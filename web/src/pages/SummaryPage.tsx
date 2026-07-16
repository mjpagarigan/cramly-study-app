import { useEffect, useState } from 'react';
import ReactMarkdown, { defaultUrlTransform } from 'react-markdown';
import { useParams } from 'react-router-dom';
import remarkGfm from 'remark-gfm';
import { CopyIcon } from '../components/Icons';
import {
  Badge,
  Button,
  ButtonLink,
  ErrorState,
  LearningTrace,
  LoadingState,
  Meta,
  PageHeader,
  Panel,
  ProgressBar,
  Toast,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useCourse, useJob, useStudyDocument, useSummary } from '../hooks/useFirestore';
import { depthLabel, relativeDate } from '../lib/format';

export function safeMarkdownUrl(url: string) {
  if (url.startsWith('#') || url.startsWith('/')) return url;
  try {
    const parsed = new URL(url);
    if (['http:', 'https:', 'mailto:'].includes(parsed.protocol)) return defaultUrlTransform(url);
  } catch {
    return '';
  }
  return '';
}

export function SummaryPage() {
  const { courseId, documentId, summaryId } = useParams();
  const { user } = useAuth();
  const summaryState = useSummary(user?.uid, summaryId);
  const documentState = useStudyDocument(user?.uid, documentId);
  const courseState = useCourse(user?.uid, courseId);
  const summary = summaryState.data;
  const [jobRetry, setJobRetry] = useState(0);
  const job = useJob(user?.uid, summary?.jobId ?? undefined, jobRetry);
  useDocumentTitle(summary ? `${depthLabel(summary.depth)} summary` : 'Summary');
  const [copyStatus, setCopyStatus] = useState<{ message: string; tone: 'success' | 'error' } | null>(null);

  useEffect(() => {
    if (!copyStatus) return;
    const timer = window.setTimeout(() => setCopyStatus(null), 2500);
    return () => window.clearTimeout(timer);
  }, [copyStatus]);

  if (summaryState.loading || documentState.loading || courseState.loading) return <LoadingState label="Loading summary" />;
  if (summaryState.error || documentState.error || courseState.error) return <ErrorState message={(summaryState.error || documentState.error || courseState.error)?.message} />;
  if (!summary) return <ErrorState title="Summary not found" message="It may have been removed." />;

  const generationFailed = summary.status === 'failed'
    || (summary.status !== 'ready' && (job.data?.status === 'failed' || Boolean(job.error)));
  const generationError = summary.errorMessage
    || job.data?.errorMessage
    || job.error?.message
    || 'Try generating another summary from the document.';

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(summary.content);
      setCopyStatus({ message: 'Summary copied.', tone: 'success' });
    } catch {
      setCopyStatus({ message: 'Could not copy. Select the summary text and copy it manually.', tone: 'error' });
    }
  };

  return (
    <>
      <PageHeader
        eyebrow={`${depthLabel(summary.depth)} summary`}
        title={documentState.data?.title || 'Generated summary'}
        copy={<Meta items={[relativeDate(summary.updatedAt), courseState.data?.name]} />}
        actions={(
          <>
            <ButtonLink className="secondary" to={`/library/${courseId}/document/${documentId}`}>Back to document</ButtonLink>
            <Button className="primary" disabled={summary.status !== 'ready'} onClick={() => void copy()}><CopyIcon /> Copy summary</Button>
          </>
        )}
      />
      <LearningTrace className="page-trace" />
      {generationFailed ? (
        <ErrorState title="Summary generation failed" message={generationError} retry={job.error ? () => setJobRetry((value) => value + 1) : undefined} />
      ) : summary.status !== 'ready' ? (
        <Panel className="summary-processing" aria-live="polite">
          <div><Badge tone="warning">{summary.status}</Badge><h2>Your summary is being prepared.</h2><p>{job.data?.status === 'queued' ? 'The generation job is queued.' : 'Cramly is organizing the key ideas.'}</p><ProgressBar value={job.data?.progress ?? 0} label="Summary generation progress" /></div>
        </Panel>
      ) : (
        <div className="reading-layout">
          <article className="panel summary-content">
            <ReactMarkdown remarkPlugins={[remarkGfm]} urlTransform={safeMarkdownUrl}>{summary.content}</ReactMarkdown>
          </article>
          <aside className="summary-aside">
            <Panel><p className="eyebrow">Depth</p><strong>{depthLabel(summary.depth)}</strong><p>{summary.depth === 'tldr' ? 'Only the biggest takeaways.' : summary.depth === 'eli5' ? 'Simpler language for quick understanding.' : 'Balanced explanation and key relationships.'}</p></Panel>
            <Panel><p className="eyebrow">Source</p><strong>{courseState.data?.name || 'Course'}</strong><p>{documentState.data?.title || 'Source document'}</p></Panel>
          </aside>
        </div>
      )}
      <Toast message={copyStatus?.message ?? null} tone={copyStatus?.tone === 'error' ? 'error' : 'success'} />
    </>
  );
}
