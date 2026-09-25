import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import { Request, Response } from 'express';

export interface ErrorEnvelope {
  code: string;
  message: string;
  details?: unknown;
}

/**
 * Consistent error envelope {code, message, details}. Friendly messages only —
 * never stack traces or internal error internals leak to clients.
 */
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let envelope: ErrorEnvelope = { code: 'INTERNAL_ERROR', message: 'Something went wrong. Please try again.' };

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();
      if (typeof body === 'object' && body !== null && 'code' in body) {
        envelope = {
          code: String((body as Record<string, unknown>).code ?? 'ERROR'),
          message: String((body as Record<string, unknown>).message ?? exception.message),
          details: (body as Record<string, unknown>).details,
        };
      } else if (Array.isArray((body as Record<string, unknown>)?.message)) {
        // class-validator errors
        envelope = {
          code: 'VALIDATION_ERROR',
          message: 'Please check the highlighted fields and try again.',
          details: (body as Record<string, unknown>).message,
        };
      } else {
        envelope = { code: httpCodeToName(status), message: friendlyMessage(status) };
      }
    }

    if (process.env.NODE_ENV !== 'production') {
      // eslint-disable-next-line no-console
      console.error(`[${req.method} ${req.path}]`, exception);
    }
    res.status(status).json(envelope);
  }
}

function httpCodeToName(status: number): string {
  switch (status) {
    case 400: return 'BAD_REQUEST';
    case 401: return 'UNAUTHENTICATED';
    case 403: return 'FORBIDDEN';
    case 404: return 'NOT_FOUND';
    case 409: return 'CONFLICT';
    case 422: return 'UNPROCESSABLE';
    case 429: return 'RATE_LIMITED';
    default: return status >= 500 ? 'INTERNAL_ERROR' : 'ERROR';
  }
}

function friendlyMessage(status: number): string {
  switch (status) {
    case 400: return 'The request could not be understood.';
    case 401: return 'Please sign in to continue.';
    case 403: return 'You do not have access to this resource.';
    case 404: return 'The requested item was not found.';
    case 409: return 'This action conflicts with the current state.';
    case 422: return 'This action cannot be completed right now.';
    case 429: return 'Too many requests. Please wait a moment and try again.';
    default: return 'Something went wrong. Please try again.';
  }
}
