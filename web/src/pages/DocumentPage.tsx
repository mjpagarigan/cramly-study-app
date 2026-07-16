import { useEffect, useState } from 'react';
import { Link, useNavigate, useParams } from 'react-router-dom';
import { DeleteResourceDialog } from '../components/DeckDialogs';
import { RefreshIcon, TrashIcon } from '../components/Icons';
import {
  Badge,
  Button,
  ButtonLink,
  ErrorState,
  LearningTrace,
  LoadingState,
  Meta,
  Notice,
  PageHeader,
  Panel,
  ProgressBar,
  Toast,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useDeck, useJob, useStudyDocument, useSummary } from '../hooks/useFirestore';
import { documentApi } from '../lib/api';
import { depthLabel, documentMeta, friendlyError } from '../lib/format';
import { fetchExtractedText, type ExtractedTextResult } from '../lib/upload';
import type { SummaryDepth } from '../types';

export function DocumentPage() {
  const { courseId, documentId } = useParams();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [extractionRetry, setExtractionRetry] = useState(0);
  const documentState = useStudyDocument(user?.uid, documentId, extractionRetry);
  const document = documentState.data;
  useDocumentTitle(document?.title || 'Document');
  const extractionJob = useJob(user?.uid, document?.extractionJobId ?? undefined, extractionRetry);
  const [textResult, setTextResult] = useState<ExtractedTextResult | null>(null);
  const [textLoading, setTextLoading] = useState(false);
  const [textRetry, setTextRetry] = useState(0);
  const [cardCount, setCardCount] = useState<8 | 12 | 16>(12);
  const [depth, setDepth] = useState<SummaryDepth>('detailed');
  const [generationBusy, setGenerationBusy] = useState<'deck' | 'summary' | null>(null);
  const [generationError, setGenerationError] = useState<string | null>(null);
  const [generationJobId, setGenerationJobId] = useState<string | null>(null);
  const [resultType, setResultType] = useState<'deck' | 'summary' | null>(null);
  const [resultId, setResultId] = useState<string | null>(null);
  const generationJob = useJob(user?.uid, generationJobId ?? undefined);
  const resultDeck = useDeck(user?.uid, resultType === 'deck' ? resultId ?? undefined : undefined);
  const resultSummary = useSummary(user?.uid, resultType === 'summary' ? resultId ?? undefined : undefined);
  const [deleteOpen, setDeleteOpen] = useState(false);
  const [deleteBusy, setDeleteBusy] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);

  useEffect(() => {
    if (!document?.extractedTextPath || document.status !== 'ready') {
      setTextResult(null);
      return;
    }
    let active = true;
    setTextLoading(true);
    fetchExtractedText(document.extractedTextPath).then((result) => {
      if (active) {
        setTextResult(result);
        setTextLoading(false);
      }
    });
    return () => { active = false; };
  }, [document?.extractedTextPath, document?.status, textRetry]);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(null), 2500);
    return () => window.clearTimeout(timer);
  }, [toast]);

  if (documentState.loading) return <LoadingState label="Loading document" />;
  if (documentState.error) return <ErrorState message={documentState.error.message} retry={() => setExtractionRetry((value) => value + 1)} />;
  if (!document) return <ErrorState title="Document not found" message="It may have been deleted." />;

  const generateDeck = async () => {
    setGenerationBusy('deck');
    setGenerationError(null);
    setResultType('deck');
    try {
      const result = await documentApi.generateFlashcards(document.id, cardCount);
      setGenerationJobId(result.job.id);
      setResultId(result.deck?.id ?? null);
    } catch (error) {
      setGenerationError(friendlyError(error));
    } finally { setGenerationBusy(null); }
  };
  const generateSummary = async () => {
    setGenerationBusy('summary');
    setGenerationError(null);
    setResultType('summary');
    try {
      const result = await documentApi.generateSummary(document.id, depth);
      setGenerationJobId(result.job.id);
      setResultId(result.summary?.id ?? null);
    } catch (error) {
      setGenerationError(friendlyError(error));
    } finally { setGenerationBusy(null); }
  };
  const deleteDocument = async () => {
    setDeleteBusy(true);
    setDeleteError(null);
    try {
      await documentApi.delete(document.id);
      navigate(`/library/${courseId}`, { replace: true });
    } catch (error) {
      setDeleteError(friendlyError(error));
      setDeleteBusy(false);
    }
  };

  const resultReady = resultType === 'deck'
    ? resultDeck.data?.status === 'ready'
    : resultSummary.data?.status === 'ready';
  const resultFailed = resultType === 'deck'
    ? resultDeck.data?.status === 'failed'
    : resultSummary.data?.status === 'failed';
  const generationFailed = !resultReady && Boolean(
    resultFailed
    || generationJob.data?.status === 'failed'
    || resultDeck.error
    || resultSummary.error
    || generationJob.error,
  );
  const resultError = resultDeck.data?.errorMessage
    || resultSummary.data?.errorMessage
    || generationJob.data?.errorMessage
    || resultDeck.error?.message
    || resultSummary.error?.message
    || generationJob.error?.message;
  const jobVisible = generationJobId || generationError;
  const existingDeckId = document.generatedAssets.deckIds.at(-1);
  const existingSummaryId = document.generatedAssets.summaryIds.at(-1);
  const extractionFailed = document.status === 'failed' || (
    document.status !== 'ready'
    && (extractionJob.data?.status === 'failed' || Boolean(extractionJob.error))
  );
  const extractionError = document.errorMessage
    || extractionJob.data?.errorMessage
    || extractionJob.error?.message
    || 'The source could not be read.';

  return (
    <>
      <PageHeader
        eyebrow={`${document.status} document`}
        title={document.title}
        copy={<Meta items={documentMeta(document)} />}
        actions={(
          <>
            <ButtonLink className="secondary" to={`/library/${courseId}`}>Back to course</ButtonLink>
            <Button className="danger" onClick={() => setDeleteOpen(true)}><TrashIcon /> Delete document</Button>
          </>
        )}
      />
      <LearningTrace className="page-trace" />
      <div className="grid-12 document-layout">
        <Panel className="span-8 document-text">
          <div className="document-text-head">
            <h2>Extracted text</h2>
            {document.wordCount > 0 && <span className="word-count">{document.wordCount.toLocaleString()} words</span>}
          </div>
          {extractionFailed ? (
            <Notice title="Extraction failed" tone="danger">
              <span>{extractionError}</span>
              {extractionJob.error && <Button className="secondary compact" onClick={() => setExtractionRetry((value) => value + 1)}><RefreshIcon /> Retry status</Button>}
            </Notice>
          ) : document.status !== 'ready' ? (
            <div className="document-processing" role="status" aria-live="polite">
              <h3>{extractionJob.data?.status === 'queued' ? 'Waiting for a worker' : 'Extracting your source'}</h3>
              <p>The text will appear here as soon as processing finishes.</p>
              <ProgressBar value={extractionJob.data?.progress ?? 0} label="Extraction progress" />
            </div>
          ) : textLoading ? (
            <LoadingState label="Downloading extracted text" />
          ) : textResult?.status === 'success' ? (
            <pre className="extracted-copy">{textResult.text}</pre>
          ) : textResult?.status === 'empty' ? (
            <Notice title="No text was extracted" tone="warning">The extraction completed, but the saved text is empty.</Notice>
          ) : (
            <div className="document-processing" role="alert">
              <h3>Extracted text could not be downloaded</h3>
              <p>{textResult?.status === 'error' ? textResult.message : 'The extracted text path is not available.'}</p>
              <Button className="secondary" onClick={() => setTextRetry((value) => value + 1)}><RefreshIcon /> Retry download</Button>
            </div>
          )}
        </Panel>
        <aside className="span-4 action-panel">
          <Panel className="generate-panel">
            <h3>Generate flashcards</h3>
            <p>Create a new deck from this document.</p>
            <div className="option-row" role="group" aria-label="Flashcard count">
              {([8, 12, 16] as const).map((count) => <Button key={count} aria-pressed={cardCount === count} className={cardCount === count ? 'selected' : ''} onClick={() => setCardCount(count)}>{count}</Button>)}
            </div>
            <Button className="primary full" disabled={document.status !== 'ready' || Boolean(generationBusy)} onClick={() => void generateDeck()}>{generationBusy === 'deck' ? 'Starting…' : `Generate ${cardCount} cards`}</Button>
            {existingDeckId && <Link className="text-action" to={`/library/${courseId}/deck/${existingDeckId}`}>Open latest generated deck</Link>}
          </Panel>
          <Panel className="generate-panel">
            <h3>Generate summary</h3>
            <p>Choose the level of detail.</p>
            <div className="option-row summary-options" role="group" aria-label="Summary depth">
              {(['tldr', 'detailed', 'eli5'] as const).map((value) => <Button key={value} aria-pressed={depth === value} className={depth === value ? 'selected' : ''} onClick={() => setDepth(value)}>{depthLabel(value)}</Button>)}
            </div>
            <Button className="secondary full" disabled={document.status !== 'ready' || Boolean(generationBusy)} onClick={() => void generateSummary()}>{generationBusy === 'summary' ? 'Starting…' : 'Generate summary'}</Button>
            {existingSummaryId && <Link className="text-action" to={`/library/${courseId}/document/${document.id}/summary/${existingSummaryId}`}>Open latest summary</Link>}
          </Panel>
          {jobVisible && (
            <Panel className="job-panel" aria-live="polite">
              <div className="job-head">
                <strong>{generationError ? 'Could not start generation' : resultReady ? 'Ready' : generationFailed ? 'Generation failed' : 'Generating in the background'}</strong>
                {!generationError && <Badge tone={resultReady ? 'success' : generationFailed ? 'danger' : 'warning'}>{generationFailed ? 'failed' : generationJob.data?.status ?? 'queued'}</Badge>}
              </div>
              <p>{generationError || resultError || (generationJob.data?.status === 'queued' ? 'Your job is queued.' : 'You can keep this page open while Cramly works.')}</p>
              {!generationError && !generationFailed && <ProgressBar value={resultReady ? 100 : generationJob.data?.progress ?? 0} label="Generation progress" />}
              {resultReady && resultId && resultType === 'deck' && <ButtonLink className="primary full" to={`/library/${courseId}/deck/${resultId}`}>Open deck</ButtonLink>}
              {resultReady && resultId && resultType === 'summary' && <ButtonLink className="primary full" to={`/library/${courseId}/document/${document.id}/summary/${resultId}`}>Open summary</ButtonLink>}
            </Panel>
          )}
          <Notice title="Deletion behavior">Generated decks and summaries remain if this source document is removed.</Notice>
        </aside>
      </div>
      <DeleteResourceDialog
        open={deleteOpen}
        title="Delete document?"
        resourceName={document.title}
        copy="The original upload and extracted text are removed. Generated decks and summaries are kept."
        busy={deleteBusy}
        error={deleteError}
        onClose={() => { setDeleteOpen(false); setDeleteError(null); }}
        onConfirm={deleteDocument}
      />
      <Toast message={toast} />
    </>
  );
}
