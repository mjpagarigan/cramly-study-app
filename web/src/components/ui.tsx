import {
  useEffect,
  useId,
  useRef,
  type ButtonHTMLAttributes,
  type HTMLAttributes,
  type KeyboardEvent,
  type ReactNode,
} from 'react';
import { Link, type LinkProps } from 'react-router-dom';
import { CloseIcon } from './Icons';

export function Brand({ compact = false }: { compact?: boolean }) {
  return (
    <span className="brand-lockup" aria-label="Cramly">
      <span className="brand-mark" aria-hidden="true" />
      {!compact && <span>Cramly</span>}
    </span>
  );
}

export function LearningTrace({ className = '' }: { className?: string }) {
  return (
    <svg
      className={`learning-trace ${className}`}
      viewBox="0 0 220 36"
      role="img"
      aria-label="Learning paths resolving into one trace"
      preserveAspectRatio="none"
    >
      <path d="M2 4H70L96 18" />
      <path d="M2 18H218" />
      <path d="M2 32H70L96 18" />
    </svg>
  );
}

export function PageHeader({
  eyebrow,
  title,
  copy,
  actions,
}: {
  eyebrow?: string;
  title: ReactNode;
  copy?: ReactNode;
  actions?: ReactNode;
}) {
  return (
    <header className="page-header">
      <div>
        {eyebrow && <p className="eyebrow">{eyebrow}</p>}
        <h1 className="page-title">{title}</h1>
        {copy && <div className="page-copy">{copy}</div>}
      </div>
      {actions && <div className="header-actions">{actions}</div>}
    </header>
  );
}

export function Button({ className = '', ...props }: ButtonHTMLAttributes<HTMLButtonElement>) {
  return <button className={`button ${className}`} {...props} />;
}

export function ButtonLink({ className = '', ...props }: LinkProps) {
  return <Link className={`button ${className}`} {...props} />;
}

export function containDialogFocus(event: KeyboardEvent<HTMLDialogElement>) {
  if (event.key !== 'Tab') return;
  const focusable = Array.from(event.currentTarget.querySelectorAll<HTMLElement>(
    'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])',
  )).filter((element) => element.getClientRects().length > 0);
  if (!focusable.length) {
    event.preventDefault();
    event.currentTarget.focus();
    return;
  }
  const first = focusable[0];
  const last = focusable.at(-1)!;
  if (event.shiftKey && document.activeElement === first) {
    event.preventDefault();
    last.focus();
  } else if (!event.shiftKey && document.activeElement === last) {
    event.preventDefault();
    first.focus();
  }
}

export function Panel({ className = '', ...props }: HTMLAttributes<HTMLElement>) {
  return <section className={`panel ${className}`} {...props} />;
}

export function Badge({ children, tone = 'neutral' }: {
  children: ReactNode;
  tone?: 'neutral' | 'success' | 'warning' | 'danger' | 'planned';
}) {
  return <span className={`badge ${tone}`}>{children}</span>;
}

export function Meta({ items }: { items: Array<ReactNode | null | undefined | false> }) {
  return <div className="meta">{items.filter(Boolean).map((item, index) => <span key={index}>{item}</span>)}</div>;
}

export function ProgressBar({ value, label = 'Progress' }: { value: number; label?: string }) {
  const clamped = Math.max(0, Math.min(100, value));
  return (
    <div
      className="progress-line"
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={clamped}
    >
      <b style={{ '--progress-scale': clamped / 100 } as React.CSSProperties} />
    </div>
  );
}

export function LoadingState({ label = 'Loading your study material' }: { label?: string }) {
  return (
    <div className="state-panel state-loading" role="status" aria-live="polite">
      <span className="sr-only">{label}</span>
      <div className="skeleton skeleton-title" />
      <div className="skeleton skeleton-copy" />
      <div className="skeleton skeleton-row" />
      <div className="skeleton skeleton-row short" />
    </div>
  );
}

export function ErrorState({ title = 'This could not be loaded', message, retry }: {
  title?: string;
  message?: string;
  retry?: () => void;
}) {
  return (
    <Panel className="empty-state" role="alert">
      <div>
        <h2>{title}</h2>
        <p>{message || 'Check your connection and try again.'}</p>
        {retry && <Button className="secondary" onClick={retry}>Try again</Button>}
      </div>
    </Panel>
  );
}

export function EmptyState({ title, copy, action }: {
  title: string;
  copy: string;
  action?: ReactNode;
}) {
  return (
    <Panel className="empty-state">
      <div>
        <h2>{title}</h2>
        <p>{copy}</p>
        {action && <div className="empty-action">{action}</div>}
      </div>
    </Panel>
  );
}

export function Notice({ title, children, tone = 'neutral' }: {
  title: string;
  children: ReactNode;
  tone?: 'neutral' | 'danger' | 'warning';
}) {
  return (
    <div className={`notice ${tone}`}>
      <strong>{title}</strong>
      <div>{children}</div>
    </div>
  );
}

export function Dialog({
  open,
  onClose,
  title,
  children,
  className = '',
}: {
  open: boolean;
  onClose(): void;
  title: string;
  children: ReactNode;
  className?: string;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  const titleId = useId();

  useEffect(() => {
    const dialog = ref.current;
    if (!dialog) return;
    if (open && !dialog.open) dialog.showModal();
    if (!open && dialog.open) dialog.close();
  }, [open]);

  return (
    <dialog
      ref={ref}
      className={`dialog-shell ${className}`}
      aria-labelledby={titleId}
      onKeyDown={containDialogFocus}
      onClose={onClose}
      onCancel={onClose}
      onMouseDown={(event) => {
        if (event.target === event.currentTarget) onClose();
      }}
    >
      <div className="dialog-card">
        <div className="dialog-head">
          <h2 id={titleId}>{title}</h2>
          <Button className="icon-button" aria-label="Close dialog" onClick={onClose}>
            <CloseIcon />
          </Button>
        </div>
        {children}
      </div>
    </dialog>
  );
}

export interface TabItem {
  id: string;
  label: string;
  disabled?: boolean;
}

export function Tabs({ tabs, active, onChange, label }: {
  tabs: TabItem[];
  active: string;
  onChange(id: string): void;
  label: string;
}) {
  const onKeyDown = (event: KeyboardEvent<HTMLButtonElement>) => {
    if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
    event.preventDefault();
    const enabled = tabs.filter((tab) => !tab.disabled);
    const currentIndex = enabled.findIndex((tab) => tab.id === active);
    let nextIndex = currentIndex;
    if (event.key === 'Home') nextIndex = 0;
    if (event.key === 'End') nextIndex = enabled.length - 1;
    if (event.key === 'ArrowRight') nextIndex = (currentIndex + 1) % enabled.length;
    if (event.key === 'ArrowLeft') nextIndex = (currentIndex - 1 + enabled.length) % enabled.length;
    const next = enabled[nextIndex];
    if (next) {
      onChange(next.id);
      document.getElementById(`tab-${next.id}`)?.focus();
    }
  };
  return (
    <div className="tabs" role="tablist" aria-label={label}>
      {tabs.map((tab) => (
        <button
          type="button"
          role="tab"
          id={`tab-${tab.id}`}
          key={tab.id}
          aria-selected={active === tab.id}
          aria-controls={`panel-${tab.id}`}
          tabIndex={active === tab.id ? 0 : -1}
          disabled={tab.disabled}
          className={active === tab.id ? 'active' : ''}
          onClick={() => onChange(tab.id)}
          onKeyDown={onKeyDown}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}

export function Toast({ message, tone = 'success' }: {
  message: string | null;
  tone?: 'success' | 'error';
}) {
  if (!message) return null;
  return <div className={`toast ${tone}`} role={tone === 'error' ? 'alert' : 'status'}>{message}</div>;
}

export function useDocumentTitle(title: string) {
  useEffect(() => {
    document.title = `${title} | Cramly`;
  }, [title]);
}
