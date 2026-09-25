import { Injectable } from '@nestjs/common';
import { NotificationEventType, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { LogPushProvider, PushProvider } from './push.provider';

export interface EmitOptions {
  title: string;
  body: string;
  data?: Record<string, unknown>;
}

/**
 * Notification fan-out: persists a Notification row, honours the recipient's
 * per-event-type preference, and hands off to the push provider.
 * Triggered on: rfq.status_changed, quote.available, quote.revision_requested,
 * order.status_changed, shipment.update, document.uploaded, security.alert,
 * ticket.reply, message.received.
 */
@Injectable()
export class NotificationsService {
  private provider: PushProvider = new LogPushProvider();

  constructor(private prisma: PrismaService) {}

  setProvider(provider: PushProvider) {
    this.provider = provider;
  }

  async emit(eventType: NotificationEventType, userId: string, opts: EmitOptions): Promise<void> {
    const pref = await this.prisma.notificationPreference.findUnique({
      where: { userId_eventType: { userId, eventType } },
    });
    const enabled = pref ? pref.enabled : true; // default on for all types
    if (!enabled) return;

    await this.prisma.notification.create({
      data: {
        userId,
        eventType,
        title: opts.title,
        body: opts.body,
        data: (opts.data ?? Prisma.JsonNull) as Prisma.InputJsonValue,
      },
    });

    const tokens = await this.prisma.deviceToken.findMany({
      where: { userId, isActive: true },
      select: { token: true },
    });
    if (tokens.length) {
      try {
        await this.provider.send({
          userId,
          title: opts.title,
          body: opts.body,
          data: opts.data,
          deviceTokens: tokens.map((t) => t.token),
        });
      } catch (err) {
        // Push failure must not break the request; the DB notification persists.
        // eslint-disable-next-line no-console
        console.error('[notifications] push provider failed', err);
      }
    }
  }

  async preferences(userId: string) {
    const existing = await this.prisma.notificationPreference.findMany({ where: { userId } });
    const byType = new Map(existing.map((p) => [p.eventType, p.enabled]));
    return Object.values(NotificationEventType).map((eventType) => ({
      eventType,
      enabled: byType.get(eventType) ?? true,
    }));
  }

  async setPreference(userId: string, eventType: NotificationEventType, enabled: boolean) {
    return this.prisma.notificationPreference.upsert({
      where: { userId_eventType: { userId, eventType } },
      update: { enabled },
      create: { userId, eventType, enabled },
    });
  }
}
