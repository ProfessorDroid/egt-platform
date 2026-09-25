import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../company/company_info.dart';

/// External link helpers: tel:, WhatsApp, maps, generic https.
class LaunchHelper {
  LaunchHelper._();

  static Future<bool> callPhone() =>
      launchUrl(Uri.parse(CompanyInfo.phoneTel), mode: LaunchMode.externalApplication);

  static Future<bool> openWhatsApp([String? text]) {
    final uri = Uri.parse(CompanyInfo.whatsAppUrl).replace(
      queryParameters: text == null ? null : {'text': text},
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openMaps() {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(CompanyInfo.address)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openUrl(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  static Future<void> shareText(String text, {String? subject}) =>
      Share.share(text, subject: subject);
}
