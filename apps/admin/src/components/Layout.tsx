/**
 * App shell: sidebar (RBAC-filtered nav), topbar, and route guards.
 * The EGT brand logo is used in the login shell and sidebar.
 *
 * RECONCILED 2026-09-25: the API has no MFA or password re-auth endpoint,
 * so the MFA button, idle lock screen and re-auth modal were removed.
 */
import React from 'react';
import { NavLink, Navigate, Outlet, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { canAccess, visibleNav } from '../auth/rbac';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const location = useLocation();
  if (!user) return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  if (!canAccess(user.role, location.pathname)) {
    // Fall back to the first page this role may see; a role with no admin
    // pages at all (e.g. buyer/supplier) lands back on sign-in.
    const fallback = visibleNav(user.role)[0]?.path ?? '/login';
    if (fallback === location.pathname) return null;
    return <Navigate to={fallback} replace />;
  }
  return <>{children}</>;
}

function Sidebar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  if (!user) return null;
  const items = visibleNav(user.role);
  return (
    <aside className="egt-sidebar">
      <div className="egt-sidebar__brand">
        <img src="/brand/egt-logo.png" alt="Eagle Goods Trading Co." />
        <div className="egt-sidebar__tag">Admin Console</div>
      </div>
      <nav className="egt-nav">
        <div className="egt-nav__section">Workspace</div>
        {items.slice(0, 8).map((i) => (
          <NavLink key={i.path} to={i.path} className={({ isActive }) => (isActive ? 'active' : '')}>
            <span className="egt-nav__icon">{i.icon}</span> {i.label}
          </NavLink>
        ))}
        {items.length > 8 && (
          <>
            <div className="egt-nav__section">Administration</div>
            {items.slice(8).map((i) => (
              <NavLink key={i.path} to={i.path} className={({ isActive }) => (isActive ? 'active' : '')}>
                <span className="egt-nav__icon">{i.icon}</span> {i.label}
              </NavLink>
            ))}
          </>
        )}
      </nav>
      <div className="egt-sidebar__foot">
        <div className="egt-sidebar__user">
          <div><strong>{user.fullName || user.name || user.email}</strong><span>{user.role}</span></div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button className="egt-btn egt-btn--ghost egt-btn--sm" style={{ color: '#C6D3DE', borderColor: 'rgba(255,255,255,0.25)' }}
            onClick={() => { logout(); navigate('/login'); }}>Sign out</button>
        </div>
      </div>
    </aside>
  );
}

const TITLES: Record<string, string> = {
  '/dashboard': 'Dashboard',
  '/rfqs': 'RFQs',
  '/products': 'Products',
  '/suppliers': 'Supplier listings',
  '/orders': 'Orders',
  '/shipments': 'Shipments',
  '/documents': 'Documents',
  '/support': 'Support tickets',
  '/users': 'Users & roles',
  '/audit-logs': 'Audit logs',
};

export function Shell() {
  const location = useLocation();
  const segment = '/' + location.pathname.split('/').filter(Boolean)[0];
  const title = TITLES[segment] ?? 'EGT Admin';
  return (
    <div className="egt-shell">
      <Sidebar />
      <div className="egt-main">
        <header className="egt-topbar">
          <h1>{title}</h1>
          <div className="egt-topbar__actions">
            <span style={{ fontSize: 13, color: 'var(--egt-steel)' }}>Eagle Goods Trading Co.</span>
          </div>
        </header>
        <main className="egt-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
