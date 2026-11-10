import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:u310_app/main.dart';
import 'package:u310_app/report_data.dart';

void main() {
  testWidgets('starts without selecting a saved report', (tester) async {
    final sample = File('assets/sample.txt').readAsStringSync();
    final imported = ImportedReport.fromText('sample_AllData.txt', sample);
    SharedPreferences.setMockInitialValues({
      'u310_imports_v1': jsonEncode([imported.toStorage()]),
    });

    await tester.pumpWidget(const U310App());
    await tester.pumpAndSettle();

    expect(
      find.text(
        'برای دیدن گزارش، یکی از اندازه‌گیری‌های تاریخچه را انتخاب کنید یا فایل جدیدی وارد کنید.',
      ),
      findsOneWidget,
    );
    expect(find.text('Body Composition Analysis'), findsNothing);
  });

  testWidgets('history opens the report in a narrow window', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sample = File('assets/sample.txt').readAsStringSync();
    final imported = ImportedReport.fromText('sample_AllData.txt', sample);
    SharedPreferences.setMockInitialValues({
      'u310_imports_v1': jsonEncode([imported.toStorage()]),
    });

    await tester.pumpWidget(const U310App());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('تاریخچه'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Body Composition Analysis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
