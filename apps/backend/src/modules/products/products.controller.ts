import { Body, Controller, ForbiddenException, Get, NotFoundException, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsOptional, IsString, MaxLength, Min } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/auth.decorators';
import { paginated, parsePagination, sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';

class UpdateProductDto {
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(160) name?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(2000) shortDescription?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(120) orderVolume?: string;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() isActive?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() isFeatured?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsInt() @Min(0) sortOrder?: number;
}

const PRODUCT_SELECT = {
  id: true, name: true, slug: true, shortDescription: true, orderVolume: true,
  expressSample: true, isFeatured: true, isActive: true, sortOrder: true,
  category: { select: { id: true, name: true, slug: true } },
  images: { orderBy: { sortOrder: 'asc' as const } },
  specifications: { orderBy: { sortOrder: 'asc' as const } },
};

@ApiTags('products')
@Controller('products')
export class ProductsController {
  constructor(private prisma: PrismaService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Public catalogue — the 16 audited products (no auth required)' })
  async list(@Query() query: { page?: string; limit?: string; category?: string; search?: string }) {
    const { page, limit, skip, take } = parsePagination(query);
    const where: Record<string, unknown> = { deletedAt: null, isActive: true };
    if (query.category) where.category = { slug: query.category };
    if (query.search) {
      where.name = { contains: sanitizeText(query.search), mode: 'insensitive' };
    }
    const [items, total] = await this.prisma.$transaction([
      this.prisma.product.findMany({ where, skip, take, orderBy: { sortOrder: 'asc' }, select: PRODUCT_SELECT }),
      this.prisma.product.count({ where }),
    ]);
    return paginated(items, total, page, limit);
  }

  @Public()
  @Get('categories')
  @ApiOperation({ summary: 'Product categories' })
  categories() {
    return this.prisma.category.findMany({
      where: { deletedAt: null },
      orderBy: { sortOrder: 'asc' },
      select: { id: true, name: true, slug: true, description: true },
    });
  }

  @Public()
  @Get(':slug')
  @ApiOperation({ summary: 'Product detail by slug' })
  async getOne(@Param('slug') slug: string) {
    const product = await this.prisma.product.findFirst({
      where: { slug, deletedAt: null, isActive: true },
      select: PRODUCT_SELECT,
    });
    if (!product) {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Product not found.' });
    }
    return product;
  }

  @Patch(':id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update a product (admin catalog manage)' })
  async update(@CurrentUser() user: RequestUser, @Param('id') id: string, @Body() dto: UpdateProductDto) {
    if (user.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    return this.prisma.product.update({
      where: { id },
      data: {
        ...dto,
        name: dto.name ? sanitizeText(dto.name) : undefined,
        shortDescription: dto.shortDescription ? sanitizeText(dto.shortDescription) : undefined,
        updatedBy: user.sub,
      },
      select: PRODUCT_SELECT,
    });
  }

  @Post()
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a product (admin only — catalogue is curated from the site audit)' })
  async create(@CurrentUser() user: RequestUser, @Body() dto: UpdateProductDto & { slug: string; categoryId: string }) {
    if (user.role !== 'admin') {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    return this.prisma.product.create({
      data: {
        name: sanitizeText(dto.name ?? ''),
        slug: dto.slug,
        categoryId: dto.categoryId,
        shortDescription: dto.shortDescription ? sanitizeText(dto.shortDescription) : undefined,
        orderVolume: dto.orderVolume,
        isActive: dto.isActive ?? true,
        isFeatured: dto.isFeatured ?? false,
        createdBy: user.sub,
      },
      select: PRODUCT_SELECT,
    });
  }
}
