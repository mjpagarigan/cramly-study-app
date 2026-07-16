import { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  CardFormDialog,
  DeckFormDialog,
  DeleteResourceDialog,
  type CardFormValue,
} from '../components/DeckDialogs';
import { EditIcon, PlusIcon, RefreshIcon, TrashIcon } from '../components/Icons';
import {
  Badge,
  Button,
  ButtonLink,
  EmptyState,
  ErrorState,
  LearningTrace,
  LoadingState,
  Meta,
  Notice,
  PageHeader,
  Panel,
  Toast,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useCards, useCourse, useDeck, useJob } from '../hooks/useFirestore';
import { deckApi } from '../lib/api';
import { friendlyError, relativeDate } from '../lib/format';
import type { DeckCard } from '../types';

export function DeckPage() {
  const { courseId, deckId } = useParams();
  const { user } = useAuth();
  const navigate = useNavigate();
  const deckState = useDeck(user?.uid, deckId);
  const cards = useCards(user?.uid, deckId);
  const courseState = useCourse(user?.uid, courseId);
  const deck = deckState.data;
  const [jobRetry, setJobRetry] = useState(0);
  const job = useJob(user?.uid, deck?.jobId ?? undefined, jobRetry);
  useDocumentTitle(deck?.title || 'Deck');
  const [deckEditOpen, setDeckEditOpen] = useState(false);
  const [deckDeleteOpen, setDeckDeleteOpen] = useState(false);
  const [cardOpen, setCardOpen] = useState(false);
  const [selectedCard, setSelectedCard] = useState<DeckCard | null>(null);
  const [deleteCard, setDeleteCard] = useState<DeckCard | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 2500);
    return () => window.clearTimeout(timer);
  }, [toast]);

  if (deckState.loading || cards.loading || courseState.loading) return <LoadingState label="Loading deck" />;
  if (deckState.error || cards.error || courseState.error) return <ErrorState message={(deckState.error || cards.error || courseState.error)?.message} />;
  if (!deck) return <ErrorState title="Deck not found" message="This deck may have been deleted." />;

  const updateDeck = async (input: { title: string; description?: string }) => {
    setBusy(true); setError(null);
    try {
      await deckApi.update(deck.id, input);
      setDeckEditOpen(false); setToast('Deck updated.');
    } catch (nextError) { setError(friendlyError(nextError)); }
    finally { setBusy(false); }
  };
  const removeDeck = async () => {
    setBusy(true); setError(null);
    try {
      await deckApi.delete(deck.id);
      navigate(`/library/${courseId}`, { replace: true });
    } catch (nextError) { setError(friendlyError(nextError)); setBusy(false); }
  };
  const saveCard = async (input: CardFormValue) => {
    setBusy(true); setError(null);
    try {
      if (selectedCard) await deckApi.updateCard(deck.id, selectedCard.id, input);
      else await deckApi.createCard(deck.id, input);
      setCardOpen(false); setSelectedCard(null); setToast(selectedCard ? 'Card updated.' : 'Card added.');
    } catch (nextError) { setError(friendlyError(nextError)); }
    finally { setBusy(false); }
  };
  const removeCard = async () => {
    if (!deleteCard) return;
    setBusy(true); setError(null);
    try {
      await deckApi.deleteCard(deck.id, deleteCard.id);
      setDeleteCard(null); setToast('Card deleted.');
    } catch (nextError) { setError(friendlyError(nextError)); }
    finally { setBusy(false); }
  };

  const canReview = deck.status === 'ready' && cards.data.length > 0;
  const generationFailed = deck.status === 'failed'
    || (deck.status !== 'ready' && (job.data?.status === 'failed' || Boolean(job.error)));
  const generationError = deck.errorMessage
    || job.data?.errorMessage
    || job.error?.message
    || 'The generated deck could not be completed.';
  return (
    <>
      <PageHeader
        eyebrow={deck.generationMethod === 'ai' ? 'AI-generated deck' : 'Manual deck'}
        title={deck.title}
        copy={<Meta items={[courseState.data?.name, `${cards.data.length} cards`, relativeDate(deck.createdAt)]} />}
        actions={(
          <>
            <Button className="secondary" onClick={() => setDeckEditOpen(true)}><EditIcon /> Edit deck</Button>
            <Button className="secondary" onClick={() => { setSelectedCard(null); setCardOpen(true); }}><PlusIcon /> Add card</Button>
            {canReview
              ? <ButtonLink className="primary" to={`/library/${courseId}/deck/${deck.id}/review`}>Review from the start</ButtonLink>
              : <Button className="primary" disabled>Review from the start</Button>}
          </>
        )}
      />
      <Panel className="deck-summary">
        <div>
          <Badge tone={deck.status === 'ready' ? 'success' : generationFailed ? 'danger' : 'warning'}>{generationFailed ? 'failed' : deck.status}</Badge>
          <h2>{cards.data.length} {cards.data.length === 1 ? 'card' : 'cards'}</h2>
          <p>{deck.description || 'Cards are reviewed in creation order. Confidence ratings and scheduling are not active.'}</p>
        </div>
        <LearningTrace />
      </Panel>
      {generationFailed && (
        <Notice title="Deck generation failed" tone="danger">
          <span>{generationError}</span>
          {job.error && <Button className="secondary compact" onClick={() => setJobRetry((value) => value + 1)}><RefreshIcon /> Retry status</Button>}
        </Notice>
      )}
      <div className="section-head">
        <h2>Cards</h2>
        <div className="header-actions"><span className="helper">Front and back are required</span><Button className="danger compact" onClick={() => setDeckDeleteOpen(true)}><TrashIcon /> Delete deck</Button></div>
      </div>
      {cards.data.length ? (
        <section className="card-grid" aria-label="Cards">
          {cards.data.map((card, index) => (
            <Panel className="flashcard-row" key={card.id}>
              <div className="card-row-head"><span className="card-number">Card {String(index + 1).padStart(2, '0')}</span>{card.topic && <span className="topic-label">{card.topic}</span>}</div>
              <h3>{card.front}</h3>
              <p className="card-back">{card.back}</p>
              {(card.hint || card.explanation) && (
                <dl className="card-details">
                  {card.hint && <><dt>Hint</dt><dd>{card.hint}</dd></>}
                  {card.explanation && <><dt>Explanation</dt><dd>{card.explanation}</dd></>}
                </dl>
              )}
              <div className="card-actions">
                <Button className="secondary compact" onClick={() => { setSelectedCard(card); setCardOpen(true); }}><EditIcon /> Edit</Button>
                <Button className="danger compact" onClick={() => setDeleteCard(card)}><TrashIcon /> Delete</Button>
              </div>
            </Panel>
          ))}
        </section>
      ) : (
        <EmptyState title="This deck has no cards" copy="Add a front-and-back card to make the deck reviewable." action={<Button className="primary" onClick={() => { setSelectedCard(null); setCardOpen(true); }}>Add first card</Button>} />
      )}
      <DeckFormDialog open={deckEditOpen} deck={deck} busy={busy} error={error} onClose={() => { setDeckEditOpen(false); setError(null); }} onSubmit={updateDeck} />
      <CardFormDialog open={cardOpen} card={selectedCard} busy={busy} error={error} onClose={() => { setCardOpen(false); setSelectedCard(null); setError(null); }} onSubmit={saveCard} />
      <DeleteResourceDialog open={deckDeleteOpen} title="Delete deck and cards?" resourceName={deck.title} copy="The deck and every card inside it will be permanently deleted." busy={busy} error={error} onClose={() => { setDeckDeleteOpen(false); setError(null); }} onConfirm={removeDeck} />
      <DeleteResourceDialog open={Boolean(deleteCard)} title="Delete this card?" resourceName={deleteCard?.front ?? ''} copy="This card will be removed from the deck." busy={busy} error={error} onClose={() => { setDeleteCard(null); setError(null); }} onConfirm={removeCard} />
      <Toast message={toast} />
    </>
  );
}
