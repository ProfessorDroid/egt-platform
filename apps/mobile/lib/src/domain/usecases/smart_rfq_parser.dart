/// Smart RFQ assistant parsing: plain-language input ->
/// structured draft preview. ALWAYS shows a confirmation screen — never
/// silently assumes or submits.

class ParsedRequirement {
  const ParsedRequirement({
    required this.raw,
    this.productName,
    this.quantity,
    this.unit,
    this.destination,
    required this.confidence,
  });

  final String raw;
  final String? productName;
  final String? quantity;
  final String? unit;
  final String? destination;

  /// 0.0–1.0. Below 0.5 the UI shows the low-confidence warning.
  final double confidence;

  bool get hasProduct => productName != null;
  bool get hasQuantity => quantity != null;
  bool get hasDestination => destination != null;
}

class SmartRfqParser {
  static final _quantity = RegExp(
    r'(\d[\d,]*(?:\.\d+)?)\s*(kg|kgs|kilograms?|grams?|g\b|mt|metric tons?|tonnes?|tons?|\bt\b|litres?|liters?|\bl\b|ml|pieces?|pcs|bottles?|cartons?|boxes?|units?|bags?|pallets?|drums?)',
    caseSensitive: false,
  );
  static final _destination = RegExp(
    r'\b(?:for|to|in|ship to|deliver to)\s+([A-Za-z][A-Za-z .&()-]{1,48}?)(?:\.|$)',
    caseSensitive: false,
  );

  /// Keyword -> official catalogue product name (Phase 0 audit, 16 products).
  /// Real data only — keep in sync with the backend catalogue.
  static const Map<String, String> productKeywords = {
    'wiping rag': 'Cotton Wiping / Cleaning Rags',
    'cleaning rag': 'Cotton Wiping / Cleaning Rags',
    'cotton rag': 'Cotton Wiping / Cleaning Rags',
    'dishwash': 'Dr. Clenzol Concentrated Dishwash Liquid',
    'dish wash': 'Dr. Clenzol Concentrated Dishwash Liquid',
    'car wash': 'Hyper-Foam Snow Car Wash Shampoo',
    'snow foam': 'Hyper-Foam Snow Car Wash Shampoo',
    'car shampoo': 'Hyper-Foam Snow Car Wash Shampoo',
    'carnauba': 'Hydro-Shield Carnauba Liquid Wax',
    'liquid wax': 'Hydro-Shield Carnauba Liquid Wax',
    'tyre polish': 'Ultra-Slick Tyre Polish & Conditioner',
    'tire polish': 'Ultra-Slick Tyre Polish & Conditioner',
    'dashboard polish': 'Anti-Static Dashboard & Leather Polish',
    'leather polish': 'Anti-Static Dashboard & Leather Polish',
    'degreaser': 'Pro-Industrial Engine Degreaser',
    'engine cleaner': 'Pro-Industrial Engine Degreaser',
    'floor cleaner': 'Dr. Clenzol Multi-Surface Floor Cleaner',
    'toilet cleaner': 'Dr. Clenzol Power-Thick Toilet Cleaner',
    'laundry detergent': 'Fabric-Care Liquid Laundry Detergent',
    'detergent': 'Fabric-Care Liquid Laundry Detergent',
    'bathroom cleaner': 'Heavy-Duty Bathroom & Tile Cleaner',
    'tile cleaner': 'Heavy-Duty Bathroom & Tile Cleaner',
    'glass cleaner': 'Crystal-Clear Streak-Free Glass Cleaner',
    'biomass': 'High-Calorie Biomass Fuel Pellets',
    'pellet': 'High-Calorie Biomass Fuel Pellets',
    'wheat flour': 'Premium Sharbati Wheat Flour (Atta & Maida)',
    'atta': 'Premium Sharbati Wheat Flour (Atta & Maida)',
    'maida': 'Premium Sharbati Wheat Flour (Atta & Maida)',
    'sharbati': 'Premium Sharbati Wheat Flour (Atta & Maida)',
    'potato': 'Export-Grade Fresh Table & Processing Potatoes',
    'cow dung': 'Organic Composted Cow Dung Manure Powder',
    'manure': 'Organic Composted Cow Dung Manure Powder',
    'compost': 'Organic Composted Cow Dung Manure Powder',
  };

  static ParsedRequirement parse(String input) {
    final raw = input.trim();
    final lower = raw.toLowerCase();
    if (raw.isEmpty) {
      return const ParsedRequirement(raw: '', confidence: 0);
    }

    String? product;
    for (final entry in productKeywords.entries) {
      if (lower.contains(entry.key)) {
        product = entry.value;
        break;
      }
    }

    String? quantity;
    String? unit;
    final qtyMatch = _quantity.firstMatch(raw);
    if (qtyMatch != null) {
      quantity = qtyMatch.group(1)!.replaceAll(',', '');
      unit = _normalizeUnit(qtyMatch.group(2)!);
    }

    String? destination;
    final destMatch = _destination.firstMatch(raw);
    if (destMatch != null) {
      destination = destMatch.group(1)!.trim();
      if (destination.length < 2) destination = null;
    }

    var confidence = 0.0;
    if (product != null) confidence += 0.4;
    if (quantity != null) confidence += 0.3;
    if (destination != null) confidence += 0.3;

    return ParsedRequirement(
      raw: raw,
      productName: product,
      quantity: quantity,
      unit: unit,
      destination: destination,
      confidence: confidence,
    );
  }

  static String _normalizeUnit(String raw) {
    final u = raw.toLowerCase();
    if (u.startsWith('kg') || u.startsWith('kilo')) return 'kg';
    if (u == 'g' || u.startsWith('gram')) return 'g';
    if (u == 'mt' || u.contains('metric') || u.contains('tonne')) return 'MT';
    if (u.contains('ton')) return 'tons';
    if (u.startsWith('litre') || u.startsWith('liter') || u == 'l') return 'L';
    if (u == 'ml') return 'mL';
    if (u.startsWith('piece') || u == 'pcs') return 'pieces';
    if (u.startsWith('bottle')) return 'bottles';
    if (u.startsWith('carton')) return 'cartons';
    if (u.startsWith('box')) return 'boxes';
    if (u.startsWith('unit')) return 'units';
    if (u.startsWith('bag')) return 'bags';
    if (u.startsWith('pallet')) return 'pallets';
    if (u.startsWith('drum')) return 'drums';
    return raw;
  }
}
