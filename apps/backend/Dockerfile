# ---- build ----
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --no-audit --no-fund
COPY tsconfig*.json nest-cli.json ./
COPY prisma ./prisma
COPY src ./src
RUN npx prisma generate && npm run build && npx prisma migrate diff --from-empty --to-schema-datamodel prisma/schema.prisma --script > /tmp/schema-check.sql

# ---- runtime ----
FROM node:24-alpine AS runtime
RUN addgroup -S egt && adduser -S egt -G egt \
  && mkdir -p /var/lib/egt-documents && chown egt:egt /var/lib/egt-documents
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/package.json /app/package-lock.json* ./
RUN npm ci --omit=dev --no-audit --no-fund && npm cache clean --force
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=build /app/node_modules/@prisma ./node_modules/@prisma
USER egt
EXPOSE 3000
# Apply migrations then start. Seed NEVER runs here (dev-only guard + not wired).
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/main"]
