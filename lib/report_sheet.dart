import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'report_data.dart';

const _navy = Color(0xff1c4785);
const _teal = Color(0xff45ad9b);
const _ink = Color(0xff37444c);
const _muted = Color(0xff829098);
const _soft = Color(0xffe7e9ea);
const _gradient = LinearGradient(colors: [_navy, Color(0xff276f90), _teal]);

class ReportSheet extends StatelessWidget {
  const ReportSheet({super.key, required this.measurement});
  final ReportMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    final p = measurement.toTemplate();
    return Container(
      width: 794,
      height: 1123,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xff5c656b), width: 2),
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _text(
                    'Body Composition Report',
                    18,
                    weight: FontWeight.w800,
                    color: _navy,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: _text('U310', 13, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _identity(p),
            const SizedBox(height: 9),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 470, child: _left(p)),
                  const SizedBox(width: 9),
                  Expanded(child: _right(p)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identity(Map<String, dynamic> p) {
    const flex = [13, 7, 8, 8, 8, 14];
    const labels = ['Name', 'ID', 'Gender', 'Age', 'Height', 'Date'];
    final values = [
      p['name'],
      p['id'],
      p['gender'],
      p['age'],
      '${p['height']}cm',
      p['date'],
    ];
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 6; i++)
              Expanded(
                flex: flex[i],
                child: Container(
                  height: 25,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(gradient: _gradient),
                  child: _text(
                    labels[i],
                    12,
                    color: Colors.white,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            for (var i = 0; i < 6; i++)
              Expanded(
                flex: flex[i],
                child: Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  alignment: Alignment.center,
                  color: const Color(0xffececec),
                  child: _text('${values[i]}', 10, maxLines: 1),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _left(Map<String, dynamic> p) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section('Body Composition Analysis', _composition(p)),
      const SizedBox(height: 6),
      _section(
        'Muscle / Fat Analysis',
        Column(
          children: [
            _bar(
              'Weight',
              'kg',
              'Total Body Weight',
              (p['w'] as num).toDouble(),
              45,
              150,
            ),
            _bar(
              'SMM',
              'kg',
              'Skeletal Muscle Mass',
              (p['smm'] as num).toDouble(),
              10,
              65,
            ),
            _bar(
              'BFM',
              'kg',
              'Body Fat Mass',
              (p['fm'] as num).toDouble(),
              0,
              45,
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      _section(
        'Obesity Analysis',
        Column(
          children: [
            _bar(
              'PBF',
              '%',
              'Percent Body Fat',
              (p['fat'] as num).toDouble(),
              0,
              50,
            ),
            _bar(
              'BMI',
              'kg/m²',
              'Body Mass Index',
              (p['bmi'] as num).toDouble(),
              10,
              55,
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      _section(
        'Segmental Analysis',
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _segment(
                'Segmental Muscle Analysis',
                Map<String, dynamic>.from(p['segM'] as Map),
                true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _segment(
                'Segmental Fat Analysis',
                Map<String, dynamic>.from(p['segF'] as Map),
                false,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      _section('Body Composition Change', _history(p)),
    ],
  );

  Widget _right(Map<String, dynamic> p) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _section('I-Shape', _shape(p), center: true),
      const SizedBox(height: 6),
      _section(
        'Body Type Trend',
        SizedBox(
          height: 280,
          child: CustomPaint(
            painter: _TrendPainter(
              (p['bmi'] as num).toDouble(),
              (p['fat'] as num).toDouble(),
            ),
          ),
        ),
        center: true,
      ),
      const SizedBox(height: 6),
      _section('Visceral Fat', _visceral(p), center: true),
      const SizedBox(height: 6),
      _trio(p),
      const SizedBox(height: 6),
      _section(
        'Compared To First And Last Measurement',
        _comparison(p),
        center: true,
        titleSize: 10,
      ),
    ],
  );

  Widget _section(
    String title,
    Widget child, {
    bool center = false,
    double titleSize = 13,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        height: 27,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: center ? Alignment.center : Alignment.centerLeft,
        decoration: const BoxDecoration(gradient: _gradient),
        child: _text(
          title,
          titleSize,
          color: Colors.white,
          weight: FontWeight.w800,
        ),
      ),
      child,
    ],
  );

  Widget _composition(Map<String, dynamic> p) {
    final rows = [
      ['Weight', 'Body Weight', '${p['w']}kg'],
      ['BMI', 'Body Mass Index', '${p['bmi']}'],
      ['Visceral Fat', 'Visceral Fat Level', '${p['visc']}'],
      ['Body Fat %', 'Percentage of body fat', '${p['fat']}%'],
      ['Body Fat Mass', 'Weight of body fat', '${p['fm']}kg'],
      ['SMM', 'Skeletal Muscle Mass', '${p['smm']}kg'],
      ['Muscle Mass', 'Lean Body Mass', '${p['lean']}kg'],
      ['Body Water', 'Body Water Percentage', '${p['water']}%'],
      ['Body Age', 'Estimated Body Age', '${p['bage']}'],
      ['BMR', 'Basal Metabolic Rate', '${p['bmr']}kcal'],
      ['Bone Mass', 'Bone Mineral Mass', '${p['bone']}kg'],
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Column(
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Container(
                    width: 283,
                    height: 21.6,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    color: _soft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _text(row[0], 12, weight: FontWeight.w700),
                        ),
                        Flexible(
                          child: _text('(${row[1]})', 8.6, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Container(
                      height: 21.6,
                      padding: const EdgeInsets.only(right: 10),
                      alignment: Alignment.centerRight,
                      color: _soft,
                      child: _text(row[2], 11, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bar(
    String name,
    String unit,
    String subtitle,
    double value,
    double min,
    double max,
  ) {
    final fraction = ((value - min) / (max - min)).clamp(0.02, 0.96);
    return Container(
      height: 39,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xff6c7479), width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(child: _text(name, 17)),
                    const SizedBox(width: 3),
                    _text(unit, 7, weight: FontWeight.w600),
                  ],
                ),
                _text(subtitle, 6, color: _muted),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 30),
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Positioned(
                      top: 8,
                      left: 0,
                      right: 0,
                      child: Row(
                        children: [
                          for (final item in const [
                            (Color(0xff7d98cf), 2),
                            (Color(0xff8fc6a2), 2),
                            (Color(0xfff4d9a7), 3),
                            (Color(0xffc3202a), 3),
                          ])
                            Expanded(
                              flex: item.$2,
                              child: Container(height: 7, color: item.$1),
                            ),
                        ],
                      ),
                    ),
                    for (var i = 0; i <= 10; i++)
                      Positioned(
                        left: (c.maxWidth - 18) * i / 10,
                        top: 16,
                        child: Column(
                          children: [
                            Container(
                              width: .7,
                              height: 7,
                              color: const Color(0xff9aa3a8),
                            ),
                            _text(
                              '${(min + (max - min) * i / 10).round()}',
                              6,
                              color: _muted,
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      left: 0,
                      top: 28,
                      child: Container(
                        width: c.maxWidth * fraction,
                        height: 5.5,
                        color: const Color(0xff262c30),
                      ),
                    ),
                    Positioned(
                      left: math.min(
                        c.maxWidth * fraction + 4,
                        c.maxWidth - 34,
                      ),
                      top: 24,
                      child: _text(
                        value.toStringAsFixed(1),
                        8.5,
                        weight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String title, Map<String, dynamic> values, bool muscle) =>
      Column(
        children: [
          Container(
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(gradient: _gradient),
            child: _text(
              title,
              11,
              color: Colors.white,
              weight: FontWeight.w800,
            ),
          ),
          SizedBox(
            height: 174,
            child: CustomPaint(
              painter: _BodyPainter(values: values, muscle: muscle),
              child: const SizedBox.expand(),
            ),
          ),
          Row(
            children: [
              for (final label in const [
                'Right Leg',
                'Right Arm',
                'Trunk',
                'Left Arm',
                'Left Leg',
              ])
                Expanded(
                  child: Column(
                    children: [
                      _text(label, 6.8, color: _ink, maxLines: 1),
                      Container(
                        height: 19,
                        margin: const EdgeInsets.only(top: 2, right: 2),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xfff2d9b0),
                              Color(0xffa9d6cc),
                              Color(0xff5f86c6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Container(width: 10, height: 1, color: _ink),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );

  Widget _history(Map<String, dynamic> p) {
    final history = [
      ...(p['hist'] as List),
      {
        'w': p['w'],
        'smm': p['smm'],
        'fat': p['fat'],
        'd': (p['short'] as String).split('\n').first,
      },
    ].takeLast(7).toList();
    Widget row(String label, String key, String unit, {bool date = false}) =>
        Row(
          children: [
            Container(
              width: 92,
              height: date ? 30 : 27,
              padding: const EdgeInsets.only(left: 6),
              alignment: Alignment.centerLeft,
              color: date ? const Color(0xffdcdcdc) : Colors.white,
              child: _text(
                label,
                date ? 8 : 14,
                weight: date ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Container(
                  height: date ? 30 : 27,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: date ? const Color(0xffdcdcdc) : Colors.white,
                    border: const Border(
                      left: BorderSide(color: Color(0xffb9c0c4)),
                      bottom: BorderSide(color: Color(0xff6c7479)),
                    ),
                  ),
                  child: _text(
                    i < history.length
                        ? '${history[i][key]}${date ? '' : unit}'
                        : '',
                    date ? 7 : 9,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        );
    return Column(
      children: [
        row('Weight', 'w', 'kg'),
        row('SMM', 'smm', 'kg'),
        row('PBF', 'fat', '%'),
        row('Test Date', 'd', '', date: true),
      ],
    );
  }

  Widget _shape(Map<String, dynamic> p) => SizedBox(
    height: 278,
    child: Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 9, bottom: 6),
                padding: const EdgeInsets.only(bottom: 7),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _muted)),
                ),
                child: _text('Standard', 12),
              ),
              SizedBox(
                height: 228,
                child: CustomPaint(
                  painter: _BodyPainter(
                    values: {'water': p['water']},
                    muscle: true,
                    simple: true,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: const Color(0xff9ca5aa)),
        Expanded(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 9, bottom: 16),
                padding: const EdgeInsets.only(bottom: 7),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _muted)),
                ),
                child: _text('I-Shape', 12),
              ),
              for (final label in const ['Weight', 'SMM', 'BFM'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      SizedBox(width: 44, child: _text(label, 9)),
                      for (final color in const [
                        Color(0xffb8c6e6),
                        Color(0xffa9d5c8),
                        Color(0xfff3d7b3),
                      ])
                        Container(
                          width: 17,
                          height: 18,
                          margin: const EdgeInsets.only(right: 1),
                          color: color,
                          child: color == const Color(0xffa9d5c8)
                              ? Center(
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: _ink,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 25),
              for (final label in const [
                '−   Result is Low',
                '○   Result is Normal',
                '+   Result is High',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _text(label, 7.5, color: _muted),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _visceral(Map<String, dynamic> p) => SizedBox(
    height: 48,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 3),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_text('1', 9), _text('10', 9), _text('50', 9)],
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 44,
                      child: Container(
                        height: 9,
                        color: const Color(0xffa8d3d4),
                      ),
                    ),
                    Expanded(
                      flex: 56,
                      child: Container(
                        height: 9,
                        color: const Color(0xfff4d4a9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 58,
          child: Align(
            alignment: Alignment.bottomRight,
            child: _text('${p['visc']} lv', 20, weight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  Widget _trio(Map<String, dynamic> p) => Column(
    children: [
      Row(
        children: [
          for (final label in const ['Body Age', 'Bone Mass', 'BMR'])
            Expanded(
              child: Container(
                height: 25,
                alignment: Alignment.center,
                decoration: const BoxDecoration(gradient: _gradient),
                child: _text(
                  label,
                  9,
                  color: Colors.white,
                  weight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
      Row(
        children: [
          for (final value in [
            '${p['bage']}Y',
            '${p['bone']}kg',
            '${p['bmr']}kcal',
          ])
            Expanded(
              child: Container(
                height: 39,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: _muted)),
                ),
                child: _text(value, 11),
              ),
            ),
        ],
      ),
    ],
  );

  Widget _comparison(Map<String, dynamic> p) {
    final all = [
      ...(p['hist'] as List),
      {'w': p['w'], 'fat': p['fat'], 'smm': p['smm']},
    ];
    final first = all.first as Map;
    final previous = all.length > 1 ? all[all.length - 2] as Map : first;
    String diff(String key, Map source) =>
        (((p[key] as num) - (source[key] as num)) * 10)
            .round()
            .toDouble()
            .toStringAsFixed(1);
    final rows = [
      ['Result', '${p['w']}kg', '${p['fat']}%', '${p['smm']}kg'],
      [
        'Compare To First',
        diff('w', first),
        diff('fat', first),
        diff('smm', first),
      ],
      [
        'Compare To Last',
        diff('w', previous),
        diff('fat', previous),
        diff('smm', previous),
      ],
      [
        'Max Results',
        for (final key in ['w', 'fat', 'smm'])
          all.map((e) => e[key] as num).reduce(math.max).toString(),
      ],
      [
        'Min Results',
        for (final key in ['w', 'fat', 'smm'])
          all.map((e) => e[key] as num).reduce(math.min).toString(),
      ],
    ];
    return Column(
      children: [
        Row(
          children: [
            for (final item in const ['%', 'Weight', 'Fat', 'SMM'])
              Expanded(
                child: Container(
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(gradient: _gradient),
                  child: _text(
                    item,
                    8,
                    weight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        for (final row in rows)
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 27,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0 ? _navy : Colors.white,
                      border: const Border(
                        right: BorderSide(color: Color(0xff6d777c)),
                        bottom: BorderSide(color: Color(0xff6d777c)),
                      ),
                    ),
                    child: _text(
                      row[i],
                      i == 0 ? 6.3 : 10,
                      weight: i == 0 ? FontWeight.w800 : FontWeight.w500,
                      color: i == 0 ? Colors.white : _ink,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

Text _text(
  String value,
  double size, {
  FontWeight weight = FontWeight.w500,
  Color color = _ink,
  int maxLines = 1,
  TextAlign? textAlign,
}) => Text(
  value,
  maxLines: maxLines,
  overflow: TextOverflow.ellipsis,
  textAlign: textAlign,
  style: TextStyle(
    fontSize: size,
    height: 1.0,
    fontWeight: weight,
    color: color,
    fontFamily: 'Arial',
    fontFeatures: const [FontFeature.tabularFigures()],
  ),
);

extension _TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int count) => skip(math.max(0, length - count));
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.values,
    required this.muscle,
    this.simple = false,
  });
  final Map<String, dynamic> values;
  final bool muscle;
  final bool simple;

  static const _standingHalf = <Offset>[
    Offset(100, 5),
    Offset(110, 8),
    Offset(117, 18),
    Offset(118, 29),
    Offset(115, 43),
    Offset(110, 58),
    Offset(112, 66),
    Offset(128, 72),
    Offset(145, 80),
    Offset(152, 96),
    Offset(155, 130),
    Offset(160, 190),
    Offset(165, 231),
    Offset(162, 244),
    Offset(154, 244),
    Offset(150, 218),
    Offset(145, 160),
    Offset(138, 119),
    Offset(132, 155),
    Offset(139, 220),
    Offset(141, 250),
    Offset(134, 310),
    Offset(128, 360),
    Offset(122, 402),
    Offset(108, 404),
    Offset(105, 350),
    Offset(103, 285),
    Offset(100, 240),
  ];

  static const _flexHalf = <Offset>[
    Offset(100, 5),
    Offset(110, 8),
    Offset(117, 18),
    Offset(118, 29),
    Offset(115, 43),
    Offset(110, 58),
    Offset(112, 66),
    Offset(127, 71),
    Offset(145, 75),
    Offset(160, 70),
    Offset(169, 58),
    Offset(166, 39),
    Offset(170, 26),
    Offset(181, 24),
    Offset(191, 34),
    Offset(192, 65),
    Offset(186, 91),
    Offset(175, 101),
    Offset(145, 107),
    Offset(138, 125),
    Offset(132, 155),
    Offset(139, 220),
    Offset(141, 250),
    Offset(134, 310),
    Offset(128, 360),
    Offset(122, 402),
    Offset(108, 404),
    Offset(105, 350),
    Offset(103, 285),
    Offset(100, 240),
  ];

  Path _outline(List<Offset> half, double scale, double x, double y) {
    final points = <Offset>[
      ...half,
      ...half
          .sublist(1, half.length - 1)
          .reversed
          .map((p) => Offset(200 - p.dx, p.dy)),
    ];
    final path = Path()
      ..moveTo(x + points.first.dx * scale, y + points.first.dy * scale);
    for (var i = 0; i < points.length; i++) {
      final p0 = points[(i - 1 + points.length) % points.length];
      final p1 = points[i];
      final p2 = points[(i + 1) % points.length];
      final p3 = points[(i + 2) % points.length];
      path.cubicTo(
        x + (p1.dx + (p2.dx - p0.dx) / 6) * scale,
        y + (p1.dy + (p2.dy - p0.dy) / 6) * scale,
        x + (p2.dx - (p3.dx - p1.dx) / 6) * scale,
        y + (p2.dy - (p3.dy - p1.dy) / 6) * scale,
        x + p2.dx * scale,
        y + p2.dy * scale,
      );
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (simple ? size.height - 6 : size.height - 8) / 410;
    final left = (size.width - 200 * scale) / 2;
    const top = 2.0;
    final path = _outline(
      muscle && !simple ? _flexHalf : _standingHalf,
      scale,
      left,
      top,
    );
    final bounds = Rect.fromLTWH(left, top, 200 * scale, 410 * scale);
    canvas.drawShadow(path, const Color(0x550d314b), simple ? 2 : 1.5, false);
    final colors = simple
        ? const [_navy, Color(0xff245f8d), _teal]
        : muscle
        ? const [Color(0xfff9e0bc), Color(0xfff0c98f)]
        : const [Color(0xffe4ecf8), Color(0xffc7d7ed)];
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(bounds),
    );
    if (simple) {
      final percentage = ((values['water'] as num?)?.toDouble() ?? 50).clamp(
        0,
        100,
      );
      final level = top + (406 - percentage / 100 * 400) * scale;
      final wave = Path()..moveTo(left, level);
      for (var i = 0; i <= 200; i += 4) {
        wave.lineTo(left + i * scale, level + math.sin(i * .07) * 2 * scale);
      }
      wave
        ..lineTo(left + 200 * scale, top + 410 * scale)
        ..lineTo(left, top + 410 * scale)
        ..close();
      canvas.save();
      canvas.clipPath(path);
      canvas.drawPath(wave, Paint()..color = const Color(0x804fc6b2));
      canvas.restore();
    }
    if (simple) return;
    final line = Paint()
      ..color = _ink
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    void label(
      String key,
      String caption,
      Offset point,
      Offset target,
      bool onLeft,
    ) {
      final a = Offset(left + point.dx * scale, top + point.dy * scale);
      final b = Offset(onLeft ? 62 : size.width - 62, target.dy);
      final leader = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo((a.dx + b.dx) / 2, a.dy, (a.dx + b.dx) / 2, b.dy, b.dx, b.dy);
      canvas.drawPath(leader, line);
      canvas.drawCircle(a, 2.1, Paint()..color = _ink);
      final tp = TextPainter(
        text: TextSpan(
          text: '$caption\n${values[key]}kg',
          style: const TextStyle(
            fontFamily: 'Arial',
            fontSize: 7.4,
            height: 1.2,
            color: _ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(onLeft ? 1 : size.width - tp.width - 1, b.dy - 17),
      );
    }

    label('tr', 'Trunk', const Offset(100, 110), const Offset(0, 27), false);
    label('ra', 'Right Arm', const Offset(45, 120), const Offset(0, 64), true);
    label('la', 'Left Arm', const Offset(155, 120), const Offset(0, 64), false);
    label('rl', 'Right Leg', const Offset(87, 300), const Offset(0, 137), true);
    label(
      'll',
      'Left Leg',
      const Offset(113, 300),
      const Offset(0, 137),
      false,
    );
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.values != values || old.muscle != muscle || old.simple != simple;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.bmi, this.fat);
  final double bmi;
  final double fat;

  @override
  void paint(Canvas canvas, Size size) {
    const x = 25.0, y = 17.0, side = 225.0;
    final rect = Rect.fromLTWH(x, y, side, side);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [_navy, Color(0xff2b7591), _teal],
        ).createShader(rect),
    );
    final line = Paint()
      ..color = const Color(0xffd6efe9)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(x + side * i / 3, y),
        Offset(x + side * i / 3, y + side),
        line,
      );
      canvas.drawLine(
        Offset(x, y + side * i / 3),
        Offset(x + side, y + side * i / 3),
        line,
      );
    }
    const cells = [
      ['Athletic', 'Over Weight\nMuscular', 'Obese'],
      ['Low Fat\nMuscular', 'Standard', 'Over Fat'],
      ['Low Fat\nLow Weight', 'Low Weight', 'Skinny Fat'],
    ];
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final tp = TextPainter(
          text: TextSpan(
            text: cells[r][c],
            style: const TextStyle(
              fontFamily: 'Arial',
              fontSize: 7.3,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 74);
        tp.paint(
          canvas,
          Offset(
            x + c * 75 + (75 - tp.width) / 2,
            y + r * 75 + (75 - tp.height) / 2,
          ),
        );
      }
    }
    final px = x + ((fat / 40).clamp(.07, .95)) * side;
    final py = y + (1 - ((bmi - 12) / 23).clamp(.07, .95)) * side;
    canvas.drawCircle(Offset(px, py), 5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(px, py), 2, Paint()..color = _navy);
    final axis = Paint()
      ..color = _ink
      ..strokeWidth = 1.2;
    canvas.drawLine(
      const Offset(x - 5, y + side + 5),
      const Offset(x - 5, y - 11),
      axis,
    );
    canvas.drawLine(
      const Offset(x - 5, y + side + 5),
      const Offset(x + side + 11, y + side + 5),
      axis,
    );
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Body Fat (%)',
        style: TextStyle(fontFamily: 'Arial', fontSize: 11, color: _ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(x + (side - tp.width) / 2, y + side + 16));
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.bmi != bmi || old.fat != fat;
}
