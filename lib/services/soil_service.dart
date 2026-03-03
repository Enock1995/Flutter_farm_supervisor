// lib/services/soil_service.dart
// Soil Management — soil test recording, lime & fertilizer calculations,
// and agronomic recommendations for Zimbabwe farming conditions.
// Developed by Sir Enocks — Cor Technologies

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class SoilRecord {
  final String id;
  final String userId;
  final String plotName;
  final DateTime testDate;
  final double? ph;
  final double? nitrogen;     // mg/kg or %
  final double? phosphorus;   // mg/kg (Bray P)
  final double? potassium;    // mg/kg
  final double? organicMatter; // %
  final String? texture;      // 'Sandy' | 'Loamy' | 'Clay' | 'Sandy Loam' | 'Clay Loam'
  final double? plotSizeHa;
  final String? labName;
  final String? notes;
  final DateTime createdAt;

  const SoilRecord({
    required this.id,
    required this.userId,
    required this.plotName,
    required this.testDate,
    this.ph,
    this.nitrogen,
    this.phosphorus,
    this.potassium,
    this.organicMatter,
    this.texture,
    this.plotSizeHa,
    this.labName,
    this.notes,
    required this.createdAt,
  });

  // pH interpretation
  String get phStatus {
    if (ph == null) return 'Not tested';
    if (ph! < 4.5) return 'Extremely Acidic';
    if (ph! < 5.5) return 'Strongly Acidic';
    if (ph! < 6.0) return 'Moderately Acidic';
    if (ph! < 6.5) return 'Slightly Acidic';
    if (ph! <= 7.0) return 'Optimal';
    if (ph! <= 7.5) return 'Slightly Alkaline';
    return 'Alkaline';
  }

  bool get needsLime =>
      ph != null && ph! < 5.8;

  bool get phIsOptimal =>
      ph != null && ph! >= 5.8 && ph! <= 6.8;

  String get phEmoji {
    if (ph == null) return '❓';
    if (ph! < 5.5) return '🔴';
    if (ph! < 5.8) return '🟠';
    if (ph! <= 6.8) return '🟢';
    return '🟡';
  }

  // Nutrient interpretations (Zimbabwe AGRITEX standards)
  String get nStatus {
    if (nitrogen == null) return 'Unknown';
    if (nitrogen! < 0.1) return 'Very Low';
    if (nitrogen! < 0.2) return 'Low';
    if (nitrogen! < 0.3) return 'Medium';
    if (nitrogen! < 0.5) return 'High';
    return 'Very High';
  }

  String get pStatus {
    if (phosphorus == null) return 'Unknown';
    if (phosphorus! < 5) return 'Very Low';
    if (phosphorus! < 10) return 'Low';
    if (phosphorus! < 20) return 'Medium';
    if (phosphorus! < 40) return 'High';
    return 'Very High';
  }

  String get kStatus {
    if (potassium == null) return 'Unknown';
    if (potassium! < 50) return 'Very Low';
    if (potassium! < 100) return 'Low';
    if (potassium! < 200) return 'Medium';
    if (potassium! < 400) return 'High';
    return 'Very High';
  }

  String get omStatus {
    if (organicMatter == null) return 'Unknown';
    if (organicMatter! < 1.0) return 'Very Low';
    if (organicMatter! < 2.0) return 'Low';
    if (organicMatter! < 3.0) return 'Medium';
    if (organicMatter! < 4.0) return 'High';
    return 'Very High';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'plot_name': plotName,
        'test_date': testDate.toIso8601String(),
        'ph': ph,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'organic_matter': organicMatter,
        'texture': texture,
        'plot_size_ha': plotSizeHa,
        'lab_name': labName,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory SoilRecord.fromMap(Map<String, dynamic> m) =>
      SoilRecord(
        id: m['id'],
        userId: m['user_id'],
        plotName: m['plot_name'],
        testDate: DateTime.parse(m['test_date']),
        ph: m['ph'] != null
            ? (m['ph'] as num).toDouble()
            : null,
        nitrogen: m['nitrogen'] != null
            ? (m['nitrogen'] as num).toDouble()
            : null,
        phosphorus: m['phosphorus'] != null
            ? (m['phosphorus'] as num).toDouble()
            : null,
        potassium: m['potassium'] != null
            ? (m['potassium'] as num).toDouble()
            : null,
        organicMatter: m['organic_matter'] != null
            ? (m['organic_matter'] as num).toDouble()
            : null,
        texture: m['texture'],
        plotSizeHa: m['plot_size_ha'] != null
            ? (m['plot_size_ha'] as num).toDouble()
            : null,
        labName: m['lab_name'],
        notes: m['notes'],
        createdAt: DateTime.parse(m['created_at']),
      );
}

// ---------------------------------------------------------------------------
// RECOMMENDATION
// ---------------------------------------------------------------------------

class SoilRecommendation {
  final String category;    // 'Lime' | 'Nitrogen' | 'Phosphorus' | 'Potassium' | 'Organic Matter' | 'General'
  final String priority;    // 'urgent' | 'high' | 'medium' | 'low'
  final String title;
  final String detail;
  final String? productExample;
  final String? quantity;   // e.g. "1.5 t/ha"

  const SoilRecommendation({
    required this.category,
    required this.priority,
    required this.title,
    required this.detail,
    this.productExample,
    this.quantity,
  });

  String get priorityEmoji {
    switch (priority) {
      case 'urgent': return '🔴';
      case 'high':   return '🟠';
      case 'medium': return '🟡';
      default:       return '🟢';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case 'Lime':           return '🪨';
      case 'Nitrogen':       return '🌿';
      case 'Phosphorus':     return '🔵';
      case 'Potassium':      return '🟤';
      case 'Organic Matter': return '♻️';
      default:               return '💡';
    }
  }
}

// ---------------------------------------------------------------------------
// LIME CALCULATION RESULT
// ---------------------------------------------------------------------------

class LimeCalcResult {
  final double limeRatePerHa;   // tonnes/ha
  final double totalLimeNeeded; // tonnes for plot
  final String limeType;
  final String basis;
  final List<String> applicationNotes;

  const LimeCalcResult({
    required this.limeRatePerHa,
    required this.totalLimeNeeded,
    required this.limeType,
    required this.basis,
    required this.applicationNotes,
  });
}

// ---------------------------------------------------------------------------
// FERTILIZER CALCULATION RESULT
// ---------------------------------------------------------------------------

class FertilizerCalcResult {
  final String crop;
  final String phase;       // 'Basal' | 'Top dress'
  final String product;
  final double ratePerHa;   // kg/ha
  final double totalForPlot;
  final String timing;
  final String method;
  final List<String> notes;

  const FertilizerCalcResult({
    required this.crop,
    required this.phase,
    required this.product,
    required this.ratePerHa,
    required this.totalForPlot,
    required this.timing,
    required this.method,
    this.notes = const [],
  });
}

// ---------------------------------------------------------------------------
// SOIL SERVICE
// ---------------------------------------------------------------------------

class SoilService {
  static const List<String> textures = [
    'Sandy',
    'Sandy Loam',
    'Loamy',
    'Clay Loam',
    'Clay',
  ];

  static const List<String> crops = [
    'Maize',
    'Tobacco',
    'Wheat',
    'Soybeans',
    'Tomatoes',
    'Cabbages',
    'Potatoes',
    'Beans',
    'Groundnuts',
    'Cotton',
    'Sunflower',
    'Sorghum',
    'Onions',
  ];

  // ---------------------------------------------------------------------------
  // GENERATE RECOMMENDATIONS
  // ---------------------------------------------------------------------------

  static List<SoilRecommendation> generateRecommendations(
      SoilRecord record, {String? targetCrop}) {
    final recs = <SoilRecommendation>[];

    // --- pH / Lime ---
    if (record.ph != null) {
      if (record.ph! < 4.5) {
        recs.add(const SoilRecommendation(
          category: 'Lime',
          priority: 'urgent',
          title: 'Severely Acidic — Lime Urgently Required',
          detail:
              'Soil pH below 4.5 causes severe aluminium and manganese toxicity. '
              'Most crops will fail. Apply lime immediately and re-test after 3 months.',
          productExample: 'Agricultural Lime (CaCO₃) or Dolomitic Lime',
          quantity: '3.0–5.0 t/ha',
        ));
      } else if (record.ph! < 5.5) {
        recs.add(SoilRecommendation(
          category: 'Lime',
          priority: 'urgent',
          title: 'Strongly Acidic — Lime Required',
          detail:
              'pH ${record.ph!.toStringAsFixed(1)} is below the optimal range for most crops (5.8–6.8). '
              'Aluminium toxicity likely. Apply lime before planting.',
          productExample: 'Agricultural Lime or Dolomitic Lime',
          quantity: '${_limeRate(record.ph!, record.texture).toStringAsFixed(1)} t/ha',
        ));
      } else if (record.ph! < 5.8) {
        recs.add(SoilRecommendation(
          category: 'Lime',
          priority: 'high',
          title: 'Moderately Acidic — Lime Recommended',
          detail:
              'pH ${record.ph!.toStringAsFixed(1)} is slightly below optimal. '
              'Apply maintenance lime to bring pH to 6.0–6.5.',
          productExample: 'Agricultural Lime',
          quantity: '${_limeRate(record.ph!, record.texture).toStringAsFixed(1)} t/ha',
        ));
      } else if (record.ph! > 7.5) {
        recs.add(SoilRecommendation(
          category: 'Lime',
          priority: 'medium',
          title: 'Alkaline Soil — Reduce pH',
          detail:
              'pH ${record.ph!.toStringAsFixed(1)} above 7.5 can lock up phosphorus, iron, and zinc. '
              'Incorporate elemental sulphur or acidifying fertilizers.',
          productExample: 'Elemental Sulphur (S) or Ammonium Sulphate',
          quantity: '200–500 kg/ha sulphur',
        ));
      } else {
        recs.add(SoilRecommendation(
          category: 'Lime',
          priority: 'low',
          title: 'pH Optimal ✓',
          detail:
              'Soil pH ${record.ph!.toStringAsFixed(1)} is in the ideal range (5.8–6.8). '
              'Apply maintenance lime (0.5–1.0 t/ha) every 3–5 years.',
        ));
      }
    }

    // --- Nitrogen ---
    if (record.nitrogen != null) {
      if (record.nitrogen! < 0.1) {
        recs.add(const SoilRecommendation(
          category: 'Nitrogen',
          priority: 'urgent',
          title: 'Very Low Nitrogen — High Input Required',
          detail:
              'Nitrogen is critically deficient. Apply basal nitrogen at planting '
              'and plan two to three top dressing applications during the season.',
          productExample: 'Compound D (7:14:7) basal + CAN top dress',
          quantity: '300–400 kg/ha basal + 200–300 kg/ha CAN',
        ));
      } else if (record.nitrogen! < 0.2) {
        recs.add(const SoilRecommendation(
          category: 'Nitrogen',
          priority: 'high',
          title: 'Low Nitrogen — Supplementation Required',
          detail:
              'Apply basal fertilizer at planting and follow with top dressing. '
              'Incorporate organic matter to build long-term nitrogen reserves.',
          productExample: 'Compound D basal + CAN top dress',
          quantity: '200–300 kg/ha basal',
        ));
      } else if (record.nitrogen! >= 0.3) {
        recs.add(const SoilRecommendation(
          category: 'Nitrogen',
          priority: 'low',
          title: 'Adequate Nitrogen ✓',
          detail:
              'Soil nitrogen is sufficient. Apply standard basal fertilizer '
              'and monitor crop colour during the season.',
        ));
      }
    }

    // --- Phosphorus ---
    if (record.phosphorus != null) {
      if (record.phosphorus! < 10) {
        recs.add(SoilRecommendation(
          category: 'Phosphorus',
          priority: record.phosphorus! < 5 ? 'urgent' : 'high',
          title: record.phosphorus! < 5
              ? 'Very Low Phosphorus — Critical Deficiency'
              : 'Low Phosphorus — Apply at Planting',
          detail:
              'Phosphorus is essential for root development and early establishment. '
              'Apply superphosphate or compound fertilizer as basal at planting. '
              'Note: Acidic soils (pH < 5.5) lock up phosphorus — lime first.',
          productExample: 'Single Superphosphate or Compound D',
          quantity: record.phosphorus! < 5
              ? '300–400 kg/ha SSP'
              : '200–300 kg/ha SSP',
        ));
      } else if (record.phosphorus! >= 20) {
        recs.add(const SoilRecommendation(
          category: 'Phosphorus',
          priority: 'low',
          title: 'Adequate Phosphorus ✓',
          detail:
              'Phosphorus levels are sufficient. Maintenance application '
              'of 100–150 kg/ha SSP at planting is adequate.',
        ));
      }
    }

    // --- Potassium ---
    if (record.potassium != null) {
      if (record.potassium! < 100) {
        recs.add(SoilRecommendation(
          category: 'Potassium',
          priority: record.potassium! < 50 ? 'high' : 'medium',
          title: 'Low Potassium — Apply Potash',
          detail:
              'Potassium is important for fruit quality, disease resistance, '
              'and drought tolerance. Apply potassium fertilizer, especially '
              'for potato, tobacco, and tomato crops.',
          productExample: 'Muriate of Potash (KCl) or Compound fertilizer',
          quantity: '100–200 kg/ha KCl',
        ));
      }
    }

    // --- Organic Matter ---
    if (record.organicMatter != null) {
      if (record.organicMatter! < 2.0) {
        recs.add(SoilRecommendation(
          category: 'Organic Matter',
          priority: record.organicMatter! < 1.0 ? 'high' : 'medium',
          title: 'Low Organic Matter — Build Soil Health',
          detail:
              'Low OM reduces water-holding capacity, nutrient availability, '
              'and beneficial soil life. Apply manure or compost annually. '
              'Incorporate crop residues instead of burning.',
          productExample: 'Kraal manure / compost',
          quantity: '5–10 t/ha manure annually',
        ));
      } else {
        recs.add(const SoilRecommendation(
          category: 'Organic Matter',
          priority: 'low',
          title: 'Good Organic Matter ✓',
          detail:
              'Organic matter is adequate. Maintain by incorporating '
              'crop residues and applying manure every 2–3 years.',
        ));
      }
    }

    // --- Texture-specific advice ---
    if (record.texture != null) {
      if (record.texture == 'Sandy') {
        recs.add(const SoilRecommendation(
          category: 'General',
          priority: 'medium',
          title: 'Sandy Soil — Manage Leaching',
          detail:
              'Sandy soils have poor water and nutrient retention. '
              'Split fertilizer applications into 3–4 smaller doses. '
              'Apply nitrogen little and often. Build organic matter urgently.',
        ));
      } else if (record.texture == 'Clay') {
        recs.add(const SoilRecommendation(
          category: 'General',
          priority: 'medium',
          title: 'Clay Soil — Improve Structure',
          detail:
              'Clay soils compact easily and drain poorly. '
              'Deep rip annually, apply gypsum to improve structure, '
              'and avoid tillage when soil is wet.',
          productExample: 'Agricultural Gypsum',
          quantity: '1–2 t/ha gypsum',
        ));
      }
    }

    // --- Target crop specific ---
    if (targetCrop != null && record.ph != null) {
      final optimalPh = _optimalPhRange(targetCrop);
      if (record.ph! < optimalPh.$1) {
        recs.add(SoilRecommendation(
          category: 'General',
          priority: 'high',
          title: '$targetCrop requires pH ${optimalPh.$1}–${optimalPh.$2}',
          detail:
              'Current pH ${record.ph!.toStringAsFixed(1)} is below the optimal '
              'range for $targetCrop. Apply lime to raise pH before planting.',
        ));
      }
    }

    // Sort by priority
    final order = ['urgent', 'high', 'medium', 'low'];
    recs.sort((a, b) =>
        order.indexOf(a.priority).compareTo(order.indexOf(b.priority)));

    return recs;
  }

  // ---------------------------------------------------------------------------
  // LIME CALCULATOR
  // ---------------------------------------------------------------------------

  static LimeCalcResult calculateLime({
    required double currentPh,
    required double targetPh,
    required String texture,
    required double plotSizeHa,
  }) {
    // Buffer capacity factor by texture
    final double bufferFactor = _limeBufferFactor(texture);

    // Base rate: tonnes/ha to raise pH by 1 unit
    final double phDiff = (targetPh - currentPh).clamp(0.0, 3.0);
    final double ratePerHa = phDiff * bufferFactor;
    final double totalLime = ratePerHa * plotSizeHa;

    return LimeCalcResult(
      limeRatePerHa: ratePerHa,
      totalLimeNeeded: totalLime,
      limeType: 'Agricultural Lime (CaCO₃, 90–100% purity)',
      basis:
          'Based on $texture texture soil. Target pH: $targetPh. '
          'Current pH: $currentPh.',
      applicationNotes: [
        'Apply lime at least 4–6 weeks before planting',
        'Incorporate lime into the top 15–20 cm of soil by ploughing',
        'If rate exceeds 3 t/ha, split into two applications 6 months apart',
        'Re-test soil pH 3 months after liming',
        'Dolomitic lime also supplies magnesium — useful on Mg-deficient soils',
        'Source: ZFC, Windmill, or Speciss Lime (available across Zimbabwe)',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FERTILIZER CALCULATOR
  // ---------------------------------------------------------------------------

  static List<FertilizerCalcResult> calculateFertilizer({
    required String crop,
    required double plotSizeHa,
    required String? nStatus,
    required String? pStatus,
    required String? kStatus,
  }) {
    final results = <FertilizerCalcResult>[];

    switch (crop) {
      case 'Maize':
        // Basal
        double basalRate = 200;
        if (pStatus == 'Very Low') basalRate = 350;
        if (pStatus == 'Low') basalRate = 250;
        if (pStatus == 'High' || pStatus == 'Very High') basalRate = 150;

        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Basal (at planting)',
          product: 'Compound D (7:14:7) or Compound L (5:18:5)',
          ratePerHa: basalRate,
          totalForPlot: basalRate * plotSizeHa,
          timing: 'Apply in the planting furrow at planting',
          method: 'Basal placement — 5 cm beside and below the seed',
          notes: [
            'Do not apply fertilizer in direct contact with seed',
            '200 kg/ha Compound D provides ~14kg P₂O₅/ha',
          ],
        ));

        // Top dress 1
        double td1Rate = 200;
        if (nStatus == 'Very Low') td1Rate = 300;
        if (nStatus == 'High') td1Rate = 150;

        results.add(FertilizerCalcResult(
          crop: crop,
          phase: '1st Top Dress',
          product: 'CAN (Calcium Ammonium Nitrate, 27% N)',
          ratePerHa: td1Rate,
          totalForPlot: td1Rate * plotSizeHa,
          timing: '3–4 weeks after emergence (V4–V6 stage)',
          method: 'Broadcast between rows or side-place beside plants',
          notes: [
            'Apply when soil is moist or rain is expected within 48 hours',
            'Do not apply during drought — wait for soil moisture',
          ],
        ));

        // Top dress 2
        results.add(FertilizerCalcResult(
          crop: crop,
          phase: '2nd Top Dress',
          product: 'CAN or AN34 (Ammonium Nitrate 34% N)',
          ratePerHa: td1Rate * 0.75,
          totalForPlot: td1Rate * 0.75 * plotSizeHa,
          timing: '6–7 weeks after emergence (V10–V12 / knee-high)',
          method: 'Broadcast between rows',
          notes: [
            'Last effective opportunity for nitrogen — after this, limited uptake',
            'Skip this application if crop is deficient in moisture',
          ],
        ));
        break;

      case 'Tomatoes':
        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Basal (at transplanting)',
          product: 'Compound S (6:28:23) or Compound C (5:15:12+10S)',
          ratePerHa: 300,
          totalForPlot: 300 * plotSizeHa,
          timing: 'Mix into planting hole or broadcast and incorporate',
          method: 'Incorporated into top 15 cm at bed preparation',
          notes: [
            'High phosphorus basal supports strong root establishment',
            'Add superphosphate if P status is very low',
          ],
        ));

        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Vegetative Top Dress',
          product: 'LAN (Limestone Ammonium Nitrate 28% N)',
          ratePerHa: 150,
          totalForPlot: 150 * plotSizeHa,
          timing: '2–3 weeks after transplanting',
          method: 'Side dress or fertigation if drip irrigation available',
          notes: ['Avoid getting fertilizer on leaves — causes scorch'],
        ));

        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Fruit Set Top Dress',
          product: 'Potassium Nitrate (KNO₃) or NK compound',
          ratePerHa: 200,
          totalForPlot: 200 * plotSizeHa,
          timing: 'At first fruit set',
          method: 'Fertigation or dissolved foliar application',
          notes: [
            'Potassium critical for fruit size, colour, and shelf life',
            'Calcium nitrate foliar spray reduces blossom end rot',
          ],
        ));
        break;

      case 'Tobacco':
        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Basal (at transplanting)',
          product: 'Compound T (5:14:5+4S) or Tobacco Compound',
          ratePerHa: 400,
          totalForPlot: 400 * plotSizeHa,
          timing: 'In the furrow at transplanting',
          method: 'Furrow application — 5 cm from plant',
          notes: [
            'DO NOT over-apply nitrogen on tobacco — reduces leaf quality',
            'Excess N causes dark, poor-quality leaf',
          ],
        ));

        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Top Dress',
          product: 'Tobacco Top Dress or CAN (low rate)',
          ratePerHa: 100,
          totalForPlot: 100 * plotSizeHa,
          timing: '3–4 weeks after transplanting only',
          method: 'Side dress beside plants',
          notes: [
            'Only one top dress for tobacco — more causes poor curing quality',
            'Stop all nitrogen applications by 6 weeks after transplanting',
          ],
        ));
        break;

      case 'Soybeans':
        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Basal (at planting)',
          product: 'SSP (Single Superphosphate, 18% P₂O₅)',
          ratePerHa: 200,
          totalForPlot: 200 * plotSizeHa,
          timing: 'In the planting furrow',
          method: 'Basal placement',
          notes: [
            'Soybeans fix their own nitrogen via Rhizobium bacteria',
            'Inoculate seed with Bradyrhizobium japonicum before planting',
            'Do NOT apply nitrogen fertilizer — it inhibits N-fixation',
          ],
        ));
        break;

      case 'Wheat':
        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Basal (at sowing)',
          product: 'Compound D (7:14:7)',
          ratePerHa: 250,
          totalForPlot: 250 * plotSizeHa,
          timing: 'In the seed furrow at sowing',
          method: 'Drill placement with seed',
          notes: ['Keep seed and fertilizer contact minimal'],
        ));

        results.add(FertilizerCalcResult(
          crop: crop,
          phase: '1st Top Dress',
          product: 'CAN (27% N)',
          ratePerHa: 200,
          totalForPlot: 200 * plotSizeHa,
          timing: 'At tillering (3–4 weeks after emergence)',
          method: 'Broadcast',
          notes: [],
        ));

        results.add(FertilizerCalcResult(
          crop: crop,
          phase: '2nd Top Dress',
          product: 'CAN (27% N)',
          ratePerHa: 150,
          totalForPlot: 150 * plotSizeHa,
          timing: 'At flag leaf stage',
          method: 'Broadcast when leaf is dry',
          notes: ['Critical for grain filling and protein content'],
        ));
        break;

      default:
        // Generic crop
        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Basal (at planting)',
          product: 'Compound D (7:14:7)',
          ratePerHa: 200,
          totalForPlot: 200 * plotSizeHa,
          timing: 'At planting or transplanting',
          method: 'Incorporated into soil',
          notes: [
            'Adjust rate based on soil test results and Agritex recommendations',
          ],
        ));

        results.add(FertilizerCalcResult(
          crop: crop,
          phase: 'Top Dress',
          product: 'CAN (27% N)',
          ratePerHa: 150,
          totalForPlot: 150 * plotSizeHa,
          timing: '3–4 weeks after establishment',
          method: 'Broadcast or side dress',
          notes: [],
        ));
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  static double _limeRate(double currentPh, String? texture) {
    final double target = 6.2;
    final double diff = (target - currentPh).clamp(0.0, 3.0);
    return diff * _limeBufferFactor(texture ?? 'Loamy');
  }

  static double _limeBufferFactor(String texture) {
    switch (texture) {
      case 'Sandy':     return 0.8;
      case 'Sandy Loam': return 1.0;
      case 'Loamy':     return 1.3;
      case 'Clay Loam': return 1.6;
      case 'Clay':      return 2.0;
      default:          return 1.2;
    }
  }

  static (double, double) _optimalPhRange(String crop) {
    switch (crop) {
      case 'Potatoes':   return (5.0, 6.0);
      case 'Blueberries': return (4.5, 5.5);
      case 'Tobacco':    return (5.5, 6.0);
      case 'Maize':      return (5.8, 6.8);
      case 'Soybeans':   return (6.0, 7.0);
      case 'Wheat':      return (6.0, 7.0);
      case 'Tomatoes':   return (6.0, 6.8);
      case 'Cabbages':   return (6.0, 7.0);
      case 'Onions':     return (6.0, 7.0);
      default:           return (5.8, 6.8);
    }
  }

  // Soil test labs in Zimbabwe
  static const List<Map<String, String>> labs = [
    {
      'name': 'SoilCare Zimbabwe (Harare)',
      'contact': '+263 242 700 000',
    },
    {
      'name': 'Agrichem (Pvt) Ltd',
      'contact': '+263 242 335 351',
    },
    {
      'name': 'Tobacco Research Board — Harare',
      'contact': '+263 242 575 452',
    },
    {
      'name': 'University of Zimbabwe — Soil Science',
      'contact': '+263 242 303 211',
    },
    {
      'name': 'ZFC Agronomy Service',
      'contact': 'Available at ZFC depots',
    },
  ];
}