import type { User } from 'firebase/auth';
import type { Document, SourceType, SummaryDepth } from '../types';

export function displayName(user: User | null) {
  if (!user) return 'Learner';
  return user.displayName?.trim() || user.email?.split('@')[0] || 'Learner';
}

export function initials(user: User | null) {
  return displayName(user)
    .split(/[\s._-]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('') || 'C';
}

export function greeting(date = new Date()) {
  const hour = date.getHours();
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}

export function longDate(date = new Date()) {
  return new Intl.DateTimeFormat(undefined, {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  }).format(date);
}

export function shortDate(date: Date | null) {
  if (!date) return 'Date unavailable';
  return new Intl.DateTimeFormat(undefined, {
    day: 'numeric',
    month: 'short',
    year: date.getFullYear() === new Date().getFullYear() ? undefined : 'numeric',
  }).format(date);
}

export function relativeDate(date: Date | null) {
  if (!date) return 'Date unavailable';
  const diffDays = Math.round((date.getTime() - Date.now()) / 86_400_000);
  if (diffDays === 0) return 'Today';
  if (diffDays === -1) return 'Yesterday';
  return shortDate(date);
}

export function fileSize(bytes?: number | null) {
  if (bytes == null) return null;
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function sourceLabel(sourceType: SourceType) {
  const labels: Record<SourceType, string> = {
    pdf: 'PDF',
    docx: 'DOCX',
    pptx: 'PPTX',
    markdown: 'Markdown',
    image: 'Image',
    audio: 'Audio',
    youtube: 'YouTube',
    web_url: 'Web page',
  };
  return labels[sourceType];
}

export function documentMeta(document: Document) {
  const values = [sourceLabel(document.sourceType)];
  if (document.pageCount) values.push(`${document.pageCount} ${document.sourceType === 'pptx' ? 'slides' : 'pages'}`);
  const size = fileSize(document.fileSize);
  if (size) values.push(size);
  if (document.wordCount) values.push(`${document.wordCount.toLocaleString()} words`);
  return values;
}

export function depthLabel(depth: SummaryDepth) {
  if (depth === 'tldr') return 'TL;DR';
  if (depth === 'eli5') return 'ELI5';
  return 'Detailed';
}

export function friendlyError(error: unknown) {
  const code = (error as { code?: string }).code;
  if (code === 'auth/invalid-credential') return 'The email or password is incorrect.';
  if (code === 'auth/email-already-in-use') return 'An account already uses this email.';
  if (code === 'auth/weak-password') return 'Use a stronger password with at least 8 characters.';
  if (code === 'auth/too-many-requests') return 'Too many attempts. Try again later.';
  if (error instanceof Error) return error.message;
  return 'Something went wrong. Please try again.';
}
