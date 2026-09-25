import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { OrdersController } from './orders.controller';

@Module({ imports: [NotificationsModule], controllers: [OrdersController] })
export class OrdersModule {}
