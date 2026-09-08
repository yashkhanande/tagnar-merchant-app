import {before, after, beforeEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, serverTimestamp} from 'firebase/firestore';

let env;
const projectId = 'demo-tagnar-merchant';
const phone = '+919000000001';
const verified = {phone_number: phone, email: 'merchant@example.test', firebase: {sign_in_provider: 'google.com', identities: {'google.com': ['google-uid']}}};
const dbFor = (uid, claims = verified) => env.authenticatedContext(uid, claims).firestore();
const profile = (uid) => ({uid, name: 'Merchant', email: 'merchant@example.test', photoUrl: '', phoneNumber: phone, createdAt: serverTimestamp(), lastLogin: serverTimestamp(), updatedAt: serverTimestamp()});
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
  await assertSucceeds(setDoc(doc(dbFor('alice'), 'merchants_new/alice'), profile('alice')));
  await assertSucceeds(setDoc(doc(dbFor('bob'), 'merchants_new/bob'), profile('bob')));
  await seed('anchor/anchor-a', {merchantId: 'alice', prefabName: 'Building', latitude: 18.4616, longitude: 73.8818});
});

test('Google login creates its own base merchant profile', async () => {
  const googleOnly = {...verified}; delete googleOnly.phone_number;
  const base = profile('new-user'); delete base.phoneNumber;
  await assertSucceeds(setDoc(doc(dbFor('new-user', googleOnly), 'merchants_new/new-user'), base));
  await assertFails(setDoc(doc(dbFor('new-user', googleOnly), 'merchants_new/other'), base));
});

test('only verified merchant can complete onboarding', async () => {
  await assertSucceeds(updateDoc(doc(dbFor('alice'), 'merchants_new/alice'), onboarding));
  const googleOnly = {...verified}; delete googleOnly.phone_number;
  await assertFails(updateDoc(doc(dbFor('alice', googleOnly), 'merchants_new/alice'), onboarding));
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
