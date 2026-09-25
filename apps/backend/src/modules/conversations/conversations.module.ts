import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { ConversationsController } from './conversations.controller';

@Module({ imports: [NotificationsModule], controllers: [ConversationsController] })
export class ConversationsModule {}
