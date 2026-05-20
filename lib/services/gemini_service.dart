import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/blueprint_result.dart';

class GeminiService {
  final String apiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Text + vision analysis of hand-drawn sketches.
  static const String analysisModel = 'gemini-2.5-flash';

  /// All image generation (floor plans, 3D renders) via Imagen 4.
  static const String imagenModel = 'imagen-4.0-generate-001';
  static const String imagenModelFast = 'imagen-4.0-fast-generate-001';

  static const List<String> _imagenModels = [imagenModel, imagenModelFast];

  final Dio _dio;

  GeminiService({required this.apiKey})
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 180),
            sendTimeout: const Duration(seconds: 60),
          ),
        );

  // ─────────────────────────────────────────────────────────────────
  // BLUEPRINT ANALYSIS — robust JSON extraction with retry fallback
  // ─────────────────────────────────────────────────────────────────

  Future<BlueprintAnalysis> analyseSketch(File imageFile) async {
    _assertApiKey();

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _getMimeType(imageFile.path);

    // ── Step 1: Analyse the hand-drawn sketch with Gemini Flash ──────────────
    const prompt = r'''
You are an expert kitchen designer and architectural CAD engineer. Analyse this HAND-DRAWN kitchen sketch carefully.

The user wants a professional 2D architectural floor plan output like a real interior-design proposal:
- Title "KITCHEN FLOOR PLAN" at top center
- Overall dimensions on top and right edges (e.g. 14'-0" × 12'-0")
- North compass rose bottom-left, scale "1/2" = 1'-0""
- Thick dark grey walls, tan horizontal wood-plank flooring
- Light speckled cream/quartz countertops on all cabinet runs
- Uppercase labels: DISHWASHER, SINK, REFRIGERATOR, RANGE, ISLAND, PANTRY
- Double-bowl sink symbol, 5-6 burner range, fridge rectangle, window above sink
- Dashed work triangle connecting sink, refrigerator, and range
- Door swing arcs, bar stools at island

Respond with ONLY valid JSON. No markdown, no backticks.

Schema:
{
  "title": "Kitchen Floor Plan",
  "description": "Brief summary",
  "kitchen_shape": "u-shape",
  "width_ft": "14",
  "depth_ft": "12",
  "measurements": [
    {"label": "Overall Width", "value": "14", "unit": "ft"},
    {"label": "Overall Depth", "value": "12", "unit": "ft"}
  ],
  "elements": ["sink", "dishwasher", "refrigerator", "range", "island", "pantry"],
  "spatial_layout": {
    "sink_wall": "top",
    "range_wall": "right",
    "refrigerator_wall": "left",
    "pantry_corner": "bottom-left",
    "island_position": "center",
    "window_above_sink": true,
    "main_door_wall": "bottom"
  },
  "layout_description": "Detailed 3-4 sentences: exact wall for each appliance, island size/position, doors, window, work triangle.",
  "blueprint_prompt": "Optional extra generation notes"
}

Rules for HAND-DRAWN sketches:
- Read rough pencil/pen lines: outer rectangle = room boundary, inner shapes = cabinets/appliances
- kitchen_shape: "u-shape" if cabinets on 3 walls; "l-shape" if 2 perpendicular walls; "island" if central island with perimeter cabinets; "straight" if single wall only
- Preserve sketch orientation: do NOT mirror or rotate — if sink is drawn on top wall, sink_wall must be "top"
- spatial_layout walls: top, bottom, left, right (relative to sketch as viewed)
- Estimate width_ft/depth_ft from sketch proportions or written numbers (typical 10-16 ft)
- elements: only what is visible or clearly implied in the sketch
- If sketch is messy, infer standard kitchen logic but keep positions from sketch
''';

    final response = await _dio.post(
      '$_baseUrl/models/$analysisModel:generateContent?key=$apiKey',
      data: {
        'contents': [
          {
            'parts': [
              {
                'inline_data': {'mime_type': mimeType, 'data': base64Image},
              },
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topK': 16,
          'topP': 0.9,
        },
      },
    );

    final rawText =
        response.data['candidates'][0]['content']['parts'][0]['text'] as String;

    // ── Robust JSON extraction ────────────────────────────────────
    final analysis = _parseAnalysisJson(rawText);
    return analysis;
  }

  BlueprintAnalysis _parseAnalysisJson(String rawText) {
    // Strip markdown fences if present
    String cleaned = rawText
        .replaceAll(RegExp(r'```json\s*'), '')
        .replaceAll(RegExp(r'```\s*'), '')
        .trim();

    // Find JSON boundaries
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw Exception(
          'Could not parse AI response as JSON. Raw: ${rawText.substring(0, rawText.length.clamp(0, 200))}');
    }

    cleaned = cleaned.substring(start, end + 1);

    Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('JSON parse error: $e\nRaw: ${cleaned.substring(0, cleaned.length.clamp(0, 300))}');
    }

    // Build the blueprint_prompt with professional floor plan style injected
    final layoutDesc = json['layout_description'] as String? ?? '';
    final kitchenShape = (json['kitchen_shape'] as String? ?? 'island').toLowerCase();
    final widthFt = json['width_ft'] as String? ?? '14';
    final depthFt = json['depth_ft'] as String? ?? '12';
    final elementsList = (json['elements'] as List? ?? []).map((e) => e.toString()).toList();

    final spatialLayout = json['spatial_layout'] is Map
        ? Map<String, dynamic>.from(json['spatial_layout'] as Map)
        : <String, dynamic>{};

    // Craft a highly detailed, targeted blueprint prompt
    final blueprintPrompt = _buildBlueprintPrompt(
      kitchenShape: kitchenShape,
      widthFt: widthFt,
      depthFt: depthFt,
      elements: elementsList,
      layoutDescription: layoutDesc,
      spatialLayout: spatialLayout,
      extraPrompt: json['blueprint_prompt'] as String? ?? '',
    );

    // Build measurements from structured fields
    final measurements = <Map<String, dynamic>>[];
    if (json['measurements'] != null) {
      for (final m in (json['measurements'] as List)) {
        if (m is Map) measurements.add(Map<String, dynamic>.from(m));
      }
    }
    if (measurements.isEmpty) {
      measurements.addAll([
        {'label': 'Overall Width', 'value': widthFt, 'unit': 'ft'},
        {'label': 'Overall Depth', 'value': depthFt, 'unit': 'ft'},
      ]);
    }

    // Build elements list including kitchen_shape
    final elements = [...elementsList];
    if (!elements.any((e) => e.toLowerCase().contains('shape') || e.toLowerCase() == kitchenShape)) {
      elements.insert(0, kitchenShape);
    }

    return BlueprintAnalysis(
      title: json['title'] as String? ?? 'Kitchen Floor Plan',
      description: json['description'] as String? ?? layoutDesc,
      measurements: measurements
          .map((m) => Measurement.fromJson(m))
          .toList(),
      elements: elements,
      blueprintPrompt: blueprintPrompt,
    );
  }

  String _buildBlueprintPrompt({
    required String kitchenShape,
    required String widthFt,
    required String depthFt,
    required List<String> elements,
    required String layoutDescription,
    Map<String, dynamic> spatialLayout = const {},
    required String extraPrompt,
  }) {
    final elementStr = elements.isNotEmpty
        ? elements.map((e) => e.toUpperCase()).join(', ')
        : 'DISHWASHER, SINK, REFRIGERATOR, RANGE, ISLAND, PANTRY';

    final sinkWall = spatialLayout['sink_wall'] ?? 'top';
    final rangeWall = spatialLayout['range_wall'] ?? 'right';
    final fridgeWall = spatialLayout['refrigerator_wall'] ?? 'left';
    final pantryCorner = spatialLayout['pantry_corner'] ?? 'bottom-left';
    final islandPos = spatialLayout['island_position'] ?? 'center';
    final windowAboveSink = spatialLayout['window_above_sink'] == true;
    final doorWall = spatialLayout['main_door_wall'] ?? 'bottom';

    final spatialBlock = '''
SPATIAL LAYOUT (preserve from hand-drawn sketch — do not rotate or mirror):
- Room: ${widthFt}'-0" wide × ${depthFt}'-0" deep, $kitchenShape perimeter cabinets
- SINK + DISHWASHER on $sinkWall wall${windowAboveSink ? ', wide WINDOW centered above SINK' : ''}
- RANGE (5-6 burner cooktop) on $rangeWall wall, centered on counter run
- REFRIGERATOR on $fridgeWall wall
- PANTRY in $pantryCorner corner with swing door arc
- ISLAND at $islandPos with 3 bar stool circles on seating side
- Main entry door on $doorWall wall with swing arc
- Dashed WORK TRIANGLE connecting sink, refrigerator, and range centers
''';

    final extra = extraPrompt.trim().isNotEmpty ? '\n$extraPrompt\n' : '';

    return '''
Transform the hand-drawn kitchen sketch into a professional 2D architectural KITCHEN FLOOR PLAN identical to a high-end interior design CAD presentation document.

REFERENCE STYLE (match exactly):
- Pure white background, top-down orthographic view only (no 3D, no perspective)
- Bold title "KITCHEN FLOOR PLAN" centered at top in black sans-serif
- Dimension strings on TOP edge (${widthFt}'-0") and RIGHT edge (${depthFt}'-0") with extension lines and arrows
- Bottom-left: compass rose with "N" arrow + "SCALE: 1/2" = 1'-0""
- Walls: thick dark grey/charcoal filled outlines
- Floor: warm tan/beige horizontal wood plank texture inside room
- Countertops: light cream speckled quartz/granite fill on all cabinet runs and island
- Cabinet runs: thin black double-lines parallel to each wall

$spatialBlock

DETAILED LAYOUT:
$layoutDescription

LABELED ELEMENTS (uppercase sans-serif text on drawing):
$elementStr

APPLIANCE SYMBOLS (draw precisely):
- SINK: double-basin undermount (two grey squares side by side), faucet dot, label "SINK"
- DISHWASHER: grey appliance box left of sink, label "DISHWASHER"
- REFRIGERATOR: tall grey box with handle, label "REFRIGERATOR"
- RANGE: dark cooktop with 5-6 circular burner marks, label "RANGE"
- ISLAND: large cream countertop rectangle, label "ISLAND", 3 stool circles
- PANTRY: closet with shelves lines, swing door arc, label "PANTRY"
- WINDOW: double-line opening on sink wall if applicable

CAD DETAILS:
- Upper cabinets: dashed lines above counter runs
- Work triangle: grey dashed lines sink↔fridge↔range
- All doors: quarter-circle swing arcs
$extra
CRITICAL: Keep the same appliance positions as the hand-drawn sketch. Output only the finished floor plan — no sketch lines, no pencil marks, no watermarks, no extra commentary text.
''';
  }

  // ─────────────────────────────────────────────────────────────────
  // BLUEPRINT IMAGE GENERATION — Imagen 4 (layout from gemini-2.5-flash)
  // ─────────────────────────────────────────────────────────────────

  Future<Uint8List> generateBlueprintImage(
    String blueprintPrompt, {
    File? sketchFile, // layout already analysed via [analysisModel]
  }) async {
    _assertApiKey();
    // Sketch layout is read by [analysisModel]; Imagen 4 draws the CAD plan.
    return _generateImageViaImagen(
      _truncateForImagen(blueprintPrompt),
      aspectRatio: '4:3',
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // AI KITCHEN 3D RENDER — Imagen 4
  // ─────────────────────────────────────────────────────────────────

  Future<Uint8List> generateKitchenRender({
    required String kitchenShape,
    required String finish,
    List<String> accessories = const [],
    String? viewAngle,
    String? additionalContext,
  }) async {
    _assertApiKey();

    final accStr = accessories.isEmpty
        ? ''
        : ', including ${accessories.take(5).join(', ')}';

    final viewStr = viewAngle != null ? ', $viewAngle camera angle' : '';
    final contextStr = additionalContext != null ? ' $additionalContext' : '';

    final prompt = '''
Photorealistic 3D interior architectural render of a high-end modern $kitchenShape modular kitchen.$contextStr
Cabinet finish: $finish laminate$accStr.
IMPORTANT: Single wide-angle overview shot of the ENTIRE kitchen in one frame — show full room from floor to ceiling, all walls and island visible, straight-on or slight three-quarter view. Do not crop to a detail or single wall.
Style: contemporary Indian modular kitchen, premium quality, similar to image 1 reference (L-Shape Kitchen, Matte Finish).
Lighting: warm ambient with under-cabinet LED strips, recessed ceiling lights.
Materials: quartz countertop, stainless steel appliances, clean handle-less cabinet fronts$viewStr.
Quality: professional architectural visualization, magazine cover quality, 
8K ultra-realistic render, perfect composition, no people.
Color palette: neutral whites and warm wood tones, dark wood grain accents.
Absolutely no text, watermarks, or overlays in the image.
''';

    return _generateKitchenImageWithFallback(prompt, aspectRatio: '4:3');
  }

  // ─────────────────────────────────────────────────────────────────
  // ZONE CLOSE-UP — focused render of a kitchen zone
  // ─────────────────────────────────────────────────────────────────

  Future<Uint8List> generateZoneCloseup({
    required String kitchenShape,
    required String finish,
    required String zoneLabel,
    required String zonePrompt,
    List<String> accessoryNames = const [],
    String? additionalContext,
  }) async {
    _assertApiKey();

    final accStr = accessoryNames.isEmpty
        ? ''
        : '. Showing: ${accessoryNames.join(', ')}';
    final contextStr =
        additionalContext != null ? ' Context: $additionalContext.' : '';

    final prompt = '''
Close-up interior shot of the $zoneLabel area of a $kitchenShape modular kitchen.$contextStr
$zonePrompt$accStr.
Camera angle: eye-level, focused tightly on the $zoneLabel zone.
Cabinet finish: $finish laminate. Style: contemporary Indian modular kitchen, premium quality.
Lighting: warm ambient with under-cabinet LED strips.
Materials: quartz countertop, stainless steel appliances, clean handle-less cabinet fronts.
Quality: professional architectural visualization, magazine cover quality, 8K ultra-realistic.
Absolutely no text, watermarks, labels, or numbered overlays in the image.
''';

    return _generateKitchenImageWithFallback(prompt, aspectRatio: '4:3');
  }

  // ─────────────────────────────────────────────────────────────────
  // FINAL KITCHEN DESIGN — overview with all placed accessories
  // ─────────────────────────────────────────────────────────────────

  Future<Uint8List> generateFinalKitchenDesign({
    required String kitchenShape,
    required String finish,
    required List<String> placements,
    String? additionalContext,
  }) async {
    _assertApiKey();

    final placementStr = placements.isEmpty
        ? 'standard modular fittings'
        : placements.join('; ');
    final contextStr =
        additionalContext != null ? ' $additionalContext.' : '';

    final prompt = '''
Photorealistic 3D interior architectural render of a complete $kitchenShape modular kitchen.$contextStr
Cabinet finish: $finish laminate.
All fittings installed and visible at their correct positions:
$placementStr.
Sink zone: top-center wall with undermount sink and faucet.
Cooktop zone: right wall with built-in hob and chimney hood.
Island/counter: center prep area with premium countertop.
Storage: left wall refrigerator and pantry pull-outs.
Upper cabinets: microwave niche and wall storage.
Lower cabinets: drawers with LED under-cabinet lighting, SS handles, soft-close hinges.
Style: contemporary Indian modular kitchen, premium quality.
Lighting: warm ambient with under-cabinet LED strips, recessed ceiling lights.
Materials: quartz countertop, stainless steel appliances, clean handle-less cabinet fronts.
Wide-angle overview camera, eye-level, showing entire kitchen layout.
Quality: professional architectural visualization, magazine cover quality, 8K ultra-realistic.
Absolutely no text, watermarks, or numbered overlays in the image.
''';

    return _generateKitchenImageWithFallback(prompt, aspectRatio: '4:3');
  }

  Future<Uint8List> _generateKitchenImageWithFallback(
    String prompt, {
    String aspectRatio = '4:3',
  }) async {
    return _generateImageViaImagen(
      _truncateForImagen(prompt),
      aspectRatio: aspectRatio,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Image Generation — Imagen 4
  // ─────────────────────────────────────────────────────────────────

  /// Generate image via Imagen 4 (:predict endpoint).
  Future<Uint8List> _generateImageViaImagen(
    String prompt, {
    String aspectRatio = '1:1',
  }) async {
    Object? lastError;
    for (final model in _imagenModels) {
      try {
        final response = await _retryOnTransient(() => _dio.post(
          '$_baseUrl/models/$model:predict?key=$apiKey',
          data: {
            'instances': [
              {'prompt': prompt},
            ],
            'parameters': {
              'sampleCount': 1,
              'aspectRatio': aspectRatio,
            },
          },
        ));
        return _extractImageFromImagenResponse(response.data, model);
      } catch (e) {
        lastError = e;
        if (_isModelUnavailable(e)) continue;
      }
    }
    throw lastError ?? Exception('No Imagen model available');
  }

  Uint8List _extractImageFromImagenResponse(
    Map<String, dynamic> data,
    String model,
  ) {
    final predictions = data['predictions'] as List?;
    if (predictions == null || predictions.isEmpty) {
      throw Exception('No predictions from $model');
    }

    final first = predictions[0];
    if (first is Map) {
      final b64 = first['bytesBase64Encoded'] as String?;
      if (b64 != null) return base64Decode(b64);
    }

    throw Exception('No image bytes from $model');
  }

  bool _isModelUnavailable(Object e) {
    if (e is DioException) {
      final code = e.response?.statusCode;
      return code == 404 || code == 403;
    }
    final msg = e.toString().toLowerCase();
    return msg.contains('404') ||
        msg.contains('not found') ||
        msg.contains('not supported');
  }

  /// Imagen prompts are limited to ~480 tokens — keep fallback prompts short.
  String _truncateForImagen(String prompt) {
    const maxLen = 1800;
    if (prompt.length <= maxLen) return prompt;
    return '${prompt.substring(0, maxLen)}…';
  }

  // ─────────────────────────────────────────────────────────────────
  // Retry logic for transient errors (503, 429, timeouts)
  // ─────────────────────────────────────────────────────────────────

  Future<Response> _retryOnTransient(
    Future<Response> Function() request, {
    int maxRetries = 2,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await request();
      } on DioException catch (e) {
        attempt++;
        final statusCode = e.response?.statusCode;
        final isRetryable = statusCode == 503 ||
            statusCode == 429 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout;

        if (!isRetryable || attempt > maxRetries) {
          print('*** DioException ***:');
          print('uri: ${e.requestOptions.uri}');
          print('$e');
          if (e.response != null) {
            print('*** Response ***');
            print('uri: ${e.response?.requestOptions.uri}');
            print('statusCode: ${e.response?.statusCode}');
            print('statusMessage: ${e.response?.statusMessage}');
            print('headers:');
            e.response?.headers.forEach((name, values) {
              print(' $name: ${values.join(", ")}');
            });
          }
          rethrow;
        }

        // Exponential backoff: 2s, 4s
        final delay = Duration(seconds: 2 * attempt);
        print('*** Retrying in ${delay.inSeconds}s (attempt $attempt/$maxRetries) after $statusCode ***');
        await Future.delayed(delay);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────

  void _assertApiKey() {
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception(
          'No Gemini API key found. Add GEMINI_API_KEY to your .env file.');
    }
  }

  String _getMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }
}
