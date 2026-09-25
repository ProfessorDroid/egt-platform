// @egt/shared — hand-written shared types for the EGT app program.
// `src/generated/api.d.ts` (created by `npm run generate` via openapi-typescript)
// carries the full machine-generated API contract; the types below are the
// small hand-maintained surface used across mobile/admin.

export type RoleName = 'buyer' | 'supplier' | 'staff' | 'admin';

export type RfqStatus =
  | 'submitted' | 'under_review' | 'sourcing' | 'supplier_matched'
  | 'sample_discussion' | 'quotation_ready' | 'buyer_action_required'
  | 'approved' | 'order_processing' | 'completed' | 'closed';

export type QuoteStatus =
  | 'draft' | 'sent' | 'revision_requested' | 'accepted'
  | 'rejected' | 'expired' | 'withdrawn';

export type OrderStatus =
  | 'pending' | 'confirmed' | 'in_production' | 'ready_to_ship'
  | 'shipped' | 'delivered' | 'cancelled';

export type ShipmentStatus =
  | 'booked' | 'picked_up' | 'in_transit' | 'customs'
  | 'out_for_delivery' | 'delivered' | 'exception';

export type SupplierProductStatus =
  | 'pending_review' | 'approved' | 'changes_required' | 'rejected';

export type TicketStatus =
  | 'open' | 'in_progress' | 'waiting_on_customer' | 'resolved' | 'closed';

export interface ErrorEnvelope {
  code: string;
  message: string;
  details?: unknown;
}

export interface Page<T> {
  data: T[];
  page: number;
  limit: number;
  total: number;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface CurrentUser {
  id: string;
  email: string;
  fullName: string;
  phone: string | null;
  role: RoleName;
  emailVerified: boolean;
}

export interface ProductSummary {
  id: string;
  name: string;
  slug: string;
  shortDescription: string | null;
  orderVolume: string | null;
  category: { id: string; name: string; slug: string };
  images: { url: string; alt: string | null }[];
  specifications: { text: string }[];
}

// Re-export the generated contract when it exists (created by npm run generate).
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type ApiPaths = any;
