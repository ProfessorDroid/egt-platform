import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { ShipmentsController } from './shipments.controller';

@Module({ imports: [NotificationsModule], controllers: [ShipmentsController] })
export class ShipmentsModule {}
