import { collection, doc } from 'firebase/firestore';
import { getBytes, ref, uploadBytesResumable } from 'firebase/storage';
import type { SourceType } from '../types';
import { db, storage } from './firebase';
import { demoExtractedText, demoMode } from './demo';

const MIB = 1024 * 1024;
export const MAX_FILE_BYTES = 50 * MIB;
export const MAX_AUDIO_BYTES = 25 * MIB;
export const MAX_EXTRACTED_TEXT_BYTES = 5 * MIB;

const extensionTypes: Record<string, { sourceType: SourceType; mimeType: string }> = {
  pdf: { sourceType: 'pdf', mimeType: 'application/pdf' },
  docx: {
    sourceType: 'docx',
    mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  },
  pptx: {
    sourceType: 'pptx',
    mimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  },
  md: { sourceType: 'markdown', mimeType: 'text/markdown' },
  markdown: { sourceType: 'markdown', mimeType: 'text/markdown' },
  png: { sourceType: 'image', mimeType: 'image/png' },
  jpg: { sourceType: 'image', mimeType: 'image/jpeg' },
  jpeg: { sourceType: 'image', mimeType: 'image/jpeg' },
  webp: { sourceType: 'image', mimeType: 'image/webp' },
  bmp: { sourceType: 'image', mimeType: 'image/bmp' },
  tif: { sourceType: 'image', mimeType: 'image/tiff' },
  tiff: { sourceType: 'image', mimeType: 'image/tiff' },
  mp3: { sourceType: 'audio', mimeType: 'audio/mpeg' },
  m4a: { sourceType: 'audio', mimeType: 'audio/mp4' },
  wav: { sourceType: 'audio', mimeType: 'audio/wav' },
  flac: { sourceType: 'audio', mimeType: 'audio/flac' },
  ogg: { sourceType: 'audio', mimeType: 'audio/ogg' },
  webm: { sourceType: 'audio', mimeType: 'audio/webm' },
};

export interface ValidatedFile {
  file: File;
  extension: string;
  sourceType: SourceType;
  mimeType: string;
}

export function validateFile(file: File): ValidatedFile {
  const extension = file.name.split('.').pop()?.toLowerCase() ?? '';
  const mapping = extensionTypes[extension];
  if (!mapping) {
    throw new Error('Choose a PDF, DOCX, PPTX, Markdown, image, or supported audio file.');
  }
  if (file.size >= MAX_FILE_BYTES) {
    throw new Error('Files must be smaller than 50 MiB.');
  }
  if (mapping.sourceType === 'audio' && file.size > MAX_AUDIO_BYTES) {
    throw new Error('Audio must be 25 MiB or smaller for transcription.');
  }
  return { file, extension, ...mapping };
}

export function validateSourceUrl(value: string, type: 'youtube' | 'web_url') {
  const raw = value.trim();
  if (type === 'youtube' && /^[A-Za-z0-9_-]{11}$/.test(raw)) return raw;
  let url: URL;
  try {
    url = new URL(raw.includes('://') ? raw : `https://${raw}`);
  } catch {
    throw new Error(type === 'youtube' ? 'Enter a valid YouTube URL or video ID.' : 'Enter a complete public URL.');
  }
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new Error('Only http and https URLs are supported.');
  }
  if (type === 'web_url' && isPrivateHost(url.hostname)) {
    throw new Error('Enter a public URL. Local and private network addresses are not supported.');
  }
  if (type === 'youtube') {
    const host = url.hostname.toLowerCase();
    const supportedHost = host === 'youtu.be' || host === 'youtube.com' || host.endsWith('.youtube.com');
    const pathSupported = host === 'youtu.be'
      ? /^\/[A-Za-z0-9_-]{11}\/?$/.test(url.pathname)
      : (
        (url.pathname === '/watch' && /^[A-Za-z0-9_-]{11}$/.test(url.searchParams.get('v') ?? ''))
        || /^\/(shorts|embed|v)\/[A-Za-z0-9_-]{11}\/?$/.test(url.pathname)
      );
    if (!supportedHost || !pathSupported) throw new Error('Enter a supported YouTube URL or video ID.');
  }
  return url.toString();
}

function isPrivateHost(hostname: string) {
  const host = hostname.toLowerCase().replace(/^\[|\]$/g, '');
  if (host === 'localhost' || host.endsWith('.localhost') || host.endsWith('.local')) return true;
  if (host.includes(':')) {
    const parts = parseIpv6(host);
    if (!parts) return true;
    const [first] = parts;
    const unspecified = parts.every((part) => part === 0);
    const loopback = parts.slice(0, 7).every((part) => part === 0) && parts[7] === 1;
    const uniqueLocal = (first & 0xfe00) === 0xfc00;
    const linkLocal = (first & 0xffc0) === 0xfe80;
    const siteLocal = (first & 0xffc0) === 0xfec0;
    const mappedIpv4 = parts.slice(0, 5).every((part) => part === 0) && parts[5] === 0xffff;
    const compatibleIpv4 = parts.slice(0, 6).every((part) => part === 0);
    if (unspecified || loopback || uniqueLocal || linkLocal || siteLocal) return true;
    if (mappedIpv4 || compatibleIpv4) {
      return isPrivateIpv4([
        parts[6] >> 8,
        parts[6] & 0xff,
        parts[7] >> 8,
        parts[7] & 0xff,
      ]);
    }
    return false;
  }
  const parts = host.split('.').map(Number);
  return parts.length === 4
    && parts.every((part) => Number.isInteger(part) && part >= 0 && part <= 255)
    && isPrivateIpv4(parts);
}

function isPrivateIpv4(parts: number[]) {
  const [a, b] = parts;
  return a === 0
    || a === 10
    || a === 127
    || (a === 100 && b >= 64 && b <= 127)
    || (a === 169 && b === 254)
    || (a === 172 && b >= 16 && b <= 31)
    || (a === 192 && b === 168)
    || (a === 198 && (b === 18 || b === 19))
    || a >= 224;
}

function parseIpv6(host: string): number[] | null {
  if ((host.match(/::/g) ?? []).length > 1) return null;
  const [leftRaw, rightRaw = ''] = host.split('::');
  const parseSide = (raw: string): number[] | null => {
    if (!raw) return [];
    const values: number[] = [];
    for (const part of raw.split(':')) {
      if (part.includes('.')) {
        const octets = part.split('.').map(Number);
        if (octets.length !== 4 || octets.some((value) => !Number.isInteger(value) || value < 0 || value > 255)) return null;
        values.push((octets[0] << 8) | octets[1], (octets[2] << 8) | octets[3]);
      } else {
        if (!/^[0-9a-f]{1,4}$/.test(part)) return null;
        values.push(Number.parseInt(part, 16));
      }
    }
    return values;
  };
  const left = parseSide(leftRaw);
  const right = parseSide(rightRaw);
  if (!left || !right) return null;
  if (!host.includes('::')) return left.length === 8 ? left : null;
  const missing = 8 - left.length - right.length;
  if (missing < 1) return null;
  return [...left, ...Array<number>(missing).fill(0), ...right];
}

export function buildStoragePath(uid: string, extension: string) {
  const generatedId = doc(collection(db, 'users', uid, 'documents')).id;
  return `users/${uid}/documents/${generatedId}/original.${extension}`;
}

export function uploadFile(
  uid: string,
  validated: ValidatedFile,
  onProgress: (progress: number) => void,
): Promise<string> {
  const storagePath = buildStoragePath(uid, validated.extension);
  const task = uploadBytesResumable(
    ref(storage, storagePath),
    validated.file,
    { contentType: validated.mimeType },
  );
  return new Promise((resolve, reject) => {
    task.on(
      'state_changed',
      (snapshot) => {
        const fraction = snapshot.totalBytes
          ? snapshot.bytesTransferred / snapshot.totalBytes
          : 0;
        onProgress(Math.round(fraction * 100));
      },
      reject,
      () => resolve(storagePath),
    );
  });
}

export type ExtractedTextResult =
  | { status: 'success'; text: string }
  | { status: 'empty'; text: '' }
  | { status: 'error'; text: ''; message: string };

export function decodeExtractedBytes(bytes: ArrayBuffer | Uint8Array): ExtractedTextResult {
  try {
    const text = new TextDecoder('utf-8', { fatal: true }).decode(bytes);
    return text.trim().length
      ? { status: 'success', text }
      : { status: 'empty', text: '' };
  } catch {
    return { status: 'error', text: '', message: 'Extracted text is not valid UTF-8.' };
  }
}

export async function fetchExtractedText(path: string): Promise<ExtractedTextResult> {
  if (demoMode && path === 'demo://extracted-text') {
    return { status: 'success', text: demoExtractedText };
  }
  try {
    const bytes = await getBytes(ref(storage, path), MAX_EXTRACTED_TEXT_BYTES);
    return decodeExtractedBytes(bytes);
  } catch (error) {
    return {
      status: 'error',
      text: '',
      message: error instanceof Error ? error.message : 'Extracted text could not be downloaded.',
    };
  }
}
