import { cleanup, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, describe, expect, it, vi } from 'vitest';

const authState = vi.hoisted(() => ({
  user: null as null | {
    uid: string;
    displayName: string;
    email: string;
    photoURL: null;
  },
  restoring: false,
}));

vi.mock('../contexts/AuthContext', () => ({
  useAuth: () => authState,
}));

vi.mock('../pages/LoginPage', () => ({ LoginPage: () => <h1>Login route</h1> }));
vi.mock('../pages/HomePage', () => ({ HomePage: () => <h1>Home route</h1> }));
vi.mock('../pages/LibraryPage', () => ({ LibraryPage: () => <h1>Library route</h1> }));
vi.mock('../pages/CoursePage', () => ({ CoursePage: () => <h1>Course route</h1> }));
vi.mock('../pages/UploadPage', () => ({ UploadPage: () => <h1>Upload route</h1> }));
vi.mock('../pages/DocumentPage', () => ({ DocumentPage: () => <h1>Document route</h1> }));
vi.mock('../pages/DeckPage', () => ({ DeckPage: () => <h1>Deck route</h1> }));
vi.mock('../pages/ReviewPage', () => ({ ReviewPage: () => <h1>Review route</h1> }));
vi.mock('../pages/SummaryPage', () => ({ SummaryPage: () => <h1>Summary route</h1> }));
vi.mock('../pages/StudyPage', () => ({ StudyPage: () => <h1>Study route</h1> }));
vi.mock('../pages/ProgressPage', () => ({ ProgressPage: () => <h1>Progress route</h1> }));
vi.mock('../pages/ProfilePage', () => ({ ProfilePage: () => <h1>Profile route</h1> }));
vi.mock('../pages/NotFoundPage', () => ({ NotFoundPage: () => <h1>Not-found route</h1> }));

import { AppRoutes } from '../App';

const protectedUser = {
  uid: 'user-1',
  displayName: 'Morgan James',
  email: 'morgan@example.com',
  photoURL: null,
};

const routes = [
  ['/login', 'Login route', false],
  ['/', 'Home route', true],
  ['/home', 'Home route', true],
  ['/library', 'Library route', true],
  ['/library/course-1', 'Course route', true],
  ['/upload?courseId=course-1', 'Upload route', true],
  ['/library/course-1/document/document-1', 'Document route', true],
  ['/library/course-1/deck/deck-1', 'Deck route', true],
  ['/library/course-1/deck/deck-1/review', 'Review route', false],
  [
    '/library/course-1/document/document-1/summary/summary-1',
    'Summary route',
    true,
  ],
  ['/study', 'Study route', true],
  ['/progress', 'Progress route', true],
  ['/profile', 'Profile route', true],
  ['/not-a-real-route', 'Not-found route', true],
] as const;

afterEach(() => {
  cleanup();
  authState.user = null;
  authState.restoring = false;
});

describe('application routes', () => {
  it.each(routes)('renders %s through the expected chrome', async (path, marker, hasShell) => {
    authState.user = path === '/login' ? null : protectedUser;
    render(
      <MemoryRouter initialEntries={[path]}>
        <AppRoutes />
      </MemoryRouter>,
    );

    expect(await screen.findByRole('heading', { name: marker })).toBeInTheDocument();
    expect(document.querySelector('.app-shell') !== null).toBe(hasShell);
  });
});
