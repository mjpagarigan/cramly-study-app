/* Main App Shell */

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "themeMode": "dark",
  "accentHue": 80,
  "cardRadius": 16,
  "showStreakOnHome": true,
  "heatmapStyle": "glow"
}/*EDITMODE-END*/;

const AppShell = () => {
  const { theme, mode, setMode } = useTheme();
  const { state, navigate } = useAppState();
  const tab = state.currentTab;
  const [fabOpen, setFabOpen] = React.useState(false);

  const tabs = [
    { key: 'home', icon: 'home', label: 'Home' },
    { key: 'library', icon: 'library', label: 'Library' },
    { key: 'study', icon: 'flash', label: 'Study' },
    { key: 'progress', icon: 'progress', label: 'Progress' },
    { key: 'profile', icon: 'profile', label: 'Profile' },
  ];

  const renderScreen = () => {
    switch (tab) {
      case 'home': return <HomeScreen onNavigate={navigate} />;
      case 'library': return <LibraryScreen onNavigate={navigate} />;
      case 'study': return <StudyScreen onNavigate={navigate} />;
      case 'quiz': return <QuizScreen onNavigate={navigate} />;
      case 'upload': return <UploadScreen onNavigate={navigate} />;
      case 'podcast': return <PodcastScreen onNavigate={navigate} />;
      case 'progress': return <ProgressScreen onNavigate={navigate} />;
      case 'profile': return <ProfileScreen onNavigate={navigate} />;
      default: return <HomeScreen onNavigate={navigate} />;
    }
  };

  const isSubScreen = ['quiz', 'upload', 'podcast'].includes(tab);

  return (
    <div style={{
      width: '100%', height: '100%', display: 'flex', flexDirection: 'column',
      background: theme.bg, fontFamily: FONT.body, color: theme.text,
      position: 'relative', overflow: 'hidden',
    }}>
      {/* Content */}
      <div style={{ flex: 1, overflow: 'auto', WebkitOverflowScrolling: 'touch' }}>
        {renderScreen()}
      </div>

      {/* FAB */}
      {!isSubScreen && (
        <div style={{ position: 'absolute', bottom: 80, right: 20, zIndex: 50 }}>
          {fabOpen && (
            <div style={{ marginBottom: 10, display: 'flex', flexDirection: 'column', gap: 8, alignItems: 'flex-end', animation: 'fadeIn 0.2s ease' }}>
              {[
                { label: 'Upload file', icon: 'upload', action: () => { navigate('upload'); setFabOpen(false); } },
                { label: 'New course', icon: 'plus', action: () => { setFabOpen(false); } },
              ].map((item, i) => (
                <div key={i} onClick={item.action} style={{
                  display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer',
                }}>
                  <span style={{
                    fontSize: 13, fontWeight: 500, color: theme.text,
                    background: theme.bgElevated, padding: '6px 12px', borderRadius: RADIUS.md,
                    border: `1px solid ${theme.border}`, boxShadow: theme.shadowSm,
                  }}>{item.label}</span>
                  <div style={{
                    width: 40, height: 40, borderRadius: '50%', background: theme.bgElevated,
                    border: `1px solid ${theme.border}`,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    boxShadow: theme.shadowSm,
                  }}>
                    <Icon name={item.icon} size={18} color={theme.accent} />
                  </div>
                </div>
              ))}
            </div>
          )}
          <div onClick={() => setFabOpen(!fabOpen)} style={{
            width: 52, height: 52, borderRadius: '50%',
            background: theme.accent, display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', boxShadow: `0 4px 20px ${theme.accent}50`,
            transform: fabOpen ? 'rotate(45deg)' : 'rotate(0)',
            transition: 'transform 0.2s ease',
          }}>
            <Icon name="plus" size={24} color="#0F1523" />
          </div>
        </div>
      )}

      {/* Tab bar */}
      {!isSubScreen && (
        <div style={{
          display: 'flex', justifyContent: 'space-around', padding: '10px 0 6px',
          background: mode === 'dark' ? 'rgba(15,21,35,0.95)' : 'rgba(244,243,240,0.95)',
          backdropFilter: 'blur(12px)',
          borderTop: `1px solid ${theme.border}`,
          flexShrink: 0,
        }}>
          {tabs.map(t => (
            <div key={t.key} onClick={() => navigate(t.key)} style={{
              display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
              cursor: 'pointer', padding: '4px 12px', minWidth: 52,
            }}>
              <Icon name={t.icon} size={22} color={tab === t.key ? theme.accent : theme.textMuted} />
              <span style={{
                fontSize: 10, fontWeight: tab === t.key ? 600 : 400,
                color: tab === t.key ? theme.accent : theme.textMuted,
              }}>{t.label}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

const App = () => {
  const tweaks = typeof useTweaks !== 'undefined' ? useTweaks(TWEAK_DEFAULTS) : [TWEAK_DEFAULTS, () => {}];
  const [tw] = tweaks;

  return (
    <ThemeProvider initialMode={tw.themeMode || 'dark'}>
      <AppStateProvider>
        <AppInner tweaks={tw} />
      </AppStateProvider>
    </ThemeProvider>
  );
};

const AppInner = ({ tweaks }) => {
  const { setMode } = useTheme();

  React.useEffect(() => {
    if (tweaks.themeMode) setMode(tweaks.themeMode);
  }, [tweaks.themeMode]);

  return (
    <div style={{
      width: '100vw', height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: '#0a0a0a',
    }}>
      <div style={{
        width: 390, height: 844, borderRadius: 44, overflow: 'hidden',
        boxShadow: '0 20px 80px rgba(0,0,0,0.5)',
        border: '4px solid #1a1a1a',
        position: 'relative',
      }}>
        <AppShell />
      </div>

      {typeof TweaksPanel !== 'undefined' && (
        <TweaksPanel title="StudyApp Tweaks">
          <TweakRadio label="Theme" prop="themeMode" options={[
            { value: 'dark', label: 'Dark' },
            { value: 'light', label: 'Light' },
          ]} />
          <TweakToggle label="Show streak on home" prop="showStreakOnHome" />
          <TweakRadio label="Heatmap style" prop="heatmapStyle" options={[
            { value: 'glow', label: 'Constellation (glow)' },
            { value: 'flat', label: 'Flat grid' },
          ]} />
          <TweakSlider label="Card radius" prop="cardRadius" min={4} max={24} step={2} />
        </TweaksPanel>
      )}
    </div>
  );
};

Object.assign(window, { App, AppShell, AppInner });

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
