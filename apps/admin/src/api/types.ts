/**
 * EGT Admin — API data transfer objects.
 *
 * RECONCILED 2026-09-25 against the real NestJS contract published at
 * packages/shared/openapi.yaml (EGT B2B API v1, 63 paths).
 *
 * IMPORTANT — response shapes: the published spec declares request DTOs,
 * path/query shapes and enums, but declares NO response schemas (every
 * response entry is empty). Anything marked UNDECLARED-RESPONSE-SHAPE below
 * is a client-side assumption about what the backend returns; request field
 * names and enum values match the spec exactly.
 */

export type Role = 'buyer' | 'supplier' | 'staff' | 'admin';

/** UNDECLARED-RESPONSE-SHAPE. Field names follow the spec's RegisterDto/UpdateMeDto vocabulary. */
export interface User {
  id: string;
  email: string;
  fullName: string;
  /** Tolerated alias — older admin builds used `name`. */
  name?: string;
  phone?: string;
  role: Role;
  isActive: boolean;
  createdAt: string;
  lastLoginAt?: string;
}

export interface Tokens {
  accessToken: string;
  refreshToken: string;
}

/** UNDECLARED-RESPONSE-SHAPE. The spec only guarantees an access token + rotating refresh token. */
export interface LoginResponse {
  user: User;
  tokens?: Tokens;
}

/** UNDECLARED-RESPONSE-SHAPE. */
export interface Session {
  id: string;
  ip?: string;
  userAgent?: string;
  createdAt?: string;
  lastSeenAt?: string;
  current?: boolean;
}

/**
 * UNDECLARED-RESPONSE-SHAPE: the spec marks list endpoints "paginated" but
 * publishes no pagination envelope. The client normalises array responses
 * into this shape (see getPaged in client.ts).
 */
export interface Paged<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

/* ---------------- Dashboard ---------------- */

/** UNDECLARED-RESPONSE-SHAPE. All widgets optional — UI renders an empty state for anything absent. */
export interface DashboardOverview {
  rfqVolume?: { total: number; byStatus: Record<string, number>; trend: { date: string; count: number }[] };
  conversionFunnel?: { stage: string; count: number }[];
  orderPipeline?: { status: string; count: number; value?: number }[];
  shipmentPipeline?: { status: string; count: number }[];
  geographicDemand?: { country: string; rfqs: number; orders: number }[];
}

/* ---------------- RFQs ---------------- */

/** Exact `to` values from TransitionRfqDto in the spec. */
export type RfqStatus =
  | 'under_review'
  | 'sourcing'
  | 'supplier_matched'
  | 'sample_discussion'
  | 'quotation_ready'
  | 'buyer_action_required'
  | 'approved'
  | 'order_processing'
  | 'completed'
  | 'closed';

/**
 * Client-side transition menu. The spec enforces a strict state machine
 * server-side but does not publish the allowed graph, so this is a
 * conservative forward-flow assumption — the backend is the authority and
 * will reject anything illegal.
 */
export const RFQ_TRANSITIONS: Record<RfqStatus, RfqStatus[]> = {
  under_review: ['sourcing', 'closed'],
  sourcing: ['supplier_matched', 'closed'],
  supplier_matched: ['sample_discussion', 'closed'],
  sample_discussion: ['quotation_ready', 'buyer_action_required', 'closed'],
  quotation_ready: ['buyer_action_required', 'approved', 'closed'],
  buyer_action_required: ['sample_discussion', 'quotation_ready', 'closed'],
  approved: ['order_processing', 'closed'],
  order_processing: ['completed', 'closed'],
  completed: [],
  closed: [],
};

/** UNDECLARED-RESPONSE-SHAPE. */
export interface Rfq {
  id: string;
  reference: string;
  buyerName: string;
  company?: string;
  email: string;
  phone: string;
  productNames: string[];
  quantity: string;
  destinationCountry: string;
  status: RfqStatus;
  assignedTo?: { id: string; name: string };
  createdAt: string;
  updatedAt: string;
}

/** UNDECLARED-RESPONSE-SHAPE. */
export interface RfqDetail extends Rfq {
  message?: string;
  budget?: string;
  currency?: string;
  privateLabel?: boolean;
  shippingPreference?: string;
}

/* ---------------- Quotes (POST /quotes — CreateQuoteDto, exact fields) ---------------- */

export type QuoteIncoterm = 'FOB' | 'CIF' | 'DDP' | 'EXW';

export interface QuoteItemInput {
  productId?: string;
  description: string;
  quantity: number;
  unit?: string;
  unitPrice: number;
}

export interface QuoteInput {
  rfqId: string;
  currency?: string;
  shippingCost?: number;
  incoterm: QuoteIncoterm;
  /** ISO date the quote remains valid until. */
  validUntil: string;
  notes?: string;
  items: QuoteItemInput[];
}

/** UNDECLARED-RESPONSE-SHAPE. */
export interface Quote {
  id: string;
  rfqId?: string;
  status?: string;
  createdAt?: string;
}

/* ---------------- Conversations ---------------- */

export type ConversationKind = 'rfq' | 'order' | 'shipment' | 'support_ticket';

/** UNDECLARED-RESPONSE-SHAPE. */
export interface Conversation {
  id: string;
  kind?: ConversationKind;
  rfqId?: string;
  orderId?: string;
  shipmentId?: string;
  ticketId?: string;
  subject?: string;
  unreadCount?: number;
}

export interface OpenConversationInput {
  kind: ConversationKind;
  rfqId?: string;
  orderId?: string;
  shipmentId?: string;
  ticketId?: string;
  subject?: string;
}

/** UNDECLARED-RESPONSE-SHAPE. SendMessageDto only declares `body`. */
export interface ConversationMessage {
  id: string;
  body?: string;
  /** Tolerated alias. */
  text?: string;
  author?: string;
  authorName?: string;
  from?: string;
  createdAt?: string;
}

/* ---------------- Products ---------------- */

/** UNDECLARED-RESPONSE-SHAPE. */
export interface Product {
  id: string;
  name: string;
  shortDescription?: string;
  description?: string;
  category?: string;
  orderVolume?: string;
  isActive?: boolean;
  isFeatured?: boolean;
  sortOrder?: number;
  images?: { id: string; url: string; alt?: string }[];
  createdAt?: string;
  updatedAt?: string;
}

/** Exact UpdateProductDto fields from the spec (PATCH /products/{id}). */
export interface UpdateProductDto {
  name?: string;
  shortDescription?: string;
  orderVolume?: string;
  isActive?: boolean;
  isFeatured?: boolean;
  sortOrder?: number;
}

/** POST /products declares no request body in the spec; best-effort shape. */
export interface ProductInput extends UpdateProductDto {
  name: string;
}

/* ---------------- Supplier listings (review queue) ---------------- */

/**
 * The spec has no supplier CRUD. Staff review lives at
 * GET /suppliers/pending + PATCH /suppliers/listings/{id}/review.
 */
export type SupplierListingStatus = 'pending' | 'approved' | 'changes_required' | 'rejected';

/** UNDECLARED-RESPONSE-SHAPE. */
export interface SupplierListing {
  id: string;
  productId?: string;
  productName?: string;
  customName?: string;
  customDescription?: string;
  supplierName?: string;
  companyName?: string;
  status: SupplierListingStatus;
  reviewNote?: string;
  createdAt?: string;
}

/** Exact ReviewSupplierProductDto fields from the spec. */
export interface ReviewListingInput {
  status: 'approved' | 'changes_required' | 'rejected';
  reviewNote?: string;
}

/* ---------------- Orders & shipments ---------------- */

/** Exact UpdateOrderStatusDto values from the spec. */
export type OrderStatus =
  | 'confirmed'
  | 'in_production'
  | 'ready_to_ship'
  | 'shipped'
  | 'delivered'
  | 'cancelled';

/**
 * Client-side transition menu. The spec enforces a strict forward flow
 * server-side but does not publish the graph; this is a conservative
 * assumption and the backend will reject anything illegal.
 */
export const ORDER_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  confirmed: ['in_production', 'cancelled'],
  in_production: ['ready_to_ship', 'cancelled'],
  ready_to_ship: ['shipped', 'cancelled'],
  shipped: ['delivered'],
  delivered: [],
  cancelled: [],
};

/** UNDECLARED-RESPONSE-SHAPE. */
export interface Order {
  id: string;
  reference: string;
  buyerName: string;
  company?: string;
  rfqId?: string;
  status: OrderStatus;
  totalValue?: number;
  currency?: string;
  shipmentId?: string;
  createdAt: string;
}

/** Exact AddEventDto status values from the spec. */
export type ShipmentEventStatus =
  | 'picked_up'
  | 'in_transit'
  | 'customs'
  | 'out_for_delivery'
  | 'delivered'
  | 'exception';

/** UNDECLARED-RESPONSE-SHAPE. */
export interface ShipmentEvent {
  id: string;
  status: ShipmentEventStatus;
  location?: string;
  note?: string;
  occurredAt?: string;
  createdBy?: string;
}

/** Exact AddEventDto fields from the spec. */
export interface AddShipmentEventInput {
  status: ShipmentEventStatus;
  location?: string;
  note?: string;
}

/** UNDECLARED-RESPONSE-SHAPE. The spec returns the event timeline inline with the detail. */
export interface Shipment {
  id: string;
  reference: string;
  orderId: string;
  status?: string;
  origin?: string;
  destination?: string;
  eta?: string;
  events?: ShipmentEvent[];
  updatedAt?: string;
}

/* ---------------- Documents ---------------- */

export type DocumentKind =
  | 'rfq_attachment'
  | 'quote_attachment'
  | 'order_document'
  | 'shipment_document'
  | 'compliance'
  | 'other';

export type DocumentOwnerType = 'rfq' | 'order' | 'shipment' | 'support_ticket';

export interface UploadDocumentInput {
  file: File;
  kind: DocumentKind;
  ownerType: DocumentOwnerType;
  ownerId: string;
}

/** UNDECLARED-RESPONSE-SHAPE. */
export interface Document {
  id: string;
  name?: string;
  kind?: string;
  url?: string;
}

/** UNDECLARED-RESPONSE-SHAPE. */
export interface DownloadUrl {
  url: string;
}

/* ---------------- Support tickets ---------------- */

/** Exact UpdateTicketDto status values from the spec. */
export type TicketStatus =
  | 'open'
  | 'in_progress'
  | 'waiting_on_customer'
  | 'resolved'
  | 'closed';

/** Exact priority values from CreateTicketDto/UpdateTicketDto. */
export type TicketPriority = 'low' | 'medium' | 'high' | 'urgent';

/** Exact UpdateTicketDto fields from the spec. */
export interface UpdateTicketInput {
  status?: TicketStatus;
  priority?: TicketPriority;
  assigneeId?: string;
}

/** UNDECLARED-RESPONSE-SHAPE. The spec returns the ticket's conversation inline with the detail. */
export interface Ticket {
  id: string;
  subject: string;
  requester?: string;
  requesterEmail?: string;
  status: TicketStatus;
  priority: TicketPriority;
  assignedTo?: { id: string; name?: string };
  createdAt?: string;
  updatedAt?: string;
  messages?: TicketMessage[];
  conversation?: { messages?: TicketMessage[] };
}

/** UNDECLARED-RESPONSE-SHAPE. ReplyTicketDto only declares `body`. */
export interface TicketMessage {
  id: string;
  body?: string;
  /** Tolerated alias. */
  text?: string;
  author?: string;
  from?: string;
  createdAt?: string;
}

/* ---------------- Audit log ---------------- */

/** UNDECLARED-RESPONSE-SHAPE. */
export interface AuditEntry {
  id: string;
  actor: string;
  actorEmail?: string;
  action: string;
  objectType: string;
  objectId?: string;
  ip?: string;
  createdAt: string;
}
