// lib/services/input_calculator_service.dart
// Input Calculator — spray volumes, seed rates, fertilizer mixing,
// and tank mix compatibility for Zimbabwe farming.
// Developed by Sir Enocks — Cor Technologies

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class SprayCalcResult {
  final String productName;
  final double areaHa;
  final double waterVolumeLitres;     // total water for area
  final double productAmountMl;       // total product needed
  final double productAmountG;        // if powder
  final double concentrationPct;      // ml or g per litre
  final String unit;                  // 'ml/L' or 'g/L'
  final int tanksNeeded;
  final double productPerTank;
  final double tankCapacityL;
  final List<String> mixingSteps;
  final List<String> safetyNotes;

  const SprayCalcResult({
    required this.productName,
    required this.areaHa,
    required this.waterVolumeLitres,
    required this.productAmountMl,
    required this.productAmountG,
    required this.concentrationPct,
    required this.unit,
    required this.tanksNeeded,
    required this.productPerTank,
    required this.tankCapacityL,
    required this.mixingSteps,
    required this.safetyNotes,
  });
}

// ---------------------------------------------------------------------------

class SeedCalcResult {
  final String crop;
  final double areaHa;
  final double seedingRateKgHa;
  final double totalSeedKg;
  final double totalSeedG;
  final double rowSpacingCm;
  final double plantSpacingCm;
  final int plantsPerHa;
  final double totalPlants;
  final String packagingAdvice;
  final List<String> notes;

  const SeedCalcResult({
    required this.crop,
    required this.areaHa,
    required this.seedingRateKgHa,
    required this.totalSeedKg,
    required this.totalSeedG,
    required this.rowSpacingCm,
    required this.plantSpacingCm,
    required this.plantsPerHa,
    required this.totalPlants,
    required this.packagingAdvice,
    required this.notes,
  });
}

// ---------------------------------------------------------------------------

class TankMixProduct {
  final String name;
  final String type;      // 'fungicide' | 'insecticide' | 'herbicide' | 'fertilizer' | 'adjuvant'
  final double doseMlPer100L;
  final String unit;      // 'ml' | 'g'
  final String? activeIngredient;

  const TankMixProduct({
    required this.name,
    required this.type,
    required this.doseMlPer100L,
    required this.unit,
    this.activeIngredient,
  });

  String get typeEmoji {
    switch (type) {
      case 'fungicide':   return '🍄';
      case 'insecticide': return '🐛';
      case 'herbicide':   return '🌿';
      case 'fertilizer':  return '🌱';
      case 'adjuvant':    return '💧';
      default:            return '🧪';
    }
  }
}

class TankMixResult {
  final double tankSizeL;
  final List<TankMixProduct> products;
  final List<_ProductQty> quantities;
  final List<String> compatibilityWarnings;
  final List<String> mixingOrder;
  final List<String> safetyNotes;
  final bool isCompatible;

  const TankMixResult({
    required this.tankSizeL,
    required this.products,
    required this.quantities,
    required this.compatibilityWarnings,
    required this.mixingOrder,
    required this.safetyNotes,
    required this.isCompatible,
  });
}

class _ProductQty {
  final String name;
  final double amount;
  final String unit;
  const _ProductQty(this.name, this.amount, this.unit);
}

// ---------------------------------------------------------------------------

class SavedCalculation {
  final String id;
  final String userId;
  final String type;        // 'spray' | 'seed' | 'mix'
  final String title;
  final String summary;
  final DateTime savedAt;
  final Map<String, dynamic> inputs;

  const SavedCalculation({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.summary,
    required this.savedAt,
    required this.inputs,
  });

  String get typeEmoji {
    switch (type) {
      case 'spray': return '🧪';
      case 'seed':  return '🌱';
      case 'mix':   return '🪣';
      default:      return '🧮';
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'title': title,
        'summary': summary,
        'saved_at': savedAt.toIso8601String(),
        'inputs': inputs.toString(),
      };

  factory SavedCalculation.fromMap(
          Map<String, dynamic> m) =>
      SavedCalculation(
        id: m['id'],
        userId: m['user_id'],
        type: m['type'],
        title: m['title'],
        summary: m['summary'],
        savedAt: DateTime.parse(m['saved_at']),
        inputs: {},
      );
}

// ---------------------------------------------------------------------------
// SERVICE
// ---------------------------------------------------------------------------

class InputCalculatorService {
  // ── SPRAY CALCULATOR ──────────────────────────────

  /// Water volume rates by application type (L/ha)
  static const Map<String, double> waterRatesLHa = {
    'Knapsack sprayer (field crops)':    200,
    'Knapsack sprayer (horticulture)':   400,
    'Motorised mist blower':             150,
    'Boom sprayer (tractor)':            200,
    'Boom sprayer (high volume)':        400,
    'Centre pivot (chemigation)':        300,
    'Drip irrigation (fertigation)':     100,
    'Aerial application':                 50,
  };

  static const List<String> equipmentTypes =
      ['Knapsack sprayer (field crops)',
       'Knapsack sprayer (horticulture)',
       'Motorised mist blower',
       'Boom sprayer (tractor)',
       'Boom sprayer (high volume)',
       'Centre pivot (chemigation)',
       'Drip irrigation (fertigation)',
       'Aerial application'];

  static const List<String> productUnits =
      ['ml/ha', 'L/ha', 'g/ha', 'kg/ha'];

  static SprayCalcResult calculateSpray({
    required String productName,
    required double areaHa,
    required double productDose,   // per ha
    required String doseUnit,      // 'ml/ha' | 'L/ha' | 'g/ha' | 'kg/ha'
    required String equipment,
    required double tankCapacityL,
  }) {
    final waterPerHa =
        waterRatesLHa[equipment] ?? 200.0;
    final totalWaterL = waterPerHa * areaHa;

    // Normalise product to ml or g total
    double totalProductMl = 0;
    double totalProductG = 0;
    String unit = 'ml/L';
    bool isPowder = false;

    switch (doseUnit) {
      case 'ml/ha':
        totalProductMl = productDose * areaHa;
        isPowder = false;
        break;
      case 'L/ha':
        totalProductMl = productDose * areaHa * 1000;
        isPowder = false;
        break;
      case 'g/ha':
        totalProductG = productDose * areaHa;
        isPowder = true;
        unit = 'g/L';
        break;
      case 'kg/ha':
        totalProductG = productDose * areaHa * 1000;
        isPowder = true;
        unit = 'g/L';
        break;
    }

    final concentration = isPowder
        ? totalProductG / totalWaterL
        : totalProductMl / totalWaterL;

    final tanksNeeded =
        (totalWaterL / tankCapacityL).ceil();
    final productPerTank = isPowder
        ? totalProductG / tanksNeeded
        : totalProductMl / tanksNeeded;

    // Mixing steps
    final productPerTankStr = isPowder
        ? '${productPerTank.toStringAsFixed(1)} g'
        : '${productPerTank.toStringAsFixed(1)} ml';
    final halfTank =
        (tankCapacityL / 2).toStringAsFixed(0);

    final mixingSteps = [
      'Fill tank with $halfTank L of clean water (half tank)',
      'Add $productPerTankStr of $productName',
      'Agitate / stir thoroughly for 30 seconds',
      'Top up to ${tankCapacityL.toStringAsFixed(0)} L with clean water',
      'Agitate again before and during spraying',
      'Calibrate sprayer before starting — check output per ha',
      'Spray at even walking pace — overlap rows by 10–15 cm',
    ];

    final safetyNotes = [
      'Wear full PPE: gloves, mask, goggles, and protective clothing',
      'Never eat, drink, or smoke while spraying',
      'Do not spray in wind above 15 km/h or midday heat',
      'Wash equipment thoroughly after use',
      'Dispose of empty containers safely — do not reuse',
      'Observe the pre-harvest interval (PHI) on the label',
      'Keep children and livestock out of sprayed areas',
    ];

    return SprayCalcResult(
      productName: productName,
      areaHa: areaHa,
      waterVolumeLitres: totalWaterL,
      productAmountMl: totalProductMl,
      productAmountG: totalProductG,
      concentrationPct: concentration,
      unit: unit,
      tanksNeeded: tanksNeeded,
      productPerTank: productPerTank,
      tankCapacityL: tankCapacityL,
      mixingSteps: mixingSteps,
      safetyNotes: safetyNotes,
    );
  }

  // ── SEED CALCULATOR ───────────────────────────────

  static const Map<String, Map<String, dynamic>> cropSeedData = {
    'Maize': {
      'rate_kg_ha': 25.0,
      'row_spacing_cm': 90,
      'plant_spacing_cm': 25,
      'seeds_per_kg': 3500,
      'notes': [
        'Use certified seed — treated with fungicide/insecticide',
        'Plant at 5 cm depth in moist soil',
        'Standard: 1 plant per station, 90 cm × 25 cm',
        'High density: 90 cm × 20 cm for irrigated maize',
        '25 kg/ha ≈ 1 × 10 kg bag per 0.4 ha (1 acre)',
      ],
      'packaging': '10 kg bags — buy ${0} bags for ${0} ha',
    },
    'Tobacco': {
      'rate_kg_ha': 0.05,
      'row_spacing_cm': 120,
      'plant_spacing_cm': 50,
      'seeds_per_kg': 10000000,
      'notes': [
        'Tobacco seed is extremely fine — handle carefully',
        'Raise in seedbeds first, then transplant at 6–8 weeks',
        'Standard plant population: 16,000–17,000 plants/ha',
        'Seed is usually sold per gram — 1 g seeds a large seedbed',
      ],
      'packaging': 'Sold per gram — consult your contractor for rate',
    },
    'Wheat': {
      'rate_kg_ha': 120.0,
      'row_spacing_cm': 20,
      'plant_spacing_cm': 3,
      'seeds_per_kg': 20000,
      'notes': [
        'Drill at 20 cm row spacing for best yield',
        'Seed depth: 3–5 cm in moist soil',
        'Use certified disease-free seed each season',
        'Treat with fungicide before planting if not pre-treated',
      ],
      'packaging': '50 kg bags — buy ${0} bags for ${0} ha',
    },
    'Soybeans': {
      'rate_kg_ha': 80.0,
      'row_spacing_cm': 45,
      'plant_spacing_cm': 5,
      'seeds_per_kg': 5500,
      'notes': [
        'Inoculate seed with Bradyrhizobium japonicum before planting',
        'Do not apply nitrogen fertilizer — beans fix their own',
        'Seed depth: 3–5 cm in good moisture',
        'Plant at 45 cm row spacing, 5 cm within row',
      ],
      'packaging': '50 kg bags — buy ${0} bags for ${0} ha',
    },
    'Groundnuts': {
      'rate_kg_ha': 120.0,
      'row_spacing_cm': 45,
      'plant_spacing_cm': 15,
      'seeds_per_kg': 1200,
      'notes': [
        'Shell just before planting — shelled nuts deteriorate quickly',
        'Plant runners at 45 × 15 cm, Virginia types at 90 × 15 cm',
        'Inoculate with Bradyrhizobium if no previous groundnut crop',
        'Plant at 5 cm depth in well-prepared, friable soil',
      ],
      'packaging': 'Sold in 20 kg or 50 kg bags',
    },
    'Cotton': {
      'rate_kg_ha': 15.0,
      'row_spacing_cm': 100,
      'plant_spacing_cm': 30,
      'seeds_per_kg': 4500,
      'notes': [
        'Use delinted, treated seed for uniform germination',
        'Standard spacing: 100 cm × 30 cm (33,000 plants/ha)',
        'Plant at 3–5 cm depth when soil temp > 18°C',
        'Thin to 1 plant per station at 2–3 weeks',
      ],
      'packaging': '10 kg bags',
    },
    'Sunflower': {
      'rate_kg_ha': 5.0,
      'row_spacing_cm': 90,
      'plant_spacing_cm': 30,
      'seeds_per_kg': 5000,
      'notes': [
        'Plant at 5 cm depth, 1 seed per station',
        'Standard population: 37,000 plants/ha',
        'Use hybrid varieties for best oil yield',
        'Thin to 1 plant per station at 2–3 weeks',
      ],
      'packaging': '5 kg cans or bags',
    },
    'Beans': {
      'rate_kg_ha': 60.0,
      'row_spacing_cm': 45,
      'plant_spacing_cm': 10,
      'seeds_per_kg': 3000,
      'notes': [
        'Plant 2 seeds per station, thin to 1 after emergence',
        'Treat seed with imidacloprid against stem maggot',
        'Plant at 3–5 cm depth when soil moisture is adequate',
        'Do not plant in waterlogged soils',
      ],
      'packaging': '50 kg bags or 2 kg packets',
    },
    'Tomatoes': {
      'rate_kg_ha': 0.3,
      'row_spacing_cm': 100,
      'plant_spacing_cm': 50,
      'seeds_per_kg': 300000,
      'notes': [
        'Raise seedlings in seedbed or tray — transplant at 4–6 weeks',
        'Standard transplanting: 100 cm × 50 cm (20,000 plants/ha)',
        'Double rows on beds: 60 cm between plants, 100 cm bed spacing',
        'Install drip irrigation and stakes/trellis before transplanting',
      ],
      'packaging': 'Sold in 1 g, 5 g, or 10 g packets',
    },
    'Cabbages': {
      'rate_kg_ha': 0.4,
      'row_spacing_cm': 60,
      'plant_spacing_cm': 45,
      'seeds_per_kg': 350000,
      'notes': [
        'Raise seedlings in protected seedbed for 4 weeks',
        'Transplant at 60 × 45 cm for medium-sized heads',
        'Wider spacing (60 × 60 cm) produces larger heads',
        'Apply 250 ml water per plant at transplanting',
      ],
      'packaging': 'Sold per gram or in 10 g packets',
    },
    'Onions': {
      'rate_kg_ha': 4.0,
      'row_spacing_cm': 30,
      'plant_spacing_cm': 10,
      'seeds_per_kg': 250000,
      'notes': [
        'Direct seed at 30 × 10 cm or transplant seedlings',
        'Seedlings ready to transplant at 6–8 weeks (pencil thickness)',
        'Plant at 1–2 cm depth — shallow planting is key',
        'Germination improved with pre-soaking seed for 12 hours',
      ],
      'packaging': 'Sold per gram or 5 g packets',
    },
    'Potatoes': {
      'rate_kg_ha': 2000.0,
      'row_spacing_cm': 90,
      'plant_spacing_cm': 30,
      'seeds_per_kg': 5,
      'notes': [
        'Use certified disease-free seed tubers only',
        'Cut large tubers to 40–60 g pieces with at least 2 eyes each',
        'Allow cut surfaces to dry/cure for 2 days before planting',
        'Plant at 10–15 cm depth, 90 × 30 cm spacing',
        '2,000 kg/ha ≈ 50 × 50 kg bags of seed potato per ha',
      ],
      'packaging': '50 kg bags — order ${0} bags per ${0} ha',
    },
    'Sorghum': {
      'rate_kg_ha': 10.0,
      'row_spacing_cm': 90,
      'plant_spacing_cm': 15,
      'seeds_per_kg': 35000,
      'notes': [
        'Plant at 3–5 cm depth in moist soil',
        'Thin to 2–3 plants per station at 2 weeks',
        'More drought-tolerant than maize — can be planted later',
        'Watch for head smut — use treated seed',
      ],
      'packaging': '10 kg bags',
    },
    'Peppers': {
      'rate_kg_ha': 0.5,
      'row_spacing_cm': 100,
      'plant_spacing_cm': 50,
      'seeds_per_kg': 200000,
      'notes': [
        'Raise seedlings in trays for 5–6 weeks before transplanting',
        'Standard spacing: 100 × 50 cm (20,000 plants/ha)',
        'Needs well-drained soil — avoid waterlogging',
        'Install stakes or trellis for sweet pepper varieties',
      ],
      'packaging': 'Sold in 1 g or 5 g packets',
    },
  };

  static SeedCalcResult calculateSeed({
    required String crop,
    required double areaHa,
    double? customRateKgHa,
    double? customRowSpacingCm,
    double? customPlantSpacingCm,
  }) {
    final data = cropSeedData[crop] ??
        cropSeedData['Maize']!;

    final rateKgHa = customRateKgHa ??
        (data['rate_kg_ha'] as num).toDouble();
    final rowSpacing = customRowSpacingCm ??
        (data['row_spacing_cm'] as num).toDouble();
    final plantSpacing = customPlantSpacingCm ??
        (data['plant_spacing_cm'] as num).toDouble();

    final totalSeedKg = rateKgHa * areaHa;
    final totalSeedG = totalSeedKg * 1000;

    // Plants per ha from spacing
    final areaCm2 = 10000 * 10000.0; // 1 ha in cm²
    final spacingCm2 = rowSpacing * plantSpacing;
    final plantsPerHa =
        (areaCm2 / spacingCm2).round();
    final totalPlants = plantsPerHa * areaHa;

    // Packaging advice
    String packaging = '';
    if (crop == 'Maize') {
      final bags =
          (totalSeedKg / 10).ceil();
      packaging =
          '$bags × 10 kg bag${bags == 1 ? '' : 's'} needed';
    } else if (crop == 'Wheat' ||
        crop == 'Soybeans' ||
        crop == 'Groundnuts') {
      final bags =
          (totalSeedKg / 50).ceil();
      packaging =
          '$bags × 50 kg bag${bags == 1 ? '' : 's'} needed';
    } else if (crop == 'Potatoes') {
      final bags =
          (totalSeedKg / 50).ceil();
      packaging =
          '$bags × 50 kg bag${bags == 1 ? '' : 's'} of seed potato needed';
    } else if (totalSeedKg < 1) {
      packaging =
          '${totalSeedG.toStringAsFixed(0)} g of seed needed — buy in small packets';
    } else {
      packaging =
          '${totalSeedKg.toStringAsFixed(1)} kg of seed needed';
    }

    return SeedCalcResult(
      crop: crop,
      areaHa: areaHa,
      seedingRateKgHa: rateKgHa,
      totalSeedKg: totalSeedKg,
      totalSeedG: totalSeedG,
      rowSpacingCm: rowSpacing,
      plantSpacingCm: plantSpacing,
      plantsPerHa: plantsPerHa,
      totalPlants: totalPlants,
      packagingAdvice: packaging,
      notes: List<String>.from(data['notes']),
    );
  }

  // ── TANK MIX CALCULATOR ───────────────────────────

  /// Common products available in Zimbabwe
  static const List<TankMixProduct> commonProducts = [
    // Fungicides
    TankMixProduct(name: 'Mancozeb 80WP (Dithane)',    type: 'fungicide',   doseMlPer100L: 250,  unit: 'g',  activeIngredient: 'Mancozeb'),
    TankMixProduct(name: 'Ridomil Gold MZ',             type: 'fungicide',   doseMlPer100L: 250,  unit: 'g',  activeIngredient: 'Mefenoxam + Mancozeb'),
    TankMixProduct(name: 'Score 250EC',                 type: 'fungicide',   doseMlPer100L: 50,   unit: 'ml', activeIngredient: 'Difenoconazole'),
    TankMixProduct(name: 'Amistar (Azoxystrobin)',      type: 'fungicide',   doseMlPer100L: 50,   unit: 'ml', activeIngredient: 'Azoxystrobin'),
    TankMixProduct(name: 'Acrobat MZ',                  type: 'fungicide',   doseMlPer100L: 250,  unit: 'g',  activeIngredient: 'Dimethomorph + Mancozeb'),
    TankMixProduct(name: 'Copper Oxychloride 50WP',    type: 'fungicide',   doseMlPer100L: 300,  unit: 'g',  activeIngredient: 'Copper oxychloride'),
    // Insecticides
    TankMixProduct(name: 'Karate Zeon (Lambda-cyh.)',  type: 'insecticide', doseMlPer100L: 15,   unit: 'ml', activeIngredient: 'Lambda-cyhalothrin'),
    TankMixProduct(name: 'Coragen 20SC',                type: 'insecticide', doseMlPer100L: 17,   unit: 'ml', activeIngredient: 'Chlorantraniliprole'),
    TankMixProduct(name: 'Actara 25WG',                 type: 'insecticide', doseMlPer100L: 20,   unit: 'g',  activeIngredient: 'Thiamethoxam'),
    TankMixProduct(name: 'Spintor 240SC (Spinosad)',   type: 'insecticide', doseMlPer100L: 10,   unit: 'ml', activeIngredient: 'Spinosad'),
    TankMixProduct(name: 'Abamectin 1.8EC',             type: 'insecticide', doseMlPer100L: 50,   unit: 'ml', activeIngredient: 'Abamectin'),
    TankMixProduct(name: 'Proclaim 5SG',                type: 'insecticide', doseMlPer100L: 20,   unit: 'g',  activeIngredient: 'Emamectin benzoate'),
    TankMixProduct(name: 'Dimethoate 40EC',             type: 'insecticide', doseMlPer100L: 100,  unit: 'ml', activeIngredient: 'Dimethoate'),
    // Herbicides
    TankMixProduct(name: 'Roundup (Glyphosate)',        type: 'herbicide',   doseMlPer100L: 500,  unit: 'ml', activeIngredient: 'Glyphosate'),
    TankMixProduct(name: 'Dual Gold (Metolachlor)',     type: 'herbicide',   doseMlPer100L: 150,  unit: 'ml', activeIngredient: 'S-metolachlor'),
    TankMixProduct(name: 'Atrazine 80WP',               type: 'herbicide',   doseMlPer100L: 250,  unit: 'g',  activeIngredient: 'Atrazine'),
    TankMixProduct(name: 'Gramoxone (Paraquat)',        type: 'herbicide',   doseMlPer100L: 300,  unit: 'ml', activeIngredient: 'Paraquat'),
    // Foliar fertilizers
    TankMixProduct(name: 'Multifeed (NPK Foliar)',      type: 'fertilizer',  doseMlPer100L: 200,  unit: 'g',  activeIngredient: 'N-P-K + micros'),
    TankMixProduct(name: 'Calcium Nitrate Foliar',      type: 'fertilizer',  doseMlPer100L: 200,  unit: 'g',  activeIngredient: 'Ca + N'),
    TankMixProduct(name: 'Zinc Sulphate 36%',           type: 'fertilizer',  doseMlPer100L: 100,  unit: 'g',  activeIngredient: 'Zinc'),
    TankMixProduct(name: 'Boron (Solubor)',              type: 'fertilizer',  doseMlPer100L: 50,   unit: 'g',  activeIngredient: 'Boron'),
    // Adjuvants
    TankMixProduct(name: 'Break-Thru (Silwet)',         type: 'adjuvant',    doseMlPer100L: 20,   unit: 'ml', activeIngredient: 'Organosilicone'),
    TankMixProduct(name: 'Agral 90 (Surfactant)',       type: 'adjuvant',    doseMlPer100L: 25,   unit: 'ml', activeIngredient: 'Nonylphenol ethoxylate'),
  ];

  /// Incompatibility rules — pairs that should NOT be mixed
  static const List<List<String>> _incompatiblePairs = [
    ['Glyphosate', 'Mancozeb'],           // inactivation
    ['Mancozeb', 'Calcium Nitrate'],       // precipitation
    ['Copper oxychloride', 'Mancozeb'],   // precipitation
    ['Paraquat', 'Mancozeb'],             // inactivation
    ['Dimethoate', 'Alkaline products'],  // degradation
    ['Copper oxychloride', 'Glyphosate'], // chelation/inactivation
  ];

  static TankMixResult calculateTankMix({
    required double tankSizeL,
    required List<TankMixProduct> products,
  }) {
    // Calculate quantities
    final quantities = products.map((p) {
      final amount =
          (p.doseMlPer100L / 100) * tankSizeL;
      return _ProductQty(p.name, amount, p.unit);
    }).toList();

    // Compatibility check
    final warnings = <String>[];
    final activeIngredients = products
        .where((p) => p.activeIngredient != null)
        .map((p) => p.activeIngredient!)
        .toList();

    for (final pair in _incompatiblePairs) {
      final a = activeIngredients.any(
          (ai) => ai.toLowerCase().contains(
              pair[0].toLowerCase()));
      final b = activeIngredients.any(
          (ai) => ai.toLowerCase().contains(
              pair[1].toLowerCase()));
      if (a && b) {
        warnings.add(
            '⚠️ ${pair[0]} + ${pair[1]}: Potential incompatibility — may cause precipitation or inactivation.');
      }
    }

    // Herbicide + pesticide warning
    final hasHerbicide =
        products.any((p) => p.type == 'herbicide');
    final hasPesticide = products.any((p) =>
        p.type == 'fungicide' ||
        p.type == 'insecticide');
    if (hasHerbicide && hasPesticide) {
      warnings.add(
          '⚠️ Mixing herbicides with fungicides/insecticides is generally not recommended — apply separately.');
    }

    // Mixing order (WISSA rule)
    final order = [
      '1️⃣ Fill tank with 50–75% of required water first',
      '2️⃣ Add Wettable Powders (WP) and Dry Flowables (DF/WDG) — stir well',
      '3️⃣ Add Suspension Concentrates (SC) — stir well',
      '4️⃣ Add Emulsifiable Concentrates (EC) — stir well',
      '5️⃣ Add water-soluble liquids (SL) — stir well',
      '6️⃣ Add adjuvants/surfactants last',
      '7️⃣ Top up to full tank volume — agitate continuously',
      '8️⃣ Spray immediately — do not store tank mixes overnight',
    ];

    final safetyNotes = [
      'Always do a jar compatibility test before full tank mixing',
      'Mix in a well-ventilated area wearing full PPE',
      'If mixture becomes lumpy, stringy, or separates — do not use',
      'Never mix more than 3 products unless you have confirmed compatibility',
      'Read each product label before mixing',
      'Flush equipment thoroughly with clean water after use',
    ];

    return TankMixResult(
      tankSizeL: tankSizeL,
      products: products,
      quantities: quantities,
      compatibilityWarnings: warnings,
      mixingOrder: order,
      safetyNotes: safetyNotes,
      isCompatible: warnings.isEmpty,
    );
  }

  static List<String> get cropNames =>
      cropSeedData.keys.toList()..sort();
}