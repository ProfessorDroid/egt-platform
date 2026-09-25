/**
 * Dashboard — BI widgets render ONLY from live API data.
 * Every widget shows an empty state when the API returns nothing or fails.
 * No placeholder statistics are ever rendered.
 *
 * RECONCILED 2026-09-25: the endpoint is GET /admin/overview. The spec
 * publishes no response schema for it, so DashboardOverview (api/types.ts)
 * stays a best-effort optional-widget shape.
 */
import React from 'react';
import { api } from '../api/client';
import { EmptyState, Loading, useApi } from '../components/ui';

function Widget({ title, icon, children }: { title: string; icon: string; children: React.ReactNode }) {
  return (
    <div className="egt-card">
      <div className="egt-card__title">{icon} {title}</div>
      {children}
    </div>
  );
}

export default function Dashboard() {
  const { data, loading, error } = useApi(() => api.dashboard.overview(), []);

  if (loading) return <Loading />;

  const noData = error || !data;
  const empty = (what: string) => (
    <EmptyState icon="◌" title="No data yet" message={error ? `Couldn’t load ${what}: ${error}` : `No ${what} data has been recorded yet.`} />
  );

  return (
    <>
      <p style={{ color: 'var(--egt-steel)', fontSize: 14, marginTop: 0 }}>
        Live business intelligence from the EGT API — nothing here is estimated or sampled.
      </p>
      <div className="egt-grid egt-grid--3">
        <Widget title="RFQ volume" icon="✉">
          {noData || !data.rfqVolume ? empty('RFQ volume') : (
            <>
              <div className="egt-stat">{data.rfqVolume.total.toLocaleString()}</div>
              <div className="egt-stat__label">Total RFQs</div>
              <div style={{ marginTop: 12, display: 'flex', gap: 8, flexWrap: 'wrap', fontSize: 13 }}>
                {Object.entries(data.rfqVolume.byStatus).map(([s, n]) => (
                  <span key={s} className="egt-badge egt-badge--navy">{s.replace(/_/g, ' ')}: {n}</span>
                ))}
              </div>
            </>
          )}
        </Widget>

        <Widget title="Conversion funnel" icon="▽">
          {noData || !data.conversionFunnel?.length ? empty('conversion funnel') : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {data.conversionFunnel.map((s) => (
                <div key={s.stage} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 14 }}>
                  <span style={{ textTransform: 'capitalize' }}>{s.stage.replace(/_/g, ' ')}</span>
                  <strong>{s.count}</strong>
                </div>
              ))}
            </div>
          )}
        </Widget>

        <Widget title="Order pipeline" icon="📦">
          {noData || !data.orderPipeline?.length ? empty('order pipeline') : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {data.orderPipeline.map((s) => (
                <div key={s.status} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 14 }}>
                  <span style={{ textTransform: 'capitalize' }}>{s.status.replace(/_/g, ' ')}</span>
                  <strong>{s.count}{s.value != null ? ` · ${s.value.toLocaleString()}` : ''}</strong>
                </div>
              ))}
            </div>
          )}
        </Widget>

        <Widget title="Shipment pipeline" icon="🚢">
          {noData || !data.shipmentPipeline?.length ? empty('shipment pipeline') : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {data.shipmentPipeline.map((s) => (
                <div key={s.status} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 14 }}>
                  <span style={{ textTransform: 'capitalize' }}>{s.status.replace(/_/g, ' ')}</span>
                  <strong>{s.count}</strong>
                </div>
              ))}
            </div>
          )}
        </Widget>

        <Widget title="Geographic demand" icon="🌍">
          {noData || !data.geographicDemand?.length ? empty('geographic demand') : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {data.geographicDemand.map((g) => (
                <div key={g.country} style={{ display: 'flex', justifyContent: 'space-between', fontSize: 14 }}>
                  <span>{g.country}</span>
                  <span><strong>{g.rfqs}</strong> RFQs · <strong>{g.orders}</strong> orders</span>
                </div>
              ))}
            </div>
          )}
        </Widget>

        <Widget title="Trend" icon="📈">
          {noData || !data.rfqVolume?.trend.length ? empty('trend') : (
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 90 }}>
              {data.rfqVolume.trend.slice(-14).map((t) => {
                const max = Math.max(...data.rfqVolume!.trend.map((x) => x.count), 1);
                return (
                  <div key={t.date} title={`${t.date}: ${t.count}`}
                    style={{ flex: 1, background: 'var(--egt-red)', borderRadius: 3,
                      height: `${Math.max(4, (t.count / max) * 84)}px` }} />
                );
              })}
            </div>
          )}
        </Widget>
      </div>
    </>
  );
}
