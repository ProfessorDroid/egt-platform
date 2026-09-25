import {
  Body, Controller, Delete, ForbiddenException, Get, NotFoundException, Param, Patch, Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';

class CreateCompanyDto {
  @ApiProperty() @IsString() @MaxLength(160) name!: string;
  @ApiPropertyOptional({ enum: ['buyer', 'supplier', 'both'], default: 'buyer' })
  @IsOptional() @IsIn(['buyer', 'supplier', 'both']) type?: 'buyer' | 'supplier' | 'both';
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(80) country?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(80) city?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(160) website?: string;
}

class CreateAddressDto {
  @ApiPropertyOptional({ default: 'Head office' }) @IsOptional() @IsString() @MaxLength(80) label?: string;
  @ApiProperty() @IsString() @MaxLength(200) line1!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(200) line2?: string;
  @ApiProperty() @IsString() @MaxLength(80) city!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(80) state?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(24) postalCode?: string;
  @ApiProperty() @IsString() @MaxLength(80) country!: string;
  @ApiPropertyOptional({ default: false }) @IsOptional() @IsBoolean() isDefault?: boolean;
}

@ApiTags('companies')
@ApiBearerAuth()
@Controller('companies')
export class CompaniesController {
  constructor(private prisma: PrismaService) {}

  @Post()
  @ApiOperation({ summary: 'Create a company and attach it to my account' })
  async create(@CurrentUser() user: RequestUser, @Body() dto: CreateCompanyDto) {
    const company = await this.prisma.company.create({
      data: {
        name: sanitizeText(dto.name),
        type: dto.type ?? 'buyer',
        country: dto.country ? sanitizeText(dto.country) : undefined,
        city: dto.city ? sanitizeText(dto.city) : undefined,
        website: dto.website ? sanitizeText(dto.website) : undefined,
        createdBy: user.sub,
      },
    });
    await this.prisma.user.update({ where: { id: user.sub }, data: { companyId: company.id } });
    return company;
  }

  @Get('mine')
  @ApiOperation({ summary: 'My company with addresses' })
  async mine(@CurrentUser() user: RequestUser) {
    const me = await this.prisma.user.findUnique({ where: { id: user.sub }, select: { companyId: true } });
    if (!me?.companyId) throw new NotFoundException({ code: 'NOT_FOUND', message: 'No company linked to this account.' });
    return this.prisma.company.findFirst({
      where: { id: me.companyId, deletedAt: null },
      include: { addresses: { where: { deletedAt: null }, orderBy: { createdAt: 'asc' } } },
    });
  }

  @Post('mine/addresses')
  @ApiOperation({ summary: 'Add an address to my company' })
  async addAddress(@CurrentUser() user: RequestUser, @Body() dto: CreateAddressDto) {
    const companyId = await this.myCompanyId(user.sub);
    if (dto.isDefault) {
      await this.prisma.address.updateMany({ where: { companyId }, data: { isDefault: false } });
    }
    return this.prisma.address.create({
      data: {
        companyId,
        label: dto.label ? sanitizeText(dto.label) : 'Head office',
        line1: sanitizeText(dto.line1),
        line2: dto.line2 ? sanitizeText(dto.line2) : undefined,
        city: sanitizeText(dto.city),
        state: dto.state ? sanitizeText(dto.state) : undefined,
        postalCode: dto.postalCode ? sanitizeText(dto.postalCode) : undefined,
        country: sanitizeText(dto.country),
        isDefault: dto.isDefault ?? false,
        createdBy: user.sub,
      },
    });
  }

  @Patch('mine/addresses/:id')
  @ApiOperation({ summary: 'Update one of my company addresses' })
  async updateAddress(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: CreateAddressDto) {
    const companyId = await this.myCompanyId(user.sub);
    const address = await this.prisma.address.findFirst({ where: { id, companyId, deletedAt: null } });
    if (!address) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Address not found.' });
    if (dto.isDefault) {
      await this.prisma.address.updateMany({ where: { companyId }, data: { isDefault: false } });
    }
    return this.prisma.address.update({
      where: { id },
      data: {
        label: dto.label ? sanitizeText(dto.label) : undefined,
        line1: dto.line1 ? sanitizeText(dto.line1) : undefined,
        line2: dto.line2 ? sanitizeText(dto.line2) : undefined,
        city: dto.city ? sanitizeText(dto.city) : undefined,
        state: dto.state ? sanitizeText(dto.state) : undefined,
        postalCode: dto.postalCode ? sanitizeText(dto.postalCode) : undefined,
        country: dto.country ? sanitizeText(dto.country) : undefined,
        isDefault: dto.isDefault,
        updatedBy: user.sub,
      },
    });
  }

  @Delete('mine/addresses/:id')
  @ApiOperation({ summary: 'Soft-delete one of my company addresses' })
  async deleteAddress(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    const companyId = await this.myCompanyId(user.sub);
    const address = await this.prisma.address.findFirst({ where: { id, companyId, deletedAt: null } });
    if (!address) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Address not found.' });
    await this.prisma.address.update({ where: { id }, data: { deletedAt: new Date(), updatedBy: user.sub } });
    return { ok: true };
  }

  private async myCompanyId(userId: string): Promise<string> {
    const me = await this.prisma.user.findUnique({ where: { id: userId }, select: { companyId: true } });
    if (!me?.companyId) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'Link a company to your account first.' });
    }
    return me.companyId;
  }
}
