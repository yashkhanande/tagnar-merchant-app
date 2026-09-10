import {initializeApp} from "firebase-admin/app";
import {getAuth} from "firebase-admin/auth";
import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";
import {setGlobalOptions} from "firebase-functions/v2";
import {HttpsError, onCall} from "firebase-functions/v2/https";

import {onboardingPayload, requireString} from "./validation.js";

initializeApp();
setGlobalOptions({region: "asia-south1", maxInstances: 10});

const db = getFirestore();
// Turn enforcement on after Firebase App Check providers are configured.
// Phone authentication and server authorization remain mandatory meanwhile.
const callable = {enforceAppCheck: false};

function phoneUser(request) {
  const uid = request.auth?.uid;
  const phone = request.auth?.token?.phone_number;
  if (!uid || typeof phone !== "string" || phone.length === 0) {
    throw new HttpsError(
        "unauthenticated",
        "Sign in and verify your mobile number to continue.",
    );
  }
  return {uid, phone};
}

async function eligibleMerchant(uid) {
  const ref = db.collection("merchants_new").doc(uid);
  const snapshot = await ref.get();
  const data = snapshot.data();
  if (
    !snapshot.exists ||
    typeof data?.phoneNumber !== "string" ||
    data.phoneNumber.length === 0 ||
    data.suspended === true
  ) {
    throw new HttpsError("permission-denied", "Merchant access is unavailable.");
  }
  return {ref, data};
}

async function requireMaster(request) {
  const {uid} = phoneUser(request);
  if (request.auth.token.admin === true || request.auth.token.master === true) {
    return uid;
  }
  const access = await db.collection("master_access").doc(uid).get();
  if (access.data()?.active !== true) {
    throw new HttpsError("permission-denied", "Master access is required.");
  }
  return uid;
}

export const ensureMerchantProfile = onCall(callable, async (request) => {
  const {uid, phone} = phoneUser(request);
  const authUser = await getAuth().getUser(uid);
  const ref = db.collection("merchants_new").doc(uid);
  await db.runTransaction(async (transaction) => {
    const current = await transaction.get(ref);
    const existing = current.data() ?? {};
    const name = authUser.displayName?.trim() || existing.name || "Merchant";
    const fields = {
      uid,
      name,
      email: authUser.email ?? "",
      photoUrl: authUser.photoURL ?? "",
      phoneNumber: phone,
      lastLogin: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (!current.exists) fields.createdAt = FieldValue.serverTimestamp();
    transaction.set(ref, fields, {merge: true});
  });
  const saved = await ref.get();
  return {onboardingCompleted: saved.data()?.onboardingCompleted === true};
});

export const updateMerchantProfile = onCall(callable, async (request) => {
  const {uid, phone} = phoneUser(request);
  const payload = onboardingPayload(request.data);
  const {ref, data} = await eligibleMerchant(uid);
  if (data.phoneNumber !== phone) {
    throw new HttpsError("permission-denied", "Verified phone does not match.");
  }
  await ref.set({...payload, updatedAt: FieldValue.serverTimestamp()}, {merge: true});
  return {updated: true};
});

export const respondToOffer = onCall(callable, async (request) => {
  const {uid} = phoneUser(request);
  const offerId = requireString(request.data, "offerId", 1, 200);
  const decision = requireString(request.data, "decision", 1, 20);
  if (decision !== "accepted" && decision !== "declined") {
    throw new HttpsError("invalid-argument", "Decision must be accepted or declined.");
  }
  await eligibleMerchant(uid);
  const ref = db.collection("merchant_offers").doc(offerId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    const data = snapshot.data();
    if (!snapshot.exists || data?.merchantId !== uid) {
      throw new HttpsError("not-found", "Offer not found.");
    }
    if (data.decision != null) {
      throw new HttpsError("already-exists", "This offer already has a response.");
    }
    if (!(data.expiresAt instanceof Timestamp) || data.expiresAt.toMillis() <= Date.now()) {
      throw new HttpsError("failed-precondition", "This offer has expired.");
    }
    transaction.update(ref, {
      decision,
      decidedAt: FieldValue.serverTimestamp(),
      decidedBy: uid,
    });
  });
  return {updated: true};
});

export const sendMerchantMessage = onCall(callable, async (request) => {
  const {uid} = phoneUser(request);
  const conversationId = requireString(request.data, "conversationId", 1, 200);
  const message = requireString(request.data, "text", 1, 1000);
  await eligibleMerchant(uid);
  const conversation = db.collection("merchant_conversations").doc(conversationId);
  const messageRef = conversation.collection("messages").doc();
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(conversation);
    if (!snapshot.exists || snapshot.data()?.merchantId !== uid) {
      throw new HttpsError("not-found", "Conversation not found.");
    }
    transaction.set(messageRef, {
      text: message,
      sentAt: FieldValue.serverTimestamp(),
      senderId: uid,
      fromMerchant: true,
    });
  });
  return {messageId: messageRef.id};
});

export const markConversationRead = onCall(callable, async (request) => {
  const {uid} = phoneUser(request);
  const conversationId = requireString(request.data, "conversationId", 1, 200);
  await eligibleMerchant(uid);
  const ref = db.collection("merchant_conversations").doc(conversationId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists || snapshot.data()?.merchantId !== uid) {
      throw new HttpsError("not-found", "Conversation not found.");
    }
    transaction.update(ref, {unread: 0, readAt: FieldValue.serverTimestamp()});
  });
  return {updated: true};
});

export const assignAnchorToMerchant = onCall(callable, async (request) => {
  const actorUid = await requireMaster(request);
  const merchantUid = requireString(request.data, "merchantUid", 1, 128);
  const anchorId = requireString(request.data, "anchorId", 1, 200);
  await eligibleMerchant(merchantUid);
  const anchor = db.collection("anchor").doc(anchorId);
  const audit = db.collection("admin_audit").doc();
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(anchor);
    if (!snapshot.exists) throw new HttpsError("not-found", "Anchor not found.");
    const previousMerchantId = snapshot.data()?.merchantId ?? null;
    transaction.update(anchor, {
      merchantId: merchantUid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    transaction.set(audit, {
      action: "anchor.assignMerchant",
      actorUid,
      anchorId,
      merchantUid,
      previousMerchantId,
      createdAt: FieldValue.serverTimestamp(),
    });
  });
  return {updated: true};
});

export const deleteMerchantAccount = onCall(callable, async (request) => {
  const {uid} = phoneUser(request);
  await eligibleMerchant(uid);
  await db.collection("merchants_new").doc(uid).delete();
  await getAuth().deleteUser(uid);
  return {deleted: true};
});
