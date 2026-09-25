/**
 * Supplier listing review queue: pending listings, approve / request
 * changes / reject (PATCH /suppliers/listings/{id}/review).
 *
 * RECONCILED 2026-09-25: the real API exposes no supplier accounts CRUD,
 * no supplier approve/suspend, and no supplier documents/products
 * endpoints — staff review lives entirely on product listings, so this page
 * is the pending-listings queue.
 */
import React, { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { api, mapError } from '../api/client';
import type { ReviewListingInput, SupplierListing, SupplierListingStatus } from '../api/types';
import {
  EmptyState, Field, Loading, Modal, PagedBlock, StatusBadge,
  formatDate, useApi, usePagedParams, useToast,
} from '../components/ui';

export function SupplierList() {
  const navigate = useNavigate();
  const { page, pageSize, setPage } = usePagedParams();

  const { data, loading, error } = useApi(
    () => api.supplierListings.pending({ page, pageSize }),
    [page, pageSize],
  );

  return (
    <>
      <div className="egt-toolbar">
        <span style={{ fontSize: 13, color: 'var(--egt-steel)' }}>
          Product listings submitted by suppliers, awaiting staff review. Listings always start as pending — they are never auto-published.
        </span>
      </div>
      {loading && <Loading />}
      {!loading && error && <EmptyState icon="⚠" title="Couldn’t load the review queue" message={error} />}
      {!loading && !error && (
        <div className="egt-card">
          <PagedBlock<SupplierListing>
            paged={data} page={page} pageSize={pageSize} onPage={setPage}
            onRowClick={(s) => navigate(`/suppliers/${s.id}`)}
            empty={{ icon: '🏭', title: 'Review queue is empty', message: 'New supplier listings will appear here for review.' }}
            columns={[
              { header: 'Listing', render: (s) => <><strong>{s.customName ?? s.productName ?? 'Untitled listing'}</strong>{s.companyName ? <><br /><span style={{ color: 'var(--egt-steel)', fontSize: 13 }}>{s.companyName}</span></> : null}</> },
              { header: 'Supplier', render: (s) => s.supplierName ?? '—' },
              { header: 'Status', render: (s) => <StatusBadge status={s.status} /> },
              { header: 'Submitted', render: (s) => formatDate(s.createdAt) },
            ]}
          />
        </div>
      )}
    </>
  );
}

const REVIEW_ACTIONS: { status: ReviewListingInput['status']; label: string }[] = [
  { status: 'approved', label: 'Approve' },
  { status: 'changes_required', label: 'Request changes' },
  { status: 'rejected', label: 'Reject' },
];

export function SupplierDetail() {
  const { id } = useParams<{ id: string }>();
  const { push } = useToast();
  const navigate = useNavigate();

  /* No single-listing endpoint exists; resolve from the pending queue. */
  const { data, loading, error, reload } = useApi(
    () => api.supplierListings.pending({ page: 1, pageSize: 100 }),
    [],
  );
  const listing: SupplierListing | undefined = (data?.items ?? []).find((s) => s.id === id);

  const [reviewing, setReviewing] = useState<ReviewListingInput['status'] | null>(null);
  const [reviewNote, setReviewNote] = useState('');
  const [busy, setBusy] = useState(false);

  if (loading) return <Loading />;
  if (error) return <EmptyState icon="⚠" title="Couldn’t load the review queue" message={error} />;
  if (!listing) {
    return (
      <EmptyState icon="◌" title="Listing not found in the pending queue"
        message="It may already have been reviewed, or the queue page size limit was hit."
        action={<button className="egt-btn egt-btn--navy egt-btn--sm" onClick={() => navigate('/suppliers')}>← Back to queue</button>} />
    );
  }

  const submitReview = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reviewing) return;
    setBusy(true);
    try {
      await api.supplierListings.review(listing.id, { status: reviewing, reviewNote: reviewNote.trim() || undefined });
      push(`Listing ${reviewing.replace(/_/g, ' ')}.`, 'success');
      setReviewing(null); setReviewNote('');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
    finally { setBusy(false); }
  };

  const statusLabel = (s: SupplierListingStatus) => s.replace(/_/g, ' ');

  return (
    <>
      <div className="egt-card" style={{ maxWidth: 720 }}>
        <div className="egt-card__title">
          {listing.customName ?? listing.productName ?? 'Untitled listing'}{' '}
          <StatusBadge status={listing.status} />
        </div>
        <dl className="egt-kv">
          <dt>Supplier</dt><dd>{listing.supplierName ?? '—'}{listing.companyName ? ` — ${listing.companyName}` : ''}</dd>
          {listing.customDescription && <><dt>Description</dt><dd>{listing.customDescription}</dd></>}
          <dt>Submitted</dt><dd>{formatDate(listing.createdAt)}</dd>
          {listing.reviewNote && <><dt>Last review note</dt><dd>{listing.reviewNote}</dd></>}
        </dl>
        <div className="egt-card__title" style={{ marginTop: 20 }}>Review</div>
        <p className="egt-hint">Suppliers can never approve their own listings — this action is staff-only and logged.</p>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          {REVIEW_ACTIONS.map((a) => (
            <button key={a.status}
              className={`egt-btn egt-btn--sm ${a.status === 'approved' ? 'egt-btn--primary' : a.status === 'rejected' ? 'egt-btn--danger' : 'egt-btn--navy'}`}
              disabled={busy} onClick={() => setReviewing(a.status)}>
              {a.label}…
            </button>
          ))}
        </div>
        <p className="egt-hint" style={{ marginTop: 16 }}>
          Current status: <strong>{statusLabel(listing.status)}</strong>. Reviewing a listing removes it from this queue.
        </p>
      </div>

      {reviewing && (
        <Modal title={`${REVIEW_ACTIONS.find((a) => a.status === reviewing)?.label} listing`} onClose={() => setReviewing(null)}>
          <form onSubmit={submitReview}>
            <Field label="Review note (optional)" hint="Shown to the supplier with the decision.">
              <textarea className="egt-textarea" value={reviewNote} onChange={(e) => setReviewNote(e.target.value)} />
            </Field>
            <div className="egt-modal__actions">
              <button type="button" className="egt-btn egt-btn--ghost" onClick={() => setReviewing(null)}>Cancel</button>
              <button className={`egt-btn ${reviewing === 'rejected' ? 'egt-btn--danger' : 'egt-btn--primary'}`} disabled={busy}>
                {busy ? 'Submitting…' : 'Submit review'}
              </button>
            </div>
          </form>
        </Modal>
      )}
    </>
  );
}
