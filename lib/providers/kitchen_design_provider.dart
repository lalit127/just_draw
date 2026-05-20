import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/kitchen_design.dart';
import '../models/blueprint_result.dart';
import '../services/gemini_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design Step Enum
// ─────────────────────────────────────────────────────────────────────────────

enum DesignStep {
  kitchenType,    // Step 1: Choose L/U/Island etc.
  drawerFittings, // Step 2: Select drawer types & quantities
  accessories,    // Step 3: Select accessories & hardware
  preview3d,      // Step 4: AI 3D preview of kitchen
  quotation,      // Step 5: Bill of Materials + pricing
  clientDetails,  // Step 6: Client name/contact
  proposal,       // Step 7: Final proposal ready
}

extension DesignStepExt on DesignStep {
  String get label {
    switch (this) {
      case DesignStep.kitchenType:
        return 'Kitchen Type';
      case DesignStep.drawerFittings:
        return 'Drawer Fittings';
      case DesignStep.accessories:
        return 'Accessories';
      case DesignStep.preview3d:
        return '3D Preview';
      case DesignStep.quotation:
        return 'Quotation';
      case DesignStep.clientDetails:
        return 'Client Details';
      case DesignStep.proposal:
        return 'Proposal';
    }
  }

  int get index => DesignStep.values.indexOf(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class KitchenDesignState {
  final KitchenDesign design;
  final DesignStep currentStep;
  final List<KitchenAccessory> availableAccessories;
  final Map<DrawerType, int> drawerQuantities;
  final bool isGeneratingProposal;

  // Blueprint context (carried over from analysis)
  final Uint8List? blueprintImageBytes;
  final BlueprintAnalysis? blueprintAnalysis;

  // AI Render state
  final Uint8List? aiRenderBytes;
  final bool isGeneratingRender;
  final String? renderError;

  // Interactive placement state
  final List<PlacedAccessory> placements;
  final KitchenZone? activeZone;
  final String? focusedAccessoryId;
  final bool isPlacementMode;
  final Map<KitchenZone, Uint8List> zoneCloseups;
  final Uint8List? finalDesignBytes;
  final bool isGeneratingFinal;
  final bool isGeneratingZoneCloseup;
  final KitchenZone? generatingCloseupZone;

  KitchenDesignState({
    this.design = const KitchenDesign(),
    this.currentStep = DesignStep.kitchenType,
    List<KitchenAccessory>? availableAccessories,
    this.drawerQuantities = const {},
    this.isGeneratingProposal = false,
    this.blueprintImageBytes,
    this.blueprintAnalysis,
    this.aiRenderBytes,
    this.isGeneratingRender = false,
    this.renderError,
    this.placements = const [],
    this.activeZone,
    this.focusedAccessoryId,
    this.isPlacementMode = true,
    this.zoneCloseups = const {},
    this.finalDesignBytes,
    this.isGeneratingFinal = false,
    this.isGeneratingZoneCloseup = false,
    this.generatingCloseupZone,
  }) : availableAccessories = availableAccessories ?? defaultAccessories;

  KitchenDesignState copyWith({
    KitchenDesign? design,
    DesignStep? currentStep,
    List<KitchenAccessory>? availableAccessories,
    Map<DrawerType, int>? drawerQuantities,
    bool? isGeneratingProposal,
    Uint8List? blueprintImageBytes,
    BlueprintAnalysis? blueprintAnalysis,
    Uint8List? aiRenderBytes,
    bool? isGeneratingRender,
    String? renderError,
    bool clearRenderError = false,
    bool clearRenderBytes = false,
    List<PlacedAccessory>? placements,
    KitchenZone? activeZone,
    bool clearActiveZone = false,
    String? focusedAccessoryId,
    bool clearFocusedAccessory = false,
    bool? isPlacementMode,
    Map<KitchenZone, Uint8List>? zoneCloseups,
    Uint8List? finalDesignBytes,
    bool clearFinalDesignBytes = false,
    bool? isGeneratingFinal,
    bool? isGeneratingZoneCloseup,
    KitchenZone? generatingCloseupZone,
    bool clearGeneratingCloseupZone = false,
  }) {
    return KitchenDesignState(
      design: design ?? this.design,
      currentStep: currentStep ?? this.currentStep,
      availableAccessories: availableAccessories ?? this.availableAccessories,
      drawerQuantities: drawerQuantities ?? this.drawerQuantities,
      isGeneratingProposal: isGeneratingProposal ?? this.isGeneratingProposal,
      blueprintImageBytes: blueprintImageBytes ?? this.blueprintImageBytes,
      blueprintAnalysis: blueprintAnalysis ?? this.blueprintAnalysis,
      aiRenderBytes: clearRenderBytes ? null : (aiRenderBytes ?? this.aiRenderBytes),
      isGeneratingRender: isGeneratingRender ?? this.isGeneratingRender,
      renderError: clearRenderError ? null : (renderError ?? this.renderError),
      placements: placements ?? this.placements,
      activeZone:
          clearActiveZone ? null : (activeZone ?? this.activeZone),
      focusedAccessoryId: clearFocusedAccessory
          ? null
          : (focusedAccessoryId ?? this.focusedAccessoryId),
      isPlacementMode: isPlacementMode ?? this.isPlacementMode,
      zoneCloseups: zoneCloseups ?? this.zoneCloseups,
      finalDesignBytes: clearFinalDesignBytes
          ? null
          : (finalDesignBytes ?? this.finalDesignBytes),
      isGeneratingFinal: isGeneratingFinal ?? this.isGeneratingFinal,
      isGeneratingZoneCloseup:
          isGeneratingZoneCloseup ?? this.isGeneratingZoneCloseup,
      generatingCloseupZone: clearGeneratingCloseupZone
          ? null
          : (generatingCloseupZone ?? this.generatingCloseupZone),
    );
  }

  int get currentStepIndex => currentStep.index;
  int get totalSteps => DesignStep.values.length;
  bool get canGoBack => currentStepIndex > 0;
  bool get isLastStep => currentStep == DesignStep.proposal;
  bool get hasAIRender => aiRenderBytes != null;
  bool get hasBlueprint => blueprintImageBytes != null;
  bool get hasFinalDesign => finalDesignBytes != null;

  /// Selected accessories that still need placement confirmation.
  List<KitchenAccessory> get selectedAccessoriesForPlacement =>
      availableAccessories.where((a) => a.isSelected).toList();

  List<KitchenAccessory> accessoriesInZone(KitchenZone zone) =>
      selectedAccessoriesForPlacement.where((a) => a.zoneId == zone).toList();

  bool isAccessoryPlaced(String id) =>
      placements.any((p) => p.accessory.id == id);

  PlacedAccessory? placementFor(String id) {
    try {
      return placements.firstWhere((p) => p.accessory.id == id);
    } catch (_) {
      return null;
    }
  }

  bool get allSelectedAccessoriesPlaced {
    final selected = selectedAccessoriesForPlacement;
    if (selected.isEmpty) return false;
    return selected.every((a) => isAccessoryPlaced(a.id));
  }

  int get nextFittingNumber => placements.length + 1;

  /// Build a numbered list of all active fittings (drawers + selected accessories)
  List<FittingItem> get numberedFittings {
    final items = <FittingItem>[];
    int index = 1;

    // Add drawers with quantity > 0
    for (final entry in drawerQuantities.entries) {
      if (entry.value > 0) {
        items.add(FittingItem(
          number: index++,
          name: entry.key.label,
          subtitle: entry.key.subtitle,
          category: _drawerCategory(entry.key),
          quantity: entry.value,
          pricePerUnit: entry.key.pricePerUnit,
        ));
      }
    }

    // Add selected accessories
    final selectedAcc = design.accessories.where((a) => a.isSelected).toList();
    for (final acc in selectedAcc) {
      items.add(FittingItem(
        number: index++,
        name: acc.name,
        subtitle: acc.description,
        category: acc.category,
        quantity: 1,
        pricePerUnit: acc.price,
      ));
    }

    return items;
  }

  String _drawerCategory(DrawerType type) {
    switch (type) {
      case DrawerType.pullOutPantry:
      case DrawerType.magicCorner:
        return 'Specialty Unit';
      default:
        return 'Drawer Fitting';
    }
  }
}

/// Represents a single numbered fitting item for the overlay
class FittingItem {
  final int number;
  final String name;
  final String subtitle;
  final String category;
  final int quantity;
  final int pricePerUnit;

  const FittingItem({
    required this.number,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.quantity,
    required this.pricePerUnit,
  });

  int get total => pricePerUnit * quantity;

  String get displayLabel => quantity > 1
      ? '$name ×$quantity'
      : name;
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class KitchenDesignNotifier extends StateNotifier<KitchenDesignState> {
  KitchenDesignNotifier() : super(KitchenDesignState()) {
    _initDefaultDrawers();
  }

  void _initDefaultDrawers() {
    final defaults = {
      DrawerType.wideDrawer: 2,
      DrawerType.narrowDrawer: 2,
      DrawerType.deepDrawer: 3,
      DrawerType.pullOutPantry: 1,
      DrawerType.magicCorner: 1,
      DrawerType.spicePullOut: 1,
      DrawerType.cutleryOrganizer: 2,
    };
    state = state.copyWith(drawerQuantities: defaults);
    _syncDrawersToDesign(defaults);
  }

  void _syncDrawersToDesign(Map<DrawerType, int> quantities) {
    final selections = quantities.entries
        .where((e) => e.value > 0)
        .map((e) => DrawerSelection(type: e.key, quantity: e.value))
        .toList();
    state = state.copyWith(
      design: state.design.copyWith(drawers: selections),
    );
  }

  // ── Blueprint Integration ──────────────────────────────────────────────────

  void startDesignFromBlueprint(BlueprintAnalysis analysis, Uint8List blueprintImage) {
    // Reset but keep blueprint data
    state = KitchenDesignState(
      blueprintAnalysis: analysis,
      blueprintImageBytes: blueprintImage,
    );
    _initDefaultDrawers();

    // Detect shape from the dedicated kitchen_shape element first, then fallback to scanning all elements
    KitchenShape? detectedShape;
    final elements = analysis.elements.map((e) => e.toLowerCase().trim()).toList();
    final allText = elements.join(' ');

    // Priority order: check dedicated shape field first (it's inserted at index 0 by service)
    if (elements.isNotEmpty) {
      final first = elements.first;
      if (first.contains('island')) {
        detectedShape = KitchenShape.island;
      } else if (first.contains('u-shape') || first.contains('u shape') || first == 'u-shape') {
        detectedShape = KitchenShape.uShape;
      } else if (first.contains('l-shape') || first.contains('l shape') || first == 'l-shape') {
        detectedShape = KitchenShape.lShape;
      } else if (first.contains('straight')) {
        detectedShape = KitchenShape.straight;
      } else if (first.contains('g-shape') || first.contains('g shape')) {
        detectedShape = KitchenShape.gShape;
      }
    }

    // Fallback: scan all elements text
    if (detectedShape == null) {
      if (allText.contains('island')) {
        detectedShape = KitchenShape.island;
      } else if (allText.contains('u-shape') || allText.contains('u shape')) {
        detectedShape = KitchenShape.uShape;
      } else if (allText.contains('l-shape') || allText.contains('l shape')) {
        detectedShape = KitchenShape.lShape;
      } else if (allText.contains('g-shape') || allText.contains('g shape')) {
        detectedShape = KitchenShape.gShape;
      } else if (allText.contains('straight')) {
        detectedShape = KitchenShape.straight;
      }
    }

    if (detectedShape != null) {
      state = state.copyWith(
        design: state.design.copyWith(shape: detectedShape),
      );
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  void goToStep(DesignStep step) => state = state.copyWith(currentStep: step);

  void selectShape(KitchenShape shape) {
    state = state.copyWith(
      design: state.design.copyWith(shape: shape),
      clearRenderBytes: true,
    );
  }

  void selectFinish(KitchenFinish finish) {
    state = state.copyWith(
      design: state.design.copyWith(finish: finish),
      clearRenderBytes: true,
    );
  }

  void updateBaseCabinetSqFt(double value) {
    state = state.copyWith(design: state.design.copyWith(baseCabinetSqFt: value));
  }

  void updateWallCabinetSqFt(double value) {
    state = state.copyWith(design: state.design.copyWith(wallCabinetSqFt: value));
  }

  // ── Drawer Fittings ─────────────────────────────────────────────────────────

  void setDrawerQuantity(DrawerType type, int quantity) {
    final updated = Map<DrawerType, int>.from(state.drawerQuantities);
    updated[type] = quantity.clamp(0, 10);
    state = state.copyWith(drawerQuantities: updated);
    _syncDrawersToDesign(updated);
  }

  void incrementDrawer(DrawerType type) {
    final current = state.drawerQuantities[type] ?? 0;
    setDrawerQuantity(type, current + 1);
  }

  void decrementDrawer(DrawerType type) {
    final current = state.drawerQuantities[type] ?? 0;
    setDrawerQuantity(type, current - 1);
  }

  // ── Accessories ─────────────────────────────────────────────────────────────

  void toggleAccessory(String id) {
    final updated = state.availableAccessories.map((a) {
      if (a.id == id) return a.copyWith(isSelected: !a.isSelected);
      return a;
    }).toList();
    state = state.copyWith(
      availableAccessories: updated,
      design: state.design.copyWith(accessories: updated),
      clearRenderBytes: true,
    );
  }

  void selectAllAccessoriesInCategory(String category, bool selected) {
    final updated = state.availableAccessories.map((a) {
      if (a.category == category) return a.copyWith(isSelected: selected);
      return a;
    }).toList();
    state = state.copyWith(
      availableAccessories: updated,
      design: state.design.copyWith(accessories: updated),
      clearRenderBytes: true,
    );
  }

  // ── Interactive Placement ───────────────────────────────────────────────────

  void setActiveZone(KitchenZone? zone) {
    if (zone == null) {
      state = state.copyWith(clearActiveZone: true);
    } else {
      state = state.copyWith(activeZone: zone);
    }
  }

  void showOverview() {
    state = state.copyWith(clearActiveZone: true);
  }

  void focusAccessory(String id) {
    KitchenAccessory? accessory;
    for (final a in state.availableAccessories) {
      if (a.id == id) {
        accessory = a;
        break;
      }
    }
    if (accessory == null || !accessory.isSelected) return;

    state = state.copyWith(
      focusedAccessoryId: id,
      clearActiveZone: true,
      isPlacementMode: true,
    );
  }

  void confirmPlacement(String id) {
    if (state.isAccessoryPlaced(id)) return;

    KitchenAccessory? accessory;
    for (final a in state.availableAccessories) {
      if (a.id == id && a.isSelected) {
        accessory = a;
        break;
      }
    }
    if (accessory == null) return;

    final placement = PlacedAccessory(
      accessory: accessory,
      zone: accessory.zoneId,
      fittingNumber: state.nextFittingNumber,
    );

    state = state.copyWith(
      placements: [...state.placements, placement],
      clearFocusedAccessory: true,
    );
  }

  void removePlacement(String id) {
    final updated = state.placements
        .where((p) => p.accessory.id != id)
        .toList();

    // Renumber remaining placements
    final renumbered = updated.asMap().entries.map((e) {
      return PlacedAccessory(
        accessory: e.value.accessory,
        zone: e.value.zone,
        fittingNumber: e.key + 1,
      );
    }).toList();

    state = state.copyWith(
      placements: renumbered,
      clearFocusedAccessory: state.focusedAccessoryId == id,
    );
  }

  void togglePlacementMode() {
    state = state.copyWith(isPlacementMode: !state.isPlacementMode);
  }

  Future<void> generateZoneCloseup(
    GeminiService service,
    KitchenZone zone,
  ) async {
    if (state.isGeneratingZoneCloseup) return;
    if (state.zoneCloseups.containsKey(zone)) return;

    final design = state.design;
    if (design.shape == null) return;

    state = state.copyWith(
      isGeneratingZoneCloseup: true,
      generatingCloseupZone: zone,
    );

    try {
      final zoneAccessories = state.placements
          .where((p) => p.zone == zone)
          .map((p) => '${p.fittingNumber}. ${p.accessory.name}')
          .toList();

      if (zoneAccessories.isEmpty) {
        zoneAccessories.addAll(
          state.accessoriesInZone(zone).map((a) => a.name),
        );
      }

      String contextNotes = '';
      if (state.blueprintAnalysis != null) {
        contextNotes = state.blueprintAnalysis!.description;
      }

      final config = kitchenZoneConfigs[zone]!;
      final bytes = await service.generateZoneCloseup(
        kitchenShape: design.shape!.label,
        finish: design.finish.label,
        zoneLabel: config.zone.label,
        zonePrompt: config.viewPrompt,
        accessoryNames: zoneAccessories,
        additionalContext: contextNotes,
      );

      final updatedCloseups = Map<KitchenZone, Uint8List>.from(state.zoneCloseups);
      updatedCloseups[zone] = bytes;

      state = state.copyWith(
        zoneCloseups: updatedCloseups,
        isGeneratingZoneCloseup: false,
        clearGeneratingCloseupZone: true,
      );
    } catch (e) {
      state = state.copyWith(
        isGeneratingZoneCloseup: false,
        clearGeneratingCloseupZone: true,
        renderError: _formatRenderError(e),
      );
    }
  }

  Future<void> generateFinalDesign(GeminiService service) async {
    final design = state.design;
    if (design.shape == null || state.isGeneratingFinal) return;

    state = state.copyWith(
      isGeneratingFinal: true,
      clearRenderError: true,
    );

    try {
      final placementList = state.placements
          .map((p) =>
              '${p.fittingNumber}. ${p.accessory.name} at ${p.zone.label} (${p.accessory.description})')
          .toList();

      String contextNotes = '';
      if (state.blueprintAnalysis != null) {
        contextNotes = state.blueprintAnalysis!.description;
      }

      final bytes = await service.generateFinalKitchenDesign(
        kitchenShape: design.shape!.label,
        finish: design.finish.label,
        placements: placementList,
        additionalContext: contextNotes,
      );

      state = state.copyWith(
        finalDesignBytes: bytes,
        aiRenderBytes: bytes,
        isGeneratingFinal: false,
      );

      // Pre-generate close-ups for zones that have placements
      final zonesWithPlacements =
          state.placements.map((p) => p.zone).toSet();
      for (final zone in zonesWithPlacements) {
        if (!state.zoneCloseups.containsKey(zone)) {
          await generateZoneCloseup(service, zone);
        }
      }
    } catch (e) {
      state = state.copyWith(
        isGeneratingFinal: false,
        renderError: _formatRenderError(e),
      );
    }
  }

  String _formatRenderError(Object e) {
    if (e is DioException) {
      if (e.response?.statusCode == 429) {
        return 'AI is busy (Rate limit). Please wait and retry.';
      }
      return 'Network error: ${e.response?.statusMessage ?? "Check connection"}';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  // ── AI Kitchen 3D Render ────────────────────────────────────────────────────

  Future<void> generateAIRender(GeminiService service, {String? viewAngle}) async {
    final design = state.design;
    
    // Guard: Don't start if missing shape OR already generating
    if (design.shape == null || state.isGeneratingRender) return;

    state = state.copyWith(
      isGeneratingRender: true,
      clearRenderError: true,
    );

    try {
      final selectedAcc = design.accessories
          .where((a) => a.isSelected)
          .map((a) => a.name)
          .toList();

      String contextNotes = '';
      if (state.blueprintAnalysis != null) {
        contextNotes = ' Architectural Context: ${state.blueprintAnalysis!.description}.';
      }

      final bytes = await service.generateKitchenRender(
        kitchenShape: design.shape!.label,
        finish: design.finish.label,
        accessories: selectedAcc,
        viewAngle: viewAngle,
        additionalContext: contextNotes,
      );

      state = state.copyWith(
        aiRenderBytes: bytes,
        isGeneratingRender: false,
      );
    } catch (e) {
      String message = 'Failed to generate render. Please try again.';
      
      if (e is DioException) {
        if (e.response?.statusCode == 429) {
          message = 'AI is busy (Rate limit reached). Please wait a minute before retrying.';
        } else {
          message = 'Network error: ${e.response?.statusMessage ?? "Check your connection"}';
        }
      } else {
        message = e.toString().replaceFirst('Exception: ', '');
      }

      state = state.copyWith(
        isGeneratingRender: false,
        renderError: message,
      );
    }
  }

  // ── Client Details ──────────────────────────────────────────────────────────

  void updateClientName(String name) {
    state = state.copyWith(design: state.design.copyWith(clientName: name));
  }

  void updateClientPhone(String phone) {
    state = state.copyWith(design: state.design.copyWith(clientPhone: phone));
  }

  void updateClientEmail(String email) {
    state = state.copyWith(design: state.design.copyWith(clientEmail: email));
  }

  void updateProjectLocation(String location) {
    state = state.copyWith(design: state.design.copyWith(projectLocation: location));
  }

  void reset() {
    state = KitchenDesignState();
    _initDefaultDrawers();
  }
}

final kitchenDesignProvider =
StateNotifierProvider<KitchenDesignNotifier, KitchenDesignState>(
      (ref) => KitchenDesignNotifier(),
);
