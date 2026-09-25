/**
 * Support tickets: list, triage (status/priority/assignee via
 * PATCH /support/tickets/{id}), reply thread (POST …/reply),
 * close/reopen (status transitions).
 *
 * RECONCILED 2026-09-25: real paths are /support/tickets/*; status values
 * are open | in_progress | waiting_on_customer | resolved | closed and
 * priorities are low | medium | high | urgent. The ticket detail carries
 * its conversation inline — there is no separate replies endpoint.
 */
import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api, mapError } from '../api/client';
import type { Ticket, TicketMessage, TicketPriority, TicketStatus } from '../api/types';
import {
  EmptyState, Field, Loading, PagedBlock, StatusBadge,
  formatDate, useApi, usePagedParams, useToast,
} from '../components/ui';

const STATUSES: (TicketStatus | '')[] = ['', 'open', 'in_progress', 'waiting_on_customer', 'resolved', 'closed'];
const PRIORITIES: TicketPriority[] = ['low', 'medium', 'high', 'urgent'];

export function TicketList() {
  const navigate = useNavigate();
  const { page, pageSize, setPage } = usePagedParams();
  const [status, setStatus] = useState('');
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');

  const { data, loading, error } = useApi(
    () => api.tickets.list({ page, pageSize, status: status || undefined, q: query || undefined }),
    [page, pageSize, status, query],
  );

  return (
    <>
      <div className="egt-toolbar">
        <select className="egt-select" value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
          {STATUSES.map((s) => <option key={s} value={s}>{s === '' ? 'All statuses' : s.replace(/_/g, ' ')}</option>)}
        </select>
        <input className="egt-input" placeholder="Search subject, requester…" value={q}
          onChange={(e) => setQ(e.target.value)} style={{ minWidth: 240 }} />
        <button className="egt-btn egt-btn--navy egt-btn--sm" onClick={() => { setQuery(q); setPage(1); }}>Search</button>
      </div>
      {loading && <Loading />}
      {!loading && error && <EmptyState icon="⚠" title="Couldn’t load tickets" message={error} />}
      {!loading && !error && (
        <div className="egt-card">
          <PagedBlock<Ticket>
            paged={data} page={page} pageSize={pageSize} onPage={setPage}
            onRowClick={(t) => navigate(`/support/${t.id}`)}
            empty={{ icon: '💬', title: 'No tickets', message: 'Support requests will appear here.' }}
            columns={[
              { header: 'Subject', render: (t) => <><strong>{t.subject}</strong><br /><span style={{ color: 'var(--egt-steel)', fontSize: 13 }}>{t.requester ?? t.requesterEmail ?? ''}</span></> },
              { header: 'Priority', render: (t) => <StatusBadge status={t.priority} /> },
              { header: 'Status', render: (t) => <StatusBadge status={t.status} /> },
              { header: 'Assigned', render: (t) => t.assignedTo?.name ?? '—' },
              { header: 'Updated', render: (t) => formatDate(t.updatedAt) },
            ]}
          />
        </div>
      )}
    </>
  );
}

function replyText(r: TicketMessage): string {
  return r.body ?? r.text ?? '';
}

export function TicketDetail() {
  const { id } = useParams<{ id: string }>();
  const { push } = useToast();
  const { data: ticket, loading, error, reload } = useApi(() => api.tickets.get(id!), [id]);

  const [status, setStatus] = useState<TicketStatus>('open');
  const [priority, setPriority] = useState<TicketPriority>('medium');
  const [assigneeId, setAssigneeId] = useState('');
  const [replyTextValue, setReplyTextValue] = useState('');
  const [busy, setBusy] = useState(false);

  if (loading) return <Loading />;
  if (error || !ticket) return <EmptyState icon="⚠" title="Couldn’t load this ticket" message={error ?? 'Not found.'} />;

  const replies: TicketMessage[] = ticket.messages ?? ticket.conversation?.messages ?? [];

  const triage = async () => {
    setBusy(true);
    try {
      await api.tickets.update(ticket.id, {
        status,
        priority,
        assigneeId: assigneeId.trim() || undefined,
      });
      push('Ticket updated.', 'success');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  const reply = async () => {
    setBusy(true);
    try {
      await api.tickets.reply(ticket.id, replyTextValue.trim());
      setReplyTextValue('');
      push('Reply sent.', 'success');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  const quickStatus = (s: TicketStatus, label: string) => {
    setBusy(true);
    api.tickets.update(ticket.id, { status: s })
      .then(() => { push(label, 'success'); reload(); })
      .catch((err: unknown) => push(mapError(err).message, 'error'))
      .finally(() => setBusy(false));
  };

  return (
    <div className="egt-grid egt-grid--2" style={{ alignItems: 'start' }}>
      <div className="egt-card">
        <div className="egt-card__title">{ticket.subject}</div>
        <div style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
          <StatusBadge status={ticket.status} /><StatusBadge status={ticket.priority} />
        </div>
        <dl className="egt-kv">
          <dt>Requester</dt><dd>{ticket.requester ?? '—'}{ticket.requesterEmail ? ` (${ticket.requesterEmail})` : ''}</dd>
          <dt>Assigned</dt><dd>{ticket.assignedTo?.name ?? 'Unassigned'}</dd>
          <dt>Opened</dt><dd>{formatDate(ticket.createdAt)}</dd>
        </dl>

        <div className="egt-card__title" style={{ marginTop: 20 }}>Triage</div>
        <div className="egt-form-row">
          <Field label="Status">
            <select className="egt-select" value={status} onChange={(e) => setStatus(e.target.value as TicketStatus)}>
              {STATUSES.filter((s) => s !== '').map((s) => <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>)}
            </select>
          </Field>
          <Field label="Priority">
            <select className="egt-select" value={priority} onChange={(e) => setPriority(e.target.value as TicketPriority)}>
              {PRIORITIES.map((p) => <option key={p}>{p}</option>)}
            </select>
          </Field>
        </div>
        <Field label="Assignee (user ID)">
          <input className="egt-input" value={assigneeId} onChange={(e) => setAssigneeId(e.target.value)} placeholder="Optional" />
        </Field>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <button className="egt-btn egt-btn--navy egt-btn--sm" disabled={busy} onClick={triage}>Apply</button>
          {ticket.status === 'closed'
            ? <button className="egt-btn egt-btn--ghost egt-btn--sm" disabled={busy} onClick={() => quickStatus('open', 'Ticket reopened.')}>Reopen</button>
            : <button className="egt-btn egt-btn--ghost egt-btn--sm" disabled={busy} onClick={() => quickStatus('closed', 'Ticket closed.')}>Close</button>}
        </div>
      </div>

      <div className="egt-card">
        <div className="egt-card__title">Replies</div>
        <div className="egt-thread" style={{ marginBottom: 12 }}>
          {replies.length === 0 && <p style={{ fontSize: 13, color: 'var(--egt-steel)' }}>No replies yet.</p>}
          {replies.map((r) => (
            <div key={r.id} className={`egt-thread__msg ${r.from === 'staff' ? 'egt-thread__msg--staff' : ''}`}>
              {replyText(r)}
              <div className="egt-thread__meta">{r.author ?? r.from ?? ''}{r.createdAt ? ` · ${formatDate(r.createdAt)}` : ''}</div>
            </div>
          ))}
        </div>
        {ticket.status !== 'closed' && (
          <div style={{ display: 'flex', gap: 8 }}>
            <input className="egt-input" placeholder="Write a reply…" value={replyTextValue}
              onChange={(e) => setReplyTextValue(e.target.value)} />
            <button className="egt-btn egt-btn--primary egt-btn--sm" disabled={busy || !replyTextValue.trim()} onClick={reply}>Send</button>
          </div>
        )}
      </div>
    </div>
  );
}
