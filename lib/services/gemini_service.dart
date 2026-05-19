import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:just_draw/models/blueprint_result.dart';

class GeminiService {
  final String apiKey;
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  final Dio _dio;

  GeminiService({required this.apiKey})
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 120),
          sendTimeout: const Duration(seconds: 60),
        ),
      ) {
    _dio.interceptors.add(
      LogInterceptor(requestBody: false, responseBody: false, error: true),
    );
  }

  /// Step 1: Analyse the sketch and extract measurements + description
  Future<BlueprintAnalysis> analyseSketch(File imageFile) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Please enter a valid Gemini API Key first.');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = _getMimeType(imageFile.path);

    final prompt = r'''
You are a senior architectural CAD engineer and spatial-layout reconstruction AI.

Your job is to convert a rough hand-drawn floor-plan sketch into a STRICTLY ACCURATE architectural blueprint description for AI image generation.

==================================================
PRIMARY OBJECTIVE
==================================================

You MUST preserve the EXACT layout from the sketch.

The final blueprint MUST look like a clean professional CAD redraw of the SAME floor plan — NOT a redesigned interpretation.

==================================================
ABSOLUTE SPATIAL RULES (VERY IMPORTANT)
==================================================

1. NEVER:
- mirror the layout
- rotate the layout
- flip horizontally
- flip vertically
- redesign room positions
- creatively reinterpret spaces
- improve architecture
- optimize circulation
- invent missing rooms

2. ALWAYS:
- preserve exact room positions
- preserve wall continuity
- preserve adjacency relationships
- preserve corridor flow
- preserve entrance placement
- preserve room proportions
- preserve orientation

3. If a room appears:
- top-left → it MUST remain top-left
- top-right → it MUST remain top-right
- center-left → it MUST remain center-left
- bottom-right → it MUST remain bottom-right

4. If two rooms share a wall in the sketch:
they MUST share a wall in the generated blueprint.

5. If a corridor connects spaces in a specific order:
that circulation order MUST remain identical.

==================================================
MANDATORY ANALYSIS PROCESS
==================================================

STEP 1 — DETERMINE GLOBAL ORIENTATION

Identify:
- top edge
- bottom edge
- left edge
- right edge

Then divide sketch into:
- top-left
- top-center
- top-right
- center-left
- center-center
- center-right
- bottom-left
- bottom-center
- bottom-right

==================================================
STEP 2 — IDENTIFY ALL SPACES
==================================================

Detect EVERY visible element including:

ROOMS:
- bedrooms
- bathrooms
- kitchen
- dining
- living room
- office
- garage
- utility
- storage
- stairs
- balcony
- patio
- hallway
- lobby

STRUCTURAL ELEMENTS:
- walls
- windows
- doors
- openings
- columns
- exterior boundaries

VISUAL ELEMENTS:
- furniture
- arrows
- dimensions
- labels
- notes
- symbols

==================================================
STEP 3 — SPATIAL RELATIONSHIP MAPPING
==================================================

For EVERY room/space provide:
- exact positional zone
- what exists above it
- what exists below it
- what exists left of it
- what exists right of it
- connected spaces
- shared walls
- nearby corridors/openings

==================================================
STEP 4 — PROPORTION PRESERVATION
==================================================

Maintain original proportions:
- large rooms stay large
- narrow corridors stay narrow
- compact bathrooms stay compact

DO NOT normalize room sizes.

==================================================
STEP 5 — BLUEPRINT PROMPT CONSTRUCTION
==================================================

The "blueprint_prompt" MUST be EXTREMELY DETAILED.

It MUST:
- describe EVERY room location
- describe EVERY adjacency
- describe circulation flow
- describe orientation
- describe room proportions
- describe entrances/exits
- describe wall alignments

==================================================
MANDATORY PHRASES
==================================================

The "blueprint_prompt" MUST contain ALL of these exact instructions:

"Maintain the exact same spatial arrangement as the original sketch."

"Do not mirror, rotate, flip, reinterpret, or redesign the layout."

"Preserve all room positions exactly as identified."

"Maintain accurate adjacency relationships between all rooms."

"Generate as a professional 2D CAD architectural floor plan."

==================================================
STYLE REQUIREMENTS
==================================================

The blueprint_prompt MUST also contain:

"Clean white background, sharp black CAD lines, professional engineering blueprint."

"All room labels must use a clean professional sans-serif font such as Arial or Helvetica."

"Absolutely no handwriting, sketch texture, pencil marks, scribbles, shadows, paper texture, or artistic effects."

"Perfect straight CAD wall lines."

"Technical architectural drafting style."

==================================================
ANTI-HALLUCINATION RULES
==================================================

- Do NOT invent dimensions unless estimated.
- Do NOT invent rooms not visible in sketch.
- If unclear, label as:
  "uncertain small room"
  or
  "possible storage area"

- Preserve ambiguity rather than hallucinating details.

==================================================
MEASUREMENT RULES
==================================================

If dimensions exist:
- extract them exactly

If missing:
- estimate proportionally

Clearly mention:
- estimated
- approximate
- marked dimensions

==================================================
OUTPUT FORMAT
==================================================

Return ONLY VALID JSON.

NO markdown.
NO explanations.
NO commentary.
NO code fences.

Use EXACT structure:

{
  "title": "Short descriptive title max 5 words",
  "description": "Concise overview max 15 words",
  "measurements": [
    {
      "label": "Overall Width",
      "value": "value",
      "unit": "m or cm or ft"
    },
    {
      "label": "Overall Height",
      "value": "value",
      "unit": "m or cm or ft"
    }
  ],
  "elements": [
    "list",
    "of",
    "visible",
    "elements"
  ],
  "blueprint_prompt": "Extremely detailed CAD blueprint generation prompt with explicit room-by-room positioning and locked spatial relationships."
}

==================================================
FINAL VALIDATION BEFORE RESPONSE
==================================================

Before generating output internally verify:

- no room position changed
- no mirrored layout
- no rotated layout
- all rooms mapped
- all adjacency relationships preserved
- all positional zones described
- JSON is syntactically valid
- blueprint_prompt contains all mandatory phrases

RETURN ONLY JSON.
''';
    final response = await _dio.post(
      '$_baseUrl/models/gemini-2.5-flash:generateContent?key=$apiKey',
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
          'temperature': 0.2,
          'topK': 32,
          'topP': 1,
          'responseMimeType': 'application/json',
        },
      },
    );

    final text =
        response.data['candidates'][0]['content']['parts'][0]['text'] as String;

    // Extract only the JSON object between the first '{' and last '}'
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw Exception('Invalid JSON response returned by Gemini analysis.');
    }
    final cleaned = text.substring(start, end + 1);

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    return BlueprintAnalysis.fromJson(json);
  }

  /// Step 2: Generate a professional blueprint image using Imagen via Gemini
  Future<Uint8List> generateBlueprintImage(String blueprintPrompt) async {
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY') {
      throw Exception('Please enter a valid Gemini API Key first.');
    }

    print('Generating blueprint image using Imagen 4...');
    final response = await _dio.post(
      '$_baseUrl/models/imagen-4.0-generate-001:predict?key=$apiKey',
      data: {
        'instances': [
          {'prompt': blueprintPrompt},
        ],
        'parameters': {
          'sampleCount': 1,
          'aspectRatio': '1:1',
          'outputMimeType': 'image/jpeg',
        },
      },
    );

    print('Imagen 4 API Response Status: ${response.statusCode}');
    final predictions = response.data['predictions'] as List?;
    if (predictions != null && predictions.isNotEmpty) {
      print('Successfully retrieved blueprint image.');
      final base64Image = predictions[0]['bytesBase64Encoded'] as String;
      return base64Decode(base64Image);
    }

    throw Exception('No image returned from Gemini image generation.');
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
