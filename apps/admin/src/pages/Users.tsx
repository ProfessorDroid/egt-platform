/**
 * Users (admin only): list, role assignment, activate/deactivate.
 * Session list + revoke is available for your own account only
 * (GET /auth/sessions) — the API exposes no per-user session endpoints.
 *
 * RECONCILED 2026-09-25: GET /admin/users, PATCH /admin/users/{id}/role
 * { role }, PATCH /admin/users/{id}/active (no body — toggles the flag).
 * The API has no MFA, so the MFA column was removed.
 */
import { useState } from 'react';
import { api, mapError } from '../api/client';
import type { Role, User } from '../api/types';
import { useAuth } from '../auth/AuthContext';
import {
  ConfirmModal, EmptyState, Loading, Modal, PagedBlock, StatusBadge,
  formatDate, useApi, usePagedParams, useToast,
} from '../components/ui';

const ROLES: Role[] = ['admin', 'staff', 'supplier', 'buyer'];

export function displayName(u: User): string {
  return u.fullName || u.name || u.email;
}

export default function Users() {
  const { push } = useToast();
  const { user: me } = useAuth();
  const { page, pageSize, setPage } = usePagedParams();
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');
  const [confirmDeactivate, setConfirmDeactivate] = useState<User | null>(null);
  const [busy, setBusy] = useState(false);

  const { data, loading, error, reload } = useApi(
    () => api.users.list({ page, pageSize, q: query || undefined }),
    [page, pageSize, query],
  );

  const changeRole = async (u: User, role: Role) => {
    if (role === u.role) return;
    setBusy(true);
    try {
      await api.users.setRole(u.id, role);
      push(`${u.email} is now ${role}.`, 'success');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  const toggleActive = async (u: User) => {
    setBusy(true);
    try {
      await api.users.toggleActive(u.id);
      push(u.isActive ? `${u.email} deactivated.` : `${u.email} activated.`, 'success');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); setConfirmDeactivate(null); }
  };

  return (
    <>
      <div className="egt-toolbar">
        <input className="egt-input" placeholder="Search name, email…" value={q}
          onChange={(e) => setQ(e.target.value)} style={{ minWidth: 220 }} />
        <button className="egt-btn egt-btn--navy egt-btn--sm" onClick={() => { setQuery(q); setPage(1); }}>Search</button>
      </div>
      {loading && <Loading />}
      {!loading && error && <EmptyState icon="⚠" title="Couldn’t load users" message={error} />}
      {!loading && !error && (
        <div className="egt-card">
          <PagedBlock<User>
            paged={data} page={page} pageSize={pageSize} onPage={setPage}
            empty={{ icon: '👥', title: 'No users yet', message: 'Staff accounts will be listed here.' }}
            columns={[
              { header: 'Name', render: (u) => <><strong>{displayName(u)}</strong><br /><span style={{ color: 'var(--egt-steel)', fontSize: 13 }}>{u.email}</span></> },
              { header: 'Role', render: (u) => (
                <select className="egt-select" value={u.role} disabled={busy}
                  onChange={(e) => changeRole(u, e.target.value as Role)} style={{ width: 'auto' }}>
                  {ROLES.map((r) => <option key={r} value={r}>{r}</option>)}
                </select>
              )},
              { header: 'Status', render: (u) => u.isActive ? <StatusBadge status="active" /> : <StatusBadge status="inactive" /> },
              { header: 'Last login', render: (u) => formatDate(u.lastLoginAt) },
              { header: 'Actions', render: (u) => (
                <span style={{ display: 'flex', gap: 6 }}>
                  {me && u.id === me.id
                    ? <MySessionsButton />
                    : <span style={{ fontSize: 12, color: 'var(--egt-steel)' }} title="The API only exposes your own sessions.">—</span>}
                  {u.isActive
                    ? <button className="egt-btn egt-btn--danger egt-btn--sm" disabled={busy} onClick={() => setConfirmDeactivate(u)}>Deactivate</button>
                    : <button className="egt-btn egt-btn--ghost egt-btn--sm" disabled={busy} onClick={() => toggleActive(u)}>Activate</button>}
                </span>
              )},
            ]}
          />
        </div>
      )}

      {confirmDeactivate && (
        <ConfirmModal title={`Deactivate ${confirmDeactivate.email}?`}
          body={<p>They will be unable to sign in until re-activated. This action is logged.</p>}
          confirmLabel="Deactivate account" danger
          onConfirm={() => toggleActive(confirmDeactivate)} onCancel={() => setConfirmDeactivate(null)} />
      )}
    </>
  );
}

function MySessionsButton() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button className="egt-btn egt-btn--ghost egt-btn--sm" onClick={() => setOpen(true)}>My sessions</button>
      {open && <SessionsModal onClose={() => setOpen(false)} />}
    </>
  );
}

function SessionsModal({ onClose }: { onClose: () => void }) {
  const { push } = useToast();
  const { logout } = useAuth();
  const { data: sessions, loading, reload } = useApi(() => api.auth.sessions(), []);

  const revoke = async (sessionId: string) => {
    try {
      await api.auth.revokeSession(sessionId);
      push('Session revoked.', 'success');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
  };

  const revokeCurrentAndLogout = async (sessionId: string) => {
    try {
      await api.auth.revokeSession(sessionId);
    } catch (err) { push(mapError(err).message, 'error'); }
    logout();
  };

  return (
    <Modal title="My sessions" onClose={onClose}>
      {loading && <Loading />}
      {!loading && (sessions ?? []).length === 0 && <p style={{ fontSize: 14, color: 'var(--egt-steel)' }}>No active sessions.</p>}
      {(sessions ?? []).map((s) => (
        <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 0', borderBottom: '1px solid var(--egt-border)', fontSize: 14 }}>
          <span>
            <strong>{s.ip ?? 'Unknown IP'}</strong>{s.current ? ' (this session)' : ''}
            {s.userAgent && <><br /><span style={{ fontSize: 12, color: 'var(--egt-steel)' }}>{s.userAgent}</span></>}
            {s.lastSeenAt && <><br /><span style={{ fontSize: 12, color: 'var(--egt-steel)' }}>Last seen {formatDate(s.lastSeenAt)}</span></>}
          </span>
          {s.current
            ? <button className="egt-btn egt-btn--danger egt-btn--sm" onClick={() => revokeCurrentAndLogout(s.id)}>Sign out</button>
            : <button className="egt-btn egt-btn--danger egt-btn--sm" onClick={() => revoke(s.id)}>Revoke</button>}
        </div>
      ))}
      <div className="egt-modal__actions">
        <button className="egt-btn egt-btn--ghost" onClick={onClose}>Close</button>
      </div>
    </Modal>
  );
}
