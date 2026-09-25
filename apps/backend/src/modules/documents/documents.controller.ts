import {
  BadRequestException, Body, Controller, ForbiddenException, Get, NotFoundException, Param, Post, Query, Req,
  UploadedFile, UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiOperation, ApiTags } from '@nestjs/swagger';
import { createHash } from 'crypto';
import { createWriteStream, promises as fs } from 'fs';
import { join } from 'path';
import { Request, Response } from 'express';
import { AuditAction, DocumentKind } from '@prisma/client';
import { CurrentUser, RequestUser } from '../../common/decorators/current-user.decorator';
import { getConfig } from '../../config/env';
import { randomStoredFilename, signDownloadToken, verifyDownloadToken } from '../../common/utils/crypto.util';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../audit/audit.module';
import { NotificationsService } from '../notifications/notifications.service';

const ALLOWED_MIME: Record<string, string[]> = {
  'application/pdf': ['pdf'],
  'image/jpeg': ['jpg', 'jpeg'],
  'image/png': ['png'],
  'image/webp': ['webp'],
  'application/msword': ['doc'],
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['docx'],
  'application/vnd.ms-excel': ['xls'],
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['xlsx'],
  'text/csv': ['csv'],
  'text/plain': ['txt'],
};

@ApiTags('documents')
@ApiBearerAuth()
@Controller('documents')
export class DocumentsController {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private notifications: NotificationsService,
  ) {}

  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB hard cap
      fileFilter: (_req, file, cb) => {
        const ext = (file.originalname.split('.').pop() ?? '').toLowerCase();
        const allowedExts = ALLOWED_MIME[file.mimetype];
        if (!allowedExts || !allowedExts.includes(ext)) {
          return cb(new BadRequestException({
            code: 'FILE_TYPE_NOT_ALLOWED',
            message: 'This file type is not allowed. Use PDF, images, Word, Excel, CSV or TXT.',
          }), false);
        }
        cb(null, true);
      },
    }),
  )
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: {
    file: { type: 'string', format: 'binary' },
    kind: { type: 'string', enum: Object.values(DocumentKind) },
    ownerType: { type: 'string', enum: ['rfq', 'order', 'shipment', 'support_ticket'] },
    ownerId: { type: 'string', format: 'uuid' },
  }, required: ['file', 'ownerType', 'ownerId'] } })
  @ApiOperation({ summary: 'Upload a document (10 MB max; stored privately, random filename)' })
  async upload(
    @CurrentUser() user: RequestUser,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: { kind?: string; ownerType: string; ownerId: string },
    @Req() req: Request,
  ) {
    if (!file) throw new BadRequestException({ code: 'FILE_REQUIRED', message: 'No file was uploaded.' });
    const cfg = getConfig();
    const ownerType = body.ownerType;
    if (!['rfq', 'order', 'shipment', 'support_ticket'].includes(ownerType)) {
      throw new BadRequestException({ code: 'BAD_REQUEST', message: 'Unknown owner type.' });
    }
    await this.assertCanAccessOwner(user, ownerType, body.ownerId);

    const ext = (file.originalname.split('.').pop() ?? 'bin').toLowerCase();
    const storedFilename = randomStoredFilename(ext);
    const dir = cfg.DOCUMENT_STORAGE_DIR;
    await fs.mkdir(dir, { recursive: true });
    const dest = join(dir, storedFilename);

    const checksum = createHash('sha256');
    await new Promise<void>((resolve, reject) => {
      const ws = createWriteStream(dest, { mode: 0o600 });
      checksum.update(file.buffer);
      ws.on('finish', resolve);
      ws.on('error', reject);
      ws.end(file.buffer);
    });

    const doc = await this.prisma.document.create({
      data: {
        kind: (body.kind as DocumentKind) ?? DocumentKind.other,
        originalName: file.originalname.slice(0, 255),
        storedFilename,
        mimeType: file.mimetype,
        sizeBytes: file.size,
        checksumSha256: checksum.digest('hex'),
        uploadedById: user.sub,
        ownerType,
        ownerId: body.ownerId,
      },
    });

    if (ownerType === 'rfq') {
      await this.prisma.rfqDocument.create({ data: { rfqId: body.ownerId, documentId: doc.id } });
    }

    await this.audit.log(AuditAction.document_uploaded, {
      actorId: user.sub, ipAddress: req.ip, userAgent: req.headers['user-agent'],
      entityType: 'document', entityId: doc.id, metadata: { ownerType, ownerId: body.ownerId, size: file.size },
    });

    // Notify the counterparty on RFQ documents.
    if (ownerType === 'rfq') {
      const rfq = await this.prisma.rfq.findUnique({ where: { id: body.ownerId }, select: { buyerId: true, rfqNumber: true } });
      if (rfq && rfq.buyerId !== user.sub) {
        await this.notifications.emit('document_uploaded', rfq.buyerId, {
          title: `New document on RFQ ${rfq.rfqNumber}`,
          body: `${file.originalname} was uploaded.`,
          data: { documentId: doc.id, rfqId: body.ownerId },
        });
      }
    }
    return { id: doc.id, originalName: doc.originalName, mimeType: doc.mimeType, sizeBytes: doc.sizeBytes };
  }

  @Get(':id/download-url')
  @ApiOperation({ summary: 'Mint a 15-minute signed download URL (authorized callers only)' })
  async downloadUrl(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    const doc = await this.mustAuthorize(user, id);
    const cfg = getConfig();
    const expiresAt = Date.now() + cfg.DOCUMENT_URL_TTL_MINUTES * 60000;
    const token = signDownloadToken(doc.id, expiresAt, cfg.DOCUMENT_SIGNING_SECRET);
    return { url: `/api/v1/documents/download?token=${token}`, expiresAt: new Date(expiresAt).toISOString() };
  }

  @Get('download')
  @ApiOperation({ summary: 'Download via signed temporary URL (15-min expiry, HMAC-verified)' })
  async download(@Query('token') token: string, @Req() req: Request & { res?: Response }) {
    if (!token) throw new BadRequestException({ code: 'TOKEN_INVALID', message: 'A download token is required.' });
    const cfg = getConfig();
    const verified = verifyDownloadToken(token, cfg.DOCUMENT_SIGNING_SECRET);
    if (!verified) {
      throw new ForbiddenException({ code: 'TOKEN_INVALID', message: 'This download link is invalid or has expired.' });
    }
    const doc = await this.prisma.document.findFirst({ where: { id: verified.documentId, deletedAt: null } });
    if (!doc) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Document not found.' });

    const res = (req as unknown as { res: Response }).res;
    const path = join(cfg.DOCUMENT_STORAGE_DIR, doc.storedFilename);
    try {
      await fs.access(path);
    } catch {
      throw new NotFoundException({ code: 'NOT_FOUND', message: 'Document file is missing.' });
    }
    await this.audit.log(AuditAction.document_downloaded, {
      ipAddress: req.ip, userAgent: req.headers['user-agent'], entityType: 'document', entityId: doc.id,
    });
    res.setHeader('Content-Type', doc.mimeType);
    res.setHeader('Content-Disposition', `attachment; filename="${encodeURIComponent(doc.originalName)}"`);
    res.setHeader('Content-Length', String(doc.sizeBytes));
    res.setHeader('Cache-Control', 'private, no-store');
    return res.sendFile(path);
  }

  /** Per-document authorization: owner-type membership re-checked server-side. */
  private async mustAuthorize(user: RequestUser, id: string) {
    const doc = await this.prisma.document.findFirst({ where: { id, deletedAt: null } });
    if (!doc) throw new NotFoundException({ code: 'NOT_FOUND', message: 'Document not found.' });
    await this.assertCanAccessOwner(user, doc.ownerType, doc.ownerId);
    return doc;
  }

  private async assertCanAccessOwner(user: RequestUser, ownerType: string, ownerId: string) {
    const isStaff = user.role === 'staff' || user.role === 'admin';
    if (isStaff) return;
    switch (ownerType) {
      case 'rfq': {
        const rfq = await this.prisma.rfq.findFirst({ where: { id: ownerId, deletedAt: null }, select: { buyerId: true } });
        if (!rfq || rfq.buyerId !== user.sub) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
        return;
      }
      case 'order': {
        const order = await this.prisma.order.findFirst({ where: { id: ownerId, deletedAt: null }, select: { buyerId: true } });
        if (!order || order.buyerId !== user.sub) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
        return;
      }
      case 'shipment': {
        const shipment = await this.prisma.shipment.findFirst({
          where: { id: ownerId, deletedAt: null }, select: { order: { select: { buyerId: true } } },
        });
        if (!shipment || shipment.order.buyerId !== user.sub) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
        return;
      }
      case 'support_ticket': {
        const ticket = await this.prisma.supportTicket.findFirst({ where: { id: ownerId, deletedAt: null }, select: { requesterId: true } });
        if (!ticket || ticket.requesterId !== user.sub) throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
        return;
      }
      default:
        throw new ForbiddenException({ code: 'FORBIDDEN', message: 'You do not have access to this resource.' });
    }
  }
}
