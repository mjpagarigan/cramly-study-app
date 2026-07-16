import { useEffect, useId, useState, type FormEvent } from 'react';
import type { Deck, DeckCard } from '../types';
import { Button, Dialog, Notice } from './ui';

export function DeckFormDialog({
  open,
  deck,
  busy,
  error,
  onClose,
  onSubmit,
}: {
  open: boolean;
  deck?: Deck | null;
  busy?: boolean;
  error?: string | null;
  onClose(): void;
  onSubmit(input: { title: string; description?: string }): Promise<void> | void;
}) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [titleError, setTitleError] = useState('');
  const [descriptionError, setDescriptionError] = useState('');
  const titleErrorId = useId();
  const descriptionErrorId = useId();
  const descriptionHelperId = useId();
  useEffect(() => {
    if (!open) return;
    setTitle(deck?.title ?? '');
    setDescription(deck?.description ?? '');
    setTitleError('');
    setDescriptionError('');
  }, [deck, open]);

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const trimmed = title.trim();
    if (!trimmed) {
      setTitleError('Enter a deck title.');
      return;
    }
    if (deck?.description && !description.trim()) {
      setDescriptionError('The current API cannot clear a saved description. Keep it or replace it.');
      return;
    }
    onSubmit({ title: trimmed, description: description.trim() || undefined });
  };
  return (
    <Dialog open={open} onClose={onClose} title={deck ? 'Edit deck' : 'Create a manual deck'}>
      <form className="form-grid" onSubmit={submit} noValidate>
        <div className="field">
          <label htmlFor="deck-title">Title</label>
          <input id="deck-title" value={title} maxLength={200} aria-invalid={Boolean(titleError)} aria-describedby={titleError ? titleErrorId : undefined} onChange={(event) => { setTitle(event.target.value); setTitleError(''); }} />
          {titleError && <span id={titleErrorId} className="field-error">{titleError}</span>}
        </div>
        <div className="field">
          <label htmlFor="deck-description">Description (optional)</label>
          <textarea
            id="deck-description"
            value={description}
            maxLength={500}
            aria-invalid={Boolean(descriptionError)}
            aria-describedby={[
              deck ? descriptionHelperId : '',
              descriptionError ? descriptionErrorId : '',
            ].filter(Boolean).join(' ') || undefined}
            onChange={(event) => {
              setDescription(event.target.value);
              setDescriptionError('');
            }}
          />
          {deck && <p id={descriptionHelperId} className="helper">The current API cannot clear a saved description. Keep it or replace it.</p>}
          {descriptionError && <span id={descriptionErrorId} className="field-error">{descriptionError}</span>}
        </div>
        {error && <p className="form-message error" role="alert">{error}</p>}
        <div className="dialog-actions">
          <Button type="button" className="secondary" onClick={onClose} disabled={busy}>Cancel</Button>
          <Button type="submit" className="primary" disabled={busy}>{busy ? 'Saving…' : 'Save deck'}</Button>
        </div>
      </form>
    </Dialog>
  );
}

export interface CardFormValue {
  front: string;
  back: string;
  hint?: string;
  explanation?: string;
  topic?: string;
}

export function CardFormDialog({
  open,
  card,
  busy,
  error,
  onClose,
  onSubmit,
}: {
  open: boolean;
  card?: DeckCard | null;
  busy?: boolean;
  error?: string | null;
  onClose(): void;
  onSubmit(input: CardFormValue): Promise<void> | void;
}) {
  const [front, setFront] = useState('');
  const [back, setBack] = useState('');
  const [hint, setHint] = useState('');
  const [explanation, setExplanation] = useState('');
  const [topic, setTopic] = useState('');
  const [fieldErrors, setFieldErrors] = useState<Partial<Record<'front' | 'back' | 'topic' | 'hint' | 'explanation', string>>>({});
  const frontErrorId = useId();
  const backErrorId = useId();
  const topicErrorId = useId();
  const hintErrorId = useId();
  const explanationErrorId = useId();
  const optionalHelperId = useId();
  useEffect(() => {
    if (!open) return;
    setFront(card?.front ?? '');
    setBack(card?.back ?? '');
    setHint(card?.hint ?? '');
    setExplanation(card?.explanation ?? '');
    setTopic(card?.topic ?? '');
    setFieldErrors({});
  }, [card, open]);
  const submit = (event: FormEvent) => {
    event.preventDefault();
    const nextErrors: typeof fieldErrors = {};
    if (!front.trim()) nextErrors.front = 'Enter the front of the card.';
    if (!back.trim()) nextErrors.back = 'Enter the back of the card.';
    if (card?.topic?.trim() && !topic.trim()) {
      nextErrors.topic = 'The current API cannot clear a saved topic. Keep it or replace it.';
    }
    if (card?.hint?.trim() && !hint.trim()) {
      nextErrors.hint = 'The current API cannot clear a saved hint. Keep it or replace it.';
    }
    if (card?.explanation?.trim() && !explanation.trim()) {
      nextErrors.explanation = 'The current API cannot clear a saved explanation. Keep it or replace it.';
    }
    setFieldErrors(nextErrors);
    if (Object.keys(nextErrors).length) {
      return;
    }
    onSubmit({
      front: front.trim(),
      back: back.trim(),
      hint: hint.trim() || undefined,
      explanation: explanation.trim() || undefined,
      topic: topic.trim() || undefined,
    });
  };
  return (
    <Dialog open={open} onClose={onClose} title={card ? 'Edit card' : 'Add a card'} className="wide-dialog">
      <form className="form-grid" onSubmit={submit} noValidate>
        <div className="form-columns">
          <div className="field">
            <label htmlFor="card-front">Front</label>
            <textarea id="card-front" value={front} maxLength={300} aria-invalid={Boolean(fieldErrors.front)} aria-describedby={fieldErrors.front ? frontErrorId : undefined} onChange={(event) => { setFront(event.target.value); setFieldErrors((current) => ({ ...current, front: undefined })); }} />
            {fieldErrors.front && <span id={frontErrorId} className="field-error">{fieldErrors.front}</span>}
          </div>
          <div className="field">
            <label htmlFor="card-back">Back</label>
            <textarea id="card-back" value={back} maxLength={2000} aria-invalid={Boolean(fieldErrors.back)} aria-describedby={fieldErrors.back ? backErrorId : undefined} onChange={(event) => { setBack(event.target.value); setFieldErrors((current) => ({ ...current, back: undefined })); }} />
            {fieldErrors.back && <span id={backErrorId} className="field-error">{fieldErrors.back}</span>}
          </div>
        </div>
        <div className="field">
          <label htmlFor="card-topic">Topic (optional)</label>
          <input id="card-topic" value={topic} maxLength={120} aria-invalid={Boolean(fieldErrors.topic)} aria-describedby={[card ? optionalHelperId : '', fieldErrors.topic ? topicErrorId : ''].filter(Boolean).join(' ') || undefined} onChange={(event) => { setTopic(event.target.value); setFieldErrors((current) => ({ ...current, topic: undefined })); }} />
          {fieldErrors.topic && <span id={topicErrorId} className="field-error">{fieldErrors.topic}</span>}
        </div>
        <div className="field">
          <label htmlFor="card-hint">Hint (optional)</label>
          <textarea id="card-hint" value={hint} maxLength={500} aria-invalid={Boolean(fieldErrors.hint)} aria-describedby={[card ? optionalHelperId : '', fieldErrors.hint ? hintErrorId : ''].filter(Boolean).join(' ') || undefined} onChange={(event) => { setHint(event.target.value); setFieldErrors((current) => ({ ...current, hint: undefined })); }} />
          {fieldErrors.hint && <span id={hintErrorId} className="field-error">{fieldErrors.hint}</span>}
        </div>
        <div className="field">
          <label htmlFor="card-explanation">Explanation (optional)</label>
          <textarea id="card-explanation" value={explanation} maxLength={2000} aria-invalid={Boolean(fieldErrors.explanation)} aria-describedby={[card ? optionalHelperId : '', fieldErrors.explanation ? explanationErrorId : ''].filter(Boolean).join(' ') || undefined} onChange={(event) => { setExplanation(event.target.value); setFieldErrors((current) => ({ ...current, explanation: undefined })); }} />
          {fieldErrors.explanation && <span id={explanationErrorId} className="field-error">{fieldErrors.explanation}</span>}
        </div>
        {card && <p id={optionalHelperId} className="helper">The current API cannot clear saved optional text. Keep each value or replace it.</p>}
        {error && <p className="form-message error" role="alert">{error}</p>}
        <div className="dialog-actions">
          <Button type="button" className="secondary" onClick={onClose} disabled={busy}>Cancel</Button>
          <Button type="submit" className="primary" disabled={busy}>{busy ? 'Saving…' : 'Save card'}</Button>
        </div>
      </form>
    </Dialog>
  );
}

export function DeleteResourceDialog({
  open,
  title,
  resourceName,
  copy,
  busy,
  error,
  onClose,
  onConfirm,
}: {
  open: boolean;
  title: string;
  resourceName: string;
  copy: string;
  busy?: boolean;
  error?: string | null;
  onClose(): void;
  onConfirm(): Promise<void> | void;
}) {
  return (
    <Dialog open={open} onClose={onClose} title={title}>
      <p><strong>{resourceName}</strong></p>
      <Notice title="This cannot be undone" tone="danger">{copy}</Notice>
      {error && <p className="form-message error" role="alert">{error}</p>}
      <div className="dialog-actions">
        <Button className="secondary" onClick={onClose} disabled={busy}>Cancel</Button>
        <Button className="danger" onClick={() => void onConfirm()} disabled={busy}>{busy ? 'Deleting…' : 'Delete'}</Button>
      </div>
    </Dialog>
  );
}
