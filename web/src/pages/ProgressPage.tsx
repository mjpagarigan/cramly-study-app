import {
  ErrorState,
  LearningTrace,
  LoadingState,
  PageHeader,
  Panel,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useAllDecks, useAllSummaries } from '../hooks/useFirestore';

export function ProgressPage() {
  useDocumentTitle('Progress');
  const { user } = useAuth();
  const decks = useAllDecks(user?.uid);
  const summaries = useAllSummaries(user?.uid);
  if (decks.loading || summaries.loading) return <LoadingState label="Loading progress status" />;
  if (decks.error || summaries.error) return <ErrorState message={(decks.error || summaries.error)?.message} />;
  return (
    <>
      <PageHeader eyebrow="Learning history" title="Progress" />
      <Panel className="progress-empty">
        <div>
          <LearningTrace />
          <h2>Your learning trace starts here.</h2>
          <p>Session analytics and mastery trends are planned. Current activity is shown without invented progress scores.</p>
          <div className="facts">
            <Panel className="fact"><strong>{decks.data.length}</strong><span>Decks created</span></Panel>
            <Panel className="fact"><strong>{summaries.data.length}</strong><span>Summaries generated</span></Panel>
            <Panel className="fact"><strong>Not active</strong><span>Tracked review sessions</span></Panel>
          </div>
        </div>
      </Panel>
    </>
  );
}
