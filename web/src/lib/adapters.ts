import type {
  AsyncJob,
  Course,
  Deck,
  DeckCard,
  Document,
  GeneratedAssets,
  Summary,
} from '../types';

type RecordData = Record<string, unknown>;

export interface SnapshotLike {
  id: string;
  data(): RecordData | undefined;
}

export function toDate(value: unknown): Date | null {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }
  if (typeof value === 'object' && 'toDate' in value) {
    const timestamp = value as { toDate: () => Date };
    try {
      return timestamp.toDate();
    } catch {
      return null;
    }
  }
  if (typeof value === 'object' && 'seconds' in value) {
    const seconds = Number((value as { seconds: unknown }).seconds);
    return Number.isFinite(seconds) ? new Date(seconds * 1000) : null;
  }
  return null;
}

const stringValue = (value: unknown, fallback = '') =>
  typeof value === 'string' ? value : fallback;
const numberValue = (value: unknown, fallback = 0) =>
  typeof value === 'number' && Number.isFinite(value) ? value : fallback;
const nullableString = (value: unknown) =>
  typeof value === 'string' ? value : null;
const stringList = (value: unknown) =>
  Array.isArray(value) ? value.filter((item): item is string => typeof item === 'string') : [];

function mapValue(value: unknown): RecordData {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as RecordData)
    : {};
}

export function adaptGeneratedAssets(value: unknown): GeneratedAssets {
  const data = mapValue(value);
  return {
    deckIds: stringList(data.deckIds),
    quizIds: stringList(data.quizIds),
    summaryIds: stringList(data.summaryIds),
    studyGuideIds: stringList(data.studyGuideIds),
    podcastIds: stringList(data.podcastIds),
  };
}

export function adaptCourse(id: string, raw: RecordData): Course {
  return {
    id,
    name: stringValue(raw.name),
    color: stringValue(raw.color, '#477966'),
    icon: nullableString(raw.icon),
    documentCount: numberValue(raw.documentCount),
    deckCount: numberValue(raw.deckCount),
    quizCount: numberValue(raw.quizCount),
    createdAt: toDate(raw.createdAt),
    updatedAt: toDate(raw.updatedAt),
  };
}

export function adaptDocument(id: string, raw: RecordData): Document {
  return {
    id,
    courseId: stringValue(raw.courseId),
    sourceType: stringValue(raw.sourceType, 'pdf') as Document['sourceType'],
    title: stringValue(raw.title),
    status: stringValue(raw.status, 'extracting') as Document['status'],
    fileName: nullableString(raw.fileName),
    fileSize: typeof raw.fileSize === 'number' ? raw.fileSize : null,
    mimeType: nullableString(raw.mimeType),
    storagePath: nullableString(raw.storagePath),
    sourceUrl: nullableString(raw.sourceUrl),
    pageCount: typeof raw.pageCount === 'number' ? raw.pageCount : null,
    wordCount: numberValue(raw.wordCount),
    extractedTextPath: nullableString(raw.extractedTextPath),
    errorMessage: nullableString(raw.errorMessage),
    generatedAssets: adaptGeneratedAssets(raw.generatedAssets),
    uploadedAt: toDate(raw.uploadedAt),
    extractedAt: toDate(raw.extractedAt),
    extractionJobId: nullableString(raw.extractionJobId),
  };
}

export function adaptDeck(id: string, raw: RecordData): Deck {
  return {
    id,
    courseId: stringValue(raw.courseId),
    sourceDocumentId: nullableString(raw.sourceDocumentId),
    title: stringValue(raw.title),
    description: stringValue(raw.description),
    cardCount: numberValue(raw.cardCount),
    generationMethod: stringValue(raw.generationMethod, 'manual') as Deck['generationMethod'],
    status: stringValue(raw.status, 'ready') as Deck['status'],
    jobId: nullableString(raw.jobId),
    errorMessage: nullableString(raw.errorMessage),
    createdAt: toDate(raw.createdAt),
    updatedAt: toDate(raw.updatedAt),
  };
}

export function adaptCard(id: string, raw: RecordData): DeckCard {
  const srs = mapValue(raw.srs);
  const stats = mapValue(raw.stats);
  return {
    id,
    front: stringValue(raw.front),
    back: stringValue(raw.back),
    hint: nullableString(raw.hint),
    explanation: nullableString(raw.explanation),
    topic: nullableString(raw.topic),
    srs: {
      easeFactor: numberValue(srs.easeFactor, 2.5),
      interval: numberValue(srs.interval),
      repetitions: numberValue(srs.repetitions),
      nextReviewDate: toDate(srs.nextReviewDate),
      lastReviewedAt: toDate(srs.lastReviewedAt),
    },
    stats: {
      timesShown: numberValue(stats.timesShown),
      timesCorrect: numberValue(stats.timesCorrect),
      timesWrong: numberValue(stats.timesWrong),
    },
    createdAt: toDate(raw.createdAt),
  };
}

export function adaptSummary(id: string, raw: RecordData): Summary {
  return {
    id,
    courseId: stringValue(raw.courseId),
    sourceDocumentId: stringValue(raw.sourceDocumentId),
    depth: stringValue(raw.depth, 'detailed') as Summary['depth'],
    status: stringValue(raw.status, 'queued') as Summary['status'],
    content: stringValue(raw.content),
    jobId: nullableString(raw.jobId),
    errorMessage: nullableString(raw.errorMessage),
    createdAt: toDate(raw.createdAt),
    updatedAt: toDate(raw.updatedAt),
  };
}

export function adaptJob(id: string, raw: RecordData): AsyncJob {
  return {
    id,
    type: stringValue(raw.type),
    status: stringValue(raw.status, 'queued') as AsyncJob['status'],
    progress: numberValue(raw.progress),
    inputRefs: mapValue(raw.inputRefs),
    outputRefs: mapValue(raw.outputRefs),
    errorMessage: nullableString(raw.errorMessage),
    workerId: nullableString(raw.workerId),
    attemptCount: numberValue(raw.attemptCount),
    maxAttempts: numberValue(raw.maxAttempts, 3),
    dependsOnJobId: nullableString(raw.dependsOnJobId),
    retryAt: toDate(raw.retryAt),
    createdAt: toDate(raw.createdAt),
    startedAt: toDate(raw.startedAt),
    completedAt: toDate(raw.completedAt),
  };
}

export const fromSnapshot = <T>(
  snapshot: SnapshotLike,
  adapter: (id: string, raw: RecordData) => T,
) => adapter(snapshot.id, snapshot.data() ?? {});
