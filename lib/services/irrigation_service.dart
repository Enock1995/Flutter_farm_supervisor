// lib/services/irrigation_service.dart
// Irrigation Manager — crop water requirements, scheduling, and logging
// for Zimbabwe farming conditions. FAO-56 Penman-Monteith based ETc values.
// Developed by Sir Enocks — Cor Technologies

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class IrrigationSetup {
  final String id;
  final String userId;
  final String plotName;
  final double areaHa;
  final String systemType;      // 'drip' | 'sprinkler' | 'flood' | 'furrow' | 'centre_pivot'
  final double? flowRateLph;    // litres per hour (total system)
  final String? waterSource;    // 'borehole' | 'dam' | 'river' | 'municipal'
  final String? currentCrop;
  final String? growthStage;
  final DateTime? plantingDate;
  final bool isActive;
  final DateTime createdAt;

  const IrrigationSetup({
    required this.id,
    required this.userId,
    required this.plotName,
    required this.areaHa,
    required this.systemType,
    this.flowRateLph,
    this.waterSource,
    this.currentCrop,
    this.growthStage,
    this.plantingDate,
    this.isActive = true,
    required this.createdAt,
  });

  String get systemEmoji {
    switch (systemType) {
      case 'drip':          return '💧';
      case 'sprinkler':     return '🌧️';
      case 'centre_pivot':  return '🔄';
      case 'flood':         return '🌊';
      case 'furrow':        return '〰️';
      default:              return '💦';
    }
  }

  String get systemLabel {
    switch (systemType) {
      case 'drip':          return 'Drip Irrigation';
      case 'sprinkler':     return 'Sprinkler';
      case 'centre_pivot':  return 'Centre Pivot';
      case 'flood':         return 'Flood Irrigation';
      case 'furrow':        return 'Furrow Irrigation';
      default:              return 'Other';
    }
  }

  double get applicationEfficiency {
    switch (systemType) {
      case 'drip':          return 0.90;
      case 'sprinkler':     return 0.75;
      case 'centre_pivot':  return 0.80;
      case 'flood':         return 0.55;
      case 'furrow':        return 0.60;
      default:              return 0.70;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'plot_name': plotName,
        'area_ha': areaHa,
        'system_type': systemType,
        'flow_rate_lph': flowRateLph,
        'water_source': waterSource,
        'current_crop': currentCrop,
        'growth_stage': growthStage,
        'planting_date': plantingDate?.toIso8601String(),
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory IrrigationSetup.fromMap(Map<String, dynamic> m) =>
      IrrigationSetup(
        id: m['id'],
        userId: m['user_id'],
        plotName: m['plot_name'],
        areaHa: (m['area_ha'] as num).toDouble(),
        systemType: m['system_type'] ?? 'drip',
        flowRateLph: m['flow_rate_lph'] != null
            ? (m['flow_rate_lph'] as num).toDouble()
            : null,
        waterSource: m['water_source'],
        currentCrop: m['current_crop'],
        growthStage: m['growth_stage'],
        plantingDate: m['planting_date'] != null
            ? DateTime.parse(m['planting_date'])
            : null,
        isActive: (m['is_active'] as int? ?? 1) == 1,
        createdAt: DateTime.parse(m['created_at']),
      );

  IrrigationSetup copyWith({
    String? currentCrop,
    String? growthStage,
    DateTime? plantingDate,
    bool? isActive,
  }) =>
      IrrigationSetup(
        id: id,
        userId: userId,
        plotName: plotName,
        areaHa: areaHa,
        systemType: systemType,
        flowRateLph: flowRateLph,
        waterSource: waterSource,
        currentCrop: currentCrop ?? this.currentCrop,
        growthStage: growthStage ?? this.growthStage,
        plantingDate: plantingDate ?? this.plantingDate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );
}

// ---------------------------------------------------------------------------

class IrrigationLog {
  final String id;
  final String userId;
  final String setupId;
  final String plotName;
  final DateTime irrigatedAt;
  final double durationMinutes;
  final double waterAppliedLitres;
  final double waterAppliedMm;    // mm = L / (area_m2)
  final String? notes;
  final String? weatherCondition; // 'hot_dry' | 'mild' | 'cool' | 'rainy'

  const IrrigationLog({
    required this.id,
    required this.userId,
    required this.setupId,
    required this.plotName,
    required this.irrigatedAt,
    required this.durationMinutes,
    required this.waterAppliedLitres,
    required this.waterAppliedMm,
    this.notes,
    this.weatherCondition,
  });

  String get daysAgo {
    final diff =
        DateTime.now().difference(irrigatedAt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'setup_id': setupId,
        'plot_name': plotName,
        'irrigated_at': irrigatedAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'water_applied_litres': waterAppliedLitres,
        'water_applied_mm': waterAppliedMm,
        'notes': notes,
        'weather_condition': weatherCondition,
      };

  factory IrrigationLog.fromMap(Map<String, dynamic> m) =>
      IrrigationLog(
        id: m['id'],
        userId: m['user_id'],
        setupId: m['setup_id'],
        plotName: m['plot_name'],
        irrigatedAt: DateTime.parse(m['irrigated_at']),
        durationMinutes:
            (m['duration_minutes'] as num).toDouble(),
        waterAppliedLitres:
            (m['water_applied_litres'] as num).toDouble(),
        waterAppliedMm:
            (m['water_applied_mm'] as num).toDouble(),
        notes: m['notes'],
        weatherCondition: m['weather_condition'],
      );
}

// ---------------------------------------------------------------------------
// WATER REQUIREMENT RESULT
// ---------------------------------------------------------------------------

class WaterRequirement {
  final String crop;
  final String stage;
  final double etcMmPerDay;       // Crop evapotranspiration mm/day
  final double grossWaterMmPerDay; // After system efficiency
  final double litresPerHaPerDay;
  final double litresForPlotPerDay;
  final double areaHa;
  final String systemType;
  final double efficiency;
  final String recommendation;
  final int suggestedIntervalDays;
  final double waterPerIrrigationMm;
  final double waterPerIrrigationLitres;

  const WaterRequirement({
    required this.crop,
    required this.stage,
    required this.etcMmPerDay,
    required this.grossWaterMmPerDay,
    required this.litresPerHaPerDay,
    required this.litresForPlotPerDay,
    required this.areaHa,
    required this.systemType,
    required this.efficiency,
    required this.recommendation,
    required this.suggestedIntervalDays,
    required this.waterPerIrrigationMm,
    required this.waterPerIrrigationLitres,
  });
}

// ---------------------------------------------------------------------------
// SCHEDULE ENTRY
// ---------------------------------------------------------------------------

class IrrigationScheduleEntry {
  final DateTime date;
  final String plotName;
  final double waterMm;
  final double waterLitres;
  final double durationMinutes;
  final String recommendation;
  final bool isDue;      // due today or overdue
  final bool isUpcoming;

  const IrrigationScheduleEntry({
    required this.date,
    required this.plotName,
    required this.waterMm,
    required this.waterLitres,
    required this.durationMinutes,
    required this.recommendation,
    required this.isDue,
    required this.isUpcoming,
  });
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------

class IrrigationService {
  // System types
  static const List<String> systemTypes = [
    'drip',
    'sprinkler',
    'centre_pivot',
    'furrow',
    'flood',
  ];

  // Water sources
  static const List<String> waterSources = [
    'Borehole',
    'Dam / Reservoir',
    'River / Stream',
    'Municipal / Council',
    'Rainwater Harvesting',
  ];

  // Growth stages per crop
  static const Map<String, List<String>> cropStages = {
    'Maize':     ['Germination (0–10 days)', 'Vegetative (10–40 days)', 'Tasseling (40–60 days)', 'Grain Fill (60–90 days)', 'Maturity (90–120 days)'],
    'Tomatoes':  ['Transplanting (0–14 days)', 'Vegetative (14–35 days)', 'Flowering (35–55 days)', 'Fruit Set (55–75 days)', 'Fruit Fill (75–110 days)', 'Harvest (110–130 days)'],
    'Tobacco':   ['Transplanting (0–14 days)', 'Vegetative (14–45 days)', 'Rapid Growth (45–65 days)', 'Topping (65–80 days)', 'Maturity (80–100 days)'],
    'Wheat':     ['Germination (0–15 days)', 'Tillering (15–40 days)', 'Stem Elongation (40–60 days)', 'Heading (60–80 days)', 'Grain Fill (80–100 days)'],
    'Soybeans':  ['Emergence (0–10 days)', 'Vegetative (10–40 days)', 'Flowering (40–65 days)', 'Pod Fill (65–90 days)', 'Maturity (90–110 days)'],
    'Potatoes':  ['Establishment (0–25 days)', 'Vegetative (25–50 days)', 'Tuber Initiation (50–70 days)', 'Tuber Bulking (70–100 days)', 'Maturity (100–120 days)'],
    'Cabbages':  ['Transplanting (0–14 days)', 'Leaf Development (14–50 days)', 'Head Formation (50–80 days)', 'Maturity (80–100 days)'],
    'Onions':    ['Establishment (0–20 days)', 'Vegetative (20–60 days)', 'Bulb Formation (60–90 days)', 'Maturity (90–120 days)'],
    'Beans':     ['Germination (0–10 days)', 'Vegetative (10–30 days)', 'Flowering (30–50 days)', 'Pod Fill (50–70 days)', 'Maturity (70–90 days)'],
    'Groundnuts':['Germination (0–15 days)', 'Vegetative (15–40 days)', 'Pegging (40–60 days)', 'Pod Fill (60–100 days)', 'Maturity (100–130 days)'],
    'Cotton':    ['Germination (0–15 days)', 'Vegetative (15–50 days)', 'Squaring (50–70 days)', 'Flowering (70–90 days)', 'Boll Fill (90–120 days)', 'Maturity (120–150 days)'],
    'Peppers':   ['Transplanting (0–14 days)', 'Vegetative (14–40 days)', 'Flowering (40–65 days)', 'Fruit Fill (65–100 days)', 'Harvest (100–130 days)'],
  };

  // FAO-56 Kc values by crop and stage (used with ETo)
  // ETo Zimbabwe average: 5–7 mm/day (hot dry season), 3–5 mm/day (cool season)
  // ETc = Kc × ETo
  static const Map<String, Map<String, double>> _kcValues = {
    'Maize': {
      'Germination (0–10 days)':    0.40,
      'Vegetative (10–40 days)':    0.80,
      'Tasseling (40–60 days)':     1.20,
      'Grain Fill (60–90 days)':    1.05,
      'Maturity (90–120 days)':     0.60,
    },
    'Tomatoes': {
      'Transplanting (0–14 days)':  0.45,
      'Vegetative (14–35 days)':    0.75,
      'Flowering (35–55 days)':     1.10,
      'Fruit Set (55–75 days)':     1.15,
      'Fruit Fill (75–110 days)':   1.05,
      'Harvest (110–130 days)':     0.80,
    },
    'Tobacco': {
      'Transplanting (0–14 days)':  0.50,
      'Vegetative (14–45 days)':    0.90,
      'Rapid Growth (45–65 days)':  1.10,
      'Topping (65–80 days)':       1.05,
      'Maturity (80–100 days)':     0.85,
    },
    'Wheat': {
      'Germination (0–15 days)':    0.40,
      'Tillering (15–40 days)':     0.70,
      'Stem Elongation (40–60 days)': 1.05,
      'Heading (60–80 days)':       1.15,
      'Grain Fill (80–100 days)':   0.65,
    },
    'Soybeans': {
      'Emergence (0–10 days)':      0.40,
      'Vegetative (10–40 days)':    0.80,
      'Flowering (40–65 days)':     1.10,
      'Pod Fill (65–90 days)':      1.05,
      'Maturity (90–110 days)':     0.55,
    },
    'Potatoes': {
      'Establishment (0–25 days)':  0.50,
      'Vegetative (25–50 days)':    0.80,
      'Tuber Initiation (50–70 days)': 1.15,
      'Tuber Bulking (70–100 days)':   1.20,
      'Maturity (100–120 days)':    0.75,
    },
    'Cabbages': {
      'Transplanting (0–14 days)':  0.45,
      'Leaf Development (14–50 days)': 0.75,
      'Head Formation (50–80 days)':   1.05,
      'Maturity (80–100 days)':     0.90,
    },
    'Onions': {
      'Establishment (0–20 days)':  0.50,
      'Vegetative (20–60 days)':    0.75,
      'Bulb Formation (60–90 days)': 1.05,
      'Maturity (90–120 days)':     0.75,
    },
    'Beans': {
      'Germination (0–10 days)':    0.35,
      'Vegetative (10–30 days)':    0.70,
      'Flowering (30–50 days)':     1.05,
      'Pod Fill (50–70 days)':      1.00,
      'Maturity (70–90 days)':      0.55,
    },
    'Groundnuts': {
      'Germination (0–15 days)':    0.40,
      'Vegetative (15–40 days)':    0.75,
      'Pegging (40–60 days)':       1.00,
      'Pod Fill (60–100 days)':     1.05,
      'Maturity (100–130 days)':    0.60,
    },
    'Cotton': {
      'Germination (0–15 days)':    0.40,
      'Vegetative (15–50 days)':    0.75,
      'Squaring (50–70 days)':      1.00,
      'Flowering (70–90 days)':     1.15,
      'Boll Fill (90–120 days)':    1.10,
      'Maturity (120–150 days)':    0.65,
    },
    'Peppers': {
      'Transplanting (0–14 days)':  0.45,
      'Vegetative (14–40 days)':    0.75,
      'Flowering (40–65 days)':     1.05,
      'Fruit Fill (65–100 days)':   1.10,
      'Harvest (100–130 days)':     0.80,
    },
  };

  // ---------------------------------------------------------------------------
  // WATER REQUIREMENT CALCULATOR
  // ---------------------------------------------------------------------------

  /// Calculate daily crop water requirement using FAO-56 Kc × ETo approach.
  /// [etoMmDay]: Reference evapotranspiration (5.5 default for Zimbabwe hot dry season)
  /// [rainfallMmDay]: Effective rainfall to subtract
  static WaterRequirement calculateRequirement({
    required String crop,
    required String stage,
    required double areaHa,
    required String systemType,
    double etoMmDay = 5.5,
    double rainfallMmDay = 0.0,
    double? flowRateLph,
  }) {
    final kc = _kcValues[crop]?[stage] ?? 0.80;
    final etcNet = (kc * etoMmDay - rainfallMmDay).clamp(0.0, 20.0);

    // System efficiency
    final eff = _efficiencyByType(systemType);

    // Gross water requirement (account for system losses)
    final grossMmDay = etcNet / eff;

    // Convert mm/day to litres
    // 1 mm over 1 ha = 10,000 litres
    final litresPerHaDay = grossMmDay * 10000;
    final litresForPlot = litresPerHaDay * areaHa;

    // Suggested irrigation interval by system type
    final intervalDays = _suggestedInterval(systemType, etcNet);

    // Water per irrigation event
    final waterPerEventMm = grossMmDay * intervalDays;
    final waterPerEventL = waterPerEventMm * 10000 * areaHa;

    // Duration if flow rate known
    String durationStr = '';
    if (flowRateLph != null && flowRateLph > 0) {
      final hours = waterPerEventL / flowRateLph;
      final mins = (hours * 60).round();
      durationStr = mins < 60
          ? ' (run for ~$mins min)'
          : ' (run for ~${hours.toStringAsFixed(1)} hrs)';
    }

    final recommendation =
        'Apply ${waterPerEventMm.toStringAsFixed(1)} mm '
        '(${waterPerEventL.toStringAsFixed(0)} L) '
        'every $intervalDays day${intervalDays == 1 ? '' : 's'}$durationStr.\n'
        'Daily ETc: ${etcNet.toStringAsFixed(1)} mm/day (Kc = ${kc.toStringAsFixed(2)}).';

    return WaterRequirement(
      crop: crop,
      stage: stage,
      etcMmPerDay: etcNet,
      grossWaterMmPerDay: grossMmDay,
      litresPerHaPerDay: litresPerHaDay,
      litresForPlotPerDay: litresForPlot,
      areaHa: areaHa,
      systemType: systemType,
      efficiency: eff,
      recommendation: recommendation,
      suggestedIntervalDays: intervalDays,
      waterPerIrrigationMm: waterPerEventMm,
      waterPerIrrigationLitres: waterPerEventL,
    );
  }

  // ---------------------------------------------------------------------------
  // SCHEDULE GENERATOR
  // ---------------------------------------------------------------------------

  /// Generate 14-day irrigation schedule for a setup.
  static List<IrrigationScheduleEntry> generateSchedule({
    required IrrigationSetup setup,
    required DateTime lastIrrigated,
    double etoMmDay = 5.5,
    double rainfallMmDay = 0.0,
  }) {
    if (setup.currentCrop == null ||
        setup.growthStage == null) return [];

    final req = calculateRequirement(
      crop: setup.currentCrop!,
      stage: setup.growthStage!,
      areaHa: setup.areaHa,
      systemType: setup.systemType,
      etoMmDay: etoMmDay,
      rainfallMmDay: rainfallMmDay,
      flowRateLph: setup.flowRateLph,
    );

    final entries = <IrrigationScheduleEntry>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Calculate duration if flow rate known
    double durationMins = 0;
    if (setup.flowRateLph != null &&
        setup.flowRateLph! > 0) {
      durationMins =
          (req.waterPerIrrigationLitres / setup.flowRateLph!) *
              60;
    }

    // Project 14 days of irrigation events
    var nextDate = DateTime(
      lastIrrigated.year,
      lastIrrigated.month,
      lastIrrigated.day,
    ).add(Duration(days: req.suggestedIntervalDays));

    int count = 0;
    while (count < 6 &&
        nextDate
            .isBefore(today.add(const Duration(days: 15)))) {
      final isDue = !nextDate.isAfter(today);
      final isUpcoming = nextDate.isAfter(today);

      entries.add(IrrigationScheduleEntry(
        date: nextDate,
        plotName: setup.plotName,
        waterMm: req.waterPerIrrigationMm,
        waterLitres: req.waterPerIrrigationLitres,
        durationMinutes: durationMins,
        recommendation: req.recommendation,
        isDue: isDue,
        isUpcoming: isUpcoming,
      ));

      nextDate = nextDate
          .add(Duration(days: req.suggestedIntervalDays));
      count++;
    }

    return entries;
  }

  // ---------------------------------------------------------------------------
  // ETO BY ZIMBABWE SEASON
  // ---------------------------------------------------------------------------

  /// Approximate ETo for Zimbabwe based on current month.
  static double estimateEto(DateTime date) {
    final month = date.month;
    // Oct–Feb: hot and wet season, high ETo
    // Jun–Aug: cool dry season, lower ETo
    const etos = {
      1: 6.0,  // January
      2: 5.8,  // February
      3: 5.5,  // March
      4: 5.0,  // April
      5: 4.2,  // May
      6: 3.5,  // June
      7: 3.8,  // July
      8: 4.5,  // August
      9: 5.8,  // September
      10: 6.5, // October
      11: 6.2, // November
      12: 5.8, // December
    };
    return etos[month] ?? 5.5;
  }

  // ---------------------------------------------------------------------------
  // GENERAL TIPS
  // ---------------------------------------------------------------------------

  static const List<Map<String, String>> irrigationTips = [
    {
      'emoji': '⏰',
      'title': 'Irrigate early morning',
      'detail':
          'Apply water before 9 AM to minimise evaporation losses. '
          'Avoid midday irrigation — up to 30% more water evaporates. '
          'Evening irrigation can promote fungal disease.',
    },
    {
      'emoji': '🌡️',
      'title': 'Adjust for hot spells',
      'detail':
          'On days above 35°C, increase irrigation by 20–30%. '
          'Plants transpire faster in extreme heat. '
          'Check soil moisture with a finger test — irrigate when top '
          '5 cm feels dry.',
    },
    {
      'emoji': '🌧️',
      'title': 'Subtract effective rainfall',
      'detail':
          'Rainfall above 5 mm counts as effective irrigation. '
          'After 10 mm of rain, skip the next scheduled irrigation. '
          'After 25+ mm, skip two events.',
    },
    {
      'emoji': '💧',
      'title': 'Drip irrigation efficiency',
      'detail':
          'Drip systems apply water directly to the root zone at 90%+ efficiency. '
          'Check emitters weekly for blockages. '
          'Flush lateral lines monthly to prevent salt build-up.',
    },
    {
      'emoji': '🪣',
      'title': 'Check your sprinkler uniformity',
      'detail':
          'Place tins/cans at various distances from the sprinkler. '
          'After 15 minutes, measure water in each. '
          'Good uniformity: variation under 20% between cans.',
    },
    {
      'emoji': '🧂',
      'title': 'Watch for salt build-up',
      'detail':
          'Borehole water in Zimbabwe is often high in salts. '
          'White crusting on soil surface indicates salt accumulation. '
          'Apply a heavy leaching irrigation (2× normal rate) every '
          '4–6 weeks to flush salts below the root zone.',
    },
    {
      'emoji': '📐',
      'title': 'Critical growth stages',
      'detail':
          'Never stress crops at these stages: maize tasseling/silking, '
          'tomato flowering/fruit set, tobacco rapid growth, '
          'potato tuber bulking. Missing irrigation at these points '
          'causes permanent yield loss.',
    },
  ];

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static double _efficiencyByType(String type) {
    switch (type) {
      case 'drip':          return 0.90;
      case 'sprinkler':     return 0.75;
      case 'centre_pivot':  return 0.80;
      case 'flood':         return 0.55;
      case 'furrow':        return 0.60;
      default:              return 0.70;
    }
  }

  static int _suggestedInterval(
      String systemType, double etcMmDay) {
    // Drip: daily or every 2 days
    // Sprinkler/pivot: every 2–4 days
    // Flood/furrow: every 5–10 days (high volume less frequent)
    if (systemType == 'drip') {
      return etcMmDay > 4 ? 1 : 2;
    } else if (systemType == 'centre_pivot') {
      return etcMmDay > 5 ? 2 : 3;
    } else if (systemType == 'sprinkler') {
      return etcMmDay > 5 ? 2 : 3;
    } else if (systemType == 'furrow' ||
        systemType == 'flood') {
      return etcMmDay > 5 ? 6 : 8;
    }
    return 3;
  }

  static List<String> get crops =>
      cropStages.keys.toList()..sort();
}