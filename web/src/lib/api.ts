import type {
  AsyncJob,
  Course,
  Deck,
  DeckCard,
  Document,
  GenerationResult,
  SourceType,
  SummaryDepth,
} from '../types';
import { auth } from './firebase';
import {
  adaptCourse,
  adaptDeck,
  adaptCard,
  adaptDocument,
  adaptJob,
  adaptSummary,
} from './adapters';

export class ApiError extends Error {
  constructor(
    public readonly status: number,
    message: string,
    public readonly detail?: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

type TokenProvider = () => Promise<string>;
type JsonRecord = Record<string, unknown>;

function detailText(value: unknown): string | undefined {
  if (typeof value === 'string') return value;
  if (!Array.isArray(value)) return undefined;
  const messages = value
    .map((item) => {
      if (typeof item === 'string') return item;
      if (item && typeof item === 'object' && 'msg' in item) {
        return String((item as { msg: unknown }).msg);
      }
      return null;
    })
    .filter((item): item is string => Boolean(item));
  return messages.length ? messages.join(' ') : undefined;
}

function statusMessage(status: number) {
  if (status === 400) return 'The request could not be completed.';
  if (status === 401) return 'Your session has expired. Sign in again.';
  if (status === 403) return 'You do not have access to this resource.';
  if (status === 404) return 'The requested item was not found.';
  if (status === 429) return 'Too many requests. Try again shortly.';
  if (status >= 500) return 'Cramly could not reach its processing service.';
  return 'The request failed.';
}

export class ApiClient {
  constructor(
    private readonly baseUrl: string,
    private readonly tokenProvider: TokenProvider,
  ) {}

  async request<T>(path: string, init: RequestInit = {}): Promise<T> {
    let response: Response;
    try {
      const token = await this.tokenProvider();
      response = await fetch(`${this.baseUrl}${path}`, {
        ...init,
        credentials: 'omit',
        headers: {
          Authorization: `Bearer ${token}`,
          ...(init.body ? { 'Content-Type': 'application/json' } : {}),
          ...init.headers,
        },
      });
    } catch (error) {
      if (error instanceof DOMException && error.name === 'AbortError') {
        throw new ApiError(0, 'Request cancelled.');
      }
      if (error instanceof ApiError) throw error;
      throw new ApiError(0, 'Network request failed. Check your connection.');
    }

    if (response.ok) {
      if (response.status === 204) return undefined as T;
      const text = await response.text();
      return text ? (JSON.parse(text) as T) : (undefined as T);
    }

    let detail: string | undefined;
    try {
      const body = (await response.json()) as { detail?: unknown };
      detail = detailText(body.detail);
    } catch {
      detail = undefined;
    }
    throw new ApiError(response.status, detail ?? statusMessage(response.status), detail);
  }

  get<T>(path: string, signal?: AbortSignal) {
    return this.request<T>(path, { method: 'GET', signal });
  }

  post<T>(path: string, body?: unknown, signal?: AbortSignal) {
    return this.request<T>(path, {
      method: 'POST',
      body: body === undefined ? undefined : JSON.stringify(body),
      signal,
    });
  }

  patch<T>(path: string, body: unknown, signal?: AbortSignal) {
    return this.request<T>(path, {
      method: 'PATCH',
      body: JSON.stringify(body),
      signal,
    });
  }

  delete(path: string, signal?: AbortSignal) {
    return this.request<void>(path, { method: 'DELETE', signal });
  }
}

const baseUrl = (import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000').replace(/\/$/, '');

export const apiClient = new ApiClient(baseUrl, async () => {
  const user = auth.currentUser;
  if (!user) throw new ApiError(401, 'You must be signed in.');
  return user.getIdToken();
});

const record = (value: unknown) => value as JsonRecord;

export const courseApi = {
  async create(input: { name: string; color: string; icon?: string | null }) {
    const raw = await apiClient.post<JsonRecord>('/courses', input);
    return adaptCourse(String(raw.id ?? ''), raw);
  },
  async update(id: string, input: { name?: string; color?: string; icon?: string }) {
    const raw = await apiClient.patch<JsonRecord>(`/courses/${id}`, input);
    return adaptCourse(String(raw.id ?? id), raw);
  },
  delete(id: string) {
    return apiClient.delete(`/courses/${id}`);
  },
};

export interface FileDocumentInput {
  courseId: string;
  sourceType: SourceType;
  fileName: string;
  fileSize: number;
  storagePath: string;
  mimeType: string;
  title?: string;
}

export const documentApi = {
  async createFromFile(input: FileDocumentInput) {
    const raw = await apiClient.post<JsonRecord>('/documents', input);
    return adaptDocument(String(raw.id ?? ''), raw);
  },
  async createFromUrl(input: {
    courseId: string;
    sourceType: 'youtube' | 'web_url';
    sourceUrl: string;
    title?: string;
  }) {
    const raw = await apiClient.post<JsonRecord>('/documents', input);
    return adaptDocument(String(raw.id ?? ''), raw);
  },
  delete(id: string) {
    return apiClient.delete(`/documents/${id}`);
  },
  async generateFlashcards(id: string, cardCount: 8 | 12 | 16): Promise<GenerationResult> {
    const raw = await apiClient.post<JsonRecord>(`/documents/${id}/generate`, {
      generator: 'flashcards',
      cardCount,
    });
    const jobRaw = record(raw.job);
    const deckRaw = raw.deck ? record(raw.deck) : null;
    return {
      job: adaptJob(String(jobRaw.id ?? ''), jobRaw),
      deck: deckRaw ? adaptDeck(String(deckRaw.id ?? ''), deckRaw) : null,
    };
  },
  async generateSummary(id: string, depth: SummaryDepth): Promise<GenerationResult> {
    const raw = await apiClient.post<JsonRecord>(`/documents/${id}/generate`, {
      generator: 'summary',
      depth,
    });
    const jobRaw = record(raw.job);
    const summaryRaw = raw.summary ? record(raw.summary) : null;
    return {
      job: adaptJob(String(jobRaw.id ?? ''), jobRaw),
      summary: summaryRaw ? adaptSummary(String(summaryRaw.id ?? ''), summaryRaw) : null,
    };
  },
};

export const deckApi = {
  async create(input: { courseId: string; title: string; description?: string }) {
    const raw = await apiClient.post<JsonRecord>('/decks', input);
    return adaptDeck(String(raw.id ?? ''), raw);
  },
  async update(id: string, input: { title?: string; description?: string }) {
    const raw = await apiClient.patch<JsonRecord>(`/decks/${id}`, input);
    return adaptDeck(String(raw.id ?? id), raw);
  },
  delete(id: string) {
    return apiClient.delete(`/decks/${id}`);
  },
  async createCard(deckId: string, input: CardInput) {
    const raw = await apiClient.post<JsonRecord>(`/decks/${deckId}/cards`, input);
    return adaptCard(String(raw.id ?? ''), raw);
  },
  async updateCard(deckId: string, cardId: string, input: Partial<CardInput>) {
    const raw = await apiClient.patch<JsonRecord>(`/decks/${deckId}/cards/${cardId}`, input);
    return adaptCard(String(raw.id ?? cardId), raw);
  },
  deleteCard(deckId: string, cardId: string) {
    return apiClient.delete(`/decks/${deckId}/cards/${cardId}`);
  },
};

export interface CardInput {
  front: string;
  back: string;
  hint?: string;
  explanation?: string;
  topic?: string;
}

export type ApiModels = Course | Deck | DeckCard | Document | AsyncJob;
