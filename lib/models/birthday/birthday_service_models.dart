import 'dart:convert';

/// Categories of birthday services supported by Vowora.
enum BirthdayServiceCategory {
  catering,
  photography,
  decoration;

  String get displayName {
    switch (this) {
      case BirthdayServiceCategory.catering:
        return 'Food & Catering';
      case BirthdayServiceCategory.photography:
        return 'Photography & Reels';
      case BirthdayServiceCategory.decoration:
        return 'Styling & Decoration';
    }
  }

  String get dbValue {
    switch (this) {
      case BirthdayServiceCategory.catering:
        return 'catering';
      case BirthdayServiceCategory.photography:
        return 'photography';
      case BirthdayServiceCategory.decoration:
        return 'decoration';
    }
  }

  static BirthdayServiceCategory fromString(String val) {
    switch (val.toLowerCase()) {
      case 'catering':
      case 'food':
        return BirthdayServiceCategory.catering;
      case 'photography':
      case 'photo':
        return BirthdayServiceCategory.photography;
      case 'decoration':
      case 'decor':
      default:
        return BirthdayServiceCategory.decoration;
    }
  }
}

/// Package tier representing luxury gradation.
enum BirthdayPackageTier {
  silver,
  gold,
  royal;

  String get label {
    switch (this) {
      case BirthdayPackageTier.silver:
        return 'Silver Elegance';
      case BirthdayPackageTier.gold:
        return 'Gold Premier';
      case BirthdayPackageTier.royal:
        return 'Royal Imperial';
    }
  }

  static BirthdayPackageTier fromString(String val) {
    switch (val.toLowerCase()) {
      case 'silver':
        return BirthdayPackageTier.silver;
      case 'gold':
        return BirthdayPackageTier.gold;
      case 'royal':
      default:
        return BirthdayPackageTier.royal;
    }
  }
}

/// Optional add-on for a package.
class BirthdayServiceAddon {
  final String id;
  final String name;
  final double price;

  const BirthdayServiceAddon({
    required this.id,
    required this.name,
    required this.price,
  });

  factory BirthdayServiceAddon.fromJson(Map<String, dynamic> json) {
    return BirthdayServiceAddon(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };
}

/// Service package representation.
class BirthdayServicePackage {
  final String id;
  final String serviceId;
  final BirthdayServiceCategory category;
  final String name;
  final BirthdayPackageTier tier;
  final double price;
  final String priceUnit; // 'per_person', 'package', 'per_hour'
  final String description;
  final String imageUrl;
  final List<String> inclusions;
  final List<BirthdayServiceAddon> availableAddons;

  const BirthdayServicePackage({
    required this.id,
    required this.serviceId,
    required this.category,
    required this.name,
    required this.tier,
    required this.price,
    this.priceUnit = 'package',
    required this.description,
    required this.imageUrl,
    required this.inclusions,
    required this.availableAddons,
  });

  factory BirthdayServicePackage.fromJson(
    Map<String, dynamic> json, {
    BirthdayServiceCategory? category,
  }) {
    final cat = category ??
        BirthdayServiceCategory.fromString(json['category'] as String? ?? 'decoration');

    final rawInclusions = json['inclusions'];
    List<String> inclusionsList = [];
    if (rawInclusions is List) {
      inclusionsList = rawInclusions.map((e) => e.toString()).toList();
    } else if (rawInclusions is String) {
      try {
        final decoded = jsonDecode(rawInclusions);
        if (decoded is List) inclusionsList = decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }

    final rawAddons = json['available_addons'];
    List<BirthdayServiceAddon> addonsList = [];
    if (rawAddons is List) {
      addonsList = rawAddons
          .map((e) => BirthdayServiceAddon.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (rawAddons is String) {
      try {
        final decoded = jsonDecode(rawAddons);
        if (decoded is List) {
          addonsList = decoded
              .map((e) => BirthdayServiceAddon.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {}
    }

    return BirthdayServicePackage(
      id: json['id'] as String? ?? '',
      serviceId: json['service_id'] as String? ?? '',
      category: cat,
      name: json['name'] as String? ?? '',
      tier: BirthdayPackageTier.fromString(json['tier'] as String? ?? 'silver'),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      priceUnit: json['price_unit'] as String? ?? (cat == BirthdayServiceCategory.catering ? 'per_person' : 'package'),
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      inclusions: inclusionsList,
      availableAddons: addonsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'service_id': serviceId,
        'category': category.dbValue,
        'name': name,
        'tier': tier.name,
        'price': price,
        'price_unit': priceUnit,
        'description': description,
        'image_url': imageUrl,
        'inclusions': inclusions,
        'available_addons': availableAddons.map((e) => e.toJson()).toList(),
      };
}

/// An item selected by the user for their birthday celebration.
class BirthdayServiceCartItem {
  final BirthdayServicePackage package;
  int quantity; // Headcount for catering, or hours for photo, or units for decor
  final List<BirthdayServiceAddon> selectedAddons;
  String customNotes;

  BirthdayServiceCartItem({
    required this.package,
    this.quantity = 1,
    List<BirthdayServiceAddon>? selectedAddons,
    this.customNotes = '',
  }) : selectedAddons = selectedAddons ?? [];

  /// Calculates item total: (Base Price * quantity) + (Sum of Addons)
  double get totalCost {
    final baseCost = package.priceUnit == 'per_person'
        ? package.price * quantity
        : package.price;
    final addonsCost = selectedAddons.fold<double>(
      0.0,
      (sum, item) => sum + item.price,
    );
    return baseCost + addonsCost;
  }

  Map<String, dynamic> toJson() => {
        'package_id': package.id,
        'package_name': package.name,
        'service_category': package.category.dbValue,
        'unit_price': package.price,
        'price_unit': package.priceUnit,
        'quantity': quantity,
        'selected_addons': selectedAddons.map((e) => e.toJson()).toList(),
        'total_cost': totalCost,
        'custom_notes': customNotes,
      };
}
