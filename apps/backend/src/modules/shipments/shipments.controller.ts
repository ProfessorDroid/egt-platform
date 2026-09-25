import {
  Body, Controller, ForbiddenException, Get, NotFoundException, Param, Patch, Post, Query, Req, UnprocessableEntityException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { Request } from 'express';
import { AuditAction, ShipmentStatus } from '@prisma/client';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { nextYearlyNumber } from '../../common/utils/sequences.util';
import { paginated, parsePagination, sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.module';
import { NotificationsService } from '../notifications/notifications.service';

const SHIPMENT_FLOW: Record<ShipmentStatus, ShipmentStatus[]> = {
  booked: ['picked_up', 'exception'],
  picked_up: ['in_transit', 'exception'],
  in_transit: ['customs', 'out_for_delivery', 'exception'],
  customs: ['in_transit', 'exception'],
  out_for_delivery: ['delivered', 'exception'],
  delivered: [],
  exception: ['in_transit', 'out_for_delivery'],
};

class CreateShipmentDto {
  @ApiProperty() @IsUUID() orderId!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(120) carrier?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(120) trackingRef?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(120) originPort?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(120) destinationPort?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() estimatedDelivery?: string;
}

class AddEventDto {
  @ApiProperty({ enum: ['picked_up', 'in_transit', 'customs', 'out_for_delivery', 'delivered', 'exception'] })
  @IsIn(['picked_up', 'in_transit', 'customs', 'out_for_delivery', 'delivered', 'exception'])
  status!: ShipmentStatus;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(160) location?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(1000) note?: string;
}

@ApiTags('shipments')
@ApiBearerAuth()
@Controller('shipments')
export class ShipmentsController {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private notifications: NotificationsService,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Create a shipment for an order (staff/admin)' })
  async create(@CurrentUser() user: RequestUser, @Body() dto: CreateShipmentDto, @Req() req: Request) {
    if (user.role !== 'staff' && user.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    const order = await this.prisma.order.findFirst({ where: { id: dto.orderId, deletedAt: null } });
    if (!order) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Order not found.' });

    const shipment = await this.prisma.$transaction(async (tx) => {
      const shipmentNumber = await nextYearlyNumber(tx, 'ShipmentSequence', 'EGT-SHP');
      const s = await tx.shipment.create({
        data: {
          shipmentNumber,
          orderId: dto.orderId,
          carrier: dto.carrier ? sanitizeText(dto.carrier) : undefined,
          trackingRef: dto.trackingRef ? sanitizeText(dto.trackingRef) : undefined,
          originPort: dto.originPort ? sanitizeText(dto.originPort) : undefined,
          destinationPort: dto.destinationPort ? sanitizeText(dto.destinationPort) : undefined,
          estimatedDelivery: dto.estimatedDelivery ? new Date(dto.estimatedDelivery) : undefined,
          events: { create: [{ status: ShipmentStatus.booked, note: 'Shipment booked', createdBy: user.sub }] },
          createdBy: user.sub,
        },
        include: { events: true },
      });
      if (order.status === 'ready_to_ship' || order.status === 'confirmed') {
        await tx.order.update({ where: { id: order.id }, data: { status: 'shipped', updatedBy: user.sub } });
      }
      return s;
    });

    await this.audit.log(AuditAction.shipment_created, {
      actorId: user.sub, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      entityType: 'shipment', entityId: shipment.id, metadata: { shipmentNumber: shipment.shipmentNumber },
    });
    return shipment;
  }

  @Get()
  @ApiOperation({ summary: 'List shipments (own orders for buyers; all for staff/admin)' })
  async list(@CurrentUser() user: RequestUser, @Query() query: { page?: string; limit?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const isStaff = user.role === 'staff' || user.role === 'admin';
    const where = isStaff ? { deletedAt: null } : { deletedAt: null, order: { buyerId: user.sub } };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.shipment.findMany({ where, skip, take, orderBy: { createdAt: 'desc' }, include: { order: { select: { orderNumber: true } } } }),
      this.prisma.shipment.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Shipment detail with event timeline' })
  async getOne(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    const shipment = await this.prisma.shipment.findFirst({
      where: { id, deletedAt: null },
      include: { events: { orderBy: { occurredAt: 'desc' } }, order: { select: { orderNumber: true, buyerId: true } } },
    });
    if (!shipment) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Shipment not found.' });
    const isStaff = user.role === 'staff' || user.role === 'admin';
    if (!isStaff && shipment.order.buyerId !== user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    return shipment;
  }

  @Post(':id/events')
  @ApiOperation({ summary: 'Append a tracking event (staff/admin); moves shipment status forward' })
  async addEvent(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: AddEventDto, @Req() req: Request) {
    if (user.role !== 'staff' && user.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    const shipment = await this.prisma.shipment.findFirst({
      where: { id, deletedAt: null }, include: { order: { select: { buyerId: true, orderNumber: true } } },
    });
    if (!shipment) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Shipment not found.' });
    if (!SHIPMENT_FLOW[shipment.status].includes(dto.status)) {
      throw new UnprocessableEntityException({
        code: 'INVALID_TRANSITION',
        message: `A shipment in "${shipment.status}" cannot move to "${dto.status}".`,
      });
    }
    const updated = await this.prisma.$transaction(async (tx) => {
      await tx.shipmentEvent.create({
        data: {
          shipmentId: id, status: dto.status,
          location: dto.location ? sanitizeText(dto.location) : undefined,
          note: dto.note ? sanitizeText(dto.note) : undefined,
          createdBy: user.sub,
        },
      });
      return tx.shipment.update({ where: { id }, data: { status: dto.status, updatedBy: user.sub }, include: { events: { orderBy: { occurredAt: 'desc' } } } });
    });
    await this.audit.log(AuditAction.shipment_status_changed, {
      actorId: user.sub, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      entityType: 'shipment', entityId: id, metadata: { from: shipment.status, to: dto.status },
    });
    await this.notifications.emit('shipment_update', shipment.order.buyerId, {
      title: `Shipment ${shipment.shipmentNumber} — ${dto.status.replace(/_/g, ' ')}`,
      body: dto.location ? `Now at ${dto.location}.` : `Status: ${dto.status.replace(/_/g, ' ')}.`,
      data: { shipmentId: id, status: dto.status },
    });
    if (dto.status === 'delivered') {
      await this.prisma.order.updateMany({ where: { id: shipment.orderId }, data: { status: 'delivered' } });
    }
    return updated;
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update shipment metadata (staff/admin)' })
  async update(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: Partial<CreateShipmentDto>) {
    if (user.role !== 'staff' && user.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    return this.prisma.shipment.update({
      where: { id },
      data: {
        carrier: dto.carrier ? sanitizeText(dto.carrier) : undefined,
        trackingRef: dto.trackingRef ? sanitizeText(dto.trackingRef) : undefined,
        destinationPort: dto.destinationPort ? sanitizeText(dto.destinationPort) : undefined,
        estimatedDelivery: dto.estimatedDelivery ? new Date(dto.estimatedDelivery) : undefined,
        updatedBy: user.sub,
      },
    });
  }
}
