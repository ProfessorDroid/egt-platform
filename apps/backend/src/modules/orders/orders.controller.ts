import {
  Body, Controller, ForbiddenException, Get, NotFoundException, Param, Patch, Query, Req, UnprocessableEntityException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import { IsIn } from 'class-validator';
import { Request } from 'express';
import { AuditAction, OrderStatus, Prisma } from '@prisma/client';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { paginated, parsePagination } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.module';
import { NotificationsService } from '../notifications/notifications.service';

const ORDER_FLOW: Record<OrderStatus, OrderStatus[]> = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['in_production', 'cancelled'],
  in_production: ['ready_to_ship', 'cancelled'],
  ready_to_ship: ['shipped'],
  shipped: ['delivered'],
  delivered: [],
  cancelled: [],
};

class UpdateOrderStatusDto {
  @ApiProperty({ enum: ['confirmed', 'in_production', 'ready_to_ship', 'shipped', 'delivered', 'cancelled'] })
  @IsIn(['confirmed', 'in_production', 'ready_to_ship', 'shipped', 'delivered', 'cancelled'])
  status!: OrderStatus;
}

@ApiTags('orders')
@ApiBearerAuth()
@Controller('orders')
export class OrdersController {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private notifications: NotificationsService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'List orders (own for buyers; all for staff/admin)' })
  async list(@CurrentUser() user: RequestUser, @Query() query: { page?: string; limit?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const isStaff = user.role === 'staff' || user.role === 'admin';
    const where: Prisma.OrderWhereInput = { deletedAt: null };
    if (!isStaff) where.buyerId = user.sub;
    const [items, total] = await this.prisma.$transaction([
      this.prisma.order.findMany({
        where, skip, take, orderBy: { createdAt: 'desc' },
        include: { items: true, shipments: { select: { id: true, shipmentNumber: true, status: true } } },
      }),
      this.prisma.order.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Order detail with items and shipments' })
  async getOne(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    const order = await this.prisma.order.findFirst({
      where: { id, deletedAt: null },
      include: { items: true, shipments: { include: { events: { orderBy: { occurredAt: 'desc' } } } } },
    });
    if (!order) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Order not found.' });
    const isStaff = user.role === 'staff' || user.role === 'admin';
    if (!isStaff && order.buyerId !== user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    return order;
  }

  @Patch(':id/status')
  @ApiOperation({ summary: 'Update order status (staff/admin, strict forward flow)' })
  async updateStatus(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: UpdateOrderStatusDto, @Req() req: Request) {
    if (user.role !== 'staff' && user.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    const order = await this.prisma.order.findFirst({ where: { id, deletedAt: null } });
    if (!order) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Order not found.' });
    if (!ORDER_FLOW[order.status].includes(dto.status)) {
      throw new UnprocessableEntityException({
        code: 'INVALID_TRANSITION',
        message: `An order in "${order.status}" cannot move to "${dto.status}".`,
      });
    }
    const updated = await this.prisma.order.update({
      where: { id }, data: { status: dto.status, updatedBy: user.sub },
    });
    await this.audit.log(AuditAction.order_created, {
      actorId: user.sub, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      entityType: 'order', entityId: id, metadata: { from: order.status, to: dto.status },
    });
    await this.notifications.emit('order_status_changed', order.buyerId, {
      title: `Order ${order.orderNumber} — ${dto.status.replace(/_/g, ' ')}`,
      body: `Your order moved to "${dto.status.replace(/_/g, ' ')}".`,
      data: { orderId: id, status: dto.status },
    });
    // Keep the linked RFQ in step: a shipped/delivered order completes it.
    if (dto.status === 'delivered' && order.rfqId) {
      await this.prisma.rfq.update({
        where: { id: order.rfqId },
        data: { status: 'completed', statusChangedAt: new Date(), updatedBy: user.sub },
      });
    }
    return updated;
  }
}
