import { canTransitionRfq, RFQ_TRANSITIONS } from '../../src/modules/rfqs/rfq-state-machine';
import { RfqStatus } from '@prisma/client';

describe('RFQ state machine', () => {
  it('allows the full happy path in order', () => {
    const path: RfqStatus[] = [
      'submitted', 'under_review', 'sourcing', 'supplier_matched', 'sample_discussion',
      'quotation_ready', 'buyer_action_required', 'approved', 'order_processing', 'completed',
    ];
    for (let i = 0; i < path.length - 1; i++) {
      expect(canTransitionRfq(path[i], path[i + 1])).toBe(true);
    }
  });

  it('rejects illegal jumps (e.g. submitted straight to approved)', () => {
    expect(canTransitionRfq('submitted', 'approved')).toBe(false);
    expect(canTransitionRfq('submitted', 'quotation_ready')).toBe(false);
    expect(canTransitionRfq('sourcing', 'approved')).toBe(false);
    expect(canTransitionRfq('completed', 'sourcing')).toBe(false);
  });

  it('treats completed and closed as terminal', () => {
    expect(RFQ_TRANSITIONS.completed).toEqual([]);
    expect(RFQ_TRANSITIONS.closed).toEqual([]);
  });

  it('allows early cancellation to closed but never reopens it', () => {
    expect(canTransitionRfq('submitted', 'closed')).toBe(true);
    expect(canTransitionRfq('under_review', 'closed')).toBe(true);
    expect(canTransitionRfq('closed', 'submitted')).toBe(false);
  });

  it('lets the buyer send the RFQ back to sourcing from buyer_action_required', () => {
    expect(canTransitionRfq('buyer_action_required', 'sourcing')).toBe(true);
  });
});
