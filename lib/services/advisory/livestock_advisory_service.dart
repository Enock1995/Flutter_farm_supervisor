// lib/services/advisory/livestock_advisory_service.dart
// Rule-based livestock intelligence engine.
// Covers feeding, health, breeding, disease alerts per animal type.

class LivestockAdvisoryService {
  static final LivestockAdvisoryService _instance =
      LivestockAdvisoryService._internal();
  factory LivestockAdvisoryService() => _instance;
  LivestockAdvisoryService._internal();

  // ---------------------------------------------------------------------------
  // ANIMAL TYPES with icons and categories
  // ---------------------------------------------------------------------------
  static const List<Map<String, String>> animalTypes = [
    {'name': 'Beef Cattle',     'icon': '🐄', 'category': 'Cattle'},
    {'name': 'Dairy Cattle',    'icon': '🐄', 'category': 'Cattle'},
    {'name': 'Goats',           'icon': '🐐', 'category': 'Small Stock'},
    {'name': 'Sheep',           'icon': '🐑', 'category': 'Small Stock'},
    {'name': 'Pigs',            'icon': '🐷', 'category': 'Pigs'},
    {'name': 'Broiler Chickens','icon': '🐔', 'category': 'Poultry'},
    {'name': 'Layer Chickens',  'icon': '🐔', 'category': 'Poultry'},
    {'name': 'Ducks',           'icon': '🦆', 'category': 'Poultry'},
    {'name': 'Turkeys',         'icon': '🦃', 'category': 'Poultry'},
    {'name': 'Rabbits',         'icon': '🐇', 'category': 'Rabbits'},
    {'name': 'Donkeys',         'icon': '🫏', 'category': 'Draft Animals'},
    {'name': 'Horses',          'icon': '🐎', 'category': 'Draft Animals'},
    {'name': 'Fish (Aquaculture)','icon':'🐟', 'category': 'Aquaculture'},
  ];

  static String getIcon(String animalType) {
    return animalTypes.firstWhere(
      (a) => a['name'] == animalType,
      orElse: () => {'icon': '🐾'},
    )['icon']!;
  }

  // ---------------------------------------------------------------------------
  // FEEDING GUIDES per animal type
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, dynamic>> feedingGuide = {
    'Beef Cattle': {
      'daily_feed': 'Dry matter intake: 2–3% of body weight per day',
      'roughage': 'Pasture grass, hay, silage, crop residues (maize stover)',
      'concentrate': 'Protein-energy supplement during dry season or finishing',
      'water': '30–50 litres per animal per day (more in heat)',
      'minerals': 'Salt lick and mineral block always available',
      'seasonal_tips': {
        'dry_season': 'Supplement with protein lick (e.g. 1kg cotton seed cake/day). Feed urea-treated stover. Provide hay or silage.',
        'rainy_season': 'Good pasture usually sufficient. Check for bloat if grazing lush legume pastures.',
        'finishing': 'Add 2–3 kg/day of concentrate (maize + cotton seed cake) for 60–90 days before sale.',
      },
      'body_condition': {
        'ideal_score': '3–3.5 out of 5',
        'thin_action': 'Increase supplementary feeding, treat for parasites, check for disease.',
        'fat_action': 'Reduce concentrate, sell earlier.',
      },
    },
    'Dairy Cattle': {
      'daily_feed': '3–4% of body weight in dry matter. High producers need more.',
      'roughage': 'High quality pasture, hay, silage — minimum 40% of diet',
      'concentrate': '1 kg dairy meal per 2–3 litres of milk produced above maintenance',
      'water': '50–100 litres per day — more in hot weather. Water affects milk production directly.',
      'minerals': 'Dairy-specific mineral supplement. Calcium critical to prevent milk fever.',
      'seasonal_tips': {
        'dry_season': 'Maintain body condition score 3–3.5. Dry cow feeding is critical for next lactation.',
        'rainy_season': 'Watch for grass staggers (hypomagnesaemia) on lush pasture. Supplement with magnesium.',
        'peak_lactation': 'First 100 days — prioritize energy. Feed concentrate 3x daily if possible.',
      },
      'production_targets': {
        'zebu_crossbred': '5–10 litres/day',
        'grade_dairy': '15–25 litres/day',
        'record': 'Keep daily milk records to detect health issues early.',
      },
    },
    'Goats': {
      'daily_feed': '3–5% of body weight. Browsers — prefer shrubs and weeds over grass.',
      'roughage': 'Browse (leaves, shrubs), hay, crop residues. Goats do well on low-quality feed.',
      'concentrate': '200–500g/day for pregnant/lactating does and growing kids',
      'water': '3–6 litres per day. Goats are relatively drought tolerant.',
      'minerals': 'Salt lick essential. Copper supplement needed (avoid sheep mineral — too much copper for goats is fine, too little is bad).',
      'seasonal_tips': {
        'dry_season': 'Supplement with protein lick or cottonseed cake. Feed crop residues.',
        'rainy_season': 'Good pasture — watch for internal parasites (barber pole worm especially).',
        'kidding': 'Increase feed 6 weeks before kidding (steaming up). Doe needs 150% of maintenance.',
      },
    },
    'Sheep': {
      'daily_feed': '2–4% of body weight. Grazers — prefer short, leafy grass.',
      'roughage': 'Pasture, hay, silage, crop residues',
      'concentrate': '200–400g/day for pregnant/lactating ewes and lambs',
      'water': '3–5 litres per day',
      'minerals': 'Salt lick. Selenium deficiency common in Zimbabwe — supplement if white muscle disease seen.',
      'seasonal_tips': {
        'dry_season': 'Protein lick essential. Thin ewes abort or produce weak lambs.',
        'rainy_season': 'Watch for footrot in wet conditions. Check hooves monthly.',
        'lambing': 'Increase feed (steaming up) 6 weeks pre-lambing. Shelter lambs from cold nights.',
      },
    },
    'Pigs': {
      'daily_feed': 'Growing pigs: 2–3 kg/day. Sows: 2–3 kg/day (3–4 kg lactating).',
      'feed_types': 'Starter (0–8 weeks), Grower (8–16 weeks), Finisher (16 weeks to market)',
      'homemade_ration': 'Maize 65% + Soya meal 20% + Fish meal 5% + Wheat bran 8% + Mineral mix 2%',
      'water': '5–10 litres/day. Lactating sows need up to 20 litres.',
      'feeding_tips': 'Feed twice daily at fixed times. Remove uneaten feed. Do NOT feed raw meat/kitchen waste with meat — disease risk.',
      'seasonal_tips': {
        'hot_weather': 'Reduce feed by 10–15%. Ensure plenty of fresh water and shade.',
        'cold_weather': 'Increase feed — pigs burn energy to keep warm.',
        'lactation': 'Sow needs up to 3x maintenance feed when nursing large litter.',
      },
    },
    'Broiler Chickens': {
      'daily_feed': 'Ad libitum (always available). Broilers eat 3–5 kg feed over 6 weeks.',
      'feed_program': 'Starter crumbles (day 1–14) → Grower pellets (day 15–28) → Finisher pellets (day 29–market)',
      'water': '2x feed intake in litres. Water must always be clean and fresh.',
      'feed_conversion': 'Target FCR: 1.6–1.8 kg feed per kg weight gain. Record feed used weekly.',
      'management': 'Maintain litter quality. Wet litter causes breast blisters and respiratory disease.',
      'seasonal_tips': {
        'hot_weather': 'Feed in cool hours (early morning, evening). Increase ventilation. Mortality increases above 35°C.',
        'cold_weather': 'Brood chicks at 32–35°C first week. Reduce brooder temp by 3°C per week.',
      },
    },
    'Layer Chickens': {
      'daily_feed': '110–120g layer mash per bird per day',
      'feed_program': 'Chick starter (0–8 weeks) → Grower (8–18 weeks) → Layer mash (18 weeks to end of lay)',
      'water': 'Always available. Water restriction reduces egg production immediately.',
      'production_target': 'Target 70–80% production rate (70–80 eggs per 100 birds per day).',
      'lighting': 'Maintain 16 hours light per day to sustain lay. Use artificial light in winter.',
      'minerals': 'Layer mash must contain adequate calcium. Limestone grit can supplement.',
      'seasonal_tips': {
        'hot_weather': 'Egg production drops above 30°C. Increase ventilation, reduce stocking density.',
        'moulting': 'Birds stop laying during moult. Induce moult by feed/water restriction for 5–7 days then resume.',
      },
    },
    'Rabbits': {
      'daily_feed': 'Pellets: 100–150g/day for adults. Plus unlimited grass hay.',
      'feed_types': 'Commercial pellets + fresh greens + hay. Avoid wet/wilted grass.',
      'water': '200–600ml/day. Water need doubles in lactation.',
      'breeding_diet': 'Increase pellets to 200g/day for pregnant/lactating does.',
      'greens': 'Kikuyu grass, lucerne, sweet potato leaves, banana leaves. Introduce slowly.',
      'avoid': 'Iceberg lettuce, avocado, potato leaves (toxic). Never feed moldy feed.',
    },
    'Fish (Aquaculture)': {
      'daily_feed': 'Feed 3–5% of fish body weight per day. Adjust monthly as fish grow.',
      'feed_times': 'Feed 2–3 times daily at fixed times. Remove uneaten feed after 30 minutes.',
      'feed_types': 'Starter crumbles (fry) → Fingerling feed → Grower pellets → Finisher',
      'water_quality': 'Check DO (dissolved oxygen >5mg/L), pH 6.5–8.5, ammonia <0.5mg/L weekly.',
      'stocking': 'Tilapia: 3–5 fish/m². Catfish: 10–20 fish/m² in intensive systems.',
      'seasonal_tips': {
        'summer': 'Fish eat more and grow faster. Increase feed rate. Monitor oxygen levels.',
        'winter': 'Fish metabolism slows — reduce feed to 2–3% body weight. Growth slows.',
      },
    },
  };

  // ---------------------------------------------------------------------------
  // VACCINATION & HEALTH SCHEDULES
  // ---------------------------------------------------------------------------
  static final Map<String, List<Map<String, Object>>> healthSchedule = {
    'Beef Cattle': [
      {
        'task': 'Foot and Mouth Disease (FMD) Vaccination',
        'frequency': 'Every 6 months (April & October)',
        'timing': 'April and October',
        'product': 'FMD polyvalent vaccine',
        'notes': 'Compulsory by law in Zimbabwe. Contact your vet or Agritex.',
        'icon': '💉',
      },
      {
        'task': 'Anthrax Vaccination',
        'frequency': 'Annual — before rainy season',
        'timing': 'September–October',
        'product': 'Sterne anthrax vaccine',
        'notes': 'Critical in Regions IV and V. Do NOT vaccinate animals showing signs of illness.',
        'icon': '💉',
      },
      {
        'task': 'Blackleg Vaccination',
        'frequency': 'Annual — before rainy season',
        'timing': 'September–October',
        'product': 'Blackleg vaccine (Clostridial)',
        'notes': 'Common in young cattle. Vaccinate calves from 3 months old.',
        'icon': '💉',
      },
      {
        'task': 'Tick Control (Dipping)',
        'frequency': 'Weekly in tick season, fortnightly in dry season',
        'timing': 'Year-round — more frequent Oct–April',
        'product': 'Amitraz, Cypermethrin, or Flumethrin dip',
        'notes': 'Rotate chemicals to prevent resistance. Inspect animals for ticks between dipping.',
        'icon': '🪣',
      },
      {
        'task': 'Internal Parasite Dosing (Drenching)',
        'frequency': 'Every 3–6 months. More frequent for calves.',
        'timing': 'Start of rainy season and mid-season',
        'product': 'Albendazole, Levamisole, or Doramectin',
        'notes': 'Rotate drug classes to prevent resistance.',
        'icon': '💊',
      },
      {
        'task': 'Brucellosis Vaccination (Heifers)',
        'frequency': 'Once, for heifers aged 4–8 months only',
        'timing': 'Once in lifetime at 4–8 months',
        'product': 'S19 or RB51 vaccine (vet must administer)',
        'notes': 'Mandatory for herd certification. Do NOT vaccinate pregnant or adult cows.',
        'icon': '💉',
      },
    ],
    'Dairy Cattle': [
      {
        'task': 'FMD Vaccination',
        'frequency': 'Every 4 months (3x per year)',
        'timing': 'March, July, November',
        'product': 'FMD polyvalent vaccine',
        'notes': 'Dairy herds need more frequent vaccination due to high economic value.',
        'icon': '💉',
      },
      {
        'task': 'Tick Control',
        'frequency': 'Weekly or as needed',
        'timing': 'Year-round',
        'product': 'Amitraz or Cypermethrin pour-on or spray',
        'notes': 'Ticks transmit East Coast Fever — extremely costly for dairy farmers.',
        'icon': '🪣',
      },
      {
        'task': 'Dry Cow Therapy',
        'frequency': 'At every drying off',
        'timing': 'When drying off each cow',
        'product': 'Long-acting intramammary antibiotic (e.g. Cephalonium)',
        'notes': 'Prevents mastitis during the dry period. Critical for udder health.',
        'icon': '💊',
      },
      {
        'task': 'Mastitis Monitoring',
        'frequency': 'Weekly California Mastitis Test (CMT)',
        'timing': 'Every week',
        'product': 'CMT reagent',
        'notes': 'Catch sub-clinical mastitis early before it becomes clinical. Record results.',
        'icon': '🔍',
      },
    ],
    'Goats': [
      {
        'task': 'Enterotoxaemia (Pulpy Kidney) Vaccination',
        'frequency': '2x per year (April & October)',
        'timing': 'Before rainy season and mid-season',
        'product': 'Pulpy Kidney vaccine (Clostridium perfringens D)',
        'notes': 'Kills kids rapidly. Vaccinate does 4–6 weeks before kidding to protect kids via colostrum.',
        'icon': '💉',
      },
      {
        'task': 'Peste des Petits Ruminants (PPR)',
        'frequency': 'Every 3 years',
        'timing': 'As recommended by vet',
        'product': 'PPR vaccine',
        'notes': 'Highly contagious viral disease. Notifiable — report to vet if suspected.',
        'icon': '💉',
      },
      {
        'task': 'Internal Parasite Control (FAMACHA)',
        'frequency': 'Monthly assessment. Drench only those that need it.',
        'timing': 'Monthly during rainy season',
        'product': 'Closantel, Levamisole, or Moxidectin',
        'notes': 'Use FAMACHA eye chart to identify anaemic animals needing treatment. Do NOT drench all animals routinely.',
        'icon': '👁️',
      },
      {
        'task': 'Hoof Trimming',
        'frequency': 'Every 3–6 months',
        'timing': 'Dry season when hooves are hard',
        'product': 'Hoof shears + Copper sulphate foot bath',
        'notes': 'Overgrown hooves cause lameness. Foot rot is common in wet conditions.',
        'icon': '✂️',
      },
    ],
    'Sheep': [
      {
        'task': 'Enterotoxaemia + Pulpy Kidney',
        'frequency': 'Annual + boost 4 weeks before lambing',
        'timing': 'September + boost before lambing',
        'product': 'Clostridial multi-vaccine (3-in-1 or 4-in-1)',
        'notes': 'Protects lambs via colostrum if ewes are vaccinated.',
        'icon': '💉',
      },
      {
        'task': 'Internal Parasite Control',
        'frequency': 'Every 4–6 weeks during rainy season',
        'timing': 'October–April',
        'product': 'Closantel, Ivermectin, or Albendazole',
        'notes': 'Haemonchus (barber pole worm) is the number one killer of sheep in Zimbabwe.',
        'icon': '💊',
      },
      {
        'task': 'Shearing',
        'frequency': 'Once or twice a year',
        'timing': 'September–October (before hot season)',
        'product': 'Shearing equipment + blowfly preventative',
        'notes': 'Long wool attracts blowfly strike. Shear before rains in wool breeds.',
        'icon': '✂️',
      },
    ],
    'Pigs': [
      {
        'task': 'African Swine Fever (ASF) Prevention',
        'frequency': 'No vaccine available — prevention only',
        'timing': 'Year-round biosecurity',
        'product': 'Strict biosecurity',
        'notes': 'ASF is fatal and highly contagious. No treatment. Prevent by: no kitchen waste/raw meat, control visitors, disinfect equipment. Report immediately if suspected.',
        'icon': '⚠️',
      },
      {
        'task': 'Foot and Mouth Disease Vaccination',
        'frequency': 'Every 6 months',
        'timing': 'April and October',
        'product': 'FMD vaccine (pigs)',
        'notes': 'Pigs are highly susceptible to FMD. Vaccinate all pigs >2 months.',
        'icon': '💉',
      },
      {
        'task': 'Internal Parasite Dosing',
        'frequency': 'Every 6 months',
        'timing': 'Every 6 months',
        'product': 'Ivermectin injection or Fenbendazole in feed',
        'notes': 'Treat sows 2 weeks before farrowing to prevent passing parasites to piglets.',
        'icon': '💊',
      },
      {
        'task': 'Iron Injection (Piglets)',
        'frequency': 'Once, at 3 days old',
        'timing': '3 days after birth',
        'product': 'Iron dextran 200mg injection',
        'notes': 'Piglets are born with low iron. Without this injection they develop fatal anaemia.',
        'icon': '💉',
      },
    ],
    'Broiler Chickens': [
      {
        'task': 'Newcastle Disease Vaccination',
        'frequency': 'Day 7 and day 21',
        'timing': 'Day 7: eye drop/drinking water. Day 21: drinking water.',
        'product': 'Lasota strain vaccine',
        'notes': 'Newcastle kills entire flocks. Never skip. Keep vaccine cold — use within 2 hours of mixing.',
        'icon': '💉',
      },
      {
        'task': 'Infectious Bursal Disease (Gumboro)',
        'frequency': 'Day 14 and day 21',
        'timing': 'Day 14 and 21 — drinking water',
        'product': 'Gumboro intermediate vaccine',
        'notes': 'Gumboro suppresses immune system — birds then die from secondary infections.',
        'icon': '💉',
      },
      {
        'task': 'Marek\'s Disease',
        'frequency': 'At hatchery (day old)',
        'timing': 'Day of hatch — by hatchery',
        'product': 'HVT vaccine',
        'notes': 'Should be done at hatchery. Confirm with your chick supplier.',
        'icon': '💉',
      },
      {
        'task': 'Coccidiosis Control',
        'frequency': 'Preventative: coccidiostat in feed weeks 1–4. Treat if outbreak occurs.',
        'timing': 'Ongoing',
        'product': 'Amprolium or Toltrazuril (treatment)',
        'notes': 'Bloody droppings = coccidiosis outbreak. Treat immediately. Keep litter dry.',
        'icon': '💊',
      },
    ],
    'Layer Chickens': [
      {
        'task': 'Full Vaccination Program',
        'frequency': 'Multiple vaccines from day 1',
        'timing': 'See schedule below',
        'product': 'Marek\'s (day 1), Newcastle (day 7, 21, 8 weeks, every 3 months), Gumboro (day 14, 21), IB (day 1, 21)',
        'notes': 'Layer vaccination is more extensive than broilers due to longer production period.',
        'icon': '💉',
      },
      {
        'task': 'External Parasite Control',
        'frequency': 'Monthly inspection. Treat if lice/mites found.',
        'timing': 'Monthly',
        'product': 'Permethrin dust or spray on birds and housing',
        'notes': 'Red mites hide in cracks during the day and feed at night. Treat house thoroughly.',
        'icon': '🪣',
      },
    ],
    'Goats': [
      {
        'task': 'Enterotoxaemia (Pulpy Kidney) Vaccination',
        'frequency': '2x per year',
        'timing': 'April and October',
        'product': 'Pulpy Kidney vaccine',
        'notes': 'Kids die rapidly from this disease. Vaccinate does before kidding.',
        'icon': '💉',
      },
      {
        'task': 'Internal Parasite Control',
        'frequency': 'Monthly FAMACHA assessment',
        'timing': 'Monthly during rainy season',
        'product': 'Closantel or Moxidectin',
        'notes': 'Target treatment — only treat animals showing anaemia (pale gums/inner eyelid).',
        'icon': '💊',
      },
    ],
    'Rabbits': [
      {
        'task': 'Rabbit Haemorrhagic Disease (RHD)',
        'frequency': 'Annual vaccination',
        'timing': 'Annual',
        'product': 'RHD vaccine (where available)',
        'notes': 'Highly fatal — no treatment. Prevention through vaccination and biosecurity.',
        'icon': '💉',
      },
      {
        'task': 'Myxomatosis Prevention',
        'frequency': 'Mosquito/fly control',
        'timing': 'Year-round',
        'product': 'Insect screens on hutches, insecticide around housing',
        'notes': 'Spread by mosquitoes and biting flies. Fatal. No treatment available.',
        'icon': '🦟',
      },
      {
        'task': 'Ear Mite Check',
        'frequency': 'Weekly inspection',
        'timing': 'Weekly',
        'product': 'Ivermectin drops in ear if mites found',
        'notes': 'Rabbits scratch ears, shake head. Brown crusty debris in ear = ear mites.',
        'icon': '🔍',
      },
    ],
  };

  // ---------------------------------------------------------------------------
  // DISEASE GUIDE per animal type
  // ---------------------------------------------------------------------------
  static const Map<String, List<Map<String, dynamic>>> diseaseGuide = {
    'Beef Cattle': [
      {
        'name': 'East Coast Fever (ECF)',
        'icon': '🦠',
        'severity': 'Very High',
        'signs': 'Swollen lymph nodes (especially behind ears/shoulders), high fever (>40°C), nasal discharge, difficulty breathing, death within 3 weeks if untreated.',
        'cause': 'Theileria parva parasite — spread by brown ear tick (Rhipicephalus appendiculatus)',
        'treatment': 'Buparvaquone (Butalex) injection — must be given EARLY. Consult vet immediately.',
        'prevention': 'Regular tick control (dipping). Immunization (ITM) available for some regions.',
        'emergency': true,
      },
      {
        'name': 'Foot and Mouth Disease (FMD)',
        'icon': '🦠',
        'severity': 'Very High',
        'signs': 'Blisters/sores on mouth, tongue, feet, teats. Excessive salivation. Lameness. Animals refuse to walk or eat.',
        'cause': 'FMD virus — extremely contagious. Spreads through air, contact, contaminated feed.',
        'treatment': 'No specific treatment. Supportive care. REPORT TO GOVERNMENT VET IMMEDIATELY.',
        'prevention': 'Regular FMD vaccination every 6 months.',
        'emergency': true,
      },
      {
        'name': 'Anthrax',
        'icon': '☠️',
        'severity': 'Very High',
        'signs': 'Sudden death — often no prior signs. Blood from body orifices (mouth, nose, anus) that does not clot.',
        'cause': 'Bacillus anthracis bacteria — spores live in soil for decades.',
        'treatment': 'Penicillin if caught early. Usually fatal before diagnosis.',
        'prevention': 'Annual vaccination before rainy season in endemic areas (Regions IV and V).',
        'emergency': true,
      },
      {
        'name': 'Lumpy Skin Disease',
        'icon': '🟤',
        'severity': 'High',
        'signs': 'Firm round nodules (lumps) on skin all over body, fever, swollen lymph nodes, reduced milk production, lameness.',
        'cause': 'LSD virus — spread by insects (mosquitoes, biting flies, ticks).',
        'treatment': 'No specific treatment. Anti-inflammatory and antibiotics for secondary infections.',
        'prevention': 'LSD vaccine available. Insect control.',
        'emergency': false,
      },
      {
        'name': 'Bovine Respiratory Disease (BRD)',
        'icon': '🫁',
        'severity': 'Medium',
        'signs': 'Nasal discharge, cough, rapid breathing, fever, reduced appetite, animals stand apart from herd.',
        'cause': 'Multiple viruses and bacteria — often triggered by stress (transport, weaning, weather change).',
        'treatment': 'Antibiotics (Oxytetracycline, Tulathromycin) — must treat early. Consult vet.',
        'prevention': 'Reduce stress, avoid overcrowding, ensure good ventilation, vaccination.',
        'emergency': false,
      },
    ],
    'Dairy Cattle': [
      {
        'name': 'Mastitis',
        'icon': '🐄',
        'severity': 'High',
        'signs': 'Hot, swollen, painful udder quarter. Abnormal milk (watery, clots, blood). Cow kicks when milked. Reduced milk.',
        'cause': 'Bacterial infection — Staphylococcus, Streptococcus, E. coli.',
        'treatment': 'Intramammary antibiotic tubes + systemic antibiotics for severe cases. Strip affected quarter 3x daily.',
        'prevention': 'Post-dip teats after every milking. Use CMT weekly. Dry cow therapy at drying off.',
        'emergency': false,
      },
      {
        'name': 'Milk Fever (Hypocalcaemia)',
        'icon': '🦴',
        'severity': 'High',
        'signs': 'Cow cannot stand within 24–72 hours after calving. Cold ears, muscle tremors, goes down and cannot get up.',
        'cause': 'Low blood calcium just after calving — more common in high producers.',
        'treatment': 'Calcium borogluconate IV injection — usually respond within 30 minutes. Consult vet.',
        'prevention': 'Low calcium diet in dry period, calcium supplements at calving.',
        'emergency': true,
      },
    ],
    'Goats': [
      {
        'name': 'Enterotoxaemia (Pulpy Kidney)',
        'icon': '☠️',
        'severity': 'Very High',
        'signs': 'Sudden death in well-fed animals, especially kids. May show convulsions, crying, paddling before death.',
        'cause': 'Clostridium perfringens bacteria — multiplies rapidly in gut after dietary change.',
        'treatment': 'Antitoxin injection (rarely works — death too fast). Antibiotics for survivors.',
        'prevention': 'Vaccination is the only effective control. Vaccinate twice yearly.',
        'emergency': true,
      },
      {
        'name': 'Haemonchosis (Barber Pole Worm)',
        'icon': '🪱',
        'severity': 'Very High',
        'signs': 'Pale gums and inner eyelids, bottle jaw (fluid under chin), weakness, death in severe cases. Animals look thin despite eating.',
        'cause': 'Haemonchus contortus — a blood-sucking internal parasite. Worst after rains.',
        'treatment': 'Closantel or Moxidectin drench. Treat based on FAMACHA score.',
        'prevention': 'FAMACHA-based targeted treatment. Avoid over-stocking. Pasture rotation.',
        'emergency': false,
      },
      {
        'name': 'Pneumonia (Pasteurella)',
        'icon': '🫁',
        'severity': 'High',
        'signs': 'Coughing, nasal discharge, rapid breathing, fever, reduced appetite. Often affects kids.',
        'cause': 'Pasteurella multocida bacteria — triggered by stress, wet conditions, crowding.',
        'treatment': 'Oxytetracycline or Penicillin injection. Treat early for best results.',
        'prevention': 'Avoid overcrowding, ensure good ventilation, reduce stress.',
        'emergency': false,
      },
    ],
    'Pigs': [
      {
        'name': 'African Swine Fever (ASF)',
        'icon': '☠️',
        'severity': 'Very High',
        'signs': 'High fever, red/purple skin discoloration on ears/snout/belly, vomiting, bloody diarrhoea, death within 7–10 days.',
        'cause': 'ASF virus — spread through contact, contaminated feed (especially kitchen waste with pork), ticks.',
        'treatment': 'NO TREATMENT. 100% fatal. REPORT IMMEDIATELY to vet/government.',
        'prevention': 'Never feed kitchen waste. Strict biosecurity. Control ticks. No contact with wild pigs.',
        'emergency': true,
      },
      {
        'name': 'Porcine Respiratory Disease',
        'icon': '🫁',
        'severity': 'Medium',
        'signs': 'Coughing, laboured breathing, reduced growth, sneezing.',
        'cause': 'Multiple bacteria and viruses — often from overcrowding or poor ventilation.',
        'treatment': 'Antibiotics as directed by vet. Improve ventilation.',
        'prevention': 'Good ventilation, correct stocking density, all-in all-out management.',
        'emergency': false,
      },
    ],
    'Broiler Chickens': [
      {
        'name': 'Newcastle Disease',
        'icon': '☠️',
        'severity': 'Very High',
        'signs': 'Sudden death, twisted neck (torticollis), gasping, green diarrhoea, nervous signs, rapid flock mortality.',
        'cause': 'Newcastle Disease Virus — airborne, spreads rapidly.',
        'treatment': 'No treatment. Supportive care only. Vaccinate survivors.',
        'prevention': 'Strict vaccination program at day 7 and day 21.',
        'emergency': true,
      },
      {
        'name': 'Coccidiosis',
        'icon': '🩸',
        'severity': 'High',
        'signs': 'Bloody or brown watery droppings, birds hunched and depressed, reduced feed and water intake, sudden deaths.',
        'cause': 'Eimeria parasite — thrives in wet, warm litter.',
        'treatment': 'Amprolium or Toltrazuril in drinking water for 3–5 days.',
        'prevention': 'Keep litter dry, use coccidiostat in starter feed, do not overstock.',
        'emergency': false,
      },
      {
        'name': 'Infectious Bronchitis (IB)',
        'icon': '🫁',
        'severity': 'High',
        'signs': 'Gasping, rales (rattling sound), nasal discharge, reduced growth, drop in egg production in layers.',
        'cause': 'Coronavirus — spreads by air and contact.',
        'treatment': 'No specific treatment. Antibiotics for secondary bacterial infection.',
        'prevention': 'Vaccination at day 1 and day 21. Good biosecurity.',
        'emergency': false,
      },
    ],
    'Layer Chickens': [
      {
        'name': 'Egg Drop Syndrome',
        'icon': '🥚',
        'severity': 'Medium',
        'signs': 'Sudden drop in egg production. Pale, thin-shelled, shell-less eggs. Normal bird health otherwise.',
        'cause': 'EDS virus or nutritional deficiency (calcium, phosphorus, vitamin D).',
        'treatment': 'No treatment. Improve nutrition. Vaccination if virus confirmed.',
        'prevention': 'Vaccination, correct layer feed, adequate calcium.',
        'emergency': false,
      },
    ],
    'Rabbits': [
      {
        'name': 'Rabbit Haemorrhagic Disease (RHD)',
        'icon': '☠️',
        'severity': 'Very High',
        'signs': 'Sudden death, sometimes blood from nose. May show paddling, convulsions.',
        'cause': 'Calicivirus — extremely contagious. Spreads through contact, insects, contaminated materials.',
        'treatment': 'No treatment. Fatal within 12–36 hours.',
        'prevention': 'Annual vaccination where available. Strict hygiene and biosecurity.',
        'emergency': true,
      },
      {
        'name': 'GI Stasis',
        'icon': '🚨',
        'severity': 'High',
        'signs': 'Rabbit stops eating and drinking, no droppings, bloated belly, hunched posture, grinding teeth.',
        'cause': 'Diet low in fibre, stress, dehydration, hairballs.',
        'treatment': 'Vet treatment urgently — gut motility drugs, fluids. Fatal if not treated quickly.',
        'prevention': 'Always provide unlimited hay, fresh water, and exercise.',
        'emergency': true,
      },
    ],
  };

  // ---------------------------------------------------------------------------
  // BREEDING GUIDE per animal type
  // ---------------------------------------------------------------------------
  static final Map<String, Map<String, Object>> breedingGuide = {
    'Beef Cattle': {
      'maturity_age': '18–24 months (heifers)',
      'gestation': '283 days (9.5 months)',
      'calving_interval': 'Target 12 months (1 calf per year)',
      'bull_ratio': '1 bull per 25–30 cows',
      'breeding_season': 'November–January (for Aug–Oct calving on good pasture)',
      'signs_of_heat': 'Stands to be mounted, restless, swollen vulva, clear mucus discharge. Heat lasts 12–18 hours.',
      'tips': [
        'Check bull fertility before breeding season (semen test).',
        'Maintain body condition score 3–3.5 at calving.',
        'Record calving dates and calf details.',
        'Wean calves at 6–8 months.',
      ],
    },
    'Dairy Cattle': {
      'maturity_age': '15–18 months (heifers)',
      'gestation': '283 days',
      'calving_interval': 'Target 12–13 months',
      'service_method': 'Artificial Insemination (AI) preferred for genetic improvement',
      'heat_detection': 'Observe twice daily (morning and evening). Use tail paint or chin ball marker.',
      'tips': [
        'Use AI with certified semen for breed improvement.',
        'Dry off cows 6–8 weeks before calving.',
        'Colostrum in first 6 hours is critical for calf immunity.',
        'Record all calvings, services, and milk production.',
      ],
    },
    'Goats': {
      'maturity_age': '7–10 months',
      'gestation': '150 days (5 months)',
      'kidding_rate': 'Target 1.5–2 kids per doe per year (twins common)',
      'buck_ratio': '1 buck per 25–30 does',
      'breeding_season': 'April–June (for September–November kidding)',
      'signs_of_heat': 'Tail wagging, bleating loudly, seeking buck, swollen vulva. Every 21 days.',
      'tips': [
        'Flush does (increase feed) 3 weeks before and during mating to increase twinning.',
        'Separate buck from does except during mating season.',
        'Mark mating dates — calculate expected kidding.',
        'Assist difficult births — kids must receive colostrum within 30 minutes.',
      ],
    },
    'Sheep': {
      'maturity_age': '8–10 months',
      'gestation': '147 days (5 months)',
      'lambing_rate': 'Target 120–140% (some ewes twin)',
      'ram_ratio': '1 ram per 30–40 ewes',
      'breeding_season': 'March–May (for August–October lambing)',
      'tips': [
        'Flush ewes before mating to increase ovulation rate.',
        'Mark mated ewes with a raddle (chalk on ram chest).',
        'Shelter ewes and lambs from cold nights at lambing.',
        'Lambs must suck colostrum within 2 hours of birth.',
      ],
    },
    'Pigs': {
      'maturity_age': '6–8 months',
      'gestation': '114 days (3 months, 3 weeks, 3 days)',
      'litter_size': 'Target 10–12 piglets per litter',
      'farrowing_interval': 'Every 5–6 months if managed well (2 litters per year)',
      'signs_of_heat': 'Standing reflex when pressure applied to back, swollen vulva, restlessness. Every 21 days.',
      'tips': [
        'Increase feed (flushing) 1 week before and during mating.',
        'Reduce feed last 2 weeks of gestation to ease farrowing.',
        'Prepare clean farrowing pen 1 week before due date.',
        'Piglets need heat lamp (32°C) for first 2 weeks.',
        'Iron inject all piglets at day 3.',
      ],
    },
    'Broiler Chickens': {
      'note': 'Broilers are not bred on farm. Purchase day-old chicks from reputable hatchery.',
      'cycle': '6–7 weeks from day-old to market weight (2–2.5 kg)',
      'tips': [
        'Plan 2–3 weeks rest between flocks for cleanup and disinfection.',
        'Order chicks from a hatchery with a good health record.',
        'Confirm vaccination status from hatchery.',
      ],
    },
    'Layer Chickens': {
      'note': 'Layers not usually bred on-farm. Purchase day-old chicks or point-of-lay pullets.',
      'production_cycle': 'Productive from 18 weeks to 72–80 weeks (12–18 months of production)',
      'tips': [
        'Replace flock after 72 weeks for economic production.',
        'Keep accurate records of feed consumed vs eggs produced.',
        'Cull poor-producing hens regularly.',
      ],
    },
    'Goats': {
      'maturity_age': '7–10 months',
      'gestation': '150 days',
      'tips': ['Flush does before mating', 'Target twinning'],
    },
    'Rabbits': {
      'maturity_age': '4–6 months (doe), 5–7 months (buck)',
      'gestation': '31 days',
      'litter_size': '6–10 kits per litter',
      'litters_per_year': '5–6 litters per year',
      'tips': [
        'Always take doe to buck\'s cage — not the reverse.',
        'Provide nest box 28 days after mating.',
        'Wean kits at 4–5 weeks.',
        'Re-breed doe 14–21 days after kindling.',
      ],
    },
  };

  // ---------------------------------------------------------------------------
  // GET MONTHLY HEALTH ALERTS
  // ---------------------------------------------------------------------------
  static List<String> getMonthlyAlerts(
      String animalType, String region, int month) {
    final alerts = <String>[];
    final monthName = _monthNames[month - 1];

    // Rainy season Oct–April
    final isRainySeason = month >= 10 || month <= 4;
    // Dry season May–September
    final isDrySeason = month >= 5 && month <= 9;

    if (animalType == 'Beef Cattle' ||
        animalType == 'Dairy Cattle') {
      if (month == 9 || month == 10) {
        alerts.add('🔴 Vaccinate for Anthrax and Blackleg before rains');
        alerts.add('🔴 FMD vaccination due — April and October');
      }
      if (month == 4) {
        alerts.add('🔴 FMD vaccination due');
      }
      if (isRainySeason) {
        alerts.add('🟡 Increase tick dipping frequency to weekly');
        alerts.add('🟡 Watch for East Coast Fever signs');
      }
      if (isDrySeason) {
        alerts.add('🟡 Supplement with protein lick');
        alerts.add('🟡 Ensure adequate water sources');
      }
    }

    if (animalType == 'Goats' || animalType == 'Sheep') {
      if (month == 4 || month == 10) {
        alerts.add('🔴 Enterotoxaemia vaccination due');
      }
      if (isRainySeason) {
        alerts.add('🔴 Check FAMACHA scores monthly — worm burden highest now');
        alerts.add('🟡 Watch for footrot in wet conditions');
      }
    }

    if (animalType == 'Broiler Chickens' ||
        animalType == 'Layer Chickens') {
      if (isRainySeason) {
        alerts.add('🟡 High humidity — watch for respiratory disease');
        alerts.add('🟡 Keep litter dry — coccidiosis risk is high');
      }
      if (isDrySeason) {
        alerts.add('🟡 Hot weather alert — increase ventilation');
        alerts.add('🟡 Ensure cool fresh water always available');
      }
    }

    if (animalType == 'Pigs') {
      alerts.add('⚠️ ASF biosecurity — never feed kitchen scraps');
      if (month == 4 || month == 10) {
        alerts.add('🔴 FMD vaccination due');
      }
    }

    if (alerts.isEmpty) {
      alerts.add(
          '✅ No critical alerts for $monthName. Continue routine health checks.');
    }

    return alerts;
  }

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];
}