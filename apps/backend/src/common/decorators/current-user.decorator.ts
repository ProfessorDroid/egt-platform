import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface RequestUser {
  sub: string; // user id
  email: string;
  role: string; // role name from the DB-backed JWT
  sessionId: string;
}

/**
 * The authenticated user. Populated ONLY by the server-side JWT guard from
 * the verified access token — client-sent role/ids are never trusted.
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): RequestUser => {
    const req = ctx.switchToHttp().getRequest();
    return req.user;
  },
);
