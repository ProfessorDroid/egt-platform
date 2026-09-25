/// Verified company facts from the Phase 0 site audit (`docs/site-audit.md`).
///
/// Rules enforced here:
/// - NO founding-year claim anywhere (logo says EST. 2024, contact page says
///   "since 2016" — conflicting; awaiting Sukh's decision).
/// - NO published email address (none found on the live site).
/// - Registration pills show the word "Registered" only — never numbers.
/// - Stats tiles use the site's exact wording; no named countries.
class CompanyInfo {
  CompanyInfo._();

  static const String name = 'Eagle Goods Trading Co.';
  static const String shortName = 'EGT';
  static const String tagline = 'Made in Punjab. Ready for the World.';
  static const String heroTitle = 'Tell Us What You Need — We Source It.';
  static const String heroSubtitle =
      'Quality products, global standard — commercial sourcing, OEM manufacturing '
      'and containerized export, managed end to end from India.';

  static const String phoneDisplay = '+91 9876609948';
  static const String phoneTel = 'tel:+919876609948';
  static const String whatsAppUrl = 'https://wa.me/919876609948';
  // NOTE: the site shows "WhatsApp Available" but no separate WhatsApp number;
  // the phone number is used pending confirmation.

  static const String address = 'Village Gill, District Ferozepur, Punjab 142060, India';

  static const String hoursWeekday = 'Monday – Friday: 9:00 AM – 6:00 PM IST';
  static const String hoursSaturday = 'Saturday: 10:00 AM – 4:00 PM IST';
  static const String hoursSunday = 'Sunday: Closed';

  static const String founderName = 'Jarnail Singh';

  /// "Registered Business" pills — words only, no numbers (per Sukh).
  static const List<String> registrationPills = [
    'GST Registered',
    'IEC (DGFT) Registered',
    'MSME (Udyam) Registered',
    'GeM Registered',
  ];

  /// Homepage stats tiles — exact site wording.
  static const List<(String value, String label)> stats = [
    ('Pan-India', 'Supplier Network'),
    ('Multiple Countries', 'Global Export Reach'),
    ('10+', 'Product Categories'),
    ('End-to-End', 'Sourcing & Export Support'),
  ];

  /// 12 featured sourcing sectors (homepage tiles). These are sourcing sectors,
  /// not listed inventory — never present them as products.
  static const List<String> featuredSectors = [
    'Apparel & Garments',
    'Textiles, Fabrics & Yarn',
    'Home Textiles & Furnishings',
    'Leather & Leather Products',
    'Footwear & Shoes',
    'Fashion & Lifestyle Accessories',
    'Medical, Surgical & Healthcare Supplies',
    'Pharmaceuticals & Wellness',
    'Automotive Parts & Accessories',
    'Engineering & Industrial Products',
    'Machinery, Tools & Equipment',
    'Electrical & Electronic Products',
  ];

  static const List<String> brandLines = [
    'Quality Products, Global Standard.',
    'Your Brand, Our Manufacturing.',
    'If the product you need is not listed, we source it.',
  ];
}
