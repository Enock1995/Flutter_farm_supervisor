// lib/services/advisory/crop_advisory_service.dart
// Rule-based crop intelligence engine.
// Provides planting calendars, growth stages, pest alerts,
// fertilizer advice — all based on region + crop + current month.

class CropAdvisoryService {
  static final CropAdvisoryService _instance =
      CropAdvisoryService._internal();
  factory CropAdvisoryService() => _instance;
  CropAdvisoryService._internal();

  // ---------------------------------------------------------------------------
  // PLANTING CALENDAR
  // Best months to plant each crop per region (1=Jan, 12=Dec)
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, List<int>>> plantingCalendar = {
    'Maize': {
      'I':   [10, 11],
      'IIa': [11, 12],
      'IIb': [11, 12],
      'III': [11, 12],
      'IV':  [12, 1],
      'V':   [12, 1],
    },
    'Tobacco': {
      'I':   [9, 10],
      'IIa': [9, 10, 11],
      'IIb': [9, 10, 11],
      'III': [10, 11],
      'IV':  [],
      'V':   [],
    },
    'Cotton': {
      'I':   [],
      'IIa': [11, 12],
      'IIb': [11, 12],
      'III': [11, 12],
      'IV':  [11, 12],
      'V':   [],
    },
    'Wheat': {
      'I':   [4, 5, 6],
      'IIa': [4, 5, 6],
      'IIb': [4, 5, 6],
      'III': [5, 6],
      'IV':  [],
      'V':   [],
    },
    'Sorghum': {
      'I':   [10, 11],
      'IIa': [11, 12],
      'IIb': [11, 12],
      'III': [11, 12],
      'IV':  [11, 12],
      'V':   [11, 12],
    },
    'Millet': {
      'I':   [10, 11],
      'IIa': [11, 12],
      'IIb': [11, 12],
      'III': [11, 12],
      'IV':  [11, 12],
      'V':   [11, 12],
    },
    'Soybeans': {
      'I':   [10, 11],
      'IIa': [11, 12],
      'IIb': [11, 12],
      'III': [11, 12],
      'IV':  [],
      'V':   [],
    },
    'Groundnuts': {
      'I':   [10, 11],
      'IIa': [11, 12],
      'IIb': [11, 12],
      'III': [11, 12],
      'IV':  [11, 12],
      'V':   [],
    },
    'Sunflower': {
      'I':   [10, 11],
      'IIa': [1, 2, 11],
      'IIb': [1, 2, 11],
      'III': [1, 2],
      'IV':  [1, 2],
      'V':   [],
    },
    'Potatoes': {
      'I':   [1, 2, 7, 8],
      'IIa': [1, 2, 7, 8],
      'IIb': [1, 2],
      'III': [],
      'IV':  [],
      'V':   [],
    },
    'Tomatoes': {
      'I':   [1, 2, 7, 8, 9],
      'IIa': [1, 2, 7, 8, 9],
      'IIb': [1, 2, 7, 8],
      'III': [7, 8],
      'IV':  [7, 8],
      'V':   [],
    },
    'Onions': {
      'I':   [3, 4, 5, 6],
      'IIa': [3, 4, 5, 6],
      'IIb': [3, 4, 5, 6],
      'III': [4, 5, 6],
      'IV':  [],
      'V':   [],
    },
    'Sugar Beans': {
      'I':   [10, 11],
      'IIa': [10, 11, 12],
      'IIb': [10, 11, 12],
      'III': [11, 12],
      'IV':  [],
      'V':   [],
    },
    'Cowpeas': {
      'I':   [10, 11],
      'IIa': [11, 12],
      'IIb': [11, 12],
      'III': [11, 12],
      'IV':  [11, 12],
      'V':   [11, 12],
    },
    'Sweet Potatoes': {
      'I':   [10, 11],
      'IIa': [10, 11, 12],
      'IIb': [10, 11, 12],
      'III': [11, 12],
      'IV':  [],
      'V':   [],
    },
  };

  // ---------------------------------------------------------------------------
  // GROWTH STAGES per crop
  // Each stage: name, duration in days, key tasks
  // ---------------------------------------------------------------------------
  static const Map<String, List<Map<String, dynamic>>> growthStages = {
    'Maize': [
      {
        'stage': 'Land Preparation',
        'days': 14,
        'icon': '🚜',
        'tasks': [
          'Plough land to 20–25cm depth',
          'Apply basal fertilizer (Compound D or compound fertilizer)',
          'Prepare seedbed — break up clods',
          'Mark out rows 90cm apart',
        ],
        'tip': 'Well-prepared land improves germination by up to 30%.',
      },
      {
        'stage': 'Planting',
        'days': 7,
        'icon': '🌱',
        'tasks': [
          'Plant 2 seeds per hole, 25cm apart in rows',
          'Cover seeds with 3–5cm of soil',
          'Apply starter fertilizer (Ammonium Nitrate) at planting',
          'Ensure adequate soil moisture before planting',
        ],
        'tip': 'Plant at the start of the rainy season for best germination.',
      },
      {
        'stage': 'Germination & Emergence',
        'days': 14,
        'icon': '🌿',
        'tasks': [
          'Monitor for poor germination — replant gaps',
          'Check for cutworm damage at base of seedlings',
          'Keep field weed-free during this critical stage',
        ],
        'tip': 'Germination should occur within 7–10 days.',
      },
      {
        'stage': 'Vegetative Growth',
        'days': 35,
        'icon': '🌾',
        'tasks': [
          'Apply top dressing fertilizer (AN) at 4–6 leaf stage',
          'Weed twice — at 2 weeks and 4 weeks after emergence',
          'Scout for fall armyworm in the whorl',
          'Apply pesticide if >20% of plants show armyworm damage',
        ],
        'tip':
            'Weeding in first 6 weeks is critical — weed competition can reduce yield by 50%.',
      },
      {
        'stage': 'Tasseling & Silking',
        'days': 14,
        'icon': '🌽',
        'tasks': [
          'Ensure adequate water at this critical stage',
          'Monitor for stalk borer damage',
          'Do NOT apply pesticide — pollination happening',
          'Remove barren tillers',
        ],
        'tip':
            'Water stress at tasseling causes the biggest yield losses.',
      },
      {
        'stage': 'Grain Fill',
        'days': 35,
        'icon': '🌽',
        'tasks': [
          'Continue monitoring for stalk borer',
          'Watch for grey leaf spot and northern leaf blight',
          'Ensure no water stress during grain fill',
        ],
        'tip': 'A healthy crop at this stage sets the final yield.',
      },
      {
        'stage': 'Maturity & Harvest',
        'days': 21,
        'icon': '🏆',
        'tasks': [
          'Check for black layer formation at grain base',
          'Harvest when grain moisture is 20–25%',
          'Dry grain to 12–13% moisture before storage',
          'Store in clean, dry, pest-free storage',
        ],
        'tip':
            'Early harvest prevents aflatoxin contamination from wet conditions.',
      },
    ],
    'Tobacco': [
      {
        'stage': 'Seedbed Preparation',
        'days': 7,
        'icon': '🌱',
        'tasks': [
          'Prepare float trays or conventional seedbed',
          'Sterilize soil/media to prevent damping off',
          'Mix growing media — peat moss + vermiculite (float)',
          'Sow seeds — extremely small, mix with sand for even spread',
        ],
        'tip': 'Tobacco seeds need light to germinate — do not cover deeply.',
      },
      {
        'stage': 'Seedling Growth',
        'days': 56,
        'icon': '🌿',
        'tasks': [
          'Maintain float tray water levels (float system)',
          'Apply starter nutrients to float water',
          'Control blue mold and damping off with fungicide',
          'Harden seedlings 2 weeks before transplanting',
        ],
        'tip': 'Seedlings are ready when they have 5–6 true leaves.',
      },
      {
        'stage': 'Transplanting',
        'days': 14,
        'icon': '🚜',
        'tasks': [
          'Transplant at start of rains or with irrigation',
          'Space at 1.2m x 0.5m (16,666 plants/ha)',
          'Apply basal fertilizer in planting hole',
          'Water immediately after transplanting',
        ],
        'tip': 'Transplant in the afternoon or on overcast days to reduce stress.',
      },
      {
        'stage': 'Early Growth',
        'days': 28,
        'icon': '🌾',
        'tasks': [
          'Weed between rows',
          'Apply side dressing nitrogen',
          'Scout for aphids, whitefly, and flea beetles',
          'Apply insecticide if pest threshold exceeded',
        ],
        'tip': 'Avoid over-applying nitrogen — causes quality problems at curing.',
      },
      {
        'stage': 'Rapid Growth & Topping',
        'days': 21,
        'icon': '✂️',
        'tasks': [
          'Top plants (remove flower head) at correct leaf number',
          'Apply sucker control chemical within 24 hours of topping',
          'Monitor for budworm attack after topping',
          'Apply pesticide for budworm if needed',
        ],
        'tip':
            'Topping at the right stage is critical for leaf quality and yield.',
      },
      {
        'stage': 'Ripening',
        'days': 28,
        'icon': '🍂',
        'tasks': [
          'Monitor leaf ripeness — look for yellowing from bottom up',
          'Begin harvesting bottom leaves (priming) when yellow',
          'Handle leaves carefully to avoid bruising',
          'Grade and tie leaves for curing',
        ],
        'tip': 'Harvest at correct ripeness — over-ripe or under-ripe reduces value.',
      },
      {
        'stage': 'Curing',
        'days': 7,
        'icon': '🔥',
        'tasks': [
          'Flue-curing: Follow temperature/humidity schedule precisely',
          'Start yellowing phase: 35–38°C for 30–40 hours',
          'Leaf drying: raise to 60–65°C',
          'Stem drying: raise to 70–75°C',
          'Cool and bulk cured leaf — condition to 14% moisture',
        ],
        'tip': 'Incorrect curing temperatures destroy leaf quality permanently.',
      },
    ],
    'Cotton': [
      {
        'stage': 'Land Preparation',
        'days': 14,
        'icon': '🚜',
        'tasks': [
          'Deep plough land 6–8 weeks before planting',
          'Apply lime if pH below 5.5',
          'Prepare fine seedbed',
          'Apply basal fertilizer',
        ],
        'tip': 'Cotton prefers well-drained soils with pH 5.8–7.0.',
      },
      {
        'stage': 'Planting',
        'days': 7,
        'icon': '🌱',
        'tasks': [
          'Plant when soil temp is above 18°C',
          'Sow 2–3 seeds per station, 30cm apart, 90cm rows',
          'Thin to 1 plant per station at 3-leaf stage',
          'Apply starter fertilizer (Compound S)',
        ],
        'tip': 'Correct plant population is key — 37,000 plants/ha is ideal.',
      },
      {
        'stage': 'Vegetative',
        'days': 42,
        'icon': '🌿',
        'tasks': [
          'Weed at 3 weeks and 6 weeks',
          'Apply top dressing nitrogen at 5-leaf stage',
          'Scout for red spider mite, aphids, and bollworm',
          'Begin pesticide program based on pest counts',
        ],
        'tip': 'A 7–10 day spray program protects early square formation.',
      },
      {
        'stage': 'Flowering & Boll Formation',
        'days': 42,
        'icon': '🌸',
        'tasks': [
          'Maintain spray program for bollworm',
          'Monitor for American bollworm and pink bollworm',
          'Apply potassium fertilizer to support boll fill',
          'Check plant for signs of cotton leafcurl virus',
        ],
        'tip': 'This is the most critical stage — protect every boll.',
      },
      {
        'stage': 'Boll Opening & Harvest',
        'days': 28,
        'icon': '☁️',
        'tasks': [
          'Apply defoliant when 60% of bolls are open (if irrigated)',
          'Harvest when 75%+ of bolls are open',
          'Pick in dry conditions — avoid harvesting wet cotton',
          'Grade cotton — keep seed cotton clean',
        ],
        'tip': 'Contaminated or wet cotton is heavily penalized at the gin.',
      },
    ],
    'Tomatoes': [
      {
        'stage': 'Seedbed / Nursery',
        'days': 28,
        'icon': '🌱',
        'tasks': [
          'Sow in seed trays with sterilized potting mix',
          'Keep moist — water twice daily',
          'Apply starter fertilizer at 2-leaf stage',
          'Harden seedlings by reducing water 1 week before transplant',
        ],
        'tip': 'Healthy transplants produce higher yields than weak ones.',
      },
      {
        'stage': 'Transplanting',
        'days': 7,
        'icon': '🚜',
        'tasks': [
          'Transplant at 4–5 leaf stage',
          'Space at 60cm x 90cm',
          'Apply base fertilizer in planting hole',
          'Water immediately — maintain moisture for 2 weeks',
        ],
        'tip': 'Transplant late afternoon or evening to reduce transplant shock.',
      },
      {
        'stage': 'Vegetative',
        'days': 21,
        'icon': '🌿',
        'tasks': [
          'Stake or tie plants when 30cm tall',
          'Remove suckers weekly for indeterminate varieties',
          'Apply balanced NPK fertilizer',
          'Scout for aphids, whitefly, leafminer',
        ],
        'tip': 'Regular suckering improves air circulation and fruit quality.',
      },
      {
        'stage': 'Flowering',
        'days': 14,
        'icon': '🌸',
        'tasks': [
          'Apply calcium nitrate to prevent blossom end rot',
          'Maintain consistent soil moisture — prevent fluctuation',
          'Scout for early blight and bacterial wilt',
          'Apply fungicide preventatively',
        ],
        'tip':
            'Inconsistent watering causes blossom drop and blossom end rot.',
      },
      {
        'stage': 'Fruit Development',
        'days': 21,
        'icon': '🍅',
        'tasks': [
          'Increase potassium fertilizer for fruit fill',
          'Maintain spray program for late blight',
          'Monitor for red spider mite in dry conditions',
          'Continue staking and tying as plant grows',
        ],
        'tip': 'Potassium is critical for fruit quality and shelf life.',
      },
      {
        'stage': 'Harvesting',
        'days': 21,
        'icon': '🏆',
        'tasks': [
          'Harvest at breaker stage for transport markets',
          'Harvest fully red for local/fresh markets',
          'Handle carefully to avoid bruising',
          'Store at 13–18°C to extend shelf life',
        ],
        'tip': 'Tomatoes harvested at the right stage fetch the best prices.',
      },
    ],
    'Wheat': [
      {
        'stage': 'Land Preparation',
        'days': 14,
        'icon': '🚜',
        'tasks': [
          'Plough and prepare fine, firm seedbed',
          'Apply basal fertilizer (Compound C or D)',
          'Ensure irrigation system is working',
          'Check seed for germination rate',
        ],
        'tip': 'Wheat is a winter crop — plant April to June in Zimbabwe.',
      },
      {
        'stage': 'Planting',
        'days': 7,
        'icon': '🌱',
        'tasks': [
          'Sow at 120–140 kg/ha seed rate',
          'Drill or broadcast seed at 2–3cm depth',
          'Apply starter nitrogen at planting',
          'Irrigate immediately after planting',
        ],
        'tip':
            'Use certified seed — higher germination and disease resistance.',
      },
      {
        'stage': 'Germination & Tillering',
        'days': 28,
        'icon': '🌿',
        'tasks': [
          'Apply herbicide for broadleaf weeds at 2-leaf stage',
          'Monitor for rust diseases',
          'Apply nitrogen top dressing at tillering',
          'Irrigate every 10–14 days',
        ],
        'tip': 'Good tillering means more heads and higher yield.',
      },
      {
        'stage': 'Stem Extension & Heading',
        'days': 28,
        'icon': '🌾',
        'tasks': [
          'Apply fungicide for rust, septoria, powdery mildew',
          'Monitor for aphids — control if >10 per tiller',
          'Apply final nitrogen at flag leaf stage',
          'Maintain regular irrigation',
        ],
        'tip': 'Rust can destroy an entire crop within 2 weeks if uncontrolled.',
      },
      {
        'stage': 'Grain Fill & Maturity',
        'days': 35,
        'icon': '🌾',
        'tasks': [
          'Reduce irrigation frequency at dough stage',
          'Monitor for aphids on the ear',
          'Watch for pre-harvest sprouting in wet conditions',
          'Harvest when grain moisture is 14–15%',
        ],
        'tip': 'Early harvest avoids quality losses from wet weather.',
      },
    ],
    'Sorghum': [
      {
        'stage': 'Land Preparation',
        'days': 7,
        'icon': '🚜',
        'tasks': [
          'Minimum tillage suitable for sorghum',
          'Apply basal fertilizer (Compound D)',
          'Sorghum tolerates poor soils better than maize',
        ],
        'tip': 'Sorghum is ideal for sandy or shallow soils where maize fails.',
      },
      {
        'stage': 'Planting',
        'days': 7,
        'icon': '🌱',
        'tasks': [
          'Plant at 90cm x 25cm spacing',
          'Sow 1–2 seeds per hole at 3cm depth',
          'Thin to 1 plant per station',
          'Plant December–January with first rains',
        ],
        'tip': 'Sorghum germinates best when soil temperature is above 20°C.',
      },
      {
        'stage': 'Vegetative',
        'days': 35,
        'icon': '🌿',
        'tasks': [
          'Weed at 3 and 6 weeks',
          'Apply nitrogen top dressing at 4-leaf stage',
          'Scout for shootfly in young plants',
          'Apply insecticide if >10% plants show deadheart',
        ],
        'tip': 'Sorghum smothers weeds better than maize once established.',
      },
      {
        'stage': 'Heading & Grain Fill',
        'days': 42,
        'icon': '🌾',
        'tasks': [
          'Monitor for head bugs (mirid bugs)',
          'Bird scaring may be needed at grain fill',
          'Apply insecticide for head bugs if needed',
          'Watch for ergot and loose smut diseases',
        ],
        'tip': 'Birds can destroy up to 50% of a sorghum crop — plan ahead.',
      },
      {
        'stage': 'Harvest',
        'days': 14,
        'icon': '🏆',
        'tasks': [
          'Harvest when grain is hard and dry',
          'Thresh and dry to 12% moisture for storage',
          'Store in airtight containers to prevent weevils',
        ],
        'tip': 'Sorghum stores better than maize — can last 2+ years if dry.',
      },
    ],
  };

  // ---------------------------------------------------------------------------
  // PEST & DISEASE GUIDE per crop
  // ---------------------------------------------------------------------------
  static const Map<String, List<Map<String, dynamic>>> pestGuide = {
    'Maize': [
      {
        'name': 'Fall Armyworm',
        'type': 'Pest',
        'icon': '🐛',
        'severity': 'High',
        'symptoms':
            'Ragged holes in leaves, frass (excrement) in whorl, damaged growing point.',
        'scouting':
            'Check whorl of 20 random plants. Treat if >20% show fresh feeding damage.',
        'control':
            'Emamectin benzoate, Chlorpyrifos, or Spinetoram. Apply into whorl. Biological: Bacillus thuringiensis.',
        'prevention':
            'Early planting, push-pull intercropping with Desmodium, monitor weekly.',
      },
      {
        'name': 'Stalk Borer',
        'type': 'Pest',
        'icon': '🐛',
        'severity': 'High',
        'symptoms':
            'Deadhearts in young plants, holes in stalk, frass at entry point, broken tassels.',
        'scouting': 'Scout weekly from emergence. Note % plants with deadhearts.',
        'control':
            'Furadan granules at planting, Cypermethrin at 4-6 leaf stage.',
        'prevention': 'Early planting, destroy crop residues after harvest.',
      },
      {
        'name': 'Grey Leaf Spot',
        'type': 'Disease',
        'icon': '🍃',
        'severity': 'Medium',
        'symptoms':
            'Rectangular grey-brown lesions between leaf veins, leaves dry out from bottom up.',
        'scouting': 'Check lower leaves from tasseling onwards.',
        'control': 'Propiconazole, Azoxystrobin fungicide.',
        'prevention': 'Use resistant varieties, crop rotation, avoid dense planting.',
      },
      {
        'name': 'Northern Corn Leaf Blight',
        'type': 'Disease',
        'icon': '🍃',
        'severity': 'Medium',
        'symptoms':
            'Long tan/grey elliptical lesions on leaves, up to 15cm long.',
        'scouting': 'Most common in cool, wet seasons.',
        'control': 'Mancozeb or Propiconazole fungicide.',
        'prevention': 'Resistant varieties, crop rotation.',
      },
      {
        'name': 'Aflatoxin (Aspergillus)',
        'type': 'Disease',
        'icon': '⚠️',
        'severity': 'Very High',
        'symptoms':
            'Yellow-green mold on grain, musty smell, discolored kernels.',
        'scouting': 'Check ears at harvest — especially after drought stress.',
        'control':
            'No chemical control once grain is infected. Discard infected grain.',
        'prevention':
            'Harvest early, dry grain quickly to 12%, store in airtight bags.',
      },
    ],
    'Tomatoes': [
      {
        'name': 'Late Blight',
        'type': 'Disease',
        'icon': '🍃',
        'severity': 'Very High',
        'symptoms':
            'Water-soaked lesions on leaves and stems, white mold in humid conditions, fruit rots.',
        'scouting': 'Check leaves and stems daily in cool, wet weather.',
        'control': 'Mancozeb + Metalaxyl (Ridomil Gold), Chlorothalonil.',
        'prevention': 'Resistant varieties, avoid overhead irrigation, 7-day spray program.',
      },
      {
        'name': 'Bacterial Wilt',
        'type': 'Disease',
        'icon': '🥀',
        'severity': 'Very High',
        'symptoms':
            'Sudden wilting of entire plant, no yellowing. Cut stem shows brown discoloration and bacterial ooze.',
        'scouting':
            'Scout daily — this disease kills plants within days.',
        'control':
            'No effective chemical cure. Remove and destroy affected plants immediately.',
        'prevention':
            'Crop rotation (3 years), grafted plants on resistant rootstock, avoid waterlogging.',
      },
      {
        'name': 'Blossom End Rot',
        'type': 'Disorder',
        'icon': '🍅',
        'severity': 'Medium',
        'symptoms':
            'Dark, sunken patch at blossom end (bottom) of fruit.',
        'scouting': 'Most common in hot, dry conditions or after heavy rain.',
        'control': 'Apply calcium nitrate foliar spray.',
        'prevention': 'Consistent irrigation, mulching, calcium fertilization.',
      },
      {
        'name': 'Whitefly',
        'type': 'Pest',
        'icon': '🦟',
        'severity': 'Medium',
        'symptoms':
            'Tiny white insects under leaves, sticky honeydew, sooty mold, virus transmission.',
        'scouting':
            'Tap plant — whiteflies will fly up. Count adults per leaf.',
        'control': 'Imidacloprid, Thiamethoxam, Yellow sticky traps.',
        'prevention': 'Reflective mulch, remove weeds, avoid over-fertilizing with nitrogen.',
      },
      {
        'name': 'Red Spider Mite',
        'type': 'Pest',
        'icon': '🕷️',
        'severity': 'Medium',
        'symptoms':
            'Fine stippling on leaves, bronze/silver color, fine webbing under leaves.',
        'scouting': 'Use magnifying glass. Most common in hot, dry conditions.',
        'control': 'Abamectin, Spiromesifen, or wettable sulphur.',
        'prevention': 'Maintain adequate irrigation, avoid dust on leaves.',
      },
    ],
    'Cotton': [
      {
        'name': 'American Bollworm',
        'type': 'Pest',
        'icon': '🐛',
        'severity': 'Very High',
        'symptoms':
            'Holes in squares (flower buds), caterpillars inside bolls, damaged bolls dropping.',
        'scouting':
            'Count squares with holes per 100 plants. Treat if >10%.',
        'control': 'Emamectin benzoate, Spinosad, Chlorpyrifos.',
        'prevention': 'Follow recommended spray program, monitor weekly.',
      },
      {
        'name': 'Red Spider Mite',
        'type': 'Pest',
        'icon': '🕷️',
        'severity': 'High',
        'symptoms':
            'Bronze/rusty leaves, leaf fall, plant defoliation in severe infestations.',
        'scouting':
            'Scout regularly, especially in hot dry conditions after rain events.',
        'control': 'Abamectin, Propargite. DO NOT use pyrethroids — causes flare-up.',
        'prevention': 'Avoid dust, maintain plant vigor.',
      },
      {
        'name': 'Cotton Leaf Curl Virus',
        'type': 'Disease',
        'icon': '🍃',
        'severity': 'High',
        'symptoms':
            'Curling and cupping of leaves, dark green veins, stunted growth.',
        'scouting': 'Check for whitefly populations — they spread the virus.',
        'control': 'No cure — remove and destroy affected plants.',
        'prevention': 'Control whitefly, use virus-free planting material, early planting.',
      },
    ],
    'Sorghum': [
      {
        'name': 'Head Bug (Eurystylus)',
        'type': 'Pest',
        'icon': '🐛',
        'severity': 'High',
        'symptoms':
            'Shriveled, chaffy grains, dark staining on grain, incomplete grain fill.',
        'scouting': 'Beat heads over white tray, count bugs. Treat if >2 per head.',
        'control': 'Cypermethrin, Lambda-cyhalothrin spray at heading.',
        'prevention': 'Early planting, use compact-headed varieties.',
      },
      {
        'name': 'Covered Kernel Smut',
        'type': 'Disease',
        'icon': '⚫',
        'severity': 'Medium',
        'symptoms':
            'Grains replaced by black powdery smut masses.',
        'scouting': 'Visible at heading — smutted heads are obvious.',
        'control': 'Seed treatment with Carboxin + Thiram before planting.',
        'prevention': 'Use certified disease-free seed, seed treatment every year.',
      },
    ],
    'Wheat': [
      {
        'name': 'Stem Rust',
        'type': 'Disease',
        'icon': '🍃',
        'severity': 'Very High',
        'symptoms':
            'Orange-red pustules on stems and leaves, weakened stems, lodging.',
        'scouting':
            'Check stems from flag leaf stage. Orange powder on hands confirms presence.',
        'control': 'Propiconazole, Tebuconazole fungicide. Apply immediately.',
        'prevention':
            'Resistant varieties, early planting, fungicide at first sign.',
      },
      {
        'name': 'Yellow Rust',
        'type': 'Disease',
        'icon': '🌿',
        'severity': 'High',
        'symptoms':
            'Yellow stripes of pustules along leaf veins.',
        'scouting': 'Common in cool, moist conditions. Check leaves regularly.',
        'control': 'Propiconazole fungicide, Azoxystrobin.',
        'prevention': 'Resistant varieties, fungicide seed treatment.',
      },
      {
        'name': 'Aphids',
        'type': 'Pest',
        'icon': '🦟',
        'severity': 'Medium',
        'symptoms':
            'Clusters of small insects on leaves and ears, yellowing, sticky honeydew, sooty mold.',
        'scouting': 'Count aphids per tiller. Treat if >10 per tiller during grain fill.',
        'control': 'Pirimicarb (aphid-specific), Dimethoate.',
        'prevention': 'Conserve natural enemies (ladybirds, parasitic wasps).',
      },
    ],
  };

  // ---------------------------------------------------------------------------
  // FERTILIZER RECOMMENDATIONS per crop
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, dynamic>> fertilizerGuide = {
    'Maize': {
      'basal': 'Compound D: 200–300 kg/ha at planting',
      'topdress1': 'Ammonium Nitrate (AN): 150–200 kg/ha at 4–6 leaf stage',
      'topdress2': 'Ammonium Nitrate (AN): 100 kg/ha at 8–10 leaf stage (optional)',
      'note':
          'Split nitrogen applications reduce losses from leaching on sandy soils.',
      'deficiencies': {
        'Nitrogen': 'V-shaped yellowing from leaf tip, starting on older leaves.',
        'Phosphorus': 'Purple/red coloring on leaves and stems in young plants.',
        'Potassium': 'Leaf edge scorch (firing) on older leaves.',
        'Zinc': 'White striping on young leaves near the midrib.',
      },
    },
    'Tomatoes': {
      'basal': 'Compound S: 500 kg/ha at transplanting',
      'topdress1': 'Calcium Ammonium Nitrate: 150 kg/ha at 3 weeks',
      'topdress2': 'NPK 5:18:38 (potassium-rich): from flowering onwards',
      'foliar': 'Calcium nitrate foliar spray weekly to prevent blossom end rot',
      'note': 'Tomatoes are heavy feeders — fertigation (fertilizer via irrigation) gives best results.',
      'deficiencies': {
        'Calcium': 'Blossom end rot, tip burn on young leaves.',
        'Magnesium': 'Interveinal yellowing on older leaves.',
        'Boron': 'Hollow fruit, distorted growing tips.',
      },
    },
    'Cotton': {
      'basal': 'Compound S: 200 kg/ha at planting',
      'topdress1': 'Ammonium Nitrate: 150 kg/ha at 5-leaf stage',
      'topdress2': 'Potassium Sulphate: 50 kg/ha at early flowering',
      'note':
          'Over-fertilizing cotton with nitrogen causes excessive vegetative growth and poor boll set.',
      'deficiencies': {
        'Nitrogen': 'Pale green to yellow leaves, small leaves, early leaf drop.',
        'Potassium': 'Leaf edge browning, premature boll opening.',
      },
    },
    'Wheat': {
      'basal': 'Compound C: 300 kg/ha at planting',
      'topdress1': 'Ammonium Nitrate: 200 kg/ha at tillering (3–4 weeks)',
      'topdress2': 'Ammonium Nitrate: 100 kg/ha at flag leaf stage',
      'note':
          'Wheat requires consistent irrigation with fertilizer for best yields under Zimbabwe conditions.',
      'deficiencies': {
        'Nitrogen': 'Pale, yellow-green plants, reduced tillering.',
        'Sulphur': 'Yellowing of young leaves, reduced protein content.',
      },
    },
    'Sorghum': {
      'basal': 'Compound D: 150–200 kg/ha at planting',
      'topdress1': 'Ammonium Nitrate: 100–150 kg/ha at 4-leaf stage',
      'note':
          'Sorghum is efficient with fertilizer — lower rates than maize give good results.',
      'deficiencies': {
        'Nitrogen': 'Yellowing from older leaves, purple leaf midribs.',
        'Iron': 'Interveinal chlorosis on young leaves (rare, in high-pH soils).',
      },
    },
  };

  // ---------------------------------------------------------------------------
  // GET PLANTING STATUS for current month
  // ---------------------------------------------------------------------------
  static PlantingStatus getPlantingStatus(
      String crop, String region, int currentMonth) {
    final calendar = plantingCalendar[crop];
    if (calendar == null) {
      return PlantingStatus(
        canPlant: false,
        message: 'No planting data available for $crop.',
        bestMonths: [],
      );
    }

    final months = calendar[region] ?? [];
    if (months.isEmpty) {
      return PlantingStatus(
        canPlant: false,
        message:
            '$crop is not recommended for Region $region.',
        bestMonths: [],
      );
    }

    final isNow = months.contains(currentMonth);
    final nextMonth = currentMonth == 12 ? 1 : currentMonth + 1;
    final isSoon = months.contains(nextMonth);

    final monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final bestMonthNames =
        months.map((m) => monthNames[m]).toList();

    if (isNow) {
      return PlantingStatus(
        canPlant: true,
        message:
            '✅ NOW is the right time to plant $crop in Region $region!',
        bestMonths: bestMonthNames,
        urgency: 'now',
      );
    } else if (isSoon) {
      return PlantingStatus(
        canPlant: false,
        message:
            '⏰ Prepare now — planting season for $crop starts next month.',
        bestMonths: bestMonthNames,
        urgency: 'soon',
      );
    } else {
      return PlantingStatus(
        canPlant: false,
        message:
            '📅 Best planting months for $crop: ${bestMonthNames.join(', ')}.',
        bestMonths: bestMonthNames,
        urgency: 'later',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // CALCULATE DAYS SINCE PLANTING & CURRENT STAGE
  // ---------------------------------------------------------------------------
  static CropStageInfo getCurrentStage(
      String crop, DateTime plantingDate) {
    final stages = growthStages[crop];
    if (stages == null) {
      return CropStageInfo(
        stageIndex: 0,
        stageName: 'Growing',
        daysInStage: 0,
        totalDays: 0,
        progressPercent: 0,
        currentTasks: [],
        tip: '',
        icon: '🌱',
      );
    }

    final daysSincePlanting =
        DateTime.now().difference(plantingDate).inDays;

    int cumulativeDays = 0;
    for (int i = 0; i < stages.length; i++) {
      final stageDays = stages[i]['days'] as int;
      cumulativeDays += stageDays;

      if (daysSincePlanting < cumulativeDays) {
        final stageStartDay =
            cumulativeDays - stageDays;
        final daysInThisStage =
            daysSincePlanting - stageStartDay;
        final totalCropDays = stages.fold<int>(
            0, (sum, s) => sum + (s['days'] as int));

        return CropStageInfo(
          stageIndex: i,
          stageName: stages[i]['stage'] as String,
          daysInStage: daysInThisStage,
          totalDays: stageDays,
          progressPercent:
              (daysSincePlanting / totalCropDays * 100)
                  .clamp(0, 100),
          currentTasks:
              List<String>.from(stages[i]['tasks']),
          tip: stages[i]['tip'] as String,
          icon: stages[i]['icon'] as String,
        );
      }
    }

    // Crop has matured
    return CropStageInfo(
      stageIndex: stages.length - 1,
      stageName: 'Completed / Harvested',
      daysInStage: daysSincePlanting,
      totalDays: daysSincePlanting,
      progressPercent: 100,
      currentTasks: [
        'Record your yield',
        'Prepare land for next season',
      ],
      tip: 'Great job completing the season! Record your yield for future planning.',
      icon: '✅',
    );
  }

  // ---------------------------------------------------------------------------
  // GET ESTIMATED HARVEST DATE
  // ---------------------------------------------------------------------------
  static DateTime? getEstimatedHarvestDate(
      String crop, DateTime plantingDate) {
    final stages = growthStages[crop];
    if (stages == null) return null;

    final totalDays = stages.fold<int>(
        0, (sum, s) => sum + (s['days'] as int));
    return plantingDate.add(Duration(days: totalDays));
  }
}

// ---------------------------------------------------------------------------
// DATA CLASSES
// ---------------------------------------------------------------------------
class PlantingStatus {
  final bool canPlant;
  final String message;
  final List<String> bestMonths;
  final String urgency; // 'now', 'soon', 'later'

  const PlantingStatus({
    required this.canPlant,
    required this.message,
    required this.bestMonths,
    this.urgency = 'later',
  });
}

class CropStageInfo {
  final int stageIndex;
  final String stageName;
  final int daysInStage;
  final int totalDays;
  final double progressPercent;
  final List<String> currentTasks;
  final String tip;
  final String icon;

  const CropStageInfo({
    required this.stageIndex,
    required this.stageName,
    required this.daysInStage,
    required this.totalDays,
    required this.progressPercent,
    required this.currentTasks,
    required this.tip,
    required this.icon,
  });
}