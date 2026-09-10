import {before, after, beforeEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, addDoc, serverTimestamp} from 'firebase/firestore';

let env;
const projectId = 'demo-tagnar-merchant';
const phone = '+919000000001';
const verified = {phone_number: phone, firebase: {sign_in_provider: 'phone', identities: {phone: [phone]}}};
const dbFor = (uid, claims = verified) => env.authenticatedContext(uid, claims).firestore();
const profile = (uid) => ({uid, name: 'Merchant', email: '', photoUrl: '', phoneNumber: phone, createdAt: serverTimestamp(), lastLogin: serverTimestamp(), updatedAt: serverTimestamp()});
const onboarding = {businessName: 'Corner Market', businessAddress: 'Baner Road, Pune', businessType: 'soleProprietorship', businessPhone: phone, businessEmail: 'anchor@example.test', gstNumber: '27ABCDE1234F1Z5', city: 'Pune', state: 'Maharashtra', country: 'India', postalCode: '411045', onboardingCompleted: true, updatedAt: serverTimestamp()};

async function seed(path, value) {
  await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(), path), value));
}

before(async () => {
  env = await initializeTestEnvironment({projectId, firestore: {host: '127.0.0.1', port: 8088, rules: await readFile(new URL('../../firestore.merchant.rules', import.meta.url), 'utf8')}});
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await seed('merchants_new/alice', profile('alice'));
  await seed('merchants_new/bob', profile('bob'));
  await seed('anchor/anchor-a', {merchantId: 'alice', prefabName: 'Building', latitude: 18.4616, longitude: 73.8818});
});

test('merchant profiles are client read-only', async () => {
  await assertFails(setDoc(doc(dbFor('alice'), 'merchants_new/new-user'), profile('new-user')));
  await assertFails(updateDoc(doc(dbFor('alice'), 'merchants_new/alice'), {name: 'Changed'}));
});

test('onboarding updates must use the trusted function', async () => {
  await assertFails(updateDoc(doc(dbFor('alice'), 'merchants_new/alice'), onboarding));
});

test('merchant reads anchors by matching merchantId', async () => {
  const result = await assertSucceeds(getDocs(query(collection(dbFor('alice'), 'anchor'), where('merchantId', '==', 'alice'))));
  assert.equal(result.size, 1);
  await assertFails(getDoc(doc(dbFor('bob'), 'anchor/anchor-a')));
  await assertFails(getDocs(collection(dbFor('alice'), 'anchor')));
});

test('merchant cannot create, modify or delete anchor ownership', async () => {
  await assertFails(setDoc(doc(dbFor('alice'), 'anchor/fake'), {merchantId: 'alice'}));
  await assertFails(updateDoc(doc(dbFor('alice'), 'anchor/anchor-a'), {merchantId: 'bob'}));
});

test('operational records are scoped by merchantId and anchorId', async () => {
  await seed('merchant_requests/request-a', {merchantId: 'alice', anchorId: 'anchor-a'});
  await assertSucceeds(getDocs(query(collection(dbFor('alice'), 'merchant_requests'), where('merchantId', '==', 'alice'), where('anchorId', '==', 'anchor-a'))));
  await assertFails(getDoc(doc(dbFor('bob'), 'merchant_requests/request-a')));
});

test('offer and chat writes must use trusted functions', async () => {
  await seed('merchant_offers/offer-a', {merchantId: 'alice', anchorId: 'anchor-a', decision: null});
  await seed('merchant_conversations/chat-a', {merchantId: 'alice', anchorId: 'anchor-a', unread: 2});
  await assertFails(updateDoc(doc(dbFor('alice'), 'merchant_offers/offer-a'), {decision: 'accepted'}));
  await assertFails(updateDoc(doc(dbFor('alice'), 'merchant_conversations/chat-a'), {unread: 0}));
  await assertFails(addDoc(collection(dbFor('alice'), 'merchant_conversations/chat-a/messages'), {
    text: 'tampered', senderId: 'alice', fromMerchant: true, sentAt: serverTimestamp(),
  }));
});

test('brand requests support document-ID targets and all-anchor scope', async () => {
  await seed('merchant_requests/selected', {
    merchantId: 'alice',
    targetScope: 'selected',
    anchorDocumentIds: ['firestore-anchor-doc-a', 'firestore-anchor-doc-b'],
  });
  await seed('merchant_requests/all', {merchantId: 'alice', targetScope: 'all'});
  const result = await assertSucceeds(getDocs(query(
    collection(dbFor('alice'), 'merchant_requests'),
    where('merchantId', '==', 'alice'),
  )));
  assert.equal(result.size, 2);
  await assertFails(getDocs(query(
    collection(dbFor('bob'), 'merchant_requests'),
    where('merchantId', '==', 'alice'),
  )));
});

test('request access trusts merchant ownership, not the anchor document path', async () => {
  await seed('merchant_requests/wrong-anchor', {merchantId: 'alice', anchorId: 'missing'});
  await seed('merchant_requests/wrong-merchant', {merchantId: 'bob', anchorId: 'anchor-a'});
  await seed('merchant_requests/missing-anchor-id', {merchantId: 'alice'});
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'merchant_requests/wrong-anchor')));
  await assertFails(getDoc(doc(dbFor('alice'), 'merchant_requests/wrong-merchant')));
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'merchant_requests/missing-anchor-id')));
});

test('merchant cannot read another profile or enumerate merchants', async () => {
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'merchants_new/alice')));
  await assertFails(getDoc(doc(dbFor('alice'), 'merchants_new/bob')));
  await assertFails(getDocs(collection(dbFor('alice'), 'merchants_new')));
});

test('unknown paths remain denied', async () => {
  await assertFails(setDoc(doc(dbFor('alice'), 'payments/fake'), {status: 'received'}));
  await assertFails(getDocs(collection(dbFor('alice'), 'users')));
});
