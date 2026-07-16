import { useRef, useState, type KeyboardEvent } from 'react';
import { LogOutIcon } from '../components/Icons';
import {
  Badge,
  Button,
  LearningTrace,
  PageHeader,
  Panel,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { displayName, friendlyError, initials } from '../lib/format';
import type { ThemeMode } from '../types';

const themes: Array<{ id: ThemeMode; label: string; copy: string }> = [
  { id: 'light', label: 'Light', copy: 'Study-paper surfaces' },
  { id: 'dark', label: 'Dark', copy: 'Evergreen night surfaces' },
  { id: 'system', label: 'System', copy: 'Follow your device' },
];

export function ProfilePage() {
  useDocumentTitle('Profile');
  const { user, signOut } = useAuth();
  const { mode, setMode } = useTheme();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const themeOptions = useRef<Array<HTMLButtonElement | null>>([]);
  const moveThemeSelection = (event: KeyboardEvent<HTMLButtonElement>, index: number) => {
    let nextIndex: number | null = null;
    if (event.key === 'ArrowRight' || event.key === 'ArrowDown') nextIndex = (index + 1) % themes.length;
    if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') nextIndex = (index - 1 + themes.length) % themes.length;
    if (event.key === 'Home') nextIndex = 0;
    if (event.key === 'End') nextIndex = themes.length - 1;
    if (nextIndex === null) return;
    event.preventDefault();
    setMode(themes[nextIndex].id);
    themeOptions.current[nextIndex]?.focus();
  };
  const logOut = async () => {
    setBusy(true); setError(null);
    try { await signOut(); }
    catch (nextError) { setError(friendlyError(nextError)); setBusy(false); }
  };
  return (
    <>
      <PageHeader eyebrow="Your account" title="Profile" actions={<Button className="danger" disabled={busy} onClick={() => void logOut()}><LogOutIcon /> {busy ? 'Signing out…' : 'Sign out'}</Button>} />
      <LearningTrace className="page-trace" />
      {error && <p className="form-message error" role="alert">{error}</p>}
      <div className="grid-12 profile-layout">
        <section className="span-5">
          <Panel className="profile-card">
            {user?.photoURL ? <img className="profile-avatar" src={user.photoURL} alt="" referrerPolicy="no-referrer" /> : <span className="profile-avatar initials" aria-hidden="true">{initials(user)}</span>}
            <div><strong>{displayName(user)}</strong><span>{user?.email || 'Email unavailable'}</span></div>
          </Panel>
          <div className="section-head"><h2>Account</h2></div>
          <Panel className="settings-list">
            <div className="setting-row"><span>Edit account</span><Badge tone="planned">Planned</Badge></div>
            <div className="setting-row"><span>Apple sign-in</span><Badge tone="planned">Planned</Badge></div>
          </Panel>
        </section>
        <section className="span-7">
          <div className="section-head flush"><h2>Appearance</h2><span className="helper">Saved on this device</span></div>
          <Panel className="theme-list" role="radiogroup" aria-label="Appearance">
            {themes.map((theme, index) => (
              <button
                type="button"
                role="radio"
                aria-checked={mode === theme.id}
                className="theme-choice"
                key={theme.id}
                tabIndex={mode === theme.id ? 0 : -1}
                ref={(element) => { themeOptions.current[index] = element; }}
                onClick={() => setMode(theme.id)}
                onKeyDown={(event) => moveThemeSelection(event, index)}
              >
                <span><strong>{theme.label}</strong><small>{theme.copy}</small></span><i className={mode === theme.id ? 'active' : ''} aria-hidden="true" />
              </button>
            ))}
          </Panel>
        </section>
      </div>
    </>
  );
}
