import { describe, expect, it } from 'vitest';
import { safeMarkdownUrl } from '../pages/SummaryPage';

describe('safeMarkdownUrl', () => {
  it('allows reading links and removes executable protocols', () => {
    expect(safeMarkdownUrl('https://example.edu/reference')).toBe('https://example.edu/reference');
    expect(safeMarkdownUrl('#main-idea')).toBe('#main-idea');
    expect(safeMarkdownUrl('javascript:alert(1)')).toBe('');
    expect(safeMarkdownUrl('data:text/html,unsafe')).toBe('');
  });
});
