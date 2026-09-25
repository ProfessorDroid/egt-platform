import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import type { UserConfig as VitestUserConfig } from 'vitest/config';

type ConfigWithTests = Parameters<typeof defineConfig>[0] &
  Pick<VitestUserConfig, 'test'>;

export default defineConfig({
  plugins: [react()],
  server: { port: 5174 },
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
} as ConfigWithTests);
