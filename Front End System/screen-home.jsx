/* Home Screen */

const HomeScreen = ({ onNavigate }) => {
  const { theme, mode } = useTheme();
  const { state } = useAppState();
  const dueCards = 14;
  const streak = state.streak || 7;
  const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const todayIdx = 4; // Friday

  return (
    <div style={{ padding: `0 ${SPACING.xl}px ${SPACING.xxxl}px`, paddingTop: SPACING.lg }}>
      {/* Greeting */}
      <p style={{ fontSize: 13, color: theme.textMuted, fontWeight: 500, marginBottom: 2 }}>
        {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' })}
      </p>
      <h1 style={{ fontSize: 26, fontWeight: 700, color: theme.text, marginBottom: SPACING.xl, letterSpacing: -0.3 }}>
        Good evening, Maya
      </h1>

      {/* Stats row */}
      <div style={{ display: 'flex', gap: 10, marginBottom: SPACING.xl }}>
        <Card style={{ flex: 1, borderColor: 'rgba(232,168,76,0.12)' }} padding={14}>
          <p style={{ fontFamily: FONT.mono, fontSize: 26, fontWeight: 700, color: theme.accent }}>{streak}</p>
          <p style={{ fontSize: 12, color: theme.textMuted, marginTop: 2 }}>day streak</p>
          <div style={{ marginTop: 8 }}><StreakDots days={streak > 7 ? 7 : streak} /></div>
        </Card>
        <Card style={{ flex: 1, borderColor: 'rgba(76,200,232,0.12)' }} padding={14}>
          <p style={{ fontFamily: FONT.mono, fontSize: 26, fontWeight: 700, color: theme.secondary }}>{dueCards}</p>
          <p style={{ fontSize: 12, color: theme.textMuted, marginTop: 2 }}>cards due</p>
          <div style={{ marginTop: 8 }}>
            <div style={{ height: 4, borderRadius: 2, background: theme.border, overflow: 'hidden' }}>
              <div style={{ width: '35%', height: '100%', borderRadius: 2, background: theme.secondary, transition: 'width 0.4s ease' }} />
            </div>
          </div>
        </Card>
      </div>

      {/* Continue card */}
      <div
        onClick={() => onNavigate('study')}
        style={{
          background: `linear-gradient(135deg, ${theme.accent}, ${mode === 'dark' ? '#D49540' : '#C08530'})`,
          borderRadius: RADIUS.xl, padding: '20px 22px', color: '#0F1523', marginBottom: SPACING.xl,
          cursor: 'pointer', transition: 'transform 0.15s ease',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <div>
            <p style={{ fontSize: 11, fontWeight: 600, letterSpacing: 0.5, opacity: 0.6, marginBottom: 6 }}>CONTINUE</p>
            <p style={{ fontSize: 18, fontWeight: 600, marginBottom: 4 }}>Organic Chemistry — Ch. 5</p>
            <p style={{ fontSize: 13, opacity: 0.7 }}>8 cards remaining · ~4 min</p>
          </div>
          <ProgressRing value={0.6} size={48} />
        </div>
      </div>

      {/* Suggested session */}
      <SectionHeader action="View all" onAction={() => onNavigate('study')}>Suggested</SectionHeader>
      <Card onClick={() => onNavigate('study')} style={{ marginBottom: SPACING.xl }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{
            width: 44, height: 44, borderRadius: RADIUS.md, background: theme.secondarySubtle,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="flash" size={20} color={theme.secondary} />
          </div>
          <div style={{ flex: 1 }}>
            <p style={{ fontSize: 15, fontWeight: 500, color: theme.text }}>Quick 5-minute review</p>
            <p style={{ fontSize: 13, color: theme.textMuted }}>12 cards across 3 decks</p>
          </div>
          <Icon name="chevronRight" size={18} color={theme.textMuted} />
        </div>
      </Card>

      {/* Recent documents */}
      <SectionHeader action="See all" onAction={() => onNavigate('library')}>Recent</SectionHeader>
      {[
        { title: 'Cell Biology Midterm', cards: 12, badge: 'Quiz ready', badgeColor: 'success' },
        { title: 'Linear Algebra — Ch. 3', cards: 8, badge: 'Podcast ready', badgeColor: 'secondary' },
        { title: 'Psych 101 Notes', cards: 20, badge: 'Summary', badgeColor: 'accent' },
      ].map((item, i) => (
        <Card key={i} onClick={() => onNavigate('library', { courseId: i })} style={{ marginBottom: SPACING.sm }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <div style={{
              width: 40, height: 40, borderRadius: RADIUS.sm, background: theme.accentSubtle,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="doc" size={18} color={theme.accent} />
            </div>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 15, fontWeight: 500, color: theme.text }}>{item.title}</p>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 3 }}>
                <span style={{ fontSize: 12, color: theme.textMuted }}>{item.cards} cards</span>
                <Badge color={item.badgeColor}>{item.badge}</Badge>
              </div>
            </div>
            <Icon name="chevronRight" size={18} color={theme.textMuted} />
          </div>
        </Card>
      ))}

      {/* Weekly heatmap preview */}
      <div style={{ marginTop: SPACING.xl }}>
        <SectionHeader action="Details" onAction={() => onNavigate('progress')}>This week</SectionHeader>
        <Card>
          <div style={{ display: 'flex', gap: 6, justifyContent: 'space-between' }}>
            {[0.9, 0.7, 0.4, 0.8, 0.6, 0, 0].map((v, i) => (
              <div key={i} style={{ textAlign: 'center', flex: 1 }}>
                <div style={{
                  width: '100%', paddingBottom: '100%', borderRadius: RADIUS.sm, position: 'relative',
                  background: v > 0
                    ? `oklch(${0.5 + v * 0.25} ${0.08 + v * 0.1} ${v > 0.5 ? 80 : 200})`
                    : theme.bgCard,
                  border: i <= todayIdx && v === 0 ? `1px dashed ${theme.border}` : 'none',
                  opacity: v > 0 ? 0.5 + v * 0.5 : 0.3,
                  boxShadow: v > 0.7 ? `0 0 8px oklch(${0.6 + v * 0.15} 0.12 80 / 0.3)` : 'none',
                  transition: 'all 0.3s ease',
                }} />
                <p style={{
                  fontSize: 10, color: i === todayIdx ? theme.accent : theme.textMuted,
                  fontWeight: i === todayIdx ? 600 : 400, marginTop: 4,
                }}>{weekdays[i]}</p>
              </div>
            ))}
          </div>
        </Card>
      </div>
    </div>
  );
};

Object.assign(window, { HomeScreen });
