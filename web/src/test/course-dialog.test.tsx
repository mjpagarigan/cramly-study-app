import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import { CourseFormDialog } from '../components/CourseDialogs';

describe('CourseFormDialog', () => {
  it('keeps the dialog open and associates a required-name error', async () => {
    const user = userEvent.setup();
    const submit = vi.fn();
    render(<CourseFormDialog open onClose={() => undefined} onSubmit={submit} />);
    await user.click(screen.getByRole('button', { name: 'Create course' }));
    expect(screen.getByText('Enter a course name.')).toBeInTheDocument();
    expect(screen.getByLabelText('Course name')).toHaveAttribute('aria-invalid', 'true');
    expect(submit).not.toHaveBeenCalled();
  });
});
