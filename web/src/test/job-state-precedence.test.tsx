import { cleanup, render, screen } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { afterEach, describe, expect, it, vi } from 'vitest';

const data = vi.hoisted(() => ({
  course: {
    id: 'course-1', name: 'Biology', color: '#477966', documentCount: 1,
    deckCount: 1, quizCount: 0, createdAt: null, updatedAt: null,
  },
  document: {
    id: 'document-1', courseId: 'course-1', sourceType: 'pdf', title: 'Cell notes',
    status: 'ready', wordCount: 100, generatedAssets: {
      deckIds: [], quizIds: [], summaryIds: ['summary-1'], studyGuideIds: [], podcastIds: [],
    }, uploadedAt: null, extractedAt: null,
  },
  summary: {
    id: 'summary-1', courseId: 'course-1', sourceDocumentId: 'document-1', depth: 'detailed',
    status: 'queued', content: '', jobId: 'job-1', createdAt: null, updatedAt: null,
  },
  deck: {
    id: 'deck-1', courseId: 'course-1', title: 'Cell deck', description: '', cardCount: 0,
    generationMethod: 'ai', status: 'queued', jobId: 'job-1', createdAt: null, updatedAt: null,
  },
  job: {
    id: 'job-1', type: 'generate', status: 'failed', progress: 42, inputRefs: {}, outputRefs: {},
    errorMessage: 'A dependency failed.', attemptCount: 1, maxAttempts: 3, retryAt: null,
    createdAt: null, updatedAt: null, startedAt: null, completedAt: null,
  },
}));

const ready = <T,>(value: T) => ({ data: value, loading: false, error: null });

vi.mock('../contexts/AuthContext', () => ({
  useAuth: () => ({ user: { uid: 'user-1' } }),
}));

vi.mock('../hooks/useFirestore', () => ({
  useCourse: () => ready(data.course),
  useStudyDocument: () => ready(data.document),
  useSummary: () => ready(data.summary),
  useDeck: () => ready(data.deck),
  useCards: () => ready([]),
  useJob: () => ready(data.job),
}));

vi.mock('../lib/api', () => ({
  deckApi: {
    update: vi.fn(), delete: vi.fn(), createCard: vi.fn(), updateCard: vi.fn(), deleteCard: vi.fn(),
  },
}));

import { DeckPage } from '../pages/DeckPage';
import { SummaryPage } from '../pages/SummaryPage';

afterEach(cleanup);

describe('failed async-job precedence', () => {
  it('stops a queued summary when its job has failed', () => {
    render(
      <MemoryRouter initialEntries={['/library/course-1/document/document-1/summary/summary-1']}>
        <Routes>
          <Route path="/library/:courseId/document/:documentId/summary/:summaryId" element={<SummaryPage />} />
        </Routes>
      </MemoryRouter>,
    );

    expect(screen.getByRole('heading', { name: 'Summary generation failed' })).toBeInTheDocument();
    expect(screen.getByText('A dependency failed.')).toBeInTheDocument();
    expect(screen.queryByRole('progressbar')).not.toBeInTheDocument();
  });

  it('marks a queued deck failed and keeps review unavailable when its job fails', () => {
    render(
      <MemoryRouter initialEntries={['/library/course-1/deck/deck-1']}>
        <Routes><Route path="/library/:courseId/deck/:deckId" element={<DeckPage />} /></Routes>
      </MemoryRouter>,
    );

    expect(screen.getByText('Deck generation failed')).toBeInTheDocument();
    expect(screen.getByText('A dependency failed.')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Review from the start' })).toBeDisabled();
  });
});
