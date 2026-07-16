import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import type { ThemeMode } from '../types';

const THEME_KEY = 'cramly:theme';

interface ThemeValue {
  mode: ThemeMode;
  resolved: 'light' | 'dark';
  setMode(mode: ThemeMode): void;
}

const ThemeContext = createContext<ThemeValue | null>(null);

function storedMode(): ThemeMode {
  if (import.meta.env.DEV) {
    const requested = new URLSearchParams(window.location.search).get('theme');
    if (requested === 'light' || requested === 'dark' || requested === 'system') return requested;
  }
  try {
    const value = localStorage.getItem(THEME_KEY);
    return value === 'light' || value === 'dark' || value === 'system' ? value : 'system';
  } catch {
    return 'system';
  }
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [mode, setModeState] = useState<ThemeMode>(storedMode);
  const [systemDark, setSystemDark] = useState(
    () => window.matchMedia('(prefers-color-scheme: dark)').matches,
  );
  const resolved = mode === 'system' ? (systemDark ? 'dark' : 'light') : mode;

  useEffect(() => {
    const media = window.matchMedia('(prefers-color-scheme: dark)');
    const change = (event: MediaQueryListEvent) => setSystemDark(event.matches);
    media.addEventListener('change', change);
    return () => media.removeEventListener('change', change);
  }, []);

  useEffect(() => {
    document.documentElement.dataset.theme = mode;
    document.documentElement.dataset.resolvedTheme = resolved;
    document.querySelector('meta[name="theme-color"]')?.setAttribute(
      'content',
      resolved === 'dark' ? '#101713' : '#f4f7f5',
    );
  }, [mode, resolved]);

  const value = useMemo<ThemeValue>(() => ({
    mode,
    resolved,
    setMode(nextMode) {
      setModeState(nextMode);
      try {
        localStorage.setItem(THEME_KEY, nextMode);
      } catch {
        // The theme still applies for this session when storage is unavailable.
      }
    },
  }), [mode, resolved]);

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const context = useContext(ThemeContext);
  if (!context) throw new Error('useTheme must be used inside ThemeProvider');
  return context;
}
