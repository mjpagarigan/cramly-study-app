import { render, screen, within } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { describe, expect, it, vi } from 'vitest';
import type { Deck, DeckCard } from '../types';

const deck: Deck = {
  id: 'deck-1',
  courseId: 'course-1',
  title: 'Respiration',
  description: '',
  cardCount: 2,
  generationMethod: 'manual',
  status: 'ready',
  createdAt: null,
  updatedAt: null,
};

const baseCard = {
  hint: null,
  explanation: null,
  topic: null,
  srs: { easeFactor: 2.5, interval: 0, repetitions: 0, nextReviewDate: null, lastReviewedAt: null },
  stats: { timesShown: 0, timesCorrect: 0, timesWrong: 0 },
  createdAt: null,
};

const cards: DeckCard[] = [
  { ...baseCard, id: 'card-1', front: 'First question?', back: 'First answer.' },
  { ...baseCard, id: 'card-2', front: 'Second question?', back: 'Second answer.' },
];

vi.mock('../contexts/AuthContext', () => ({
  useAuth: () => ({ user: { uid: 'user-1' } }),
}));

vi.mock('../hooks/useFirestore', () => ({
  useDeck: () => ({ data: deck, loading: false, error: null }),
  useCards: () => ({ data: cards, loading: false, error: null }),
}));

import { ReviewPage } from '../pages/ReviewPage';

describe('ReviewPage', () => {
  it('reveals cards linearly and completes without writing review data', async () => {
    const user = userEvent.setup();
    render(
      <MemoryRouter initialEntries={['/library/course-1/deck/deck-1/review']}>
        <Routes><Route path="/library/:courseId/deck/:deckId/review" element={<ReviewPage />} /></Routes>
      </MemoryRouter>,
    );
    const controls = within(document.querySelector('.review-foot')!);
    expect(screen.getByRole('heading', { name: 'First question?' })).toBeInTheDocument();
    await user.click(controls.getByRole('button', { name: 'Reveal answer' }));
    expect(screen.getByText('First answer.')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Next' }));
    expect(screen.getByRole('heading', { name: 'Second question?' })).toBeInTheDocument();
    await user.click(controls.getByRole('button', { name: 'Reveal answer' }));
    await user.click(screen.getByRole('button', { name: 'Finish' }));
    expect(screen.getByRole('heading', { name: '2 cards reviewed.' })).toBeInTheDocument();
  });
});
