/** Master-side integration helper, not an admin or Master application.
 * Uses a Firebase USER ID token so Firestore Security Rules remain enforced.
 * No Admin SDK, service account, or database-rule bypass is used.
 */
import {readFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';

export function approvalWrites({projectId, merchantId, shopId, anchorId, masterId, name, address}) {
  for (const [key, value] of Object.entries({projectId, merchantId, shopId, anchorId, masterId})) {
    if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new Error(`Invalid ${key}`);
  }
  if (typeof name !== 'string' || name.trim().length < 2 || name.length > 100) throw new Error('Invalid shop name');
  if (typeof address !== 'string' || address.trim().length < 5 || address.length > 300) throw new Error('Invalid address');
  const root = `projects/${projectId}/databases/tagnar-merchant/documents`;
  const string = (value) => ({stringValue: value});
  const timestamps = (...fields) => fields.map(fieldPath => ({fieldPath, setToServerValue: 'REQUEST_TIME'}));
  return [
    {update: {name: `${root}/merchant_shops/${shopId}`, fields: {
      merchantId: string(merchantId), name: string(name.trim()), address: string(address.trim()),
      status: string('approved'), anchorId: string(anchorId), approvedBy: string(masterId),
    }}, currentDocument: {exists: false}, updateTransforms: timestamps('createdAt', 'updatedAt')},
    {update: {name: `${root}/merchant_anchors/${anchorId}`, fields: {
      merchantId: string(merchantId), shopId: string(shopId), approvedBy: string(masterId), active: {booleanValue: true},
    }}, currentDocument: {exists: false}, updateTransforms: timestamps('createdAt')},
  ];
}

async function main() {
  const [requestFile, ...flags] = process.argv.slice(2);
  if (!requestFile || flags.some(flag => flag !== '--commit')) throw new Error('Usage: node backend/approve_shop.mjs request.json [--commit]');
  const request = JSON.parse(await readFile(requestFile, 'utf8'));
  const writes = approvalWrites(request);
  if (!flags.includes('--commit')) {
    console.log(JSON.stringify({writes}, null, 2));
    console.log('Preview only. Add --commit with TAGNAR_MASTER_ID_TOKEN set to a signed-in Master’s Firebase ID token.');
    return;
  }
  const token = process.env.TAGNAR_MASTER_ID_TOKEN;
  if (!token) throw new Error('TAGNAR_MASTER_ID_TOKEN is required; do not use an OAuth access token or service account.');
  const response = await fetch(`https://firestore.googleapis.com/v1/projects/${request.projectId}/databases/tagnar-merchant/documents:commit`, {
    method: 'POST', headers: {Authorization: `Bearer ${token}`, 'Content-Type': 'application/json'}, body: JSON.stringify({writes}),
  });
  if (!response.ok) throw new Error(`Approval rejected (${response.status}). Check Master access, merchant verification and unused shop/anchor IDs.`);
  console.log('Shop and anchor approved together.');
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => {console.error(error.message); process.exitCode = 1;});
}
