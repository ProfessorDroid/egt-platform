import { RfqStatus } from '@prisma/client';

/**
 * Strict server-side RFQ lifecycle. Every transition is validated here;
 * illegal jumps are rejected with 422. Terminal states: completed, closed.
 */
export const RFQ_TRANSITIONS: Record<RfqStatus, RfqStatus[]> = {
  submitted: ['under_review', 'closed'],
  under_review: ['sourcing', 'closed'],
  sourcing: ['supplier_matched', 'closed'],
  supplier_matched: ['sample_discussion'],
  sample_discussion: ['quotation_ready'],
  quotation_ready: ['buyer_action_required'],
  buyer_action_required: ['approved', 'sourcing'], // buyer may ask to re-source
  approved: ['order_processing'],
  order_processing: ['completed'],
  completed: [],
  closed: [],
};

export function canTransitionRfq(from: RfqStatus, to: RfqStatus): boolean {
  return RFQ_TRANSITIONS[from]?.includes(to) ?? false;
}

export function isTerminalRfq(status: RfqStatus): boolean {
  return status === 'completed' || status === 'closed';
}
