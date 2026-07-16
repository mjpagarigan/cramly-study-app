import { cleanup, render, screen, waitFor } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const firestore = vi.hoisted(() => ({
  collection: vi.fn((...segments: unknown[]) => ({ kind: 'collection', segments })),
  doc: vi.fn((...segments: unknown[]) => ({ kind: 'document', segments })),
  onSnapshot: vi.fn(),
  orderBy: vi.fn((...segments: unknown[]) => ({ kind: 'orderBy', segments })),
  query: vi.fn((...segments: unknown[]) => ({ kind: 'query', segments })),
  where: vi.fn((...segments: unknown[]) => ({ kind: 'where', segments })),
}));

const demo = vi.hoisted(() => ({ enabled: false }));

vi.mock('firebase/firestore', () => firestore);
vi.mock('../lib/firebase', () => ({ db: { name: 'test-db' } }));
vi.mock('../lib/demo', () => ({
  get demoMode() {
    return demo.enabled;
  },
  demoCards: {},
  demoCourses: [],
  demoDecks: [],
  demoDocuments: [],
  demoJobs: [],
  demoSummaries: [],
}));

import { useCourses } from '../hooks/useFirestore';

function CoursesHarness({ uid }: { uid?: string }) {
  const courses = useCourses(uid);
  return <output>{courses.loading ? 'loading' : `ready:${courses.data.length}`}</output>;
}

describe('Firestore listener hooks', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    demo.enabled = false;
  });

  afterEach(() => {
    cleanup();
  });

  it('unsubscribes before replacing a listener and again on unmount', () => {
    const unsubscribeFirst = vi.fn();
    const unsubscribeSecond = vi.fn();
    firestore.onSnapshot
      .mockReturnValueOnce(unsubscribeFirst)
      .mockReturnValueOnce(unsubscribeSecond);

    const view = render(<CoursesHarness uid="user-1" />);
    expect(firestore.onSnapshot).toHaveBeenCalledTimes(1);

    view.rerender(<CoursesHarness uid="user-2" />);
    expect(unsubscribeFirst).toHaveBeenCalledTimes(1);
    expect(firestore.onSnapshot).toHaveBeenCalledTimes(2);

    view.unmount();
    expect(unsubscribeSecond).toHaveBeenCalledTimes(1);
  });

  it('does not register a listener until its required uid exists', async () => {
    render(<CoursesHarness />);

    await waitFor(() => expect(screen.getByText('ready:0')).toBeInTheDocument());
    expect(firestore.onSnapshot).not.toHaveBeenCalled();
  });

  it('uses demo records without opening a Firebase listener', async () => {
    demo.enabled = true;
    render(<CoursesHarness uid="demo-user" />);

    await waitFor(() => expect(screen.getByText('ready:0')).toBeInTheDocument());
    expect(firestore.onSnapshot).not.toHaveBeenCalled();
  });
});
