import { lazy, Suspense } from 'react';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AppLoading, ProtectedRoute, SignedOutRoute } from './components/RouteGuards';
import { AppShell } from './components/Shell';
import { AuthProvider } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';

const CoursePage = lazy(() => import('./pages/CoursePage').then((module) => ({ default: module.CoursePage })));
const DeckPage = lazy(() => import('./pages/DeckPage').then((module) => ({ default: module.DeckPage })));
const DocumentPage = lazy(() => import('./pages/DocumentPage').then((module) => ({ default: module.DocumentPage })));
const HomePage = lazy(() => import('./pages/HomePage').then((module) => ({ default: module.HomePage })));
const LibraryPage = lazy(() => import('./pages/LibraryPage').then((module) => ({ default: module.LibraryPage })));
const LoginPage = lazy(() => import('./pages/LoginPage').then((module) => ({ default: module.LoginPage })));
const NotFoundPage = lazy(() => import('./pages/NotFoundPage').then((module) => ({ default: module.NotFoundPage })));
const ProfilePage = lazy(() => import('./pages/ProfilePage').then((module) => ({ default: module.ProfilePage })));
const ProgressPage = lazy(() => import('./pages/ProgressPage').then((module) => ({ default: module.ProgressPage })));
const ReviewPage = lazy(() => import('./pages/ReviewPage').then((module) => ({ default: module.ReviewPage })));
const StudyPage = lazy(() => import('./pages/StudyPage').then((module) => ({ default: module.StudyPage })));
const SummaryPage = lazy(() => import('./pages/SummaryPage').then((module) => ({ default: module.SummaryPage })));
const UploadPage = lazy(() => import('./pages/UploadPage').then((module) => ({ default: module.UploadPage })));

export function App() {
  return (
    <ThemeProvider>
      <AuthProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </AuthProvider>
    </ThemeProvider>
  );
}

export function AppRoutes() {
  return (
    <Suspense fallback={<AppLoading />}><Routes>
      <Route path="/login" element={<SignedOutRoute><LoginPage /></SignedOutRoute>} />
      <Route
        path="/library/:courseId/deck/:deckId/review"
        element={<ProtectedRoute><ReviewPage /></ProtectedRoute>}
      />
      <Route element={<ProtectedRoute><AppShell /></ProtectedRoute>}>
        <Route index element={<HomePage />} />
        <Route path="library" element={<LibraryPage />} />
        <Route path="library/:courseId" element={<CoursePage />} />
        <Route path="upload" element={<UploadPage />} />
        <Route path="library/:courseId/document/:documentId" element={<DocumentPage />} />
        <Route path="library/:courseId/deck/:deckId" element={<DeckPage />} />
        <Route path="library/:courseId/document/:documentId/summary/:summaryId" element={<SummaryPage />} />
        <Route path="study" element={<StudyPage />} />
        <Route path="progress" element={<ProgressPage />} />
        <Route path="profile" element={<ProfilePage />} />
        <Route path="home" element={<Navigate to="/" replace />} />
        <Route path="*" element={<NotFoundPage />} />
      </Route>
    </Routes></Suspense>
  );
}
