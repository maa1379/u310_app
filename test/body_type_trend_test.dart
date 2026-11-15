import 'package:flutter_test/flutter_test.dart';
import 'package:u310_app/body_type_trend.dart';

void main() {
  test('assigns all nine cells from fat and muscle percentages', () {
    for (final (fat, column) in [(10.0, 0), (20.0, 1), (35.0, 2)]) {
      for (final (muscle, row) in [(25.0, 2), (35.0, 1), (50.0, 0)]) {
        final trend = BodyTypeTrend(
          bodyFatPercent: fat,
          skeletalMusclePercent: muscle,
        );
        expect(trend.column, column);
        expect(trend.row, row);
      }
    }
  });

  test('uses skeletal muscle as a share of weight and respects boundaries', () {
    final moderate = BodyTypeTrend.fromMeasurement(
      weightKg: 70,
      skeletalMuscleKg: 28,
      bodyFatPercent: 15,
    );
    expect(moderate.skeletalMusclePercent, 40);
    expect(moderate.row, 1);
    expect(moderate.column, 1);

    final highMuscle = BodyTypeTrend.fromMeasurement(
      weightKg: 70,
      skeletalMuscleKg: 31.5,
      bodyFatPercent: 30,
    );
    expect(highMuscle.row, 0);
    expect(highMuscle.column, 2);
  });

  test('marker falls in its matching cell', () {
    final trend = BodyTypeTrend.fromMeasurement(
      weightKg: 70,
      skeletalMuscleKg: 33,
      bodyFatPercent: 20,
    );
    expect(trend.plotX, inInclusiveRange(1 / 3, 2 / 3));
    expect(trend.plotY, lessThan(1 / 3));
    expect(trend.row, 0);
    expect(trend.column, 1);
  });
}
