import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hand-rolled localization (no codegen step). `lib/l10n/app_en.arb` is the
/// source of truth; `app_pa.arb` / `app_hi.arb` are stubs that fall back to
/// English per-key until professionally translated.
///
/// Usage: `context.l10n.homeHeroTitle`.
class AppLocalizations {
  AppLocalizations._(this._strings);

  final Map<String, String> _strings;

  static const supportedLocales = [Locale('en'), Locale('pa'), Locale('hi')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  String _t(String key) => _strings[key] ?? '⟦$key⟧';

  /// Parameterized lookup, e.g. tr('rfq_step', {'current':'1','total':'12'}).
  String tr(String key, [Map<String, String> args = const {}]) {
    var s = _t(key);
    args.forEach((k, v) => s = s.replaceAll('{$k}', v));
    return s;
  }

  // --- app ---
  String get appName => _t('app_name');
  String get appTagline => _t('app_tagline');
  String get splashTagline => _t('splash_tagline');

  // --- nav ---
  String get navHome => _t('nav_home');
  String get navProducts => _t('nav_products');
  String get navRfq => _t('nav_rfq');
  String get navOrders => _t('nav_orders');
  String get navAccount => _t('nav_account');

  // --- actions ---
  String get actionRetry => _t('action_retry');
  String get actionCancel => _t('action_cancel');
  String get actionClose => _t('action_close');
  String get actionSave => _t('action_save');
  String get actionSubmit => _t('action_submit');
  String get actionNext => _t('action_next');
  String get actionBack => _t('action_back');
  String get actionContinue => _t('action_continue');
  String get actionDone => _t('action_done');
  String get actionSearch => _t('action_search');
  String get actionShare => _t('action_share');
  String get actionDownload => _t('action_download');
  String get actionViewAll => _t('action_view_all');
  String get actionLearnMore => _t('action_learn_more');
  String get actionTrack => _t('action_track');
  String get actionClear => _t('action_clear');
  String get actionEdit => _t('action_edit');
  String get actionConfirm => _t('action_confirm');
  String get actionSend => _t('action_send');
  String get actionCall => _t('action_call');
  String get actionWhatsapp => _t('action_whatsapp');
  String get actionLogout => _t('action_logout');
  String get actionSignIn => _t('action_sign_in');
  String get actionCreateAccount => _t('action_create_account');
  String get commonRequired => _t('common_required');

  String get actionDelete => _t('action_delete');

  // --- errors / empty ---
  String get errorOffline => _t('error_offline');
  String get errorNetwork => _t('error_network');
  String get errorTimeout => _t('error_timeout');
  String get errorUnauthorized => _t('error_unauthorized');
  String get errorForbidden => _t('error_forbidden');
  String get errorNotFound => _t('error_not_found');
  String get errorValidation => _t('error_validation');
  String get errorConflict => _t('error_conflict');
  String get errorServer => _t('error_server');
  String get errorGeneric => _t('error_generic');
  String get errorCancelled => _t('error_cancelled');
  String get emptyTitle => _t('empty_title');
  String get emptyBody => _t('empty_body');

  // --- home ---
  String get homeWelcome => _t('home_welcome');
  String get homeActiveRfqs => _t('home_active_rfqs');
  String get homeOpenOrders => _t('home_open_orders');
  String get homeLatestRfqs => _t('home_latest_rfqs');
  String get homeTrackShipment => _t('home_track_shipment');
  String get actionNewRfq => _t('action_new_rfq');
  String get rfqEmptyTitle => _t('rfq_empty_title');
  String get homeHeroTitle => _t('home_hero_title');
  String get homeHeroSubtitle => _t('home_hero_subtitle');
  String get homeStartRfq => _t('home_start_rfq');
  String get homeExploreProducts => _t('home_explore_products');
  String get homeSectionQuickRfq => _t('home_section_quick_rfq');
  String get homeSectionPopular => _t('home_section_popular');
  String get homeSectionCategories => _t('home_section_categories');
  String get homeSectionPrivateLabel => _t('home_section_private_label');
  String get homeSectionSourcing => _t('home_section_sourcing');
  String get homeSectionWhy => _t('home_section_why');
  String get homeSectionSupplier => _t('home_section_supplier');
  String get homeSectionTracking => _t('home_section_tracking');
  String get homeSectionFeatured => _t('home_section_featured');
  String get homeSectionContact => _t('home_section_contact');
  String get homePrivateLabelTitle => _t('home_private_label_title');
  String get homePrivateLabelBody => _t('home_private_label_body');
  String get homePrivateLabelCta => _t('home_private_label_cta');
  String get homeSourcingTitle => _t('home_sourcing_title');
  String get homeSourcingBody => _t('home_sourcing_body');
  String get homeSourcingCta => _t('home_sourcing_cta');
  String get homeWhyTitle => _t('home_why_title');
  String get homeSupplierTitle => _t('home_supplier_title');
  String get homeSupplierBody => _t('home_supplier_body');
  String get homeSupplierCta => _t('home_supplier_cta');
  String get homeTrackingHint => _t('home_tracking_hint');
  String get homeRegisteredBusiness => _t('home_registered_business');
  String get homeContactCall => _t('home_contact_call');
  String get homeContactWhatsapp => _t('home_contact_whatsapp');
  String get homeContactEnquiry => _t('home_contact_enquiry');

  // --- products ---
  String get productsTitle => _t('products_title');
  String get productsSearchHint => _t('products_search_hint');
  String get productsFilters => _t('products_filters');
  String get productsSort => _t('products_sort');
  String get productsSortName => _t('products_sort_name');
  String get productsSortCategory => _t('products_sort_category');
  String get productsNoResults => _t('products_no_results');
  String get productsRequestQuote => _t('products_request_quote');
  String productsResults(int count) => tr('products_results', {'count': '$count'});
  String get productSpecs => _t('product_specs');
  String get productMoq => _t('product_moq');
  String get productPackaging => _t('product_packaging');
  String get productCustomization => _t('product_customization');
  String get productPrivateLabel => _t('product_private_label');
  String get productPrivateLabelBody => _t('product_private_label_body');
  String get productDocuments => _t('product_documents');
  String get productRequest => _t('product_request');
  String get productAddToRfq => _t('product_add_to_rfq');
  String get productAddedToRfq => _t('product_added_to_rfq');
  String get productShare => _t('product_share');

  // --- RFQ ---
  String get rfqTitle => _t('rfq_title');
  String get rfqNew => _t('rfq_new');
  String get rfqSmart => _t('rfq_smart');
  String get rfqMyRfqs => _t('rfq_my_rfqs');
  String get rfqLandingBody => _t('rfq_landing_body');
  String rfqStep(int current, int total) =>
      tr('rfq_step', {'current': '$current', 'total': '$total'});
  String get rfqStepProduct => _t('rfq_step_product');
  String get rfqStepQuantity => _t('rfq_step_quantity');
  String get rfqStepPackaging => _t('rfq_step_packaging');
  String get rfqStepPrivateLabel => _t('rfq_step_private_label');
  String get rfqStepDestination => _t('rfq_step_destination');
  String get rfqStepPort => _t('rfq_step_port');
  String get rfqStepIncoterm => _t('rfq_step_incoterm');
  String get rfqStepSpecs => _t('rfq_step_specs');
  String get rfqStepDocuments => _t('rfq_step_documents');
  String get rfqStepNotes => _t('rfq_step_notes');
  String get rfqStepReview => _t('rfq_step_review');
  String get rfqStepSubmit => _t('rfq_step_submit');
  String get rfqProductLabel => _t('rfq_product_label');
  String get rfqProductHint => _t('rfq_product_hint');
  String get rfqProductCustom => _t('rfq_product_custom');
  String get rfqQtyLabel => _t('rfq_qty_label');
  String get rfqQtyHint => _t('rfq_qty_hint');
  String get rfqUnitLabel => _t('rfq_unit_label');
  String get rfqPackagingLabel => _t('rfq_packaging_label');
  String get rfqPackagingHint => _t('rfq_packaging_hint');
  String get rfqPrivateLabelLabel => _t('rfq_private_label_label');
  String get rfqYes => _t('rfq_yes');
  String get rfqNo => _t('rfq_no');
  String get rfqCountryLabel => _t('rfq_country_label');
  String get rfqPortLabel => _t('rfq_port_label');
  String get rfqIncotermLabel => _t('rfq_incoterm_label');
  String get incotermExw => _t('incoterm_exw');
  String get incotermFob => _t('incoterm_fob');
  String get incotermCif => _t('incoterm_cif');
  String get incotermDdp => _t('incoterm_ddp');
  String get incotermOther => _t('incoterm_other');
  String get rfqSpecsLabel => _t('rfq_specs_label');
  String get rfqSpecsHint => _t('rfq_specs_hint');
  String get rfqDocumentsLabel => _t('rfq_documents_label');
  String get rfqDocumentsHint => _t('rfq_documents_hint');
  String get rfqDocumentsAdd => _t('rfq_documents_add');
  String get rfqNotesLabel => _t('rfq_notes_label');
  String get rfqNotesHint => _t('rfq_notes_hint');
  String get rfqReviewTitle => _t('rfq_review_title');
  String get rfqSubmitCta => _t('rfq_submit_cta');
  String get rfqSubmitting => _t('rfq_submitting');
  String get rfqOfflineBlocked => _t('rfq_offline_blocked');
  String get rfqValidationRequired => _t('rfq_validation_required');
  String get rfqDiscard => _t('rfq_discard');
  String get rfqResultTitle => _t('rfq_result_title');
  String get rfqResultBody => _t('rfq_result_body');
  String get rfqResultId => _t('rfq_result_id');
  String get rfqResultSubmittedOn => _t('rfq_result_submitted_on');
  String get rfqResultProduct => _t('rfq_result_product');
  String get rfqResultQuantity => _t('rfq_result_quantity');
  String get rfqResultDestination => _t('rfq_result_destination');
  String get rfqResultStatus => _t('rfq_result_status');
  String get rfqResultAssignee => _t('rfq_result_assignee');
  String get rfqResultUnassigned => _t('rfq_result_unassigned');
  String get rfqStatusDraft => _t('rfq_status_draft');
  String get rfqStatusSubmitted => _t('rfq_status_submitted');
  String get rfqStatusUnderReview => _t('rfq_status_under_review');
  String get rfqStatusQuoted => _t('rfq_status_quoted');
  String get rfqStatusClosed => _t('rfq_status_closed');
  String get rfqResultNextStep => _t('rfq_result_next_step');
  String get rfqResultNextStepBody => _t('rfq_result_next_step_body');
  String get rfqResultTrack => _t('rfq_result_track');

  // --- smart RFQ ---
  String get smartTitle => _t('smart_title');
  String get smartHint => _t('smart_hint');
  String get smartExample => _t('smart_example');
  String get smartAnalyzing => _t('smart_analyzing');
  String get smartNotUnderstood => _t('smart_not_understood');
  String get smartConfirmTitle => _t('smart_confirm_title');
  String get smartConfirmBody => _t('smart_confirm_body');
  String get smartProduct => _t('smart_product');
  String get smartQuantity => _t('smart_quantity');
  String get smartDestination => _t('smart_destination');
  String get smartLowConfidence => _t('smart_low_confidence');
  String get smartUseAsIs => _t('smart_use_as_is');
  String get smartStartOver => _t('smart_start_over');

  // --- dashboard ---
  String get dashboardTitle => _t('dashboard_title');
  String get dashboardActiveRfqs => _t('dashboard_active_rfqs');
  String get dashboardQuotations => _t('dashboard_quotations');
  String get dashboardOrders => _t('dashboard_orders');
  String get dashboardShipments => _t('dashboard_shipments');
  String get dashboardDocuments => _t('dashboard_documents');
  String get dashboardSaved => _t('dashboard_saved');
  String get dashboardJourney => _t('dashboard_journey');
  String get dashboardConversations => _t('dashboard_conversations');

  // --- quotations ---
  String get quoteValidity => _t('quote_validity');
  String get quoteLeadTime => _t('quote_lead_time');
  String get quotePaymentTerms => _t('quote_payment_terms');
  String get quoteAccept => _t('quote_accept');
  String get quoteAcceptTitle => _t('quote_accept_title');
  String get quoteAcceptBody => _t('quote_accept_body');
  String get quoteRequestRevision => _t('quote_request_revision');
  String get quoteRevisionTitle => _t('quote_revision_title');
  String get quoteRevisionHint => _t('quote_revision_hint');
  String get quoteAskEgt => _t('quote_ask_egt');
  String get quoteStatusPending => _t('quote_status_pending');
  String get quoteStatusAccepted => _t('quote_status_accepted');
  String get quoteStatusRevisionRequested => _t('quote_status_revision_requested');
  String get quoteStatusExpired => _t('quote_status_expired');

  // --- orders / shipments ---
  String get ordersTitle => _t('orders_title');
  String get ordersEmpty => _t('orders_empty');
  String get orderStatusConfirmed => _t('order_status_confirmed');
  String get orderStatusInProduction => _t('order_status_in_production');
  String get orderStatusQualityCheck => _t('order_status_quality_check');
  String get orderStatusShipped => _t('order_status_shipped');
  String get orderStatusDelivered => _t('order_status_delivered');
  String get orderStatusCancelled => _t('order_status_cancelled');
  String get shipmentTrackTitle => _t('shipment_track_title');
  String get shipmentTrackHint => _t('shipment_track_hint');
  String get shipmentTrackCta => _t('shipment_track_cta');
  String get shipmentNotFound => _t('shipment_not_found');
  String get shipmentLastVerified => _t('shipment_last_verified');
  String get shipmentNoCarrier => _t('shipment_no_carrier');
  String get shipmentStatusPending => _t('shipment_status_pending');
  String get shipmentStatusInTransit => _t('shipment_status_in_transit');
  String get shipmentStatusOutForDelivery =>
      _t('shipment_status_out_for_delivery');
  String get shipmentStatusDelivered => _t('shipment_status_delivered');
  String get shipmentStatusDelayed => _t('shipment_status_delayed');
  String get shipmentStatusException => _t('shipment_status_exception');
  String get shipmentStatusCancelled => _t('shipment_status_cancelled');

  // --- documents ---
  String get docsTitle => _t('docs_title');
  String get docsEmpty => _t('docs_empty');
  String get docsPreview => _t('docs_preview');
  String get docsDownload => _t('docs_download');

  // --- private label ---
  String get plTitle => _t('pl_title');
  String get plNew => _t('pl_new');
  String get plStepProduct => _t('pl_step_product');
  String get plStepBrand => _t('pl_step_brand');
  String get plStepPackaging => _t('pl_step_packaging');
  String get plStepSize => _t('pl_step_size');
  String get plStepLabel => _t('pl_step_label');
  String get plStepQuantity => _t('pl_step_quantity');
  String get plStepDestination => _t('pl_step_destination');
  String get plStepArtwork => _t('pl_step_artwork');
  String get plStepSubmit => _t('pl_step_submit');
  String get plBrandHint => _t('pl_brand_hint');
  String get plArtworkHint => _t('pl_artwork_hint');
  String get plProductHint => _t('pl_product_hint');
  String get plQuantityHint => _t('pl_quantity_hint');
  String get plPackagingHint => _t('pl_packaging_hint');
  String get plUploadLogo => _t('pl_upload_logo');
  String get plSubmitTitle => _t('pl_submit_title');
  String get plSubmitBody => _t('pl_submit_body');
  String get plResultTitle => _t('pl_result_title');
  String get plResultBody => _t('pl_result_body');
  String get plStatusSubmitted => _t('pl_status_submitted');
  String get plStatusUnderReview => _t('pl_status_under_review');
  String get plStatusArtworkPending => _t('pl_status_artwork_pending');
  String get plStatusApproved => _t('pl_status_approved');
  String get plStatusInProduction => _t('pl_status_in_production');
  String get plStatusClosed => _t('pl_status_closed');

  // --- supplier ---
  String get supplierTitle => _t('supplier_title');
  String get supplierApply => _t('supplier_apply');
  String get supplierCompany => _t('supplier_company');
  String get supplierContactPerson => _t('supplier_contact_person');
  String get supplierPhone => _t('supplier_phone');
  String get supplierCertifications => _t('supplier_certifications');
  String get supplierProductDetails => _t('supplier_product_details');
  String get supplierProductDetailsHint => _t('supplier_product_details_hint');
  String get supplierNoAutopublish => _t('supplier_no_autopublish');
  String get supplierStatusPending => _t('supplier_status_pending');
  String get supplierStatusApproved => _t('supplier_status_approved');
  String get supplierStatusChanges => _t('supplier_status_changes');
  String get supplierStatusRejected => _t('supplier_status_rejected');
  String get supplierApplicationsTitle => _t('supplier_applications_title');
  String get supplierStatusLabel => _t('supplier_status_label');
  String get supplierSubmittedOn => _t('supplier_submitted_on');

  // --- dropship ---
  String get dropshipTitle => _t('dropship_title');
  String get dropshipVerified => _t('dropship_verified');
  String get dropshipSupplier => _t('dropship_supplier');
  String get dropshipUnavailable => _t('dropship_unavailable');
  String get dropshipEmpty => _t('dropship_empty');

  // --- search ---
  String get searchTitle => _t('search_title');
  String get searchHint => _t('search_hint');
  String get searchScoped => _t('search_scoped');
  String get searchSectionProducts => _t('search_section_products');
  String get searchSectionRfqs => _t('search_section_rfqs');
  String get searchSectionOrders => _t('search_section_orders');
  String get searchSectionDocuments => _t('search_section_documents');
  String get searchNoResults => _t('search_no_results');

  // --- notifications ---
  String get notifTitle => _t('notif_title');
  String get notifPrefs => _t('notif_prefs');
  String get notifMarkAllRead => _t('notif_mark_all_read');
  String get notifEmpty => _t('notif_empty');
  String get notifRfq => _t('notif_rfq');
  String get notifQuotation => _t('notif_quotation');
  String get notifOrder => _t('notif_order');
  String get notifShipment => _t('notif_shipment');
  String get notifMessages => _t('notif_messages');
  String get notifMarketing => _t('notif_marketing');

  // --- conversations ---
  String get convTitle => _t('conv_title');
  String get convEmpty => _t('conv_empty');
  String get convHint => _t('conv_hint');
  String get convSend => _t('conv_send');
  String get convRfq => _t('conv_rfq');
  String get convOrder => _t('conv_order');
  String get convAttachments => _t('conv_attachments');

  // --- contact ---
  String get contactTitle => _t('contact_title');
  String get contactCall => _t('contact_call');
  String get contactWhatsapp => _t('contact_whatsapp');
  String get contactAddress => _t('contact_address');
  String get contactHours => _t('contact_hours');
  String get contactEnquiryTitle => _t('contact_enquiry_title');
  String get contactName => _t('contact_name');
  String get contactPhone => _t('contact_phone');
  String get contactMessage => _t('contact_message');
  String get contactSent => _t('contact_sent');
  String get contactRfqCta => _t('contact_rfq_cta');
  String get contactProductInterest => _t('contact_product_interest');

  // --- account ---
  String get accountTitle => _t('account_title');
  String get accountProfile => _t('account_profile');
  String get accountCompany => _t('account_company');
  String get accountAddresses => _t('account_addresses');
  String get accountMyRfqs => _t('account_my_rfqs');
  String get accountQuotations => _t('account_quotations');
  String get accountOrders => _t('account_orders');
  String get accountShipments => _t('account_shipments');
  String get accountDocuments => _t('account_documents');
  String get accountSaved => _t('account_saved');
  String get accountNotifications => _t('account_notifications');
  String get accountSecurity => _t('account_security');
  String get accountPrivacy => _t('account_privacy');
  String get accountSupport => _t('account_support');
  String get accountLogout => _t('account_logout');
  String get languageSystem => _t('language_system');
  String get languageComingSoon => _t('language_coming_soon');
  String get accountLanguage => _t('account_language');
  String get accountEmail => _t('account_email');
  String get accountCity => _t('account_city');
  String get accountCountry => _t('account_country');
  String get accountAddressLabel => _t('account_address_label');
  String get accountAddressLines => _t('account_address_lines');
  String get accountTaxId => _t('account_tax_id');
  String get accountNewPassword => _t('account_new_password');
  String get accountConfirmPassword => _t('account_confirm_password');
  String get accountLogoutTitle => _t('account_logout_title');
  String get accountLogoutBody => _t('account_logout_body');
  String get accountPasswordChanged => _t('account_password_changed');
  String get accountProfileSaved => _t('account_profile_saved');
  String get accountSetDefault => _t('account_set_default');
  String get accountAddAddress => _t('account_add_address');
  String get accountDeleteAddress => _t('account_delete_address');
  String get accountSupportBody => _t('account_support_body');

  // --- security / privacy ---
  String get securityTitle => _t('security_title');
  String get securityChangePassword => _t('security_change_password');
  String get securityBiometric => _t('security_biometric');
  String get securityBiometricBody => _t('security_biometric_body');
  String get securityBiometricUnavailable => _t('security_biometric_unavailable');
  String get securityLogoutAll => _t('security_logout_all');
  String get securityLogoutAllTitle => _t('security_logout_all_title');
  String get securityLogoutAllBody => _t('security_logout_all_body');
  String get privacyTitle => _t('privacy_title');
  String get privacyDataRequest => _t('privacy_data_request');
  String get privacyDeleteAccount => _t('privacy_delete_account');
  String get privacyDeleteTitle => _t('privacy_delete_title');
  String get privacyDeleteBody => _t('privacy_delete_body');
  String get privacyBody => _t('privacy_body');

  // --- auth ---
  String get authSignIn => _t('auth_sign_in');
  String get authCreateAccount => _t('auth_create_account');
  String get authPhone => _t('auth_phone');
  String get authPassword => _t('auth_password');
  String get authFullName => _t('auth_full_name');
  String get authCompany => _t('auth_company');
  String get authSignInCta => _t('auth_sign_in_cta');
  String get authNoAccount => _t('auth_no_account');
  String get authHaveAccount => _t('auth_have_account');
  String get authGuestContinue => _t('auth_guest_continue');
  String get authBiometricUnlock => _t('auth_biometric_unlock');
  String get authSessionExpired => _t('auth_session_expired');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final enJson = await rootBundle.loadString('lib/l10n/app_en.arb');
    final Map<String, String> strings = Map<String, String>.from(json.decode(enJson) as Map)
      ..removeWhere((k, _) => k.startsWith('@@') || k.startsWith('_'));
    if (locale.languageCode != 'en') {
      try {
        final locJson = await rootBundle.loadString('lib/l10n/app_${locale.languageCode}.arb');
        final overlay = Map<String, String>.from(json.decode(locJson) as Map)
          ..removeWhere((k, _) => k.startsWith('@@') || k.startsWith('_'));
        overlay.removeWhere((_, v) => v.isEmpty);
        strings.addAll(overlay); // missing keys fall back to English
      } catch (_) {
        // Missing locale file -> full English fallback.
      }
    }
    return AppLocalizations._(strings);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
