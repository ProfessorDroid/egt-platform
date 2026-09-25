import { Body, Controller, Delete, Get, HttpCode, Param, Post, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Request } from 'express';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { Public } from '../../common/decorators/auth.decorators';
import { AuthService, RequestMeta } from './auth.service';
import { ForgotPasswordDto, LoginDto, RefreshDto, RegisterDto, ResetPasswordDto, VerifyEmailDto } from './dto/auth.dto';

function metaOf(req: Request): RequestMeta {
  return { ip: req.ip, userAgent: req.headers['user-agent'] };
}

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private auth: AuthService) {}

  @Public()
  @Post('register')
  @Throttle({ default: { limit: 20, ttl: 3600 } })
  @ApiOperation({ summary: 'Register as buyer or supplier' })
  register(@Body() dto: RegisterDto, @Req() req: Request) {
    return this.auth.register(dto, metaOf(req));
  }

  @Public()
  @Post('verify-email')
  @HttpCode(200)
  @ApiOperation({ summary: 'Verify email address with token' })
  verifyEmail(@Body() dto: VerifyEmailDto, @Req() req: Request) {
    return this.auth.verifyEmail(dto.token, metaOf(req));
  }

  @Public()
  @Post('login')
  @HttpCode(200)
  @Throttle({ default: { limit: 10, ttl: 60 } }) // strict login throttle (plus 5-fail account lockout)
  @ApiOperation({ summary: 'Sign in; returns short-lived access token + rotating refresh token' })
  login(@Body() dto: LoginDto, @Req() req: Request) {
    return this.auth.login(dto, metaOf(req));
  }

  @Public()
  @Post('refresh')
  @HttpCode(200)
  @ApiOperation({ summary: 'Rotate refresh token (reuse detection locks the session)' })
  refresh(@Body() dto: RefreshDto, @Req() req: Request) {
    return this.auth.refresh(dto.refreshToken, metaOf(req));
  }

  @Post('logout')
  @HttpCode(200)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Sign out of this device/session' })
  logout(@CurrentUser() user: RequestUser, @Req() req: Request) {
    return this.auth.logout(user.sessionId, metaOf(req));
  }

  @Post('logout-all')
  @HttpCode(200)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Sign out of every device' })
  logoutAll(@CurrentUser() user: RequestUser, @Req() req: Request) {
    return this.auth.logoutAll(user.sub, metaOf(req));
  }

  @Get('sessions')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List active device sessions for the current user' })
  sessions(@CurrentUser() user: RequestUser) {
    return this.auth.listSessions(user.sub);
  }

  @Public()
  @Post('forgot-password')
  @HttpCode(200)
  @Throttle({ default: { limit: 5, ttl: 3600 } })
  @ApiOperation({ summary: 'Request a password reset link' })
  forgotPassword(@Body() dto: ForgotPasswordDto, @Req() req: Request) {
    return this.auth.forgotPassword(dto, metaOf(req));
  }

  @Public()
  @Post('reset-password')
  @HttpCode(200)
  @ApiOperation({ summary: 'Reset password with token (invalidates all sessions)' })
  resetPassword(@Body() dto: ResetPasswordDto, @Req() req: Request) {
    return this.auth.resetPassword(dto, metaOf(req));
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Current authenticated user profile' })
  me(@CurrentUser() user: RequestUser) {
    return { id: user.sub, email: user.email, role: user.role };
  }

  @Delete('sessions/:id')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Revoke one device session (must belong to the caller)' })
  revokeSession(@CurrentUser() user: RequestUser, @Param('id') id: string, @Req() req: Request) {
    return this.auth.revokeSession(user.sub, id, metaOf(req));
  }
}
