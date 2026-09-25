import '../../core/l10n/app_localizations.dart';
import '../../domain/entities/growth.dart';
import '../../domain/entities/trade.dart';

/// Localized display labels for domain status enums. Status keys themselves
/// are never rendered raw in the UI.

String rfqStatusLabel(RfqStatus status, AppLocalizations l10n) {
  switch (status) {
    case RfqStatus.draft:
      return l10n.rfqStatusDraft;
    case RfqStatus.submitted:
      return l10n.rfqStatusSubmitted;
    case RfqStatus.underReview:
      return l10n.rfqStatusUnderReview;
    case RfqStatus.quoted:
      return l10n.rfqStatusQuoted;
    case RfqStatus.closed:
      return l10n.rfqStatusClosed;
  }
}

String orderStatusLabel(OrderStatus status, AppLocalizations l10n) {
  switch (status) {
    case OrderStatus.confirmed:
      return l10n.orderStatusConfirmed;
    case OrderStatus.inProduction:
      return l10n.orderStatusInProduction;
    case OrderStatus.qualityCheck:
      return l10n.orderStatusQualityCheck;
    case OrderStatus.shipped:
      return l10n.orderStatusShipped;
    case OrderStatus.delivered:
      return l10n.orderStatusDelivered;
    case OrderStatus.cancelled:
      return l10n.orderStatusCancelled;
  }
}

String privateLabelStatusLabel(PrivateLabelStatus status, AppLocalizations l10n) {
  switch (status) {
    case PrivateLabelStatus.submitted:
      return l10n.plStatusSubmitted;
    case PrivateLabelStatus.underReview:
      return l10n.plStatusUnderReview;
    case PrivateLabelStatus.artworkPending:
      return l10n.plStatusArtworkPending;
    case PrivateLabelStatus.approved:
      return l10n.plStatusApproved;
    case PrivateLabelStatus.inProduction:
      return l10n.plStatusInProduction;
    case PrivateLabelStatus.closed:
      return l10n.plStatusClosed;
  }
}

String supplierAppStatusLabel(
    SupplierApplicationStatus status, AppLocalizations l10n) {
  switch (status) {
    case SupplierApplicationStatus.pendingReview:
      return l10n.supplierStatusPending;
    case SupplierApplicationStatus.approved:
      return l10n.supplierStatusApproved;
    case SupplierApplicationStatus.changesRequired:
      return l10n.supplierStatusChanges;
    case SupplierApplicationStatus.rejected:
      return l10n.supplierStatusRejected;
  }
}

/// Shipment status arrives from the backend as a plain string. Common
/// logistics keys are mapped to localized labels; anything unrecognized is
/// shown as the raw backend value rather than an invented label. Confirm the
/// exact key vocabulary against the backend API before release.
String shipmentStatusLabel(String status, AppLocalizations l10n) {
  switch (status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_')) {
    case 'pending':
    case 'booked':
      return l10n.shipmentStatusPending;
    case 'in_transit':
    case 'shipped':
      return l10n.shipmentStatusInTransit;
    case 'out_for_delivery':
      return l10n.shipmentStatusOutForDelivery;
    case 'delivered':
      return l10n.shipmentStatusDelivered;
    case 'delayed':
    case 'on_hold':
      return l10n.shipmentStatusDelayed;
    case 'exception':
      return l10n.shipmentStatusException;
    case 'cancelled':
    case 'canceled':
      return l10n.shipmentStatusCancelled;
    default:
      return status;
  }
}
