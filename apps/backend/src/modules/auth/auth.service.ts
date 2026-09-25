import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuditAction, RoleName } from '@prisma/client';
import * as argon2 from 'argon2';
import { randomUUID } from 'crypto';
import { getConfig } from '../../config/env';
import { randomToken, sha256Hex } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.module';
import { ForgotPasswordDto, LoginDto, RegisterDto, ResetPasswordDto } from './dto/auth.dto';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface RequestMeta {
  ip?: string;
  userAgent?: string;
}

const PUBLIC_ROLES: RoleName[] = [RoleName.buyer, RoleName.supplier];

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwt: JwtService,
    private audit: AuditService,
  ) {}

  // ------------------------------------------------------------ registration
  async register(dto: RegisterDto, meta: RequestMeta) {
    const cfg = getConfig();
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email.toLowerCase() } });
    if (existing) {
      throw new ConflictException({ code: 'EMAIL_TAKEN', message: 'An account with this email already exists.' });
    }
    const roleName: RoleName = dto.role && PUBLIC_ROLES.includes(dto.role) ? dto.role : RoleName.buyer;
    const role = await this.prisma.role.findUniqueOrThrow({ where: { name: roleName } });

    let companyId: string | undefined;
    if (dto.companyName) {
      const company = await this.prisma.company.create({
        data: { name: dto.companyName, type: roleName === RoleName.supplier ? 'supplier' : 'buyer' },
      });
      companyId = company.id;
    }

    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        passwordHash: await argon2.hash(dto.password, { type: argon2.argon2id }),
        fullName: dto.fullName,
        phone: dto.phone,
        roleId: role.id,
        companyId,
      },
      include: { role: true },
    });

    // Email verification token (raw token is emailed; only the hash is stored).
    const rawToken = randomToken();
    await this.prisma.verificationToken.create({
      data: {
        userId: user.id,
        purpose: 'email_verification',
        tokenHash: sha256Hex(rawToken),
        expiresAt: new Date(Date.now() + 24 * 3600 * 1000),
      },
    });

    await this.audit.log(AuditAction.user_registered, {
      actorId: user.id,
      ipAddress: meta.ip,
      userAgent: meta.userAgent,
      entityType: 'user',
      entityId: user.id,
      metadata: { email: user.email, role: roleName },
    });

    // TODO: send verification email via SMTP once credentials are provided (needs-from-Sukh).
    return { user: this.publicUser(user), verificationToken: cfg.NODE_ENV === 'production' ? undefined : rawToken };
  }

  async verifyEmail(token: string, meta: RequestMeta) {
    const record = await this.prisma.verificationToken.findUnique({ where: { tokenHash: sha256Hex(token) } });
    if (!record || record.usedAt || record.expiresAt < new Date() || record.purpose !== 'email_verification') {
      throw new BadRequestException({ code: 'TOKEN_INVALID', message: 'This verification link is invalid or has expired.' });
    }
    const user = await this.prisma.user.update({
      where: { id: record.userId },
      data: { emailVerifiedAt: new Date() },
      include: { role: true },
    });
    await this.prisma.verificationToken.update({ where: { id: record.id }, data: { usedAt: new Date() } });
    await this.audit.log(AuditAction.email_verified, {
      actorId: user.id, ipAddress: meta.ip, userAgent: meta.userAgent, entityType: 'user', entityId: user.id,
    });
    return { user: this.publicUser(user) };
  }

  // ------------------------------------------------------------------ login
  async login(dto: LoginDto, meta: RequestMeta): Promise<AuthTokens & { user: unknown }> {
    const cfg = getConfig();
    const email = dto.email.toLowerCase();
    const user = await this.prisma.user.findFirst({
      where: { email, deletedAt: null },
      include: { role: true },
    });

    if (user?.lockedUntil && user.lockedUntil > new Date()) {
      const minutes = Math.ceil((user.lockedUntil.getTime() - Date.now()) / 60000);
      await this.audit.log(AuditAction.user_login_failed, {
        actorId: user.id, ipAddress: meta.ip, userAgent: meta.userAgent, metadata: { reason: 'locked' },
      });
      throw new ForbiddenException({
        code: 'ACCOUNT_LOCKED',
        message: `Too many failed attempts. Try again in about ${minutes} minutes.`,
      });
    }

    const passwordOk = user && user.isActive ? await argon2.verify(user.passwordHash, dto.password) : false;
    if (!user || !passwordOk) {
      if (user) {
        const failed = user.failedLoginCount + 1;
        const lock = failed >= cfg.LOGIN_MAX_ATTEMPTS
          ? { lockedUntil: new Date(Date.now() + cfg.LOGIN_LOCKOUT_MINUTES * 60000), failedLoginCount: 0 }
          : { failedLoginCount: failed };
        await this.prisma.user.update({ where: { id: user.id }, data: lock });
        await this.audit.log(AuditAction.user_login_failed, {
          actorId: user.id, ipAddress: meta.ip, userAgent: meta.userAgent, metadata: { attempts: failed },
        });
      }
      // Same message for unknown email to avoid account enumeration.
      throw new UnauthorizedException({ code: 'INVALID_CREDENTIALS', message: 'Email or password is incorrect.' });
    }

    await this.prisma.user.update({
      where: { id: user.id },
      data: { failedLoginCount: 0, lockedUntil: null, lastLoginAt: new Date() },
    });

    const session = await this.prisma.session.create({
      data: {
        userId: user.id,
        userAgent: meta.userAgent,
        ipAddress: meta.ip,
        expiresAt: new Date(Date.now() + cfg.REFRESH_TOKEN_TTL_DAYS * 86400 * 1000),
      },
    });
    const tokens = await this.issueTokenPair(user.id, user.email, user.role.name, session.id);
    await this.audit.log(AuditAction.user_login, {
      actorId: user.id, ipAddress: meta.ip, userAgent: meta.userAgent, entityType: 'session', entityId: session.id,
    });
    return { ...tokens, user: this.publicUser(user) };
  }

  // ----------------------------------------------------------------- logout
  async logout(sessionId: string, meta: RequestMeta) {
    await this.prisma.$transaction([
      this.prisma.refreshToken.updateMany({ where: { sessionId, revokedAt: null }, data: { revokedAt: new Date() } }),
      this.prisma.session.update({ where: { id: sessionId }, data: { revokedAt: new Date(), revokedReason: 'logout' } }),
    ]);
    await this.audit.log(AuditAction.user_logout, {
      ipAddress: meta.ip, userAgent: meta.userAgent, entityType: 'session', entityId: sessionId,
    });
    return { ok: true };
  }

  async logoutAll(userId: string, meta: RequestMeta) {
    const sessions = await this.prisma.session.findMany({ where: { userId, revokedAt: null }, select: { id: true } });
    const ids = sessions.map((s) => s.id);
    if (ids.length) {
      await this.prisma.$transaction([
        this.prisma.refreshToken.updateMany({ where: { sessionId: { in: ids } }, data: { revokedAt: new Date() } }),
        this.prisma.session.updateMany({ where: { id: { in: ids } }, data: { revokedAt: new Date(), revokedReason: 'logout_all' } }),
      ]);
    }
    await this.audit.log(AuditAction.user_logout_all, {
      actorId: userId, ipAddress: meta.ip, userAgent: meta.userAgent, metadata: { sessionsRevoked: ids.length },
    });
    return { ok: true, sessionsRevoked: ids.length };
  }

  async listSessions(userId: string) {
    return this.prisma.session.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: { id: true, userAgent: true, ipAddress: true, createdAt: true, expiresAt: true, revokedAt: true },
      take: 50,
    });
  }

  async revokeSession(userId: string, sessionId: string, meta: RequestMeta) {
    const session = await this.prisma.session.findFirst({ where: { id: sessionId, userId } });
    if (!session) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    await this.prisma.$transaction([
      this.prisma.refreshToken.updateMany({ where: { sessionId, revokedAt: null }, data: { revokedAt: new Date() } }),
      this.prisma.session.update({ where: { id: sessionId }, data: { revokedAt: new Date(), revokedReason: 'revoked_by_user' } }),
    ]);
    await this.audit.log(AuditAction.user_logout, {
      actorId: userId, ipAddress: meta.ip, userAgent: meta.userAgent, entityType: 'session', entityId: sessionId,
    });
    return { ok: true };
  }

  // ------------------------------------------------- refresh + rotation
  private async issueTokenPair(userId: string, email: string, role: string, sessionId: string): Promise<AuthTokens> {
    const cfg = getConfig();
    const familyId = randomUUID();
    const rawRefresh = randomToken(48);
    const refreshExpires = new Date(Date.now() + cfg.REFRESH_TOKEN_TTL_DAYS * 86400 * 1000);
    await this.prisma.refreshToken.create({
      data: {
        familyId,
        tokenHash: sha256Hex(rawRefresh),
        sessionId,
        userId,
        expiresAt: refreshExpires,
      },
    });
    const accessToken = await this.jwt.signAsync(
      { sub: userId, email, role, sessionId },
      { secret: cfg.JWT_ACCESS_SECRET, expiresIn: cfg.ACCESS_TOKEN_TTL_SECONDS },
    );
    return { accessToken, refreshToken: rawRefresh, expiresIn: cfg.ACCESS_TOKEN_TTL_SECONDS };
  }

  /**
   * Rotate a refresh token. If the presented token was already rotated
   * (reuse detection), the ENTIRE token family is revoked and the session
   * locked — a rotated token being replayed means compromise.
   */
  async refresh(rawToken: string, meta: RequestMeta): Promise<AuthTokens> {
    const cfg = getConfig();
    const record = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: sha256Hex(rawToken) },
      include: { session: true },
    });
    if (!record) {
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Session expired. Please sign in again.' });
    }

    // Reuse detection: token already rotated or revoked → compromise.
    if (record.rotatedAt || record.revokedAt) {
      await this.prisma.$transaction([
        this.prisma.refreshToken.updateMany({
          where: { familyId: record.familyId },
          data: { revokedAt: new Date(), reusedAt: record.rotatedAt ? new Date() : undefined },
        }),
        this.prisma.session.update({
          where: { id: record.sessionId },
          data: { revokedAt: new Date(), revokedReason: 'refresh_token_reuse_detected' },
        }),
      ]);
      await this.audit.log(AuditAction.user_login_failed, {
        actorId: record.userId, ipAddress: meta.ip, userAgent: meta.userAgent,
        metadata: { reason: 'refresh_reuse', familyId: record.familyId },
      });
      throw new UnauthorizedException({
        code: 'TOKEN_REUSE_DETECTED',
        message: 'This session was used on another device and has been locked for security. Please sign in again.',
      });
    }

    if (record.expiresAt < new Date() || record.session.revokedAt) {
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Session expired. Please sign in again.' });
    }

    const user = await this.prisma.user.findFirst({
      where: { id: record.userId, deletedAt: null, isActive: true },
      include: { role: true },
    });
    if (!user) {
      throw new UnauthorizedException({ code: 'TOKEN_INVALID', message: 'Session expired. Please sign in again.' });
    }

    // Rotate: mark old, issue new in the same family.
    const newRaw = randomToken(48);
    await this.prisma.$transaction([
      this.prisma.refreshToken.update({ where: { id: record.id }, data: { rotatedAt: new Date() } }),
      this.prisma.refreshToken.create({
        data: {
          familyId: record.familyId,
          tokenHash: sha256Hex(newRaw),
          sessionId: record.sessionId,
          userId: record.userId,
          expiresAt: new Date(Date.now() + cfg.REFRESH_TOKEN_TTL_DAYS * 86400 * 1000),
        },
      }),
    ]);

    const accessToken = await this.jwt.signAsync(
      { sub: user.id, email: user.email, role: user.role.name, sessionId: record.sessionId },
      { secret: cfg.JWT_ACCESS_SECRET, expiresIn: cfg.ACCESS_TOKEN_TTL_SECONDS },
    );
    return { accessToken, refreshToken: newRaw, expiresIn: cfg.ACCESS_TOKEN_TTL_SECONDS };
  }

  // ------------------------------------------------------- password reset
  async forgotPassword(dto: ForgotPasswordDto, meta: RequestMeta) {
    const user = await this.prisma.user.findFirst({
      where: { email: dto.email.toLowerCase(), deletedAt: null },
    });
    // Always respond OK to avoid account enumeration.
    if (user) {
      const rawToken = randomToken();
      await this.prisma.verificationToken.create({
        data: {
          userId: user.id,
          purpose: 'password_reset',
          tokenHash: sha256Hex(rawToken),
          expiresAt: new Date(Date.now() + 60 * 60000),
        },
      });
      await this.audit.log(AuditAction.password_reset_requested, {
        actorId: user.id, ipAddress: meta.ip, userAgent: meta.userAgent,
      });
      // TODO: email the raw token once SMTP credentials are provided (needs-from-Sukh).
      if (getConfig().NODE_ENV !== 'production') return { ok: true, resetToken: rawToken };
    }
    return { ok: true };
  }

  async resetPassword(dto: ResetPasswordDto, meta: RequestMeta) {
    const record = await this.prisma.verificationToken.findUnique({ where: { tokenHash: sha256Hex(dto.token) } });
    if (!record || record.usedAt || record.expiresAt < new Date() || record.purpose !== 'password_reset') {
      throw new BadRequestException({ code: 'TOKEN_INVALID', message: 'This reset link is invalid or has expired.' });
    }
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: record.userId },
        data: { passwordHash: await argon2.hash(dto.newPassword, { type: argon2.argon2id }) },
      }),
      this.prisma.verificationToken.update({ where: { id: record.id }, data: { usedAt: new Date() } }),
      // Password change invalidates every session — forced re-login everywhere.
      this.prisma.session.updateMany({
        where: { userId: record.userId, revokedAt: null },
        data: { revokedAt: new Date(), revokedReason: 'password_reset' },
      }),
    ]);
    await this.audit.log(AuditAction.password_reset_completed, {
      actorId: record.userId, ipAddress: meta.ip, userAgent: meta.userAgent,
    });
    return { ok: true };
  }

  private publicUser(user: { id: string; email: string; fullName: string; phone: string | null; emailVerifiedAt: Date | null; role: { name: string } }) {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phone: user.phone,
      role: user.role.name,
      emailVerified: !!user.emailVerifiedAt,
    };
  }
}
