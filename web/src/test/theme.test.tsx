import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it } from 'vitest';
import { ThemeProvider, useTheme } from '../contexts/ThemeContext';

function ThemeHarness() {
  const { mode, resolved, setMode } = useTheme();
  return (
    <div>
      <output>{mode}:{resolved}</output>
      <button onClick={() => setMode('dark')}>Dark</button>
      <button onClick={() => setMode('system')}>System</button>
    </div>
  );
}

describe('ThemeProvider', () => {
  beforeEach(() => localStorage.clear());

  it('defaults to system and persists an explicit choice', async () => {
    const user = userEvent.setup();
    render(<ThemeProvider><ThemeHarness /></ThemeProvider>);
    expect(screen.getByText('system:light')).toBeInTheDocument();
    await user.click(screen.getByRole('button', { name: 'Dark' }));
    expect(screen.getByText('dark:dark')).toBeInTheDocument();
    expect(localStorage.getItem('cramly:theme')).toBe('dark');
    expect(document.documentElement.dataset.resolvedTheme).toBe('dark');
  });
});
