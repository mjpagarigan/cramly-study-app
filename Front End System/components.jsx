/* Shared UI Components — Nightowl */

// ─── Icons (simple SVG) ─────────────────────────────────────────
const Icon = ({ name, size = 22, color = 'currentColor', style = {} }) => {
  const paths = {
    home: <><path d="M3 10.5L12 3l9 7.5V20a1 1 0 01-1 1H4a1 1 0 01-1-1v-9.5z" fill="none" stroke={color} strokeWidth="1.8"/><path d="M9 21V14h6v7" fill="none" stroke={color} strokeWidth="1.8"/></>,
    library: <><rect x="3" y="3" width="7" height="9" rx="1.5" fill="none" stroke={color} strokeWidth="1.8"/><rect x="14" y="3" width="7" height="5" rx="1.5" fill="none" stroke={color} strokeWidth="1.8"/><rect x="14" y="12" width="7" height="9" rx="1.5" fill="none" stroke={color} strokeWidth="1.8"/><rect x="3" y="16" width="7" height="5" rx="1.5" fill="none" stroke={color} strokeWidth="1.8"/></>,
    study: <><rect x="4" y="2" width="16" height="20" rx="2" fill="none" stroke={color} strokeWidth="1.8"/><path d="M8 7h8M8 11h5" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
    progress: <><circle cx="12" cy="12" r="9" fill="none" stroke={color} strokeWidth="1.8"/><path d="M12 7v5l3 3" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
    profile: <><circle cx="12" cy="8" r="4" fill="none" stroke={color} strokeWidth="1.8"/><path d="M4 20c0-4 3.6-7 8-7s8 3 8 7" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
    plus: <><line x1="12" y1="5" x2="12" y2="19" stroke={color} strokeWidth="2" strokeLinecap="round"/><line x1="5" y1="12" x2="19" y2="12" stroke={color} strokeWidth="2" strokeLinecap="round"/></>,
    chevronRight: <path d="M9 6l6 6-6 6" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>,
    chevronLeft: <path d="M15 6l-6 6 6 6" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>,
    close: <><line x1="6" y1="6" x2="18" y2="18" stroke={color} strokeWidth="2" strokeLinecap="round"/><line x1="18" y1="6" x2="6" y2="18" stroke={color} strokeWidth="2" strokeLinecap="round"/></>,
    check: <path d="M5 12l5 5L19 7" fill="none" stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>,
    flash: <><path d="M13 2L4 14h7l-1 8 9-12h-7l1-8z" fill="none" stroke={color} strokeWidth="1.8" strokeLinejoin="round"/></>,
    mic: <><rect x="9" y="2" width="6" height="11" rx="3" fill="none" stroke={color} strokeWidth="1.8"/><path d="M5 11a7 7 0 0014 0M12 18v3M9 21h6" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
    play: <path d="M6 4l14 8-14 8V4z" fill={color} stroke="none"/>,
    pause: <><rect x="6" y="4" width="4" height="16" rx="1" fill={color}/><rect x="14" y="4" width="4" height="16" rx="1" fill={color}/></>,
    upload: <><path d="M12 16V4M12 4l-4 4M12 4l4 4" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/><path d="M4 14v5a2 2 0 002 2h12a2 2 0 002-2v-5" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
    doc: <><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8l-6-6z" fill="none" stroke={color} strokeWidth="1.8"/><path d="M14 2v6h6" fill="none" stroke={color} strokeWidth="1.8"/></>,
    podcast: <><circle cx="12" cy="12" r="2" fill="none" stroke={color} strokeWidth="1.8"/><path d="M8 16a5.66 5.66 0 01-1-3.16 5.66 5.66 0 019.33-4.34M16 16a5.66 5.66 0 001-3.16" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"/><path d="M5 19a9.66 9.66 0 01-1-4.33 9.66 9.66 0 0116-7.34M19 19a9.66 9.66 0 001-4.33" fill="none" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
    streak: <><path d="M12 2C8 7 4 10 4 14a8 8 0 0016 0c0-4-4-7-8-12z" fill="none" stroke={color} strokeWidth="1.8"/></>,
    sun: <><circle cx="12" cy="12" r="4" fill="none" stroke={color} strokeWidth="1.8"/><path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
    moon: <path d="M21 12.79A9 9 0 1111.21 3a7 7 0 009.79 9.79z" fill="none" stroke={color} strokeWidth="1.8"/>,
    skip: <><path d="M5 4l10 8-10 8V4z" fill="none" stroke={color} strokeWidth="1.8" strokeLinejoin="round"/><line x1="19" y1="4" x2="19" y2="20" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
    rewind: <><path d="M19 20L9 12l10-8v16z" fill="none" stroke={color} strokeWidth="1.8" strokeLinejoin="round"/><line x1="5" y1="4" x2="5" y2="20" stroke={color} strokeWidth="1.8" strokeLinecap="round"/></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" style={{ display: 'block', flexShrink: 0, ...style }}>
      {paths[name] || null}
    </svg>
  );
};

// ─── Buttons ────────────────────────────────────────────────────
const Button = ({ children, variant = 'primary', size = 'md', icon, onClick, disabled, style = {}, fullWidth }) => {
  const { theme } = useTheme();
  const [hover, setHover] = React.useState(false);
  const sizes = { sm: { padding: '8px 14px', fontSize: 13 }, md: { padding: '12px 20px', fontSize: 15 }, lg: { padding: '14px 24px', fontSize: 16 } };
  const variants = {
    primary: { background: hover ? theme.accentHover : theme.accent, color: '#0F1523', fontWeight: 600 },
    secondary: { background: hover ? theme.bgCardHover : theme.bgCard, color: theme.text, border: `1px solid ${theme.border}` },
    ghost: { background: hover ? theme.accentSubtle : 'transparent', color: theme.accent },
    destructive: { background: hover ? theme.error : theme.errorSubtle, color: hover ? '#fff' : theme.error },
  };
  return (
    <button
      onClick={onClick} disabled={disabled}
      onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
      style={{
        ...sizes[size], ...variants[variant],
        border: variants[variant].border || 'none',
        borderRadius: RADIUS.md, cursor: disabled ? 'default' : 'pointer',
        display: 'inline-flex', alignItems: 'center', gap: 8, justifyContent: 'center',
        fontFamily: FONT.body, transition: 'all 0.15s ease',
        opacity: disabled ? 0.5 : 1, width: fullWidth ? '100%' : 'auto',
        ...style,
      }}
    >
      {icon && <Icon name={icon} size={size === 'sm' ? 16 : 18} color="currentColor" />}
      {children}
    </button>
  );
};

// ─── Card ───────────────────────────────────────────────────────
const Card = ({ children, onClick, style = {}, padding = SPACING.lg, glow }) => {
  const { theme } = useTheme();
  const [hover, setHover] = React.useState(false);
  return (
    <div
      onClick={onClick}
      onMouseEnter={() => setHover(true)} onMouseLeave={() => setHover(false)}
      style={{
        background: hover && onClick ? theme.bgCardHover : theme.bgCard,
        borderRadius: RADIUS.lg, padding,
        border: `1px solid ${glow ? 'rgba(232,168,76,0.15)' : theme.border}`,
        boxShadow: glow ? '0 0 20px rgba(232,168,76,0.06)' : 'none',
        cursor: onClick ? 'pointer' : 'default',
        transition: 'all 0.15s ease',
        ...style,
      }}
    >
      {children}
    </div>
  );
};

// ─── Input ──────────────────────────────────────────────────────
const Input = ({ placeholder, value, onChange, type = 'text', icon, style = {} }) => {
  const { theme } = useTheme();
  const [focus, setFocus] = React.useState(false);
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      background: theme.bgInput, borderRadius: RADIUS.md,
      border: `1px solid ${focus ? theme.accent : theme.border}`,
      padding: '12px 14px', transition: 'border 0.15s ease', ...style,
    }}>
      {icon && <Icon name={icon} size={18} color={theme.textMuted} />}
      <input
        type={type} placeholder={placeholder} value={value}
        onChange={e => onChange?.(e.target.value)}
        onFocus={() => setFocus(true)} onBlur={() => setFocus(false)}
        style={{
          background: 'none', border: 'none', outline: 'none', flex: 1,
          color: theme.text, fontSize: 15, fontFamily: FONT.body,
        }}
      />
    </div>
  );
};

// ─── Bottom Sheet ───────────────────────────────────────────────
const BottomSheet = ({ open, onClose, title, children }) => {
  const { theme } = useTheme();
  if (!open) return null;
  return (
    <div style={{
      position: 'fixed', inset: 0, zIndex: 100,
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
    }}>
      <div onClick={onClose} style={{ flex: 1, background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(4px)' }} />
      <div style={{
        background: theme.bgElevated, borderRadius: `${RADIUS.xl}px ${RADIUS.xl}px 0 0`,
        padding: `${SPACING.xl}px ${SPACING.xl}px ${SPACING.xxxl}px`, maxHeight: '85vh', overflow: 'auto',
      }}>
        <div style={{ width: 36, height: 4, borderRadius: 2, background: theme.border, margin: '0 auto 16px' }} />
        {title && <h3 style={{ fontSize: 18, fontWeight: 600, color: theme.text, marginBottom: 16 }}>{title}</h3>}
        {children}
      </div>
    </div>
  );
};

// ─── Progress Ring ──────────────────────────────────────────────
const ProgressRing = ({ value = 0, size = 52, strokeWidth = 4 }) => {
  const { theme } = useTheme();
  const r = (size - strokeWidth) / 2;
  const circ = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={theme.border} strokeWidth={strokeWidth} />
      <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="url(#nightGrad)" strokeWidth={strokeWidth}
        strokeLinecap="round" strokeDasharray={`${value * circ} ${circ}`}
        transform={`rotate(-90 ${size/2} ${size/2})`}
        style={{ transition: 'stroke-dasharray 0.6s ease' }} />
      <defs>
        <linearGradient id="nightGrad" x1="0" y1="0" x2="1" y2="1">
          <stop stopColor="#E8A84C" /><stop offset="1" stopColor="#4CC8E8" />
        </linearGradient>
      </defs>
    </svg>
  );
};

// ─── Streak Dot Row ─────────────────────────────────────────────
const StreakDots = ({ days = 7 }) => {
  const { theme } = useTheme();
  return (
    <div style={{ display: 'flex', gap: 4, alignItems: 'center' }}>
      {Array.from({ length: 7 }, (_, i) => (
        <div key={i} style={{
          width: 8, height: 8, borderRadius: '50%',
          background: i < days ? theme.accent : theme.border,
          transition: 'background 0.3s ease',
        }} />
      ))}
    </div>
  );
};

// ─── Section Header ─────────────────────────────────────────────
const SectionHeader = ({ children, action, onAction }) => {
  const { theme } = useTheme();
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: SPACING.md }}>
      <span style={{
        fontSize: 11, fontWeight: 600, letterSpacing: 1.2,
        color: theme.textMuted, textTransform: 'uppercase',
      }}>{children}</span>
      {action && (
        <span onClick={onAction} style={{ fontSize: 13, color: theme.accent, cursor: 'pointer', fontWeight: 500 }}>{action}</span>
      )}
    </div>
  );
};

// ─── Badge ──────────────────────────────────────────────────────
const Badge = ({ children, color = 'accent' }) => {
  const { theme } = useTheme();
  const colors = {
    accent: { bg: theme.accentSubtle, text: theme.accent },
    secondary: { bg: theme.secondarySubtle, text: theme.secondary },
    success: { bg: theme.successSubtle, text: theme.success },
    error: { bg: theme.errorSubtle, text: theme.error },
  };
  const c = colors[color] || colors.accent;
  return (
    <span style={{
      fontSize: 11, fontWeight: 600, padding: '3px 8px', borderRadius: RADIUS.full,
      background: c.bg, color: c.text, letterSpacing: 0.3,
    }}>{children}</span>
  );
};

// ─── Toast ──────────────────────────────────────────────────────
const Toast = ({ message, type = 'info', visible }) => {
  const { theme } = useTheme();
  const colors = { info: theme.secondary, success: theme.success, error: theme.error };
  if (!visible) return null;
  return (
    <div style={{
      position: 'fixed', bottom: 100, left: '50%', transform: 'translateX(-50%)',
      background: theme.bgElevated, border: `1px solid ${colors[type]}30`,
      borderRadius: RADIUS.md, padding: '10px 18px', zIndex: 200,
      color: colors[type], fontSize: 14, fontWeight: 500, fontFamily: FONT.body,
      boxShadow: theme.shadow, animation: 'fadeIn 0.2s ease',
    }}>
      {message}
    </div>
  );
};

// ─── Skeleton ───────────────────────────────────────────────────
const Skeleton = ({ width = '100%', height = 16, radius = RADIUS.sm }) => {
  const { theme } = useTheme();
  return (
    <div style={{
      width, height, borderRadius: radius, background: theme.bgCard,
      animation: 'pulse 1.5s infinite ease-in-out',
    }} />
  );
};

// ─── Empty State ────────────────────────────────────────────────
const EmptyState = ({ title, subtitle, actionLabel, onAction, icon = 'plus' }) => {
  const { theme } = useTheme();
  return (
    <div style={{ textAlign: 'center', padding: `${SPACING.xxxl}px ${SPACING.xl}px` }}>
      <div style={{
        width: 56, height: 56, borderRadius: RADIUS.lg, background: theme.accentSubtle,
        display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 16px',
      }}>
        <Icon name={icon} size={24} color={theme.accent} />
      </div>
      <p style={{ fontSize: 16, fontWeight: 600, color: theme.text, marginBottom: 4 }}>{title}</p>
      <p style={{ fontSize: 14, color: theme.textMuted, marginBottom: 20, lineHeight: 1.5 }}>{subtitle}</p>
      {actionLabel && <Button onClick={onAction}>{actionLabel}</Button>}
    </div>
  );
};

Object.assign(window, {
  Icon, Button, Card, Input, BottomSheet, ProgressRing, StreakDots,
  SectionHeader, Badge, Toast, Skeleton, EmptyState,
});
