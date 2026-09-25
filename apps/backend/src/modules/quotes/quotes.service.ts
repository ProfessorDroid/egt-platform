import {
  ConflictException, ForbiddenException, Injectable, NotFoundException, UnprocessableEntityException,
} from '@nestjs/common';
import { AuditAction, Prisma, QuoteStatus, RfqStatus } from '@prisma/client';
import { nextYearlyNumber } from '../../common/utils/sequences.util';
import { paginated, parsePagination, sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.module';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateQuoteDto } from './dto/quote.dto';

@Injectable()
export class QuotesService {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private notifications: NotificationsService,
  ) {}

  /** Staff/admin create a quote against an RFQ that is in quotation_ready. */
  async create(caller: { sub: string }, dto: CreateQuoteDto, meta: { ip?: string; userAgent?: string }) {
    const rfq = await this.prisma.rfq.findFirst({ where: { id: dto.rfqId, deletedAt: null } });
    if (!rfq) throw new NotFoundException({ code: 'NOT_FOUND', message: 'RFQ not found.' });
    if (rfq.status !== RfqStatus.quotation_ready) {
      throw new UnprocessableEntityException({
        code: 'RFQ_NOT_QUOTABLE',
        message: 'Quotes can only be created while the RFQ is in "Quotation Ready".',
        details: { rfqStatus: rfq.status },
      });
    }

    const validUntil = new Date(dto.validUntil);
    if (Number.isNaN(validUntil.getTime()) || validUntil <= new Date()) {
      throw new UnprocessableEntityException({
        code: 'INVALID_VALIDITY',
        message: 'The quote validity date must be in the future.',
      });
    }

    const items = dto.items.map((i) => {
      const lineTotal = Number(i.quantity) * Number(i.unitPrice);
      return {
        productId: i.productId,
        description: sanitizeText(i.description),
        quantity: i.quantity,
        unit: i.unit ?? 'units',
        unitPrice: i.unitPrice,
        lineTotal,
      };
    });
    const subtotal = items.reduce((s, i) => s + i.lineTotal, 0);
    const shipping = dto.shippingCost ?? 0;

    const quote = await this.prisma.quote.create({
      data: {
        rfqId: rfq.id,
        status: QuoteStatus.draft,
        currency: dto.currency ?? 'USD',
        subtotal,
        shippingCost: shipping,
        total: subtotal + shipping,
        incoterm: dto.incoterm,
        validUntil,
        notes: dto.notes ? sanitizeText(dto.notes) : undefined,
        items: { create: items },
        createdBy: caller.sub,
      },
      include: { items: true },
    });
    await this.audit.log(AuditAction.quote_created, {
      actorId: caller.sub, ipAddress: meta.ip, userAgent: meta.userAgent,
      entityType: 'quote', entityId: quote.id, metadata: { rfqId: rfq.id, total: quote.total },
    });
    return quote;
  }

  async send(caller: { sub: string }, id: string, meta: { ip?: string; userAgent?: string }) {
    const quote = await this.mustFind(id);
    if (quote.status !== QuoteStatus.draft && quote.status !== QuoteStatus.revision_requested) {
      throw new UnprocessableEntityException({
        code: 'QUOTE_NOT_SENDABLE', message: 'Only draft or revision-requested quotes can be sent.',
      });
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      const q = await tx.quote.update({
        where: { id }, data: { status: QuoteStatus.sent, sentAt: new Date(), updatedBy: caller.sub },
      });
      await tx.rfq.update({ where: { id: q.rfqId }, data: { status: RfqStatus.buyer_action_required, statusChangedAt: new Date() } });
      return q;
    });
    await this.notifications.emit('quote_available', quote.rfq.buyerId, {
      title: `New quote for RFQ ${quote.rfq.rfqNumber}`,
      body: `EGT sent a quote of ${updated.currency} ${updated.total}. Valid until ${updated.validUntil.toDateString()}.`,
      data: { quoteId: id, rfqId: quote.rfqId },
    });
    return updated;
  }

  /**
   * Buyer accepts a quote. ALL rules re-verified server-side at accept time:
   *  - quote.status === sent (a live, unexpired offer)
   *  - quote.validUntil is in the future (expired → 422)
   *  - caller owns the RFQ (wrong owner → 403)
   *  - RFQ is in quotation_ready / buyer_action_required
   *  - idempotency: already-accepted → 409
   * On success the quote is accepted, the RFQ moves to approved and an order
   * is created atomically.
   */
  async accept(caller: { sub: string }, id: string, meta: { ip?: string; userAgent?: string }) {
    const quote = await this.mustFind(id);

    if (quote.rfq.buyerId !== caller.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    if (quote.status === QuoteStatus.accepted) {
      throw new ConflictException({ code: 'QUOTE_ALREADY_ACCEPTED', message: 'This quote has already been accepted.' });
    }
    if (quote.status !== QuoteStatus.sent) {
      throw new UnprocessableEntityException({
        code: 'QUOTE_NOT_ACCEPTABLE',
        message: 'Only a live (sent) quote can be accepted.',
        details: { quoteStatus: quote.status },
      });
    }
    if (quote.validUntil <= new Date()) {
      throw new UnprocessableEntityException({
        code: 'QUOTE_EXPIRED',
        message: 'This quote has expired. Please request a revised quote.',
        details: { validUntil: quote.validUntil },
      });
    }
    if (!([RfqStatus.quotation_ready, RfqStatus.buyer_action_required] as RfqStatus[]).includes(quote.rfq.status)) {
      throw new UnprocessableEntityException({
        code: 'RFQ_NOT_QUOTABLE',
        message: 'The RFQ is no longer in a quotable state.',
        details: { rfqStatus: quote.rfq.status },
      });
    }

    const result = await this.prisma.$transaction(async (tx) => {
      // Re-read inside the transaction to close the race between check and write.
      const fresh = await tx.quote.findUniqueOrThrow({ where: { id }, include: { rfq: true, items: true } });
      if (fresh.status !== QuoteStatus.sent) {
        throw new ConflictException({ code: 'QUOTE_STATE_CHANGED', message: 'The quote changed while you were reviewing it. Please refresh.' });
      }
      const orderNumber = await nextYearlyNumber(tx, 'OrderSequence', 'EGT-ORD');
      const order = await tx.order.create({
        data: {
          orderNumber,
          rfqId: fresh.rfqId,
          quoteId: fresh.id,
          buyerId: fresh.rfq.buyerId,
          companyId: fresh.rfq.companyId,
          status: 'pending',
          currency: fresh.currency,
          total: fresh.total,
          items: {
            create: fresh.items.map((i) => ({
              productId: i.productId,
              description: i.description,
              quantity: i.quantity,
              unit: i.unit,
              unitPrice: i.unitPrice,
              lineTotal: i.lineTotal,
            })),
          },
          createdBy: caller.sub,
        },
      });
      const acceptedQuote = await tx.quote.update({
        where: { id },
        data: { status: QuoteStatus.accepted, acceptedAt: new Date(), acceptedBy: caller.sub, updatedBy: caller.sub },
      });
      await tx.rfq.update({
        where: { id: fresh.rfqId },
        data: { status: RfqStatus.approved, statusChangedAt: new Date(), updatedBy: caller.sub },
      });
      return { quote: acceptedQuote, order };
    });

    await this.audit.log(AuditAction.quote_accepted, {
      actorId: caller.sub, ipAddress: meta.ip, userAgent: meta.userAgent,
      entityType: 'quote', entityId: id,
      metadata: { orderId: result.order.id, orderNumber: result.order.orderNumber },
    });
    await this.notifications.emit('order_status_changed', quote.rfq.buyerId, {
      title: `Order ${result.order.orderNumber} created`,
      body: `Your quote was accepted and order ${result.order.orderNumber} is now pending confirmation.`,
      data: { orderId: result.order.id, quoteId: id },
    });
    return result;
  }

  async reject(caller: { sub: string }, id: string, reason: string | undefined, meta: { ip?: string; userAgent?: string }) {
    const quote = await this.mustFind(id);
    if (quote.rfq.buyerId !== caller.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    if (quote.status !== QuoteStatus.sent) {
      throw new UnprocessableEntityException({ code: 'QUOTE_NOT_REJECTABLE', message: 'Only a live (sent) quote can be rejected.' });
    }
    const updated = await this.prisma.quote.update({
      where: { id },
      data: { status: QuoteStatus.rejected, rejectionReason: reason ? sanitizeText(reason) : undefined, updatedBy: caller.sub },
    });
    await this.audit.log(AuditAction.quote_rejected, {
      actorId: caller.sub, ipAddress: meta.ip, userAgent: meta.userAgent, entityType: 'quote', entityId: id,
    });
    return updated;
  }

  /** Buyer asks staff to revise a live quote — quote returns to staff. */
  async requestRevision(caller: { sub: string }, id: string, reason: string | undefined, meta: { ip?: string; userAgent?: string }) {
    const quote = await this.mustFind(id);
    if (quote.rfq.buyerId !== caller.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    if (quote.status !== QuoteStatus.sent) {
      throw new UnprocessableEntityException({ code: 'QUOTE_NOT_REVISABLE', message: 'Only a live (sent) quote can be sent back for revision.' });
    }
    const updated = await this.prisma.quote.update({
      where: { id },
      data: {
        status: QuoteStatus.revision_requested,
        rejectionReason: reason ? sanitizeText(reason) : undefined,
        updatedBy: caller.sub,
      },
    });
    await this.notifications.emit('quote_revision_requested', quote.rfq.buyerId, {
      title: 'Quote sent back for revision',
      body: `Your revision request on quote for RFQ ${quote.rfq.rfqNumber} was recorded.`,
      data: { quoteId: id, rfqId: quote.rfqId },
    });
    return updated;
  }

  async list(caller: { sub: string; role: string }, query: { page?: string; limit?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const isStaff = caller.role === 'staff' || caller.role === 'admin';
    const where: Prisma.QuoteWhereInput = { deletedAt: null };
    if (!isStaff) where.rfq = { buyerId: caller.sub };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.quote.findMany({ where, skip, take, orderBy: { createdAt: 'desc' }, include: { items: true } }),
      this.prisma.quote.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }

  async getOne(caller: { sub: string; role: string }, id: string) {
    const quote = await this.mustFind(id);
    const isStaff = caller.role === 'staff' || caller.role === 'admin';
    if (!isStaff && quote.rfq.buyerId !== caller.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    return quote;
  }

  private async mustFind(id: string) {
    const quote = await this.prisma.quote.findFirst({
      where: { id, deletedAt: null },
      include: { items: true, rfq: true },
    });
    if (!quote) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Quote not found.' });
    return quote;
  }
}
