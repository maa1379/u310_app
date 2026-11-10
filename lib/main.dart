import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'report_data.dart';
import 'report_pdf.dart';
import 'report_sheet.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const U310App());
}

class U310App extends StatefulWidget {
  const U310App({super.key});

  @override
  State<U310App> createState() => _U310AppState();
}

class _U310AppState extends State<U310App> {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'گزارش ترکیب بدن U310',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1c4785)),
      scaffoldBackgroundColor: const Color(0xffe9eef0),
    ),
    home: const ReportHome(),
  );
}

class ReportHome extends StatefulWidget {
  const ReportHome({super.key});

  @override
  State<ReportHome> createState() => _ReportHomeState();
}

class _ReportHomeState extends State<ReportHome> {
  static const _storageKey = 'u310_imports_v1';
  final _sheetKey = GlobalKey();
  final _sidebarScrollController = ScrollController();
  final _historySheetScrollController = ScrollController();
  final List<ImportedReport> _imports = [];
  ReportMeasurement? _selected;
  bool _loading = true;
  bool _busy = false;
  String _busyMessage = 'در حال آماده‌سازی گزارش…';
  String? _error;
  ReportMeasurement? _pdfFor;
  Uint8List? _cachedPdf;
  Future<Uint8List>? _pdfJob;

  @override
  void initState() {
    FlutterNativeSplash.remove();
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    _historySheetScrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      if (stored != null) {
        for (final item in jsonDecode(stored) as List) {
          _imports.add(
            ImportedReport.fromStorage(Map<String, dynamic>.from(item as Map)),
          );
        }
      }
      if (mounted) setState(() => _loading = false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'بارگذاری تاریخچه انجام نشد: $error';
        });
      }
    }
  }

  List<ReportMeasurement> get _allMeasurements {
    final list = [for (final item in _imports) ...item.measurements];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(_imports.map((e) => e.toStorage()).toList()),
    );
  }

  Future<void> _importFile() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyMessage = 'در حال دریافت فایل…';
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.bytes == null) {
        throw const FormatException('امکان خواندن فایل انتخاب‌شده وجود ندارد.');
      }
      if (!mounted) return;
      setState(() => _busyMessage = 'در حال پردازش اندازه‌گیری‌ها…');
      await WidgetsBinding.instance.endOfFrame;
      final imported = ImportedReport.fromText(
        file.name,
        utf8.decode(file.bytes!),
      );
      if (_imports.any(
        (item) => jsonEncode(item.payload) == jsonEncode(imported.payload),
      )) {
        _notice('این فایل قبلاً وارد شده است.');
        return;
      }
      setState(() {
        _imports.insert(0, imported);
        _selected = imported.measurements.last;
        _error = null;
        _pdfFor = null;
        _cachedPdf = null;
        _pdfJob = null;
      });
      await _persist();
      _notice('گزارش به تاریخچه اضافه شد.');
    } catch (error) {
      _notice(
        error is FormatException
            ? error.message
            : 'وارد کردن فایل انجام نشد: $error',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List> _createPdf() async {
    final boundary =
        _sheetKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('گزارشی برای خروجی گرفتن آماده نیست.');
    }
    return ReportPdf.fromBoundary(boundary);
  }

  Future<Uint8List> _ensurePdf(ReportMeasurement measurement) {
    if (identical(_pdfFor, measurement)) {
      if (_cachedPdf != null) return Future.value(_cachedPdf);
      if (_pdfJob != null) return _pdfJob!;
    }
    _pdfFor = measurement;
    _cachedPdf = null;
    final job = _createPdf();
    _pdfJob = job;
    return job.then(
      (bytes) {
        if (identical(_pdfFor, measurement)) {
          _cachedPdf = bytes;
          _pdfJob = null;
        }
        return bytes;
      },
      onError: (Object error, StackTrace stack) {
        if (identical(_pdfFor, measurement)) _pdfJob = null;
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  Future<void> _export({required bool print}) async {
    if (_selected == null || _busy) return;
    setState(() {
      _busy = true;
      _busyMessage = 'در حال ساخت فایل PDF…';
    });
    try {
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final bytes = await _ensurePdf(_selected!);
      if (!mounted) return;
      setState(
        () => _busyMessage = print
            ? 'در حال باز کردن پنجره چاپ…'
            : 'در حال ذخیره فایل…',
      );
      if (print) {
        await Printing.layoutPdf(
          name: 'U310-${_selected!.name}',
          onLayout: (_) async => bytes,
        );
      } else {
        final safeName = _selected!.name.replaceAll(
          RegExp(r'[^a-zA-Z0-9_-]'),
          '_',
        );
        final date = _selected!.date.split(' ').first;
        final fileName = 'U310_${safeName}_$date.pdf';
        if (kIsWeb) {
          final saved = await Printing.sharePdf(
            bytes: bytes,
            filename: fileName,
          );
          if (saved) _notice('فایل PDF دانلود شد.');
        } else {
          final path = await FilePicker.platform.saveFile(
            dialogTitle: 'ذخیره گزارش PDF',
            fileName: fileName,
            type: FileType.custom,
            allowedExtensions: ['pdf'],
            bytes: bytes,
          );
          if (path != null) _notice('فایل PDF ذخیره شد.');
        }
      }
    } catch (error) {
      _notice('ساخت خروجی انجام نشد: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _delete(ImportedReport imported) async {
    setState(() {
      _imports.remove(imported);
      _selected = null;
      _pdfFor = null;
      _cachedPdf = null;
      _pdfJob = null;
    });
    await _persist();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 1080;
              return Row(
                children: [
                  if (desktop) SizedBox(width: 284, child: _sidebar()),
                  Expanded(
                    child: Column(
                      children: [
                        _toolbar(desktop),
                        Expanded(child: _viewer()),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          if (_busy)
            Positioned.fill(
              child: AbsorbPointer(
                child: ColoredBox(
                  color: const Color(0x99102d47),
                  child: Center(
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 20),
                          Text(
                            _busyMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _sidebar() => Container(
    decoration: const BoxDecoration(
      color: Color(0xff102d47),
      border: Border(left: BorderSide(color: Color(0xff24627c))),
    ),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 6),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff45ad9b),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'U310',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'گزارش ترکیب بدن',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xffb3cbd5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 26, 20, 10),
            child: Text(
              'تاریخچه اندازه‌گیری‌ها',
              style: TextStyle(
                color: Color(0xffb3cbd5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: _historyList(dark: true)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: _importFile,
              icon: const Icon(Icons.add),
              label: const Text('وارد کردن فایل متن'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff45ad9b),
                foregroundColor: const Color(0xff102d47),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _toolbar(bool desktop) => Container(
    height: desktop ? 78 : 70,
    padding: EdgeInsets.symmetric(horizontal: desktop ? 28 : 8),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xffdce5e8))),
    ),
    child: Row(
      children: [
        if (!desktop)
          IconButton(
            tooltip: 'تاریخچه',
            onPressed: _showHistory,
            icon: const Icon(Icons.history),
          ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selected?.name ?? 'گزارش ترکیب بدن',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  color: Color(0xff183c5a),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _selected == null
                    ? 'فایل متن را وارد کنید'
                    : 'اندازه‌گیری ${_selected!.date}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xff687d88)),
              ),
            ],
          ),
        ),
        if (desktop) ...[
          OutlinedButton.icon(
            onPressed: _importFile,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('وارد کردن فایل'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _export(print: true),
            icon: const Icon(Icons.print_outlined),
            label: const Text('چاپ'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _busy ? null : () => _export(print: false),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('ذخیره PDF'),
          ),
        ] else ...[
          IconButton(
            tooltip: 'وارد کردن فایل',
            onPressed: _importFile,
            icon: const Icon(Icons.upload_file_outlined),
          ),
          IconButton(
            tooltip: 'چاپ',
            onPressed: _busy ? null : () => _export(print: true),
            icon: const Icon(Icons.print_outlined),
          ),
          IconButton(
            tooltip: 'ذخیره PDF',
            onPressed: _busy ? null : () => _export(print: false),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ],
    ),
  );

  Widget _viewer() {
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_selected == null) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xffd3e8e7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    size: 40,
                    color: Color(0xff1c4785),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'گزارش ترکیب بدن',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: Color(0xff183c5a),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _imports.isEmpty
                      ? 'برای شروع، فایل متن خروجی دستگاه را وارد کنید.'
                      : 'برای دیدن گزارش، یکی از اندازه‌گیری‌های تاریخچه را انتخاب کنید یا فایل جدیدی وارد کنید.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.7, color: Color(0xff647984)),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: _importFile,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('وارد کردن فایل متن'),
                ),
                if (_imports.isNotEmpty)
                  TextButton.icon(
                    onPressed: _showHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('انتخاب از تاریخچه'),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ((constraints.maxWidth - 24) / 794).clamp(0.1, 1.0);
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            12,
            constraints.maxWidth >= 860 ? 24 : 12,
            12,
            32,
          ),
          child: Center(
            child: SizedBox(
              width: 794 * scale,
              height: 1123 * scale,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 794,
                maxWidth: 794,
                minHeight: 1123,
                maxHeight: 1123,
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topLeft,
                  child: RepaintBoundary(
                    key: _sheetKey,
                    child: ReportSheet(measurement: _selected!),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _historyList({required bool dark}) {
    final items = _allMeasurements;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'هنوز گزارشی وارد نشده است.',
          style: TextStyle(color: dark ? Colors.white70 : Colors.black54),
        ),
      );
    }
    final controller = dark
        ? _sidebarScrollController
        : _historySheetScrollController;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ScrollbarTheme(
        data: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(
            dark ? const Color(0xffa3c0cb) : const Color(0xff557381),
          ),
        ),
        child: Scrollbar(
          controller: controller,
          thumbVisibility: true,
          interactive: true,
          thickness: 6,
          radius: const Radius.circular(6),
          child: _historyListView(items, dark, controller),
        ),
      ),
    );
  }

  Widget _historyListView(
    List<ReportMeasurement> items,
    bool dark,
    ScrollController controller,
  ) => ListView.builder(
    controller: controller,
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      final selected =
          identical(item.imported, _selected?.imported) &&
          item.index == _selected?.index;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Material(
          color: selected
              ? (dark ? const Color(0xff235770) : const Color(0xffdceef0))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: () {
              setState(() {
                _selected = item;
                _pdfFor = null;
                _cachedPdf = null;
                _pdfJob = null;
              });
              if (!dark) Navigator.pop(context);
            },
            leading: Icon(
              Icons.description_outlined,
              color: selected
                  ? const Color(0xff63d6bf)
                  : (dark ? const Color(0xffa3c0cb) : const Color(0xff557381)),
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark ? Colors.white : const Color(0xff183c5a),
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              item.date,
              style: TextStyle(
                fontSize: 11,
                color: dark ? const Color(0xffb3cbd5) : const Color(0xff647984),
              ),
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'گزینه‌های فایل',
              icon: Icon(
                Icons.more_vert,
                color: dark ? Colors.white70 : Colors.black54,
              ),
              onSelected: (choice) {
                if (choice == 'delete') _delete(item.imported);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('حذف فایل از تاریخچه'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  void _showHistory() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'تاریخچه اندازه‌گیری‌ها',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(child: _historyList(dark: false)),
            ],
          ),
        ),
      ),
    ),
  );
}

