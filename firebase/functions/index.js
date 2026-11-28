/**
 * Mindora Production Cloud Functions (Firebase Blaze + Paid Gemini API Tier)
 *
 * Pre-Launch Requirements (`AGENTS.md` Steps 10 & 14):
 * 1. Configure Secret Manager secret: `firebase functions:secrets:set GEMINI_PAID_API_KEY`
 *    using a Cloud Billing-linked Paid Gemini API key (zero training / no human review).
 * 2. Configure Google Cloud Budgets & Alerts (50%, 80%, 100%) and API quotas.
 * 3. Enforce Firebase App Check across client builds (`--dart-define=AI_PROXY_URL=...`).
 */

const crypto = require('crypto');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { onCall, onRequest, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');

initializeApp();

const geminiPaidApiKey = defineSecret('GEMINI_PAID_API_KEY');
const db = getFirestore();
const auth = getAuth();

function sha256Hex(raw) {
  return crypto.createHash('sha256').update(raw).digest('hex');
}

function hashPinPbkdf2(pin) {
  const salt = crypto.randomBytes(16).toString('hex');
  const derived = crypto.pbkdf2Sync(pin, salt, 100000, 32, 'sha256').toString('hex');
  return `pbkdf2_sha256$100000$${salt}$${derived}`;
}

function assertClinicianCaller(request) {
  if (!request.auth || request.auth.token.role !== 'clinician') {
    throw new HttpsError('permission-denied', 'Clinician credentials required.');
  }
  const clinicId = request.auth.token.clinicId;
  const doctorId = request.auth.token.doctorId;
  if (!clinicId || !doctorId) {
    throw new HttpsError('failed-precondition', 'Clinician tenant claims missing.');
  }
  return { clinicId, doctorId };
}

/**
 * Provisions a new patient within the calling clinician's tenant and emits
 * an opaque, zero-PII single-use QR payload (`MF-INVITE-V1:`).
 */
exports.provisionPatientAccount = onCall({ enforceAppCheck: true }, async (request) => {
  const { clinicId, doctorId } = assertClinicianCaller(request);
  const {
    displayName,
    loginIdentifier,
    ageRange = '25-44',
    preferredLanguage = 'en',
    assignedTrackIds = [],
    initialPin,
  } = request.data || {};

  if (!displayName || !loginIdentifier || !initialPin || String(initialPin).length < 4) {
    throw new HttpsError('invalid-argument', 'Valid displayName, loginIdentifier, and 4+ digit PIN required.');
  }

  const patientRef = db.collection('clinics').doc(clinicId).collection('patients').doc();
  const patientId = patientRef.id;
  const inviteSecret = crypto.randomBytes(18).toString('base64url');
  const inviteId = crypto.randomBytes(8).toString('hex');
  const inviteTokenHash = sha256Hex(`${inviteId}.${inviteSecret}`);
  const expiresAt = Date.now() + 24 * 60 * 60 * 1000;

  await db.runTransaction(async (tx) => {
    tx.set(patientRef, {
      patientId,
      clinicId,
      doctorId,
      displayName: String(displayName).trim(),
      loginIdentifier: String(loginIdentifier).trim().toLowerCase(),
      ageRange,
      preferredLanguage,
      assignedTrackIds,
      credentialHash: hashPinPbkdf2(String(initialPin).trim()),
      requiresPinChange: true,
      status: 'pendingFirstLogin',
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    tx.set(db.collection('inviteTokens').doc(inviteId), {
      inviteId,
      clinicId,
      doctorId,
      patientId,
      tokenHash: inviteTokenHash,
      used: false,
      revoked: false,
      expiresAt,
    });

    tx.set(db.collection('clinics').doc(clinicId).collection('auditLog').doc(), {
      clinicId,
      doctorId,
      patientId,
      action: 'createdAccount',
      actorRole: 'clinician',
      timestamp: FieldValue.serverTimestamp(),
    });
  });

  await auth.setCustomUserClaims(patientId, {
    role: 'patient',
    clinicId,
    doctorId,
  }).catch(() => {
    // User auth record is created lazily on first QR exchange if not yet provisioned.
  });

  const payloadJson = Buffer.from(
    JSON.stringify({ v: 2, t: inviteId, s: inviteSecret }),
    'utf8',
  ).toString('base64url');

  return {
    patientId,
    qrPayload: `MF-INVITE-V1:${payloadJson}`,
    expiresAt,
  };
});

/**
 * Exchanges a single-use opaque `MF-INVITE-V1:` token for a custom Firebase Auth token.
 */
exports.exchangeQrInvite = onCall({ enforceAppCheck: true }, async (request) => {
  const { t: inviteId, s: inviteSecret } = request.data || {};
  if (!inviteId || !inviteSecret) {
    throw new HttpsError('invalid-argument', 'Malformed invite payload.');
  }

  const tokenRef = db.collection('inviteTokens').doc(String(inviteId));
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(tokenRef);
    if (!snap.exists) {
      throw new HttpsError('not-found', 'Invite not found.');
    }
    const token = snap.data();
    if (token.revoked) {
      throw new HttpsError('permission-denied', 'Invite has been revoked.');
    }
    if (token.used) {
      throw new HttpsError('already-exists', 'Invite already redeemed.');
    }
    if (Date.now() > token.expiresAt) {
      throw new HttpsError('deadline-exceeded', 'Invite expired.');
    }
    const presentedHash = sha256Hex(`${inviteId}.${inviteSecret}`);
    if (presentedHash !== token.tokenHash) {
      throw new HttpsError('permission-denied', 'Invalid invite secret.');
    }

    const patientRef = db
      .collection('clinics')
      .doc(token.clinicId)
      .collection('patients')
      .doc(token.patientId);
    const patientSnap = await tx.get(patientRef);
    if (!patientSnap.exists || patientSnap.data().status === 'paused') {
      throw new HttpsError('permission-denied', 'Patient account is paused or missing.');
    }

    tx.update(tokenRef, { used: true, usedAt: FieldValue.serverTimestamp() });
    tx.set(db.collection('clinics').doc(token.clinicId).collection('auditLog').doc(), {
      clinicId: token.clinicId,
      doctorId: token.doctorId,
      patientId: token.patientId,
      action: 'patientQrLogin',
      actorRole: 'patient',
      timestamp: FieldValue.serverTimestamp(),
    });

    return {
      patientId: token.patientId,
      clinicId: token.clinicId,
      doctorId: token.doctorId,
    };
  });

  const customToken = await auth.createCustomToken(result.patientId, {
    role: 'patient',
    clinicId: result.clinicId,
    doctorId: result.doctorId,
  });

  return { customToken, ...result };
});

/**
 * Updates patient access (`active` | `paused`) and immediately revokes Firebase
 * refresh tokens whenever an account is paused by the assigning clinician.
 */
exports.setPatientAccessStatus = onCall({ enforceAppCheck: true }, async (request) => {
  const { clinicId, doctorId } = assertClinicianCaller(request);
  const { patientId, status } = request.data || {};
  if (!patientId || !['active', 'paused'].includes(status)) {
    throw new HttpsError('invalid-argument', 'Valid patientId and status (active|paused) required.');
  }

  const patientRef = db
    .collection('clinics')
    .doc(clinicId)
    .collection('patients')
    .doc(String(patientId));
  const snap = await patientRef.get();
  if (!snap.exists || snap.data().doctorId !== doctorId) {
    throw new HttpsError('permission-denied', 'Patient belongs to a different doctor.');
  }

  await patientRef.update({
    status,
    updatedAt: FieldValue.serverTimestamp(),
  });

  if (status === 'paused') {
    await auth.revokeRefreshTokens(String(patientId)).catch(() => {});
  }

  await db.collection('clinics').doc(clinicId).collection('auditLog').add({
    clinicId,
    doctorId,
    patientId: String(patientId),
    action: status === 'paused' ? 'pausedAccount' : 'resumedAccount',
    actorRole: 'clinician',
    timestamp: FieldValue.serverTimestamp(),
  });

  return { patientId: String(patientId), status };
});

/**
 * Paid-tier AI Companion proxy matching `DirectGeminiInvestigatorService`'s
 * `--dart-define=AI_PROXY_URL=...` wire contract so zero provider API keys
 * are ever bundled in mobile/desktop client binaries.
 */
exports.aiCompanionProxy = onRequest(
  { secrets: [geminiPaidApiKey], maxInstances: 20 },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    const authHeader = req.headers.authorization || '';
    if (!authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'Missing Firebase ID token' });
      return;
    }

    let decodedToken;
    try {
      decodedToken = await auth.verifyIdToken(authHeader.slice(7), true);
    } catch (_) {
      res.status(401).json({ error: 'Invalid or revoked session token' });
      return;
    }

    const body = req.body || {};
    if (body.isPrivate === true) {
      res.status(403).json({ error: 'Private entries are strictly excluded from AI transmission' });
      return;
    }

    const model = String(body.model || 'gemini-2.5-flash').replace(/[^a-zA-Z0-9._-]/g, '');
    const apiKey = geminiPaidApiKey.value();
    if (!apiKey) {
      res.status(503).json({ error: 'Paid AI service key is not configured on backend' });
      return;
    }

    const upstreamPayload = {
      system_instruction: body.system_instruction,
      contents: body.contents || [],
      generationConfig: body.generationConfig || { temperature: 0.7 },
    };

    try {
      const upstream = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
            'x-mindora-uid': decodedToken.uid,
          },
          body: JSON.stringify(upstreamPayload),
        },
      );
      const text = await upstream.text();
      res.status(upstream.status).type('application/json').send(text);
    } catch (_) {
      res.status(502).json({ error: 'Upstream AI proxy request failed' });
    }
  },
);
