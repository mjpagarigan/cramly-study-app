import { afterEach, describe, expect, it, vi } from 'vitest';
import { ApiClient } from '../lib/api';

describe('ApiClient', () => {
  afterEach(() => vi.unstubAllGlobals());

  it('attaches a fresh token, omits credentials, and handles 204', async () => {
    const token = vi.fn().mockResolvedValue('fresh-token');
    const fetchMock = vi.fn().mockResolvedValue(new Response(null, { status: 204 }));
    vi.stubGlobal('fetch', fetchMock);
    const client = new ApiClient('http://localhost:8000', token);

    await expect(client.delete('/courses/course-1')).resolves.toBeUndefined();
    expect(token).toHaveBeenCalledOnce();
    expect(fetchMock).toHaveBeenCalledWith('http://localhost:8000/courses/course-1', expect.objectContaining({
      method: 'DELETE',
      credentials: 'omit',
      headers: expect.objectContaining({ Authorization: 'Bearer fresh-token' }),
    }));
  });

  it('normalizes FastAPI validation arrays', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(JSON.stringify({
      detail: [{ loc: ['body', 'name'], msg: 'Field required', type: 'missing' }],
    }), { status: 422, headers: { 'Content-Type': 'application/json' } })));
    const client = new ApiClient('https://api.example', async () => 'token');

    await expect(client.post('/courses', {})).rejects.toMatchObject({
      status: 422,
      message: 'Field required',
    });
  });

  it('preserves string-valued FastAPI errors', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue(new Response(JSON.stringify({
      detail: 'This course name is already in use.',
    }), { status: 400, headers: { 'Content-Type': 'application/json' } })));
    const client = new ApiClient('https://api.example', async () => 'token');

    await expect(client.post('/courses', {})).rejects.toMatchObject({
      status: 400,
      message: 'This course name is already in use.',
    });
  });

  it('reports an aborted request as cancelled', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new DOMException('Aborted', 'AbortError')));
    const client = new ApiClient('https://api.example', async () => 'token');

    await expect(client.get('/courses', new AbortController().signal)).rejects.toMatchObject({
      status: 0,
      message: 'Request cancelled.',
    });
  });

  it('reports network failures without leaking implementation errors', async () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new TypeError('socket closed')));
    const client = new ApiClient('https://api.example', async () => 'token');
    await expect(client.get('/courses')).rejects.toEqual(
      expect.objectContaining({ status: 0, message: 'Network request failed. Check your connection.' }),
    );
  });
});
