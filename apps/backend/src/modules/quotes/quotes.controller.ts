import { Body, Controller, Get, Param, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Request } from 'express';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/auth.decorators';
import { CreateQuoteDto, RejectQuoteDto } from './dto/quote.dto';
import { QuotesService } from './quotes.service';

@ApiTags('quotes')
@ApiBearerAuth()
@Controller('quotes')
export class QuotesController {
  constructor(private quotes: QuotesService) {}

  @Post()
  @RequirePermissions('quote.create')
  @ApiOperation({ summary: 'Create a quote against an RFQ (staff/admin)' })
  create(@CurrentUser() user: RequestUser, @Body() dto: CreateQuoteDto, @Req() req: Request) {
    return this.quotes.create({ sub: user.sub }, dto, { ip: req.ip, userAgent: req.headers['user-agent'] });
  }

  @Post(':id/send')
  @RequirePermissions('quote.create')
  @ApiOperation({ summary: 'Send a draft quote to the buyer (staff/admin)' })
  send(@CurrentUser() user: RequestUser, @Param('id') id: string, @Req() req: Request) {
    return this.quotes.send({ sub: user.sub }, id, { ip: req.ip, userAgent: req.headers['user-agent'] });
  }

  @Post(':id/accept')
  @RequirePermissions('quote.accept')
  @ApiOperation({ summary: 'Accept a live quote (buyer, owns the RFQ; creates an order)' })
  accept(@CurrentUser() user: RequestUser, @Param('id') id: string, @Req() req: Request) {
    return this.quotes.accept({ sub: user.sub }, id, { ip: req.ip, userAgent: req.headers['user-agent'] });
  }

  @Post(':id/reject')
  @ApiOperation({ summary: 'Reject a live quote (buyer, owns the RFQ)' })
  reject(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: RejectQuoteDto, @Req() req: Request) {
    return this.quotes.reject({ sub: user.sub }, id, dto.reason, { ip: req.ip, userAgent: req.headers['user-agent'] });
  }

  @Post(':id/request-revision')
  @ApiOperation({ summary: 'Send a live quote back to staff for revision (buyer)' })
  requestRevision(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: RejectQuoteDto, @Req() req: Request) {
    return this.quotes.requestRevision({ sub: user.sub }, id, dto.reason, { ip: req.ip, userAgent: req.headers['user-agent'] });
  }

  @Get()
  @ApiOperation({ summary: 'List quotes (own for buyers; all for staff/admin)' })
  list(@CurrentUser() user: RequestUser, @Query() query: { page?: string; limit?: string }) {
    return this.quotes.list({ sub: user.sub, role: user.role }, query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Quote detail' })
  getOne(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    return this.quotes.getOne({ sub: user.sub, role: user.role }, id);
  }
}
