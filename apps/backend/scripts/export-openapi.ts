// Exports the Swagger/OpenAPI document to packages/shared/openapi.yaml.
// This YAML is the API contract consumed by the mobile and admin apps.
// Run: npm run openapi:export
import './export-env';
import { NestFactory } from '@nestjs/core';
import { PrismaService } from '../src/prisma/prisma.service';

// Doc generation never queries the DB. PrismaService connects in onModuleInit,
// so stub the connection out — the OpenAPI document only needs route metadata.
PrismaService.prototype.$connect = async () => undefined as never;
PrismaService.prototype.$disconnect = async () => undefined as never;
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { writeFileSync, mkdirSync } from 'fs';
import { join, resolve } from 'path';
import * as yaml from 'yaml';
import { AppModule } from '../src/app.module';

async function main() {
  const app = await NestFactory.create(AppModule, { logger: false });
  app.setGlobalPrefix('api/v1');
  const document = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle('EGT B2B API')
      .setDescription('Eagle Goods Trading Co. — sourcing & export backend API (v1)')
      .setVersion('1.0.0')
      .addBearerAuth()
      .build(),
  );
  const outDir = resolve(__dirname, '../../../packages/shared');
  mkdirSync(outDir, { recursive: true });
  const outPath = join(outDir, 'openapi.yaml');
  writeFileSync(outPath, yaml.stringify(document));
  // eslint-disable-next-line no-console
  console.log(`Wrote ${outPath} (${Object.keys(document.paths ?? {}).length} paths)`);
  // Skip app.close(): Prisma's engine binaries aren't needed for doc generation
  // and tearing down would try (and fail) to load the query engine. Exit clean.
  process.exit(0);
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});
