import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { DocumentsController } from './documents.controller';

@Module({ imports: [NotificationsModule], controllers: [DocumentsController] })
export class DocumentsModule {}
