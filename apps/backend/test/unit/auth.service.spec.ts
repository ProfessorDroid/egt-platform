import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import {
  BadRequestException, ConflictException, ForbiddenException, UnauthorizedException,
} from '@nestjs/common';
import * as argon2 from 'argon2';
import { AuthService } from '../../src/modules/auth/auth.service';
import { PrismaService } from '../../src/prisma/prisma.service';
import { AuditService } from '../../src/modules/audit/audit.module';

// Shared Prisma mock: delegate methods are replaced per-test.
function makePrismaMock() {
  const tx: Record<string, any> = {};
  const delegates = ['user', 'role', 'company', 'verificationToken', 'session', 'refreshToken'];
  for (const d of delegates) {
    tx[d] = { findUnique: jest.fn(), findUniqueOrThrow: jest.fn(), findFirst: jest.fn(), findMany: jest.fn(), create: jest.fn(), update: jest.fn(), updateMany: jest.fn(), deleteMany: jest.fn() };
  }
  tx.$queryRaw = jest.fn();
  const prisma: Record<string, unknown> = {
    $transaction: jest.fn((arg: unknown) => (typeof arg === 'function' ? (arg as (t: unknown) => unknown)(tx) : Promise.resolve([]))),
    $queryRaw: jest.fn(),
  };
  for (const d of delegates) prisma[d] = tx[d];
  return { prisma, tx };
}

describe('AuthService', () => {
  let service: AuthService;
  let prisma: Record<string, any>;
  let tx: Record<string, any>;
  const audit = { log: jest.fn() };
  const jwt = { signAsync: jest.fn().mockResolvedValue('access.jwt.token') };
  const PASSWORD = 'Strong#Pass123';
  let passwordHash: string;

  beforeAll(async () => {
    passwordHash = await argon2.hash(PASSWORD, { type: argon2.argon2id });
  });

  beforeEach(async () => {
    const mocks = makePrismaMock();
    prisma = mocks.prisma;
    tx = mocks.tx;
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prisma },
        { provide: JwtService, useValue: jwt },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();
    service = module.get(AuthService);
  });

  const baseUser = (over: Record<string, unknown> = {}) => ({
    id: 'user-1', email: 'buyer@example.com', passwordHash,
    fullName: 'Dev Buyer', phone: null, isActive: true,
    failedLoginCount: 0, lockedUntil: null, emailVerifiedAt: null,
    companyId: null,
    role: { id: 'role-buyer', name: 'buyer' },
    ...over,
  });

  // ---------------------------------------------------------- registration
  describe('register', () => {
    it('creates a buyer with hashed password and a verification token', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.role.findUniqueOrThrow.mockResolvedValue({ id: 'role-buyer', name: 'buyer' });
      prisma.user.create.mockImplementation(async (args: { data: Record<string, unknown> }) => ({
        id: 'user-1', ...args.data, role: { name: 'buyer' }, emailVerifiedAt: null,
      }));
      prisma.verificationToken.create.mockResolvedValue({ id: 'vt-1' });

      const res = await service.register(
        { email: 'buyer@example.com', password: PASSWORD, fullName: 'Dev Buyer' },
        {},
      );
      expect(prisma.user.create).toHaveBeenCalled();
      const data = prisma.user.create.mock.calls[0][0].data;
      expect(data.passwordHash).not.toBe(PASSWORD); // never stored raw
      expect(data.email).toBe('buyer@example.com');
      expect(res.user.email).toBe('buyer@example.com');
      expect(audit.log).toHaveBeenCalledWith('user_registered', expect.anything());
    });

    it('forces public registration to buyer even when role=admin is sent', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.role.findUniqueOrThrow.mockResolvedValue({ id: 'role-buyer', name: 'buyer' });
      prisma.user.create.mockImplementation(async (args: { data: Record<string, unknown> }) => ({
        id: 'user-1', ...args.data, role: { name: 'buyer' }, emailVerifiedAt: null,
      }));
      prisma.verificationToken.create.mockResolvedValue({ id: 'vt-1' });

      await service.register(
        { email: 'x@example.com', password: PASSWORD, fullName: 'X', role: 'admin' as never },
        {},
      );
      expect(prisma.role.findUniqueOrThrow).toHaveBeenCalledWith({ where: { name: 'buyer' } });
    });

    it('rejects duplicate email with 409', async () => {
      prisma.user.findUnique.mockResolvedValue(baseUser());
      await expect(
        service.register({ email: 'buyer@example.com', password: PASSWORD, fullName: 'X' }, {}),
      ).rejects.toThrow(ConflictException);
    });
  });

  // ------------------------------------------------------- email verification
  describe('verifyEmail', () => {
    it('rejects an unknown/expired token with 400', async () => {
      prisma.verificationToken.findUnique.mockResolvedValue(null);
      await expect(service.verifyEmail('bogus', {})).rejects.toThrow(BadRequestException);
    });
  });

  // ------------------------------------------------------------------ login
  describe('login', () => {
    it('returns token pair on valid credentials and resets fail counter', async () => {
      prisma.user.findFirst.mockResolvedValue(baseUser());
      prisma.user.update.mockResolvedValue({});
      prisma.session.create.mockResolvedValue({ id: 'sess-1' });
      prisma.refreshToken.create.mockResolvedValue({ id: 'rt-1' });

      const res = await service.login({ email: 'buyer@example.com', password: PASSWORD }, {});
      expect(res.accessToken).toBe('access.jwt.token');
      expect(res.refreshToken).toBeDefined();
      expect(res.user).toMatchObject({ email: 'buyer@example.com', role: 'buyer' });
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { failedLoginCount: 0, lockedUntil: null, lastLoginAt: expect.any(Date) },
      });
    });

    it('rejects wrong password with 401 and increments the fail counter', async () => {
      prisma.user.findFirst.mockResolvedValue(baseUser());
      prisma.user.update.mockResolvedValue({});

      await expect(
        service.login({ email: 'buyer@example.com', password: 'Wrong#Pass999' }, {}),
      ).rejects.toThrow(UnauthorizedException);
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { failedLoginCount: 1 },
      });
    });

    it('locks the account for 15 min after 5 failed attempts (403)', async () => {
      prisma.user.findFirst.mockResolvedValue(baseUser({ failedLoginCount: 4 }));
      prisma.user.update.mockResolvedValue({});

      await expect(
        service.login({ email: 'buyer@example.com', password: 'Wrong#Pass999' }, {}),
      ).rejects.toThrow(UnauthorizedException);
      const data = prisma.user.update.mock.calls[0][0].data;
      expect(data.lockedUntil).toBeInstanceOf(Date);
      expect(data.failedLoginCount).toBe(0);

      // Subsequent login while locked → 403 ACCOUNT_LOCKED
      prisma.user.findFirst.mockResolvedValue(baseUser({ lockedUntil: new Date(Date.now() + 600000) }));
      await expect(
        service.login({ email: 'buyer@example.com', password: PASSWORD }, {}),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  // ---------------------------------------------------------------- refresh
  describe('refresh', () => {
    const liveRecord = () => ({
      id: 'rt-1', familyId: 'fam-1', tokenHash: 'h', sessionId: 'sess-1',
      userId: 'user-1', rotatedAt: null, revokedAt: null,
      expiresAt: new Date(Date.now() + 86400000),
      session: { revokedAt: null },
    });

    it('rotates a live token and issues a new pair', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue(liveRecord());
      prisma.user.findFirst.mockResolvedValue(baseUser());
      tx.refreshToken.update.mockResolvedValue({});
      tx.refreshToken.create.mockResolvedValue({});

      const res = await service.refresh('raw-refresh-token', {});
      expect(res.accessToken).toBe('access.jwt.token');
      expect(res.refreshToken).not.toBe('raw-refresh-token');
      expect(tx.refreshToken.update).toHaveBeenCalledWith({
        where: { id: 'rt-1' }, data: { rotatedAt: expect.any(Date) },
      });
    });

    it('detects reuse of a rotated token, revokes the whole family and locks the session', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue({ ...liveRecord(), rotatedAt: new Date() });
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 2 });
      prisma.session.update.mockResolvedValue({});

      await expect(service.refresh('reused-token', {})).rejects.toThrow(UnauthorizedException);
      // $transaction with array form: family revoked + session locked
      const txArg = (prisma.$transaction as jest.Mock).mock.calls[0][0];
      expect(Array.isArray(txArg)).toBe(true);
      expect(prisma.session.update).toHaveBeenCalledWith({
        where: { id: 'sess-1' },
        data: { revokedAt: expect.any(Date), revokedReason: 'refresh_token_reuse_detected' },
      });
      expect(audit.log).toHaveBeenCalledWith('user_login_failed', expect.objectContaining({
        metadata: expect.objectContaining({ reason: 'refresh_reuse' }),
      }));
    });

    it('rejects an unknown refresh token with 401', async () => {
      prisma.refreshToken.findUnique.mockResolvedValue(null);
      await expect(service.refresh('nope', {})).rejects.toThrow(UnauthorizedException);
    });
  });

  // ----------------------------------------------------------------- logout
  describe('logout / logoutAll', () => {
    it('logout-all revokes every session of the user', async () => {
      prisma.session.findMany.mockResolvedValue([{ id: 's1' }, { id: 's2' }]);
      prisma.refreshToken.updateMany.mockResolvedValue({ count: 2 });
      prisma.session.updateMany.mockResolvedValue({ count: 2 });

      const res = await service.logoutAll('user-1', {});
      expect(res.sessionsRevoked).toBe(2);
      expect(prisma.session.updateMany).toHaveBeenCalledWith({
        where: { id: { in: ['s1', 's2'] } },
        data: { revokedAt: expect.any(Date), revokedReason: 'logout_all' },
      });
      expect(audit.log).toHaveBeenCalledWith('user_logout_all', expect.anything());
    });
  });
});
