/* Podcast Player */

const PodcastScreen = ({ onNavigate }) => {
  const { theme } = useTheme();
  const [playing, setPlaying] = React.useState(false);
  const [currentTime, setCurrentTime] = React.useState(0);
  const [speed, setSpeed] = React.useState(1);
  const [showTranscript, setShowTranscript] = React.useState(true);
  const duration = 754; // 12:34

  const transcript = [
    { speaker: 'A', time: 0, text: "So today we're diving into stereochemistry, which is basically about how atoms are arranged in 3D space." },
    { speaker: 'B', time: 18, text: "Right, and this matters because molecules that look the same on paper can actually behave completely differently." },
    { speaker: 'A', time: 32, text: "Exactly. The classic example is your hands — they're mirror images but you can't superimpose them." },
    { speaker: 'B', time: 45, text: "That's chirality. A chiral molecule has a carbon with four different groups attached." },
    { speaker: 'A', time: 58, text: "And when you have that, you get enantiomers — two molecules that are mirror images of each other." },
    { speaker: 'B', time: 72, text: "Which is wild because they have the same boiling point, same melting point, same everything — except how they rotate light." },
    { speaker: 'A', time: 88, text: "One rotates it clockwise, the other counterclockwise. That's optical activity." },
    { speaker: 'B', time: 100, text: "And in biology this matters a lot. Your body's enzymes are chiral, so they only interact with one form." },
  ];

  React.useEffect(() => {
    if (!playing) return;
    const interval = setInterval(() => {
      setCurrentTime(t => {
        if (t >= duration) { setPlaying(false); return duration; }
        return t + 1;
      });
    }, 1000 / speed);
    return () => clearInterval(interval);
  }, [playing, speed]);

  const formatTime = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;
  const activeLineIdx = [...transcript].reverse().findIndex(l => currentTime >= l.time);
  const activeLine = activeLineIdx >= 0 ? transcript.length - 1 - activeLineIdx : 0;

  return (
    <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.lg, display: 'flex', flexDirection: 'column', minHeight: '100%' }}>
      {/* Back */}
      <div onClick={() => onNavigate('library')} style={{
        display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer',
        color: theme.accent, fontSize: 14, fontWeight: 500, marginBottom: SPACING.xl,
      }}>
        <Icon name="chevronLeft" size={18} color={theme.accent} /> Back
      </div>

      {/* Hero card */}
      <div style={{
        borderRadius: RADIUS.xl, padding: SPACING.xxl, textAlign: 'center', marginBottom: SPACING.xl,
        background: `linear-gradient(135deg, ${theme.accent}20, ${theme.secondary}15)`,
        border: `1px solid ${theme.accent}15`,
      }}>
        <div style={{
          width: 80, height: 80, borderRadius: RADIUS.xl, margin: '0 auto 16px',
          background: `linear-gradient(135deg, ${theme.accent}, ${theme.secondary})`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 8px 30px ${theme.accent}30`,
        }}>
          <Icon name="podcast" size={36} color="#0F1523" />
        </div>
        <h2 style={{ fontSize: 20, fontWeight: 700, color: theme.text, marginBottom: 4 }}>Stereochemistry Overview</h2>
        <p style={{ fontSize: 13, color: theme.textMuted }}>From Chapter 5 — Stereochemistry.pdf · 12:34</p>
      </div>

      {/* Waveform / progress */}
      <div style={{ marginBottom: SPACING.lg }}>
        <div style={{ display: 'flex', gap: 2, alignItems: 'center', height: 40, marginBottom: 8 }}
          onClick={(e) => {
            const rect = e.currentTarget.getBoundingClientRect();
            const pct = (e.clientX - rect.left) / rect.width;
            setCurrentTime(Math.floor(pct * duration));
          }}>
          {Array.from({ length: 60 }, (_, i) => {
            const pct = i / 60;
            const h = 8 + Math.sin(i * 0.7) * 12 + Math.cos(i * 1.3) * 8;
            const past = pct <= currentTime / duration;
            return (
              <div key={i} style={{
                flex: 1, height: Math.max(4, h), borderRadius: 2,
                background: past
                  ? `linear-gradient(to top, ${theme.accent}, ${theme.secondary})`
                  : theme.bgCard,
                transition: 'background 0.15s ease',
                cursor: 'pointer',
              }} />
            );
          })}
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          <span style={{ fontFamily: FONT.mono, fontSize: 12, color: theme.textMuted }}>{formatTime(currentTime)}</span>
          <span style={{ fontFamily: FONT.mono, fontSize: 12, color: theme.textMuted }}>{formatTime(duration)}</span>
        </div>
      </div>

      {/* Controls */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 24, marginBottom: SPACING.xl }}>
        <div onClick={() => setCurrentTime(Math.max(0, currentTime - 15))} style={{ cursor: 'pointer', padding: 8 }}>
          <Icon name="rewind" size={22} color={theme.textSecondary} />
        </div>
        <div onClick={() => setPlaying(!playing)} style={{
          width: 56, height: 56, borderRadius: '50%', background: theme.accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          boxShadow: `0 4px 16px ${theme.accent}40`,
        }}>
          <Icon name={playing ? 'pause' : 'play'} size={22} color="#0F1523" />
        </div>
        <div onClick={() => setCurrentTime(Math.min(duration, currentTime + 15))} style={{ cursor: 'pointer', padding: 8 }}>
          <Icon name="skip" size={22} color={theme.textSecondary} />
        </div>
      </div>

      {/* Speed selector */}
      <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginBottom: SPACING.xl }}>
        {[0.5, 1, 1.25, 1.5, 2].map(s => (
          <div key={s} onClick={() => setSpeed(s)} style={{
            padding: '5px 10px', borderRadius: RADIUS.full, fontSize: 12, fontWeight: 600,
            fontFamily: FONT.mono, cursor: 'pointer',
            background: speed === s ? theme.accent : theme.bgCard,
            color: speed === s ? '#0F1523' : theme.textMuted,
            border: `1px solid ${speed === s ? theme.accent : theme.border}`,
          }}>
            {s}x
          </div>
        ))}
      </div>

      {/* Transcript toggle */}
      <div onClick={() => setShowTranscript(!showTranscript)} style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        padding: '10px 0', borderTop: `1px solid ${theme.border}`, cursor: 'pointer',
      }}>
        <span style={{ fontSize: 14, fontWeight: 600, color: theme.text }}>Transcript</span>
        <Icon name={showTranscript ? 'chevronLeft' : 'chevronRight'} size={16} color={theme.textMuted}
          style={{ transform: showTranscript ? 'rotate(-90deg)' : 'rotate(90deg)' }} />
      </div>

      {/* Transcript */}
      {showTranscript && (
        <div style={{ flex: 1, overflow: 'auto', paddingBottom: SPACING.xxxl }}>
          {transcript.map((line, i) => (
            <div key={i}
              onClick={() => setCurrentTime(line.time)}
              style={{
                display: 'flex', gap: 12, padding: '10px 0', cursor: 'pointer',
                opacity: i === activeLine ? 1 : 0.5, transition: 'opacity 0.3s ease',
              }}>
              <div style={{
                width: 28, height: 28, borderRadius: '50%', flexShrink: 0,
                background: line.speaker === 'A' ? theme.accentSubtle : theme.secondarySubtle,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 11, fontWeight: 700,
                color: line.speaker === 'A' ? theme.accent : theme.secondary,
              }}>
                {line.speaker}
              </div>
              <div>
                <p style={{
                  fontSize: 14, color: theme.text, lineHeight: 1.5,
                  fontWeight: i === activeLine ? 500 : 400,
                }}>{line.text}</p>
                <p style={{ fontSize: 11, color: theme.textMuted, fontFamily: FONT.mono, marginTop: 2 }}>
                  {formatTime(line.time)}
                </p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

Object.assign(window, { PodcastScreen });
