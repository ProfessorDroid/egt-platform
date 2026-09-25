import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  JWT_ACCESS_SECRET: z.string().min(32, 'JWT_ACCESS_SECRET must be >= 32 chars'),
  JWT_REFRESH_SECRET: z.string().min(32, 'JWT_REFRESH_SECRET must be >= 32 chars'),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().default(900), // 15 min
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().default(30),

  CORS_ORIGINS: z.string().default('http://localhost:3000'), // comma-separated allowlist
  MAX_REQUEST_BODY_MB: z.coerce.number().int().default(2),
  MAX_UPLOAD_MB: z.coerce.number().int().default(10),
  DOCUMENT_STORAGE_DIR: z.string().default('/var/lib/egt-documents'),
  DOCUMENT_SIGNING_SECRET: z.string().min(32, 'DOCUMENT_SIGNING_SECRET must be >= 32 chars'),
  DOCUMENT_URL_TTL_MINUTES: z.coerce.number().int().default(15),

  LOGIN_MAX_ATTEMPTS: z.coerce.number().int().default(5),
  LOGIN_LOCKOUT_MINUTES: z.coerce.number().int().default(15),
  THROTTLE_LOGIN_TTL: z.coerce.number().int().default(60), // seconds
  THROTTLE_LOGIN_LIMIT: z.coerce.number().int().default(10),
  THROTTLE_DEFAULT_TTL: z.coerce.number().int().default(60),
  THROTTLE_DEFAULT_LIMIT: z.coerce.number().int().default(120),

  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().int().optional(),
  SMTP_USER: z.string().optional(),
  SMTP_PASS: z.string().optional(),
  MAIL_FROM: z.string().optional(),
  APP_PUBLIC_URL: z.string().default('http://localhost:3000'),
});

export type AppConfig = z.infer<typeof envSchema>;

let cached: AppConfig | null = null;

export function getConfig(): AppConfig {
  if (cached) return cached;
  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`);
    // eslint-disable-next-line no-console
    console.error('Invalid environment configuration:\n' + issues.join('\n'));
    process.exit(1);
  }
  cached = parsed.data;
  return cached;
}
