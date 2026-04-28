/* Progress / Analytics Screen */

const ProgressScreen = ({ onNavigate }) => {
  const { theme } = useTheme();
  const [activeView, setActiveView] = React.useState('overview');

  // Heatmap data (7 cols x 5 rows = topics x days)
  const topics = ['Stereochemistry', 'Nomenclature', 'Reactions', 'Acid-Base', 'Spectroscopy', 'Thermodynamics', 'Kinetics', 'Bonding'];
  const mastery = [85, 62, 45, 78, 30, 55, 40, 72];
  const heatmapData = topics.map((t, i) => ({
    topic: t, mastery: mastery[i],
    days: Array.from({ length: 7 }, () => Math.random() * mastery[i] / 100),
  }));

  const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  return (
    <div style={{ padding: `0 ${SPACING.xl}px ${SPACING.xxxl}px`, paddingTop: SPACING.lg }}>
      <h1 style={{ fontSize: 26, fontWeight: 700, color: theme.text, marginBottom: SPACING.xl, letterSpacing: -0.3 }}>Progress</h1>

      {/* Overview stats */}
      <div style={{ display: 'flex', gap: 8, marginBottom: SPACING.xl }}>
        {[
          { value: '8', label: 'Day streak', color: theme.accent, icon: 'streak' },
          { value: '4.2h', label: 'This week', color: theme.secondary, icon: 'progress' },
          { value: '73%', label: 'Readiness', color: theme.success, icon: 'check' },
        ].map((s, i) => (
          <Card key={i} style={{ flex: 1, textAlign: 'center' }} padding={14}>
            <p style={{ fontFamily: FONT.mono, fontSize: 22, fontWeight: 700, color: s.color }}>{s.value}</p>
            <p style={{ fontSize: 11, color: theme.textMuted, marginTop: 2 }}>{s.label}</p>
          </Card>
        ))}
      </div>

      {/* Weekly trend */}
      <SectionHeader>Weekly study time</SectionHeader>
      <Card style={{ marginBottom: SPACING.xl }}>
        <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 80, justifyContent: 'space-between' }}>
          {[40, 65, 30, 80, 55, 20, 0].map((v, i) => (
            <div key={i} style={{ flex: 1, textAlign: 'center' }}>
              <div style={{
                height: `${Math.max(4, v)}%`, borderRadius: 4,
                background: i < 5
                  ? `linear-gradient(to top, ${theme.accent}, ${theme.secondary})`
                  : theme.bgElevated,
                marginBottom: 6, transition: 'height 0.5s ease',
                boxShadow: v > 60 ? `0 0 8px ${theme.accent}30` : 'none',
              }} />
              <span style={{ fontSize: 10, color: i === 4 ? theme.accent : theme.textMuted }}>{weekdays[i]}</span>
            </div>
          ))}
        </div>
      </Card>

      {/* Knowledge Heatmap */}
      <SectionHeader action="Expand" onAction={() => {}}>Knowledge heatmap</SectionHeader>
      <Card style={{ marginBottom: SPACING.xl, overflow: 'hidden' }}>
        {/* Column headers */}
        <div style={{ display: 'flex', paddingLeft: 90, marginBottom: 6 }}>
          {weekdays.map((d, i) => (
            <div key={i} style={{ flex: 1, textAlign: 'center', fontSize: 10, color: theme.textMuted }}>{d}</div>
          ))}
        </div>
        {/* Rows */}
        {heatmapData.map((row, ri) => (
          <div key={ri} style={{ display: 'flex', alignItems: 'center', marginBottom: 3 }}>
            <div style={{
              width: 86, fontSize: 11, color: theme.textSecondary, fontWeight: 500,
              overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', paddingRight: 6,
            }}>
              {row.topic}
            </div>
            <div style={{ flex: 1, display: 'flex', gap: 3 }}>
              {row.days.map((v, di) => (
                <div key={di} style={{
                  flex: 1, paddingBottom: '100%', position: 'relative',
                }}>
                  <div style={{
                    position: 'absolute', inset: 0, borderRadius: 4,
                    background: v > 0.01
                      ? `oklch(${0.35 + v * 0.4} ${0.06 + v * 0.12} ${v > 0.4 ? 80 : 200})`
                      : theme.bgElevated,
                    boxShadow: v > 0.6 ? `0 0 6px oklch(${0.5 + v * 0.2} 0.12 80 / 0.4)` : 'none',
                    transition: 'all 0.3s ease',
                  }} />
                </div>
              ))}
            </div>
          </div>
        ))}
        {/* Legend */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: 4, marginTop: 10 }}>
          <span style={{ fontSize: 10, color: theme.textMuted, marginRight: 4 }}>Low</span>
          {[0.1, 0.3, 0.5, 0.7, 0.9].map((v, i) => (
            <div key={i} style={{
              width: 12, height: 12, borderRadius: 3,
              background: `oklch(${0.35 + v * 0.4} ${0.06 + v * 0.12} ${v > 0.4 ? 80 : 200})`,
            }} />
          ))}
          <span style={{ fontSize: 10, color: theme.textMuted, marginLeft: 4 }}>High</span>
        </div>
      </Card>

      {/* Mastery breakdown */}
      <SectionHeader>Mastery by topic</SectionHeader>
      {topics.map((t, i) => (
        <Card key={i} style={{ marginBottom: SPACING.sm }} padding={12}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <span style={{ fontSize: 14, fontWeight: 500, color: theme.text }}>{t}</span>
            <span style={{ fontFamily: FONT.mono, fontSize: 13, fontWeight: 600, color: mastery[i] > 70 ? theme.success : mastery[i] > 40 ? theme.accent : theme.error }}>
              {mastery[i]}%
            </span>
          </div>
          <div style={{ height: 4, borderRadius: 2, background: theme.border, overflow: 'hidden' }}>
            <div style={{
              width: `${mastery[i]}%`, height: '100%', borderRadius: 2,
              background: mastery[i] > 70
                ? `linear-gradient(90deg, ${theme.success}, ${theme.success})`
                : mastery[i] > 40
                ? `linear-gradient(90deg, ${theme.accent}, ${theme.secondary})`
                : theme.error,
              transition: 'width 0.6s ease',
            }} />
          </div>
        </Card>
      ))}

      {/* Readiness score */}
      <div style={{ marginTop: SPACING.xl }}>
        <SectionHeader>Exam readiness</SectionHeader>
        <Card glow>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <div style={{ position: 'relative' }}>
              <ProgressRing value={0.73} size={64} strokeWidth={5} />
              <div style={{ position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <span style={{ fontFamily: FONT.mono, fontSize: 18, fontWeight: 700, color: theme.accent }}>73</span>
              </div>
            </div>
            <div style={{ flex: 1 }}>
              <p style={{ fontSize: 16, fontWeight: 600, color: theme.text }}>Organic Chemistry</p>
              <p style={{ fontSize: 13, color: theme.textMuted, lineHeight: 1.5 }}>
                Good coverage. Focus on Spectroscopy and Kinetics to improve.
              </p>
            </div>
          </div>
        </Card>
      </div>

      {/* Weakness recommendations */}
      <div style={{ marginTop: SPACING.xl }}>
        <SectionHeader>Recommended focus</SectionHeader>
        {[
          { topic: 'Spectroscopy', time: '15 min', reason: 'Lowest mastery' },
          { topic: 'Kinetics', time: '10 min', reason: 'Declining retention' },
        ].map((r, i) => (
          <Card key={i} onClick={() => onNavigate('study')} style={{ marginBottom: SPACING.sm }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{
                width: 40, height: 40, borderRadius: RADIUS.md, background: theme.errorSubtle,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <Icon name="flash" size={18} color={theme.error} />
              </div>
              <div style={{ flex: 1 }}>
                <p style={{ fontSize: 14, fontWeight: 500, color: theme.text }}>{r.topic}</p>
                <p style={{ fontSize: 12, color: theme.textMuted }}>{r.reason} · {r.time}</p>
              </div>
              <Icon name="chevronRight" size={16} color={theme.textMuted} />
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
};

Object.assign(window, { ProgressScreen });
