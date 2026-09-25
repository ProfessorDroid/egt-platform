import { describe, expect, it } from 'vitest';
import axios from 'axios';
import { mapError } from './client';

describe('mapError', () => {
  it('maps a network failure to a friendly message', () => {
    const err = new axios.AxiosError('Network Error');
    err.response = undefined;
    const mapped = mapError(err);
    expect(mapped.code).toBe('network');
    expect(mapped.message).toMatch(/reach the server/);
  });

  it('maps 401 to session-expired wording', () => {
    const err = new axios.AxiosError('x', 'x', undefined, undefined, {
      status: 401, statusText: '', headers: {}, config: {}, data: {},
    } as never);
    const mapped = mapError(err);
    expect(mapped.code).toBe('unauthorized');
    expect(mapped.message).toMatch(/session has expired/i);
  });

  it('maps 403 to permission wording', () => {
    const err = new axios.AxiosError('x', 'x', undefined, undefined, {
      status: 403, statusText: '', headers: {}, config: {}, data: {},
    } as never);
    const mapped = mapError(err);
    expect(mapped.code).toBe('forbidden');
    expect(mapped.message).toMatch(/permission/);
  });

  it('maps 422 with field errors, keeping the detail', () => {
    const err = new axios.AxiosError('x', 'x', undefined, undefined, {
      status: 422, statusText: '', headers: {}, config: {},
      data: { message: 'Validation failed', errors: { email: 'Invalid email' } },
    } as never);
    const mapped = mapError(err);
    expect(mapped.code).toBe('validation');
    expect(mapped.fields).toEqual({ email: 'Invalid email' });
  });

  it('maps 500 to a generic server message', () => {
    const err = new axios.AxiosError('x', 'x', undefined, undefined, {
      status: 500, statusText: '', headers: {}, config: {}, data: {},
    } as never);
    const mapped = mapError(err);
    expect(mapped.code).toBe('server');
    expect(mapped.message).toMatch(/our side/);
  });

  it('maps non-axios errors to a generic message', () => {
    const mapped = mapError(new Error('kaboom'));
    expect(mapped.code).toBe('unknown');
    expect(mapped.message).not.toContain('kaboom');
  });
});
