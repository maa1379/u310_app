import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:u310_app/report_data.dart';

void main() {
  test('reads the synthetic Base64 report and converts source units', () {
    final content = File('assets/sample.txt').readAsStringSync();
    final imported = ImportedReport.fromText(
      'sample_AllData_2026-11-09 12.00.00.txt',
      content,
    );
    final report = imported.measurements.single.toTemplate();

    expect(report['name'], 'sample');
    expect(report['height'], 175);
    expect(report['age'], 31);
    expect(report['w'], 70.0);
    expect(report['bmi'], 22.9);
    expect(report['fat'], 20.0);
    expect(report['fm'], 14.0);
    expect((report['segM'] as Map)['tr'], 30.0);
    expect((report['segF'] as Map)['ra'], 0.7);
  });

  test('rejects text without measurements', () {
    expect(
      () => ImportedReport.fromText('broken.txt', '{"DataArray":[]}'),
      throwsFormatException,
    );
  });
}
