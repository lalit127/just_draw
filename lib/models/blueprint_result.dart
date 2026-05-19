class Measurement {
  final String label;
  final String value;
  final String unit;

  const Measurement({
    required this.label,
    required this.value,
    required this.unit,
  });

  factory Measurement.fromJson(Map<String, dynamic> json) => Measurement(
    label: json['label'] as String? ?? '',
    value: json['value'] as String? ?? '',
    unit: json['unit'] as String? ?? '',
  );

  String get display => '$value $unit';
}

class BlueprintAnalysis {
  final String title;
  final String description;
  final List<Measurement> measurements;
  final List<String> elements;
  final String blueprintPrompt;

  const BlueprintAnalysis({
    required this.title,
    required this.description,
    required this.measurements,
    required this.elements,
    required this.blueprintPrompt,
  });

  factory BlueprintAnalysis.fromJson(Map<String, dynamic> json) {
    return BlueprintAnalysis(
      title: json['title'] as String? ?? 'Blueprint',
      description: json['description'] as String? ?? '',
      measurements: (json['measurements'] as List? ?? [])
          .where((e) => e is Map)
          .map((e) => Measurement.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      elements: (json['elements'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      blueprintPrompt: (json['blueprint_prompt'] ??
          json['blueprintPrompt'] ??
          json['prompt'] ??
          '') as String,
    );
  }
}
