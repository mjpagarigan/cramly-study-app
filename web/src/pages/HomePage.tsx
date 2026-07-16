import { Link } from 'react-router-dom';
import { ChevronRightIcon, PlusIcon, UploadIcon } from '../components/Icons';
import {
  ButtonLink,
  EmptyState,
  ErrorState,
  LearningTrace,
  LoadingState,
  Meta,
  PageHeader,
  Panel,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useAllDecks, useAllDocuments, useAllSummaries, useCourses } from '../hooks/useFirestore';
import { displayName, greeting, longDate, relativeDate } from '../lib/format';

export function HomePage() {
  useDocumentTitle('Home');
  const { user } = useAuth();
  const courses = useCourses(user?.uid);
  const documents = useAllDocuments(user?.uid);
  const decks = useAllDecks(user?.uid);
  const summaries = useAllSummaries(user?.uid);
  const loading = courses.loading || documents.loading || decks.loading || summaries.loading;
  const error = courses.error || documents.error || decks.error || summaries.error;
  const readyDocument = documents.data.find((item) => item.status === 'ready');
  const latestCourse = courses.data[0];

  const nextStep = readyDocument
    ? {
      title: `Continue ${courses.data.find((item) => item.id === readyDocument.courseId)?.name || readyDocument.title}`,
      copy: 'Your document is ready. Create flashcards or read a focused summary.',
      label: 'Open document',
      to: `/library/${readyDocument.courseId}/document/${readyDocument.id}`,
    }
    : latestCourse
      ? {
        title: `Add material to ${latestCourse.name}`,
        copy: 'Upload a source to start building your study library.',
        label: 'Add material',
        to: `/upload?courseId=${latestCourse.id}`,
      }
      : {
        title: 'Start your first course',
        copy: 'Create one place for source material, flashcards, and summaries.',
        label: 'Create a course',
        to: '/library#create',
      };

  const recent = [
    ...courses.data.map((item) => ({
      id: `course-${item.id}`,
      title: item.name,
      type: 'Course',
      date: item.updatedAt,
      to: `/library/${item.id}`,
      mark: <span className="course-color" style={{ '--course': item.color } as React.CSSProperties} />,
    })),
    ...decks.data.map((item) => ({
      id: `deck-${item.id}`,
      title: item.title,
      type: `${item.cardCount} cards`,
      date: item.updatedAt,
      to: `/library/${item.courseId}/deck/${item.id}`,
      mark: <span className="row-mark">{item.cardCount}</span>,
    })),
    ...summaries.data.map((item) => ({
      id: `summary-${item.id}`,
      title: 'Generated summary',
      type: item.depth === 'tldr' ? 'TL;DR' : item.depth === 'eli5' ? 'ELI5' : 'Detailed',
      date: item.updatedAt,
      to: `/library/${item.courseId}/document/${item.sourceDocumentId}/summary/${item.id}`,
      mark: <span className="row-mark">S</span>,
    })),
  ]
    .sort((a, b) => (b.date?.getTime() ?? 0) - (a.date?.getTime() ?? 0))
    .slice(0, 4);

  return (
    <>
      <PageHeader
        eyebrow={longDate()}
        title={`${greeting()}, ${displayName(user)}.`}
        copy="Continue from your latest material or add something new."
        actions={(
          <>
            <ButtonLink className="secondary" to="/library#create"><PlusIcon /> Create course</ButtonLink>
            <ButtonLink className="primary" to="/upload"><UploadIcon /> Upload material</ButtonLink>
          </>
        )}
      />
      {loading ? <LoadingState /> : error ? <ErrorState message={error.message} /> : (
        <>
          <div className="grid-12 home-lead">
            <Panel className="span-8 hero-panel">
              <div>
                <LearningTrace />
                <h2>{nextStep.title}</h2>
                <p>{nextStep.copy}</p>
              </div>
              <ButtonLink className="light" to={nextStep.to}>{nextStep.label}</ButtonLink>
            </Panel>
            <aside className="span-4 home-status">
              <div className="stat-row">
                <Panel className="stat"><strong>0</strong><span>Current streak</span></Panel>
                <Panel className="stat"><strong>0</strong><span>Cards due</span></Panel>
              </div>
              <Panel className="activity-panel">
                <h2>Study status</h2>
                <p>Adaptive scheduling and tracked sessions are not active yet.</p>
                <Link className="text-action" to="/progress">View progress status</Link>
              </Panel>
            </aside>
          </div>
          <div className="grid-12 home-followup">
            <section className="span-7">
              <div className="section-head"><h2>Recent work</h2><Link to="/library">Open library</Link></div>
              {recent.length ? (
                <div className="resource-list">
                  {recent.map((item) => (
                    <Link className="list-row" to={item.to} key={item.id}>
                      {item.mark}
                      <span><strong>{item.title}</strong><small>{item.type} / {relativeDate(item.date)}</small></span>
                      <ChevronRightIcon className="chevron" />
                    </Link>
                  ))}
                </div>
              ) : (
                <EmptyState title="Nothing here yet" copy="Create a course or upload material to begin." />
              )}
            </section>
            <section className="span-5">
              <div className="section-head"><h2>Quick actions</h2></div>
              <div className="quick-actions">
                <Link className="panel quick-action" to="/upload">
                  <UploadIcon /><div><strong>Upload material</strong><p>Files, audio, YouTube, or a public web page.</p></div><span>Choose a source</span>
                </Link>
                <Link className="panel quick-action" to="/library#create">
                  <PlusIcon /><div><strong>Create a course</strong><p>Group documents, decks, and future quizzes.</p></div><span>Create course</span>
                </Link>
              </div>
              <Meta items={[`${courses.data.length} courses`, `${documents.data.length} documents`]} />
            </section>
          </div>
        </>
      )}
    </>
  );
}
