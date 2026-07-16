import { useEffect, useMemo, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { ChevronRightIcon, PlusIcon, SearchIcon } from '../components/Icons';
import { CourseFormDialog } from '../components/CourseDialogs';
import {
  Button,
  EmptyState,
  ErrorState,
  LearningTrace,
  LoadingState,
  Meta,
  PageHeader,
  Toast,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useCourses } from '../hooks/useFirestore';
import { courseApi } from '../lib/api';
import { friendlyError } from '../lib/format';
import type { Course } from '../types';

export function filterCourses(courses: Course[], search: string) {
  const query = search.trim().toLocaleLowerCase();
  return query
    ? courses.filter((course) => course.name.toLocaleLowerCase().includes(query))
    : courses;
}

export function LibraryPage() {
  useDocumentTitle('Library');
  const { user } = useAuth();
  const courses = useCourses(user?.uid);
  const location = useLocation();
  const navigate = useNavigate();
  const [search, setSearch] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (location.hash === '#create') setDialogOpen(true);
  }, [location.hash]);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 2600);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const filtered = useMemo(() => {
    return filterCourses(courses.data, search);
  }, [courses.data, search]);

  const create = async (input: { name: string; color: string }) => {
    setBusy(true);
    setError(null);
    try {
      await courseApi.create(input);
      setDialogOpen(false);
      navigate('/library', { replace: true });
      setToast('Course created.');
    } catch (nextError) {
      setError(friendlyError(nextError));
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <PageHeader
        eyebrow="Your material"
        title="Library"
        copy="Courses keep source documents and generated study aids together."
      />
      <LearningTrace className="page-trace" />
      <div className="library-tools">
        <div className="search-field">
          <SearchIcon />
          <label className="sr-only" htmlFor="course-search">Search courses</label>
          <input
            id="course-search"
            type="search"
            placeholder="Search courses"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
          />
          {search && <Button className="search-clear" aria-label="Clear search" onClick={() => setSearch('')}>Clear</Button>}
        </div>
        <Button className="primary" onClick={() => setDialogOpen(true)}><PlusIcon /> Create course</Button>
      </div>
      {courses.loading ? <LoadingState label="Loading courses" /> : courses.error ? (
        <ErrorState message={courses.error.message} />
      ) : filtered.length ? (
        <section className="course-grid" aria-label="Courses">
          {filtered.map((course) => (
            <Link className="panel course-card" to={`/library/${course.id}`} key={course.id}>
              <div>
                <span className="course-color" style={{ '--course': course.color } as React.CSSProperties} />
                <h2>{course.name}</h2>
              </div>
              <div className="course-card-foot">
                <Meta items={[
                  `${course.documentCount} ${course.documentCount === 1 ? 'document' : 'documents'}`,
                  `${course.deckCount} ${course.deckCount === 1 ? 'deck' : 'decks'}`,
                  `${course.quizCount} quizzes · planned, not active`,
                ]} />
                <ChevronRightIcon />
              </div>
            </Link>
          ))}
        </section>
      ) : search ? (
        <EmptyState title="No course found" copy="Try another name or create a new course." action={<Button className="primary" onClick={() => setDialogOpen(true)}>Create course</Button>} />
      ) : (
        <EmptyState title="Create your first course" copy="Courses organize documents, decks, and future study formats." action={<Button className="primary" onClick={() => setDialogOpen(true)}>Create course</Button>} />
      )}
      <CourseFormDialog
        open={dialogOpen}
        busy={busy}
        error={error}
        onClose={() => {
          setDialogOpen(false);
          setError(null);
          if (location.hash) navigate('/library', { replace: true });
        }}
        onSubmit={create}
      />
      <Toast message={toast} />
    </>
  );
}
