import { render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const authState = vi.hoisted(() => ({
  user: null as null | { uid: string },
  restoring: false,
}));

vi.mock('../contexts/AuthContext', () => ({
  useAuth: () => authState,
}));

import { ProtectedRoute } from '../components/RouteGuards';

describe('ProtectedRoute', () => {
  beforeEach(() => {
    authState.user = null;
    authState.restoring = false;
  });

  it('returns a signed-out visitor to login', () => {
    render(
      <MemoryRouter initialEntries={['/library']}>
        <Routes>
          <Route path="/login" element={<h1>Sign in</h1>} />
          <Route path="/library" element={<ProtectedRoute><h1>Library</h1></ProtectedRoute>} />
        </Routes>
      </MemoryRouter>,
    );
    expect(screen.getByRole('heading', { name: 'Sign in' })).toBeInTheDocument();
  });

  it('shows protected content for an authenticated visitor', () => {
    authState.user = { uid: 'user-1' };
    render(
      <MemoryRouter initialEntries={['/library']}>
        <Routes><Route path="/library" element={<ProtectedRoute><h1>Library</h1></ProtectedRoute>} /></Routes>
      </MemoryRouter>,
    );
    expect(screen.getByRole('heading', { name: 'Library' })).toBeInTheDocument();
  });
});
