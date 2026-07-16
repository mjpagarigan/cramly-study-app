import type { ReactNode } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { LearningTrace } from './ui';

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { user, restoring } = useAuth();
  const location = useLocation();
  if (restoring) return <AppLoading />;
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname + location.search }} />;
  return children;
}

export function SignedOutRoute({ children }: { children: ReactNode }) {
  const { user, restoring } = useAuth();
  if (restoring) return <AppLoading />;
  if (user) return <Navigate to="/" replace />;
  return children;
}

export function AppLoading() {
  return (
    <main className="splash" aria-live="polite">
      <div>
        <LearningTrace />
        <p className="eyebrow">Cramly</p>
        <h1>Restoring your learning trace</h1>
        <p>Checking your session and saved study material.</p>
      </div>
    </main>
  );
}
