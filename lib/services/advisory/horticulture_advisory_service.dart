// lib/services/advisory/horticulture_advisory_service.dart
// Rule-based horticulture intelligence engine.
// Covers irrigation, fertilization, pest control,
// market timing, and post-harvest for Zimbabwe horticulture.

class HorticultureAdvisoryService {
  static final HorticultureAdvisoryService _instance =
      HorticultureAdvisoryService._internal();
  factory HorticultureAdvisoryService() => _instance;
  HorticultureAdvisoryService._internal();

  // ---------------------------------------------------------------------------
  // HORTICULTURE CROPS with categories
  // ---------------------------------------------------------------------------
  static const List<Map<String, String>> hortiCrops = [
    // Vegetables
    {'name': 'Tomatoes',       'icon': '🍅', 'category': 'Fruiting Veg'},
    {'name': 'Butternuts',     'icon': '🎃', 'category': 'Fruiting Veg'},
    {'name': 'Peppers',        'icon': '🫑', 'category': 'Fruiting Veg'},
    {'name': 'Cucumbers',      'icon': '🥒', 'category': 'Fruiting Veg'},
    {'name': 'Watermelons',    'icon': '🍉', 'category': 'Fruiting Veg'},
    {'name': 'Pumpkins',       'icon': '🎃', 'category': 'Fruiting Veg'},
    {'name': 'Brinjals',       'icon': '🍆', 'category': 'Fruiting Veg'},
    // Bulb & Root
    {'name': 'Onions',         'icon': '🧅', 'category': 'Bulb & Root'},
    {'name': 'Garlic',         'icon': '🧄', 'category': 'Bulb & Root'},
    {'name': 'Carrots',        'icon': '🥕', 'category': 'Bulb & Root'},
    {'name': 'Beetroot',       'icon': '🫛', 'category': 'Bulb & Root'},
    {'name': 'Potatoes',       'icon': '🥔', 'category': 'Bulb & Root'},
    {'name': 'Sweet Potatoes', 'icon': '🍠', 'category': 'Bulb & Root'},
    // Leafy Greens
    {'name': 'Cabbages',       'icon': '🥬', 'category': 'Leafy Greens'},
    {'name': 'Rape (Covo)',    'icon': '🥬', 'category': 'Leafy Greens'},
    {'name': 'Spinach',        'icon': '🥬', 'category': 'Leafy Greens'},
    {'name': 'Lettuce',        'icon': '🥗', 'category': 'Leafy Greens'},
    {'name': 'Swiss Chard',    'icon': '🥬', 'category': 'Leafy Greens'},
    {'name': 'Kale',           'icon': '🥬', 'category': 'Leafy Greens'},
    // Legumes
    {'name': 'Sugar Beans',    'icon': '🫘', 'category': 'Legumes'},
    {'name': 'Cowpeas',        'icon': '🫘', 'category': 'Legumes'},
    {'name': 'Garden Peas',    'icon': '🫛', 'category': 'Legumes'},
    {'name': 'Butternuts',     'icon': '🎃', 'category': 'Legumes'},
    // Herbs
    {'name': 'Coriander',      'icon': '🌿', 'category': 'Herbs'},
    {'name': 'Parsley',        'icon': '🌿', 'category': 'Herbs'},
    {'name': 'Chillies',       'icon': '🌶️', 'category': 'Herbs'},
    {'name': 'Mint',           'icon': '🌿', 'category': 'Herbs'},
    // Fruits
    {'name': 'Bananas',        'icon': '🍌', 'category': 'Fruits'},
    {'name': 'Mangoes',        'icon': '🥭', 'category': 'Fruits'},
    {'name': 'Avocados',       'icon': '🥑', 'category': 'Fruits'},
    {'name': 'Citrus',         'icon': '🍊', 'category': 'Fruits'},
    {'name': 'Papaya',         'icon': '🍈', 'category': 'Fruits'},
    {'name': 'Strawberries',   'icon': '🍓', 'category': 'Fruits'},
  ];

  static String getCropIcon(String cropName) {
    return hortiCrops.firstWhere(
      (c) => c['name'] == cropName,
      orElse: () => {'icon': '🌱'},
    )['icon']!;
  }

  // ---------------------------------------------------------------------------
  // GROWTH STAGES per horticultural crop
  // ---------------------------------------------------------------------------
  static const Map<String, List<Map<String, dynamic>>> growthStages = {
    'Tomatoes': [
      {
        'stage': 'Nursery / Seedbed',
        'days': 28,
        'icon': '🌱',
        'tasks': [
          'Fill seed trays with sterilized potting mix (peat:vermiculite 3:1)',
          'Sow 1–2 seeds per cell, 5mm deep',
          'Water twice daily — keep moist but not waterlogged',
          'Apply starter fertilizer (Nitrosol or Peters) at 2-leaf stage',
          'Shade seedlings first 3 days after emergence',
          'Harden off seedlings 7 days before transplanting',
        ],
        'irrigation': 'Twice daily — misting only',
        'tip': 'Healthy 4–5 leaf transplants outperform leggy seedlings significantly.',
      },
      {
        'stage': 'Land Prep & Transplanting',
        'days': 7,
        'icon': '🚜',
        'tasks': [
          'Prepare beds — add compost 5 tonnes/ha',
          'Apply basal fertilizer: Compound S 500kg/ha',
          'Irrigate beds 24 hours before transplanting',
          'Transplant at 4–5 leaf stage, spacing 60cm x 90cm',
          'Water immediately after transplanting',
          'Apply Ridomil Gold drench at transplanting to prevent Pythium',
        ],
        'irrigation': 'Daily for 7 days post-transplant',
        'tip': 'Transplant in the late afternoon or on overcast days to reduce stress.',
      },
      {
        'stage': 'Establishment & Vegetative',
        'days': 21,
        'icon': '🌿',
        'tasks': [
          'Stake plants when 25–30cm tall (indeterminate varieties)',
          'Remove suckers weekly — leave one main stem (single stem)',
          'Apply herbicide between rows or hand weed',
          'Top dress with CAN 150kg/ha at 3 weeks',
          'Scout for aphids, whitefly, and leafminer',
          'Apply insecticide if pest threshold reached',
        ],
        'irrigation': 'Every 2–3 days (keep soil moist)',
        'tip': 'Consistent suckering improves airflow, reduces disease, and boosts yield.',
      },
      {
        'stage': 'Flowering',
        'days': 14,
        'icon': '🌸',
        'tasks': [
          'Apply Calcium Nitrate foliar: 3kg/100L water weekly',
          'Maintain consistent irrigation — fluctuation causes blossom drop',
          'Apply preventive fungicide (Mancozeb) for early blight',
          'Scout for tomato leaf curl virus symptoms',
          'Shake plants gently in morning to aid pollination',
          'Remove lower leaves touching soil',
        ],
        'irrigation': 'Every 2 days — critical not to stress',
        'tip': 'Calcium at flowering is the single best investment to prevent blossom end rot.',
      },
      {
        'stage': 'Fruit Development',
        'days': 21,
        'icon': '🍅',
        'tasks': [
          'Switch to high-K fertilizer: NPK 5:18:38 or SoluPotasse',
          'Maintain Mancozeb + Ridomil spray program every 7 days',
          'Scout for red spider mite (fine webbing under leaves)',
          'Apply Abamectin if spider mite found',
          'Monitor for late blight — treat immediately with Revus or Acrobat',
          'Continue tying and pruning',
        ],
        'irrigation': 'Every 2–3 days — even moisture critical',
        'tip': 'Even soil moisture prevents cracking and blossom end rot.',
      },
      {
        'stage': 'Harvesting',
        'days': 28,
        'icon': '🏆',
        'tasks': [
          'Harvest at breaker (turning pink) for transport to distant markets',
          'Harvest red-ripe for local/farm gate sales',
          'Harvest 2–3x per week — every 2–3 days',
          'Handle carefully to avoid bruising',
          'Grade: A (large, perfect), B (medium), C (small or blemished)',
          'Store at 13–18°C to extend shelf life',
        ],
        'irrigation': 'Reduce slightly to improve flavour and shelf life',
        'tip': 'Harvesting at breaker stage gives 7–10 extra days of shelf life for distant markets.',
      },
    ],
    'Onions': [
      {
        'stage': 'Nursery',
        'days': 42,
        'icon': '🌱',
        'tasks': [
          'Sow seed thickly in nursery rows 15cm apart',
          'Keep moist — onion seed germinates slowly (14–21 days)',
          'Apply Nitrosol at 2-leaf stage',
          'Control damping off with Metalaxyl drench',
          'Seedlings ready when pencil-thick (42–50 days)',
        ],
        'irrigation': 'Daily — keep consistently moist',
        'tip': 'Never let onion nursery dry out — seedlings die within hours.',
      },
      {
        'stage': 'Transplanting',
        'days': 7,
        'icon': '🚜',
        'tasks': [
          'Trim roots and tops to 5cm before transplanting',
          'Space at 10cm x 30cm (33,000 plants/ha)',
          'Plant shallow — bulb forms at soil surface',
          'Firm soil around roots',
          'Water immediately and daily for first week',
        ],
        'irrigation': 'Daily for establishment',
        'tip': 'Shallow planting is critical — deep planting causes elongated, poor bulbs.',
      },
      {
        'stage': 'Vegetative Growth',
        'days': 56,
        'icon': '🌿',
        'tasks': [
          'Weed by hand — onions cannot compete with weeds',
          'Apply CAN top dress 200kg/ha at 3 weeks',
          'Scout for onion thrips (silvery streaks on leaves)',
          'Apply Spinosad or Emamectin for thrips',
          'Control purple blotch with Iprodione fungicide',
        ],
        'irrigation': 'Every 3–4 days — do NOT over-irrigate',
        'tip': 'Thrips are the #1 enemy — scout weekly and treat early.',
      },
      {
        'stage': 'Bulb Formation',
        'days': 28,
        'icon': '🧅',
        'tasks': [
          'STOP nitrogen fertilizer — excess N delays bulbing',
          'Apply Potassium Sulphate 100kg/ha for bulb quality',
          'Reduce irrigation frequency',
          'Control downy mildew with Mancozeb',
          'Remove any plants that have bolted (flowered)',
        ],
        'irrigation': 'Every 5–7 days',
        'tip': 'Stopping nitrogen at bulbing is the single most important management decision.',
      },
      {
        'stage': 'Maturity & Harvest',
        'days': 21,
        'icon': '🏆',
        'tasks': [
          'Stop irrigation when 50% of tops have fallen over',
          'Harvest when 80% of tops are down',
          'Pull carefully and cure in field for 7 days',
          'Clip tops and roots when fully cured',
          'Grade and store in cool, dry, well-ventilated store',
        ],
        'irrigation': 'Stop 2 weeks before harvest',
        'tip': 'Proper curing (sun drying) doubles onion storage life from 2 weeks to 3+ months.',
      },
    ],
    'Cabbages': [
      {
        'stage': 'Nursery',
        'days': 21,
        'icon': '🌱',
        'tasks': [
          'Sow in seed trays or nursery bed',
          'Germination in 5–7 days',
          'Apply starter fertilizer at 2-leaf stage',
          'Control damping off with Metalaxyl drench',
        ],
        'irrigation': 'Twice daily',
        'tip': 'Cabbage seedlings are fast — 21 days to transplant size.',
      },
      {
        'stage': 'Transplanting',
        'days': 7,
        'icon': '🚜',
        'tasks': [
          'Space at 45cm x 60cm (37,000 plants/ha)',
          'Apply basal fertilizer Compound S 500kg/ha',
          'Water daily for 7 days post-transplant',
        ],
        'irrigation': 'Daily',
        'tip': 'Bigger spacing = bigger heads. Do not crowd cabbages.',
      },
      {
        'stage': 'Vegetative & Head Formation',
        'days': 49,
        'icon': '🥬',
        'tasks': [
          'Top dress CAN 200kg/ha at 3 weeks',
          'Control diamondback moth (DBM) with Chlorfenapyr or Spinosad',
          'Scout for aphids under outer leaves',
          'Apply Imidacloprid for aphids',
          'Control black rot with Copper fungicide',
        ],
        'irrigation': 'Every 3–4 days',
        'tip': 'Diamondback moth is resistant to pyrethroids — use Spinosad or Chlorfenapyr.',
      },
      {
        'stage': 'Harvest',
        'days': 7,
        'icon': '🏆',
        'tasks': [
          'Harvest when heads are firm and solid',
          'Cut with sharp knife — leave 3 outer leaves to protect head',
          'Avoid splitting — harvest promptly when mature',
          'Grade by size and quality',
        ],
        'irrigation': 'Reduce — excess water causes splitting',
        'tip': 'Harvest before heads split — split cabbages have zero market value.',
      },
    ],
    'Rape (Covo)': [
      {
        'stage': 'Direct Seeding / Transplant',
        'days': 7,
        'icon': '🌱',
        'tasks': [
          'Can direct-seed at 30cm x 30cm spacing',
          'Or transplant seedlings from nursery at 21 days',
          'Apply Compound S 300kg/ha as basal',
          'Water immediately after planting',
        ],
        'irrigation': 'Daily for first week',
        'tip': 'Rape grows fast — first harvest possible in 45–60 days from transplant.',
      },
      {
        'stage': 'Vegetative Growth',
        'days': 35,
        'icon': '🥬',
        'tasks': [
          'Top dress with CAN 150kg/ha at 3 weeks',
          'Control aphids with Pirimicarb or Imidacloprid',
          'Scout for diamondback moth and club root',
          'Keep well-watered — rapid growth needs consistent moisture',
        ],
        'irrigation': 'Every 2–3 days',
        'tip': 'Leafy greens are high-value but fast-growing — don\'t let them stress for water.',
      },
      {
        'stage': 'Continuous Harvest',
        'days': 60,
        'icon': '🏆',
        'tasks': [
          'Begin leaf harvest when plants are 30–40cm tall',
          'Harvest outer leaves only — leave growing tip',
          'Harvest every 7–10 days for continuous production',
          'Apply CAN 50kg/ha after each harvest',
          'Replace old plants every 3 months',
        ],
        'irrigation': 'Every 2–3 days',
        'tip': 'Cut-and-come-again harvesting gives months of production from one planting.',
      },
    ],
    'Butternuts': [
      {
        'stage': 'Land Prep & Planting',
        'days': 7,
        'icon': '🚜',
        'tasks': [
          'Prepare pits 50cm x 50cm x 30cm, 2m x 2m spacing',
          'Fill pits with compost + Compound S',
          'Plant 3 seeds per pit, thin to 2 plants',
          'Mulch around plants',
        ],
        'irrigation': 'Every 3 days at establishment',
        'tip': 'Butternuts are drought-tolerant but yield best with consistent moisture.',
      },
      {
        'stage': 'Vine Growth',
        'days': 35,
        'icon': '🌿',
        'tasks': [
          'Train vines in one direction',
          'Top dress CAN 100kg/ha at 3 weeks',
          'Scout for cucumber beetle and aphids',
          'Control powdery mildew with Sulphur fungicide',
        ],
        'irrigation': 'Every 4–5 days',
        'tip': 'Powdery mildew reduces fruit quality — start control early.',
      },
      {
        'stage': 'Flowering & Fruit Set',
        'days': 21,
        'icon': '🌸',
        'tasks': [
          'Do NOT spray insecticide — bees needed for pollination',
          'Apply Potassium Sulphate for fruit quality',
          'Hand pollinate in early morning if bee activity is low',
          'Remove weak/malformed fruitlets early',
        ],
        'irrigation': 'Every 4–5 days',
        'tip': 'Bees are essential — do not spray during flowering.',
      },
      {
        'stage': 'Fruit Maturity & Harvest',
        'days': 35,
        'icon': '🎃',
        'tasks': [
          'Harvest when skin is hard and corky (cannot pierce with fingernail)',
          'Stem should be dry and corky',
          'Cut with 5cm of stem attached',
          'Cure in sun for 7 days to harden skin',
          'Store in cool, dry place — can keep 3–6 months',
        ],
        'irrigation': 'Stop 2 weeks before harvest',
        'tip': 'Butternuts stored properly are one of the most profitable horticultural crops in Zimbabwe.',
      },
    ],
    'Spinach': [
      {
        'stage': 'Direct Seeding',
        'days': 7,
        'icon': '🌱',
        'tasks': [
          'Sow direct in rows 30cm apart, thin to 15cm spacing',
          'Germination 7–10 days',
          'Apply Compound S 300kg/ha as basal',
        ],
        'irrigation': 'Daily until germination',
        'tip': 'Spinach prefers cool weather — best planted March–September.',
      },
      {
        'stage': 'Vegetative & Harvest',
        'days': 45,
        'icon': '🥬',
        'tasks': [
          'First harvest at 30–40 days (when leaves are 15–20cm)',
          'Harvest outer leaves or cut whole plant',
          'Top dress CAN 100kg/ha every 3 weeks',
          'Control aphids with Pirimicarb',
          'Watch for downy mildew in wet conditions',
        ],
        'irrigation': 'Every 2–3 days',
        'tip': 'Spinach is one of the fastest, most profitable urban market crops.',
      },
    ],
    'Peppers': [
      {
        'stage': 'Nursery',
        'days': 35,
        'icon': '🌱',
        'tasks': [
          'Sow in seed trays — takes 14–21 days to germinate',
          'Keep warm (above 20°C) for good germination',
          'Apply Nitrosol at 2-leaf stage',
          'Harden off for 7 days before transplanting',
        ],
        'irrigation': 'Twice daily — misting',
        'tip': 'Peppers germinate slowly — be patient and keep warm.',
      },
      {
        'stage': 'Transplanting & Establishment',
        'days': 14,
        'icon': '🚜',
        'tasks': [
          'Transplant at 6-leaf stage, spacing 45cm x 60cm',
          'Apply Compound S 500kg/ha basal',
          'Stake plants as they grow',
          'Water daily for 2 weeks',
        ],
        'irrigation': 'Daily for 2 weeks',
        'tip': 'Peppers need warmth — do not transplant during cold season.',
      },
      {
        'stage': 'Vegetative Growth',
        'days': 28,
        'icon': '🌿',
        'tasks': [
          'Apply CAN 150kg/ha at 3 weeks',
          'Scout for aphids, thrips, and pepper weevil',
          'Remove first flowers to build plant structure',
          'Apply Calcium Nitrate foliar spray',
        ],
        'irrigation': 'Every 2–3 days',
        'tip': 'Removing first flush of flowers increases later yield significantly.',
      },
      {
        'stage': 'Flowering & Fruiting',
        'days': 35,
        'icon': '🌸',
        'tasks': [
          'Switch to high-K fertilizer for fruit quality',
          'Control Phytophthora (crown rot) with Metalaxyl',
          'Scout for pepper moth (borer inside fruit)',
          'Apply Emamectin for fruit borers',
          'Harvest green peppers from 70 days (fresh market)',
          'Allow to turn red for premium price',
        ],
        'irrigation': 'Every 2–3 days — consistent moisture critical',
        'tip': 'Red peppers fetch 2–3x the price of green — if market timing allows, wait.',
      },
    ],
    'Carrots': [
      {
        'stage': 'Direct Seeding',
        'days': 14,
        'icon': '🌱',
        'tasks': [
          'Prepare deep, fine, stone-free seedbed (30cm deep)',
          'Sow thinly in rows 30cm apart',
          'Cover lightly with 3mm fine soil or sand',
          'Keep moist until germination (14–21 days)',
          'Mix seed with sand for even sowing',
        ],
        'irrigation': 'Daily — never let surface dry out before germination',
        'tip': 'Carrot germination is the hardest part — keep surface moist for 2 full weeks.',
      },
      {
        'stage': 'Thinning & Establishment',
        'days': 14,
        'icon': '🌿',
        'tasks': [
          'Thin to 5cm between plants at 3–4 leaf stage',
          'Apply Compound S 200kg/ha (low N — high P)',
          'Weed carefully by hand — do not disturb roots',
          'Scout for carrot fly (maggots in roots)',
        ],
        'irrigation': 'Every 2–3 days',
        'tip': 'Thinning is painful but essential — crowded carrots are small and forked.',
      },
      {
        'stage': 'Root Development',
        'days': 56,
        'icon': '🥕',
        'tasks': [
          'Apply Potassium Sulphate 100kg/ha at 6 weeks',
          'Mound soil around shoulders to prevent greening',
          'Scout for leaf blight (Alternaria) — apply Mancozeb',
          'Maintain even soil moisture — cracks cause forked roots',
        ],
        'irrigation': 'Every 3–4 days — even moisture is key',
        'tip': 'Inconsistent watering is the main cause of forked and cracked roots.',
      },
      {
        'stage': 'Harvest',
        'days': 14,
        'icon': '🏆',
        'tasks': [
          'Harvest at 70–90 days (check shoulder width — target 2–3cm)',
          'Loosen soil with fork before pulling',
          'Twist tops off immediately after harvest',
          'Wash, grade, and bunch for market',
          'Store in cool, humid conditions',
        ],
        'irrigation': 'Reduce before harvest',
        'tip': 'Well-graded, washed carrots in neat bunches command premium prices at supermarkets.',
      },
    ],
    'Potatoes': [
      {
        'stage': 'Seed Preparation',
        'days': 14,
        'icon': '🌱',
        'tasks': [
          'Use certified seed — avoid farm-saved seed (disease risk)',
          'Pre-sprout (chit) seed 14 days before planting in light',
          'Cut large tubers with 1–2 eyes per piece',
          'Dust cuts with sulphur or ash to prevent rotting',
        ],
        'irrigation': 'N/A',
        'tip': 'Certified seed is expensive but prevents 50% yield losses from disease.',
      },
      {
        'stage': 'Planting & Emergence',
        'days': 21,
        'icon': '🚜',
        'tasks': [
          'Plant in rows 75cm apart, 30cm between plants',
          'Plant at 10–12cm depth',
          'Apply Compound S or Compound D 500kg/ha in furrow',
          'Do NOT apply fertilizer directly on seed — burns',
          'Emergence in 14–21 days',
        ],
        'irrigation': 'Every 3–4 days',
        'tip': 'Correct planting depth prevents greening of tubers.',
      },
      {
        'stage': 'Vegetative Growth',
        'days': 28,
        'icon': '🌿',
        'tasks': [
          'Earth up (mound) rows when plants are 25cm tall',
          'Apply CAN 200kg/ha at 3 weeks',
          'Scout for Colorado potato beetle, aphids',
          'Apply Imidacloprid for beetle control',
          'Begin Mancozeb + Metalaxyl spray for late blight (every 7 days)',
        ],
        'irrigation': 'Every 3 days',
        'tip': 'Earthing up is critical — exposed tubers turn green and are poisonous.',
      },
      {
        'stage': 'Tuber Initiation & Bulking',
        'days': 35,
        'icon': '🥔',
        'tasks': [
          'Maintain intensive late blight spray program — every 5–7 days',
          'Apply Potassium Sulphate 100kg/ha for tuber quality',
          'DO NOT damage haulm (foliage) — each leaf feeds tubers',
          'Watch for Phytophthora — act within 24 hours',
        ],
        'irrigation': 'Every 3–4 days — tuber bulking needs even moisture',
        'tip': 'Late blight is the biggest yield thief — maintain spray program religiously.',
      },
      {
        'stage': 'Maturity & Harvest',
        'days': 21,
        'icon': '🏆',
        'tasks': [
          'Cease irrigation 2 weeks before harvest to harden skins',
          'Kill haulm (foliage) with Diquat or Reglone 10 days before harvest',
          'Harvest when skins are firm and set (rub test)',
          'Handle gently — bruising causes storage rot',
          'Cure at 15–20°C for 10 days before storage',
        ],
        'irrigation': 'Stop 2 weeks before harvest',
        'tip': 'Killing haulm 10 days before harvest gives firmer skins and better storage.',
      },
    ],
  };

  // ---------------------------------------------------------------------------
  // IRRIGATION SCHEDULES per crop and season
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, dynamic>> irrigationGuide = {
    'Tomatoes': {
      'method': 'Drip irrigation preferred. Sprinkler acceptable.',
      'weekly_requirement': '25–35mm per week (250–350m³/ha/week)',
      'critical_stages': 'Flowering and fruit development — never stress at these stages',
      'symptoms_of_stress': 'Leaf curl, flower drop, blossom end rot, fruit cracking',
      'symptoms_of_overwatering': 'Yellowing lower leaves, root rot, Pythium damping off',
      'schedule': {
        'summer_rainy': 'Supplement irrigation only — check soil before irrigating',
        'cool_dry': '2–3 times per week — 20mm per irrigation',
        'hot_dry': 'Every 2 days — 25mm per irrigation',
      },
    },
    'Onions': {
      'method': 'Sprinkler or drip. Avoid furrow — bulb diseases increase.',
      'weekly_requirement': '20–25mm per week',
      'critical_stages': 'Bulbing stage — reduce irrigation. Post-harvest: stop completely.',
      'symptoms_of_stress': 'Leaf tip die-back, small bulbs, premature bolting',
      'symptoms_of_overwatering': 'Neck rot, basal plate rot, poor curing',
      'schedule': {
        'summer_rainy': 'Supplement only — over-irrigation causes neck rot',
        'cool_dry': 'Every 4–5 days — 15mm per irrigation',
        'hot_dry': 'Every 3 days — 20mm per irrigation',
      },
    },
    'Cabbages': {
      'method': 'Sprinkler or drip. Overhead sprinkler good for cooling.',
      'weekly_requirement': '25–30mm per week',
      'critical_stages': 'Head formation — consistent moisture prevents splitting',
      'symptoms_of_stress': 'Tip burn on inner leaves, loose heads, bolting',
      'symptoms_of_overwatering': 'Head splitting, black rot spread, club root',
      'schedule': {
        'summer_rainy': 'Supplement only in dry spells',
        'cool_dry': 'Every 3–4 days',
        'hot_dry': 'Every 2–3 days — shade net recommended above 32°C',
      },
    },
    'Potatoes': {
      'method': 'Drip or sprinkler. Consistent even moisture critical.',
      'weekly_requirement': '30–35mm per week during tuber bulking',
      'critical_stages': 'Tuber initiation (6–8 weeks) — water stress here is irreversible',
      'symptoms_of_stress': 'Wilting, hollow heart, cracked tubers',
      'symptoms_of_overwatering': 'Tuber rot, late blight explosion, waterlogging',
      'schedule': {
        'summer_rainy': 'Heavy supplement — rainy season is highest yield window',
        'cool_dry': 'Every 3–4 days — 25mm per irrigation',
        'hot_dry': 'Every 2–3 days — 30mm per irrigation, mulch to retain moisture',
      },
    },
    'Butternuts': {
      'method': 'Drip ideal. Basin irrigation at planting.',
      'weekly_requirement': '15–20mm per week (drought tolerant)',
      'critical_stages': 'Flowering and fruit fill — do not stress',
      'symptoms_of_stress': 'Wilting vines, small fruits, blossom drop',
      'symptoms_of_overwatering': 'Powdery mildew, crown rot, poor fruit set',
      'schedule': {
        'summer_rainy': 'Minimal supplementation needed',
        'cool_dry': 'Every 5–7 days',
        'hot_dry': 'Every 4–5 days',
      },
    },
    'Rape (Covo)': {
      'method': 'Sprinkler or flood. Leafy greens tolerate both.',
      'weekly_requirement': '20–25mm per week',
      'critical_stages': 'Constant moisture for rapid leaf growth',
      'symptoms_of_stress': 'Bolting (flowering prematurely), bitter taste, tough leaves',
      'symptoms_of_overwatering': 'Root rot, club root, yellowing',
      'schedule': {
        'summer_rainy': 'Usually sufficient from rain — supplement in dry spells',
        'cool_dry': 'Every 2–3 days',
        'hot_dry': 'Daily or every 2 days',
      },
    },
    'Spinach': {
      'method': 'Sprinkler or drip. Keep leaves clean.',
      'weekly_requirement': '20mm per week',
      'critical_stages': 'Consistent moisture for quality leaves — stress causes bitterness',
      'symptoms_of_stress': 'Bolting, bitter leaves, yellowing',
      'symptoms_of_overwatering': 'Root rot, downy mildew',
      'schedule': {
        'summer_rainy': 'Supplement in dry spells',
        'cool_dry': 'Every 2–3 days',
        'hot_dry': 'Every 1–2 days',
      },
    },
    'Carrots': {
      'method': 'Sprinkler preferred — keeps surface moist for germination.',
      'weekly_requirement': '20–25mm per week',
      'critical_stages': 'Germination (daily until sprouted), root development',
      'symptoms_of_stress': 'Forked roots, cracks, premature flowering',
      'symptoms_of_overwatering': 'Root rot, excessive top growth, forking',
      'schedule': {
        'summer_rainy': 'Supplement only — over-irrigation causes forking',
        'cool_dry': 'Every 3–4 days',
        'hot_dry': 'Every 2–3 days',
      },
    },
  };

  // ---------------------------------------------------------------------------
  // MARKET PRICE GUIDE
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, dynamic>> marketGuide = {
    'Tomatoes': {
      'peak_price_months': [5, 6, 7, 8],
      'low_price_months': [1, 2, 12],
      'peak_price_usd': '15–25 per 10kg box',
      'low_price_usd': '3–8 per 10kg box',
      'best_markets': ['Mbare Musika', 'OK/TM Supermarkets', 'Hotels & restaurants', 'Direct to householders'],
      'grading': 'Grade A: >80g, perfect. Grade B: 50–80g. Grade C: <50g or blemished',
      'packaging': '10kg cardboard boxes for commercial. Buckets for informal.',
      'tip': 'Plant to harvest in May–August for peak prices. Avoid Dec–Feb glut.',
      'shelf_life': '7–10 days at room temp. 3–4 weeks at 13°C.',
      'profitability': 'Very High — 1ha can yield 40–60 tonnes. Profit \$8,000–15,000/ha/season.',
    },
    'Onions': {
      'peak_price_months': [10, 11, 12, 1],
      'low_price_months': [4, 5, 6],
      'peak_price_usd': '0.80–1.50 per kg',
      'low_price_usd': '0.20–0.50 per kg',
      'best_markets': ['Mbare Musika', 'Supermarkets', 'Hotels', 'Export to DRC/Zambia'],
      'grading': 'Large (>70mm), Medium (50–70mm), Small (<50mm)',
      'packaging': '25kg mesh bags or open weave bags for air circulation',
      'tip': 'Store well-cured onions for 3–4 months and sell in the October–December high-price window.',
      'shelf_life': 'Well-cured: 3–6 months in cool, dry, ventilated store.',
      'profitability': 'High — 15–25 tonnes/ha possible. Profit \$4,000–10,000/ha.',
    },
    'Cabbages': {
      'peak_price_months': [7, 8, 9, 10],
      'low_price_months': [1, 2, 3],
      'peak_price_usd': '0.50–1.20 per head',
      'low_price_usd': '0.15–0.40 per head',
      'best_markets': ['Mbare Musika', 'Local markets', 'Tuck shops', 'Schools'],
      'grading': 'Large (>2kg), Medium (1–2kg), Small (<1kg)',
      'packaging': 'Loose in truck or plastic bags for retail',
      'tip': 'Cabbage prices collapse during rainy season. Plant for July–October harvest.',
      'shelf_life': '2–4 weeks at room temperature. 8 weeks in cold storage.',
      'profitability': 'Medium — high volume, lower margins. Good for cash flow.',
    },
    'Butternuts': {
      'peak_price_months': [4, 5, 6, 7, 8],
      'low_price_months': [1, 2, 3],
      'peak_price_usd': '0.60–1.20 per kg',
      'low_price_usd': '0.20–0.40 per kg',
      'best_markets': ['Supermarkets', 'Mbare', 'Hotels', 'Export'],
      'grading': '1.5–3kg is ideal supermarket size',
      'packaging': '15kg boxes or loose in truck',
      'tip': 'Butternuts store 3–6 months — plant rainy season and sell in dry season premium.',
      'shelf_life': '3–6 months in cool, dry store.',
      'profitability': 'High — low input cost, stores well. One of best cash crops.',
    },
    'Rape (Covo)': {
      'peak_price_months': [5, 6, 7, 8, 9],
      'low_price_months': [1, 2, 12],
      'peak_price_usd': '0.30–0.80 per bunch',
      'low_price_usd': '0.10–0.25 per bunch',
      'best_markets': ['Local markets', 'Tuck shops', 'Roadside', 'Direct to households'],
      'grading': 'Bunch size consistency — 250–500g bunches',
      'packaging': 'Tied in bunches, wet for freshness',
      'tip': 'Rape is the most consumed leafy green in Zimbabwe — consistent demand year round.',
      'shelf_life': '2–3 days at room temp. 7 days refrigerated.',
      'profitability': 'Medium-High — fast turnover, low inputs, multiple harvests.',
    },
    'Spinach': {
      'peak_price_months': [5, 6, 7, 8],
      'low_price_months': [11, 12, 1, 2],
      'peak_price_usd': '0.50–1.00 per bunch',
      'low_price_usd': '0.15–0.30 per bunch',
      'best_markets': ['Supermarkets', 'Hotels', 'Urban markets', 'Tuck shops'],
      'grading': 'Dark green, large leaves, no yellowing',
      'packaging': 'Bunches 250–300g, with rubber band. Keep wet.',
      'tip': 'Spinach at supermarkets commands 3x the price of informal market.',
      'shelf_life': '2–3 days at room temp. Keep wet.',
      'profitability': 'High per m² — excellent for small urban plots.',
    },
    'Potatoes': {
      'peak_price_months': [9, 10, 11],
      'low_price_months': [3, 4, 5],
      'peak_price_usd': '0.60–1.00 per kg',
      'low_price_usd': '0.20–0.35 per kg',
      'best_markets': ['Supermarkets', 'Fast food (chips)', 'Mbare', 'Hotels'],
      'grading': 'Large (>75mm), Medium (55–75mm), Small (<55mm)',
      'packaging': '10kg, 25kg, or 50kg bags depending on market',
      'tip': 'Pre-pack 2kg supermarket bags — 40% price premium over bulk sales.',
      'shelf_life': '4–8 weeks in cool, dark store. 6+ months in cold storage.',
      'profitability': 'High — 25–40 tonnes/ha possible. High input cost but high return.',
    },
    'Carrots': {
      'peak_price_months': [6, 7, 8, 9, 10],
      'low_price_months': [1, 2, 3],
      'peak_price_usd': '0.60–1.20 per kg',
      'low_price_usd': '0.20–0.40 per kg',
      'best_markets': ['Supermarkets', 'Hotels', 'Juicing companies', 'Urban markets'],
      'grading': 'Supermarket: 15–20cm, smooth, 100–200g. Informal: any size.',
      'packaging': '500g, 1kg pre-packs for supermarkets. 10kg bags bulk.',
      'tip': 'Supermarket-graded, pre-packed carrots earn 3x bulk price. Invest in grading.',
      'shelf_life': '3–4 weeks at room temp. 3 months refrigerated.',
      'profitability': 'High — good yields (25–40t/ha) and good market.',
    },
    'Peppers': {
      'peak_price_months': [4, 5, 6, 7, 8, 9],
      'low_price_months': [12, 1, 2],
      'peak_price_usd': '2.00–5.00 per kg (red/yellow) | 1.00–2.50 (green)',
      'low_price_usd': '0.50–1.00 per kg',
      'best_markets': ['Supermarkets', 'Hotels', 'Fast food chains', 'Export'],
      'grading': 'Uniform size and colour. No blemishes for supermarket.',
      'packaging': '250g, 500g punnets for supermarkets. Loose for informal.',
      'tip': 'Coloured peppers (red, yellow, orange) earn 2–3x green pepper price.',
      'shelf_life': '7–14 days at room temp. 3–4 weeks refrigerated.',
      'profitability': 'Very High — highest value per kg of any common vegetable.',
    },
  };

  // ---------------------------------------------------------------------------
  // GET CURRENT GROWTH STAGE for a plot
  // ---------------------------------------------------------------------------
  static PlotStageInfo getCurrentStage(
      String cropName, DateTime plantingDate) {
    final stages = growthStages[cropName];
    if (stages == null) {
      return PlotStageInfo(
        stageIndex: 0,
        stageName: 'Growing',
        progressPercent: 0,
        currentTasks: [],
        irrigationFrequency: 'Every 2–3 days',
        tip: '',
        icon: '🌱',
        daysInStage: 0,
        totalStageDays: 0,
      );
    }

    final daysSince =
        DateTime.now().difference(plantingDate).inDays;
    int cumDays = 0;
    for (int i = 0; i < stages.length; i++) {
      final stageDays = stages[i]['days'] as int;
      cumDays += stageDays;
      if (daysSince < cumDays) {
        final stageStart = cumDays - stageDays;
        final totalDays = stages.fold<int>(
            0, (s, st) => s + (st['days'] as int));
        return PlotStageInfo(
          stageIndex: i,
          stageName: stages[i]['stage'] as String,
          progressPercent:
              (daysSince / totalDays * 100).clamp(0, 100),
          currentTasks:
              List<String>.from(stages[i]['tasks']),
          irrigationFrequency:
              stages[i]['irrigation'] as String? ??
                  'Every 2–3 days',
          tip: stages[i]['tip'] as String,
          icon: stages[i]['icon'] as String,
          daysInStage: daysSince - stageStart,
          totalStageDays: stageDays,
        );
      }
    }

    return PlotStageInfo(
      stageIndex: stages.length - 1,
      stageName: 'Completed / Ready to Harvest',
      progressPercent: 100,
      currentTasks: ['Harvest your crop!', 'Record your yield'],
      irrigationFrequency: 'Reduce or stop',
      tip: 'Crop has reached full maturity. Harvest promptly to avoid quality losses.',
      icon: '✅',
      daysInStage: daysSince,
      totalStageDays: daysSince,
    );
  }

  // ---------------------------------------------------------------------------
  // GET ESTIMATED HARVEST DATE
  // ---------------------------------------------------------------------------
  static DateTime? getEstimatedHarvest(
      String cropName, DateTime plantingDate) {
    final stages = growthStages[cropName];
    if (stages == null) return null;
    final totalDays = stages.fold<int>(
        0, (s, st) => s + (st['days'] as int));
    return plantingDate.add(Duration(days: totalDays));
  }

  // ---------------------------------------------------------------------------
  // MARKET TIMING ADVICE
  // ---------------------------------------------------------------------------
  static MarketTimingInfo getMarketTiming(
      String cropName, DateTime? harvestDate) {
    final market = marketGuide[cropName];
    if (market == null) {
      return MarketTimingInfo(
        isPeakMonth: false,
        advice: 'Check local market prices before harvesting.',
        peakMonths: [],
        priceRange: 'Check local market',
      );
    }

    final targetMonth = harvestDate?.month ??
        DateTime.now().month;
    final peakMonths =
        List<int>.from(market['peak_price_months'] as List);
    final lowMonths =
        List<int>.from(market['low_price_months'] as List);
    final isPeak = peakMonths.contains(targetMonth);
    final isLow = lowMonths.contains(targetMonth);

    const monthNames = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final peakMonthNames =
        peakMonths.map((m) => monthNames[m]).toList();

    String advice;
    if (isPeak) {
      advice =
          '✅ Great timing! ${harvestDate != null ? 'Your harvest month is' : 'This month is'} a peak price period for $cropName.';
    } else if (isLow) {
      advice =
          '⚠️ Low price season for $cropName. Consider: (1) Store and sell later, (2) Find direct buyers, (3) Add value through processing.';
    } else {
      advice =
          '🟡 Moderate prices for $cropName now. Peak months are: ${peakMonthNames.join(', ')}.';
    }

    return MarketTimingInfo(
      isPeakMonth: isPeak,
      advice: advice,
      peakMonths: peakMonthNames,
      priceRange: isPeak
          ? market['peak_price_usd'].toString()
          : market['low_price_usd'].toString(),
      bestMarkets:
          List<String>.from(market['best_markets'] as List),
      profitability:
          market['profitability']?.toString(),
    );
  }
}

// ---------------------------------------------------------------------------
// DATA CLASSES
// ---------------------------------------------------------------------------
class PlotStageInfo {
  final int stageIndex;
  final String stageName;
  final double progressPercent;
  final List<String> currentTasks;
  final String irrigationFrequency;
  final String tip;
  final String icon;
  final int daysInStage;
  final int totalStageDays;

  const PlotStageInfo({
    required this.stageIndex,
    required this.stageName,
    required this.progressPercent,
    required this.currentTasks,
    required this.irrigationFrequency,
    required this.tip,
    required this.icon,
    required this.daysInStage,
    required this.totalStageDays,
  });
}

class MarketTimingInfo {
  final bool isPeakMonth;
  final String advice;
  final List<String> peakMonths;
  final String priceRange;
  final List<String>? bestMarkets;
  final String? profitability;

  const MarketTimingInfo({
    required this.isPeakMonth,
    required this.advice,
    required this.peakMonths,
    required this.priceRange,
    this.bestMarkets,
    this.profitability,
  });
}