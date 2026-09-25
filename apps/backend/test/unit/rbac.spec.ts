import { Test } from '@nestjs/testing';
import { ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { JwtAuthGuard } from '../../src/common/guards/jwt-auth.guard';
import { RolesGuard } from '../../src/common/guards/roles.guard';
import { RfqsService } from '../../src/modules/rfqs/rfqs.service';
import { SuppliersController } from '../../src/modules/suppliers/suppliers.controller';
import { PrismaService } from '../../src/prisma/prisma.service';
import { AuditService } from '../../src/modules/audit/audit.module';
import { NotificationsService } from '../../src/modules/notifications/notifications.service';
import { ExecutionContext } from '@nestjs/common';

function httpContext(headers: Record<string, string> = {}): ExecutionContext {
  const req: Record<string, unknown> = { headers };
  return {
    getHandler: () => jest.fn(),
    getClass: () => jest.fn(),
    switchToHttp: () => ({ getRequest: () => req }),
  } as unknown as ExecutionContext;
}

describe('RBAC negative tests (server-side enforcement)', () => {
  // ------------------------------------------------------------- JwtAuthGuard
  describe('JwtAuthGuard', () => {
    it('401s guests with no token', async () => {
      const reflector = { getAllAndOverride: jest.fn().mockReturnValue(false) };
      const module = await Test.createTestingModule({
        providers: [
          JwtAuthGuard,
          { provide: Reflector, useValue: reflector },
          { provide: JwtService, useValue: { verifyAsync: jest.fn() } },
        ],
      }).compile();
      const guard = module.get(JwtAuthGuard);
      await expect(guard.canActivate(httpContext())).rejects.toThrow(UnauthorizedException);
    });

    it('lets @Public() routes through without a token', async () => {
      const reflector = { getAllAndOverride: jest.fn().mockReturnValue(true) };
      const module = await Test.createTestingModule({
        providers: [
          JwtAuthGuard,
          { provide: Reflector, useValue: reflector },
          { provide: JwtService, useValue: { verifyAsync: jest.fn() } },
        ],
      }).compile();
      const guard = module.get(JwtAuthGuard);
      await expect(guard.canActivate(httpContext())).resolves.toBe(true);
    });
  });

  // --------------------------------------------------------------- RolesGuard
  describe('RolesGuard', () => {
    const dbUser = (roleName: string) => ({
      id: 'u1', role: { name: roleName, permissions: [{ permission: { key: 'admin.users.manage' } }] },
    });

    async function guardFor(user: { sub: string }, db: unknown, requiredRoles: string[]) {
      const reflector = {
        getAllAndOverride: jest.fn((key: string) =>
          key === 'roles' ? requiredRoles : undefined,
        ),
      };
      const prisma = { user: { findFirst: jest.fn().mockResolvedValue(db) } };
      const module = await Test.createTestingModule({
        providers: [
          RolesGuard,
          { provide: Reflector, useValue: reflector },
          { provide: PrismaService, useValue: prisma },
        ],
      }).compile();
      const guard = module.get(RolesGuard);
      const ctx = httpContext();
      (ctx.switchToHttp().getRequest() as Record<string, unknown>).user = user;
      return guard.canActivate(ctx);
    }

    it('403s a buyer hitting an admin-only route (role resolved from DB, not token)', async () => {
      // Even if the JWT claims admin, the DB says buyer → 403.
      await expect(
        guardFor({ sub: 'u1' }, dbUser('buyer'), ['admin']),
      ).rejects.toThrow(ForbiddenException);
    });

    it('allows an admin through', async () => {
      await expect(guardFor({ sub: 'u1' }, dbUser('admin'), ['admin'])).resolves.toBe(true);
    });
  });

  // ------------------------------------------------- buyer A / buyer B isolation
  describe('RFQ ownership isolation', () => {
    it("403s buyer B reading buyer A's RFQ", async () => {
      const prisma = {
        rfq: { findFirst: jest.fn().mockResolvedValue({ id: 'rfq-1', buyerId: 'buyer-A' }) },
      };
      const module = await Test.createTestingModule({
        providers: [
          RfqsService,
          { provide: PrismaService, useValue: prisma },
          { provide: AuditService, useValue: { log: jest.fn() } },
          { provide: NotificationsService, useValue: { emit: jest.fn() } },
        ],
      }).compile();
      const service = module.get(RfqsService);
      await expect(
        service.getOne({ sub: 'buyer-B', role: 'buyer' }, 'rfq-1'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('403s buyer B transitioning buyer A\'s RFQ', async () => {
      const prisma = {
        rfq: { findFirst: jest.fn().mockResolvedValue({ id: 'rfq-1', buyerId: 'buyer-A', status: 'submitted' }) },
      };
      const module = await Test.createTestingModule({
        providers: [
          RfqsService,
          { provide: PrismaService, useValue: prisma },
          { provide: AuditService, useValue: { log: jest.fn() } },
          { provide: NotificationsService, useValue: { emit: jest.fn() } },
        ],
      }).compile();
      const service = module.get(RfqsService);
      await expect(
        service.transition({ sub: 'buyer-B', role: 'buyer' }, 'rfq-1', 'closed' as never, {}),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // ------------------------------------------- supplier cannot approve own listing
  describe('supplier listing self-approval', () => {
    it('403s when the reviewer owns the supplier record', async () => {
      const prisma = {
        supplierProduct: {
          findFirst: jest.fn().mockResolvedValue({
            id: 'sp-1', status: 'pending_review',
            supplier: { ownerId: 'supplier-1' },
          }),
        },
      };
      const controller = new SuppliersController(prisma as never, { log: jest.fn() } as never);
      await expect(
        controller.review(
          { sub: 'supplier-1', email: 's@x.com', role: 'staff', sessionId: 'sess' },
          'sp-1',
          { status: 'approved' },
          { ip: '1.2.3.4', headers: {} } as never,
        ),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
