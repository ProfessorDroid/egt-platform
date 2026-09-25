import {
  Body, Controller, ForbiddenException, Get, NotFoundException, Param, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { ConversationKind } from '@prisma/client';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { paginated, parsePagination, sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

class CreateConversationDto {
  @ApiProperty({ enum: ['rfq', 'order', 'shipment', 'support_ticket'] })
  @IsIn(['rfq', 'order', 'shipment', 'support_ticket'])
  kind!: ConversationKind;
  @ApiPropertyOptional() @IsOptional() @IsUUID() rfqId?: string;
  @ApiPropertyOptional() @IsOptional() @IsUUID() orderId?: string;
  @ApiPropertyOptional() @IsOptional() @IsUUID() shipmentId?: string;
  @ApiPropertyOptional() @IsOptional() @IsUUID() ticketId?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(160) subject?: string;
}

class SendMessageDto {
  @ApiProperty() @IsString() @MaxLength(4000) body!: string;
}

@ApiTags('conversations')
@ApiBearerAuth()
@Controller('conversations')
export class ConversationsController {
  constructor(private prisma: PrismaService, private notifications: NotificationsService) {}

  /** Start (or fetch the existing) conversation scoped to exactly one entity. */
  @Post()
  @ApiOperation({ summary: 'Open a conversation scoped to one RFQ/Order/Shipment/Ticket' })
  async open(@CurrentUser() user: RequestUser, @Body() dto: CreateConversationDto) {
    const ref = { rfqId: dto.rfqId, orderId: dto.orderId, shipmentId: dto.shipmentId, ticketId: dto.ticketId };
    const set = Object.entries(ref).filter(([, v]) => !!v);
    const expectedKey = dto.kind === 'support_ticket' ? 'ticketId' : `${dto.kind}Id`;
    if (set.length !== 1 || set[0][0] !== expectedKey) {
      throw new ForbiddenException({ code: 'BAD_REQUEST', message: 'A conversation must reference exactly one matching entity.' });
    }
    const entityId = set[0][1] as string;
    await this.assertEntityAccess(user, dto.kind, entityId);

    let conversation = await this.prisma.conversation.findFirst({
      where: { kind: dto.kind, rfqId: ref.rfqId ?? null, orderId: ref.orderId ?? null, shipmentId: ref.shipmentId ?? null, ticketId: ref.ticketId ?? null },
    });
    if (!conversation) {
      conversation = await this.prisma.conversation.create({
        data: { kind: dto.kind, ...ref, subject: dto.subject ? sanitizeText(dto.subject) : undefined },
      });
    }
    await this.prisma.conversationParticipant.upsert({
      where: { conversationId_userId: { conversationId: conversation.id, userId: user.sub } },
      update: {},
      create: { conversationId: conversation.id, userId: user.sub },
    });
    return conversation;
  }

  @Get()
  @ApiOperation({ summary: 'My conversations with unread counters' })
  async list(@CurrentUser() user: RequestUser, @Query() query: { page?: string; limit?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const participations = await this.prisma.conversationParticipant.findMany({
      where: { userId: user.sub },
      select: { conversationId: true, lastReadAt: true },
    });
    const ids = participations.map((p) => p.conversationId);
    const readMap = new Map(participations.map((p) => [p.conversationId, p.lastReadAt]));
    const [items, total] = await this.prisma.$transaction([
      this.prisma.conversation.findMany({
        where: { id: { in: ids } },
        skip, take, orderBy: { updatedAt: 'desc' },
        include: { messages: { orderBy: { createdAt: 'desc' }, take: 1 } },
      }),
      this.prisma.conversation.count({ where: { id: { in: ids } } }),
    ]);
    const withUnread = await Promise.all(items.map(async (c) => {
      const lastRead = readMap.get(c.id);
      const unread = await this.prisma.message.count({
        where: {
          conversationId: c.id,
          senderId: { not: user.sub },
          deletedAt: null,
          ...(lastRead ? { createdAt: { gt: lastRead } } : {}),
        },
      });
      return { ...c, unread };
    }));
    return paginated(withUnread, total, page, limit);
  }

  @Get(':id/messages')
  @ApiOperation({ summary: 'Messages in a conversation (membership checked)' })
  async messages(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Query() query: { page?: string; limit?: string },
  ) {
    await this.assertMembership(user.sub, id);
    const { page, limit, skip, take } = parsePagination(query);
    const [items, total] = await this.prisma.$transaction([
      this.prisma.message.findMany({
        where: { conversationId: id, deletedAt: null },
        skip, take, orderBy: { createdAt: 'asc' },
        include: { sender: { select: { id: true, fullName: true, role: { select: { name: true } } } } },
      }),
      this.prisma.message.count({ where: { conversationId: id, deletedAt: null } }),
    ]);
    await this.prisma.conversationParticipant.updateMany({
      where: { conversationId: id, userId: user.sub },
      data: { lastReadAt: new Date() },
    });
    return paginated(items, total, page, limit);
  }

  @Post(':id/messages')
  @ApiOperation({ summary: 'Send a message (members only)' })
  async send(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: SendMessageDto) {
    await this.assertMembership(user.sub, id);
    const message = await this.prisma.$transaction(async (tx) => {
      const m = await tx.message.create({
        data: { conversationId: id, senderId: user.sub, body: sanitizeText(dto.body) },
      });
      await tx.conversation.update({ where: { id }, data: { updatedAt: new Date() } });
      return m;
    });
    // Notify other participants.
    const others = await this.prisma.conversationParticipant.findMany({
      where: { conversationId: id, userId: { not: user.sub } },
      select: { userId: true },
    });
    for (const o of others) {
      await this.notifications.emit('message_received', o.userId, {
        title: 'New message',
        body: sanitizeText(dto.body).slice(0, 120),
        data: { conversationId: id, messageId: message.id },
      });
    }
    return message;
  }

  private async assertMembership(userId: string, conversationId: string) {
    const p = await this.prisma.conversationParticipant.findUnique({
      where: { conversationId_userId: { conversationId, userId } },
    });
    if (!p) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
  }

  /** Entity-level access: buyers see their own RFQs/orders/shipments/tickets; staff see all. */
  private async assertEntityAccess(user: RequestUser, kind: ConversationKind, entityId: string) {
    const isStaff = user.role === 'staff' || user.role === 'admin';
    if (isStaff) return;
    if (kind === 'rfq') {
      const r = await this.prisma.rfq.findFirst({ where: { id: entityId, deletedAt: null }, select: { buyerId: true } });
      if (!r || r.buyerId !== user.sub) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    } else if (kind === 'order') {
      const o = await this.prisma.order.findFirst({ where: { id: entityId, deletedAt: null }, select: { buyerId: true } });
      if (!o || o.buyerId !== user.sub) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    } else if (kind === 'shipment') {
      const s = await this.prisma.shipment.findFirst({ where: { id: entityId, deletedAt: null }, select: { order: { select: { buyerId: true } } } });
      if (!s || s.order.buyerId !== user.sub) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    } else {
      const t = await this.prisma.supportTicket.findFirst({ where: { id: entityId, deletedAt: null }, select: { requesterId: true } });
      if (!t || t.requesterId !== user.sub) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
  }
}
