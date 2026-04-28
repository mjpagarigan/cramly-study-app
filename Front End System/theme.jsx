/* Nightowl Theme System */

const THEMES = {
  dark: {
    bg: '#0F1523',
    bgCard: '#171E30',
    bgCardHover: '#1C2438',
    bgElevated: '#1E2538',
    bgInput: '#1A2235',
    border: 'rgba(255,255,255,0.06)',
    borderSubtle: 'rgba(255,255,255,0.03)',
    text: '#E0DFE4',
    textSecondary: '#8890A8',
    textMuted: '#6B7394',
    textInverse: '#0F1523',
    accent: '#E8A84C',
    accentHover: '#F0B860',
    accentSubtle: 'rgba(232,168,76,0.12)',
    secondary: '#4CC8E8',
    secondarySubtle: 'rgba(76,200,232,0.12)',
    success: '#5CB87A',
    successSubtle: 'rgba(92,184,122,0.12)',
    error: '#E85C5C',
    errorSubtle: 'rgba(232,92,92,0.12)',
    shadow: '0 4px 24px rgba(0,0,0,0.3)',
    shadowSm: '0 2px 8px rgba(0,0,0,0.2)',
  },
  light: {
    bg: '#F4F3F0',
    bgCard: '#FFFFFF',
    bgCardHover: '#F9F8F6',
    bgElevated: '#FFFFFF',
    bgInput: '#EEECEA',
    border: 'rgba(0,0,0,0.08)',
    borderSubtle: 'rgba(0,0,0,0.04)',
    text: '#1A1E2E',
    textSecondary: '#6B6860',
    textMuted: '#9A9890',
    textInverse: '#F4F3F0',
    accent: '#D49540',
    accentHover: '#C08530',
    accentSubtle: 'rgba(212,149,64,0.12)',
    secondary: '#3AA8C4',
    secondarySubtle: 'rgba(58,168,196,0.12)',
    success: '#4A9E65',
    successSubtle: 'rgba(74,158,101,0.12)',
    error: '#D04848',
    errorSubtle: 'rgba(208,72,72,0.12)',
    shadow: '0 4px 24px rgba(0,0,0,0.06)',
    shadowSm: '0 2px 8px rgba(0,0,0,0.04)',
  },
};

const SPACING = { xs: 4, sm: 8, md: 12, lg: 16, xl: 24, xxl: 32, xxxl: 48 };
const RADIUS = { sm: 8, md: 12, lg: 16, xl: 20, full: 999 };
const FONT = {
  display: "'DM Sans', sans-serif",
  body: "'DM Sans', sans-serif",
  mono: "'JetBrains Mono', monospace",
};

const ThemeContext = React.createContext({ theme: THEMES.dark, mode: 'dark', toggle: () => {} });

const ThemeProvider = ({ children, initialMode = 'dark' }) => {
  const [mode, setMode] = React.useState(initialMode);
  const toggle = () => setMode(m => m === 'dark' ? 'light' : 'dark');
  const value = { theme: THEMES[mode], mode, toggle, setMode };
  return React.createElement(ThemeContext.Provider, { value }, children);
};

const useTheme = () => React.useContext(ThemeContext);

Object.assign(window, { THEMES, SPACING, RADIUS, FONT, ThemeContext, ThemeProvider, useTheme });
