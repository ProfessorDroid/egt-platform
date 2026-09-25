import {
  Body, Controller, ForbiddenException, Get, NotFoundException, Param, Patch, Post, Query, Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { Request } from 'express';
import { TicketPriority, TicketStatus } from '@prisma/client';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { nextYearlyNumber } from '../../common/utils/sequences.util';
import { paginated, parsePagination, sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

class CreateTicketDto {
  @ApiProperty() @IsString() @MaxLength(160) subject!: string;
  @ApiProperty() @IsString() @MaxLength(4000) body!: string;
  @ApiPropertyOptional({ enum: ['low', 'medium', 'high', 'urgent'], default: 'medium' })
  @IsOptional() @IsIn(['low', 'medium', 'high', 'urgent']) priority?: TicketPriority;
}

class UpdateTicketDto {
  @ApiPropertyOptional({ enum: ['open', 'in_progress', 'waiting_on_customer', 'resolved', 'closed'] })
  @IsOptional() @IsIn(['open', 'in_progress', 'waiting_on_customer', 'resolved', 'closed']) status?: TicketStatus;
  @ApiPropertyOptional({ enum: ['low', 'medium', 'high', 'urgent'] })
  @IsOptional() @IsIn(['low', 'medium', 'high', 'urgent']) priority?: TicketPriority;
  @ApiPropertyOptional() @IsOptional() @IsUUID() assigneeId?: string;
}

class ReplyTicketDto {
  @ApiProperty() @IsString() @MaxLength(4000) body!: string;
}

@ApiTags('support')
@ApiBearerAuth()
@Controller('support/tickets')
export class SupportController {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Open a support ticket' })
  async create(@CurrentUser() user: RequestUser, @Body() dto: CreateTicketDto) {
    const ticket = await this.prisma.$transaction(async (tx) => {
      const ticketNumber = await nextYearlyNumber(tx, 'TicketSequence', 'EGT-TCK');
      const t = await tx.supportTicket.create({
        data: {
          ticketNumber,
          requesterId: user.sub,
          subject: sanitizeText(dto.subject),
          priority: dto.priority ?? TicketPriority.medium,
          createdBy: user.sub,
        },
      });
      const conv = await tx.conversation.create({
        data: { kind: 'support_ticket', ticketId: t.id, subject: sanitizeText(dto.subject) },
      });
      await tx.conversationParticipant.create({ data: { conversationId: conv.id, userId: user.sub } });
      await tx.message.create({ data: { conversationId: conv.id, senderId: user.sub, body: sanitizeText(dto.body) } });
      return t;
    });
    return ticket;
  }

  @Get()
  @ApiOperation({ summary: 'List tickets (own for users; all for staff/admin)' })
  async list(@CurrentUser() user: RequestUser, @Query() query: { page?: string; limit?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const isStaff = user.role === 'staff' || user.role === 'admin';
    const where = isStaff ? { deletedAt: null } : { deletedAt: null, requesterId: user.sub };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.supportTicket.findMany({ where, skip, take, orderBy: { createdAt: 'desc' } }),
      this.prisma.supportTicket.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Ticket detail with its conversation' })
  async getOne(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    const ticket = await this.prisma.supportTicket.findFirst({
      where: { id, deletedAt: null },
      include: { conversations: { include: { messages: { orderBy: { createdAt: 'asc' }, include: { sender: { select: { id: true, fullName: true } } } } } } },
    });
    if (!ticket) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Ticket not found.' });
    const isStaff = user.role === 'staff' || user.role === 'admin';
    if (!isStaff && ticket.requesterId !== user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    return ticket;
  }

  @Post(':id/reply')
  @ApiOperation({ summary: 'Reply on the ticket conversation' })
  async reply(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: ReplyTicketDto) {
    const ticket = await this.prisma.supportTicket.findFirst({
      where: { id, deletedAt: null },
      include: { conversations: true },
    });
    if (!ticket) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Ticket not found.' });
    const isStaff = user.role === 'staff' || user.role === 'admin';
    if (!isStaff && ticket.requesterId !== user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    const conv = ticket.conversations[0];
    if (!conv) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Ticket conversation missing.' });
    await this.prisma.conversationParticipant.upsert({
      where: { conversationId_userId: { conversationId: conv.id, userId: user.sub } },
      update: {},
      create: { conversationId: conv.id, userId: user.sub },
    });
    const message = await this.prisma.message.create({
      data: { conversationId: conv.id, senderId: user.sub, body: sanitizeText(dto.body) },
    });
    // Notify the other side.
    const otherId = isStaff ? ticket.requesterId : ticket.assigneeId;
    if (otherId && otherId !== user.sub) {
      await this.notifications.emit('ticket_reply', otherId, {
        title: `Ticket ${ticket.ticketNumber} — new reply`,
        body: sanitizeText(dto.body).slice(0, 120),
        data: { ticketId: id },
      });
    }
    return message;
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update ticket status/priority/assignee (staff/admin)' })
  async update(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: UpdateTicketDto, @Req() req: Request) {
    if (user.role !== 'staff' && user.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    const ticket = await this.prisma.supportTicket.update({
      where: { id },
      data: { ...dto, updatedBy: user.sub },
    });
    return ticket;
  }
}
