import { Global, Injectable, Module } from '@nestjs/common';
import { AuditAction, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';

export interface AuditContext {
  actorId?: string;
  ipAddress?: string;
  userAgent?: string;
  entityType?: string;
  entityId?: string;
  metadata?: Prisma.InputJsonValue;
}

/**
 * Append-only audit log for sensitive actions: login, role change, RFQ
 * create, quote accept, document access, admin actions.
 */
@Global()
@Injectable()
export class AuditService {
  constructor(private prisma: PrismaService) {}

  async log(action: AuditAction, ctx: AuditContext = {}): Promise<void> {
    try {
      await this.prisma.auditLog.create({
        data: {
          action,
          actorId: ctx.actorId ?? null,
          entityType: ctx.entityType,
          entityId: ctx.entityId,
          metadata: ctx.metadata ?? Prisma.JsonNull,
          ipAddress: ctx.ipAddress,
          userAgent: ctx.userAgent,
        },
      });
    } catch (err) {
      // Audit must never break the request path; surface loudly in logs.
      // eslint-disable-next-line no-console
      console.error('[audit] failed to write audit log', action, err);
    }
  }
}

@Global()
@Module({
  providers: [AuditService],
  exports: [AuditService],
})
export class AuditModule {}
