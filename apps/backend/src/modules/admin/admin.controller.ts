import {
  Body, Controller, ForbiddenException, Get, NotFoundException, Param, Patch, Query, Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsIn } from 'class-validator';
import { Request } from 'express';
import { AuditAction, Prisma, RoleName } from '@prisma/client';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/auth.decorators';
import { paginated, parsePagination } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.module';

class ChangeRoleDto {
  @ApiProperty({ enum: ['buyer', 'supplier', 'staff', 'admin'] })
  @IsIn(['buyer', 'supplier', 'staff', 'admin'])
  role!: RoleName;
}

@ApiTags('admin')
@ApiBearerAuth()
@Roles('admin')
@Controller('admin')
export class AdminController {
  constructor(private prisma: PrismaService, private audit: AuditService) {}

  @Get('overview')
  @ApiOperation({ summary: 'Dashboard counters' })
  async overview() {
    const [users, rfqs, quotes, orders, shipments, tickets, pendingListings] = await this.prisma.$transaction([
      this.prisma.user.count({ where: { deletedAt: null } }),
      this.prisma.rfq.count({ where: { deletedAt: null } }),
      this.prisma.quote.count({ where: { deletedAt: null } }),
      this.prisma.order.count({ where: { deletedAt: null } }),
      this.prisma.shipment.count({ where: { deletedAt: null } }),
      this.prisma.supportTicket.count({ where: { deletedAt: null, status: { in: ['open', 'in_progress'] } } }),
      this.prisma.supplierProduct.count({ where: { status: 'pending_review', deletedAt: null } }),
    ]);
    return { users, rfqs, quotes, orders, shipments, openTickets: tickets, pendingListings };
  }

  @Get('users')
  @ApiOperation({ summary: 'List users (paginated)' })
  async users(@Query() query: { page?: string; limit?: string; role?: string; search?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const where: Prisma.UserWhereInput = { deletedAt: null };
    if (query.role) where.role = { name: query.role as RoleName };
    if (query.search) {
      where.OR = [
        { email: { contains: query.search, mode: 'insensitive' } },
        { fullName: { contains: query.search, mode: 'insensitive' } },
      ];
    }
    const [items, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where, skip, take, orderBy: { createdAt: 'desc' },
        select: { id: true, email: true, fullName: true, phone: true, isActive: true, emailVerifiedAt: true, createdAt: true, role: { select: { name: true } } },
      }),
      this.prisma.user.count({ where }),
    ]);
    return paginated(items.map((u) => ({ ...u, role: u.role.name })), total, page, limit);
  }

  @Patch('users/:id/role')
  @ApiOperation({ summary: 'Change a user role (audited; cannot demote yourself)' })
  async changeRole(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Body() dto: ChangeRoleDto,
    @Req() req: Request,
  ) {
    if (id === user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You cannot change your own role.' });
    }
    const target = await this.prisma.user.findFirst({ where: { id, deletedAt: null }, include: { role: true } });
    if (!target) throw new NotFoundException({ code: 'NOT_FOUND', message: 'User not found.' });
    const role = await this.prisma.role.findUniqueOrThrow({ where: { name: dto.role } });
    const updated = await this.prisma.user.update({
      where: { id },
      data: { roleId: role.id, updatedBy: user.sub },
      select: { id: true, email: true, role: { select: { name: true } } },
    });
    await this.audit.log(AuditAction.role_changed, {
      actorId: user.sub, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      entityType: 'user', entityId: id, metadata: { from: target.role.name, to: dto.role },
    });
    return { ...updated, role: updated.role.name };
  }

  @Patch('users/:id/active')
  @ApiOperation({ summary: 'Activate/deactivate a user (audited)' })
  async setActive(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Body() dto: { active: boolean },
    @Req() req: Request,
  ) {
    if (id === user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You cannot deactivate yourself.' });
    }
    const updated = await this.prisma.user.update({
      where: { id }, data: { isActive: dto.active, updatedBy: user.sub },
      select: { id: true, email: true, isActive: true },
    });
    await this.audit.log(AuditAction.admin_action, {
      actorId: user.sub, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      entityType: 'user', entityId: id, metadata: { action: 'set_active', active: dto.active },
    });
    return updated;
  }

  @Get('audit-log')
  @ApiOperation({ summary: 'Read the audit log (paginated, filterable)' })
  async auditLog(@Query() query: { page?: string; limit?: string; action?: string; actorId?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const where: Prisma.AuditLogWhereInput = {};
    if (query.action) where.action = query.action as AuditAction;
    if (query.actorId) where.actorId = query.actorId;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.auditLog.findMany({
        where, skip, take, orderBy: { createdAt: 'desc' },
        include: { actor: { select: { id: true, email: true, fullName: true } } },
      }),
      this.prisma.auditLog.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }

  @Get('rfqs')
  @ApiOperation({ summary: 'All RFQs for staff review' })
  async rfqs(@Query() query: { page?: string; limit?: string; status?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const where: Prisma.RfqWhereInput = { deletedAt: null };
    if (query.status) where.status = query.status as Prisma.EnumRfqStatusFilter['equals'];
    const [items, total] = await this.prisma.$transaction([
      this.prisma.rfq.findMany({ where, skip, take, orderBy: { createdAt: 'desc' }, include: { items: true } }),
      this.prisma.rfq.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }
}
