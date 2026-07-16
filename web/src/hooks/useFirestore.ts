import {
  collection,
  doc,
  onSnapshot,
  orderBy,
  query,
  where,
  type DocumentData,
  type DocumentReference,
  type Query,
} from 'firebase/firestore';
import { useEffect, useState } from 'react';
import type {
  AsyncJob,
  Course,
  Deck,
  DeckCard,
  Document,
  ResourceState,
  Summary,
} from '../types';
import {
  adaptCard,
  adaptCourse,
  adaptDeck,
  adaptDocument,
  adaptJob,
  adaptSummary,
  type SnapshotLike,
} from '../lib/adapters';
import { db } from '../lib/firebase';
import {
  demoCards,
  demoCourses,
  demoDecks,
  demoDocuments,
  demoJobs,
  demoMode,
  demoSummaries,
} from '../lib/demo';

type Adapter<T> = (id: string, raw: Record<string, unknown>) => T;

function emptyList<T>(): ResourceState<T[]> {
  return { data: [], loading: true, error: null };
}

function useQueryResource<T>(
  enabled: boolean,
  buildQuery: () => Query<DocumentData>,
  adapter: Adapter<T>,
  dependencies: readonly unknown[],
): ResourceState<T[]> {
  const [state, setState] = useState<ResourceState<T[]>>(emptyList);

  useEffect(() => {
    if (!enabled) {
      setState({ data: [], loading: false, error: null });
      return;
    }
    setState((current) => ({ ...current, loading: true, error: null }));
    const unsubscribe = onSnapshot(
      buildQuery(),
      (snapshot) => {
        setState({
          data: snapshot.docs.map((item) => {
            const raw = (item as SnapshotLike).data() ?? {};
            return adapter(item.id, raw);
          }),
          loading: false,
          error: null,
        });
      },
      (error) => setState({ data: [], loading: false, error }),
    );
    return unsubscribe;
  }, dependencies);

  return state;
}

function useDocumentResource<T>(
  enabled: boolean,
  buildReference: () => DocumentReference<DocumentData>,
  adapter: Adapter<T>,
  dependencies: readonly unknown[],
): ResourceState<T | null> {
  const [state, setState] = useState<ResourceState<T | null>>({
    data: null,
    loading: true,
    error: null,
  });

  useEffect(() => {
    if (!enabled) {
      setState({ data: null, loading: false, error: null });
      return;
    }
    setState((current) => ({ ...current, loading: true, error: null }));
    const unsubscribe = onSnapshot(
      buildReference(),
      (snapshot) => setState({
        data: snapshot.exists()
          ? adapter(snapshot.id, ((snapshot as SnapshotLike).data() ?? {}))
          : null,
        loading: false,
        error: null,
      }),
      (error) => setState({ data: null, loading: false, error }),
    );
    return unsubscribe;
  }, dependencies);

  return state;
}

export function useCourses(uid?: string): ResourceState<Course[]> {
  const live = useQueryResource(
    Boolean(uid) && !demoMode,
    () => query(collection(db, 'users', uid!, 'courses'), orderBy('updatedAt', 'desc')),
    adaptCourse,
    [uid],
  );
  return demoMode ? { data: demoCourses, loading: false, error: null } : live;
}

export function useCourse(uid?: string, courseId?: string): ResourceState<Course | null> {
  const live = useDocumentResource(
    Boolean(uid && courseId) && !demoMode,
    () => doc(db, 'users', uid!, 'courses', courseId!),
    adaptCourse,
    [uid, courseId],
  );
  return demoMode ? { data: demoCourses.find((item) => item.id === courseId) ?? null, loading: false, error: null } : live;
}

export function useAllDocuments(uid?: string): ResourceState<Document[]> {
  const live = useQueryResource(
    Boolean(uid) && !demoMode,
    () => query(collection(db, 'users', uid!, 'documents'), orderBy('uploadedAt', 'desc')),
    adaptDocument,
    [uid],
  );
  return demoMode ? { data: demoDocuments, loading: false, error: null } : live;
}

export function useDocuments(uid?: string, courseId?: string): ResourceState<Document[]> {
  const live = useQueryResource(
    Boolean(uid && courseId) && !demoMode,
    () => query(
      collection(db, 'users', uid!, 'documents'),
      where('courseId', '==', courseId),
      orderBy('uploadedAt', 'desc'),
    ),
    adaptDocument,
    [uid, courseId],
  );
  return demoMode ? { data: demoDocuments.filter((item) => item.courseId === courseId), loading: false, error: null } : live;
}

export function useStudyDocument(uid?: string, documentId?: string, refreshKey = 0): ResourceState<Document | null> {
  const live = useDocumentResource(
    Boolean(uid && documentId) && !demoMode,
    () => doc(db, 'users', uid!, 'documents', documentId!),
    adaptDocument,
    [uid, documentId, refreshKey],
  );
  return demoMode ? { data: demoDocuments.find((item) => item.id === documentId) ?? null, loading: false, error: null } : live;
}

export function useAllDecks(uid?: string): ResourceState<Deck[]> {
  const live = useQueryResource(
    Boolean(uid) && !demoMode,
    () => query(collection(db, 'users', uid!, 'decks'), orderBy('updatedAt', 'desc')),
    adaptDeck,
    [uid],
  );
  return demoMode ? { data: demoDecks, loading: false, error: null } : live;
}

export function useDecks(uid?: string, courseId?: string): ResourceState<Deck[]> {
  const live = useQueryResource(
    Boolean(uid && courseId) && !demoMode,
    () => query(
      collection(db, 'users', uid!, 'decks'),
      where('courseId', '==', courseId),
      orderBy('updatedAt', 'desc'),
    ),
    adaptDeck,
    [uid, courseId],
  );
  return demoMode ? { data: demoDecks.filter((item) => item.courseId === courseId), loading: false, error: null } : live;
}

export function useDeck(uid?: string, deckId?: string): ResourceState<Deck | null> {
  const live = useDocumentResource(
    Boolean(uid && deckId) && !demoMode,
    () => doc(db, 'users', uid!, 'decks', deckId!),
    adaptDeck,
    [uid, deckId],
  );
  return demoMode ? { data: demoDecks.find((item) => item.id === deckId) ?? null, loading: false, error: null } : live;
}

export function useCards(uid?: string, deckId?: string): ResourceState<DeckCard[]> {
  const live = useQueryResource(
    Boolean(uid && deckId) && !demoMode,
    () => query(
      collection(db, 'users', uid!, 'decks', deckId!, 'cards'),
      orderBy('createdAt', 'asc'),
    ),
    adaptCard,
    [uid, deckId],
  );
  return demoMode ? { data: demoCards[deckId ?? ''] ?? [], loading: false, error: null } : live;
}

export function useAllSummaries(uid?: string): ResourceState<Summary[]> {
  const live = useQueryResource(
    Boolean(uid) && !demoMode,
    () => query(collection(db, 'users', uid!, 'summaries'), orderBy('updatedAt', 'desc')),
    adaptSummary,
    [uid],
  );
  return demoMode ? { data: demoSummaries, loading: false, error: null } : live;
}

export function useSummary(uid?: string, summaryId?: string): ResourceState<Summary | null> {
  const live = useDocumentResource(
    Boolean(uid && summaryId) && !demoMode,
    () => doc(db, 'users', uid!, 'summaries', summaryId!),
    adaptSummary,
    [uid, summaryId],
  );
  return demoMode ? { data: demoSummaries.find((item) => item.id === summaryId) ?? null, loading: false, error: null } : live;
}

export function useJob(uid?: string, jobId?: string, refreshKey = 0): ResourceState<AsyncJob | null> {
  const live = useDocumentResource(
    Boolean(uid && jobId) && !demoMode,
    () => doc(db, 'users', uid!, 'asyncJobs', jobId!),
    adaptJob,
    [uid, jobId, refreshKey],
  );
  return demoMode ? { data: demoJobs.find((item) => item.id === jobId) ?? null, loading: false, error: null } : live;
}
