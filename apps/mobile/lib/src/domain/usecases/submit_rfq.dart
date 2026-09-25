import '../entities/trade.dart';
import '../repositories/repositories.dart';

/// Submits an RFQ draft. Resolves ONLY after backend confirmation —
/// callers must not report success earlier (no false success offline).
class SubmitRfq {
  SubmitRfq(this._repo);
  final RfqRepository _repo;

  Future<Rfq> call(RfqDraft draft) => _repo.submit(draft);
}
