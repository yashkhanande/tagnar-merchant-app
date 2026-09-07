import {before, after, beforeEach, test} from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {initializeTestEnvironment, assertFails, assertSucceeds} from '@firebase/rules-unit-testing';
import {doc, setDoc, getDoc, getDocs, collection, query, where, updateDoc, deleteDoc, writeBatch, serverTimestamp} from 'firebase/firestore';
import {approvalWrites} from '../approve_shop.mjs';

let env;
const projectId = 'demo-tagnar-merchant';
const phone = '+919000000001';
const verified = {phone_number: phone, email: 'merchant@example.test', firebase: {sign_in_provider: 'google.com', identities: {'google.com': ['google-uid']}}};
const dbFor = (uid, claims = verified) => env.authenticatedContext(uid, claims).firestore();
const profile = (uid) => ({uid, name: 'Merchant', email: 'merchant@example.test', phoneNumber: phone, createdAt: serverTimestamp(), updatedAt: serverTimestamp()});
function approve(db, {uid = 'alice', shop = 'shop-a', anchor = 'anchor-a', master = 'master-a'} = {}) {
  const batch = writeBatch(db);
  batch.set(doc(db, 'merchant_shops', shop), {merchantId: uid, name: 'Corner Market', address: 'Baner Road, Pune', status: 'approved', anchorId: anchor, approvedBy: master, createdAt: serverTimestamp(), updatedAt: serverTimestamp()});
  batch.set(doc(db, 'merchant_anchors', anchor), {merchantId: uid, shopId: shop, active: true, approvedBy: master, createdAt: serverTimestamp()});
  return batch.commit();
}
async function seed(path, value) { await env.withSecurityRulesDisabled(async context => setDoc(doc(context.firestore(), path), value)); }

before(async () => {
  env = await initializeTestEnvironment({projectId, firestore: {host: '127.0.0.1', port: 8088, rules: await readFile(new URL('../../firestore.merchant.rules', import.meta.url), 'utf8')}});
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await seed('master_access/master-a', {active: true});
  await seed('master_access/master-b', {active: true});
  await assertSucceeds(setDoc(doc(dbFor('alice'), 'merchants_new', 'alice'), profile('alice')));
  await assertSucceeds(setDoc(doc(dbFor('bob'), 'merchants_new', 'bob'), profile('bob')));
});

test('unauthenticated and Google-only users cannot create verified profiles', async () => {
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'merchants_new/guest'), profile('guest')));
  const googleOnly = {...verified}; delete googleOnly.phone_number;
  await assertFails(setDoc(doc(dbFor('no-phone', googleOnly), 'merchants_new/no-phone'), profile('no-phone')));
  const phoneOnly = {...verified, firebase: {sign_in_provider: 'phone', identities: {phone: [phone]}}};
  await assertFails(setDoc(doc(dbFor('phone-only', phoneOnly), 'merchants_new/phone-only'), profile('phone-only')));
});

test('profile phone must match Firebase token; self-granted role is rejected', async () => {
  await assertFails(setDoc(doc(dbFor('forger'), 'merchants_new/forger'), {...profile('forger'), phoneNumber: '+919999999999'}));
  await assertFails(setDoc(doc(dbFor('forger'), 'merchants_new/forger'), {...profile('forger'), role: 'master'}));
  await assertFails(setDoc(doc(dbFor('alice'), 'master_access/alice'), {active: true}));
  await assertFails(updateDoc(doc(dbFor('alice'), 'merchants_new/alice'), {suspended: false}));
});

test('merchant cannot read another profile or enumerate merchants', async () => {
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'merchants_new/alice')));
  await assertFails(getDoc(doc(dbFor('alice'), 'merchants_new/bob')));
  await assertFails(getDocs(collection(dbFor('alice'), 'merchants_new')));
});

test('any active Master can atomically create and approve shops', async () => {
  await assertSucceeds(approve(dbFor('master-a')));
  await assertSucceeds(approve(dbFor('master-b'), {shop: 'shop-b', anchor: 'anchor-b', master: 'master-b'}));
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'merchant_anchors/anchor-a')));
  await assertSucceeds(getDoc(doc(dbFor('alice'), 'merchant_anchors/anchor-b')));
});

test('merchant self-approval and inactive/forged Master roles are rejected', async () => {
  await assertFails(approve(dbFor('alice'), {master: 'alice'}));
  await assertFails(approve(dbFor('fake-master', {...verified, role: 'master'}), {master: 'fake-master'}));
  await seed('master_access/master-a', {active: false});
  await assertFails(approve(dbFor('master-a')));
});

test('one-sided approvals and forged approver are denied', async () => {
  const db = dbFor('master-a');
  await assertFails(setDoc(doc(db, 'merchant_shops/shop-a'), {merchantId: 'alice', name: 'Shop', address: 'Pune India', status: 'approved', anchorId: 'anchor-a', approvedBy: 'master-a', createdAt: serverTimestamp(), updatedAt: serverTimestamp()}));
  await assertFails(setDoc(doc(db, 'merchant_anchors/anchor-a'), {merchantId: 'alice', shopId: 'shop-a', active: true, approvedBy: 'master-a', createdAt: serverTimestamp()}));
  await assertFails(approve(db, {master: 'master-b'}));
  await assertFails(approve(db, {uid: 'unknown'}));
});

test('cross-merchant shops/anchors and broad queries are denied', async () => {
  await approve(dbFor('master-a'));
  await assertSucceeds(getDocs(query(collection(dbFor('alice'), 'merchant_shops'), where('merchantId', '==', 'alice'))));
  await assertFails(getDocs(collection(dbFor('alice'), 'merchant_shops')));
  await assertFails(getDoc(doc(dbFor('bob'), 'merchant_shops/shop-a')));
  await assertFails(getDoc(doc(dbFor('bob'), 'merchant_anchors/anchor-a')));
  await assertFails(getDocs(collection(dbFor('alice'), 'merchant_anchors')));
});

test('owners cannot rewrite approval, transfer anchors, or delete shops', async () => {
  await approve(dbFor('master-a'));
  await assertFails(updateDoc(doc(dbFor('alice'), 'merchant_shops/shop-a'), {merchantId: 'bob'}));
  await assertFails(updateDoc(doc(dbFor('alice'), 'merchant_anchors/anchor-a'), {active: true}));
  await assertFails(deleteDoc(doc(dbFor('alice'), 'merchant_shops/shop-a')));
  await assertFails(approve(dbFor('master-b'), {uid: 'bob', shop: 'shop-b', master: 'master-b'}));
});

test('mismatched two-document ownership does not pass atomic validation', async () => {
  const db = dbFor('master-a');
  const batch = writeBatch(db);
  batch.set(doc(db, 'merchant_shops/shop-a'), {merchantId: 'alice', name: 'Shop', address: 'Pune India', status: 'approved', anchorId: 'anchor-a', approvedBy: 'master-a', createdAt: serverTimestamp(), updatedAt: serverTimestamp()});
  batch.set(doc(db, 'merchant_anchors/anchor-a'), {merchantId: 'bob', shopId: 'shop-a', active: true, approvedBy: 'master-a', createdAt: serverTimestamp()});
  await assertFails(batch.commit());
});

test('revoked anchors and suspended merchants lose backend access', async () => {
  await approve(dbFor('master-a'));
  await env.withSecurityRulesDisabled(async context => updateDoc(doc(context.firestore(), 'merchant_anchors/anchor-a'), {active: false}));
  await assertFails(getDoc(doc(dbFor('alice'), 'merchant_anchors/anchor-a')));
  await env.withSecurityRulesDisabled(async context => updateDoc(doc(context.firestore(), 'merchants_new/alice'), {suspended: true}));
  await assertFails(getDoc(doc(dbFor('alice'), 'merchant_shops/shop-a')));
  await assertFails(approve(dbFor('master-a'), {shop: 'shop-b', anchor: 'anchor-b'}));
});

test('100 shops work without giving the merchant unscoped database access', async () => {
  const master = dbFor('master-a');
  for (let index = 0; index < 100; index++) await assertSucceeds(approve(master, {shop: `shop-${index}`, anchor: `anchor-${index}`}));
  const result = await assertSucceeds(getDocs(query(collection(dbFor('alice'), 'merchant_shops'), where('merchantId', '==', 'alice'))));
  assert.equal(result.size, 100);
  await assertFails(getDocs(collection(dbFor('bob'), 'merchant_shops')));
});

test('unimplemented financial and chat paths are denied even for Masters', async () => {
  for (const uid of ['alice', 'master-a']) {
    await assertFails(setDoc(doc(dbFor(uid), 'payments/fake'), {status: 'received', amount: 100}));
    await assertFails(setDoc(doc(dbFor(uid), 'chats/other'), {members: [uid]}));
  }
});

test('Master helper targets only named database with create preconditions', () => {
  const writes = approvalWrites({projectId, merchantId:'alice', shopId:'shop-a', anchorId:'anchor-a', masterId:'master-a', name:'Shop A', address:'Pune India'});
  assert.equal(writes.length, 2);
  for (const write of writes) {
    assert.ok(write.update.name.includes('/databases/tagnar-merchant/'));
    assert.equal(write.currentDocument.exists, false);
  }
  assert.throws(() => approvalWrites({projectId, merchantId:'alice', shopId:'../bad', anchorId:'anchor', masterId:'master', name:'Shop', address:'Pune India'}));
});
