// ─── Kitchen Design Models ────────────────────────────────────────────────────

import 'dart:ui';

// ─── Kitchen Zones (interactive placement) ────────────────────────────────────

enum KitchenZone {
  sinkArea,
  cooktopArea,
  islandCenter,
  fridgePantry,
  upperCabinets,
  lowerCabinets,
}

extension KitchenZoneExt on KitchenZone {
  String get label {
    switch (this) {
      case KitchenZone.sinkArea:
        return 'Sink Area';
      case KitchenZone.cooktopArea:
        return 'Cooktop';
      case KitchenZone.islandCenter:
        return 'Island';
      case KitchenZone.fridgePantry:
        return 'Storage';
      case KitchenZone.upperCabinets:
        return 'Upper';
      case KitchenZone.lowerCabinets:
        return 'Lower';
    }
  }

  String get shortLabel {
    switch (this) {
      case KitchenZone.sinkArea:
        return 'Sink';
      case KitchenZone.cooktopArea:
        return 'Cooktop';
      case KitchenZone.islandCenter:
        return 'Island';
      case KitchenZone.fridgePantry:
        return 'Storage';
      case KitchenZone.upperCabinets:
        return 'Upper';
      case KitchenZone.lowerCabinets:
        return 'Lower';
    }
  }
}

class KitchenZoneConfig {
  final KitchenZone zone;
  final Rect zoomRegion;
  final Offset pinPosition;
  /// Pin on full overview interior shot (not floor-plan crop).
  final Offset overviewPinPosition;
  final String viewPrompt;

  const KitchenZoneConfig({
    required this.zone,
    required this.zoomRegion,
    required this.pinPosition,
    required this.overviewPinPosition,
    required this.viewPrompt,
  });
}

const Map<KitchenZone, KitchenZoneConfig> kitchenZoneConfigs = {
  KitchenZone.sinkArea: KitchenZoneConfig(
    zone: KitchenZone.sinkArea,
    zoomRegion: Rect.fromLTWH(0.22, 0.02, 0.38, 0.28),
    pinPosition: Offset(0.42, 0.14),
    overviewPinPosition: Offset(0.34, 0.58),
    viewPrompt:
        'sink and faucet area with undermount double bowl stainless sink, pull-down faucet, dishwasher',
  ),
  KitchenZone.cooktopArea: KitchenZoneConfig(
    zone: KitchenZone.cooktopArea,
    zoomRegion: Rect.fromLTWH(0.58, 0.02, 0.38, 0.32),
    pinPosition: Offset(0.78, 0.16),
    overviewPinPosition: Offset(0.72, 0.58),
    viewPrompt:
        'cooktop and chimney zone with built-in gas hob, auto-clean chimney hood above',
  ),
  KitchenZone.islandCenter: KitchenZoneConfig(
    zone: KitchenZone.islandCenter,
    zoomRegion: Rect.fromLTWH(0.28, 0.30, 0.44, 0.38),
    pinPosition: Offset(0.50, 0.48),
    overviewPinPosition: Offset(0.50, 0.72),
    viewPrompt:
        'central island prep area with premium countertop surface and bar seating',
  ),
  KitchenZone.fridgePantry: KitchenZoneConfig(
    zone: KitchenZone.fridgePantry,
    zoomRegion: Rect.fromLTWH(0.02, 0.08, 0.28, 0.55),
    pinPosition: Offset(0.14, 0.38),
    overviewPinPosition: Offset(0.16, 0.56),
    viewPrompt:
        'refrigerator and pull-out pantry storage wall with tall units',
  ),
  KitchenZone.upperCabinets: KitchenZoneConfig(
    zone: KitchenZone.upperCabinets,
    zoomRegion: Rect.fromLTWH(0.15, 0.02, 0.70, 0.22),
    pinPosition: Offset(0.55, 0.10),
    overviewPinPosition: Offset(0.54, 0.40),
    viewPrompt:
        'upper wall cabinets with built-in microwave niche and spice storage',
  ),
  KitchenZone.lowerCabinets: KitchenZoneConfig(
    zone: KitchenZone.lowerCabinets,
    zoomRegion: Rect.fromLTWH(0.05, 0.55, 0.90, 0.40),
    pinPosition: Offset(0.35, 0.72),
    overviewPinPosition: Offset(0.36, 0.74),
    viewPrompt:
        'lower base cabinets with drawers, under-cabinet LED lighting, handles and soft-close hinges',
  ),
};

KitchenZone zoneForAccessoryId(String id) {
  switch (id) {
    case 'sink_double':
    case 'faucet_pulldown':
      return KitchenZone.sinkArea;
    case 'hob_builtin':
    case 'chimney':
      return KitchenZone.cooktopArea;
    case 'microwave_builtin':
      return KitchenZone.upperCabinets;
    case 'countertop_quartz':
    case 'countertop_marble':
      return KitchenZone.islandCenter;
    case 'led_cabinet':
    case 'handles_ss':
    case 'hinges_softclose':
      return KitchenZone.lowerCabinets;
    default:
      return KitchenZone.islandCenter;
  }
}

/// Pin anchor on the **full kitchen overview** (wide-angle interior render).
/// Coordinates are normalized 0–1 over the image area (x left→right, y top→bottom).
/// Tuned for typical modular kitchen shots: back wall across upper-middle, island in foreground.
Offset overviewPinForAccessoryId(String id) {
  switch (id) {
    case 'sink_double':
      return const Offset(0.34, 0.58);
    case 'faucet_pulldown':
      return const Offset(0.36, 0.55);
    case 'hob_builtin':
      return const Offset(0.72, 0.58);
    case 'chimney':
      return const Offset(0.74, 0.36);
    case 'microwave_builtin':
      return const Offset(0.54, 0.40);
    case 'countertop_quartz':
    case 'countertop_marble':
      return const Offset(0.50, 0.72);
    case 'led_cabinet':
      return const Offset(0.44, 0.62);
    case 'handles_ss':
      return const Offset(0.28, 0.74);
    case 'hinges_softclose':
      return const Offset(0.24, 0.76);
    default:
      return kitchenZoneConfigs[zoneForAccessoryId(id)]!.overviewPinPosition;
  }
}

/// Thumbnail URLs aligned to product names (verified HTTP 200).
String accessoryImageUrl(String id) {
  switch (id) {
    case 'sink_double':
      return 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500&q=85';
    case 'faucet_pulldown':
      return 'https://images.pexels.com/photos/6480708/pexels-photo-6480708.jpeg?auto=compress&cs=tinysrgb&w=500';
    case 'hob_builtin':
      return 'https://images.pexels.com/photos/2062431/pexels-photo-2062431.jpeg?auto=compress&cs=tinysrgb&w=500';
    case 'chimney':
      return 'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=500&q=85';
    case 'microwave_builtin':
      return 'https://images.unsplash.com/photo-1574269909862-7e1d70bb8078?w=500&q=85';
    case 'countertop_quartz':
      return 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?auto=compress&cs=tinysrgb&w=500';
    case 'countertop_marble':
      return 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=500&q=85';
    case 'led_cabinet':
      return 'https://images.pexels.com/photos/1571463/pexels-photo-1571463.jpeg?auto=compress&cs=tinysrgb&w=500';
    case 'handles_ss':
      return 'https://images.unsplash.com/photo-1618220179428-22790b461013?w=500&q=85';
    case 'hinges_softclose':
      return 'https://images.pexels.com/photos/1080721/pexels-photo-1080721.jpeg?auto=compress&cs=tinysrgb&w=500';
    default:
      return 'https://images.unsplash.com/photo-1556909172-54557c7e4fb7?w=500&q=85';
  }
}

class PlacedAccessory {
  final KitchenAccessory accessory;
  final KitchenZone zone;
  final int fittingNumber;
  final bool isConfirmed;

  const PlacedAccessory({
    required this.accessory,
    required this.zone,
    required this.fittingNumber,
    this.isConfirmed = true,
  });
}

enum KitchenShape { lShape, uShape, island, straight, gShape }

extension KitchenShapeExt on KitchenShape {
  String get label {
    switch (this) {
      case KitchenShape.lShape:
        return 'L-Shape';
      case KitchenShape.uShape:
        return 'U-Shape';
      case KitchenShape.island:
        return 'Island';
      case KitchenShape.straight:
        return 'Straight';
      case KitchenShape.gShape:
        return 'G-Shape';
    }
  }

  String get description {
    switch (this) {
      case KitchenShape.lShape:
        return 'Two perpendicular walls. Efficient corner use.';
      case KitchenShape.uShape:
        return 'Three-wall layout. Maximum storage & workspace.';
      case KitchenShape.island:
        return 'Central island with perimeter cabinets. Best for open kitchens.';
      case KitchenShape.straight:
        return 'Single wall. Compact and minimal.';
      case KitchenShape.gShape:
        return 'Wraparound with peninsula. Maximum enclosed space.';
    }
  }

  /// Card preview: elevated / wide-angle shot so layout reads like a “top 3D” view of that shape.
  String get previewImageUrl {
    switch (this) {
      case KitchenShape.lShape:
        return 'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=900&q=85';
      case KitchenShape.uShape:
        return 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=900&q=85';
      case KitchenShape.island:
        return 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=900&q=85';
      case KitchenShape.straight:
        return 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=900&q=85';
      case KitchenShape.gShape:
        return 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=900&q=85';
    }
  }

  /// Higher-res reference (e.g. proposals).
  String get render3dUrl {
    switch (this) {
      case KitchenShape.lShape:
        return 'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=1600&q=90';
      case KitchenShape.uShape:
        return 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=1600&q=90';
      case KitchenShape.island:
        return 'https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=1600&q=90';
      case KitchenShape.straight:
        return 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=1600&q=90';
      case KitchenShape.gShape:
        return 'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=1600&q=90';
    }
  }
}

// ─── Finish / Style ───────────────────────────────────────────────────────────

enum KitchenFinish { matte, glossy, woodVeneer, antiFingerprint, lacquered }

extension KitchenFinishExt on KitchenFinish {
  String get label {
    switch (this) {
      case KitchenFinish.matte:
        return 'Matte';
      case KitchenFinish.glossy:
        return 'High Gloss';
      case KitchenFinish.woodVeneer:
        return 'Wood Veneer';
      case KitchenFinish.antiFingerprint:
        return 'Anti-Fingerprint';
      case KitchenFinish.lacquered:
        return 'Lacquered';
    }
  }

  int get pricePerSqFt {
    switch (this) {
      case KitchenFinish.matte:
        return 2200;
      case KitchenFinish.glossy:
        return 2800;
      case KitchenFinish.woodVeneer:
        return 3200;
      case KitchenFinish.antiFingerprint:
        return 2600;
      case KitchenFinish.lacquered:
        return 3500;
    }
  }
}

// ─── Drawer Fitting ──────────────────────────────────────────────────────────

enum DrawerType {
  wideDrawer,
  narrowDrawer,
  deepDrawer,
  pullOutPantry,
  magicCorner,
  spicePullOut,
  cutleryOrganizer,
}

extension DrawerTypeExt on DrawerType {
  String get label {
    switch (this) {
      case DrawerType.wideDrawer:
        return 'Wide Drawer';
      case DrawerType.narrowDrawer:
        return 'Narrow Drawer';
      case DrawerType.deepDrawer:
        return 'Deep Drawer';
      case DrawerType.pullOutPantry:
        return 'Pull-Out Pantry';
      case DrawerType.magicCorner:
        return 'Magic Corner';
      case DrawerType.spicePullOut:
        return 'Spice Pull-Out';
      case DrawerType.cutleryOrganizer:
        return 'Cutlery Organizer';
    }
  }

  String get subtitle {
    switch (this) {
      case DrawerType.wideDrawer:
        return 'Cutlery & utensils · 100mm height';
      case DrawerType.narrowDrawer:
        return 'Cleaning & spice · 150mm height';
      case DrawerType.deepDrawer:
        return 'Pots, pans & bowls · 300mm height';
      case DrawerType.pullOutPantry:
        return 'Groceries & bottles · full height';
      case DrawerType.magicCorner:
        return 'Corner space optimizer';
      case DrawerType.spicePullOut:
        return 'Spice jars & condiments';
      case DrawerType.cutleryOrganizer:
        return 'Cutlery tray insert';
    }
  }

  int get pricePerUnit {
    switch (this) {
      case DrawerType.wideDrawer:
        return 3500;
      case DrawerType.narrowDrawer:
        return 3500;
      case DrawerType.deepDrawer:
        return 3500;
      case DrawerType.pullOutPantry:
        return 28000;
      case DrawerType.magicCorner:
        return 18000;
      case DrawerType.spicePullOut:
        return 8500;
      case DrawerType.cutleryOrganizer:
        return 2000;
    }
  }

  String get imageUrl {
    switch (this) {
      case DrawerType.wideDrawer:
        return 'https://images.unsplash.com/photo-1600585154084-4e5fe7c39198?w=500&q=85';
      case DrawerType.narrowDrawer:
        return 'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=500&q=85';
      case DrawerType.deepDrawer:
        return 'https://images.pexels.com/photos/1350789/pexels-photo-1350789.jpeg?auto=compress&cs=tinysrgb&w=500';
      case DrawerType.pullOutPantry:
        return 'https://images.unsplash.com/photo-1615876063860-d971f6dca5dc?w=500&q=85';
      case DrawerType.magicCorner:
        return 'https://images.unsplash.com/photo-1600607687644-c7171b42498f?w=500&q=85';
      case DrawerType.spicePullOut:
        return 'https://images.pexels.com/photos/2995162/pexels-photo-2995162.jpeg?auto=compress&cs=tinysrgb&w=500';
      case DrawerType.cutleryOrganizer:
        return 'https://images.unsplash.com/photo-1555949963-ff9fe0c870eb?w=500&q=85';
    }
  }
}

// ─── Accessory ───────────────────────────────────────────────────────────────

class KitchenAccessory {
  final String id;
  final String name;
  final String category;
  final String description;
  final int price;
  final String imageUrl;
  final KitchenZone zoneId;
  final bool isSelected;

  const KitchenAccessory({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.zoneId,
    this.isSelected = false,
  });

  KitchenAccessory copyWith({bool? isSelected}) {
    return KitchenAccessory(
      id: id,
      name: name,
      category: category,
      description: description,
      price: price,
      imageUrl: imageUrl,
      zoneId: zoneId,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// Default accessory catalog
List<KitchenAccessory> buildDefaultAccessories() => [
  KitchenAccessory(
    id: 'sink_double',
    name: 'Double Bowl Sink',
    category: 'Sink & Faucet',
    description: 'SS 304 grade double bowl undermount',
    price: 9500,
    imageUrl: accessoryImageUrl('sink_double'),
    zoneId: KitchenZone.sinkArea,
  ),
  KitchenAccessory(
    id: 'faucet_pulldown',
    name: 'Pull-Down Faucet',
    category: 'Sink & Faucet',
    description: 'Chrome finish with flexible hose',
    price: 7500,
    imageUrl: accessoryImageUrl('faucet_pulldown'),
    zoneId: KitchenZone.sinkArea,
  ),
  KitchenAccessory(
    id: 'hob_builtin',
    name: 'Built-in Hob',
    category: 'Appliances',
    description: '4-burner auto-ignition gas hob',
    price: 18000,
    imageUrl: accessoryImageUrl('hob_builtin'),
    zoneId: KitchenZone.cooktopArea,
  ),
  KitchenAccessory(
    id: 'chimney',
    name: 'Auto-Clean Chimney',
    category: 'Appliances',
    description: 'Filterless 60cm baffle chimney',
    price: 14000,
    imageUrl: accessoryImageUrl('chimney'),
    zoneId: KitchenZone.cooktopArea,
  ),
  KitchenAccessory(
    id: 'microwave_builtin',
    name: 'Built-in Microwave',
    category: 'Appliances',
    description: '25L convection microwave housing',
    price: 6500,
    imageUrl: accessoryImageUrl('microwave_builtin'),
    zoneId: KitchenZone.upperCabinets,
  ),
  KitchenAccessory(
    id: 'countertop_quartz',
    name: 'Quartz Countertop',
    category: 'Countertop',
    description: 'Engineered quartz 20mm thick',
    price: 14400,
    imageUrl: accessoryImageUrl('countertop_quartz'),
    zoneId: KitchenZone.islandCenter,
  ),
  KitchenAccessory(
    id: 'countertop_marble',
    name: 'Italian Marble Top',
    category: 'Countertop',
    description: 'Carrara white 18mm polished',
    price: 22000,
    imageUrl: accessoryImageUrl('countertop_marble'),
    zoneId: KitchenZone.islandCenter,
  ),
  KitchenAccessory(
    id: 'led_cabinet',
    name: 'LED Cabinet Lighting',
    category: 'Lighting',
    description: 'Under-cabinet warm LED strip 3000K',
    price: 6300,
    imageUrl: accessoryImageUrl('led_cabinet'),
    zoneId: KitchenZone.lowerCabinets,
  ),
  KitchenAccessory(
    id: 'handles_ss',
    name: 'SS Profile Handles',
    category: 'Hardware',
    description: '32 pcs brushed steel bar handles',
    price: 8000,
    imageUrl: accessoryImageUrl('handles_ss'),
    zoneId: KitchenZone.lowerCabinets,
  ),
  KitchenAccessory(
    id: 'hinges_softclose',
    name: 'Soft-Close Hinges',
    category: 'Hardware',
    description: '28 pcs hydraulic cabinet hinges',
    price: 6160,
    imageUrl: accessoryImageUrl('hinges_softclose'),
    zoneId: KitchenZone.lowerCabinets,
  ),
];

final List<KitchenAccessory> defaultAccessories = buildDefaultAccessories();

// ─── Drawer Selection ────────────────────────────────────────────────────────

class DrawerSelection {
  final DrawerType type;
  final int quantity;

  const DrawerSelection({required this.type, required this.quantity});

  DrawerSelection copyWith({int? quantity}) {
    return DrawerSelection(type: type, quantity: quantity ?? this.quantity);
  }

  int get total => type.pricePerUnit * quantity;
}

// ─── Full Kitchen Design State ────────────────────────────────────────────────

class KitchenDesign {
  final KitchenShape? shape;
  final KitchenFinish finish;
  final double baseCabinetSqFt;
  final double wallCabinetSqFt;
  final List<DrawerSelection> drawers;
  final List<KitchenAccessory> accessories;

  // Client info
  final String clientName;
  final String clientPhone;
  final String clientEmail;
  final String projectLocation;

  const KitchenDesign({
    this.shape,
    this.finish = KitchenFinish.matte,
    this.baseCabinetSqFt = 38,
    this.wallCabinetSqFt = 24,
    this.drawers = const [],
    this.accessories = const [],
    this.clientName = '',
    this.clientPhone = '',
    this.clientEmail = '',
    this.projectLocation = '',
  });

  KitchenDesign copyWith({
    KitchenShape? shape,
    KitchenFinish? finish,
    double? baseCabinetSqFt,
    double? wallCabinetSqFt,
    List<DrawerSelection>? drawers,
    List<KitchenAccessory>? accessories,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? projectLocation,
  }) {
    return KitchenDesign(
      shape: shape ?? this.shape,
      finish: finish ?? this.finish,
      baseCabinetSqFt: baseCabinetSqFt ?? this.baseCabinetSqFt,
      wallCabinetSqFt: wallCabinetSqFt ?? this.wallCabinetSqFt,
      drawers: drawers ?? this.drawers,
      accessories: accessories ?? this.accessories,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      projectLocation: projectLocation ?? this.projectLocation,
    );
  }

  // ── Pricing calculations ──────────────────────────────────────────────────

  double get baseCabinetTotal =>
      baseCabinetSqFt * finish.pricePerSqFt;

  double get wallCabinetTotal =>
      wallCabinetSqFt * (finish.pricePerSqFt * 0.9);

  double get drawersTotal =>
      drawers.fold(0, (sum, d) => sum + d.total.toDouble());

  double get accessoriesTotal => accessories
      .where((a) => a.isSelected)
      .fold(0, (sum, a) => sum + a.price);

  double get installationCharges => 22000;

  double get subTotal =>
      baseCabinetTotal +
          wallCabinetTotal +
          drawersTotal +
          accessoriesTotal +
          installationCharges;

  double get gst => subTotal * 0.18;

  double get grandTotal => subTotal + gst;
}