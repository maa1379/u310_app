import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:u310_app/report_data.dart';
import 'package:u310_app/report_pdf.dart';
import 'package:u310_app/report_sheet.dart';

void main() {
  testWidgets('A4 report renders all sections without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final text = File('assets/sample.txt').readAsStringSync();
    final report = ImportedReport.fromText(
      'sample_AllData.txt',
      text,
    ).measurements.single;
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: key,
              child: ReportSheet(measurement: report),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Body Composition Analysis'), findsOneWidget);
    expect(find.text('Segmental Analysis'), findsOneWidget);
    expect(find.text('Body Type Trend'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() => ReportPdf.fromBoundary(boundary));
    expect(bytes, isNotNull);
    expect(String.fromCharCodes(bytes!.take(5)), '%PDF-');
  });
}
