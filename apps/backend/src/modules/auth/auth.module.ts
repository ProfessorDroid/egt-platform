import { Module } from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';

@Module({
  // JwtService comes from the global JwtModule registered in AppModule.
  imports: [],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
