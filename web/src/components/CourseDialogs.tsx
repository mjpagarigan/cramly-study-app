import { useEffect, useId, useState, type FormEvent } from 'react';
import type { Course } from '../types';
import { Button, Dialog, Notice } from './ui';

export const COURSE_COLORS = [
  '#477966',
  '#486F91',
  '#9B675F',
  '#7C6896',
  '#9B7B3E',
  '#6C7B55',
  '#556D72',
  '#825B69',
] as const;

export function CourseFormDialog({
  open,
  course,
  busy,
  error,
  onClose,
  onSubmit,
}: {
  open: boolean;
  course?: Course | null;
  busy?: boolean;
  error?: string | null;
  onClose(): void;
  onSubmit(input: { name: string; color: string }): Promise<void> | void;
}) {
  const [name, setName] = useState('');
  const [color, setColor] = useState<string>(COURSE_COLORS[0]);
  const [nameError, setNameError] = useState('');
  const errorId = useId();

  useEffect(() => {
    if (!open) return;
    setName(course?.name ?? '');
    setColor(course?.color ?? COURSE_COLORS[0]);
    setNameError('');
  }, [course, open]);

  const submit = (event: FormEvent) => {
    event.preventDefault();
    const trimmed = name.trim();
    if (!trimmed) {
      setNameError('Enter a course name.');
      return;
    }
    if (trimmed.length > 100) {
      setNameError('Use 100 characters or fewer.');
      return;
    }
    void onSubmit({ name: trimmed, color });
  };

  return (
    <Dialog open={open} onClose={onClose} title={course ? 'Edit course' : 'Create a course'}>
      <form className="form-grid" onSubmit={submit} noValidate>
        <div className="field">
          <label htmlFor="course-name">Course name</label>
          <input
            id="course-name"
            value={name}
            maxLength={100}
            autoComplete="off"
            aria-invalid={Boolean(nameError)}
            aria-describedby={nameError ? errorId : undefined}
            onChange={(event) => {
              setName(event.target.value);
              setNameError('');
            }}
          />
          <span className="field-error" id={errorId}>{nameError}</span>
        </div>
        <fieldset className="color-fieldset">
          <legend>Course color</legend>
          <div className="color-grid">
            {COURSE_COLORS.map((option) => (
              <button
                key={option}
                type="button"
                className={color.toLowerCase() === option.toLowerCase() ? 'active' : ''}
                style={{ '--course-color': option } as React.CSSProperties}
                aria-label={`Use ${option}`}
                aria-pressed={color.toLowerCase() === option.toLowerCase()}
                onClick={() => setColor(option)}
              />
            ))}
          </div>
        </fieldset>
        {error && <p className="form-message error" role="alert">{error}</p>}
        <div className="dialog-actions">
          <Button type="button" className="secondary" onClick={onClose} disabled={busy}>Cancel</Button>
          <Button type="submit" className="primary" disabled={busy}>
            {busy ? 'Saving…' : course ? 'Save changes' : 'Create course'}
          </Button>
        </div>
      </form>
    </Dialog>
  );
}

export function DeleteCourseDialog({
  open,
  course,
  busy,
  error,
  onClose,
  onConfirm,
}: {
  open: boolean;
  course: Course | null;
  busy?: boolean;
  error?: string | null;
  onClose(): void;
  onConfirm(): Promise<void> | void;
}) {
  return (
    <Dialog open={open} onClose={onClose} title="Delete course record?">
      <div className="confirm-copy">
        <p><strong>{course?.name}</strong> will disappear from the course list.</p>
        <Notice title="Materials are not deleted" tone="warning">
          Documents, decks, cards, and summaries must be removed separately.
        </Notice>
        {error && <p className="form-message error" role="alert">{error}</p>}
      </div>
      <div className="dialog-actions">
        <Button className="secondary" onClick={onClose} disabled={busy}>Keep course</Button>
        <Button className="danger" onClick={() => void onConfirm()} disabled={busy}>
          {busy ? 'Deleting…' : 'Delete record'}
        </Button>
      </div>
    </Dialog>
  );
}
