import { Prisma, PrismaClient } from '@prisma/client';

type SequenceTable = 'RfqSequence' | 'OrderSequence' | 'ShipmentSequence' | 'TicketSequence';

/**
 * Allocate the next yearly-sequential number atomically.
 * Single UPSERT ... RETURNING statement inside the caller's transaction —
 * the row lock serializes concurrent creators, and allocating the number in
 * the SAME transaction as the record insert means a failed insert rolls back
 * the allocation: no gaps, no collisions. Safe to retry.
 */
export async function nextYearlyNumber(
  tx: Pick<PrismaClient, '$queryRaw'>,
  table: SequenceTable,
  prefix: string,
): Promise<string> {
  const year = new Date().getFullYear();
  const rows = await tx.$queryRaw<{ n: number }[]>(
    Prisma.sql`INSERT INTO ${Prisma.raw(`"${table}"`)} ("year", "nextVal")
      VALUES (${year}, 2)
      ON CONFLICT ("year") DO UPDATE SET "nextVal" = ${Prisma.raw(`"${table}"."nextVal"`)} + 1
      RETURNING "nextVal" - 1 AS n`,
  );
  const n = rows[0]?.n ?? 1;
  return `${prefix}-${year}-${String(n).padStart(6, '0')}`;
}
