import { NotificationEventType } from '@prisma/client';

export interface PushPayload {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, unknown>;
  deviceTokens: string[];
}

/** Push provider interface. No FCM credentials are needed for development —
 *  the LogPushProvider records what WOULD be sent. Swap in an FCM/APNs
 *  provider via env config when keys are available (needs-from-Sukh). */
export interface PushProvider {
  name: string;
  send(payload: PushPayload): Promise<void>;
}

export class LogPushProvider implements PushProvider {
  name = 'log';
  async send(payload: PushPayload): Promise<void> {
    // eslint-disable-next-line no-console
    console.log(`[push:${this.name}] user=${payload.userId} tokens=${payload.deviceTokens.length} title=${payload.title}`);
  }
}
