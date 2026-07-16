import { act, cleanup, render, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const firebaseAuth = vi.hoisted(() => ({
  browserLocalPersistence: { name: 'local' },
  createUserWithEmailAndPassword: vi.fn(),
  firebaseSignOut: vi.fn(),
  onIdTokenChanged: vi.fn(),
  setPersistence: vi.fn(),
  signInWithEmailAndPassword: vi.fn(),
  signInWithPopup: vi.fn(),
}));

vi.mock('firebase/auth', () => ({
  browserLocalPersistence: firebaseAuth.browserLocalPersistence,
  createUserWithEmailAndPassword: firebaseAuth.createUserWithEmailAndPassword,
  GoogleAuthProvider: class GoogleAuthProvider {},
  onIdTokenChanged: firebaseAuth.onIdTokenChanged,
  setPersistence: firebaseAuth.setPersistence,
  signInWithEmailAndPassword: firebaseAuth.signInWithEmailAndPassword,
  signInWithPopup: firebaseAuth.signInWithPopup,
  signOut: firebaseAuth.firebaseSignOut,
}));
vi.mock('../lib/firebase', () => ({
  auth: { currentUser: null },
  firebaseConfigured: true,
}));
vi.mock('../lib/demo', () => ({ demoMode: false }));

import { AuthProvider } from '../contexts/AuthContext';

function deferred() {
  let resolve!: () => void;
  const promise = new Promise<void>((complete) => {
    resolve = complete;
  });
  return { promise, resolve };
}

describe('AuthProvider restoration listener lifecycle', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  afterEach(() => {
    cleanup();
  });

  it('does not register a token listener after unmounting during persistence setup', async () => {
    const persistence = deferred();
    firebaseAuth.setPersistence.mockReturnValue(persistence.promise);

    const view = render(<AuthProvider><span>child</span></AuthProvider>);
    expect(firebaseAuth.setPersistence).toHaveBeenCalledTimes(1);

    view.unmount();
    await act(async () => {
      persistence.resolve();
      await persistence.promise;
    });

    expect(firebaseAuth.onIdTokenChanged).not.toHaveBeenCalled();
  });

  it('unsubscribes a registered token listener on unmount', async () => {
    const unsubscribe = vi.fn();
    firebaseAuth.setPersistence.mockResolvedValue(undefined);
    firebaseAuth.onIdTokenChanged.mockReturnValue(unsubscribe);

    const view = render(<AuthProvider><span>child</span></AuthProvider>);
    await waitFor(() => expect(firebaseAuth.onIdTokenChanged).toHaveBeenCalledTimes(1));

    view.unmount();
    expect(unsubscribe).toHaveBeenCalledTimes(1);
  });
});
