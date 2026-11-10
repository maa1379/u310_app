import 'dart:convert';

class ImportedReport {
  const ImportedReport({
    required this.fileName,
    required this.importedAt,
    required this.payload,
  });

  final String fileName;
  final DateTime importedAt;
  final Map<String, dynamic> payload;

  factory ImportedReport.fromText(String fileName, String content) {
    final trimmed = content.trim();
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException {
      try {
        decoded = jsonDecode(
          utf8.decode(base64.decode(base64.normalize(trimmed))),
        );
      } on FormatException {
        throw const FormatException(
          'فایل باید JSON یا متن Base64 حاوی JSON باشد.',
        );
      }
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['DataArray'] is! List ||
        (decoded['DataArray'] as List).isEmpty) {
      throw const FormatException('در فایل اندازه‌گیری معتبری پیدا نشد.');
    }
    for (final item in decoded['DataArray'] as List) {
      if (item is! Map<String, dynamic> ||
          item['date'] is! String ||
          item['weight'] is! num) {
        throw const FormatException('ساختار یکی از اندازه‌گیری‌ها معتبر نیست.');
      }
    }
    return ImportedReport(
      fileName: fileName,
      importedAt: DateTime.now(),
      payload: decoded,
    );
  }

  factory ImportedReport.fromStorage(Map<String, dynamic> data) =>
      ImportedReport(
        fileName: data['fileName'] as String,
        importedAt: DateTime.parse(data['importedAt'] as String),
        payload: Map<String, dynamic>.from(data['payload'] as Map),
      );

  Map<String, dynamic> toStorage() => {
    'fileName': fileName,
    'importedAt': importedAt.toIso8601String(),
    'payload': payload,
  };

  String get displayName {
    final base = fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
    return base.split(RegExp(r'_AllData_', caseSensitive: false)).first;
  }

  List<ReportMeasurement> get measurements {
    final source =
        (payload['DataArray'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList()
          ..sort(
            (a, b) => (a['date'] as String).compareTo(b['date'] as String),
          );
    return [
      for (var index = 0; index < source.length; index++)
        ReportMeasurement(this, source, index),
    ];
  }
}

class ReportMeasurement {
  const ReportMeasurement(this.imported, this.source, this.index);

  final ImportedReport imported;
  final List<Map<String, dynamic>> source;
  final int index;

  Map<String, dynamic> get data => source[index];
  String get date => data['date'] as String;
  String get name => imported.displayName;

  double _scaled(Map<String, dynamic> item, String key, double divisor) =>
      ((item[key] as num?)?.toDouble() ?? 0) / divisor;

  double get weight => _scaled(data, 'weight', 100);
  double get fat => _scaled(data, 'bodyFat', 10);

  Map<String, dynamic> toTemplate() {
    final birthday = DateTime.tryParse(
      (imported.payload['Birthday'] as String?) ?? '',
    );
    final measured = DateTime.tryParse(date.replaceFirst(' ', 'T'));
    final age = birthday == null || measured == null
        ? 0
        : measured.year -
              birthday.year -
              ((measured.month < birthday.month ||
                      (measured.month == birthday.month &&
                          measured.day < birthday.day))
                  ? 1
                  : 0);
    final height = ((imported.payload['Height'] as num?)?.toDouble() ?? 0) / 10;
    final bmi = _scaled(data, 'bmi', 10);
    final bodyFat = fat;
    final bodyWeight = weight;
    final shortDate = measured == null
        ? date
        : '${measured.year.toString().padLeft(4, '0')}.${measured.month.toString().padLeft(2, '0')}.${measured.day.toString().padLeft(2, '0')}\n${measured.hour.toString().padLeft(2, '0')}:${measured.minute.toString().padLeft(2, '0')}';
    double one(String key, [double divisor = 10]) =>
        _scaled(data, key, divisor);
    return {
      'name': name,
      'id': (data['deviceId'] as num?) == 0
          ? '—'
          : '${data['deviceId'] ?? '—'}',
      'gender': imported.payload['Gender'] == 0 ? 'Female' : 'Male',
      'age': age,
      'height': height,
      'date': date,
      'short': shortDate,
      'w': bodyWeight,
      'bmi': bmi,
      'visc': data['vatLevel'] ?? 0,
      'fat': bodyFat,
      'fm': double.parse((bodyWeight * bodyFat / 100).toStringAsFixed(2)),
      'smm': one('smm'),
      'lean': one('muscleMass'),
      'water': one('bodyWater'),
      'bage': data['bodyAge'] ?? 0,
      'bmr': data['bmr'] ?? 0,
      'bone': one('boneMass'),
      'segM': {
        'tr': one('muscleMassTrunk'),
        'ra': one('muscleMassRightArm'),
        'la': one('muscleMassLeftArm'),
        'rl': one('muscleMassRightLeg'),
        'll': one('muscleMassLeftLeg'),
      },
      'segF': {
        'tr': one('bodyFatTrunkMass'),
        'ra': one('bodyFatRightArmMass'),
        'la': one('bodyFatLeftArmMass'),
        'rl': one('bodyFatRightLegMass'),
        'll': one('bodyFatLeftLegMass'),
      },
      'hist': [
        for (final prior in source.take(index))
          {
            'w': _scaled(prior, 'weight', 100),
            'smm': _scaled(prior, 'smm', 10),
            'fat': _scaled(prior, 'bodyFat', 10),
            'd': (prior['date'] as String)
                .split(' ')
                .first
                .replaceAll('-', '.'),
          },
      ],
    };
  }
}
