import {
  Body, Controller, ForbiddenException, Get, NotFoundException, Param, Patch, Post, Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiProperty, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { Request } from 'express';
import { AuditAction, SupplierProductStatus } from '@prisma/client';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/auth.decorators';
import { sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.module';

class CreateSupplierDto {
  @ApiProperty() @IsUUID() companyId!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(2000) capabilities?: string;
}

class CreateSupplierProductDto {
  @ApiPropertyOptional() @IsOptional() @IsUUID() productId?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(160) customName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(2000) customDescription?: string;
}

class ReviewSupplierProductDto {
  @ApiProperty({ enum: ['approved', 'changes_required', 'rejected'] })
  @IsIn(['approved', 'changes_required', 'rejected'])
  status!: 'approved' | 'changes_required' | 'rejected';
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(2000) reviewNote?: string;
}

@ApiTags('suppliers')
@ApiBearerAuth()
@Controller('suppliers')
export class SuppliersController {
  constructor(private prisma: PrismaService, private audit: AuditService) {}

  @Post('profile')
  @ApiOperation({ summary: 'Create my supplier profile (supplier role)' })
  async createProfile(@CurrentUser() user: RequestUser, @Body() dto: CreateSupplierDto, @Req() req: Request) {
    if (user.role !== 'supplier' && user.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    const company = await this.prisma.company.findFirst({ where: { id: dto.companyId, deletedAt: null } });
    if (!company) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Company not found.' });
    return this.prisma.supplier.create({
      data: {
        companyId: dto.companyId,
        ownerId: user.sub,
        capabilities: dto.capabilities ? sanitizeText(dto.capabilities) : undefined,
        createdBy: user.sub,
      },
    });
  }

  @Get('me')
  @ApiOperation({ summary: 'My supplier profile with listings' })
  async myProfile(@CurrentUser() user: RequestUser) {
    const supplier = await this.prisma.supplier.findFirst({
      where: { ownerId: user.sub, deletedAt: null },
      include: { company: true, products: { include: { product: { select: { name: true } } } } },
    });
    if (!supplier) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Supplier profile not found.' });
    return supplier;
  }

  @Post('me/listings')
  @ApiOperation({ summary: 'Submit a product listing — always starts as Pending Review, never auto-published' })
  async submitListing(@CurrentUser() user: RequestUser, @Body() dto: CreateSupplierProductDto) {
    const supplier = await this.mustOwnSupplier(user.sub);
    if (!dto.productId && !dto.customName) {
      throw new NotFoundException({ code: 'BAD_REQUEST', message: 'Provide a catalogue product or a custom name.' });
    }
    return this.prisma.supplierProduct.create({
      data: {
        supplierId: supplier.id,
        productId: dto.productId,
        customName: dto.customName ? sanitizeText(dto.customName) : undefined,
        customDescription: dto.customDescription ? sanitizeText(dto.customDescription) : undefined,
        status: SupplierProductStatus.pending_review,
        createdBy: user.sub,
      },
    });
  }

  @Get('me/listings')
  @ApiOperation({ summary: 'My listings and their review status' })
  async myListings(@CurrentUser() user: RequestUser) {
    const supplier = await this.mustOwnSupplier(user.sub);
    return this.prisma.supplierProduct.findMany({
      where: { supplierId: supplier.id, deletedAt: null },
      orderBy: { createdAt: 'desc' },
      include: { product: { select: { name: true } } },
    });
  }

  @Get('pending')
  @Roles('staff', 'admin')
  @ApiOperation({ summary: 'Listings awaiting review (staff/admin)' })
  pending() {
    return this.prisma.supplierProduct.findMany({
      where: { status: SupplierProductStatus.pending_review, deletedAt: null },
      orderBy: { createdAt: 'asc' },
      include: { supplier: { include: { company: { select: { name: true } } } }, product: { select: { name: true } } },
    });
  }

  @Patch('listings/:id/review')
  @Roles('staff', 'admin')
  @ApiOperation({ summary: 'Approve / request changes / reject a listing (staff/admin only — suppliers can never approve their own)' })
  async review(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Body() dto: ReviewSupplierProductDto,
    @Req() req: Request,
  ) {
    const listing = await this.prisma.supplierProduct.findFirst({
      where: { id, deletedAt: null },
      include: { supplier: true },
    });
    if (!listing) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Listing not found.' });
    // Defence in depth: even a staff account that owns the supplier record
    // cannot approve its own listing.
    if (listing.supplier.ownerId === user.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You cannot review your own listing.' });
    }
    if (listing.status !== SupplierProductStatus.pending_review && listing.status !== SupplierProductStatus.changes_required) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'Only pending or changes-required listings can be reviewed.' });
    }
    const updated = await this.prisma.supplierProduct.update({
      where: { id },
      data: {
        status: SupplierProductStatus[dto.status],
        reviewNote: dto.reviewNote ? sanitizeText(dto.reviewNote) : null,
        reviewedBy: user.sub,
        reviewedAt: new Date(),
        updatedBy: user.sub,
      },
    });
    await this.audit.log(AuditAction.supplier_product_reviewed, {
      actorId: user.sub, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      entityType: 'supplier_product', entityId: id, metadata: { status: dto.status },
    });
    return updated;
  }

  private async mustOwnSupplier(userId: string) {
    const supplier = await this.prisma.supplier.findFirst({ where: { ownerId: userId, deletedAt: null } });
    if (!supplier) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Supplier profile not found.' });
    return supplier;
  }
}
