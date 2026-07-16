export type ThemeMode = 'light' | 'dark' | 'system';

export interface Course {
  id: string;
  name: string;
  color: string;
  icon?: string | null;
  documentCount: number;
  deckCount: number;
  quizCount: number;
  createdAt: Date | null;
  updatedAt: Date | null;
}

export interface GeneratedAssets {
  deckIds: string[];
  quizIds: string[];
  summaryIds: string[];
  studyGuideIds: string[];
  podcastIds: string[];
}

export type SourceType =
  | 'pdf'
  | 'docx'
  | 'pptx'
  | 'markdown'
  | 'image'
  | 'audio'
  | 'youtube'
  | 'web_url';

export type DocumentStatus = 'uploading' | 'extracting' | 'ready' | 'failed';

export interface Document {
  id: string;
  courseId: string;
  sourceType: SourceType;
  title: string;
  status: DocumentStatus;
  fileName?: string | null;
  fileSize?: number | null;
  mimeType?: string | null;
  storagePath?: string | null;
  sourceUrl?: string | null;
  pageCount?: number | null;
  wordCount: number;
  extractedTextPath?: string | null;
  errorMessage?: string | null;
  generatedAssets: GeneratedAssets;
  uploadedAt: Date | null;
  extractedAt: Date | null;
  extractionJobId?: string | null;
}

export type DeckStatus = 'queued' | 'generating' | 'ready' | 'failed';
export type DeckGenerationMethod = 'ai' | 'manual';

export interface Deck {
  id: string;
  courseId: string;
  sourceDocumentId?: string | null;
  title: string;
  description: string;
  cardCount: number;
  generationMethod: DeckGenerationMethod;
  status: DeckStatus;
  jobId?: string | null;
  errorMessage?: string | null;
  createdAt: Date | null;
  updatedAt: Date | null;
}

export interface CardSrs {
  easeFactor: number;
  interval: number;
  repetitions: number;
  nextReviewDate: Date | null;
  lastReviewedAt: Date | null;
}

export interface CardStats {
  timesShown: number;
  timesCorrect: number;
  timesWrong: number;
}

export interface DeckCard {
  id: string;
  front: string;
  back: string;
  hint?: string | null;
  explanation?: string | null;
  topic?: string | null;
  srs: CardSrs;
  stats: CardStats;
  createdAt: Date | null;
}

export type SummaryDepth = 'tldr' | 'detailed' | 'eli5';
export type SummaryStatus = 'queued' | 'generating' | 'ready' | 'failed';

export interface Summary {
  id: string;
  courseId: string;
  sourceDocumentId: string;
  depth: SummaryDepth;
  status: SummaryStatus;
  content: string;
  jobId?: string | null;
  errorMessage?: string | null;
  createdAt: Date | null;
  updatedAt: Date | null;
}

export type JobStatus = 'queued' | 'processing' | 'completed' | 'failed';

export interface AsyncJob {
  id: string;
  type: string;
  status: JobStatus;
  progress: number;
  inputRefs: Record<string, unknown>;
  outputRefs: Record<string, unknown>;
  errorMessage?: string | null;
  workerId?: string | null;
  attemptCount: number;
  maxAttempts: number;
  dependsOnJobId?: string | null;
  retryAt: Date | null;
  createdAt: Date | null;
  startedAt: Date | null;
  completedAt: Date | null;
}

export interface GenerationResult {
  job: AsyncJob;
  deck?: Deck | null;
  summary?: Summary | null;
}

export interface ResourceState<T> {
  data: T;
  loading: boolean;
  error: Error | null;
}
