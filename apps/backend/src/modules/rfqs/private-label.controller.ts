import {
  Body, Controller, ForbiddenException, Get, NotFoundException, Param, Post, UnprocessableEntityException,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { PrivateLabelStatus } from '@prisma/client';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/auth.decorators';
import { sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';

const PL_FLOW: Record<PrivateLabelStatus, PrivateLabelStatus[]> = {
  submitted: ['design_review'],
  design_review: ['sample'],
  sample: ['approval'],
  approval: ['production'],
  production: ['completed'],
  completed: [],
};

class CreatePrivateLabelDto {
  @ApiProperty() @IsUUID() rfqId!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(160) brandName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(2000) designNotes?: string;
}

class TransitionPlDto {
  @ApiProperty({ enum: ['design_review', 'sample', 'approval', 'production', 'completed'] })
  @IsIn(['design_review', 'sample', 'approval', 'production', 'completed'])
  to!: PrivateLabelStatus;
}

@ApiTags('private-label')
@ApiBearerAuth()
@Controller('private-label')
export class PrivateLabelController {
  constructor(private prisma: PrismaService) {}

  @Post()
  @ApiOperation({ summary: 'Start a private-label/OEM request linked to my RFQ' })
  async create(@CurrentUser() user: RequestUser, @Body() dto: CreatePrivateLabelDto) {
    const rfq = await this.prisma.rfq.findFirst({ where: { id: dto.rfqId, deletedAt: null } });
    if (!rfq) throw new NotFoundException({ code: 'NOT_FOUND', message: 'RFQ not found.' });
    const isStaff = user.role === 'staff' || user.role === 'admin';
    if (!isStaff && rfq.buyerId !== user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    const existing = await this.prisma.privateLabelRequest.findUnique({ where: { rfqId: dto.rfqId } });
    if (existing) return existing;
    return this.prisma.privateLabelRequest.create({
      data: {
        rfqId: dto.rfqId,
        requesterId: user.sub,
        brandName: dto.brandName ? sanitizeText(dto.brandName) : undefined,
        designNotes: dto.designNotes ? sanitizeText(dto.designNotes) : undefined,
        createdBy: user.sub,
      },
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Private-label request detail' })
  async getOne(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    const pl = await this.prisma.privateLabelRequest.findFirst({
      where: { id, deletedAt: null }, include: { rfq: { select: { buyerId: true, rfqNumber: true } } },
    });
    if (!pl) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Request not found.' });
    const isStaff = user.role === 'staff' || user.role === 'admin';
    if (!isStaff && pl.rfq.buyerId !== user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    return pl;
  }

  @Post(':id/transition')
  @Roles('staff', 'admin')
  @ApiOperation({ summary: 'Move private-label request forward (strict flow, staff/admin)' })
  async transition(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: TransitionPlDto) {
    const pl = await this.prisma.privateLabelRequest.findFirst({ where: { id, deletedAt: null } });
    if (!pl) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Request not found.' });
    if (!PL_FLOW[pl.status].includes(dto.to)) {
      throw new UnprocessableEntityException({
        code: 'INVALID_TRANSITION',
        message: `A request in "${pl.status}" cannot move to "${dto.to}".`,
      });
    }
    return this.prisma.privateLabelRequest.update({
      where: { id }, data: { status: dto.to, statusChangedAt: new Date(), updatedBy: user.sub },
    });
  }
}
