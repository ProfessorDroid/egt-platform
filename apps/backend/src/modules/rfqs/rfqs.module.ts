import { Module } from '@nestjs/common';
import { NotificationsModule } from '../notifications/notifications.module';
import { PrivateLabelController } from './private-label.controller';
import { RfqsController } from './rfqs.controller';
import { RfqsService } from './rfqs.service';

@Module({
  imports: [NotificationsModule],
  controllers: [RfqsController, PrivateLabelController],
  providers: [RfqsService],
  exports: [RfqsService],
})
export class RfqsModule {}
