import { Link } from 'react-router-dom';
import { ChevronRightIcon } from '../components/Icons';
import {
  Badge,
  ButtonLink,
  EmptyState,
  ErrorState,
  LearningTrace,
  LoadingState,
  Meta,
  Notice,
  PageHeader,
  Panel,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useAllDecks, useCourses } from '../hooks/useFirestore';
import { relativeDate } from '../lib/format';

export function StudyPage() {
  useDocumentTitle('Study');
  const { user } = useAuth();
  const decks = useAllDecks(user?.uid);
  const courses = useCourses(user?.uid);
  const featured = decks.data.find((deck) => deck.status === 'ready' && deck.cardCount > 0);
  if (decks.loading || courses.loading) return <LoadingState label="Loading study decks" />;
  if (decks.error || courses.error) return <ErrorState message={(decks.error || courses.error)?.message} />;
  return (
    <>
      <PageHeader eyebrow="Choose a deck" title="Study" copy="Review saved cards in their creation order." />
      {featured ? (
        <div className="grid-12 study-lead">
          <Panel className="span-7 hero-panel">
            <div><LearningTrace /><h2>{featured.title}</h2><p>{featured.cardCount} cards from {courses.data.find((course) => course.id === featured.courseId)?.name || 'your library'}.</p></div>
            <ButtonLink className="light" to={`/library/${featured.courseId}/deck/${featured.id}/review`}>Review deck</ButtonLink>
          </Panel>
          <Notice title="Adaptive daily review is planned">Spaced-repetition ratings, due queues, quizzes, voice quiz, and study guides are not active in this build.</Notice>
        </div>
      ) : (
        <Panel className="study-empty-trace"><LearningTrace /><EmptyState title="No reviewable deck yet" copy="Ready decks with at least one card appear here." action={<ButtonLink className="primary" to="/library">Open Library</ButtonLink>} /></Panel>
      )}
      <div className="section-head"><h2>Your decks</h2><Link to="/library">Open Library</Link></div>
      {decks.data.length ? (
        <section className="deck-grid" aria-label="Your decks">
          {decks.data.map((deck) => {
            const canReview = deck.status === 'ready' && deck.cardCount > 0;
            return (
              <Panel className="deck-card" key={deck.id}>
                <div className="deck-card-head"><Badge tone={deck.status === 'ready' ? 'success' : deck.status === 'failed' ? 'danger' : 'warning'}>{deck.status}</Badge><span>{relativeDate(deck.updatedAt)}</span></div>
                <h2>{deck.title}</h2>
                <p>{deck.description || `${deck.generationMethod === 'ai' ? 'AI-generated' : 'Manual'} deck in ${courses.data.find((course) => course.id === deck.courseId)?.name || 'your library'}.`}</p>
                <Meta items={[deck.generationMethod === 'ai' ? 'AI-generated' : 'Manual', `${deck.cardCount} cards`]} />
                <div className="deck-card-actions">
                  <ButtonLink className="secondary" to={`/library/${deck.courseId}/deck/${deck.id}`}>Manage cards</ButtonLink>
                  {canReview ? <ButtonLink className="primary" to={`/library/${deck.courseId}/deck/${deck.id}/review`}>Review <ChevronRightIcon /></ButtonLink> : <Badge tone="planned">Not reviewable</Badge>}
                </div>
              </Panel>
            );
          })}
        </section>
      ) : !featured ? null : <EmptyState title="No saved decks" copy="Create a manual deck or generate one from a document." />}
    </>
  );
}
