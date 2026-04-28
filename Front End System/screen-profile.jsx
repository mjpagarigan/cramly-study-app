/* Profile / Settings Screen */

const ProfileScreen = () => {
  const { theme, mode, toggle } = useTheme();

  const sections = [
    {
      title: 'Preferences', items: [
        { label: 'Theme', value: mode === 'dark' ? 'Dark' : 'Light', action: toggle, icon: mode === 'dark' ? 'moon' : 'sun' },
        { label: 'Daily study goal', value: '30 min', icon: 'progress' },
        { label: 'Review reminders', value: '9:00 AM', icon: 'streak' },
      ]
    },
    {
      title: 'Account', items: [
        { label: 'Email', value: 'maya@university.edu', icon: 'profile' },
        { label: 'Usage limits', value: '12/30 generations', icon: 'flash' },
        { label: 'Data export', icon: 'upload' },
      ]
    },
    {
      title: 'Support', items: [
        { label: 'Help & FAQ', icon: 'doc' },
        { label: 'About', value: 'v1.0.0', icon: 'study' },
      ]
    },
  ];

  return (
    <div style={{ padding: `0 ${SPACING.xl}px ${SPACING.xxxl}px`, paddingTop: SPACING.lg }}>
      <h1 style={{ fontSize: 26, fontWeight: 700, color: theme.text, marginBottom: SPACING.xl, letterSpacing: -0.3 }}>Profile</h1>

      {/* Avatar + name */}
      <Card style={{ marginBottom: SPACING.xxl }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <div style={{
            width: 56, height: 56, borderRadius: '50%',
            background: `linear-gradient(135deg, ${theme.accent}, ${theme.secondary})`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 22, fontWeight: 700, color: '#0F1523',
          }}>M</div>
          <div>
            <p style={{ fontSize: 18, fontWeight: 600, color: theme.text }}>Maya Chen</p>
            <p style={{ fontSize: 13, color: theme.textMuted }}>maya@university.edu</p>
          </div>
        </div>
      </Card>

      {/* Usage card */}
      <Card style={{ marginBottom: SPACING.xxl, borderColor: theme.accent + '15' }}>
        <p style={{ fontSize: 12, fontWeight: 600, letterSpacing: 0.8, color: theme.textMuted, marginBottom: 12 }}>TODAY'S USAGE</p>
        <div style={{ display: 'flex', gap: 12 }}>
          {[
            { label: 'Podcasts', used: 1, max: 3, color: theme.accent },
            { label: 'Generations', used: 12, max: 30, color: theme.secondary },
            { label: 'Uploads', used: 3, max: 50, color: theme.success },
          ].map((u, i) => (
            <div key={i} style={{ flex: 1, textAlign: 'center' }}>
              <p style={{ fontFamily: FONT.mono, fontSize: 16, fontWeight: 700, color: u.color }}>{u.used}<span style={{ fontSize: 12, color: theme.textMuted }}>/{u.max}</span></p>
              <div style={{ height: 3, borderRadius: 2, background: theme.border, marginTop: 6, overflow: 'hidden' }}>
                <div style={{ width: `${(u.used / u.max) * 100}%`, height: '100%', background: u.color, borderRadius: 2 }} />
              </div>
              <p style={{ fontSize: 10, color: theme.textMuted, marginTop: 4 }}>{u.label}</p>
            </div>
          ))}
        </div>
      </Card>

      {/* Settings sections */}
      {sections.map((sec, si) => (
        <div key={si} style={{ marginBottom: SPACING.xl }}>
          <SectionHeader>{sec.title}</SectionHeader>
          <Card padding={0}>
            {sec.items.map((item, ii) => (
              <div key={ii} onClick={item.action} style={{
                display: 'flex', alignItems: 'center', gap: 12, padding: '14px 16px',
                borderBottom: ii < sec.items.length - 1 ? `1px solid ${theme.border}` : 'none',
                cursor: item.action ? 'pointer' : 'default',
              }}>
                <Icon name={item.icon} size={18} color={theme.textMuted} />
                <span style={{ flex: 1, fontSize: 15, color: theme.text }}>{item.label}</span>
                {item.value && <span style={{ fontSize: 13, color: theme.textMuted }}>{item.value}</span>}
                <Icon name="chevronRight" size={16} color={theme.textMuted} />
              </div>
            ))}
          </Card>
        </div>
      ))}

      {/* Sign out */}
      <Button variant="destructive" fullWidth>Sign out</Button>
    </div>
  );
};

Object.assign(window, { ProfileScreen });
