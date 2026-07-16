import { useEffect, useRef, useState } from 'react';
import { NavLink, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { displayName, initials } from '../lib/format';
import {
  CloseIcon,
  HomeIcon,
  LibraryIcon,
  MenuIcon,
  ProgressIcon,
  StudyIcon,
} from './Icons';
import { Brand, Button, containDialogFocus } from './ui';

const links = [
  { to: '/', label: 'Home', icon: HomeIcon, end: true },
  { to: '/library', label: 'Library', icon: LibraryIcon, end: false },
  { to: '/study', label: 'Study', icon: StudyIcon, end: true },
  { to: '/progress', label: 'Progress', icon: ProgressIcon, end: true },
];

function Navigation({ close }: { close?: () => void }) {
  const { user } = useAuth();
  return (
    <>
      <NavLink to="/" className="brand-link" onClick={close}><Brand /></NavLink>
      <nav className="nav-group" aria-label="Primary navigation">
        <p className="nav-label">Workspace</p>
        {links.map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}
            onClick={close}
          >
            <Icon /><span>{label}</span>
          </NavLink>
        ))}
      </nav>
      <div className="sidebar-foot">
        <NavLink to="/profile" className="profile-link" onClick={close}>
          {user?.photoURL ? (
            <img className="avatar" src={user.photoURL} alt="" referrerPolicy="no-referrer" />
          ) : (
            <span className="avatar" aria-hidden="true">{initials(user)}</span>
          )}
          <span className="profile-copy">
            <strong>{displayName(user)}</strong>
            <small>{user?.email ?? 'Signed in'}</small>
          </span>
          <span aria-hidden="true">›</span>
        </NavLink>
      </div>
    </>
  );
}

export function AppShell() {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const drawer = useRef<HTMLDialogElement>(null);
  const location = useLocation();

  useEffect(() => {
    setDrawerOpen(false);
  }, [location.pathname]);

  useEffect(() => {
    const element = drawer.current;
    if (!element) return;
    if (drawerOpen && !element.open) element.showModal();
    if (!drawerOpen && element.open) element.close();
  }, [drawerOpen]);

  useEffect(() => {
    const desktop = window.matchMedia('(min-width: 1024px)');
    const closeAtDesktop = (event: MediaQueryListEvent | MediaQueryList) => {
      if (!event.matches) return;
      setDrawerOpen(false);
      if (drawer.current?.open) drawer.current.close();
    };
    closeAtDesktop(desktop);
    desktop.addEventListener('change', closeAtDesktop);
    return () => desktop.removeEventListener('change', closeAtDesktop);
  }, []);

  return (
    <div className="app-shell">
      <a className="skip-link" href="#main-content">Skip to content</a>
      <aside className="sidebar"><Navigation /></aside>
      <section className="shell-content">
        <header className="mobile-top">
          <Button className="icon-button" aria-label="Open navigation" onClick={() => setDrawerOpen(true)}>
            <MenuIcon />
          </Button>
          <NavLink to="/" className="mobile-brand"><Brand /></NavLink>
          <span className="mobile-top-spacer" aria-hidden="true" />
        </header>
        <main id="main-content" className="page" tabIndex={-1}>
          <div className="page-inner"><Outlet /></div>
        </main>
      </section>
      <dialog
        ref={drawer}
        className="nav-drawer"
        aria-label="Navigation"
        onKeyDown={containDialogFocus}
        onClose={() => setDrawerOpen(false)}
        onCancel={() => setDrawerOpen(false)}
        onMouseDown={(event) => {
          if (event.target === event.currentTarget) setDrawerOpen(false);
        }}
      >
        <div className="drawer-panel">
          <Button className="icon-button drawer-close" aria-label="Close navigation" onClick={() => setDrawerOpen(false)}>
            <CloseIcon />
          </Button>
          <Navigation close={() => setDrawerOpen(false)} />
        </div>
      </dialog>
    </div>
  );
}
