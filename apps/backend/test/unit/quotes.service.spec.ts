import { Test } from '@nestjs/testing';
import { ConflictException, ForbiddenException, UnprocessableEntityException } from '@nestjs/common';
import { QuoteStatus, RfqStatus } from '@prisma/client';
import { QuotesService } from '../../src/modules/quotes/quotes.service';
import { PrismaService } from '../../src/prisma/prisma.service';
import { AuditService } from '../../src/modules/audit/audit.module';
import { NotificationsService } from '../../src/modules/notifications/notifications.service';

describe('QuotesService.accept business rules', () => {
  let service: QuotesService;
  let prisma: Record<string, any>;
  let tx: Record<string, any>;
  const audit = { log: jest.fn() };
  const notifications = { emit: jest.fn() };

  const quote = (over: Record<string, unknown> = {}) => ({
    id: 'quote-1',
    rfqId: 'rfq-1',
    status: QuoteStatus.sent,
    currency: 'USD',
    total: 1000,
    validUntil: new Date(Date.now() + 7 * 86400000),
    items: [
      { productId: null, description: 'Item', quantity: 10, unit: 'units', unitPrice: 100, lineTotal: 1000 },
    ],
    rfq: { id: 'rfq-1', buyerId: 'buyer-A', companyId: null, status: RfqStatus.quotation_ready, rfqNumber: 'EGT-RFQ-2026-000001' },
    ...over,
  });

  beforeEach(async () => {
    tx = {
      quote: { findUniqueOrThrow: jest.fn(), update: jest.fn() },
      rfq: { update: jest.fn() },
      order: { create: jest.fn() },
      $queryRaw: jest.fn().mockResolvedValue([{ n: 7 }]),
    };
    prisma = {
      quote: { findFirst: jest.fn() },
      $transaction: jest.fn((arg: unknown) => (typeof arg === 'function' ? (arg as (t: unknown) => unknown)(tx) : Promise.resolve([]))),
    };
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        QuotesService,
        { provide: PrismaService, useValue: prisma },
        { provide: AuditService, useValue: audit },
        { provide: NotificationsService, useValue: notifications },
      ],
    }).compile();
    service = module.get(QuotesService);
  });

  it('403s when the caller does not own the RFQ', async () => {
    prisma.quote.findFirst.mockResolvedValue(quote());
    await expect(service.accept({ sub: 'buyer-B' }, 'quote-1', {})).rejects.toThrow(ForbiddenException);
  });

  it('422s when the quote is expired', async () => {
    prisma.quote.findFirst.mockResolvedValue(quote({ validUntil: new Date(Date.now() - 1000) }));
    await expect(service.accept({ sub: 'buyer-A' }, 'quote-1', {})).rejects.toThrow(UnprocessableEntityException);
  });

  it('409s on double accept', async () => {
    prisma.quote.findFirst.mockResolvedValue(quote({ status: QuoteStatus.accepted }));
    await expect(service.accept({ sub: 'buyer-A' }, 'quote-1', {})).rejects.toThrow(ConflictException);
  });

  it('422s when the quote is not in sent state', async () => {
    prisma.quote.findFirst.mockResolvedValue(quote({ status: QuoteStatus.draft }));
    await expect(service.accept({ sub: 'buyer-A' }, 'quote-1', {})).rejects.toThrow(UnprocessableEntityException);
  });

  it('422s when the RFQ is not in a quotable state', async () => {
    prisma.quote.findFirst.mockResolvedValue(
      quote({ rfq: { id: 'rfq-1', buyerId: 'buyer-A', status: RfqStatus.sourcing, rfqNumber: 'EGT-RFQ-2026-000001' } }),
    );
    await expect(service.accept({ sub: 'buyer-A' }, 'quote-1', {})).rejects.toThrow(UnprocessableEntityException);
  });

  it('accepts a valid quote: marks accepted, creates order, moves RFQ to approved', async () => {
    prisma.quote.findFirst.mockResolvedValue(quote());
    tx.quote.findUniqueOrThrow.mockResolvedValue(quote());
    tx.quote.update.mockResolvedValue(quote({ status: QuoteStatus.accepted }));
    tx.order.create.mockResolvedValue({ id: 'order-1', orderNumber: 'EGT-ORD-2026-000007' });
    tx.rfq.update.mockResolvedValue({});

    const res = await service.accept({ sub: 'buyer-A' }, 'quote-1', {});
    expect(tx.quote.update).toHaveBeenCalledWith({
      where: { id: 'quote-1' },
      data: expect.objectContaining({ status: QuoteStatus.accepted, acceptedBy: 'buyer-A' }),
    });
    expect(tx.order.create).toHaveBeenCalled();
    expect(tx.rfq.update).toHaveBeenCalledWith({
      where: { id: 'rfq-1' },
      data: expect.objectContaining({ status: RfqStatus.approved }),
    });
    expect(res.order.orderNumber).toBe('EGT-ORD-2026-000007');
    expect(audit.log).toHaveBeenCalledWith('quote_accepted', expect.anything());
  });

  it('rejects a concurrent state change inside the transaction (409)', async () => {
    prisma.quote.findFirst.mockResolvedValue(quote());
    tx.quote.findUniqueOrThrow.mockResolvedValue(quote({ status: QuoteStatus.accepted }));
    await expect(service.accept({ sub: 'buyer-A' }, 'quote-1', {})).rejects.toThrow(ConflictException);
  });
});
