/**
 * Documents: attach a file to an RFQ, order, shipment, or support ticket
 * (POST /documents/upload, multipart) and mint 15-minute signed download
 * URLs (GET /documents/{id}/download-url).
 *
 * RECONCILED 2026-09-25: the real API has no documents vault listing and
 * no document categories — uploads are always scoped to an owner record.
 */
import { useState } from 'react';
import { api, mapError } from '../api/client';
import type { DocumentKind, DocumentOwnerType } from '../api/types';
import { Field, useToast } from '../components/ui';

const OWNER_TYPES: DocumentOwnerType[] = ['rfq', 'order', 'shipment', 'support_ticket'];
const KINDS: DocumentKind[] = [
  'rfq_attachment', 'quote_attachment', 'order_document',
  'shipment_document', 'compliance', 'other',
];

export default function Documents() {
  const { push } = useToast();
  const [ownerType, setOwnerType] = useState<DocumentOwnerType>('order');
  const [ownerId, setOwnerId] = useState('');
  const [kind, setKind] = useState<DocumentKind>('order_document');
  const [file, setFile] = useState<File | null>(null);
  const [busy, setBusy] = useState(false);
  const [lastDocId, setLastDocId] = useState<string | null>(null);

  const upload = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file || !ownerId.trim()) return;
    setBusy(true);
    try {
      const doc = await api.documents.upload({
        file,
        kind,
        ownerType,
        ownerId: ownerId.trim(),
      });
      push(`Document attached (${doc.id}).`, 'success');
      setFile(null);
      setLastDocId(doc.id);
    } catch (err) {
      push(mapError(err).message, 'error');
    } finally {
      setBusy(false);
    }
  };

  const download = async () => {
    if (!lastDocId) return;
    try {
      const { url } = await api.documents.downloadUrl(lastDocId);
      window.open(url, '_blank', 'noopener');
    } catch (err) {
      push(mapError(err).message, 'error');
    }
  };

  return (
    <div className="egt-card" style={{ maxWidth: 640 }}>
      <div className="egt-card__title">Attach document</div>
      <p className="egt-hint">
        Files are stored privately (10 MB max, random filename). Downloads go
        through a signed URL that expires after 15 minutes.
      </p>
      <form onSubmit={upload}>
        <div className="egt-form-row">
          <Field label="Attach to">
            <select className="egt-select" value={ownerType} onChange={(e) => setOwnerType(e.target.value as DocumentOwnerType)}>
              {OWNER_TYPES.map((t) => <option key={t} value={t}>{t.replace(/_/g, ' ')}</option>)}
            </select>
          </Field>
          <Field label="Record ID (UUID)">
            <input className="egt-input" value={ownerId} onChange={(e) => setOwnerId(e.target.value)}
              placeholder="e.g. the order UUID" required />
          </Field>
        </div>
        <Field label="Document kind">
          <select className="egt-select" value={kind} onChange={(e) => setKind(e.target.value as DocumentKind)}>
            {KINDS.map((k) => <option key={k} value={k}>{k.replace(/_/g, ' ')}</option>)}
          </select>
        </Field>
        <Field label="File">
          <input type="file" onChange={(e) => setFile(e.target.files?.[0] ?? null)} required />
        </Field>
        <div className="egt-modal__actions" style={{ padding: 0, border: 'none' }}>
          <button className="egt-btn egt-btn--primary" disabled={busy || !file || !ownerId.trim()}>
            {busy ? 'Uploading…' : 'Upload & attach'}
          </button>
          {lastDocId && (
            <button type="button" className="egt-btn egt-btn--ghost" onClick={download}>
              Get download link for last upload
            </button>
          )}
        </div>
      </form>
    </div>
  );
}
