/* Study Screen — Flashcard SRS Review */

const StudyScreen = ({ onNavigate }) => {
  const { theme, mode } = useTheme();
  const [reviewing, setReviewing] = React.useState(false);
  const [flipped, setFlipped] = React.useState(false);
  const [cardIndex, setCardIndex] = React.useState(0);
  const [showHint, setShowHint] = React.useState(false);
  const [sessionDone, setSessionDone] = React.useState(false);
  const [results, setResults] = React.useState([]);

  const cards = [
    { front: 'What is a chiral center?', back: 'A carbon atom bonded to four different substituents, creating non-superimposable mirror images.', hint: 'Think about hands...', topic: 'Stereochemistry' },
    { front: 'Define enantiomers.', back: 'Stereoisomers that are non-superimposable mirror images of each other.', hint: 'Mirror, mirror...', topic: 'Stereochemistry' },
    { front: 'What is the Cahn-Ingold-Prelog priority system used for?', back: 'Assigning R/S configuration to chiral centers based on atomic number priority of substituents.', hint: 'R and S labels', topic: 'Nomenclature' },
    { front: 'What are diastereomers?', back: 'Stereoisomers that are not mirror images of each other. They have different physical properties.', hint: 'Not mirror images, not identical', topic: 'Stereochemistry' },
  ];

  const handleRate = (rating) => {
    setResults(prev => [...prev, { ...cards[cardIndex], rating }]);
    setFlipped(false);
    setShowHint(false);
    if (cardIndex < cards.length - 1) {
      setTimeout(() => setCardIndex(cardIndex + 1), 200);
    } else {
      setTimeout(() => setSessionDone(true), 200);
    }
  };

  // Session complete screen
  if (sessionDone) {
    const correct = results.filter(r => r.rating === 'good' || r.rating === 'easy').length;
    return (
      <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.xxxl, textAlign: 'center' }}>
        <div style={{
          width: 80, height: 80, borderRadius: '50%', background: theme.accentSubtle,
          display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 20px',
        }}>
          <Icon name="check" size={36} color={theme.accent} />
        </div>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: theme.text, marginBottom: 6 }}>Session complete</h2>
        <p style={{ fontSize: 14, color: theme.textMuted, marginBottom: SPACING.xxl }}>
          {cards.length} cards reviewed · {correct}/{cards.length} correct
        </p>

        <div style={{ display: 'flex', gap: 10, marginBottom: SPACING.xxl }}>
          {[
            { label: 'Time', value: '3:24', unit: 'min' },
            { label: 'Accuracy', value: `${Math.round(correct / cards.length * 100)}%`, unit: '' },
            { label: 'Streak', value: '8', unit: 'days' },
          ].map((s, i) => (
            <Card key={i} style={{ flex: 1, textAlign: 'center' }} padding={14}>
              <p style={{ fontFamily: FONT.mono, fontSize: 22, fontWeight: 700, color: [theme.accent, theme.secondary, theme.success][i] }}>{s.value}</p>
              <p style={{ fontSize: 11, color: theme.textMuted, marginTop: 2 }}>{s.label}</p>
            </Card>
          ))}
        </div>

        <Button fullWidth onClick={() => { setSessionDone(false); setCardIndex(0); setResults([]); setReviewing(false); }}>
          Done
        </Button>
        <div style={{ height: 10 }} />
        <Button variant="secondary" fullWidth onClick={() => { setSessionDone(false); setCardIndex(0); setResults([]); }}>
          Review again
        </Button>
      </div>
    );
  }

  // Active review
  if (reviewing) {
    const card = cards[cardIndex];
    return (
      <div style={{ padding: `0 ${SPACING.xl}px`, paddingTop: SPACING.lg, height: '100%', display: 'flex', flexDirection: 'column' }}>
        {/* Top bar */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: SPACING.xl }}>
          <div onClick={() => setReviewing(false)} style={{ cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6 }}>
            <Icon name="close" size={20} color={theme.textMuted} />
          </div>
          <span style={{ fontSize: 13, color: theme.textMuted, fontFamily: FONT.mono }}>
            {cardIndex + 1}/{cards.length}
          </span>
          <Badge color="accent">{card.topic}</Badge>
        </div>

        {/* Progress bar */}
        <div style={{ height: 3, borderRadius: 2, background: theme.border, marginBottom: SPACING.xxl, overflow: 'hidden' }}>
          <div style={{
            width: `${((cardIndex + (flipped ? 1 : 0.5)) / cards.length) * 100}%`,
            height: '100%', borderRadius: 2,
            background: `linear-gradient(90deg, ${theme.accent}, ${theme.secondary})`,
            transition: 'width 0.4s ease',
          }} />
        </div>

        {/* Card */}
        <div
          onClick={() => !flipped && setFlipped(true)}
          style={{
            flex: 1, perspective: 1000, cursor: flipped ? 'default' : 'pointer',
            maxHeight: 380, marginBottom: SPACING.xl,
          }}
        >
          <div style={{
            width: '100%', height: '100%', position: 'relative',
            transformStyle: 'preserve-3d',
            transform: flipped ? 'rotateY(180deg)' : 'rotateY(0)',
            transition: 'transform 0.5s cubic-bezier(0.4, 0, 0.2, 1)',
          }}>
            {/* Front */}
            <div style={{
              position: 'absolute', inset: 0, backfaceVisibility: 'hidden',
              background: theme.bgCard, borderRadius: RADIUS.xl, padding: SPACING.xxl,
              border: `1px solid ${theme.border}`,
              display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center',
            }}>
              <p style={{ fontSize: 20, fontWeight: 600, color: theme.text, textAlign: 'center', lineHeight: 1.5 }}>
                {card.front}
              </p>
              {!showHint && (
                <p onClick={(e) => { e.stopPropagation(); setShowHint(true); }} style={{
                  fontSize: 13, color: theme.accent, marginTop: SPACING.xl, cursor: 'pointer', fontWeight: 500,
                }}>Show hint</p>
              )}
              {showHint && (
                <p style={{ fontSize: 14, color: theme.textSecondary, marginTop: SPACING.lg, fontStyle: 'italic', textAlign: 'center' }}>
                  {card.hint}
                </p>
              )}
              <p style={{ fontSize: 12, color: theme.textMuted, marginTop: 'auto', paddingTop: SPACING.lg }}>Tap to reveal</p>
            </div>
            {/* Back */}
            <div style={{
              position: 'absolute', inset: 0, backfaceVisibility: 'hidden',
              transform: 'rotateY(180deg)',
              background: theme.bgCard, borderRadius: RADIUS.xl, padding: SPACING.xxl,
              border: `1px solid rgba(232,168,76,0.15)`,
              display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center',
            }}>
              <p style={{ fontSize: 18, fontWeight: 500, color: theme.text, textAlign: 'center', lineHeight: 1.6 }}>
                {card.back}
              </p>
            </div>
          </div>
        </div>

        {/* Rating buttons */}
        {flipped && (
          <div style={{ display: 'flex', gap: 8, marginBottom: SPACING.xxl, animation: 'fadeIn 0.3s ease' }}>
            {[
              { label: 'Again', color: theme.error, key: 'again' },
              { label: 'Hard', color: theme.textSecondary, key: 'hard' },
              { label: 'Good', color: theme.success, key: 'good' },
              { label: 'Easy', color: theme.accent, key: 'easy' },
            ].map(btn => (
              <div key={btn.key} onClick={() => handleRate(btn.key)} style={{
                flex: 1, padding: '14px 0', borderRadius: RADIUS.md, textAlign: 'center',
                background: `${btn.color}15`, color: btn.color, fontSize: 14, fontWeight: 600,
                cursor: 'pointer', transition: 'all 0.15s ease', border: `1px solid ${btn.color}20`,
              }}>
                {btn.label}
              </div>
            ))}
          </div>
        )}
      </div>
    );
  }

  // Study hub
  return (
    <div style={{ padding: `0 ${SPACING.xl}px ${SPACING.xxxl}px`, paddingTop: SPACING.lg }}>
      <h1 style={{ fontSize: 26, fontWeight: 700, color: theme.text, marginBottom: SPACING.xl, letterSpacing: -0.3 }}>Study</h1>

      {/* Due cards CTA */}
      <Card glow style={{ marginBottom: SPACING.xl }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <ProgressRing value={0.35} size={56} strokeWidth={4} />
          <div style={{ flex: 1 }}>
            <p style={{ fontSize: 18, fontWeight: 600, color: theme.text }}>14 cards due</p>
            <p style={{ fontSize: 13, color: theme.textMuted }}>Across 3 decks · ~8 min</p>
          </div>
        </div>
        <div style={{ marginTop: SPACING.lg }}>
          <Button fullWidth onClick={() => setReviewing(true)}>Start review</Button>
        </div>
      </Card>

      <SectionHeader>Study modes</SectionHeader>
      {[
        { icon: 'flash', title: 'Flashcard Review', desc: 'Spaced repetition for due cards', color: theme.accent },
        { icon: 'study', title: 'Practice Quiz', desc: 'Test yourself on any topic', color: theme.secondary },
        { icon: 'mic', title: 'Voice Quiz', desc: 'Hands-free study mode', color: theme.success },
      ].map((m, i) => (
        <Card key={i} onClick={() => i === 0 ? setReviewing(true) : (i === 1 ? onNavigate('quiz') : null)} style={{ marginBottom: SPACING.sm }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 44, height: 44, borderRadius: RADIUS.md, background: `${m.color}18`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name={m.icon} size={20} color={m.color} />
            </div>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 15, fontWeight: 500, color: theme.text }}>{m.title}</p>
              <p style={{ fontSize: 13, color: theme.textMuted }}>{m.desc}</p>
            </div>
            <Icon name="chevronRight" size={18} color={theme.textMuted} />
          </div>
        </Card>
      ))}

      <div style={{ marginTop: SPACING.xl }}>
        <SectionHeader>Decks</SectionHeader>
        {['Stereochemistry Basics', 'Reaction Mechanisms', 'Cell Biology Ch. 1-3'].map((d, i) => (
          <Card key={i} onClick={() => setReviewing(true)} style={{ marginBottom: SPACING.sm }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
              <ProgressRing value={[0.72, 0.45, 0.88][i]} size={40} strokeWidth={3} />
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 15, fontWeight: 500, color: theme.text }}>{d}</p>
                <p style={{ fontSize: 12, color: theme.textMuted }}>{[32, 28, 20][i]} cards · {[72, 45, 88][i]}%</p>
              </div>
              <Badge color={[2].includes(i) ? 'success' : 'accent'}>{[3, 8, 0][i]} due</Badge>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
};

Object.assign(window, { StudyScreen });
