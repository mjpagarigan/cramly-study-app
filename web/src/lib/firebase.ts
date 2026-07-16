import { getApp, getApps, initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const configuredValues = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

export const firebaseConfigured = Object.values(configuredValues).every(Boolean);
const firebaseConfig = firebaseConfigured ? configuredValues : {
  apiKey: 'local-placeholder-api-key',
  authDomain: 'local-placeholder.firebaseapp.com',
  projectId: 'local-placeholder',
  storageBucket: 'local-placeholder.firebasestorage.app',
  messagingSenderId: '000000000000',
  appId: '1:000000000000:web:0000000000000000000000',
};
export const firebaseApp = getApps().length ? getApp() : initializeApp(firebaseConfig);
export const auth = getAuth(firebaseApp);
export const db = getFirestore(firebaseApp);
export const storage = getStorage(firebaseApp);
