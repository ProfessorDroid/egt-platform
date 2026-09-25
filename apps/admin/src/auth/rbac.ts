/**
 * RBAC for the EGT admin dashboard.
 * - admin: everything
 * - staff: dashboard / rfqs / products / suppliers / orders / shipments /
 *   documents / support — no users, roles, or audit logs.
 * Enforced in two places: nav visibility AND route guards.
 */
import type { Role } from '../api/types';

export interface NavItem {
  path: string;
  label: string;
  icon: string;
  roles: Role[];
}

export const NAV_ITEMS: NavItem[] = [
  { path: '/dashboard', label: 'Dashboard', icon: '▦', roles: ['admin', 'staff'] },
  { path: '/rfqs', label: 'RFQs', icon: '✉', roles: ['admin', 'staff'] },
  { path: '/products', label: 'Products', icon: '▤', roles: ['admin', 'staff'] },
  { path: '/suppliers', label: 'Supplier listings', icon: '🏭', roles: ['admin', 'staff'] },
  { path: '/orders', label: 'Orders', icon: '📦', roles: ['admin', 'staff'] },
  { path: '/shipments', label: 'Shipments', icon: '🚢', roles: ['admin', 'staff'] },
  { path: '/documents', label: 'Documents', icon: '🗂', roles: ['admin', 'staff'] },
  { path: '/support', label: 'Support', icon: '💬', roles: ['admin', 'staff'] },
  { path: '/users', label: 'Users & Roles', icon: '👥', roles: ['admin'] },
  { path: '/audit-logs', label: 'Audit Logs', icon: '📋', roles: ['admin'] },
];

/** Nav items the given role is allowed to see. */
export function visibleNav(role: Role): NavItem[] {
  return NAV_ITEMS.filter((item) => item.roles.includes(role));
}

/**
 * Route guard: true when `role` may visit `path`.
 * Matches on the first path segment so nested routes (e.g. /rfqs/123)
 * inherit the parent permission.
 */
export function canAccess(role: Role, path: string): boolean {
  const segment = '/' + path.split('/').filter(Boolean)[0];
  const item = NAV_ITEMS.find((n) => n.path === segment || n.path === path);
  if (!item) return false;
  return item.roles.includes(role);
}

/** Sensitive actions require a fresh password confirmation first. */
export type SensitiveAction =
  | 'user:role-change'
  | 'user:disable'
  | 'supplier:approve'
  | 'supplier:reject'
  | 'rfq:quote-create';

export function sensitiveActionLabel(action: SensitiveAction): string {
  switch (action) {
    case 'user:role-change': return 'Change user role';
    case 'user:disable': return 'Disable user account';
    case 'supplier:approve': return 'Approve supplier';
    case 'supplier:reject': return 'Reject supplier';
    case 'rfq:quote-create': return 'Create quotation';
  }
}
