import { describe, expect, it } from 'vitest';
import { canAccess, sensitiveActionLabel, visibleNav } from './rbac';

describe('visibleNav', () => {
  it('admin sees every nav item', () => {
    const paths = visibleNav('admin').map((i) => i.path);
    expect(paths).toEqual(
      expect.arrayContaining(['/dashboard', '/rfqs', '/users', '/audit-logs']),
    );
    expect(paths).toHaveLength(10);
  });

  it('staff does not see users or audit logs', () => {
    const paths = visibleNav('staff').map((i) => i.path);
    expect(paths).toContain('/dashboard');
    expect(paths).toContain('/support');
    expect(paths).not.toContain('/users');
    expect(paths).not.toContain('/audit-logs');
  });
});

describe('canAccess', () => {
  it('admin can access everything', () => {
    expect(canAccess('admin', '/users')).toBe(true);
    expect(canAccess('admin', '/audit-logs')).toBe(true);
    expect(canAccess('admin', '/rfqs/123')).toBe(true);
  });

  it('staff can access shared modules including nested routes', () => {
    expect(canAccess('staff', '/rfqs')).toBe(true);
    expect(canAccess('staff', '/rfqs/abc-123')).toBe(true);
    expect(canAccess('staff', '/products')).toBe(true);
    expect(canAccess('staff', '/shipments')).toBe(true);
  });

  it('staff is blocked from admin-only routes', () => {
    expect(canAccess('staff', '/users')).toBe(false);
    expect(canAccess('staff', '/users/abc')).toBe(false);
    expect(canAccess('staff', '/audit-logs')).toBe(false);
  });

  it('unknown paths are denied', () => {
    expect(canAccess('admin', '/nope')).toBe(false);
    expect(canAccess('staff', '/')).toBe(false);
  });
});

describe('sensitiveActionLabel', () => {
  it('labels every sensitive action', () => {
    expect(sensitiveActionLabel('user:role-change')).toContain('role');
    expect(sensitiveActionLabel('supplier:approve')).toContain('Approve');
    expect(sensitiveActionLabel('rfq:quote-create')).toContain('quotation');
  });
});
