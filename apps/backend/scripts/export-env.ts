// MUST be imported before anything that calls getConfig() (e.g. AppModule).
// Provides dummy-but-valid secrets for doc generation only — the export never
// touches the database (Prisma connects lazily).
process.env.DATABASE_URL ??= 'postgresql://dummy:dummy@localhost:5432/dummy';
process.env.JWT_ACCESS_SECRET ??= '0'.repeat(32);
process.env.JWT_REFRESH_SECRET ??= '1'.repeat(32);
process.env.DOCUMENT_SIGNING_SECRET ??= '2'.repeat(32);

export {};
