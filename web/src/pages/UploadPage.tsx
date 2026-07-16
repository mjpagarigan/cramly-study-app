import { useEffect, useMemo, useRef, useState, type ChangeEvent } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { CourseFormDialog } from '../components/CourseDialogs';
import { ArrowLeftIcon, FileIcon, PlusIcon, RefreshIcon, UploadIcon } from '../components/Icons';
import {
  Button,
  ButtonLink,
  LearningTrace,
  Notice,
  PageHeader,
  Panel,
  ProgressBar,
  useDocumentTitle,
} from '../components/ui';
import { useAuth } from '../contexts/AuthContext';
import { useCourses, useJob, useStudyDocument } from '../hooks/useFirestore';
import { courseApi, documentApi } from '../lib/api';
import { fileSize, friendlyError } from '../lib/format';
import {
  uploadFile,
  validateFile,
  validateSourceUrl,
  type ValidatedFile,
} from '../lib/upload';

type SourceChoice = 'file' | 'audio' | 'youtube' | 'web_url';
type ProcessPhase = 'idle' | 'uploading' | 'registering' | 'extracting' | 'ready' | 'failed';
type FailurePoint = 'upload' | 'registration' | 'extraction' | null;

const sourceOptions: Array<{ id: SourceChoice; title: string; copy: string; accept?: string }> = [
  { id: 'file', title: 'File', copy: 'PDF, DOCX, PPTX, Markdown, or image', accept: '.pdf,.docx,.pptx,.md,.markdown,.png,.jpg,.jpeg,.webp,.bmp,.tif,.tiff' },
  { id: 'audio', title: 'Audio', copy: 'MP3, M4A, WAV, FLAC, OGG, or WebM', accept: '.mp3,.m4a,.wav,.flac,.ogg,.webm,audio/*' },
  { id: 'youtube', title: 'YouTube', copy: 'English captions are required' },
  { id: 'web_url', title: 'Web page', copy: 'Use a public article URL' },
];

export function UploadPage() {
  useDocumentTitle('Upload material');
  const { user } = useAuth();
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const preselectedCourse = searchParams.get('courseId') || '';
  const courses = useCourses(user?.uid);
  const inputRef = useRef<HTMLInputElement>(null);
  const [stage, setStage] = useState(0);
  const [source, setSource] = useState<SourceChoice | null>(null);
  const [file, setFile] = useState<ValidatedFile | null>(null);
  const [url, setUrl] = useState('');
  const [sourceError, setSourceError] = useState<string | null>(null);
  const [courseId, setCourseId] = useState(preselectedCourse);
  const [courseDialog, setCourseDialog] = useState(false);
  const [courseBusy, setCourseBusy] = useState(false);
  const [courseError, setCourseError] = useState<string | null>(null);
  const [uploadedPath, setUploadedPath] = useState<string | null>(null);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [createdDocumentId, setCreatedDocumentId] = useState<string | null>(null);
  const [phase, setPhase] = useState<ProcessPhase>('idle');
  const [failurePoint, setFailurePoint] = useState<FailurePoint>(null);
  const [processError, setProcessError] = useState<string | null>(null);
  const [statusRetry, setStatusRetry] = useState(0);
  const documentState = useStudyDocument(user?.uid, createdDocumentId ?? undefined, statusRetry);
  const extractionJobId = documentState.data?.extractionJobId ?? undefined;
  const jobState = useJob(user?.uid, extractionJobId, statusRetry);

  useEffect(() => {
    if (courses.loading) return;
    if (!courses.data.length) {
      if (courseId) setCourseId('');
      return;
    }
    if (courses.data.some((course) => course.id === courseId)) return;
    const requested = courses.data.find((course) => course.id === preselectedCourse);
    setCourseId(requested?.id ?? courses.data[0].id);
  }, [courseId, courses.data, courses.loading, preselectedCourse]);

  useEffect(() => {
    if (stage !== 3) return;
    if (documentState.data?.status === 'ready') {
      setPhase('ready');
      setFailurePoint(null);
      setProcessError(null);
    } else if (
      documentState.data?.status === 'failed'
      || jobState.data?.status === 'failed'
      || documentState.error
      || jobState.error
    ) {
      setPhase('failed');
      setFailurePoint('extraction');
      setProcessError(
        documentState.data?.errorMessage
        || jobState.data?.errorMessage
        || documentState.error?.message
        || jobState.error?.message
        || 'Text extraction failed.',
      );
    } else if (documentState.data) {
      setPhase('extracting');
    }
  }, [documentState.data, documentState.error, jobState.data, jobState.error, stage]);

  const selectedCourse = courses.data.find((course) => course.id === courseId);
  const combinedProgress = phase === 'uploading'
    ? Math.round(uploadProgress * 0.8)
    : phase === 'registering'
      ? 82
      : phase === 'extracting'
        ? Math.max(84, Math.min(99, 84 + Math.round((jobState.data?.progress ?? 0) * 0.15)))
        : phase === 'ready' ? 100 : 0;

  const chooseSource = (choice: SourceChoice) => {
    setSource(choice);
    setSourceError(null);
    setFile(null);
    setUrl('');
    setUploadedPath(null);
    if (choice === 'file' || choice === 'audio') {
      window.setTimeout(() => inputRef.current?.click(), 0);
    }
  };

  const chooseFile = (event: ChangeEvent<HTMLInputElement>) => {
    const selected = event.target.files?.[0];
    event.target.value = '';
    if (!selected) return;
    try {
      const validated = validateFile(selected);
      if (source === 'audio' && validated.sourceType !== 'audio') {
        throw new Error('Choose a supported audio recording.');
      }
      if (source === 'file' && validated.sourceType === 'audio') {
        throw new Error('Use the Audio source for recordings.');
      }
      setFile(validated);
      setSourceError(null);
    } catch (error) {
      setFile(null);
      setSourceError(friendlyError(error));
    }
  };

  const toReview = () => {
    if ((source === 'file' || source === 'audio') && !file) {
      setSourceError('Choose a file before continuing.');
      return;
    }
    if (!source) {
      setSourceError('Choose one source.');
      return;
    }
    setStage(1);
  };

  const toCourse = () => {
    if (source === 'youtube' || source === 'web_url') {
      try {
        const normalized = validateSourceUrl(url, source);
        setUrl(normalized);
      } catch (error) {
        setSourceError(friendlyError(error));
        return;
      }
    }
    setSourceError(null);
    setStage(2);
  };

  const process = async () => {
    if (!user || !source || !courseId) return;
    setStage(3);
    setFailurePoint(null);
    setProcessError(null);
    setStatusRetry(0);
    let attemptPoint: Exclude<FailurePoint, null> = 'registration';
    try {
      if (source === 'file' || source === 'audio') {
        if (!file) throw new Error('The selected file is no longer available.');
        let storagePath = uploadedPath;
        if (!storagePath) {
          attemptPoint = 'upload';
          setPhase('uploading');
          storagePath = await uploadFile(user.uid, file, setUploadProgress);
          setUploadedPath(storagePath);
        }
        attemptPoint = 'registration';
        setPhase('registering');
        const created = await documentApi.createFromFile({
          courseId,
          sourceType: file.sourceType,
          fileName: file.file.name,
          fileSize: file.file.size,
          storagePath,
          mimeType: file.mimeType,
        });
        setCreatedDocumentId(created.id);
      } else {
        attemptPoint = 'registration';
        setPhase('registering');
        const created = await documentApi.createFromUrl({
          courseId,
          sourceType: source,
          sourceUrl: url,
        });
        setCreatedDocumentId(created.id);
      }
      setPhase('extracting');
    } catch (error) {
      setPhase('failed');
      setFailurePoint(attemptPoint);
      setProcessError(friendlyError(error));
    }
  };

  const reset = () => {
    setStage(0);
    setSource(null);
    setFile(null);
    setUrl('');
    setSourceError(null);
    setUploadedPath(null);
    setUploadProgress(0);
    setCreatedDocumentId(null);
    setPhase('idle');
    setFailurePoint(null);
    setProcessError(null);
  };

  const createCourse = async (input: { name: string; color: string }) => {
    setCourseBusy(true);
    setCourseError(null);
    try {
      const course = await courseApi.create(input);
      setCourseId(course.id);
      setCourseDialog(false);
    } catch (error) {
      setCourseError(friendlyError(error));
    } finally {
      setCourseBusy(false);
    }
  };

  const stepLabels = ['Choose source', 'Review', 'Assign course', 'Process'];
  const sourceCopy = useMemo(() => sourceOptions.find((item) => item.id === source), [source]);

  return (
    <>
      <PageHeader eyebrow="Add material" title="Upload" copy="Choose one source, assign it to a course, then let Cramly extract the content." />
      <LearningTrace className="page-trace" />
      <div className="upload-layout">
        <aside className="panel upload-steps" aria-label="Upload steps">
          {stepLabels.map((label, index) => (
            <div className={`step ${stage === index ? 'active' : ''} ${stage > index ? 'complete' : ''}`} key={label} aria-current={stage === index ? 'step' : undefined}>
              <b>{stage > index ? '✓' : index + 1}</b><span>{label}</span>
            </div>
          ))}
        </aside>
        <Panel className="upload-stage-panel">
          {stage === 0 && (
            <section>
              <h2 className="panel-title">Choose a source</h2>
              <p className="page-copy">One source can be processed at a time.</p>
              <input
                className="sr-only"
                ref={inputRef}
                type="file"
                tabIndex={-1}
                accept={sourceOptions.find((item) => item.id === source)?.accept}
                onChange={chooseFile}
              />
              <div className="source-grid">
                {sourceOptions.map((option) => (
                  <button type="button" className={`source-choice ${source === option.id ? 'active' : ''}`} key={option.id} aria-pressed={source === option.id} onClick={() => chooseSource(option.id)}>
                    {option.id === 'file' || option.id === 'audio' ? <FileIcon /> : <span className="source-glyph" aria-hidden="true">{option.id === 'youtube' ? 'YT' : 'URL'}</span>}
                    <strong>{option.title}</strong><span>{option.copy}</span>
                  </button>
                ))}
              </div>
              {file && (
                <div className="selected-source" role="status">
                  <FileIcon /><span><strong>{file.file.name}</strong><small>{fileSize(file.file.size)} / {file.mimeType}</small></span>
                </div>
              )}
              {sourceError && <p className="form-message error" role="alert">{sourceError}</p>}
              <div className="stage-actions"><Button className="primary" disabled={!source || ((source === 'file' || source === 'audio') && !file)} onClick={toReview}>Continue</Button></div>
            </section>
          )}
          {stage === 1 && (
            <section>
              <h2 className="panel-title">Review source</h2>
              <div className="selected-source review-source">
                <FileIcon /><span><strong>{file?.file.name ?? sourceCopy?.title}</strong><small>{file ? `${fileSize(file.file.size)} / ${file.mimeType}` : sourceCopy?.copy}</small></span>
                <Button className="secondary compact" onClick={reset}>Clear</Button>
              </div>
              {(source === 'youtube' || source === 'web_url') && (
                <div className="field">
                  <label htmlFor="source-url">{source === 'youtube' ? 'YouTube URL or video ID' : 'Public article URL'}</label>
                  <input id="source-url" type="text" inputMode="url" value={url} aria-invalid={Boolean(sourceError)} aria-describedby="url-error" placeholder={source === 'youtube' ? 'https://youtube.com/watch?v=…' : 'https://example.com/article'} onChange={(event) => { setUrl(event.target.value); setSourceError(null); }} />
                  <span className="field-error" id="url-error">{sourceError}</span>
                </div>
              )}
              <div className="stage-actions split"><Button className="secondary" onClick={() => setStage(0)}><ArrowLeftIcon /> Back</Button><Button className="primary" onClick={toCourse}>Assign course</Button></div>
            </section>
          )}
          {stage === 2 && (
            <section>
              <h2 className="panel-title">Assign to a course</h2>
              {courses.loading ? <p role="status">Loading courses…</p> : courses.error ? <p className="form-message error" role="alert">{courses.error.message}</p> : (
                <div className="field">
                  <label htmlFor="upload-course">Course</label>
                  <select id="upload-course" value={courseId} onChange={(event) => setCourseId(event.target.value)}>
                    {!courses.data.length && <option value="">Create a course first</option>}
                    {courses.data.map((course) => <option value={course.id} key={course.id}>{course.name}</option>)}
                  </select>
                </div>
              )}
              <Button className="secondary inline-create" onClick={() => setCourseDialog(true)}><PlusIcon /> Create a new course</Button>
              <Notice title="After extraction">Generate 8-16 flashcards or create a TL;DR, Detailed, or ELI5 summary.</Notice>
              <div className="stage-actions split"><Button className="secondary" onClick={() => setStage(1)}><ArrowLeftIcon /> Back</Button><Button className="primary" disabled={!courseId || courses.loading} onClick={() => void process()}><UploadIcon /> Upload and process</Button></div>
            </section>
          )}
          {stage === 3 && (
            <section className="processing-stage" aria-live="polite" aria-busy={phase !== 'ready' && phase !== 'failed'}>
              <div className={`process-symbol ${phase}`} aria-hidden="true">{phase === 'ready' ? '✓' : phase === 'failed' ? '!' : ''}</div>
              <h2>{phase === 'ready' ? 'Document ready' : phase === 'failed' ? 'Processing stopped' : phase === 'uploading' ? 'Uploading material' : phase === 'registering' ? 'Starting extraction' : 'Extracting text'}</h2>
              <p>{phase === 'ready'
                ? `Your source is ready in ${selectedCourse?.name ?? 'the selected course'}.`
                : phase === 'failed'
                  ? processError
                  : phase === 'uploading'
                    ? 'Sending the selected file securely to your Cramly storage.'
                    : phase === 'registering'
                      ? 'Registering the upload with the processing service.'
                      : jobState.data?.status === 'queued'
                        ? 'Your extraction job is queued.'
                        : 'Reading the source and preparing searchable text.'}</p>
              {phase !== 'failed' && <ProgressBar value={combinedProgress} label="Upload and extraction progress" />}
              {phase === 'failed' && failurePoint === 'registration' && uploadedPath && (
                <Notice title="Your file is already uploaded" tone="warning">Retry registration without uploading the file again.</Notice>
              )}
              <div className="stage-actions process-actions">
                {phase === 'ready' && createdDocumentId && (
                  <>
                    <ButtonLink className="primary" to={`/library/${courseId}/document/${createdDocumentId}`}>Open document</ButtonLink>
                    <Button className="secondary" onClick={reset}>Upload another</Button>
                  </>
                )}
                {phase === 'failed' && failurePoint !== 'extraction' && (
                  <Button className="primary" onClick={() => void process()}><RefreshIcon /> {failurePoint === 'registration' ? 'Retry registration' : 'Try upload again'}</Button>
                )}
                {phase === 'failed' && failurePoint === 'extraction' && (
                  <Button className="primary" onClick={() => {
                    setPhase('extracting');
                    setFailurePoint(null);
                    setProcessError(null);
                    setStatusRetry((value) => value + 1);
                  }}><RefreshIcon /> Retry status</Button>
                )}
                {phase === 'failed' && (
                  <Button className="secondary" onClick={reset}>Choose another source</Button>
                )}
                {phase === 'failed' && createdDocumentId && (
                  <Button className="secondary" onClick={() => navigate(`/library/${courseId}/document/${createdDocumentId}`)}>Open failed document</Button>
                )}
              </div>
            </section>
          )}
        </Panel>
      </div>
      <CourseFormDialog open={courseDialog} busy={courseBusy} error={courseError} onClose={() => { setCourseDialog(false); setCourseError(null); }} onSubmit={createCourse} />
    </>
  );
}
