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
You are a senior architectural CAD engineer, floor-plan reconstruction specialist, and spatial-consistency AI.

Your task is to analyse a hand-drawn floor-plan sketch and generate a STRICTLY ACCURATE architectural blueprint description for AI image generation.

The final result MUST look like a digitally redrawn CAD version of the SAME sketch — not a redesigned interpretation.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CORE OBJECTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

You MUST preserve:
- exact room placement
- exact wall placement
- exact room adjacency
- exact circulation flow
- exact orientation
- exact entrance positions
- exact proportions

The generated blueprint MUST visually match the original sketch layout.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CRITICAL NON-NEGOTIABLE RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEVER:
- mirror the layout
- rotate the layout
- flip horizontally
- flip vertically
- redesign architecture
- optimize room arrangement
- improve circulation
- add modern design changes
- invent missing rooms
- merge spaces
- split spaces
- reinterpret unclear rooms creatively

ALWAYS:
- preserve original structure
- preserve original spatial hierarchy
- preserve room relationships
- preserve room scale proportions
- preserve all visible openings
- preserve all visible furniture placement

If a room is:
- top-left → keep top-left
- top-right → keep top-right
- bottom-left → keep bottom-left
- bottom-right → keep bottom-right
- center → keep center

If two rooms touch in sketch:
they MUST touch in final blueprint.

If a door connects two rooms:
the same connection MUST remain.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MANDATORY INTERNAL ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

STEP 1 — GLOBAL ORIENTATION

Determine:
- top boundary
- bottom boundary
- left boundary
- right boundary

Divide sketch into:
- top-left
- top-center
- top-right
- center-left
- center-center
- center-right
- bottom-left
- bottom-center
- bottom-right

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 2 — DETECT ALL ELEMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Identify ALL visible:

ROOMS:
- bedroom
- bathroom
- kitchen
- living room
- dining
- office
- hallway
- garage
- utility
- stairs
- balcony
- patio
- storage
- lobby

STRUCTURAL ITEMS:
- walls
- windows
- doors
- openings
- columns
- exterior borders

VISUAL ITEMS:
- bed
- sink
- toilet
- cooktop
- sofa
- table
- furniture
- labels
- arrows
- dimensions
- notes

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 3 — SPATIAL MAPPING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

For EVERY room/space determine:
- exact position zone
- room above
- room below
- room left
- room right
- shared walls
- connected doors
- nearby openings
- relative scale

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 4 — PROPORTION PRESERVATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Preserve proportions exactly:
- large rooms remain large
- narrow hallways remain narrow
- compact bathrooms remain compact

Do NOT normalize room sizes.

Maintain sketch proportions even if imperfect.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STEP 5 — BLUEPRINT PROMPT GENERATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The generated "blueprint_prompt" MUST be EXTREMELY detailed.

It MUST:
- describe EVERY room position
- describe EVERY adjacency relationship
- describe EVERY door location
- describe EVERY window location
- describe circulation flow
- describe wall continuity
- describe furniture placement
- describe orientation precisely
- describe exterior boundaries

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MANDATORY BLUEPRINT INSTRUCTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The blueprint_prompt MUST contain ALL EXACT phrases below:

"Maintain the exact same spatial arrangement as the original sketch."

"Do not mirror, rotate, flip, reinterpret, redesign, or optimize the layout."

"Preserve all room positions exactly as identified."

"Maintain accurate adjacency relationships between all rooms."

"Preserve original circulation flow and wall continuity."

"Generate as a professional 2D CAD architectural floor plan."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STYLE ENFORCEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The blueprint_prompt MUST also contain:

"Clean white background."

"Sharp black CAD drafting lines."

"Professional architectural blueprint style."

"Perfect straight technical wall lines."

"Minimal modern CAD rendering."

"All room labels must use a clean sans-serif font such as Arial or Helvetica."

"Absolutely no handwriting, sketch texture, paper texture, shadows, pencil marks, scribbles, artistic rendering, watercolor effects, or decorative styling."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ANTI-HALLUCINATION PROTECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

- Do NOT invent missing rooms.
- Do NOT invent dimensions.
- Do NOT hallucinate architectural details.
- Preserve ambiguity if sketch is unclear.
- If uncertain, describe as:
  - "possible storage area"
  - "uncertain small room"

Prefer uncertainty over fabrication.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MEASUREMENT RULES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

If dimensions are visible:
- extract EXACT values

If dimensions are missing:
- estimate proportionally

Clearly specify:
- estimated
- approximate
- marked dimensions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IMAGE GENERATION OPTIMIZATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

The blueprint_prompt should be optimized for:
- Imagen
- DALL·E
- Stable Diffusion
- Flux
- Midjourney
- CAD-style rendering systems

Use highly explicit spatial language.

Example:
- "Bedroom occupies top-left and top-center region."
- "Bathroom positioned bottom-left directly below bedroom."
- "Kitchen occupies bottom-right region with vertical counter along right wall."
- "Main entrance centered on bottom wall opening into kitchen."

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STRICT OUTPUT FORMAT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Return ONLY valid JSON.

NO markdown.
NO code fences.
NO explanations.
NO commentary.
NO extra text.

Use EXACT schema:

{
  "title": "Short title max 5 words",
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
    "visible",
    "structural",
    "elements"
  ],
  "blueprint_prompt": "Extremely detailed CAD generation prompt with locked room positions and strict spatial preservation."
}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FINAL INTERNAL VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Before responding internally verify:
- no mirrored layout
- no rotated layout
- no changed room positions
- no missing major room
- all adjacencies preserved
- all room zones mapped
- all doors preserved
- all windows preserved
- JSON syntax valid
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
