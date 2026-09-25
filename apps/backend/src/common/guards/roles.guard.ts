import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PrismaService } from '../../prisma/prisma.service';
import { PERMISSIONS_KEY, ROLES_KEY } from '../decorators/auth.decorators';

/**
 * Server-side RBAC. Roles and permissions are resolved from the DATABASE
 * against the user id in the verified JWT — never from client input.
 */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector, private prisma: PrismaService) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>(ROLES_KEY, [ctx.getHandler(), ctx.getClass()]);
    const requiredPermissions = this.reflector.getAllAndOverride<string[]>(PERMISSIONS_KEY, [
      ctx.getHandler(),
      ctx.getClass(),
    ]);
    if (!requiredRoles?.length && !requiredPermissions?.length) return true;

    const req = ctx.switchToHttp().getRequest();
    const user = req.user;
    if (!user?.sub) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }

    const dbUser = await this.prisma.user.findFirst({
      where: { id: user.sub, deletedAt: null, isActive: true },
      include: { role: { include: { permissions: { include: { permission: true } } } } },
    });
    if (!dbUser) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }

    const roleName = dbUser.role.name;
    req.user.role = roleName; // refresh from DB, not from the token claim

    if (requiredRoles?.length && !requiredRoles.includes(roleName)) {
      throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
    if (requiredPermissions?.length) {
      const granted = new Set(dbUser.role.permissions.map((rp) => rp.permission.key));
      const missing = requiredPermissions.filter((p) => !granted.has(p));
      if (missing.length) {
        throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
      }
    }
    return true;
  }
}
