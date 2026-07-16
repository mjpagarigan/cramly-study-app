import { useEffect, useRef, useState, type KeyboardEvent } from 'react';
import { useParams } from 'react-router-dom';
import { ArrowLeftIcon, ArrowRightIcon } from '../components/Icons';
import {
  Button,
  ButtonLink,
  ErrorState,
  LearningTrace,
  LoadingState,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useCards, useDeck } from '../hooks/useFirestore';

export function ReviewPage() {
  const { courseId, deckId } = useParams();
  const { user } = useAuth();
  const deckState = useDeck(user?.uid, deckId);
  const cards = useCards(user?.uid, deckId);
  const deck = deckState.data;
  useDocumentTitle(deck ? `Review ${deck.title}` : 'Review');
  const [index, setIndex] = useState(0);
  const [revealed, setRevealed] = useState(false);
  const [hintVisible, setHintVisible] = useState(false);
  const [complete, setComplete] = useState(false);
  const completionHeadingRef = useRef<HTMLHeadingElement>(null);
  const cardRef = useRef<HTMLElement>(null);
  const completedOnce = useRef(false);

  useEffect(() => {
    if (index >= cards.data.length && cards.data.length) setIndex(cards.data.length - 1);
  }, [cards.data.length, index]);

  useEffect(() => {
    if (complete) {
      completedOnce.current = true;
      completionHeadingRef.current?.focus();
    } else if (completedOnce.current) {
      cardRef.current?.focus();
    }
  }, [complete]);

  if (deckState.loading || cards.loading) return <LoadingState label="Loading review cards" />;
  if (deckState.error || cards.error) return <ErrorState message={(deckState.error || cards.error)?.message} />;
  if (!deck) return <ErrorState title="Deck not found" message="Exit review and choose another deck." />;
  if (deck.status !== 'ready') {
    return (
      <main className="review-empty">
        <ErrorState title="This deck is not ready" message="Only ready decks can start a review." />
        <ButtonLink className="secondary" to={`/library/${courseId}/deck/${deck.id}`}>Back to deck</ButtonLink>
      </main>
    );
  }
  if (!cards.data.length) {
    return (
      <main className="review-empty">
        <ErrorState title="No cards to review" message="Add at least one card before starting a review." />
        <ButtonLink className="secondary" to={`/library/${courseId}/deck/${deck.id}`}>Back to deck</ButtonLink>
      </main>
    );
  }
  const card = cards.data[index];
  const resetCard = (nextIndex: number) => {
    setIndex(nextIndex);
    setRevealed(false);
    setHintVisible(false);
  };
  const next = () => {
    if (!revealed) return;
    if (index === cards.data.length - 1) setComplete(true);
    else resetCard(index + 1);
  };
  const toggle = () => setRevealed((value) => !value);
  const cardKey = (event: KeyboardEvent<HTMLElement>) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      toggle();
    }
  };

  if (complete) {
    return (
      <main className="review-complete">
        <div>
          <LearningTrace />
          <h1 ref={completionHeadingRef} tabIndex={-1}>{cards.data.length} {cards.data.length === 1 ? 'card' : 'cards'} reviewed.</h1>
          <p>This basic review does not rate confidence or schedule the next session yet.</p>
          <div className="header-actions">
            <Button className="secondary-on-dark" onClick={() => { setComplete(false); resetCard(0); }}>Review again</Button>
            <ButtonLink className="light" to="/study">Back to Study</ButtonLink>
          </div>
        </div>
      </main>
    );
  }

  return (
    <main className="review-page">
      <header className="review-head">
        <ButtonLink className="secondary" to={`/library/${courseId}/deck/${deck.id}`}><ArrowLeftIcon /> Exit review</ButtonLink>
        <div className="review-count"><strong>{index + 1} of {cards.data.length}</strong><span>{deck.title}</span></div>
        <Button className="secondary" disabled={!card.hint} aria-pressed={hintVisible} onClick={() => setHintVisible((value) => !value)}>{hintVisible ? 'Hide hint' : 'Show hint'}</Button>
      </header>
      <LearningTrace className="review-trace" />
      <article ref={cardRef} className={`review-card ${revealed ? 'revealed' : ''}`} role="button" tabIndex={0} aria-label={revealed ? 'Hide answer' : 'Reveal answer'} onClick={toggle} onKeyDown={cardKey}>
        <section className="question-side">
          {card.topic && <span className="topic-label">{card.topic}</span>}
          <h1>{card.front}</h1>
          {hintVisible && card.hint && <p className="hint-copy">{card.hint}</p>}
          <span className="review-affordance">{revealed ? 'Click to hide answer' : 'Click to reveal answer'}</span>
        </section>
        <section className="answer-side" aria-hidden={!revealed}>
          <p className="eyebrow">Answer</p>
          <h2>{card.back}</h2>
          {card.explanation && <div className="answer-explanation"><strong>Why</strong><p>{card.explanation}</p></div>}
        </section>
      </article>
      <footer className="review-foot">
        <Button className="secondary" disabled={index === 0} onClick={() => resetCard(index - 1)}><ArrowLeftIcon /> Previous</Button>
        <Button className="primary" onClick={toggle}>{revealed ? 'Hide answer' : 'Reveal answer'}</Button>
        <Button className="primary" disabled={!revealed} onClick={next}>{index === cards.data.length - 1 ? 'Finish' : 'Next'} <ArrowRightIcon /></Button>
      </footer>
    </main>
  );
}
