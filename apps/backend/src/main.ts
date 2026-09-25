import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { json, urlencoded } from 'express';
import { AppModule } from './app.module';
import { getConfig } from './config/env';

async function bootstrap() {
  const config = getConfig();
  const app = await NestFactory.create(AppModule, { cors: false });

  app.use(helmet());
  app.use(json({ limit: `${config.MAX_REQUEST_BODY_MB}mb` }));
  app.use(urlencoded({ extended: true, limit: `${config.MAX_REQUEST_BODY_MB}mb` }));

  const origins = config.CORS_ORIGINS.split(',').map((o) => o.trim()).filter(Boolean);
  app.enableCors({
    origin: (origin, cb) => {
      if (!origin || origins.includes(origin)) return cb(null, true);
      return cb(new Error('CORS origin not allowed'), false);
    },
    credentials: true,
  });

  app.setGlobalPrefix('api/v1');

  const swaggerConfig = new DocumentBuilder()
    .setTitle('EGT B2B API')
    .setDescription('Eagle Goods Trading Co. — sourcing & export backend API (v1)')
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(config.PORT);
  // eslint-disable-next-line no-console
  console.log(`EGT backend listening on :${config.PORT} (NODE_ENV=${config.NODE_ENV})`);
}

void bootstrap();
