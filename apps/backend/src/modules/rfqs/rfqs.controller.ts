import { Body, Controller, Get, Param, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/auth.decorators';
import { CreateRfqDto, TransitionRfqDto } from './dto/rfq.dto';
import { RfqsService } from './rfqs.service';
import { RfqStatus } from '@prisma/client';

@ApiTags('rfqs')
@ApiBearerAuth()
@Controller('rfqs')
export class RfqsController {
  constructor(private rfqs: RfqsService) {}

  @Post()
  @RequirePermissions('rfq.create')
  @ApiOperation({ summary: 'Submit a new RFQ (multi-item)' })
  create(@CurrentUser() user: RequestUser, @Body() dto: CreateRfqDto, @Req() req: Request) {
    return this.rfqs.create(user.sub, dto, { ip: req.ip, userAgent: req.headers['user-agent'] });
  }

  @Get()
  @ApiOperation({ summary: 'List RFQs (own for buyers; all for staff/admin)' })
  list(@CurrentUser() user: RequestUser, @Query() query: { page?: string; limit?: string; status?: string }) {
    return this.rfqs.list({ sub: user.sub, role: user.role }, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'RFQ detail with items, quotes and documents' })
  getOne(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    return this.rfqs.getOne({ sub: user.sub, role: user.role }, id);
  }

  @Post(':id/transition')
  @ApiOperation({ summary: 'Move RFQ through lifecycle (strict state machine; buyers may only cancel own RFQ)' })
  transition(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Body() dto: TransitionRfqDto,
    @Req() req: Request,
  ) {
    // RBAC detail lives in the service: staff/admin need rfq.transition and
    // may move any RFQ; buyers may only cancel (→ closed) their own RFQ from
    // early states. Nothing here trusts the client.
    return this.rfqs.transition({ sub: user.sub, role: user.role }, id, dto.to as RfqStatus, {
      ip: req.ip, userAgent: req.headers['user-agent'],
    });
  }
}
