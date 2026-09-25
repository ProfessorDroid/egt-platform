import { Body, Controller, Get, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiPropertyOptional, ApiTags } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { sanitizeText } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';

class UpdateMeDto {
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(120) fullName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(32) phone?: string;
}

const USER_SELECT = {
  id: true, email: true, fullName: true, phone: true, emailVerifiedAt: true,
  isActive: true, createdAt: true,
  role: { select: { name: true } },
  company: { select: { id: true, name: true, type: true, isVerified: true } },
};

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private prisma: PrismaService) {}

  @Get('me')
  @ApiOperation({ summary: 'My full profile' })
  async me(@CurrentUser() user: RequestUser) {
    const record = await this.prisma.user.findUnique({ where: { id: user.sub }, select: USER_SELECT });
    return { ...record, role: record?.role.name, emailVerified: !!record?.emailVerifiedAt };
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update my profile (name/phone only — role changes are admin-only)' })
  async updateMe(@CurrentUser() user: RequestUser, @Body() dto: UpdateMeDto) {
    const updated = await this.prisma.user.update({
      where: { id: user.sub },
      data: {
        fullName: dto.fullName ? sanitizeText(dto.fullName) : undefined,
        phone: dto.phone ? sanitizeText(dto.phone) : undefined,
        updatedBy: user.sub,
      },
      select: USER_SELECT,
    });
    return { ...updated, role: updated.role.name, emailVerified: !!updated.emailVerifiedAt };
  }
}
