// Jest setup: dummy-but-valid env so getConfig() passes in unit tests.
// No real secrets — these values never leave the test process.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgresql://test:test@localhost:5432/test';
process.env.JWT_ACCESS_SECRET = 'test-access-secret-0000000000000000';
process.env.JWT_REFRESH_SECRET = 'test-refresh-secret-000000000000000';
process.env.DOCUMENT_SIGNING_SECRET = 'test-doc-secret-0000000000000000000';
process.env.DOCUMENT_STORAGE_DIR = '/tmp/egt-test-documents';
