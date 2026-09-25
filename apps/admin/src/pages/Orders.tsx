/**
 * Orders: status management (PATCH /orders/{id}/status, exact
 * UpdateOrderStatusDto enum) and document attachment
 * (POST /documents/upload with ownerType=order).
 *
 * RECONCILED 2026-09-25: the status endpoint takes no note field, and the
 * API exposes no per-order document listing — documents are attached via
 * the documents resource and downloaded through signed URLs.
 */
import { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api, mapError } from '../api/client';
import { ORDER_TRANSITIONS, type DocumentKind, type Order, type OrderStatus } from '../api/types';
import {
  ConfirmModal, EmptyState, Field, Loading, PagedBlock, StatusBadge,
  formatDate, useApi, usePagedParams, useToast,
} from '../components/ui';

const STATUSES: (OrderStatus | '')[] = ['', 'confirmed', 'in_production', 'ready_to_ship', 'shipped', 'delivered', 'cancelled'];

const DOC_KINDS: DocumentKind[] = ['order_document', 'compliance', 'other'];

export function OrderList() {
  const navigate = useNavigate();
  const { page, pageSize, setPage } = usePagedParams();
  const [status, setStatus] = useState('');
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');

  const { data, loading, error } = useApi(
    () => api.orders.list({ page, pageSize, status: status || undefined, q: query || undefined }),
    [page, pageSize, status, query],
  );

  return (
    <>
      <div className="egt-toolbar">
        <select className="egt-select" value={status} onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
          {STATUSES.map((s) => <option key={s} value={s}>{s === '' ? 'All statuses' : s.replace(/_/g, ' ')}</option>)}
        </select>
        <input className="egt-input" placeholder="Search buyer, reference…" value={q}
          onChange={(e) => setQ(e.target.value)} style={{ minWidth: 220 }} />
        <button className="egt-btn egt-btn--navy egt-btn--sm" onClick={() => { setQuery(q); setPage(1); }}>Search</button>
      </div>
      {loading && <Loading />}
      {!loading && error && <EmptyState icon="⚠" title="Couldn’t load orders" message={error} />}
      {!loading && !error && (
        <div className="egt-card">
          <PagedBlock<Order>
            paged={data} page={page} pageSize={pageSize} onPage={setPage}
            onRowClick={(o) => navigate(`/orders/${o.id}`)}
            empty={{ icon: '📦', title: 'No orders yet', message: 'Confirmed orders will appear here.' }}
            columns={[
              { header: 'Reference', render: (o) => <strong>{o.reference}</strong> },
              { header: 'Buyer', render: (o) => <>{o.buyerName}{o.company ? <><br /><span style={{ color: 'var(--egt-steel)' }}>{o.company}</span></> : null}</> },
              { header: 'Value', render: (o) => (o.totalValue != null ? `${o.currency ?? ''} ${o.totalValue.toLocaleString()}` : '—') },
              { header: 'Status', render: (o) => <StatusBadge status={o.status} /> },
              { header: 'Created', render: (o) => formatDate(o.createdAt) },
            ]}
          />
        </div>
      )}
    </>
  );
}

export function OrderDetail() {
  const { id } = useParams<{ id: string }>();
  const { push } = useToast();
  const { data: order, loading, error, reload } = useApi(() => api.orders.get(id!), [id]);

  const [pendingStatus, setPendingStatus] = useState<OrderStatus | null>(null);
  const [file, setFile] = useState<File | null>(null);
  const [docKind, setDocKind] = useState<DocumentKind>('order_document');
  const [lastDocId, setLastDocId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  if (loading) return <Loading />;
  if (error || !order) return <EmptyState icon="⚠" title="Couldn’t load this order" message={error ?? 'Not found.'} />;

  const allowed = ORDER_TRANSITIONS[order.status] ?? [];

  const confirmStatus = async () => {
    if (!pendingStatus) return;
    setBusy(true);
    try {
      await api.orders.setStatus(order.id, pendingStatus);
      push(`Order moved to ${pendingStatus.replace(/_/g, ' ')}.`, 'success');
      setPendingStatus(null);
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  const upload = async () => {
    if (!file) return;
    setBusy(true);
    try {
      const doc = await api.documents.upload({ file, kind: docKind, ownerType: 'order', ownerId: order.id });
      push('Document attached to this order.', 'success');
      setFile(null);
      setLastDocId(doc.id);
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  const downloadLast = async () => {
    if (!lastDocId) return;
    try {
      const { url } = await api.documents.downloadUrl(lastDocId);
      window.open(url, '_blank', 'noopener');
    } catch (err) { push(mapError(err).message, 'error'); }
  };

  return (
    <>
      <div className="egt-grid egt-grid--2" style={{ alignItems: 'start' }}>
        <div className="egt-card">
          <div className="egt-card__title">{order.reference} <StatusBadge status={order.status} /></div>
          <dl className="egt-kv">
            <dt>Buyer</dt><dd>{order.buyerName}{order.company ? ` — ${order.company}` : ''}</dd>
            <dt>Value</dt><dd>{order.totalValue != null ? `${order.currency ?? ''} ${order.totalValue.toLocaleString()}` : '—'}</dd>
            {order.rfqId && <><dt>RFQ</dt><dd>{order.rfqId}</dd></>}
            {order.shipmentId && <><dt>Shipment</dt><dd>{order.shipmentId}</dd></>}
            <dt>Created</dt><dd>{formatDate(order.createdAt)}</dd>
          </dl>
          <div className="egt-card__title" style={{ marginTop: 20 }}>Update status</div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {allowed.length === 0 && <p className="egt-hint">This order is in a terminal state — no further transitions.</p>}
            {allowed.map((s) => (
              <button key={s} className="egt-btn egt-btn--ghost egt-btn--sm" disabled={busy}
                onClick={() => setPendingStatus(s)}>→ {s.replace(/_/g, ' ')}</button>
            ))}
          </div>
        </div>

        <div className="egt-card">
          <div className="egt-card__title">Attach document</div>
          <p className="egt-hint">Documents are stored privately; downloads go through a 15-minute signed URL. The API exposes no per-order document list.</p>
          <Field label="Document">
            <div style={{ display: 'flex', gap: 8, alignItems: 'center', flexWrap: 'wrap' }}>
              <select className="egt-select" value={docKind} onChange={(e) => setDocKind(e.target.value as DocumentKind)}>
                {DOC_KINDS.map((c) => <option key={c} value={c}>{c.replace(/_/g, ' ')}</option>)}
              </select>
              <input type="file" onChange={(e) => setFile(e.target.files?.[0] ?? null)} />
              <button className="egt-btn egt-btn--navy egt-btn--sm" disabled={!file || busy} onClick={upload}>
                {busy ? 'Uploading…' : 'Upload'}
              </button>
            </div>
          </Field>
          {lastDocId && (
            <button className="egt-btn egt-btn--ghost egt-btn--sm" onClick={downloadLast}>
              Get download link for the last upload
            </button>
          )}
        </div>
      </div>

      {pendingStatus && (
        <ConfirmModal title={`Move order to “${pendingStatus.replace(/_/g, ' ')}”?`}
          body={<p>The backend enforces a strict forward status flow and will reject illegal transitions. This action is logged.</p>}
          confirmLabel="Confirm" onConfirm={confirmStatus} onCancel={() => setPendingStatus(null)} />
      )}
    </>
  );
}
