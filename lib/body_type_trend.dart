enum BodyLevel { low, moderate, high }

class BodyTypeTrend {
  const BodyTypeTrend({
    required this.bodyFatPercent,
    required this.skeletalMusclePercent,
  });

  factory BodyTypeTrend.fromMeasurement({
    required double weightKg,
    required double skeletalMuscleKg,
    required double bodyFatPercent,
  }) => BodyTypeTrend(
    bodyFatPercent: bodyFatPercent,
    skeletalMusclePercent: weightKg > 0 ? skeletalMuscleKg / weightKg * 100 : 0,
  );

  final double bodyFatPercent;
  final double skeletalMusclePercent;

  // These bands describe the plotted ranges; they are not clinical cutoffs.
  BodyLevel get fatLevel => bodyFatPercent < 15
      ? BodyLevel.low
      : bodyFatPercent < 30
      ? BodyLevel.moderate
      : BodyLevel.high;

  BodyLevel get muscleLevel => skeletalMusclePercent < 30
      ? BodyLevel.low
      : skeletalMusclePercent < 45
      ? BodyLevel.moderate
      : BodyLevel.high;

  int get column => fatLevel.index;
  int get row => 2 - muscleLevel.index;

  double get plotX => (bodyFatPercent / 45).clamp(0.03, 0.97);
  double get plotY => (1 - (skeletalMusclePercent - 15) / 45).clamp(0.03, 0.97);
}
