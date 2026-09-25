/// Account domain: profile, company, addresses, notifications, conversations, documents.

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phone,
    this.email,
    this.companyId,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String? companyId;
}

class Company {
  const Company({
    required this.id,
    required this.name,
    this.country,
    this.city,
    this.addressLine,
    this.taxId,
  });

  final String id;
  final String name;
  final String? country;
  final String? city;
  final String? addressLine;
  final String? taxId;
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.lines,
    this.city,
    this.country,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String lines;
  final String? city;
  final String? country;
  final bool isDefault;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.at,
    this.read = false,
    this.deepLink,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime at;
  final bool read;
  final String? deepLink;
}

class NotificationPreferences {
  const NotificationPreferences({
    this.rfqUpdates = true,
    this.quotationUpdates = true,
    this.orderUpdates = true,
    this.shipmentUpdates = true,
    this.messages = true,
    this.marketing = false,
  });

  final bool rfqUpdates;
  final bool quotationUpdates;
  final bool orderUpdates;
  final bool shipmentUpdates;
  final bool messages;
  final bool marketing;

  NotificationPreferences copyWith({
    bool? rfqUpdates,
    bool? quotationUpdates,
    bool? orderUpdates,
    bool? shipmentUpdates,
    bool? messages,
    bool? marketing,
  }) =>
      NotificationPreferences(
        rfqUpdates: rfqUpdates ?? this.rfqUpdates,
        quotationUpdates: quotationUpdates ?? this.quotationUpdates,
        orderUpdates: orderUpdates ?? this.orderUpdates,
        shipmentUpdates: shipmentUpdates ?? this.shipmentUpdates,
        messages: messages ?? this.messages,
        marketing: marketing ?? this.marketing,
      );

  Map<String, dynamic> toJson() => {
        'rfqUpdates': rfqUpdates,
        'quotationUpdates': quotationUpdates,
        'orderUpdates': orderUpdates,
        'shipmentUpdates': shipmentUpdates,
        'messages': messages,
        'marketing': marketing,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        rfqUpdates: json['rfqUpdates'] as bool? ?? true,
        quotationUpdates: json['quotationUpdates'] as bool? ?? true,
        orderUpdates: json['orderUpdates'] as bool? ?? true,
        shipmentUpdates: json['shipmentUpdates'] as bool? ?? true,
        messages: json['messages'] as bool? ?? true,
        marketing: json['marketing'] as bool? ?? false,
      );
}

/// Conversation thread scoped to one RFQ or order — there is no global chat.
class ConversationSummary {
  const ConversationSummary({
    required this.scope,
    required this.scopeId,
    required this.title,
    this.unreadCount = 0,
    this.lastMessageAt,
    this.lastMessagePreview,
  });

  final String scope; // 'rfq' | 'order'
  final String scopeId;
  final String title;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.body,
    required this.at,
    required this.fromMe,
    this.senderName,
  });

  final String id;
  final String body;
  final DateTime at;
  final bool fromMe;
  final String? senderName;
}

class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.name,
    required this.category,
    this.mimeType,
    this.sizeBytes,
    this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final String? mimeType;
  final int? sizeBytes;
  final DateTime? createdAt;

  /// Downloads go through backend-issued signed URLs only — never raw paths.
  bool get isPreviewable =>
      mimeType != null &&
      (mimeType!.startsWith('image/') || mimeType == 'application/pdf');
}
