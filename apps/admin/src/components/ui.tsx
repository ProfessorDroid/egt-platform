/**
 * Shared UI primitives: toasts, empty states, pagination, tables, modals,
 * form fields, badges, and a small data-fetch hook.
 */
import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { mapError } from '../api/client';
import type { Paged } from '../api/types';

/* ---------------- toasts ---------------- */

interface Toast {
  id: number;
  kind: 'info' | 'success' | 'error';
  message: string;
}

const ToastContext = createContext<{ push: (message: string, kind?: Toast['kind']) => void } | null>(null);

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast must be used inside ToastProvider');
  return ctx;
}

let toastSeq = 1;

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const push = useCallback((message: string, kind: Toast['kind'] = 'info') => {
    const id = toastSeq++;
    setToasts((t) => [...t, { id, kind, message }]);
    window.setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 6000);
  }, []);
  return (
    <ToastContext.Provider value={{ push }}>
      {children}
      <div className="egt-toasts" role="status" aria-live="polite">
        {toasts.map((t) => (
          <div key={t.id} className={`egt-toast egt-toast--${t.kind}`}>
            <span style={{ flex: 1 }}>{t.message}</span>
            <button aria-label="Dismiss" onClick={() => setToasts((x) => x.filter((y) => y.id !== t.id))}>×</button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

/* ---------------- data fetching ---------------- */

interface UseApiResult<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
}

/** Runs `loader`, maps failures to friendly messages. Reloads when deps change. */
export function useApi<T>(loader: () => Promise<T>, deps: unknown[]): UseApiResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [nonce, setNonce] = useState(0);
  const loaderRef = useRef(loader);
  loaderRef.current = loader;

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    loaderRef.current()
      .then((d) => { if (!cancelled) { setData(d); setLoading(false); } })
      .catch((err: unknown) => { if (!cancelled) { setError(mapError(err).message); setLoading(false); } });
    return () => { cancelled = true; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [nonce, ...deps]);

  const reload = useCallback(() => setNonce((n) => n + 1), []);
  return { data, loading, error, reload };
}

/* ---------------- primitives ---------------- */

export function EmptyState({ icon = '◌', title, message, action }: {
  icon?: string; title: string; message: string; action?: React.ReactNode;
}) {
  return (
    <div className="egt-empty">
      <div className="egt-empty__icon">{icon}</div>
      <h3>{title}</h3>
      <p>{message}</p>
      {action && <div style={{ marginTop: 16 }}>{action}</div>}
    </div>
  );
}

export function Loading() {
  return <div className="egt-loading"><span className="egt-spinner" /> Loading…</div>;
}

export function Badge({ tone = 'default', children }: {
  tone?: 'default' | 'red' | 'navy' | 'green' | 'amber'; children: React.ReactNode;
}) {
  const cls = tone === 'default' ? 'egt-badge' : `egt-badge egt-badge--${tone}`;
  return <span className={cls}>{children}</span>;
}

export function statusTone(status: string): 'default' | 'red' | 'navy' | 'green' | 'amber' {
  const s = status.toLowerCase();
  if (['won', 'delivered', 'approved', 'closed', 'qc_passed', 'shipped'].includes(s)) return 'green';
  if (['lost', 'cancelled', 'rejected', 'disabled'].includes(s)) return 'red';
  if (['new', 'open', 'pending', 'urgent', 'high'].includes(s)) return 'amber';
  return 'navy';
}

export function StatusBadge({ status }: { status: string }) {
  return <Badge tone={statusTone(status)}>{status.replace(/_/g, ' ')}</Badge>;
}

export interface Column<T> {
  header: string;
  render: (row: T) => React.ReactNode;
}

export function DataTable<T extends { id: string }>({ columns, rows, onRowClick }: {
  columns: Column<T>[]; rows: T[]; onRowClick?: (row: T) => void;
}) {
  return (
    <div className="egt-table-wrap">
      <table className="egt-table">
        <thead>
          <tr>{columns.map((c) => <th key={c.header}>{c.header}</th>)}</tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.id} onClick={onRowClick ? () => onRowClick(row) : undefined}
                style={onRowClick ? { cursor: 'pointer' } : undefined}>
              {columns.map((c) => <td key={c.header}>{c.render(row)}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function Pagination({ page, pageSize, total, onPage }: {
  page: number; pageSize: number; total: number; onPage: (page: number) => void;
}) {
  const pages = Math.max(1, Math.ceil(total / pageSize));
  const from = total === 0 ? 0 : (page - 1) * pageSize + 1;
  const to = Math.min(total, page * pageSize);
  return (
    <div className="egt-pagination">
      <button className="egt-btn egt-btn--ghost egt-btn--sm" disabled={page <= 1} onClick={() => onPage(page - 1)}>← Prev</button>
      <span>Showing {from}–{to} of {total}</span>
      <button className="egt-btn egt-btn--ghost egt-btn--sm" disabled={page >= pages} onClick={() => onPage(page + 1)}>Next →</button>
    </div>
  );
}

export function usePagedParams(initialPageSize = 20) {
  const [page, setPage] = useState(1);
  const [pageSize] = useState(initialPageSize);
  return { page, pageSize, setPage };
}

export function PagedBlock<T extends { id: string }>({ paged, page, pageSize, onPage, columns, onRowClick, empty }: {
  paged: Paged<T> | null; page: number; pageSize: number; onPage: (p: number) => void;
  columns: Column<T>[]; onRowClick?: (row: T) => void;
  empty: { title: string; message: string; icon?: string };
}) {
  if (!paged || paged.items.length === 0) {
    return <EmptyState icon={empty.icon} title={empty.title} message={empty.message} />;
  }
  return (
    <>
      <DataTable columns={columns} rows={paged.items} onRowClick={onRowClick} />
      <Pagination page={page} pageSize={pageSize} total={paged.total} onPage={onPage} />
    </>
  );
}

export function Modal({ title, onClose, children }: {
  title: string; onClose: () => void; children: React.ReactNode;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);
  return (
    <div className="egt-modal-backdrop" onClick={onClose}>
      <div className="egt-modal" role="dialog" aria-modal="true" onClick={(e) => e.stopPropagation()}>
        <h2>{title}</h2>
        {children}
      </div>
    </div>
  );
}

export function Field({ label, hint, error, children }: {
  label: string; hint?: string; error?: string; children: React.ReactNode;
}) {
  return (
    <div className="egt-field">
      <label>{label}</label>
      {children}
      {hint && <div className="egt-hint">{hint}</div>}
      {error && <div className="egt-error">{error}</div>}
    </div>
  );
}

export function ConfirmModal({ title, body, confirmLabel = 'Confirm', danger, onConfirm, onCancel }: {
  title: string; body: React.ReactNode; confirmLabel?: string; danger?: boolean;
  onConfirm: () => void; onCancel: () => void;
}) {
  return (
    <Modal title={title} onClose={onCancel}>
      <div style={{ fontSize: 14 }}>{body}</div>
      <div className="egt-modal__actions">
        <button className="egt-btn egt-btn--ghost" onClick={onCancel}>Cancel</button>
        <button className={`egt-btn ${danger ? 'egt-btn--danger' : 'egt-btn--primary'}`} onClick={onConfirm}>
          {confirmLabel}
        </button>
      </div>
    </Modal>
  );
}

export function formatDate(iso: string | undefined): string {
  if (!iso) return '—';
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? '—' : d.toLocaleString();
}
