import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../screens/account/account_screen.dart';
import '../screens/account/addresses_screen.dart';
import '../screens/account/company_screen.dart';
import '../screens/account/language_screen.dart';
import '../screens/account/privacy_screen.dart';
import '../screens/account/profile_screen.dart';
import '../screens/account/security_screen.dart';
import '../screens/account/support_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/contact/contact_screen.dart';
import '../screens/conversations/conversation_detail_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/documents/document_vault_screen.dart';
import '../screens/dropship/dropship_hub_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/not_found_screen.dart';
import '../screens/notifications/notification_list_screen.dart';
import '../screens/notifications/notification_prefs_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/orders/order_list_screen.dart';
import '../screens/private_label/private_label_flow_screen.dart';
import '../screens/private_label/private_label_list_screen.dart';
import '../screens/products/product_detail_screen.dart';
import '../screens/products/product_list_screen.dart';
import '../screens/quotations/quotation_detail_screen.dart';
import '../screens/quotations/quotation_list_screen.dart';
import '../screens/rfq/rfq_landing_screen.dart';
import '../screens/rfq/rfq_list_screen.dart';
import '../screens/rfq/rfq_result_screen.dart';
import '../screens/rfq/rfq_wizard_screen.dart';
import '../screens/rfq/smart_rfq_screen.dart';
import '../screens/search/global_search_screen.dart';
import '../screens/shipments/shipment_detail_screen.dart';
import '../screens/shipments/shipment_tracking_screen.dart';
import '../screens/shell_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/supplier/supplier_apply_screen.dart';
import '../screens/supplier/supplier_portal_screen.dart';

/// Deep-link contracts (see AndroidManifest.xml + Runner.entitlements):
/// - egt://product/:id, egt://rfq/:id, egt://order/:id, egt://shipment/:id
/// - https://eaglegoodstrading.com/app/<path>  (applinks; needs server-side
///   /.well-known/assetlinks.json + apple-app-site-association for /app/* —
///   flagged as needs-from-Sukh/server)

String? _mapDeepLink(Uri uri) {
  if (uri.scheme == 'egt') {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    if (id == null || id.isEmpty) return null;
    switch (uri.host) {
      case 'product':
        return '/products/$id';
      case 'rfq':
        return '/rfq/result/$id';
      case 'order':
        return '/orders/$id';
      case 'shipment':
        return '/shipments/$id';
    }
    return null;
  }
  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host == 'eaglegoodstrading.com' &&
      uri.pathSegments.isNotEmpty &&
      uri.pathSegments.first == 'app') {
    final rest = uri.pathSegments.skip(1).join('/');
    return '/$rest${uri.hasQuery ? '?${uri.query}' : ''}';
  }
  return null;
}

const _protectedPrefixes = [
  '/quotations',
  '/orders',
  '/documents',
  '/private-label',
  '/supplier',
  '/account',
  '/notifications',
  '/conversations',
  '/rfq/list',
];

bool _isProtected(String location) =>
    _protectedPrefixes.any((p) => location == p || location.startsWith('$p/'));

final routerProvider = Provider<GoRouter>((ref) {
  final loggedIn = ref.watch(isLoggedInProvider);

  return GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const NotFoundScreen(),
    redirect: (context, state) {
      // 1. Custom-scheme + applink deep links.
      final mapped = _mapDeepLink(state.uri);
      if (mapped != null && mapped != state.uri.toString()) return mapped;

      final location = state.uri.toString();
      final onAuthPage = location == '/login' || location == '/register';

      // 2. Auth guard.
      if (!loggedIn && _isProtected(location)) {
        return '/login?next=${Uri.encodeComponent(location)}';
      }
      if (loggedIn && onAuthPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
      GoRoute(path: '/contact', builder: (c, s) => const ContactScreen()),
      GoRoute(path: '/search', builder: (c, s) => const GlobalSearchScreen()),
      GoRoute(path: '/notifications', builder: (c, s) => const NotificationListScreen()),
      GoRoute(
          path: '/notifications/preferences',
          builder: (c, s) => const NotificationPrefsScreen()),
      GoRoute(
        path: '/conversations/:scope/:scopeId',
        builder: (c, s) => ConversationDetailScreen(
          scope: s.pathParameters['scope']!,
          scopeId: s.pathParameters['scopeId']!,
        ),
      ),
      GoRoute(path: '/quotations', builder: (c, s) => const QuotationListScreen()),
      GoRoute(
        path: '/quotations/:quotationId',
        builder: (c, s) =>
            QuotationDetailScreen(quotationId: s.pathParameters['quotationId']!),
      ),
      GoRoute(path: '/shipments/track', builder: (c, s) => const ShipmentTrackingScreen()),
      GoRoute(
        path: '/shipments/:shipmentId',
        builder: (c, s) =>
            ShipmentDetailScreen(shipmentId: s.pathParameters['shipmentId']!),
      ),
      GoRoute(path: '/documents', builder: (c, s) => const DocumentVaultScreen()),
      GoRoute(path: '/private-label', builder: (c, s) => const PrivateLabelListScreen()),
      GoRoute(path: '/private-label/new', builder: (c, s) => const PrivateLabelFlowScreen()),
      GoRoute(path: '/supplier', builder: (c, s) => const SupplierPortalScreen()),
      GoRoute(path: '/supplier/apply', builder: (c, s) => const SupplierApplyScreen()),
      GoRoute(path: '/dropship', builder: (c, s) => const DropshipHubScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
            GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/products', builder: (c, s) => const ProductListScreen()),
            GoRoute(
              path: '/products/:productId',
              builder: (c, s) =>
                  ProductDetailScreen(productId: s.pathParameters['productId']!),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/rfq', builder: (c, s) => const RfqLandingScreen()),
            GoRoute(path: '/rfq/new', builder: (c, s) => const RfqWizardScreen()),
            GoRoute(path: '/rfq/smart', builder: (c, s) => const SmartRfqScreen()),
            GoRoute(path: '/rfq/list', builder: (c, s) => const RfqListScreen()),
            GoRoute(
              path: '/rfq/result/:rfqId',
              builder: (c, s) => RfqResultScreen(rfqId: s.pathParameters['rfqId']!),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/orders', builder: (c, s) => const OrderListScreen()),
            GoRoute(
              path: '/orders/:orderId',
              builder: (c, s) => OrderDetailScreen(orderId: s.pathParameters['orderId']!),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/account', builder: (c, s) => const AccountScreen()),
            GoRoute(path: '/account/profile', builder: (c, s) => const ProfileScreen()),
            GoRoute(path: '/account/company', builder: (c, s) => const CompanyScreen()),
            GoRoute(path: '/account/addresses', builder: (c, s) => const AddressesScreen()),
            GoRoute(path: '/account/security', builder: (c, s) => const SecurityScreen()),
            GoRoute(path: '/account/privacy', builder: (c, s) => const PrivacyScreen()),
            GoRoute(path: '/account/language', builder: (c, s) => const LanguageScreen()),
            GoRoute(path: '/account/support', builder: (c, s) => const SupportScreen()),
          ]),
        ],
      ),
    ],
  );
});
