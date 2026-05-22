import admin from 'firebase-admin';
import { readFileSync } from 'fs';
import { getStorage } from 'firebase-admin/storage';

const cred = JSON.parse(readFileSync('./service-account.json', 'utf8'));
admin.initializeApp({ credential: admin.credential.cert(cred), projectId: 'melodaiapp' });

for (const name of ['gs://melodaiapp.firebasestorage.app', 'melodaiapp.firebasestorage.app']) {
  const b = getStorage().bucket(name);
  const [exists] = await b.exists();
  console.log(name, 'exists=', exists);
  if (exists) {
    try {
      const [url] = await b.file('test/key').getSignedUrl({
        version: 'v4',
        action: 'write',
        expires: Date.now() + 60000,
        contentType: 'audio/mpeg',
      });
      console.log(name, 'signed ok', url.slice(0, 80));
    } catch (e) {
      console.log(name, 'signed ERR', e.message);
    }
  }
}
