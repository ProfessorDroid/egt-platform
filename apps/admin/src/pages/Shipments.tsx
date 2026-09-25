/**
 * Shipments: event timeline entry. The detail endpoint returns the event
 * timeline inline; new events move the shipment status forward.
 *
 * RECONCILED 2026-09-25: POST /shipments/{id}/events takes AddEventDto
 * { status, location?, note? } with status in
 * picked_up | in_transit | customs | out_for_delivery | delivered | exception.
 * There is no separate milestone endpoint and no GET events endpoint.
 */
import React, { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api, mapError } from '../api/client';
import type { Shipment, ShipmentEventStatus } from '../api/types';
import {
  EmptyState, Field, Loading, PagedBlock, StatusBadge,
  formatDate, useApi, usePagedParams, useToast,
} from '../components/ui';

const EVENT_STATUSES: ShipmentEventStatus[] = [
  'picked_up', 'in_transit', 'customs', 'out_for_delivery', 'delivered', 'exception',
];

export function ShipmentList() {
  const navigate = useNavigate();
  const { page, pageSize, setPage } = usePagedParams();
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');

  const { data, loading, error } = useApi(
    () => api.shipments.list({ page, pageSize, q: query || undefined }),
    [page, pageSize, query],
  );

  return (
    <>
      <div className="egt-toolbar">
        <input className="egt-input" placeholder="Search reference, order…" value={q}
          onChange={(e) => setQ(e.target.value)} style={{ minWidth: 240 }} />
        <button className="egt-btn egt-btn--navy egt-btn--sm" onClick={() => { setQuery(q); setPage(1); }}>Search</button>
      </div>
      {loading && <Loading />}
      {!loading && error && <EmptyState icon="⚠" title="Couldn’t load shipments" message={error} />}
      {!loading && !error && (
        <div className="egt-card">
          <PagedBlock<Shipment>
            paged={data} page={page} pageSize={pageSize} onPage={setPage}
            onRowClick={(s) => navigate(`/shipments/${s.id}`)}
            empty={{ icon: '🚢', title: 'No shipments yet', message: 'Shipments linked to orders will appear here.' }}
            columns={[
              { header: 'Reference', render: (s) => <strong>{s.reference}</strong> },
              { header: 'Route', render: (s) => <>{s.origin ?? '—'} → {s.destination ?? '—'}</> },
              { header: 'Status', render: (s) => s.status ? <StatusBadge status={s.status} /> : <span style={{ color: 'var(--egt-steel)' }}>—</span> },
              { header: 'ETA', render: (s) => formatDate(s.eta) },
              { header: 'Updated', render: (s) => formatDate(s.updatedAt) },
            ]}
          />
        </div>
      )}
    </>
  );
}

export function ShipmentDetail() {
  const { id } = useParams<{ id: string }>();
  const { push } = useToast();
  const { data: shipment, loading, error, reload } = useApi(() => api.shipments.get(id!), [id]);

  const [status, setStatus] = useState<ShipmentEventStatus>('in_transit');
  const [location, setLocation] = useState('');
  const [note, setNote] = useState('');
  const [busy, setBusy] = useState(false);

  if (loading) return <Loading />;
  if (error || !shipment) return <EmptyState icon="⚠" title="Couldn’t load this shipment" message={error ?? 'Not found.'} />;

  const events = shipment.events ?? [];

  const addEvent = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      await api.shipments.addEvent(shipment.id, {
        status,
        location: location.trim() || undefined,
        note: note.trim() || undefined,
      });
      push('Timeline event recorded.', 'success');
      setLocation(''); setNote('');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  return (
    <div className="egt-grid egt-grid--2" style={{ alignItems: 'start' }}>
      <div>
        <div className="egt-card" style={{ marginBottom: 16 }}>
          <div className="egt-card__title">
            {shipment.reference}{' '}
            {shipment.status ? <StatusBadge status={shipment.status} /> : null}
          </div>
          <dl className="egt-kv">
            <dt>Order</dt><dd>{shipment.orderId}</dd>
            <dt>Route</dt><dd>{shipment.origin ?? '—'} → {shipment.destination ?? '—'}</dd>
            <dt>ETA</dt><dd>{formatDate(shipment.eta)}</dd>
            <dt>Updated</dt><dd>{formatDate(shipment.updatedAt)}</dd>
          </dl>
        </div>
        <div className="egt-card">
          <div className="egt-card__title">Record timeline event</div>
          <p className="egt-hint">Appending an event moves the shipment status forward on the backend.</p>
          <form onSubmit={addEvent}>
            <Field label="Status">
              <select className="egt-select" value={status} onChange={(e) => setStatus(e.target.value as ShipmentEventStatus)} required>
                {EVENT_STATUSES.map((s) => <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>)}
              </select>
            </Field>
            <Field label="Location (optional)">
              <input className="egt-input" value={location} onChange={(e) => setLocation(e.target.value)}
                placeholder="e.g. Nhava Sheva port" />
            </Field>
            <Field label="Note (optional)">
              <textarea className="egt-textarea" value={note} onChange={(e) => setNote(e.target.value)} />
            </Field>
            <button className="egt-btn egt-btn--primary" disabled={busy}>{busy ? 'Saving…' : 'Add event'}</button>
          </form>
        </div>
      </div>
      <div className="egt-card">
        <div className="egt-card__title">Timeline</div>
        {events.length === 0 && <EmptyState icon="◌" title="No events yet" message="Record the first timeline event for this shipment." />}
        <ul className="egt-timeline">
          {events.map((ev) => (
            <li key={ev.id}>
              <strong>{ev.status.replace(/_/g, ' ')}</strong>{ev.location ? ` — ${ev.location}` : ''}
              {ev.note && <div style={{ fontSize: 13 }}>{ev.note}</div>}
              <div className="egt-timeline__meta">{formatDate(ev.occurredAt)}{ev.createdBy ? ` · ${ev.createdBy}` : ''}</div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
