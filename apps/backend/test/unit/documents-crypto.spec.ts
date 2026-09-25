import { signDownloadToken, verifyDownloadToken, sha256Hex } from '../../src/common/utils/crypto.util';

describe('document signed download URLs', () => {
  const secret = 'test-signing-secret-1234567890abcdef';

  it('round-trips a valid token', () => {
    const token = signDownloadToken('doc-123', Date.now() + 15 * 60000, secret);
    expect(verifyDownloadToken(token, secret)).toEqual({ documentId: 'doc-123' });
  });

  it('rejects an expired token', () => {
    const token = signDownloadToken('doc-123', Date.now() - 1000, secret);
    expect(verifyDownloadToken(token, secret)).toBeNull();
  });

  it('rejects a tampered token', () => {
    const token = signDownloadToken('doc-123', Date.now() + 15 * 60000, secret);
    const tampered = token.slice(0, -2) + 'xx';
    expect(verifyDownloadToken(token + 'x', secret)).toBeNull();
    expect(verifyDownloadToken(tampered, secret)).toBeNull();
  });

  it('rejects a token signed with a different secret', () => {
    const token = signDownloadToken('doc-123', Date.now() + 15 * 60000, secret);
    expect(verifyDownloadToken(token, 'wrong-secret')).toBeNull();
  });

  it('sha256Hex is deterministic', () => {
    expect(sha256Hex('abc')).toBe(sha256Hex('abc'));
    expect(sha256Hex('abc')).not.toBe(sha256Hex('abd'));
  });
});
