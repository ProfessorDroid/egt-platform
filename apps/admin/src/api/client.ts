/**
 * EGT Admin — HTTP client.
 *
 * RECONCILED 2026-09-25 against the real NestJS contract published at
 * packages/shared/openapi.yaml (EGT B2B API v1). Every path/method/body
 * below exists in that spec with the field names shown.
 *
 * Absent from the spec (so NOT exposed here — the UI marks those features
 * as unsupported instead of calling a fabricated endpoint):
 *   - MFA (/auth/mfa/*) and password re-auth (/auth/reauth)
 *   - RFQ assign, RFQ notes, RFQ request-info
 *   - product DELETE and product image endpoints
 *   - supplier CRUD / approve / suspend / supplier documents
 *   - order/shipment document listing, shipment milestone endpoint
 *   - documents vault listing and document categories
 */
import axios, { AxiosError, AxiosInstance, AxiosRequestConfig } from 'axios';
import type {
  AddShipmentEventInput, AuditEntry, Conversation, ConversationMessage, DashboardOverview,
  Document, DownloadUrl, LoginResponse, OpenConversationInput, Order,
  OrderStatus, Paged, Product, ProductInput, Quote, QuoteInput, ReviewListingInput, Rfq,
  RfqDetail, RfqStatus, Role, Session, Shipment, ShipmentEvent, SupplierListing, Ticket,
  TicketMessage, Tokens, UpdateProductDto, UpdateTicketInput, UploadDocumentInput, User,
} from './types';

export const API_BASE: string =
  (import.meta.env.VITE_API_URL as string | undefined) || '/api/v1';

/* ---------------- token store (access token in memory, refresh in sessionStorage) ---------------- */

const REFRESH_KEY = 'egt.admin.refresh';
let accessToken: string | null = null;

export function setTokens(t: Tokens | null): void {
  accessToken = t?.accessToken ?? null;
  if (t) sessionStorage.setItem(REFRESH_KEY, t.refreshToken);
  else sessionStorage.removeItem(REFRESH_KEY);
}
export function getRefreshToken(): string | null {
  return sessionStorage.getItem(REFRESH_KEY);
}
export function clearSession(): void {
  accessToken = null;
  sessionStorage.removeItem(REFRESH_KEY);
}

/* ---------------- friendly error mapping ---------------- */

export interface ApiError {
  status?: number;
  code: string;
  /** User-facing message — never a raw stack trace. */
  message: string;
  fields?: Record<string, string>;
}

interface ErrorBody {
  message?: string;
  errors?: Record<string, string>;
}

export function mapError(err: unknown): ApiError {
  if (axios.isAxiosError(err)) {
    const ax = err as AxiosError<ErrorBody>;
    if (!ax.response) {
      return {
        code: 'network',
        message: "We couldn't reach the server. Check your connection and try again.",
      };
    }
    const s = ax.response.status;
    const detail = ax.response.data?.message;
    if (s === 400) return { status: s, code: 'bad-request', message: detail || 'That request wasn’t valid. Please check the form and try again.' };
    if (s === 401) return { status: s, code: 'unauthorized', message: 'Your session has expired. Please sign in again.' };
    if (s === 403) return { status: s, code: 'forbidden', message: "You don't have permission to do that." };
    if (s === 404) return { status: s, code: 'not-found', message: 'We couldn’t find what you asked for. It may have been moved or deleted.' };
    if (s === 409) return { status: s, code: 'conflict', message: detail || 'That conflicts with the current state. Refresh and try again.' };
    if (s === 422) return { status: s, code: 'validation', message: detail || 'Some fields need attention before this can be saved.', fields: ax.response.data?.errors };
    if (s >= 500) return { status: s, code: 'server', message: 'Something went wrong on our side. Please try again in a moment.' };
    return { status: s, code: 'unknown', message: detail || 'Something unexpected happened. Please try again.' };
  }
  return { code: 'unknown', message: 'Something unexpected happened. Please try again.' };
}

/* ---------------- axios instance with auth + refresh ---------------- */

const http: AxiosInstance = axios.create({ baseURL: API_BASE, timeout: 20000 });

http.interceptors.request.use((config) => {
  if (accessToken) config.headers.Authorization = `Bearer ${accessToken}`;
  return config;
});

let refreshPromise: Promise<Tokens> | null = null;

async function doRefresh(): Promise<Tokens> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) throw new Error('no-refresh-token');
  // Real flow per spec: POST /auth/refresh { refreshToken } rotates the pair;
  // reuse detection locks the session server-side.
  const { data } = await axios.post<Tokens>(`${API_BASE}/auth/refresh`, { refreshToken });
  setTokens(data);
  return data;
}

http.interceptors.response.use(
  (res) => res,
  async (error: unknown) => {
    const ax = error as AxiosError;
    const original = ax.config as (AxiosRequestConfig & { _retried?: boolean }) | undefined;
    const isRefreshCall = ax.config?.url?.includes('/auth/refresh');
    if (ax.response?.status === 401 && original && !original._retried && !isRefreshCall) {
      original._retried = true;
      try {
        refreshPromise = refreshPromise ?? doRefresh().finally(() => { refreshPromise = null; });
        const tokens = await refreshPromise;
        original.headers = { ...original.headers, Authorization: `Bearer ${tokens.accessToken}` };
        return http(original);
      } catch {
        clearSession();
        window.dispatchEvent(new CustomEvent('egt:session-expired'));
      }
    }
    throw error;
  },
);

/* ---------------- small helpers ---------------- */

async function get<T>(url: string, params?: Record<string, unknown>): Promise<T> {
  const { data } = await http.get<T>(url, { params });
  return data;
}

/**
 * The spec marks list endpoints "paginated" but publishes no envelope, so a
 * list may come back as an array or as a paged object — normalise to Paged.
 */
async function getPaged<T>(url: string, params?: Record<string, unknown>): Promise<Paged<T>> {
  const data = await get<Paged<T> | T[]>(url, params);
  if (Array.isArray(data)) {
    const page = typeof params?.page === 'number' ? params.page : 1;
    const pageSize = typeof params?.pageSize === 'number' ? params.pageSize : data.length;
    return { items: data, total: data.length, page, pageSize };
  }
  return data;
}

async function post<T>(url: string, body?: unknown): Promise<T> {
  const { data } = await http.post<T>(url, body);
  return data;
}
async function patch<T>(url: string, body?: unknown): Promise<T> {
  const { data } = await http.patch<T>(url, body);
  return data;
}
async function del<T>(url: string): Promise<T> {
  const { data } = await http.delete<T>(url);
  return data;
}
async function postForm<T>(url: string, form: FormData): Promise<T> {
  const { data } = await http.post<T>(url, form, { headers: { 'Content-Type': 'multipart/form-data' } });
  return data;
}

/* ---------------- API surface (reconciled with openapi.yaml v1) ---------------- */

export const api = {
  auth: {
    login: async (email: string, password: string): Promise<LoginResponse> => {
      // The API returns tokens flat ({accessToken, refreshToken, ...});
      // normalize to the {user, tokens} shape the session layer expects.
      const res = await post<LoginResponse & { accessToken?: string; refreshToken?: string }>(
        '/auth/login',
        { email, password },
      );
      if (!res.tokens && res.accessToken && res.refreshToken) {
        res.tokens = { accessToken: res.accessToken, refreshToken: res.refreshToken };
      }
      return res as LoginResponse;
    },
    me: () => get<User>('/auth/me'),
    logout: () => post<{ ok: boolean }>('/auth/logout').catch(() => ({ ok: true })),
    logoutAll: () => post<{ ok: boolean }>('/auth/logout-all'),
    /** The caller's own device sessions. */
    sessions: () => get<Session[]>('/auth/sessions'),
    revokeSession: (id: string) => del<{ ok: boolean }>(`/auth/sessions/${id}`),
  },

  dashboard: {
    overview: () => get<DashboardOverview>('/admin/overview'),
  },

  rfqs: {
    list: (params: { page?: number; pageSize?: number; status?: string; q?: string }) =>
      getPaged<Rfq>('/rfqs', params),
    get: (id: string) => get<RfqDetail>(`/rfqs/${id}`),
    /** POST /rfqs/{id}/transition { to } — TransitionRfqDto, exact enum in types.ts. */
    transition: (id: string, to: RfqStatus) =>
      post<Rfq>(`/rfqs/${id}/transition`, { to }),
  },

  quotes: {
    create: (input: QuoteInput) => post<Quote>('/quotes', input),
    list: (params: { page?: number; pageSize?: number }) => getPaged<Quote>('/quotes', params),
    get: (id: string) => get<Quote>(`/quotes/${id}`),
    send: (id: string) => post<Quote>(`/quotes/${id}/send`),
  },

  conversations: {
    list: () => get<Conversation[]>('/conversations'),
    open: (input: OpenConversationInput) => post<Conversation>('/conversations', input),
    messages: (id: string) => get<ConversationMessage[]>(`/conversations/${id}/messages`),
    send: (id: string, body: string) =>
      post<ConversationMessage>(`/conversations/${id}/messages`, { body }),
  },

  products: {
    list: (params: { page?: number; pageSize?: number; q?: string; category?: string }) =>
      getPaged<Product>('/products', params),
    /** Detail is looked up by slug in the real API. */
    getBySlug: (slug: string) => get<Product>(`/products/${slug}`),
    create: (input: ProductInput) => post<Product>('/products', input),
    /** Exact UpdateProductDto fields only. */
    update: (id: string, dto: UpdateProductDto) => patch<Product>(`/products/${id}`, dto),
    setFeatured: (id: string, featured: boolean) =>
      patch<Product>(`/products/${id}`, { isFeatured: featured }),
    setActive: (id: string, active: boolean) =>
      patch<Product>(`/products/${id}`, { isActive: active }),
    categories: () => get<string[]>('/products/categories'),
  },

  /** Staff review queue: the spec exposes listings, not supplier accounts. */
  supplierListings: {
    pending: (params: { page?: number; pageSize?: number }) =>
      getPaged<SupplierListing>('/suppliers/pending', params),
    /** Exact ReviewSupplierProductDto fields. */
    review: (id: string, input: ReviewListingInput) =>
      patch<SupplierListing>(`/suppliers/listings/${id}/review`, input),
  },

  orders: {
    list: (params: { page?: number; pageSize?: number; status?: string; q?: string }) =>
      getPaged<Order>('/orders', params),
    get: (id: string) => get<Order>(`/orders/${id}`),
    /** PATCH /orders/{id}/status { status } — exact UpdateOrderStatusDto enum. No note field. */
    setStatus: (id: string, status: OrderStatus) =>
      patch<Order>(`/orders/${id}/status`, { status }),
  },

  shipments: {
    list: (params: { page?: number; pageSize?: number; q?: string }) =>
      getPaged<Shipment>('/shipments', params),
    /** Detail carries the event timeline inline. */
    get: (id: string) => get<Shipment>(`/shipments/${id}`),
    /** Exact AddEventDto fields; moves the shipment status forward. */
    addEvent: (id: string, ev: AddShipmentEventInput) =>
      post<ShipmentEvent>(`/shipments/${id}/events`, ev),
  },

  documents: {
    /**
     * Real upload: multipart { file, kind, ownerType, ownerId }.
     * There is no vault listing endpoint in the spec.
     */
    upload: (input: UploadDocumentInput) => {
      const form = new FormData();
      form.append('file', input.file);
      form.append('kind', input.kind);
      form.append('ownerType', input.ownerType);
      form.append('ownerId', input.ownerId);
      return postForm<Document>('/documents/upload', form);
    },
    /** Mint a 15-minute signed download URL. */
    downloadUrl: (id: string) => get<DownloadUrl>(`/documents/${id}/download-url`),
  },

  tickets: {
    list: (params: { page?: number; pageSize?: number; status?: string; q?: string }) =>
      getPaged<Ticket>('/support/tickets', params),
    /** Detail carries the ticket's conversation inline. */
    get: (id: string) => get<Ticket>(`/support/tickets/${id}`),
    /** Exact UpdateTicketDto fields: status / priority / assigneeId. */
    update: (id: string, input: UpdateTicketInput) =>
      patch<Ticket>(`/support/tickets/${id}`, input),
    /** ReplyTicketDto: { body }. */
    reply: (id: string, body: string) =>
      post<TicketMessage>(`/support/tickets/${id}/reply`, { body }),
  },

  users: {
    list: (params: { page?: number; pageSize?: number; q?: string }) =>
      getPaged<User>('/admin/users', params),
    /** Exact ChangeRoleDto: { role: buyer | supplier | staff | admin }. */
    setRole: (id: string, role: Role) => patch<User>(`/admin/users/${id}/role`, { role }),
    /**
     * PATCH /admin/users/{id}/active — the spec declares no request body;
     * the backend toggles the active flag.
     */
    toggleActive: (id: string) => patch<User>(`/admin/users/${id}/active`),
  },

  audit: {
    list: (params: { page?: number; pageSize?: number; actor?: string; action?: string; objectType?: string; from?: string; to?: string }) =>
      getPaged<AuditEntry>('/admin/audit-log', params),
  },
};

export type Api = typeof api;
