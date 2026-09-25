import { BadRequestException, Body, Controller, Delete, Get, NotFoundException, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { paginated, parsePagination } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { NotificationsService } from './notifications.service';
import { NotificationEventType } from '@prisma/client';

class RegisterTokenDto {
  @ApiProperty() @IsString() @IsNotEmpty() @MaxLength(512) token!: string;
  @ApiProperty({ enum: ['android', 'ios', 'web'] }) @IsIn(['android', 'ios', 'web']) platform!: string;
}

class UpdatePreferenceDto {
  @ApiProperty() @IsBoolean() enabled!: boolean;
}

@ApiTags('notifications')
@ApiBearerAuth()
@Controller('notifications')
export class NotificationsController {
  constructor(private notifications: NotificationsService, private prisma: PrismaService) {}

  @Get()
  @ApiOperation({ summary: 'List my notifications (newest first)' })
  async list(@CurrentUser() user: RequestUser, @Query() query: { page?: string; limit?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const where = { userId: user.sub };
    const [items, total] = await this.prisma.$transaction([
      this.prisma.notification.findMany({ where, skip, take, orderBy: { createdAt: 'desc' } }),
      this.prisma.notification.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }

  @Get('unread-count')
  @ApiOperation({ summary: 'Unread notification count' })
  async unreadCount(@CurrentUser() user: RequestUser) {
    const count = await this.prisma.notification.count({ where: { userId: user.sub, readAt: null } });
    return { unread: count };
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark one notification as read (must belong to caller)' })
  async markRead(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    const updated = await this.prisma.notification.updateMany({
      where: { id, userId: user.sub },
      data: { readAt: new Date() },
    });
    if (!updated.count) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Notification not found.' });
    }
    return { ok: true };
  }

  @Post('device-tokens')
  @ApiOperation({ summary: 'Register a device push token (multi-device supported)' })
  async registerToken(@CurrentUser() user: RequestUser, @Body() dto: RegisterTokenDto) {
    await this.prisma.deviceToken.upsert({
      where: { token: dto.token },
      update: { userId: user.sub, platform: dto.platform, isActive: true, lastSeenAt: new Date() },
      create: { userId: user.sub, token: dto.token, platform: dto.platform },
    });
    return { ok: true };
  }

  @Delete('device-tokens')
  @ApiOperation({ summary: 'Remove this device push token' })
  async removeToken(@CurrentUser() user: RequestUser, @Body() dto: RegisterTokenDto) {
    await this.prisma.deviceToken.updateMany({
      where: { token: dto.token, userId: user.sub },
      data: { isActive: false },
    });
    return { ok: true };
  }

  @Get('preferences')
  @ApiOperation({ summary: 'My per-event-type notification preferences' })
  async preferences(@CurrentUser() user: RequestUser) {
    return this.notifications.preferences(user.sub);
  }

  @Patch('preferences/:eventType')
  @ApiOperation({ summary: 'Enable/disable one event type' })
  async updatePreference(
    @CurrentUser() user: RequestUser,
    @Param('eventType') eventType: string,
    @Body() dto: UpdatePreferenceDto,
  ) {
    const valid = Object.values(NotificationEventType).includes(eventType as NotificationEventType);
    if (!valid) {
      throw new BadRequestException({ code: 'BAD_REQUEST', message: 'Unknown event type.' });
    }
    return this.notifications.setPreference(user.sub, eventType as NotificationEventType, dto.enabled);
  }
}
