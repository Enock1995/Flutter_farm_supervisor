// lib/constants/zimbabwe_districts.dart
// Complete mapping of all Zimbabwean districts to their agro-ecological regions.
// Region I   = Specialized farming (coffee, tea, timber, dairy)
// Region IIa = Intensive farming - higher rainfall
// Region IIb = Intensive farming - moderate rainfall
// Region III = Semi-intensive (drought-resistant crops, some livestock)
// Region IV  = Semi-extensive (ranching, drought-tolerant crops)
// Region V   = Extensive farming (game, cattle, very dry)

class ZimbabweDistricts {
  // ---------------------------------------------------------------------------
  // MASTER DISTRICT → REGION MAP
  // Key: district name (lowercase, trimmed) for easy matching
  // Value: AgroRegion enum value
  // ---------------------------------------------------------------------------
  static const Map<String, String> districtToRegion = {
    // ── REGION I ──────────────────────────────────────────────────────────────
    'nyanga':         'I',
    'mutasa':         'I',
    'chimanimani':    'I',

    // ── REGION IIa ────────────────────────────────────────────────────────────
    'harare':         'IIa',
    'chitungwiza':    'IIa',
    'mazowe':         'IIa',
    'goromonzi':      'IIa',
    'murewa':         'IIa',
    'marondera':      'IIa',
    'wedza':          'IIa',
    'UMP':            'IIa', // UMP = Umzingwane (common abbreviation)
    'kwekwe':         'IIa',
    'gweru':          'IIa',
    'shurugwi':       'IIa',
    'zvishavane':     'IIa',
    'chegutu':        'IIa',
    'kadoma':         'IIa',
    'hurungwe':       'IIa',
    'karoi':          'IIa',

    // ── REGION IIb ────────────────────────────────────────────────────────────
    'bindura':        'IIb',
    'shamva':         'IIb',
    'mount darwin':   'IIb',
    'centenary':      'IIb',
    'guruve':         'IIb',
    'makonde':        'IIb',
    'zvimba':         'IIb',
    'chinhoyi':       'IIb',
    'chikomba':       'IIb',
    'seke':           'IIb',
    'buhera':         'IIb',
    'mutare':         'IIb',
    'makoni':         'IIb',
    'nyazura':        'IIb',
    'rusape':         'IIb',
    'chipinge':       'IIb',
    'bikita':         'IIb',
    'gutu':           'IIb',
    'masvingo':       'IIb',
    'chivi':          'IIb',
    'zaka':           'IIb',
    'bulawayo':       'IIb',
    'umguza':         'IIb',
    'umzingwane':     'IIb',
    'insiza':         'IIb',

    // ── REGION III ────────────────────────────────────────────────────────────
    'gokwe north':    'III',
    'gokwe south':    'III',
    'nkayi':          'III',
    'lupane':         'III',
    'hwange':         'III',
    'binga':          'III',
    'kariba':         'III',
    'nyaminyami':     'III',
    'mberengwa':      'III',
    'midlands':       'III',

    // ── REGION IV ─────────────────────────────────────────────────────────────
    'umzingwane south': 'IV',
    'beitbridge':     'IV',
    'gwanda':         'IV',
    'mangwe':         'IV',
    'matobo':         'IV',
    'plumtree':       'IV',
    'bulilima':       'IV',
    'tsholotsho':     'IV',
    'nyanga north':   'IV',
    'muzarabani':     'IV',
    'mbire':          'IV',
    'rushinga':       'IV',
    'mudzi':          'IV',
    'mutoko':         'IV',
    'uzumba maramba pfungwe': 'IV',
    'UMP district':   'IV',
    'chirundu':       'IV',

    // ── REGION V ──────────────────────────────────────────────────────────────
    'chiredzi':       'V',
    'mwenezi':        'V',
    'nuanetsi':       'V',
    'gokwe':          'V',
    'hwange national': 'V',
  };

  // ---------------------------------------------------------------------------
  // PROVINCE → DISTRICTS lookup (for validation UI hints)
  // ---------------------------------------------------------------------------
  static const Map<String, List<String>> provinceDistricts = {
    'Manicaland': [
      'Buhera', 'Chimanimani', 'Chipinge', 'Makoni',
      'Mutare', 'Mutasa', 'Nyanga',
    ],
    'Mashonaland Central': [
      'Bindura', 'Centenary', 'Guruve', 'Mazowe',
      'Mount Darwin', 'Muzarabani', 'Rushinga', 'Shamva',
    ],
    'Mashonaland East': [
      'Chikomba', 'Goromonzi', 'Hwedza', 'Marondera',
      'Mudzi', 'Murehwa', 'Mutoko', 'Seke',
      'UMP', 'Uzumba Maramba Pfungwe',
    ],
    'Mashonaland West': [
      'Chegutu', 'Chinhoyi', 'Hurungwe', 'Kadoma',
      'Kariba', 'Makonde', 'Nyaminyami', 'Zvimba',
    ],
    'Matabeleland North': [
      'Binga', 'Hwange', 'Lupane', 'Nkayi',
      'Tsholotsho', 'Umguza',
    ],
    'Matabeleland South': [
      'Beitbridge', 'Bulilima', 'Gwanda', 'Insiza',
      'Mangwe', 'Matobo', 'Umzingwane',
    ],
    'Midlands': [
      'Chirumhanzu', 'Gokwe North', 'Gokwe South', 'Gweru',
      'Kwekwe', 'Mberengwa', 'Shurugwi', 'Zvishavane',
    ],
    'Masvingo': [
      'Bikita', 'Chiredzi', 'Chivi', 'Gutu',
      'Masvingo', 'Mwenezi', 'Zaka',
    ],
    'Harare': ['Harare', 'Chitungwiza'],
    'Bulawayo': ['Bulawayo'],
  };

  // ---------------------------------------------------------------------------
  // Flat list of all official district names (for validation)
  // ---------------------------------------------------------------------------
  static List<String> get allOfficialDistricts {
    final districts = <String>[];
    for (final list in provinceDistricts.values) {
      districts.addAll(list);
    }
    return districts..sort();
  }

  // ---------------------------------------------------------------------------
  // LOOKUP: given a district name, return its region code
  // Returns null if not found
  // ---------------------------------------------------------------------------
  static String? getRegion(String districtName) {
    final key = districtName.trim().toLowerCase();
    return districtToRegion[key];
  }

  // ---------------------------------------------------------------------------
  // DISTRICT CODE: 3-letter code used in User_ID generation
  // e.g. "Harare" → "HAR", "Mberengwa" → "MBE"
  // ---------------------------------------------------------------------------
  static String getDistrictCode(String districtName) {
    final cleaned = districtName.trim();
    if (cleaned.length >= 3) {
      return cleaned.substring(0, 3).toUpperCase();
    }
    return cleaned.toUpperCase().padRight(3, 'X');
  }

  // ---------------------------------------------------------------------------
  // REGION DESCRIPTIONS
  // ---------------------------------------------------------------------------
  static const Map<String, String> regionDescriptions = {
    'I':   'Specialized Farming Region — High rainfall (>1000mm). Suited for coffee, tea, fruit orchards, timber, and dairy.',
    'IIa': 'Intensive Farming Region A — High to moderate rainfall (750–1000mm). Prime maize, tobacco, wheat, soybeans.',
    'IIb': 'Intensive Farming Region B — Moderate rainfall (650–800mm). Maize, tobacco, cotton, groundnuts.',
    'III': 'Semi-Intensive Region — Erratic rainfall (500–700mm). Drought-resistant crops, sorghum, millet, cotton, livestock.',
    'IV':  'Semi-Extensive Region — Low rainfall (400–600mm). Ranching, cattle, drought-tolerant crops, sorghum.',
    'V':   'Extensive Farming Region — Very low rainfall (<400mm). Cattle ranching, game farming, minimal cropping.',
  };

  // ---------------------------------------------------------------------------
  // REGION CROPS: recommended crops per region
  // ---------------------------------------------------------------------------
  static const Map<String, List<String>> regionCrops = {
    'I':   ['Coffee', 'Tea', 'Macadamia Nuts', 'Apples', 'Pears', 'Potatoes', 'Wheat', 'Barley'],
    'IIa': ['Maize', 'Tobacco', 'Wheat', 'Soybeans', 'Sunflower', 'Groundnuts', 'Vegetables'],
    'IIb': ['Maize', 'Tobacco', 'Cotton', 'Groundnuts', 'Sunflower', 'Sugar Beans', 'Sorghum'],
    'III': ['Sorghum', 'Millet', 'Cotton', 'Groundnuts', 'Sunflower', 'Cowpeas', 'Maize (early)'],
    'IV':  ['Sorghum', 'Millet', 'Cowpeas', 'Watermelons', 'Cattle Fodder', 'Sesame'],
    'V':   ['Sorghum', 'Millet', 'Cowpeas', 'Sesame', 'Game Crops'],
  };

  // ---------------------------------------------------------------------------
  // REGION LIVESTOCK: suitable livestock per region
  // ---------------------------------------------------------------------------
  static const Map<String, List<String>> regionLivestock = {
    'I':   ['Dairy Cattle', 'Pigs', 'Poultry', 'Trout (aquaculture)'],
    'IIa': ['Beef Cattle', 'Dairy Cattle', 'Pigs', 'Poultry', 'Goats'],
    'IIb': ['Beef Cattle', 'Pigs', 'Poultry', 'Goats', 'Sheep'],
    'III': ['Beef Cattle', 'Goats', 'Sheep', 'Donkeys', 'Poultry'],
    'IV':  ['Beef Cattle', 'Goats', 'Donkeys', 'Sheep'],
    'V':   ['Beef Cattle', 'Game Animals', 'Goats', 'Donkeys'],
  };
}