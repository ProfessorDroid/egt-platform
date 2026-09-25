import { ForbiddenException, Injectable, NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { AuditAction, RfqStatus } from '@prisma/client';
import { nextYearlyNumber } from '../../common/utils/sequences.util';
import { paginated, parsePagination, sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.module';
import { NotificationsService } from '../notifications/notifications.service';
import { CreateRfqDto } from './dto/rfq.dto';
import { canTransitionRfq } from './rfq-state-machine';

@Injectable()
export class RfqsService {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private notifications: NotificationsService,
  ) {}

  /** Create an RFQ. The human-readable number is allocated in the SAME
   *  transaction as the insert — a failed insert rolls back the allocation. */
  async create(buyerId: string, dto: CreateRfqDto, meta: { ip?: string; userAgent?: string }) {
    const buyer = await this.prisma.user.findFirst({ where: { id: buyerId, deletedAt: null } });
    if (!buyer) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'Account not found.' });

    const rfq = await this.prisma.$transaction(async (tx) => {
      const rfqNumber = await nextYearlyNumber(tx, 'RfqSequence', 'EGT-RFQ');
      return tx.rfq.create({
        data: {
          rfqNumber,
          buyerId,
          companyId: buyer.companyId,
          status: RfqStatus.submitted,
          contactName: sanitizeText(dto.contactName),
          contactEmail: dto.contactEmail.toLowerCase(),
          contactPhone: dto.contactPhone,
          destinationCountry: sanitizeText(dto.destinationCountry),
          destinationCity: dto.destinationCity ? sanitizeText(dto.destinationCity) : undefined,
          deliveryAddress: dto.deliveryAddress ? sanitizeText(dto.deliveryAddress) : undefined,
          shippingPreference: dto.shippingPreference,
          currency: dto.currency ?? 'USD',
          budget: dto.budget,
          targetPrice: dto.targetPrice,
          privateLabel: dto.privateLabel ?? false,
          packagingPreference: dto.packagingPreference ? sanitizeText(dto.packagingPreference) : undefined,
          requirementDetails: sanitizeText(dto.requirementDetails),
          items: {
            create: dto.items.map((i) => ({
              productId: i.productId,
              customName: i.customName ? sanitizeText(i.customName) : undefined,
              customDetails: i.customDetails ? sanitizeText(i.customDetails) : undefined,
              quantity: i.quantity,
              unit: i.unit ?? 'units',
            })),
          },
        },
        include: { items: true },
      });
    });

    await this.audit.log(AuditAction.rfq_created, {
      actorId: buyerId, ipAddress: meta.ip, userAgent: meta.userAgent,
      entityType: 'rfq', entityId: rfq.id, metadata: { rfqNumber: rfq.rfqNumber },
    });
    return rfq;
  }

  /** Buyer sees own RFQs; staff/admin see all. Ownership enforced server-side. */
  async list(caller: { sub: string; role: string }, query: { page?: string; limit?: string; status?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const where: Record<string, unknown> = { deletedAt: null };
    if (caller.role === 'buyer' || caller.role === 'supplier') where.buyerId = caller.sub;
    if (query.status) where.status = query.status;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.rfq.findMany({
        where, skip, take, orderBy: { createdAt: 'desc' },
        include: { items: { include: { product: { select: { name: true } } } } },
      }),
      this.prisma.rfq.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }

  async getOne(caller: { sub: string; role: string }, id: string) {
    const rfq = await this.prisma.rfq.findFirst({
      where: { id, deletedAt: null },
      include: {
        items: { include: { product: true } },
        quotes: { orderBy: { createdAt: 'desc' } },
        documents: { include: { document: true } },
      },
    });
    if (!rfq) throw new NotFoundException({ code: 'NOT_FOUND', message: 'RFQ not found.' });
    this.assertCanSee(caller, rfq.buyerId);
    return rfq;
  }

  /** Move the RFQ through the lifecycle. Staff/admin only; buyers may only
   *  close (cancel) their own RFQ from early states. */
  async transition(
    caller: { sub: string; role: string },
    id: string,
    to: RfqStatus,
    meta: { ip?: string; userAgent?: string },
  ) {
    const rfq = await this.prisma.rfq.findFirst({ where: { id, deletedAt: null } });
    if (!rfq) throw new NotFoundException({ code: 'NOT_FOUND', message: 'RFQ not found.' });

    const isStaff = caller.role === 'staff' || caller.role === 'admin';
    const owns = rfq.buyerId === caller.sub;
    if (isStaff) {
      // Staff transitions additionally require the rfq.transition permission.
      const holder = await this.prisma.user.findFirst({
        where: { id: caller.sub },
        include: { role: { include: { permissions: { include: { permission: true } } } } },
      });
      const granted = new Set(holder?.role.permissions.map((p) => p.permission.key) ?? []);
      if (!granted.has('rfq.transition')) {
        throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
      }
    } else if (!(owns && to === 'closed' && ['submitted', 'under_review'].includes(rfq.status))) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }

    if (!canTransitionRfq(rfq.status, to)) {
      throw new UnprocessableEntityException({
        code: 'INVALID_TRANSITION',
        message: `An RFQ in "${rfq.status}" cannot move to "${to}".`,
        details: { from: rfq.status, to },
      });
    }

    const updated = await this.prisma.rfq.update({
      where: { id },
      data: { status: to, statusChangedAt: new Date(), updatedBy: caller.sub },
    });

    await this.audit.log(AuditAction.rfq_status_changed, {
      actorId: caller.sub, ipAddress: meta.ip, userAgent: meta.userAgent,
      entityType: 'rfq', entityId: id, metadata: { from: rfq.status, to },
    });
    await this.notifications.emit('rfq_status_changed', rfq.buyerId, {
      title: `RFQ ${rfq.rfqNumber} — ${to.replace(/_/g, ' ')}`,
      body: `Your requirement moved to "${to.replace(/_/g, ' ')}".`,
      data: { rfqId: id, from: rfq.status, to },
    });
    return updated;
  }

  assertCanSee(caller: { sub: string; role: string }, buyerId: string) {
    const isStaff = caller.role === 'staff' || caller.role === 'admin';
    if (!isStaff && buyerId !== caller.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
  }
}
