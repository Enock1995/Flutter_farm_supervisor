// lib/services/pest_disease_service.dart
// Pest & Disease — comprehensive Zimbabwe crop pest & disease database.
// Offline-first: all data built-in, no internet required.
// Developed by Sir Enocks — Cor Technologies

// ---------------------------------------------------------------------------
// MODELS
// ---------------------------------------------------------------------------

class PestOrDisease {
  final String id;
  final String name;
  final String localName;       // Shona/Ndebele common name if known
  final String type;            // 'pest' | 'disease'
  final List<String> affectedCrops;
  final String description;
  final List<String> symptoms;
  final List<String> conditions; // weather/conditions that favour it
  final String severity;        // 'low' | 'medium' | 'high' | 'critical'
  final List<TreatmentOption> treatments;
  final List<String> prevention;
  final String? imageEmoji;     // representative emoji

  const PestOrDisease({
    required this.id,
    required this.name,
    this.localName = '',
    required this.type,
    required this.affectedCrops,
    required this.description,
    required this.symptoms,
    required this.conditions,
    required this.severity,
    required this.treatments,
    required this.prevention,
    this.imageEmoji,
  });

  String get typeLabel => type == 'pest' ? 'Pest' : 'Disease';
  String get typeEmoji => type == 'pest' ? '🐛' : '🍄';

  String get severityEmoji {
    switch (severity) {
      case 'critical': return '🔴';
      case 'high':     return '🟠';
      case 'medium':   return '🟡';
      default:         return '🟢';
    }
  }

  String get severityLabel {
    switch (severity) {
      case 'critical': return 'Critical';
      case 'high':     return 'High';
      case 'medium':   return 'Medium';
      default:         return 'Low';
    }
  }
}

// ---------------------------------------------------------------------------

class TreatmentOption {
  final String type;          // 'chemical' | 'biological' | 'cultural'
  final String productName;   // e.g. "Mancozeb 80WP"
  final String activeIngredient;
  final String dosage;        // e.g. "2.5g per litre"
  final String frequency;     // e.g. "Every 7 days"
  final String timing;        // e.g. "Apply at first sign of infection"
  final String safetyInterval; // Days before harvest
  final List<String> safetyNotes;
  final bool availableInZimbabwe;

  const TreatmentOption({
    required this.type,
    required this.productName,
    this.activeIngredient = '',
    required this.dosage,
    required this.frequency,
    required this.timing,
    this.safetyInterval = '',
    this.safetyNotes = const [],
    this.availableInZimbabwe = true,
  });

  String get typeEmoji {
    switch (type) {
      case 'chemical':   return '🧪';
      case 'biological': return '🌿';
      default:           return '🔧';
    }
  }
}

// ---------------------------------------------------------------------------

class FarmAlert {
  final String id;
  final String userId;
  final String pestDiseaseId;
  final String pestDiseaseName;
  final String affectedCrop;
  final String? plotOrField;
  final String severity;
  final String notes;
  final DateTime reportedAt;
  final bool isResolved;
  final DateTime? resolvedAt;

  const FarmAlert({
    required this.id,
    required this.userId,
    required this.pestDiseaseId,
    required this.pestDiseaseName,
    required this.affectedCrop,
    this.plotOrField,
    required this.severity,
    this.notes = '',
    required this.reportedAt,
    this.isResolved = false,
    this.resolvedAt,
  });

  String get severityEmoji {
    switch (severity) {
      case 'critical': return '🔴';
      case 'high':     return '🟠';
      case 'medium':   return '🟡';
      default:         return '🟢';
    }
  }

  String get daysAgo {
    final diff = DateTime.now().difference(reportedAt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'pest_disease_id': pestDiseaseId,
        'pest_disease_name': pestDiseaseName,
        'affected_crop': affectedCrop,
        'plot_or_field': plotOrField,
        'severity': severity,
        'notes': notes,
        'reported_at': reportedAt.toIso8601String(),
        'is_resolved': isResolved ? 1 : 0,
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  factory FarmAlert.fromMap(Map<String, dynamic> m) => FarmAlert(
        id: m['id'],
        userId: m['user_id'],
        pestDiseaseId: m['pest_disease_id'],
        pestDiseaseName: m['pest_disease_name'],
        affectedCrop: m['affected_crop'],
        plotOrField: m['plot_or_field'],
        severity: m['severity'] ?? 'medium',
        notes: m['notes'] ?? '',
        reportedAt: DateTime.parse(m['reported_at']),
        isResolved: (m['is_resolved'] as int? ?? 0) == 1,
        resolvedAt: m['resolved_at'] != null
            ? DateTime.parse(m['resolved_at'])
            : null,
      );

  FarmAlert copyWith({bool? isResolved}) => FarmAlert(
        id: id,
        userId: userId,
        pestDiseaseId: pestDiseaseId,
        pestDiseaseName: pestDiseaseName,
        affectedCrop: affectedCrop,
        plotOrField: plotOrField,
        severity: severity,
        notes: notes,
        reportedAt: reportedAt,
        isResolved: isResolved ?? this.isResolved,
        resolvedAt: isResolved == true ? DateTime.now() : resolvedAt,
      );
}

// ---------------------------------------------------------------------------
// DATABASE
// ---------------------------------------------------------------------------

class PestDiseaseService {
  // All crops covered
  static const List<String> allCrops = [
    'All Crops',
    'Maize',
    'Tobacco',
    'Wheat',
    'Soybeans',
    'Tomatoes',
    'Cabbages',
    'Onions',
    'Potatoes',
    'Peppers',
    'Beans',
    'Groundnuts',
    'Cotton',
    'Sunflower',
    'Sorghum',
    'Cattle',
    'Poultry',
  ];

  static List<PestOrDisease> getAll() => _database;

  static List<PestOrDisease> getByCrop(String crop) {
    if (crop == 'All Crops') return _database;
    return _database
        .where((p) =>
            p.affectedCrops.contains(crop) ||
            p.affectedCrops.contains('All Crops'))
        .toList();
  }

  static List<PestOrDisease> search(String query) {
    final q = query.toLowerCase();
    return _database.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.localName.toLowerCase().contains(q) ||
        p.affectedCrops.any((c) => c.toLowerCase().contains(q)) ||
        p.symptoms.any((s) => s.toLowerCase().contains(q))).toList();
  }

  static PestOrDisease? getById(String id) {
    try {
      return _database.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ZIMBABWE PEST & DISEASE DATABASE
  // ---------------------------------------------------------------------------

  static const List<PestOrDisease> _database = [

    // ══════════════════════════════════════════════════════════
    // MAIZE PESTS
    // ══════════════════════════════════════════════════════════

    PestOrDisease(
      id: 'faw',
      name: 'Fall Armyworm',
      localName: 'Hungwe (Shona)',
      type: 'pest',
      affectedCrops: ['Maize', 'Sorghum', 'Wheat'],
      imageEmoji: '🐛',
      severity: 'critical',
      description:
          'Fall Armyworm (Spodoptera frugiperda) is the most destructive '
          'maize pest in Zimbabwe. Larvae feed inside the whorl and on leaves, '
          'causing characteristic "window pane" damage and ragged holes. '
          'A single larva can destroy an entire plant within days.',
      symptoms: [
        'Ragged holes in leaves with fine sawdust-like frass',
        'Window pane damage — transparent patches on young leaves',
        'Larvae visible inside the whorl (green/brown caterpillars)',
        'Pin-hole feeding on leaf midribs',
        'Severe cases: complete whorl destruction',
        'Young plants may be killed ("dead heart")',
      ],
      conditions: [
        'Warm, humid conditions (25–30°C)',
        'Early to mid rainy season (October–January)',
        'Dense canopy slows detection',
        'Newly emerged crops most vulnerable (2–8 weeks after planting)',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Coragen 20SC (Rynaxypyr)',
          activeIngredient: 'Chlorantraniliprole 200g/L',
          dosage: '150–200ml per hectare in 200L water',
          frequency: 'Once, repeat after 14 days if needed',
          timing:
              'Apply when larvae are small (1st–2nd instar). '
              'Direct spray into whorl for best results.',
          safetyInterval: '1 day',
          safetyNotes: [
            'Highly effective — one application usually sufficient',
            'Best applied early morning or late afternoon',
            'Avoid spraying in strong wind',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Ampligo 150ZC',
          activeIngredient: 'Chlorantraniliprole + Lambda-cyhalothrin',
          dosage: '200ml per hectare',
          frequency: 'Every 14 days',
          timing: 'At first sign of infestation',
          safetyInterval: '7 days',
          safetyNotes: [
            'Broad-spectrum — also controls other pests',
            'Wear PPE: gloves, mask, goggles',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Karate Zeon 10CS',
          activeIngredient: 'Lambda-cyhalothrin 100g/L',
          dosage: '150ml per hectare',
          frequency: 'Every 7–10 days',
          timing: 'When 20% of plants show damage',
          safetyInterval: '7 days',
          safetyNotes: [
            'Less effective on large larvae',
            'Do not apply near water bodies',
          ],
        ),
        TreatmentOption(
          type: 'biological',
          productName: 'Push-pull intercropping',
          activeIngredient: 'Desmodium + Napier grass',
          dosage: 'Plant Desmodium between maize rows',
          frequency: 'Seasonal — plant at same time as maize',
          timing: 'At planting',
          safetyNotes: [
            'Desmodium repels FAW and Striga weed',
            'Napier grass as border crop traps pests',
            'No chemical cost — sustainable long-term',
          ],
        ),
      ],
      prevention: [
        'Scout fields twice a week from emergence — catch early',
        'Pheromone traps to monitor adult moth populations',
        'Plant early in the season to avoid peak moth flights',
        'Use FAW-tolerant varieties where available (e.g. SC403)',
        'Intercrop with Desmodium (push-pull method)',
        'Remove crop residues after harvest to break the cycle',
        'Economic threshold: treat when 20% of plants are infested',
      ],
    ),

    PestOrDisease(
      id: 'maize_stalk_borer',
      name: 'Maize Stalk Borer',
      localName: 'Borer',
      type: 'pest',
      affectedCrops: ['Maize', 'Sorghum'],
      imageEmoji: '🐛',
      severity: 'high',
      description:
          'Busseola fusca — a major native maize pest in Zimbabwe. '
          'Larvae bore into stems causing "dead heart" in young plants '
          'and broken tassels/ears in older plants.',
      symptoms: [
        'Dead heart — central shoot dies in young plants',
        'Small circular holes in leaves (window paning)',
        'Frass (sawdust-like droppings) at leaf axils',
        'Broken tassels or stems',
        'Larvae visible when stem is split open',
      ],
      conditions: [
        'First generation: early rains (Oct–Nov)',
        'Second generation: mid-season (Jan–Feb)',
        'Warm temperatures favour rapid development',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Carbofuran 5G (Furadan)',
          activeIngredient: 'Carbofuran 50g/kg',
          dosage: '1 teaspoon (5g) per plant whorl',
          frequency: 'Once at early infestation',
          timing: 'Apply granules into whorl at 3–4 weeks after emergence',
          safetyInterval: '60 days',
          safetyNotes: [
            'HIGHLY TOXIC — wear full PPE',
            'Keep away from children and livestock',
            'Do not use near water sources',
            'Wash hands thoroughly after use',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Lambda-cyhalothrin (Karate)',
          activeIngredient: 'Lambda-cyhalothrin 50g/L',
          dosage: '200ml per hectare',
          frequency: 'Every 10–14 days',
          timing: 'At egg hatch / first instar larvae',
          safetyInterval: '7 days',
          safetyNotes: ['Wear gloves and mask when spraying'],
        ),
      ],
      prevention: [
        'Plant early — avoid synchrony with peak moth emergence',
        'Use resistant varieties (consult Seed Co/Agritex)',
        'Destroy crop residues after harvest',
        'Deep ploughing exposes pupae to predators',
        'Avoid ratoon cropping (regrowth harbours pests)',
      ],
    ),

    // ══════════════════════════════════════════════════════════
    // MAIZE DISEASES
    // ══════════════════════════════════════════════════════════

    PestOrDisease(
      id: 'grey_leaf_spot',
      name: 'Grey Leaf Spot',
      localName: '',
      type: 'disease',
      affectedCrops: ['Maize'],
      imageEmoji: '🍄',
      severity: 'high',
      description:
          'Cercospora zeae-maydis — the most economically significant '
          'maize foliar disease in Zimbabwe. Causes rectangular grey/tan '
          'lesions on leaves, reducing photosynthesis and yield.',
      symptoms: [
        'Small, water-soaked spots that elongate into rectangular lesions',
        'Grey to tan coloured lesions with yellow halos',
        'Lesions run parallel to leaf veins',
        'Lower leaves affected first, progressing upward',
        'Severe cases: complete leaf blighting',
      ],
      conditions: [
        'High humidity (>90%) and moderate temperatures (20–30°C)',
        'Extended leaf wetness (dew, fog, rain)',
        'Dense plant populations with poor air circulation',
        'Conservation tillage (residue on soil surface)',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Amistar (Azoxystrobin)',
          activeIngredient: 'Azoxystrobin 250g/L',
          dosage: '500ml per hectare',
          frequency: 'Every 14–21 days',
          timing: 'Apply at first sign — before lesions coalesce',
          safetyInterval: '14 days',
          safetyNotes: [
            'Strobilurin fungicide — excellent systemic activity',
            'Rotate with different chemistry to prevent resistance',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Tilt 250EC (Propiconazole)',
          activeIngredient: 'Propiconazole 250g/L',
          dosage: '500ml per hectare',
          frequency: 'Every 14 days',
          timing: 'Preventive application from tasseling',
          safetyInterval: '21 days',
          safetyNotes: ['Triazole fungicide — good curative activity'],
        ),
      ],
      prevention: [
        'Plant resistant hybrids (SC403, DK8031 have moderate tolerance)',
        'Reduce plant population density to improve airflow',
        'Avoid overhead irrigation in humid conditions',
        'Rotate maize with soybeans or other non-host crops',
        'Incorporate crop residues (reduces inoculum)',
        'Apply fungicide preventively from tasseling in high-risk seasons',
      ],
    ),

    PestOrDisease(
      id: 'maize_streak',
      name: 'Maize Streak Virus',
      localName: 'Chitukutuku (Shona)',
      type: 'disease',
      affectedCrops: ['Maize'],
      imageEmoji: '🌽',
      severity: 'high',
      description:
          'Transmitted by leafhoppers (Cicadulina spp.), Maize Streak '
          'Virus causes severe yield loss — up to 100% in susceptible '
          'varieties. Virus is not soil-borne; control the vector.',
      symptoms: [
        'Narrow, broken yellow streaks along leaf veins',
        'Stunted plant growth',
        'Leaves may turn completely yellow in severe cases',
        'No treatment once plant is infected',
        'Symptoms appear 10–14 days after infection',
      ],
      conditions: [
        'High leafhopper populations',
        'Dry spells during early crop growth',
        'Weedy fields (alternative hosts for leafhoppers)',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Imidacloprid seed dressing',
          activeIngredient: 'Imidacloprid 600g/L',
          dosage: '5ml per kg of seed',
          frequency: 'Once — at planting (seed treatment)',
          timing: 'Treat seed before planting',
          safetyInterval: 'N/A — systemic seed treatment',
          safetyNotes: [
            'Controls leafhoppers for first 4–6 weeks',
            'Most cost-effective prevention method',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Karate Zeon (Lambda-cyhalothrin)',
          activeIngredient: 'Lambda-cyhalothrin 100g/L',
          dosage: '150ml per hectare',
          frequency: 'Every 7 days in high-pressure periods',
          timing: 'When leafhoppers are observed on plants',
          safetyInterval: '7 days',
          safetyNotes: ['Target leafhoppers — not the virus itself'],
        ),
      ],
      prevention: [
        'Plant MSV-resistant varieties — this is the best control',
        'SC403, SC513, and most modern hybrids have MSV resistance',
        'Treat seed with systemic insecticide before planting',
        'Remove and destroy infected plants early',
        'Control weeds — reduce leafhopper habitat',
        'Plant as early as possible (before leafhopper peak)',
      ],
    ),

    // ══════════════════════════════════════════════════════════
    // TOMATO PESTS & DISEASES
    // ══════════════════════════════════════════════════════════

    PestOrDisease(
      id: 'tomato_leaf_miner',
      name: 'Tomato Leaf Miner',
      localName: 'Tuta absoluta',
      type: 'pest',
      affectedCrops: ['Tomatoes', 'Potatoes', 'Peppers'],
      imageEmoji: '🐛',
      severity: 'critical',
      description:
          'Tuta absoluta — an invasive moth whose larvae mine leaves, '
          'bore into stems and fruits. Can cause 80–100% crop loss '
          'in unmanaged crops. Major threat to Zimbabwe tomato production.',
      symptoms: [
        'Silvery or white blotch mines on leaves',
        'Larvae visible inside leaf mines (tiny, cream-coloured)',
        'Bored entry holes in green and ripe fruits',
        'Fruit rot at entry points',
        'Wilting of affected shoots',
        'Frass inside mined galleries',
      ],
      conditions: [
        'Year-round pest — no seasonal break in Zimbabwe',
        'Worse in dry season (irrigated crops)',
        'Greenhouse/tunnel crops highly vulnerable',
        'Rapid population buildup in warm weather',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Coragen 20SC',
          activeIngredient: 'Chlorantraniliprole 200g/L',
          dosage: '150ml per hectare',
          frequency: 'Every 10–14 days',
          timing: 'Apply before larvae enter fruit',
          safetyInterval: '1 day',
          safetyNotes: [
            'Best product for Tuta — high efficacy on young larvae',
            'Rotate with other chemistry to prevent resistance',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Spintor 240SC (Spinosad)',
          activeIngredient: 'Spinosad 240g/L',
          dosage: '100ml per hectare',
          frequency: 'Every 7–10 days',
          timing: 'At first sign of mines',
          safetyInterval: '3 days',
          safetyNotes: [
            'Biological insecticide — lower mammalian toxicity',
            'Excellent resistance management partner',
          ],
        ),
        TreatmentOption(
          type: 'biological',
          productName: 'Pheromone traps',
          activeIngredient: 'Tuta absoluta sex pheromone',
          dosage: '1 trap per 1000 m²',
          frequency: 'Replace lures every 4–6 weeks',
          timing: 'Install before transplanting',
          safetyNotes: [
            'Mass trapping reduces adult populations',
            'Also used for monitoring to time sprays',
          ],
        ),
      ],
      prevention: [
        'Install pheromone traps before transplanting',
        'Use insect-proof netting in tunnels/greenhouses',
        'Remove and destroy infested plant material',
        'Do not leave tomato residues in the field',
        'Avoid planting near previous infested crops',
        'Rotate crops — break the pest cycle',
        'Inspect transplants carefully before planting',
      ],
    ),

    PestOrDisease(
      id: 'early_blight',
      name: 'Early Blight',
      localName: '',
      type: 'disease',
      affectedCrops: ['Tomatoes', 'Potatoes', 'Peppers'],
      imageEmoji: '🍄',
      severity: 'high',
      description:
          'Alternaria solani — one of the most common tomato diseases '
          'in Zimbabwe. Causes characteristic target-board lesions on '
          'older leaves, defoliating plants and reducing yield.',
      symptoms: [
        'Dark brown to black lesions with concentric rings (target board pattern)',
        'Yellow halo around lesions',
        'Lower/older leaves affected first',
        'Lesions on stems — dark, sunken cankers',
        'Fruit infection — dark, leathery lesions at stem end',
        'Severe defoliation in humid conditions',
      ],
      conditions: [
        'Warm temperatures (24–29°C) with high humidity',
        'Alternating wet and dry periods',
        'Stressed or nutrient-deficient plants',
        'Overhead irrigation wetting foliage',
        'Dense planting with poor air circulation',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Mancozeb 80WP (Dithane M-45)',
          activeIngredient: 'Mancozeb 800g/kg',
          dosage: '2.5g per litre of water',
          frequency: 'Every 7 days preventively',
          timing: 'Start before symptoms appear in high-risk conditions',
          safetyInterval: '7 days',
          safetyNotes: [
            'Contact fungicide — must cover all leaf surfaces',
            'Re-apply after rain',
            'Very affordable and widely available in Zimbabwe',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Ridomil Gold MZ (Mefenoxam + Mancozeb)',
          activeIngredient: 'Mefenoxam 40g/kg + Mancozeb 640g/kg',
          dosage: '2.5g per litre',
          frequency: 'Every 10–14 days',
          timing: 'At first sign of disease',
          safetyInterval: '14 days',
          safetyNotes: [
            'Systemic + contact — excellent curative action',
            'Alternate with Mancozeb for resistance management',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Score 250EC (Difenoconazole)',
          activeIngredient: 'Difenoconazole 250g/L',
          dosage: '500ml per hectare',
          frequency: 'Every 14 days',
          timing: 'Curative — apply when lesions first appear',
          safetyInterval: '14 days',
          safetyNotes: ['Triazole — good curative activity'],
        ),
      ],
      prevention: [
        'Use certified disease-free seed or seedlings',
        'Maintain good plant nutrition — especially potassium',
        'Use drip irrigation — avoid wetting foliage',
        'Stake/trellis tomatoes for good air circulation',
        'Remove and destroy infected leaves and plant debris',
        'Rotate with non-solanaceous crops for 2–3 years',
        'Apply preventive fungicide spray from transplanting',
      ],
    ),

    PestOrDisease(
      id: 'late_blight',
      name: 'Late Blight',
      localName: '',
      type: 'disease',
      affectedCrops: ['Tomatoes', 'Potatoes'],
      imageEmoji: '🍄',
      severity: 'critical',
      description:
          'Phytophthora infestans — the most destructive tomato and '
          'potato disease worldwide. Can destroy an entire crop within '
          '1–2 weeks in cool, wet conditions. Caused the Irish Famine.',
      symptoms: [
        'Water-soaked, pale green spots on leaves',
        'Spots turn brown/black rapidly',
        'White fluffy mould on leaf undersides (in humid conditions)',
        'Dark brown lesions on stems — plants collapse',
        'Fruit: brown, greasy-looking rot spreading from surface',
        'Entire plant can collapse within days',
      ],
      conditions: [
        'Cool temperatures (15–20°C) with high humidity',
        'Extended leaf wetness from rain or heavy dew',
        'Cool, wet nights and mild days',
        'Zimbabwe: mainly April–June (cool season)',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Ridomil Gold MZ',
          activeIngredient: 'Mefenoxam + Mancozeb',
          dosage: '2.5g per litre',
          frequency: 'Every 7–10 days',
          timing:
              'Begin preventive sprays before cool/wet weather. '
              'Once disease is established, increase to every 5–7 days.',
          safetyInterval: '14 days',
          safetyNotes: [
            'Best product for late blight — systemic activity',
            'Apply under leaf surfaces for maximum coverage',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Acrobat MZ (Dimethomorph + Mancozeb)',
          activeIngredient: 'Dimethomorph 90g/kg + Mancozeb 600g/kg',
          dosage: '2.5g per litre',
          frequency: 'Every 7–10 days',
          timing: 'Rotate with Ridomil for resistance management',
          safetyInterval: '7 days',
          safetyNotes: ['Excellent resistance management partner to Ridomil'],
        ),
      ],
      prevention: [
        'CRITICAL: Start preventive sprays before cool/wet weather arrives',
        'Use resistant varieties where available',
        'Avoid overhead irrigation — use drip',
        'Space plants for maximum air circulation',
        'Remove volunteer tomato/potato plants from field',
        'Destroy infected plant material immediately — do not compost',
        'Monitor weather forecasts — act before blight conditions arrive',
      ],
    ),

    // ══════════════════════════════════════════════════════════
    // GENERAL / CROSS-CROP PESTS
    // ══════════════════════════════════════════════════════════

    PestOrDisease(
      id: 'whitefly',
      name: 'Whitefly',
      localName: '',
      type: 'pest',
      affectedCrops: [
        'Tomatoes', 'Cabbages', 'Peppers', 'Beans',
        'Cotton', 'Tobacco'
      ],
      imageEmoji: '🦟',
      severity: 'high',
      description:
          'Bemisia tabaci (tobacco whitefly) — a tiny sap-sucking insect '
          'that also vectors Tomato Yellow Leaf Curl Virus (TYLCV) and '
          'other damaging viruses. Heavy infestations cause leaf yellowing '
          'and wilting.',
      symptoms: [
        'Tiny white insects flying up when plant is disturbed',
        'Yellow, sticky honeydew on leaves and fruit',
        'Black sooty mould growing on honeydew',
        'Yellowing and curling of leaves',
        'Silvery appearance on leaf undersides',
        'Virus symptoms: yellow mosaic, leaf curl, stunting',
      ],
      conditions: [
        'Hot, dry conditions favour rapid population buildup',
        'Dry season (May–October) on irrigated crops',
        'Dusty conditions reduce natural enemies',
        'Monoculture planting',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Actara 25WG (Thiamethoxam)',
          activeIngredient: 'Thiamethoxam 250g/kg',
          dosage: '200g per hectare',
          frequency: 'Every 14 days',
          timing: 'Apply at first sign of infestation',
          safetyInterval: '7 days',
          safetyNotes: [
            'Neonicotinoid — excellent systemic uptake',
            'Avoid use when bees are active',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Movento 150OD (Spirotetramat)',
          activeIngredient: 'Spirotetramat 150g/L',
          dosage: '500ml per hectare',
          frequency: 'Every 14–21 days',
          timing: 'For established populations',
          safetyInterval: '3 days',
          safetyNotes: [
            'Translaminar — reaches leaf undersides from top spray',
            'Excellent for resistance management',
          ],
        ),
        TreatmentOption(
          type: 'biological',
          productName: 'Yellow sticky traps',
          activeIngredient: 'Physical trap',
          dosage: '40–50 traps per hectare',
          frequency: 'Replace every 2–4 weeks',
          timing: 'Install before transplanting',
          safetyNotes: [
            'Monitoring and mass trapping combined',
            'No chemical residue concerns',
          ],
        ),
      ],
      prevention: [
        'Use reflective mulch — disorients whiteflies',
        'Install yellow sticky traps for early detection',
        'Plant resistant varieties (TYLCV-resistant tomatoes)',
        'Use insect-proof nets in tunnels',
        'Avoid planting near old/infected crops',
        'Remove crop residues promptly after harvest',
        'Encourage natural enemies — avoid broad-spectrum sprays',
      ],
    ),

    PestOrDisease(
      id: 'red_spider_mite',
      name: 'Red Spider Mite',
      localName: '',
      type: 'pest',
      affectedCrops: [
        'Tomatoes', 'Beans', 'Maize', 'Cotton',
        'Groundnuts', 'Peppers'
      ],
      imageEmoji: '🕷️',
      severity: 'high',
      description:
          'Tetranychus urticae — tiny mites that feed on leaf cells, '
          'causing stippling, bronzing, and webbing. Populations explode '
          'in hot, dry conditions. Resistant to many pesticides.',
      symptoms: [
        'Fine stippling (tiny yellow dots) on upper leaf surface',
        'Leaf undersides covered with fine webbing',
        'Bronzing or silvering of heavily infested leaves',
        'Premature leaf drop',
        'Tiny red/orange mites visible under leaves with magnification',
        'Plant vigour declines rapidly in severe infestations',
      ],
      conditions: [
        'Hot, dry weather (>30°C with low humidity)',
        'Dusty conditions that kill natural predators',
        'Drought-stressed plants are more susceptible',
        'Overuse of broad-spectrum insecticides (kills predators)',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Abamectin (Agrimec 1.8EC)',
          activeIngredient: 'Abamectin 18g/L',
          dosage: '500–750ml per hectare',
          frequency: 'Every 7–10 days',
          timing:
              'Apply at first sign — mites multiply rapidly. '
              'Spray under leaf surfaces thoroughly.',
          safetyInterval: '7 days',
          safetyNotes: [
            'Highly effective on mites',
            'Toxic to bees — do not spray during flowering',
            'Rotate with different chemistry',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Envidor 240SC (Spirodiclofen)',
          activeIngredient: 'Spirodiclofen 240g/L',
          dosage: '500ml per hectare',
          frequency: 'Once per season (residual)',
          timing: 'At early infestation',
          safetyInterval: '3 days',
          safetyNotes: ['Long residual — one application protects for weeks'],
        ),
        TreatmentOption(
          type: 'biological',
          productName: 'Wettable sulphur (Thiovit)',
          activeIngredient: 'Sulphur 800g/kg',
          dosage: '3g per litre',
          frequency: 'Every 7–10 days',
          timing: 'Preventive and curative',
          safetyInterval: '1 day',
          safetyNotes: [
            'Do not apply in temperatures above 35°C (phytotoxic)',
            'Good organic-compatible option',
            'Available everywhere in Zimbabwe',
          ],
        ),
      ],
      prevention: [
        'Avoid dusty conditions — water access roads near crops',
        'Maintain adequate soil moisture — avoid plant stress',
        'Conserve natural predators (Phytoseiid mites)',
        'Avoid overuse of broad-spectrum insecticides',
        'Remove and destroy heavily infested plant material',
        'Intercrop to disrupt mite spread',
      ],
    ),

    // ══════════════════════════════════════════════════════════
    // CABBAGE / BRASSICA PESTS
    // ══════════════════════════════════════════════════════════

    PestOrDisease(
      id: 'diamondback_moth',
      name: 'Diamondback Moth',
      localName: '',
      type: 'pest',
      affectedCrops: ['Cabbages', 'Onions'],
      imageEmoji: '🦋',
      severity: 'high',
      description:
          'Plutella xylostella — the most important brassica pest worldwide. '
          'Highly resistant to many insecticides. Larvae skeletonize leaves, '
          'leaving a "windowpane" of thin tissue.',
      symptoms: [
        'Small, irregular holes in outer leaves',
        'Window-paning — translucent patches where larvae have fed',
        'Small green larvae (1cm) on leaf undersides',
        'Larvae wriggle and drop on silk threads when disturbed',
        'Severe defoliation in high-pressure situations',
      ],
      conditions: [
        'Year-round pest in Zimbabwe',
        'Dry conditions favour outbreaks',
        'Continuous brassica production allows population buildup',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Proclaim 5SG (Emamectin benzoate)',
          activeIngredient: 'Emamectin benzoate 50g/kg',
          dosage: '200g per hectare',
          frequency: 'Every 7–10 days',
          timing: 'When young larvae are present',
          safetyInterval: '3 days',
          safetyNotes: [
            'Excellent on DBM including resistant populations',
            'Rotate with Spinosad for resistance management',
          ],
        ),
        TreatmentOption(
          type: 'biological',
          productName: 'Bt (Dipel / Thuricide)',
          activeIngredient: 'Bacillus thuringiensis var. kurstaki',
          dosage: '1–2kg per hectare',
          frequency: 'Every 5–7 days',
          timing: 'When young larvae are actively feeding',
          safetyInterval: '0 days',
          safetyNotes: [
            'Completely safe for humans and beneficial insects',
            'Only kills caterpillars — excellent for resistance management',
            'Efficacy reduced in full sunlight — apply evening',
          ],
        ),
      ],
      prevention: [
        'Avoid continuous brassica cultivation in same field',
        'Use fine-mesh netting to exclude adults',
        'Intercrop with tomatoes, onions, or coriander',
        'Plant trap crops (Indian mustard) on field borders',
        'Conserve parasitoid wasps (Cotesia plutellae)',
        'Rotate insecticide classes to manage resistance',
      ],
    ),

    // ══════════════════════════════════════════════════════════
    // LIVESTOCK DISEASES
    // ══════════════════════════════════════════════════════════

    PestOrDisease(
      id: 'fmd',
      name: 'Foot and Mouth Disease (FMD)',
      localName: 'Murwi (Shona)',
      type: 'disease',
      affectedCrops: ['Cattle'],
      imageEmoji: '🐄',
      severity: 'critical',
      description:
          'Highly contagious viral disease affecting cloven-hoofed animals. '
          'Causes severe production losses and trade restrictions. '
          'Notifiable disease — must report to DVS immediately.',
      symptoms: [
        'Excessive salivation and drooling',
        'Blisters (vesicles) on tongue, gums, and lips',
        'Blisters on feet — severe lameness',
        'Animals reluctant to walk or stand',
        'Reduced milk production in dairy cows',
        'High fever (40–41°C)',
        'Young animals may die from heart muscle damage',
      ],
      conditions: [
        'Spreads rapidly through direct contact',
        'Airborne transmission over short distances',
        'Contaminated vehicles, equipment, and people',
        'Movement of infected animals',
      ],
      treatments: [
        TreatmentOption(
          type: 'cultural',
          productName: 'Supportive care only',
          activeIngredient: 'No specific antiviral treatment',
          dosage: 'Consult veterinarian',
          frequency: 'Daily until recovery',
          timing: 'Immediately upon diagnosis',
          safetyNotes: [
            'NOTIFIABLE DISEASE — contact DVS immediately',
            'Isolate affected animals immediately',
            'Provide soft feed and clean water',
            'Treat mouth lesions with glycerine or antiseptic',
            'Foot baths with 4% sodium carbonate solution',
          ],
        ),
      ],
      prevention: [
        'VACCINATE annually — FMD vaccines available from DVS/private vets',
        'Maintain strict biosecurity — control animal movements',
        'Disinfect vehicles entering the farm',
        'Do not purchase animals from outbreak areas',
        'Report any suspected FMD to DVS immediately',
        'Comply with government movement restrictions',
        'Do not share equipment with neighbouring farms during outbreaks',
      ],
    ),

    PestOrDisease(
      id: 'newcastle_disease',
      name: 'Newcastle Disease',
      localName: '',
      type: 'disease',
      affectedCrops: ['Poultry'],
      imageEmoji: '🐓',
      severity: 'critical',
      description:
          'Highly contagious viral disease of poultry that can kill '
          'an entire flock within days. Major cause of poultry losses '
          'in Zimbabwe, especially in backyard flocks.',
      symptoms: [
        'Sudden death with high mortality',
        'Gasping, coughing, and wheezing',
        'Greenish, watery diarrhoea',
        'Twisted neck (torticollis) and nervous signs',
        'Swollen head and face',
        'Severe drop in egg production',
        'Soft-shelled or malformed eggs',
      ],
      conditions: [
        'Spreads through direct contact, faeces, and equipment',
        'Wild birds are carriers',
        'Unvaccinated flocks at extreme risk',
        'Stress weakens resistance',
      ],
      treatments: [
        TreatmentOption(
          type: 'cultural',
          productName: 'Supportive care only',
          activeIngredient: 'No specific antiviral',
          dosage: 'Electrolytes in water',
          frequency: 'Daily',
          timing: 'Immediately',
          safetyNotes: [
            'No cure — prevention through vaccination is essential',
            'Cull severely affected birds humanely',
            'Add vitamins and electrolytes to water',
            'Biosecurity: isolate new birds for 21 days',
          ],
        ),
      ],
      prevention: [
        'VACCINATE at day-old with Hitchner B1 or LaSota vaccine',
        'Booster vaccine at 3–4 weeks',
        'Maintain good biosecurity — limit visitor access',
        'Prevent wild birds from entering poultry houses',
        'Clean and disinfect houses between flocks',
        'Do not mix birds of different ages',
        'Source chicks from reputable, vaccinated flocks',
      ],
    ),

    // ══════════════════════════════════════════════════════════
    // TOBACCO
    // ══════════════════════════════════════════════════════════

    PestOrDisease(
      id: 'tobacco_blue_mould',
      name: 'Blue Mould (Tobacco)',
      localName: '',
      type: 'disease',
      affectedCrops: ['Tobacco'],
      imageEmoji: '🍄',
      severity: 'critical',
      description:
          'Peronospora hyoscyami — the most destructive tobacco disease '
          'in Zimbabwe. Spreads rapidly in cool, wet conditions and can '
          'devastate an entire crop or seedbed within days.',
      symptoms: [
        'Yellow patches on upper leaf surface',
        'Bluish-grey fluffy mould on corresponding leaf undersides',
        'Affected leaves curl and wither',
        'Seedlings collapse rapidly in seedbeds',
        'Disease spreads downwind — look for new patches daily',
      ],
      conditions: [
        'Cool temperatures (7–25°C)',
        'High humidity and rain',
        'Dense seedbeds with poor ventilation',
        'Overhead irrigation',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Ridomil Gold MZ',
          activeIngredient: 'Mefenoxam + Mancozeb',
          dosage: '2.5g per litre',
          frequency: 'Every 7–10 days preventively',
          timing:
              'Begin preventive sprays at seedbed stage. '
              'In the field: apply at transplanting and fortnightly.',
          safetyInterval: '14 days',
          safetyNotes: [
            'Best product for blue mould',
            'Apply under leaves for full coverage',
          ],
        ),
      ],
      prevention: [
        'Monitor weather forecasts — act before blue mould conditions',
        'Ensure good seedbed ventilation — remove covers during dry days',
        'Use certified, disease-free transplants only',
        'Avoid overhead irrigation in the field',
        'Remove and destroy infected plants immediately',
        'Apply Ridomil preventively at transplanting',
      ],
    ),

    // ══════════════════════════════════════════════════════════
    // BEANS / GROUNDNUTS
    // ══════════════════════════════════════════════════════════

    PestOrDisease(
      id: 'bean_stem_maggot',
      name: 'Bean Stem Maggot',
      localName: '',
      type: 'pest',
      affectedCrops: ['Beans', 'Soybeans', 'Groundnuts'],
      imageEmoji: '🐛',
      severity: 'high',
      description:
          'Ophiomyia spp. — tiny fly larvae that mine into bean stems '
          'near the soil surface, girdling plants and causing wilting '
          'and death. Often mistaken for a root disease.',
      symptoms: [
        'Yellowing and wilting of young seedlings',
        'Plant fails to thrive despite adequate moisture',
        'Dark streaks or tunnels in stems at soil level',
        'Plant pulls out easily — roots appear healthy',
        'Tiny white maggots visible when stem is split',
      ],
      conditions: [
        'Most damaging during seedling stage (0–3 weeks)',
        'Early planting before first rains',
        'Dry conditions at planting',
      ],
      treatments: [
        TreatmentOption(
          type: 'chemical',
          productName: 'Imidacloprid seed treatment',
          activeIngredient: 'Imidacloprid 600g/L',
          dosage: '5ml per kg of seed',
          frequency: 'Once — at planting',
          timing: 'Treat seed before planting',
          safetyInterval: 'N/A',
          safetyNotes: [
            'Most effective preventive measure',
            'Wear gloves when handling treated seed',
          ],
        ),
        TreatmentOption(
          type: 'chemical',
          productName: 'Dimethoate 40EC',
          activeIngredient: 'Dimethoate 400g/L',
          dosage: '1L per hectare',
          frequency: 'Every 7 days',
          timing: 'Spray around stem base at soil level',
          safetyInterval: '14 days',
          safetyNotes: [
            'Direct spray to soil/stem junction',
            'Wear full PPE — organophosphate',
          ],
        ),
      ],
      prevention: [
        'Treat seed with imidacloprid before planting',
        'Plant when soil moisture is adequate — avoid dry planting',
        'Avoid planting beans repeatedly in the same field',
        'Rotate with cereals (maize, sorghum)',
        'Plant at recommended depth to encourage strong seedling emergence',
      ],
    ),
  ];
}