import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportPdf {
  static Future<Uint8List> fromBoundary(RenderRepaintBoundary boundary) async {
    // OffsetLayer exposes region capture; RenderRepaintBoundary only captures
    // the full page, which can exceed the texture limit on some Windows GPUs.
    // ignore: invalid_use_of_protected_member
    final layer = boundary.layer;
    if (layer is! OffsetLayer) {
      throw StateError('گزارش هنوز برای خروجی آماده نیست.');
    }
    final size = boundary.size;
    final split = size.height / 2;
    final regions = [
      ui.Rect.fromLTWH(0, 0, size.width, split),
      ui.Rect.fromLTWH(0, split, size.width, size.height - split),
    ];
    final pngSlices = <Uint8List>[];
    for (final region in regions) {
      // Keep each raster below common GPU texture limits on Windows.
      final image = await layer.toImage(region, pixelRatio: kIsWeb ? 1.5 : 2);
      try {
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) throw StateError('تصویر گزارش ساخته نشد.');
        pngSlices.add(byteData.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    }
    return compute(_encodePdf, pngSlices);
  }
}

Future<Uint8List> _encodePdf(List<Uint8List> pngSlices) async {
  final document = pw.Document();
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (_) => pw.FullPage(
        ignoreMargins: true,
        child: pw.Column(
          children: [
            for (final pngBytes in pngSlices)
              pw.SizedBox(
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height / pngSlices.length,
                child: pw.Image(pw.MemoryImage(pngBytes), fit: pw.BoxFit.fill),
              ),
          ],
        ),
      ),
    ),
  );
  return document.save();
}
