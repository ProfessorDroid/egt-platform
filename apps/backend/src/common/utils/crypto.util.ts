import { createHmac, randomBytes, createHash } from 'crypto';

/** SHA-256 hex of a secret value (refresh tokens, verification tokens). */
export function sha256Hex(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

/** Cryptographically random URL-safe token (email verification, resets). */
export function randomToken(bytes = 32): string {
  return randomBytes(bytes).toString('base64url');
}

/** Random server-side stored filename preserving the extension. */
export function randomStoredFilename(extension: string): string {
  const ext = extension.replace(/[^a-z0-9]/gi, '').toLowerCase().slice(0, 10);
  return `${randomBytes(16).toString('hex')}.${ext}`;
}

/**
 * HMAC-signed temporary download token: `docId:expiresAt:signature`.
 * Verified server-side in the documents module.
 */
export function signDownloadToken(documentId: string, expiresAt: number, secret: string): string {
  const payload = `${documentId}:${expiresAt}`;
  const sig = createHmac('sha256', secret).update(payload).digest('base64url');
  return Buffer.from(`${payload}:${sig}`).toString('base64url');
}

export function verifyDownloadToken(token: string, secret: string): { documentId: string } | null {
  try {
    const decoded = Buffer.from(token, 'base64url').toString('utf8');
    const [documentId, expiresAtStr, sig] = decoded.split(':');
    if (!documentId || !expiresAtStr || !sig) return null;
    const expected = createHmac('sha256', secret).update(`${documentId}:${expiresAtStr}`).digest('base64url');
    if (sig.length !== expected.length) return null;
    // constant-time comparison
    let diff = 0;
    for (let i = 0; i < sig.length; i++) diff |= sig.charCodeAt(i) ^ expected.charCodeAt(i);
    if (diff !== 0) return null;
    if (Date.now() > Number(expiresAtStr)) return null;
    return { documentId };
  } catch {
    return null;
  }
}

/** Minimal HTML/script-tag stripping for free-text fields. Never a substitute for validation. */
export function sanitizeText(input: string): string {
  return input.replace(/<[^>]*>/g, '').trim();
}

/** Pagination helpers — consistent {page, limit, total} envelope. */
export function parsePagination(query: { page?: string | number; limit?: string | number }) {
  const page = Math.max(1, parseInt(String(query.page ?? 1), 10) || 1);
  const limit = Math.min(100, Math.max(1, parseInt(String(query.limit ?? 20), 10) || 20));
  return { page, limit, skip: (page - 1) * limit, take: limit };
}

export function paginated<T>(items: T[], total: number, page: number, limit: number) {
  return { data: items, page, limit, total };
}
