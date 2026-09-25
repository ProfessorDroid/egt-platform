/**
 * RFQ management: list/filter, detail, backend-constrained status
 * transitions (POST /rfqs/{id}/transition), buyer conversation thread
 * (via /conversations), and quotation creation (POST /quotes).
 *
 * RECONCILED 2026-09-25: the real API has no RFQ assign, notes, or
 * request-info endpoints — those controls were removed.
 */
import React, { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api, mapError } from '../api/client';
import {
  RFQ_TRANSITIONS,
  type Conversation,
  type ConversationMessage,
  type QuoteIncoterm,
  type QuoteInput,
  type Rfq,
  type RfqStatus,
} from '../api/types';
import {
  ConfirmModal, EmptyState, Field, Loading, Modal, PagedBlock, StatusBadge,
  formatDate, useApi, usePagedParams, useToast,
} from '../components/ui';

const STATUSES: (RfqStatus | '')[] = [
  '',
  'under_review', 'sourcing', 'supplier_matched', 'sample_discussion',
  'quotation_ready', 'buyer_action_required', 'approved', 'order_processing',
  'completed', 'closed',
];

/* ---------------- list ---------------- */

export function RfqList() {
  const navigate = useNavigate();
  const { page, pageSize, setPage } = usePagedParams();
  const [status, setStatus] = useState('');
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');

  const { data, loading, error } = useApi(
    () => api.rfqs.list({ page, pageSize, status: status || undefined, q: query || undefined }),
    [page, pageSize, status, query],
  );

  return (
    <>
      <div className="egt-toolbar">
        <select className="egt-select" value={status}
          onChange={(e) => { setStatus(e.target.value); setPage(1); }}>
          {STATUSES.map((s) => <option key={s} value={s}>{s === '' ? 'All statuses' : s.replace(/_/g, ' ')}</option>)}
        </select>
        <input className="egt-input" placeholder="Search buyer, company, reference…" value={q}
          onChange={(e) => setQ(e.target.value)} style={{ minWidth: 240 }} />
        <button className="egt-btn egt-btn--navy egt-btn--sm" onClick={() => { setQuery(q); setPage(1); }}>Search</button>
      </div>
      {loading && <Loading />}
      {!loading && error && <EmptyState icon="⚠" title="Couldn’t load RFQs" message={error} />}
      {!loading && !error && (
        <div className="egt-card">
          <PagedBlock<Rfq>
            paged={data} page={page} pageSize={pageSize} onPage={setPage}
            onRowClick={(r) => navigate(`/rfqs/${r.id}`)}
            empty={{ icon: '✉', title: 'No RFQs yet', message: 'New quote requests from the website will appear here.' }}
            columns={[
              { header: 'Reference', render: (r) => <strong>{r.reference}</strong> },
              { header: 'Buyer', render: (r) => <>{r.buyerName}{r.company ? <><br /><span style={{ color: 'var(--egt-steel)' }}>{r.company}</span></> : null}</> },
              { header: 'Products', render: (r) => r.productNames.join(', ') },
              { header: 'Destination', render: (r) => r.destinationCountry },
              { header: 'Status', render: (r) => <StatusBadge status={r.status} /> },
              { header: 'Received', render: (r) => formatDate(r.createdAt) },
            ]}
          />
        </div>
      )}
    </>
  );
}

/* ---------------- detail ---------------- */

function messageText(m: ConversationMessage): string {
  return m.body ?? m.text ?? '';
}

function messageMeta(m: ConversationMessage): string {
  const who = m.authorName ?? m.author ?? m.from ?? 'Unknown';
  return m.createdAt ? `${who} · ${formatDate(m.createdAt)}` : who;
}

export function RfqDetail() {
  const { id } = useParams<{ id: string }>();
  const { push } = useToast();
  const { data: rfq, loading, error, reload } = useApi(() => api.rfqs.get(id!), [id]);

  /* Buyer conversation: find the rfq-scoped conversation, or open one. */
  const { data: conversations, reload: reloadConvos } = useApi(() => api.conversations.list(), []);
  const convo: Conversation | undefined = (conversations ?? [])
    .find((c) => c.kind === 'rfq' && c.rfqId === id);
  const { data: messages, reload: reloadMessages } = useApi(
    () => (convo ? api.conversations.messages(convo.id) : Promise.resolve([] as ConversationMessage[])),
    [convo?.id],
  );

  const [msgText, setMsgText] = useState('');
  const [showQuote, setShowQuote] = useState(false);
  const [pendingStatus, setPendingStatus] = useState<RfqStatus | null>(null);
  const [busy, setBusy] = useState(false);

  if (loading) return <Loading />;
  if (error || !rfq) return <EmptyState icon="⚠" title="Couldn’t load this RFQ" message={error ?? 'Not found.'} />;

  const allowed = RFQ_TRANSITIONS[rfq.status] ?? [];

  const run = async (fn: () => Promise<unknown>, okMsg: string) => {
    setBusy(true);
    try { await fn(); push(okMsg, 'success'); reload(); }
    catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  const confirmTransition = () =>
    run(() => api.rfqs.transition(rfq.id, pendingStatus!), `RFQ moved to ${pendingStatus!.replace(/_/g, ' ')}.`)
      .finally(() => setPendingStatus(null));

  const startConversation = async () => {
    setBusy(true);
    try {
      await api.conversations.open({ kind: 'rfq', rfqId: rfq.id, subject: `RFQ ${rfq.reference}` });
      push('Conversation opened.', 'success');
      reloadConvos();
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  const sendMessage = () =>
    run(
      () => api.conversations.send(convo!.id, msgText.trim()).then(() => { setMsgText(''); reloadMessages(); }),
      'Message sent.',
    );

  return (
    <>
      <div className="egt-grid egt-grid--2" style={{ alignItems: 'start' }}>
        <div className="egt-card">
          <div className="egt-card__title">{rfq.reference} <StatusBadge status={rfq.status} /></div>
          <dl className="egt-kv">
            <dt>Buyer</dt><dd>{rfq.buyerName}{rfq.company ? ` — ${rfq.company}` : ''}</dd>
            <dt>Contact</dt><dd>{rfq.email} · {rfq.phone}</dd>
            <dt>Products</dt><dd>{rfq.productNames.join(', ')}</dd>
            <dt>Quantity</dt><dd>{rfq.quantity}</dd>
            <dt>Destination</dt><dd>{rfq.destinationCountry}</dd>
            {rfq.budget && <><dt>Budget</dt><dd>{rfq.currency ?? ''} {rfq.budget}</dd></>}
            {rfq.privateLabel != null && <><dt>Private label</dt><dd>{rfq.privateLabel ? 'Yes' : 'No'}</dd></>}
            {rfq.shippingPreference && <><dt>Shipping</dt><dd>{rfq.shippingPreference}</dd></>}
            {rfq.assignedTo?.name && <><dt>Assigned to</dt><dd>{rfq.assignedTo.name}</dd></>}
            <dt>Received</dt><dd>{formatDate(rfq.createdAt)}</dd>
          </dl>
          {rfq.message && (
            <><div className="egt-card__title" style={{ marginTop: 16 }}>Buyer requirement</div>
            <p style={{ fontSize: 14 }}>{rfq.message}</p></>
          )}

          <div className="egt-card__title" style={{ marginTop: 20 }}>Actions</div>
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {allowed.map((s) => (
              <button key={s} className="egt-btn egt-btn--ghost egt-btn--sm" disabled={busy}
                onClick={() => setPendingStatus(s)}>
                → {s.replace(/_/g, ' ')}
              </button>
            ))}
            <button className="egt-btn egt-btn--navy egt-btn--sm" disabled={busy}
              onClick={() => setShowQuote(true)}>
              Create quotation
            </button>
          </div>
        </div>

        <div className="egt-card">
          <div className="egt-card__title">Conversation with buyer</div>
          {!convo ? (
            <EmptyState icon="💬" title="No conversation yet"
              message="Open a conversation to message the buyer about this RFQ."
              action={<button className="egt-btn egt-btn--primary egt-btn--sm" disabled={busy} onClick={startConversation}>
                Open conversation
              </button>} />
          ) : (
            <>
              <div className="egt-thread" style={{ marginBottom: 12 }}>
                {(messages ?? []).length === 0 && <p style={{ fontSize: 13, color: 'var(--egt-steel)' }}>No messages yet.</p>}
                {(messages ?? []).map((m) => (
                  <div key={m.id} className={`egt-thread__msg ${m.from === 'staff' ? 'egt-thread__msg--staff' : ''}`}>
                    {messageText(m)}
                    <div className="egt-thread__meta">{messageMeta(m)}</div>
                  </div>
                ))}
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <input className="egt-input" placeholder="Write a reply to the buyer…" value={msgText}
                  onChange={(e) => setMsgText(e.target.value)} />
                <button className="egt-btn egt-btn--primary egt-btn--sm" disabled={busy || !msgText.trim()}
                  onClick={sendMessage}>
                  Send
                </button>
              </div>
            </>
          )}
        </div>
      </div>

      {pendingStatus && (
        <ConfirmModal title={`Move RFQ to “${pendingStatus.replace(/_/g, ' ')}”?`}
          body={<p>The backend state machine will validate this transition. This action is logged.</p>}
          confirmLabel="Confirm" onConfirm={confirmTransition} onCancel={() => setPendingStatus(null)} />
      )}
      {showQuote && <QuotationModal rfqId={rfq.id} onClose={() => setShowQuote(false)} onDone={reload} />}
    </>
  );
}

/* ---------------- quotation form (POST /quotes — CreateQuoteDto) ---------------- */

const INCOTERMS: QuoteIncoterm[] = ['FOB', 'CIF', 'DDP', 'EXW'];

function QuotationModal({ rfqId, onClose, onDone }: { rfqId: string; onClose: () => void; onDone: () => void }) {
  const { push } = useToast();
  const [items, setItems] = useState([{ description: '', quantity: '', unit: '', unitPrice: '' }]);
  const [currency, setCurrency] = useState('USD');
  const [shippingCost, setShippingCost] = useState('');
  const [incoterm, setIncoterm] = useState<QuoteIncoterm>('FOB');
  const [validUntil, setValidUntil] = useState('');
  const [notes, setNotes] = useState('');
  const [busy, setBusy] = useState(false);

  const setItem = (i: number, patch: Partial<(typeof items)[number]>) =>
    setItems((xs) => xs.map((x, j) => (j === i ? { ...x, ...patch } : x)));

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    const input: QuoteInput = {
      rfqId,
      currency,
      shippingCost: shippingCost ? Number(shippingCost) : undefined,
      incoterm,
      validUntil: new Date(validUntil).toISOString(),
      notes: notes || undefined,
      items: items.map((i) => ({
        description: i.description,
        quantity: Number(i.quantity) || 0,
        unit: i.unit || undefined,
        unitPrice: Number(i.unitPrice) || 0,
      })),
    };
    setBusy(true);
    try {
      await api.quotes.create(input);
      push('Quotation created.', 'success');
      onDone(); onClose();
    } catch (err) {
      push(mapError(err).message, 'error');
    } finally { setBusy(false); }
  };

  return (
    <Modal title="Create quotation" onClose={onClose}>
      <form onSubmit={submit}>
        {items.map((it, i) => (
          <div key={i} className="egt-form-row" style={{ marginBottom: 8 }}>
            <input className="egt-input" placeholder="Description" value={it.description} required
              onChange={(e) => setItem(i, { description: e.target.value })} />
            <input className="egt-input" placeholder="Quantity" inputMode="decimal" value={it.quantity} required
              onChange={(e) => setItem(i, { quantity: e.target.value })} />
            <input className="egt-input" placeholder="Unit (optional)" value={it.unit}
              onChange={(e) => setItem(i, { unit: e.target.value })} />
            <input className="egt-input" placeholder="Unit price" inputMode="decimal" value={it.unitPrice} required
              onChange={(e) => setItem(i, { unitPrice: e.target.value })} />
          </div>
        ))}
        <button type="button" className="egt-btn egt-btn--ghost egt-btn--sm" style={{ marginBottom: 12 }}
          onClick={() => setItems((xs) => [...xs, { description: '', quantity: '', unit: '', unitPrice: '' }])}>
          + Add line
        </button>
        <div className="egt-form-row">
          <Field label="Currency">
            <select className="egt-select" value={currency} onChange={(e) => setCurrency(e.target.value)}>
              {['USD', 'EUR', 'INR', 'CAD', 'AED'].map((c) => <option key={c}>{c}</option>)}
            </select>
          </Field>
          <Field label="Incoterm">
            <select className="egt-select" value={incoterm} onChange={(e) => setIncoterm(e.target.value as QuoteIncoterm)}>
              {INCOTERMS.map((t) => <option key={t}>{t}</option>)}
            </select>
          </Field>
        </div>
        <div className="egt-form-row">
          <Field label="Valid until">
            <input className="egt-input" type="date" value={validUntil}
              onChange={(e) => setValidUntil(e.target.value)} required />
          </Field>
          <Field label="Shipping cost (optional)">
            <input className="egt-input" inputMode="decimal" value={shippingCost}
              onChange={(e) => setShippingCost(e.target.value)} placeholder="0.00" />
          </Field>
        </div>
        <Field label="Notes for the buyer (optional)">
          <textarea className="egt-textarea" value={notes} onChange={(e) => setNotes(e.target.value)} />
        </Field>
        <div className="egt-modal__actions">
          <button type="button" className="egt-btn egt-btn--ghost" onClick={onClose}>Cancel</button>
          <button className="egt-btn egt-btn--primary" disabled={busy}>{busy ? 'Creating…' : 'Create quotation'}</button>
        </div>
      </form>
    </Modal>
  );
}
