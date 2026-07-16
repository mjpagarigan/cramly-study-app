import {
  browserLocalPersistence,
  createUserWithEmailAndPassword,
  GoogleAuthProvider,
  onIdTokenChanged,
  setPersistence,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut as firebaseSignOut,
  type User,
} from 'firebase/auth';
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { auth, firebaseConfigured } from '../lib/firebase';
import { demoMode } from '../lib/demo';

interface AuthValue {
  user: User | null;
  restoring: boolean;
  restorationError: string | null;
  retryRestoration(): void;
  signIn(email: string, password: string): Promise<void>;
  register(email: string, password: string): Promise<void>;
  signInWithGoogle(): Promise<boolean>;
  signOut(): Promise<void>;
}

const AuthContext = createContext<AuthValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [restoring, setRestoring] = useState(true);
  const [restorationError, setRestorationError] = useState<string | null>(null);
  const [restorationAttempt, setRestorationAttempt] = useState(0);
  const demoSignedOut = demoMode && new URLSearchParams(window.location.search).get('signedOut') === '1';

  useEffect(() => {
    if (demoMode) {
      setUser(demoSignedOut ? null : {
        uid: 'demo-user',
        displayName: 'Morgan James',
        email: 'morgan@example.com',
        photoURL: null,
        getIdToken: async () => 'demo-token',
      } as User);
      setRestoring(false);
      setRestorationError(null);
      return;
    }
    if (!firebaseConfigured) {
      setRestorationError('Firebase web configuration is missing. Add the VITE_FIREBASE_* values.');
      setRestoring(false);
      return;
    }
    let disposed = false;
    let unsubscribe: () => void = () => {};
    setPersistence(auth, browserLocalPersistence)
      .then(() => {
        if (disposed) return;
        unsubscribe = onIdTokenChanged(
          auth,
          (nextUser) => {
            if (disposed) return;
            setUser(nextUser);
            setRestoring(false);
            setRestorationError(null);
          },
          (error) => {
            if (disposed) return;
            setRestorationError(error.message);
            setRestoring(false);
          },
        );
      })
      .catch((error: unknown) => {
        if (disposed) return;
        setRestorationError(error instanceof Error ? error.message : 'Could not restore your session.');
        setRestoring(false);
      });
    return () => {
      disposed = true;
      unsubscribe();
    };
  }, [demoSignedOut, restorationAttempt]);

  const value = useMemo<AuthValue>(() => ({
    user,
    restoring,
    restorationError,
    retryRestoration() {
      setRestoring(true);
      setRestorationError(null);
      setRestorationAttempt((value) => value + 1);
    },
    async signIn(email, password) {
      if (demoMode) return;
      await setPersistence(auth, browserLocalPersistence);
      await signInWithEmailAndPassword(auth, email, password);
    },
    async register(email, password) {
      if (demoMode) return;
      await setPersistence(auth, browserLocalPersistence);
      await createUserWithEmailAndPassword(auth, email, password);
    },
    async signInWithGoogle() {
      if (demoMode) return true;
      await setPersistence(auth, browserLocalPersistence);
      try {
        await signInWithPopup(auth, new GoogleAuthProvider());
        await auth.currentUser?.getIdToken(true);
        return true;
      } catch (error) {
        const code = (error as { code?: string }).code;
        if (code === 'auth/popup-closed-by-user' || code === 'auth/cancelled-popup-request') {
          return false;
        }
        throw error;
      }
    },
    signOut() {
      if (demoMode) {
        setUser(null);
        return Promise.resolve();
      }
      return firebaseSignOut(auth);
    },
  }), [restorationError, restoring, user]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used inside AuthProvider');
  return context;
}
