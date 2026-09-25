import '../../domain/entities/account.dart';

DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v as String);

class UserProfileDto {
  UserProfileDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        fullName = json['fullName'] as String? ?? '',
        phone = json['phone'] as String? ?? '',
        email = json['email'] as String?,
        companyId = json['companyId'] as String?;

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? companyId;

  UserProfile toEntity() => UserProfile(
      id: id, fullName: fullName, phone: phone, email: email, companyId: companyId);
}

class CompanyDto {
  CompanyDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String? ?? '',
        country = json['country'] as String?,
        city = json['city'] as String?,
        addressLine = json['addressLine'] as String?,
        taxId = json['taxId'] as String?;

  final String id;
  final String name;
  final String? country;
  final String? city;
  final String? addressLine;
  final String? taxId;

  Company toEntity() => Company(
      id: id, name: name, country: country, city: city, addressLine: addressLine, taxId: taxId);

  static Map<String, dynamic> toJson(Company c) => {
        'id': c.id,
        'name': c.name,
        'country': c.country,
        'city': c.city,
        'addressLine': c.addressLine,
        'taxId': c.taxId,
      };
}

class AddressDto {
  AddressDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        label = json['label'] as String? ?? '',
        lines = json['lines'] as String? ?? '',
        city = json['city'] as String?,
        country = json['country'] as String?,
        isDefault = json['isDefault'] as bool? ?? false;

  final String id;
  final String label;
  final String lines;
  final String? city;
  final String? country;
  final bool isDefault;

  Address toEntity() => Address(
      id: id, label: label, lines: lines, city: city, country: country, isDefault: isDefault);

  static Map<String, dynamic> toJson(Address a) => {
        'id': a.id,
        'label': a.label,
        'lines': a.lines,
        'city': a.city,
        'country': a.country,
        'isDefault': a.isDefault,
      };
}

class AppNotificationDto {
  AppNotificationDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        type = json['type'] as String? ?? 'general',
        title = json['title'] as String? ?? '',
        body = json['body'] as String? ?? '',
        at = _dt(json['at']) ?? DateTime.now(),
        read = json['read'] as bool? ?? false,
        deepLink = json['deepLink'] as String?;

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime at;
  final bool read;
  final String? deepLink;

  AppNotification toEntity() => AppNotification(
      id: id, type: type, title: title, body: body, at: at, read: read, deepLink: deepLink);
}

class ConversationSummaryDto {
  ConversationSummaryDto.fromJson(Map<String, dynamic> json)
      : scope = json['scope'] as String? ?? 'rfq',
        scopeId = json['scopeId'] as String? ?? '',
        title = json['title'] as String? ?? '',
        unreadCount = json['unreadCount'] as int? ?? 0,
        lastMessageAt = _dt(json['lastMessageAt']),
        lastMessagePreview = json['lastMessagePreview'] as String?;

  final String scope;
  final String scopeId;
  final String title;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;

  ConversationSummary toEntity() => ConversationSummary(
      scope: scope, scopeId: scopeId, title: title, unreadCount: unreadCount,
      lastMessageAt: lastMessageAt, lastMessagePreview: lastMessagePreview);
}

class ChatMessageDto {
  ChatMessageDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        body = json['body'] as String? ?? '',
        at = _dt(json['at']) ?? DateTime.now(),
        fromMe = json['fromMe'] as bool? ?? false,
        senderName = json['senderName'] as String?;

  final String id;
  final String body;
  final DateTime at;
  final bool fromMe;
  final String? senderName;

  ChatMessage toEntity() => ChatMessage(
      id: id, body: body, at: at, fromMe: fromMe, senderName: senderName);
}

class DocumentItemDto {
  DocumentItemDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        name = json['name'] as String? ?? '',
        category = json['category'] as String? ?? '',
        mimeType = json['mimeType'] as String?,
        sizeBytes = json['sizeBytes'] as int?,
        createdAt = _dt(json['createdAt']);

  final String id;
  final String name;
  final String category;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime? createdAt;

  DocumentItem toEntity() => DocumentItem(
      id: id, name: name, category: category, mimeType: mimeType,
      sizeBytes: sizeBytes, createdAt: createdAt);
}

class AuthTokensDto {
  AuthTokensDto.fromJson(Map<String, dynamic> json)
      : accessToken = json['accessToken'] as String,
        refreshToken = json['refreshToken'] as String,
        user = UserProfileDto.fromJson(json['user'] as Map<String, dynamic>);

  final String accessToken;
  final String refreshToken;
  final UserProfileDto user;
}
