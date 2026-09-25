import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { SupportController } from './support.controller';

@Module({ imports: [NotificationsModule], controllers: [SupportController] })
export class SupportModule {}
