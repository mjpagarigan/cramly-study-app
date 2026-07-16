import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { CourseFormDialog, DeleteCourseDialog } from '../components/CourseDialogs';
import { DeckFormDialog } from '../components/DeckDialogs';
import { ChevronRightIcon, EditIcon, PlusIcon, TrashIcon, UploadIcon } from '../components/Icons';
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
  Tabs,
  Toast,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useCourse, useDecks, useDocuments } from '../hooks/useFirestore';
import { courseApi, deckApi } from '../lib/api';
import { documentMeta, friendlyError, relativeDate } from '../lib/format';

export function CoursePage() {
  const { courseId } = useParams();
  const { user } = useAuth();
  const courseState = useCourse(user?.uid, courseId);
  const documents = useDocuments(user?.uid, courseId);
  const decks = useDecks(user?.uid, courseId);
  const course = courseState.data;
  useDocumentTitle(course?.name || 'Course');
  const navigate = useNavigate();
  const [tab, setTab] = useState('documents');
  const [editOpen, setEditOpen] = useState(false);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deckOpen, setDeckOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 2500);
    return () => window.clearTimeout(timer);
  }, [toast]);

  if (courseState.loading || documents.loading || decks.loading) return <LoadingState label="Loading course" />;
  if (courseState.error || documents.error || decks.error) {
    return <ErrorState message={(courseState.error || documents.error || decks.error)?.message} />;
  }
  if (!course) return <ErrorState title="Course not found" message="This course may have been deleted." />;
  const documentCount = `${documents.data.length} ${documents.data.length === 1 ? 'document' : 'documents'}`;
  const deckCount = `${decks.data.length} ${decks.data.length === 1 ? 'deck' : 'decks'}`;

  const saveCourse = async (input: { name: string; color: string }) => {
    setBusy(true);
    setActionError(null);
    try {
      await courseApi.update(course.id, input);
      setEditOpen(false);
      setToast('Course updated.');
    } catch (error) {
      setActionError(friendlyError(error));
    } finally { setBusy(false); }
  };
  const deleteCourse = async () => {
    setBusy(true);
    setActionError(null);
    try {
      await courseApi.delete(course.id);
      navigate('/library', { replace: true });
    } catch (error) {
      setActionError(friendlyError(error));
      setBusy(false);
    }
  };
  const createDeck = async (input: { title: string; description?: string }) => {
    setBusy(true);
    setActionError(null);
    try {
      const deck = await deckApi.create({ courseId: course.id, ...input });
      setDeckOpen(false);
      navigate(`/library/${course.id}/deck/${deck.id}`);
    } catch (error) {
      setActionError(friendlyError(error));
    } finally { setBusy(false); }
  };

  return (
    <>
      <PageHeader
        eyebrow="Course"
        title={course.name}
        copy={`${documentCount}, ${deckCount}`}
        actions={(
          <>
            <Button className="secondary" onClick={() => setEditOpen(true)}><EditIcon /> Edit course</Button>
            <Button className="danger" onClick={() => setDeleteOpen(true)}><TrashIcon /> Delete record</Button>
          </>
        )}
      />
      <div className="grid-12 course-lead">
        <Panel className="span-8 course-summary">
          <span className="course-color" style={{ '--course': course.color } as React.CSSProperties} />
          <h2>{course.name}</h2>
          <Meta items={[documentCount, deckCount]} />
          <LearningTrace />
        </Panel>
        <aside className="span-4 course-actions">
          <ButtonLink className="primary" to={`/upload?courseId=${course.id}`}><UploadIcon /> Add material</ButtonLink>
          <Button className="secondary" onClick={() => setDeckOpen(true)}><PlusIcon /> Create manual deck</Button>
          <Notice title="Deletion behavior">
            Deleting a course removes only the course record. Materials must be removed separately.
          </Notice>
        </aside>
      </div>
      <div className="section-head"><h2>Course material</h2></div>
      <Tabs
        label="Course material"
        active={tab}
        onChange={setTab}
        tabs={[
          { id: 'documents', label: `Documents (${documents.data.length})` },
          { id: 'decks', label: `Decks (${decks.data.length})` },
          { id: 'quizzes', label: 'Quizzes · Planned', disabled: true },
          { id: 'podcasts', label: 'Podcasts · Planned', disabled: true },
        ]}
      />
      <section className="tab-panel" role="tabpanel" id={`panel-${tab}`} aria-labelledby={`tab-${tab}`}>
        {tab === 'documents' && (documents.data.length ? (
          <div className="resource-list">
            {documents.data.map((document) => (
              <Link className="list-row" key={document.id} to={`/library/${course.id}/document/${document.id}`}>
                <span className="row-mark">{document.sourceType === 'web_url' ? 'WEB' : document.sourceType.toUpperCase()}</span>
                <span><strong>{document.title}</strong><small>{documentMeta(document).join(' / ')}</small></span>
                <Badge tone={document.status === 'ready' ? 'success' : document.status === 'failed' ? 'danger' : 'warning'}>{document.status}</Badge>
              </Link>
            ))}
          </div>
        ) : <EmptyState title="No documents yet" copy="Add a file, recording, YouTube video, or public article." action={<ButtonLink className="primary" to={`/upload?courseId=${course.id}`}>Add material</ButtonLink>} />)}
        {tab === 'decks' && (decks.data.length ? (
          <div className="resource-list">
            {decks.data.map((deck) => (
              <Link className="list-row" key={deck.id} to={`/library/${course.id}/deck/${deck.id}`}>
                <span className="row-mark">{deck.cardCount}</span>
                <span><strong>{deck.title}</strong><small>{deck.generationMethod === 'ai' ? 'AI-generated' : 'Manual'} / {relativeDate(deck.updatedAt)}</small></span>
                {deck.status === 'ready' ? <ChevronRightIcon className="chevron" /> : <Badge tone={deck.status === 'failed' ? 'danger' : 'warning'}>{deck.status}</Badge>}
              </Link>
            ))}
          </div>
        ) : <EmptyState title="No decks yet" copy="Create cards manually or generate a deck from a ready document." action={<Button className="primary" onClick={() => setDeckOpen(true)}>Create manual deck</Button>} />)}
        {tab === 'quizzes' && <EmptyState title="Quizzes are planned" copy="Quiz creation and exams are not active in this build." action={<Badge tone="planned">Planned</Badge>} />}
        {tab === 'podcasts' && <EmptyState title="Podcasts are planned" copy="Audio study episodes are not generated in this build." action={<Badge tone="planned">Planned</Badge>} />}
      </section>
      <CourseFormDialog open={editOpen} course={course} busy={busy} error={actionError} onClose={() => { setEditOpen(false); setActionError(null); }} onSubmit={saveCourse} />
      <DeleteCourseDialog open={deleteOpen} course={course} busy={busy} error={actionError} onClose={() => { setDeleteOpen(false); setActionError(null); }} onConfirm={deleteCourse} />
      <DeckFormDialog open={deckOpen} busy={busy} error={actionError} onClose={() => { setDeckOpen(false); setActionError(null); }} onSubmit={createDeck} />
      <Toast message={toast} />
    </>
  );
}
