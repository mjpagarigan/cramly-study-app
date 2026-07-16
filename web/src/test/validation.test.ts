import { describe, expect, it } from 'vitest';
import { validateAuthInput } from '../pages/LoginPage';
import { filterCourses } from '../pages/LibraryPage';
import { decodeExtractedBytes, MAX_AUDIO_BYTES, MAX_FILE_BYTES, validateFile, validateSourceUrl } from '../lib/upload';
import type { Course } from '../types';

const course = (id: string, name: string): Course => ({
  id,
  name,
  color: '#477966',
  documentCount: 0,
  deckCount: 0,
  quizCount: 0,
  createdAt: null,
  updatedAt: null,
});

describe('authentication validation', () => {
  it('requires eight characters only when registering', () => {
    expect(validateAuthInput('login', 'learner@example.com', 'short')).toEqual({});
    expect(validateAuthInput('register', 'learner@example.com', 'short')).toEqual({
      password: 'Use at least 8 characters.',
    });
  });
});

describe('course search', () => {
  it('filters case-insensitively and restores all courses for blank search', () => {
    const courses = [course('1', 'Cell Biology'), course('2', 'Modern World History')];
    expect(filterCourses(courses, ' biology ')).toEqual([courses[0]]);
    expect(filterCourses(courses, ' ')).toEqual(courses);
  });
});

describe('upload validation', () => {
  it('maps supported file extensions to backend-compatible source types and MIME metadata', () => {
    const markdown = validateFile(new File(['notes'], 'week-1.markdown', { type: '' }));
    expect(markdown).toMatchObject({ sourceType: 'markdown', mimeType: 'text/markdown' });
  });

  it('enforces the strict general limit and audio transcription limit', () => {
    expect(() => validateFile(new File([new Uint8Array(1)], 'large.pdf', { type: 'application/pdf' }))).not.toThrow();
    const largePdf = { name: 'large.pdf', size: MAX_FILE_BYTES } as File;
    const largeAudio = { name: 'lecture.mp3', size: MAX_AUDIO_BYTES + 1 } as File;
    expect(() => validateFile(largePdf)).toThrow('smaller than 50 MiB');
    expect(() => validateFile(largeAudio)).toThrow('25 MiB or smaller');
  });

  it('accepts supported YouTube shapes and rejects local/private web targets', () => {
    expect(validateSourceUrl('dQw4w9WgXcQ', 'youtube')).toBe('dQw4w9WgXcQ');
    expect(() => validateSourceUrl('http://localhost:8080/notes', 'web_url')).toThrow('public URL');
    expect(() => validateSourceUrl('http://192.168.1.7/notes', 'web_url')).toThrow('public URL');
    expect(() => validateSourceUrl('http://[::]/notes', 'web_url')).toThrow('public URL');
    expect(() => validateSourceUrl('http://[::ffff:127.0.0.1]/notes', 'web_url')).toThrow('public URL');
    expect(validateSourceUrl('https://www.fda.gov', 'web_url')).toBe('https://www.fda.gov/');
    expect(validateSourceUrl('https://example.edu/notes', 'web_url')).toBe('https://example.edu/notes');
    expect(() => validateSourceUrl('https://youtu.be/dQw4w9WgXcQextra', 'youtube')).toThrow('supported YouTube');
  });

  it('distinguishes empty text from malformed UTF-8', () => {
    expect(decodeExtractedBytes(new TextEncoder().encode('  '))).toEqual({ status: 'empty', text: '' });
    expect(decodeExtractedBytes(new Uint8Array([0xc3, 0x28]))).toEqual({
      status: 'error',
      text: '',
      message: 'Extracted text is not valid UTF-8.',
    });
  });
});
