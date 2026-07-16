import { useEffect, useState, type FormEvent } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { GoogleIcon } from '../components/Icons';
import { Brand, Button, LearningTrace, useDocumentTitle } from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { friendlyError } from '../lib/format';

export function validateAuthInput(mode: 'login' | 'register', email: string, password: string) {
  const errors: { email?: string; password?: string } = {};
  if (!/^\S+@\S+\.\S+$/.test(email.trim())) errors.email = 'Enter a valid email address.';
  if (!password) errors.password = 'Enter your password.';
  else if (mode === 'register' && password.length < 8) errors.password = 'Use at least 8 characters.';
  return errors;
}

export function LoginPage() {
  useDocumentTitle('Sign in');
  const { signIn, register, signInWithGoogle, restorationError, retryRestoration } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [emailError, setEmailError] = useState('');
  const [passwordError, setPasswordError] = useState('');
  const [formError, setFormError] = useState<string | null>(restorationError);
  const [status, setStatus] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const destination = (location.state as { from?: string } | null)?.from || '/';

  useEffect(() => {
    if (restorationError) setFormError(restorationError);
  }, [restorationError]);

  const validate = () => {
    const errors = validateAuthInput(mode, email, password);
    setEmailError(errors.email ?? '');
    setPasswordError(errors.password ?? '');
    return !errors.email && !errors.password;
  };

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (!validate()) return;
    setBusy(true);
    setFormError(null);
    setStatus(mode === 'register' ? 'Creating your account.' : 'Signing you in.');
    try {
      if (mode === 'register') await register(email.trim(), password);
      else await signIn(email.trim(), password);
      navigate(destination, { replace: true });
    } catch (error) {
      setFormError(friendlyError(error));
      setStatus(null);
    } finally {
      setBusy(false);
    }
  };

  const google = async () => {
    setBusy(true);
    setFormError(null);
    setStatus('Opening Google sign-in.');
    try {
      const completed = await signInWithGoogle();
      if (completed) navigate(destination, { replace: true });
      else setStatus('Google sign-in was canceled.');
    } catch (error) {
      setFormError(friendlyError(error));
      setStatus(null);
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="auth-layout">
      <section className="auth-story" aria-labelledby="auth-story-title">
        <div className="auth-brand"><Brand /></div>
        <div>
          <LearningTrace />
          <h1 id="auth-story-title">Make sense of what you study.</h1>
          <p>Bring course material together, create useful study aids, and review without unnecessary noise.</p>
        </div>
      </section>
      <section className="auth-form-wrap">
        <div className="auth-form">
          <p className="eyebrow">Your learning trace</p>
          <h2>{mode === 'register' ? 'Create your account' : 'Welcome back'}</h2>
          <p>{mode === 'register' ? 'Start organizing your study material.' : 'Sign in to continue your courses.'}</p>
          <form className="form-grid" onSubmit={submit} noValidate>
            <div className="field">
              <label htmlFor="email">Email</label>
              <input
                id="email"
                type="email"
                autoComplete="email"
                value={email}
                aria-invalid={Boolean(emailError)}
                aria-describedby="email-error"
                onChange={(event) => {
                  setEmail(event.target.value);
                  setEmailError('');
                }}
              />
              <span className="field-error" id="email-error">{emailError}</span>
            </div>
            <div className="field">
              <label htmlFor="password">Password</label>
              <input
                id="password"
                type="password"
                autoComplete={mode === 'register' ? 'new-password' : 'current-password'}
                value={password}
                aria-invalid={Boolean(passwordError)}
                aria-describedby="password-error"
                onChange={(event) => {
                  setPassword(event.target.value);
                  setPasswordError('');
                }}
              />
              <span className="field-error" id="password-error">{passwordError}</span>
            </div>
            {formError && <p className="form-message error" role="alert">{formError}</p>}
            {restorationError && (
              <Button type="button" className="secondary full" onClick={retryRestoration}>Retry session check</Button>
            )}
            <Button type="submit" className="primary full" disabled={busy}>
              {busy ? 'Please wait…' : mode === 'register' ? 'Create account' : 'Sign in'}
            </Button>
          </form>
          <div className="divider"><span>or</span></div>
          <Button className="secondary full" type="button" disabled={busy} onClick={() => void google()}>
            <GoogleIcon /> Continue with Google
          </Button>
          <p className="auth-switch">
            {mode === 'register' ? 'Already have an account?' : 'New to Cramly?'}{' '}
            <button
              type="button"
              disabled={busy}
              onClick={() => {
                setMode(mode === 'login' ? 'register' : 'login');
                setFormError(null);
                setPasswordError('');
              }}
            >
              {mode === 'register' ? 'Sign in' : 'Create an account'}
            </button>
          </p>
          <p className="sr-only" aria-live="polite">{status}</p>
        </div>
      </section>
    </main>
  );
}
