/**
 * Product management: list, create, update (UpdateProductDto fields only),
 * feature/active toggles, categories.
 *
 * RECONCILED 2026-09-25: PATCH /products/{id} accepts exactly
 * { name, shortDescription, orderVolume, isActive, isFeatured, sortOrder }.
 * The real API has no product DELETE and no product image endpoints, so the
 * Delete button and image upload were removed. Product detail is by slug.
 */
import React, { useState } from 'react';
import { api, mapError } from '../api/client';
import type { Product, ProductInput } from '../api/types';
import {
  EmptyState, Field, Loading, Modal, PagedBlock, StatusBadge,
  formatDate, useApi, usePagedParams, useToast,
} from '../components/ui';

const blankInput = (): ProductInput => ({
  name: '', shortDescription: '', orderVolume: '', isFeatured: false, isActive: true,
});

export default function Products() {
  const { push } = useToast();
  const { page, pageSize, setPage } = usePagedParams();
  const [q, setQ] = useState('');
  const [query, setQuery] = useState('');
  const [category, setCategory] = useState('');
  const [showInactive, setShowInactive] = useState(false);
  const [editing, setEditing] = useState<{ id: string | null; input: ProductInput } | null>(null);

  const { data, loading, error, reload } = useApi(
    () => api.products.list({ page, pageSize, q: query || undefined, category: category || undefined }),
    [page, pageSize, query, category],
  );
  const { data: categories } = useApi(() => api.products.categories(), []);

  const toggleFeatured = async (p: Product) => {
    try {
      await api.products.setFeatured(p.id, !p.isFeatured);
      push(p.isFeatured ? 'Product unfeatured.' : 'Product featured.', 'success');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
  };

  const toggleActive = async (p: Product) => {
    try {
      await api.products.setActive(p.id, p.isActive === false);
      push(p.isActive === false ? 'Product activated.' : 'Product deactivated.', 'success');
      reload();
    } catch (err) { push(mapError(err).message, 'error'); }
  };

  const visible = (data?.items ?? []).filter((p) => showInactive || p.isActive !== false);
  const paged = data ? { ...data, items: visible } : data;

  return (
    <>
      <div className="egt-toolbar">
        <select className="egt-select" value={category} onChange={(e) => { setCategory(e.target.value); setPage(1); }}>
          <option value="">All categories</option>
          {(categories ?? []).map((c) => <option key={c} value={c}>{c}</option>)}
        </select>
        <input className="egt-input" placeholder="Search products…" value={q}
          onChange={(e) => setQ(e.target.value)} style={{ minWidth: 200 }} />
        <button className="egt-btn egt-btn--navy egt-btn--sm" onClick={() => { setQuery(q); setPage(1); }}>Search</button>
        <label style={{ fontSize: 13, display: 'flex', gap: 6, alignItems: 'center' }}>
          <input type="checkbox" checked={showInactive} onChange={(e) => { setShowInactive(e.target.checked); setPage(1); }} />
          Show inactive
        </label>
        <button className="egt-btn egt-btn--primary egt-btn--sm" style={{ marginLeft: 'auto' }}
          onClick={() => setEditing({ id: null, input: blankInput() })}>
          + New product
        </button>
      </div>
      {loading && <Loading />}
      {!loading && error && <EmptyState icon="⚠" title="Couldn’t load products" message={error} />}
      {!loading && !error && (
        <div className="egt-card">
          <PagedBlock<Product>
            paged={paged} page={page} pageSize={pageSize} onPage={setPage}
            empty={{ icon: '▤', title: 'No products yet', message: 'Add products to the export catalogue here.' }}
            columns={[
              { header: 'Product', render: (p) => <><strong>{p.name}</strong>{p.shortDescription ? <><br /><span style={{ color: 'var(--egt-steel)', fontSize: 13 }}>{p.shortDescription}</span></> : null}</> },
              { header: 'Order volume', render: (p) => p.orderVolume ?? '—' },
              { header: 'Flags', render: (p) => (
                <span style={{ display: 'flex', gap: 6 }}>
                  {p.isFeatured ? <StatusBadge status="featured" /> : null}
                  {p.isActive === false ? <StatusBadge status="inactive" /> : null}
                </span>
              )},
              { header: 'Updated', render: (p) => formatDate(p.updatedAt) },
              { header: 'Actions', render: (p) => (
                <span style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
                  <button className="egt-btn egt-btn--ghost egt-btn--sm"
                    onClick={() => setEditing({ id: p.id, input: { name: p.name, shortDescription: p.shortDescription ?? '', orderVolume: p.orderVolume ?? '', isFeatured: !!p.isFeatured, isActive: p.isActive !== false } })}>
                    Edit
                  </button>
                  <button className="egt-btn egt-btn--ghost egt-btn--sm" onClick={() => toggleFeatured(p)}>
                    {p.isFeatured ? 'Unfeature' : 'Feature'}
                  </button>
                  <button className="egt-btn egt-btn--ghost egt-btn--sm" onClick={() => toggleActive(p)}>
                    {p.isActive === false ? 'Activate' : 'Deactivate'}
                  </button>
                </span>
              )},
            ]}
          />
        </div>
      )}
      {editing && (
        <ProductEditor
          id={editing.id} input={editing.input}
          onClose={() => setEditing(null)}
          onSaved={() => { setEditing(null); reload(); }}
        />
      )}
    </>
  );
}

/* ---------------- editor (UpdateProductDto fields only) ---------------- */

function ProductEditor({ id, input, onClose, onSaved }: {
  id: string | null; input: ProductInput; onClose: () => void; onSaved: () => void;
}) {
  const { push } = useToast();
  const [form, setForm] = useState<ProductInput>(input);
  const [busy, setBusy] = useState(false);

  const set = <K extends keyof ProductInput>(k: K, v: ProductInput[K]) =>
    setForm((f) => ({ ...f, [k]: v }));

  const save = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      if (id) await api.products.update(id, form);
      else await api.products.create(form);
      push(id ? 'Product updated.' : 'Product created.', 'success');
      onSaved();
    } catch (err) {
      push(mapError(err).message, 'error');
    } finally { setBusy(false); }
  };

  return (
    <Modal title={id ? 'Edit product' : 'New product'} onClose={onClose}>
      <form onSubmit={save}>
        <Field label="Product name">
          <input className="egt-input" value={form.name} onChange={(e) => set('name', e.target.value)} required />
        </Field>
        <Field label="Short description">
          <textarea className="egt-textarea" value={form.shortDescription ?? ''}
            onChange={(e) => set('shortDescription', e.target.value)} />
        </Field>
        <Field label="Order volume">
          <input className="egt-input" value={form.orderVolume ?? ''} onChange={(e) => set('orderVolume', e.target.value)}
            placeholder="e.g. 500 L / 50 Cartons" />
        </Field>
        <div className="egt-form-row">
          <label style={{ fontSize: 14, display: 'flex', gap: 8, alignItems: 'center' }}>
            <input type="checkbox" checked={!!form.isFeatured} onChange={(e) => set('isFeatured', e.target.checked)} /> Featured
          </label>
          <label style={{ fontSize: 14, display: 'flex', gap: 8, alignItems: 'center' }}>
            <input type="checkbox" checked={form.isActive !== false} onChange={(e) => set('isActive', e.target.checked)} /> Active
          </label>
        </div>
        <p className="egt-hint" style={{ marginTop: 12 }}>
          Note: the API supports no product deletion or image management — the catalogue is curated.
        </p>
        <div className="egt-modal__actions">
          <button type="button" className="egt-btn egt-btn--ghost" onClick={onClose}>Cancel</button>
          <button className="egt-btn egt-btn--primary" disabled={busy}>{busy ? 'Saving…' : 'Save product'}</button>
        </div>
      </form>
    </Modal>
  );
}
