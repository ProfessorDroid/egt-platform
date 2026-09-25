/** Audit log viewer: filterable table (actor, action, object, timestamp, IP). Admin only. */
import { useState } from 'react';
import { api } from '../api/client';
import type { AuditEntry } from '../api/types';
import { EmptyState, Loading, PagedBlock, formatDate, useApi, usePagedParams } from '../components/ui';

export default function AuditLog() {
  const { page, pageSize, setPage } = usePagedParams(25);
  const [actor, setActor] = useState('');
  const [action, setAction] = useState('');
  const [objectType, setObjectType] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [filters, setFilters] = useState({ actor: '', action: '', objectType: '', from: '', to: '' });

  const { data, loading, error } = useApi(
    () => api.audit.list({
      page, pageSize,
      actor: filters.actor || undefined,
      action: filters.action || undefined,
      objectType: filters.objectType || undefined,
      from: filters.from || undefined,
      to: filters.to || undefined,
    }),
    [page, pageSize, filters],
  );

  const apply = () => { setFilters({ actor, action, objectType, from, to }); setPage(1); };
  const clear = () => {
    setActor(''); setAction(''); setObjectType(''); setFrom(''); setTo('');
    setFilters({ actor: '', action: '', objectType: '', from: '', to: '' });
    setPage(1);
  };

  return (
    <>
      <div className="egt-card" style={{ marginBottom: 16 }}>
        <div className="egt-form-row" style={{ gridTemplateColumns: '1fr 1fr 1fr' }}>
          <input className="egt-input" placeholder="Actor (name or email)" value={actor} onChange={(e) => setActor(e.target.value)} />
          <input className="egt-input" placeholder="Action (e.g. rfq.status)" value={action} onChange={(e) => setAction(e.target.value)} />
          <input className="egt-input" placeholder="Object type (e.g. rfq)" value={objectType} onChange={(e) => setObjectType(e.target.value)} />
          <input className="egt-input" type="date" value={from} onChange={(e) => setFrom(e.target.value)} aria-label="From date" />
          <input className="egt-input" type="date" value={to} onChange={(e) => setTo(e.target.value)} aria-label="To date" />
          <div style={{ display: 'flex', gap: 8 }}>
            <button className="egt-btn egt-btn--navy egt-btn--sm" onClick={apply}>Apply</button>
            <button className="egt-btn egt-btn--ghost egt-btn--sm" onClick={clear}>Clear</button>
          </div>
        </div>
      </div>

      {loading && <Loading />}
      {!loading && error && <EmptyState icon="⚠" title="Couldn’t load audit logs" message={error} />}
      {!loading && !error && (
        <div className="egt-card">
          <PagedBlock<AuditEntry>
            paged={data} page={page} pageSize={pageSize} onPage={setPage}
            empty={{ icon: '📋', title: 'No audit entries', message: 'Sensitive actions and changes will be recorded here.' }}
            columns={[
              { header: 'Timestamp', render: (a) => formatDate(a.createdAt) },
              { header: 'Actor', render: (a) => <>{a.actor}{a.actorEmail ? <><br /><span style={{ color: 'var(--egt-steel)', fontSize: 13 }}>{a.actorEmail}</span></> : null}</> },
              { header: 'Action', render: (a) => <code style={{ fontSize: 13 }}>{a.action}</code> },
              { header: 'Object', render: (a) => <>{a.objectType}{a.objectId ? <><br /><span style={{ color: 'var(--egt-steel)', fontSize: 13 }}>{a.objectId}</span></> : null}</> },
              { header: 'IP', render: (a) => a.ip ?? '—' },
            ]}
          />
        </div>
      )}
    </>
  );
}
