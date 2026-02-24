// lib/services/advisory/knowledge_base_service.dart
// Developed by Sir Enocks — Cor Technologies
// Offline farming knowledge base for Zimbabwe smallholder and commercial farmers.

class KbArticle {
  final String id;
  final String title;
  final String category;
  final String categoryIcon;
  final String summary;
  final List<KbSection> sections;
  final List<String> tags;

  const KbArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryIcon,
    required this.summary,
    required this.sections,
    required this.tags,
  });
}

class KbSection {
  final String heading;
  final String body;
  final String? tip;
  const KbSection({
    required this.heading,
    required this.body,
    this.tip,
  });
}

class KbGlossaryTerm {
  final String term;
  final String definition;
  final String? example;
  const KbGlossaryTerm({
    required this.term,
    required this.definition,
    this.example,
  });
}

class KbCategory {
  final String name;
  final String icon;
  final String description;
  const KbCategory({
    required this.name,
    required this.icon,
    required this.description,
  });
}

class KnowledgeBaseService {
  // ─────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────
  static const List<KbCategory> categories = [
    KbCategory(name: 'Soil Health',         icon: '🌱', description: 'Soil types, pH, fertility, composting'),
    KbCategory(name: 'Post-Harvest',        icon: '📦', description: 'Storage, grading, handling, value addition'),
    KbCategory(name: 'Marketing & Selling', icon: '💰', description: 'Markets, pricing, contracts, branding'),
    KbCategory(name: 'Government Programs', icon: '🏛️', description: 'GMB, Agritex, grants, subsidies'),
    KbCategory(name: 'Pest & Disease',      icon: '🐛', description: 'Identification, control, prevention'),
    KbCategory(name: 'Climate & Seasons',   icon: '🌦️', description: 'Zimbabwe seasons, rainfall, planning'),
    KbCategory(name: 'Glossary',            icon: '📖', description: 'Farming terms explained simply'),
  ];

  // ─────────────────────────────────────────
  // ALL ARTICLES
  // ─────────────────────────────────────────
  static const List<KbArticle> articles = [

    // ══════════════════════════════════════
    // SOIL HEALTH
    // ══════════════════════════════════════
    KbArticle(
      id: 'soil_001',
      title: 'Understanding Zimbabwe\'s Soil Types',
      category: 'Soil Health',
      categoryIcon: '🌱',
      summary: 'Zimbabwe has 5 main soil types. Knowing yours determines which crops you can grow and how much fertilizer you need.',
      tags: ['soil', 'fertility', 'clay', 'sand', 'loam'],
      sections: [
        KbSection(
          heading: 'The 5 Main Soil Types in Zimbabwe',
          body: 'Zimbabwe\'s soils range from highly fertile to very poor. The five main types are:\n\n'
              '1. CLAY SOILS (Vlei/Dambo soils) — Heavy, waterlog easily, high fertility. Found in valleys and low-lying areas. Good for rice, sugar cane, and vegetables with drainage.\n\n'
              '2. SANDY SOILS (Arenosols) — Light, drain fast, low fertility, low water-holding capacity. Cover most of Regions III, IV, V. Maize struggles without fertilizer. Good for groundnuts, sorghum.\n\n'
              '3. LOAM SOILS — The best! Mix of sand, silt, and clay. Good drainage and water retention. Found mainly in Mashonaland and parts of Midlands. Excellent for all crops.\n\n'
              '4. RED CLAY LOAM (Fersiallitic soils) — Red soils of Mashonaland Highveld. Well-drained, moderate fertility. Excellent for tobacco, maize, wheat.\n\n'
              '5. SANDY CLAY LOAM — Common in commercial farming areas. Moderate drainage, good fertility when managed properly.',
          tip: 'Do the ribbon test: squeeze moist soil and push it through your fingers. Long ribbon = clay. Short crumbly ribbon = loam. No ribbon = sandy.',
        ),
        KbSection(
          heading: 'Soil pH — Why It Matters',
          body: 'Soil pH measures acidity or alkalinity on a scale of 1–14. Most crops prefer pH 5.5–6.5.\n\n'
              'ACIDIC SOIL (pH below 5.5) — Most of Zimbabwe\'s soils are naturally acidic. Acid soils lock up phosphorus and molybdenum, causing poor growth even when fertilized.\n\n'
              'Signs of acidic soil: Poor crop growth despite fertilizer. Aluminum toxicity (stunted roots). Poor legume nodulation.\n\n'
              'NEUTRAL TO SLIGHTLY ACIDIC (pH 5.5–6.5) — Ideal for maize, vegetables, tobacco, wheat. Nutrients are most available at this pH.\n\n'
              'ALKALINE SOIL (pH above 7.0) — Rare in Zimbabwe. Iron and manganese become unavailable. Symptoms: yellow leaves with green veins (iron chlorosis).',
          tip: 'Soil pH test kits cost less than \$5 from agricultural suppliers. Test your soil every 3 years. It is the most valuable \$5 you will spend.',
        ),
        KbSection(
          heading: 'Liming — How to Fix Acidic Soils',
          body: 'Agricultural lime (calcium carbonate) neutralizes soil acidity. It is the single most important soil improvement practice in Zimbabwe.\n\n'
              'WHEN TO LIME: When pH is below 5.5. Test soil before liming — do not lime without testing.\n\n'
              'HOW MUCH TO APPLY:\n'
              '— Sandy soils: 500–1,000 kg/ha\n'
              '— Loam soils: 1,000–2,000 kg/ha\n'
              '— Clay soils: 2,000–3,000 kg/ha\n\n'
              'WHEN TO APPLY: At least 3–6 months before planting. Lime needs time to react with the soil. Apply at land preparation in October–November for the following season.\n\n'
              'HOW TO APPLY: Spread evenly and disc into the topsoil (0–15cm). Do not leave on the surface — it must mix with soil to work.\n\n'
              'HOW OFTEN: Every 3–5 years depending on crop and soil type. Continuous maize and tobacco farming acidifies soil fastest.',
          tip: 'Dolomitic lime also supplies magnesium — use this if your soil is both acidic and magnesium-deficient (common in tobacco areas).',
        ),
        KbSection(
          heading: 'Building Soil Organic Matter',
          body: 'Organic matter is the life of the soil. It feeds soil organisms, improves water retention, reduces erosion, and slowly releases nutrients.\n\n'
              'COMPOST MAKING:\n'
              '1. Build a heap 1.5m x 1.5m x 1m high\n'
              '2. Layer: crop residues, manure, soil, ash — repeat layers\n'
              '3. Keep moist (like a wrung-out cloth)\n'
              '4. Turn every 2–3 weeks\n'
              '5. Ready in 6–8 weeks (dark, crumbly, earthy smell)\n'
              '6. Apply 5–10 tonnes/ha at land preparation\n\n'
              'MANURE: Cattle manure 5–10 tonnes/ha. Apply and incorporate before planting. Fresh manure can burn crops — compost it first or apply 2 months before planting.\n\n'
              'CROP ROTATION: Include legumes (beans, groundnuts, soybeans) in rotation. They fix nitrogen and leave organic matter in the soil.\n\n'
              'MINIMUM TILLAGE: Excessive plowing destroys soil structure and burns off organic matter. Consider conservation agriculture (CA) — minimum tillage with crop residue mulching.',
          tip: 'Adding 1 tonne of well-made compost provides approximately 10–12kg of slow-release nitrogen, 2kg phosphorus, and 10kg potassium.',
        ),
        KbSection(
          heading: 'Conservation Agriculture (CA)',
          body: 'Conservation Agriculture is the most important soil health practice for Zimbabwe small-scale farmers. It is promoted by government and NGOs because it improves yields while reducing input costs.\n\n'
              'THE THREE PRINCIPLES:\n'
              '1. MINIMUM TILLAGE — Do not plow. Use rip lines or dibble (Chaka hoe) to create planting basins only. Soil structure is preserved.\n\n'
              '2. PERMANENT SOIL COVER — Leave crop residues on the surface as mulch. This reduces evaporation, suppresses weeds, and feeds soil organisms.\n\n'
              '3. CROP ROTATION — Rotate maize with legumes every season. This breaks pest cycles and improves soil fertility.\n\n'
              'RESULTS IN ZIMBABWE: Yield increases of 20–50% in 3–5 years. Water use efficiency doubles. Fertilizer requirements decrease over time.\n\n'
              'PLANTING BASINS: 15cm x 15cm x 15cm basins, 90cm between rows, 60cm within rows. Add compost to each basin before planting.',
          tip: 'Agritex extension workers can demonstrate CA planting basin layout free of charge. Contact your local Agritex office.',
        ),
      ],
    ),

    KbArticle(
      id: 'soil_002',
      title: 'Reading Fertilizer Labels and NPK',
      category: 'Soil Health',
      categoryIcon: '🌱',
      summary: 'Every fertilizer bag has three numbers — N, P, K. Understanding them saves money and improves yields.',
      tags: ['fertilizer', 'NPK', 'nitrogen', 'phosphorus', 'potassium', 'compound'],
      sections: [
        KbSection(
          heading: 'What NPK Means',
          body: 'Every fertilizer bag shows three numbers — these are the percentages of Nitrogen (N), Phosphorus (P₂O₅), and Potassium (K₂O) in the bag.\n\n'
              'COMPOUND D (7:14:7) — 7% N, 14% P, 7% K. A balanced basal fertilizer. Good for establishment of most crops.\n'
              'COMPOUND S (7:21:8+S) — Higher phosphorus. Best for tobacco and phosphorus-hungry crops.\n'
              'COMPOUND L (5:15:9) — Lower N, good for potatoes and root vegetables.\n'
              'CAN (Calcium Ammonium Nitrate 26%N) — Pure nitrogen top dress. Use 6–8 weeks after planting.\n'
              'UREA (46%N) — Highest nitrogen content. Most cost-effective N source but must be incorporated — volatilizes on surface.\n'
              'AN (Ammonium Nitrate 34.5%N) — Common top dress for maize. Half nitrate (fast) + half ammonium (slow).',
          tip: 'Buy fertilizer by cost per kg of nutrient, not price per bag. Urea at 46%N is often the cheapest source of nitrogen.',
        ),
        KbSection(
          heading: 'Fertilizer Application Rates for Common Crops',
          body: 'MAIZE:\n'
              '— Basal: Compound D 200–400kg/ha at planting (5–7cm beside and below seed)\n'
              '— Top dress: AN or CAN 200kg/ha at 4–6 weeks (knee-high stage)\n\n'
              'TOBACCO:\n'
              '— Basal: Compound S 500–700kg/ha\n'
              '— Top dress: AN 200kg/ha in split doses\n\n'
              'VEGETABLES:\n'
              '— Basal: Compound D or S 500–800kg/ha + compost 10–20t/ha\n'
              '— Top dress: CAN or AN 200kg/ha every 3–4 weeks during growth\n\n'
              'WHEAT:\n'
              '— Basal: Compound C (6:28:23) 350kg/ha\n'
              '— Top dress: AN 150kg/ha at tillering, 150kg/ha at stem extension\n\n'
              'SOYBEANS: Do NOT apply nitrogen — they fix their own. Apply Compound L (phosphorus-high) 200kg/ha basal only.',
          tip: 'Under-apply and split your nitrogen rather than applying it all at once. Two smaller applications out-perform one large dose.',
        ),
      ],
    ),

    // ══════════════════════════════════════
    // POST-HARVEST & STORAGE
    // ══════════════════════════════════════
    KbArticle(
      id: 'postharvest_001',
      title: 'Maize Storage — Preventing Losses',
      category: 'Post-Harvest',
      categoryIcon: '📦',
      summary: 'Up to 30% of maize is lost in storage in Zimbabwe. Correct drying, storage, and treatment prevents these losses.',
      tags: ['maize', 'storage', 'grain', 'weevils', 'hermetic', 'drying'],
      sections: [
        KbSection(
          heading: 'Why Storage Losses Happen',
          body: 'Storage losses in Zimbabwe are caused by:\n\n'
              '1. WEEVILS (Grain Weevil, Larger Grain Borer) — The biggest problem. One female weevil can produce 300 offspring. A small infestation becomes a disaster in 3 months.\n\n'
              '2. MOULDS — Occur when grain moisture is above 13%. Aflatoxin mould is toxic to humans and animals and is a common cause of rejected grain.\n\n'
              '3. RODENTS — Mice and rats. One rat eats 10kg of grain per year and contaminates much more.\n\n'
              '4. HIGH MOISTURE — Grain above 13% moisture will heat, mould, and rot in storage.',
          tip: 'Test grain moisture before storage. Bite a grain — if it dents without breaking, moisture is too high. A sharp clean snap means it is dry enough.',
        ),
        KbSection(
          heading: 'Drying Grain Correctly',
          body: 'FIELD DRYING: Leave maize on the stalk until husks are brown and dry — usually May–June in Zimbabwe. This is the cheapest form of drying.\n\n'
              'SHELLING MOISTURE: Only shell and store when grain is below 13% moisture. Grain stored above 13% will mould.\n\n'
              'SUN DRYING: After shelling, spread grain on a clean tarpaulin in direct sun. Turn regularly. Do not dry on bare ground — it absorbs moisture from soil.\n\n'
              'TARGET MOISTURE: 12–13% for long-term storage. Less than 12% for very long storage (6+ months).\n\n'
              'AVOID: Drying in bags. Bags retain heat and moisture. Always dry in open, thin layers.',
          tip: 'A \$15 grain moisture meter from agricultural suppliers will save you far more in storage losses. It is one of the best investments a farmer can make.',
        ),
        KbSection(
          heading: 'Storage Methods',
          body: 'HERMETIC STORAGE (Best method):\n'
              'Hermetic bags (Triple-layer PICS bags, ZeroFly bags) or hermetic silos seal grain completely from air. Insects and moulds cannot survive without oxygen. No chemical treatment needed. Grain stores 12+ months with minimal losses.\n'
              'Cost: PICS bags \$2–4 each (holds 100kg). Available from Agritex offices and agro-dealers.\n\n'
              'TRADITIONAL GRANARIES (Improved):\n'
              'Raised granaries with rat guards on legs. Line with ash or diatomaceous earth. Seal cracks with mud or cement.\n\n'
              'METAL SILOS:\n'
              'Welded metal silos 1–3 tonne capacity. Sealed airtight. 15–20 year lifespan. Cost \$150–400. Available from FAO/NGO programs in some areas.\n\n'
              'CHEMICAL TREATMENT:\n'
              'Actellic Super dust (Pirimiphos-methyl + Permethrin) 20g per 100kg grain. Mix thoroughly before storing in bags. Protects for 6 months. Only approved chemicals — do not use expired chemicals.',
          tip: 'Always store treated grain separately and label clearly. Never sell or eat grain treated with chemicals without washing thoroughly and after the withholding period.',
        ),
        KbSection(
          heading: 'Rodent Control',
          body: 'PREVENTION:\n'
              '— Raise storage structures on metal rat guards (cone-shaped barriers on legs)\n'
              '— Clear all grass and debris within 3 metres of the granary\n'
              '— Block all holes and cracks larger than 5mm\n'
              '— Keep storage areas clean — no spilled grain on the floor\n\n'
              'CONTROL:\n'
              '— Snap traps (most effective, reusable, no poison risk)\n'
              '— Rodenticides: Zinc phosphide bait or warfarin bait in bait stations — keep out of reach of children and other animals\n'
              '— Cats — effective for rats and mice around grain storage\n\n'
              'IMPORTANT: Never use rodenticides inside grain storage. Contamination of grain is a serious health risk.',
          tip: 'A well-constructed raised metal silo on a concrete base with proper rat guards eliminates almost all rodent losses.',
        ),
      ],
    ),

    KbArticle(
      id: 'postharvest_002',
      title: 'Vegetable Post-Harvest Handling',
      category: 'Post-Harvest',
      categoryIcon: '📦',
      summary: 'Correct handling, grading, and storage of vegetables can increase your income by 30–50% and reduce waste dramatically.',
      tags: ['vegetables', 'grading', 'storage', 'shelf life', 'tomatoes', 'onions'],
      sections: [
        KbSection(
          heading: 'Harvest Timing and Handling',
          body: 'HARVEST IN THE COOL OF THE DAY:\n'
              'Always harvest vegetables early morning (before 9am) or late afternoon. Heat accelerates deterioration. Vegetables harvested in the midday heat have half the shelf life of those harvested cool.\n\n'
              'CLEAN TOOLS:\n'
              'Use clean, sharp knives and pruning shears. Dirty or rusty tools spread disease. Wipe blades with a cloth dipped in diluted bleach (1:10) between plants.\n\n'
              'HANDLE GENTLY:\n'
              'Every bruise is a bacteria entry point. Bruised fruit rots within 24–48 hours. Handle as if you are handling eggs.\n\n'
              'SHADE IMMEDIATELY:\n'
              'After harvest, move produce into shade within 30 minutes. Direct sun causes wilting and accelerated deterioration.',
          tip: 'Field heat is the biggest enemy of shelf life. Get vegetables cool as fast as possible after harvest.',
        ),
        KbSection(
          heading: 'Grading — Why It Matters',
          body: 'Grading means sorting produce by size, quality, and appearance. Graded produce earns 30–100% more than ungraded.\n\n'
              'GRADE A (Supermarket / Export):\n'
              '— Uniform size and colour\n'
              '— No blemishes, bruises, or disease\n'
              '— Correct maturity\n'
              '— Clean, free of soil and debris\n\n'
              'GRADE B (Formal wholesale market):\n'
              '— Slightly variable size\n'
              '— Minor cosmetic blemishes acceptable\n'
              '— Good maturity\n\n'
              'GRADE C (Informal market / roadside):\n'
              '— Irregular size and shape\n'
              '— Visible blemishes\n'
              '— Still good quality for eating\n\n'
              'WASTE / CULLS:\n'
              '— Rotten, diseased, or severely damaged\n'
              '— Remove and compost or feed to livestock immediately\n'
              '— Never mix with saleable grades',
          tip: 'Never mix grades. Buyers immediately downgrade the entire lot if they find even one bad item. Sort ruthlessly.',
        ),
        KbSection(
          heading: 'Storage Conditions by Crop',
          body: 'TOMATOES: Store at 13–18°C. Do not refrigerate below 13°C — chilling injury occurs, causes flavour loss and soft spots. Shelf life 7–14 days. Ethylene gas from tomatoes ripens nearby produce faster.\n\n'
              'ONIONS: Store in a cool (10–15°C), dry, dark, well-ventilated place. Properly cured onions store 3–6 months. Light causes sprouting. Moisture causes rot.\n\n'
              'LEAFY VEGETABLES (Rape, Spinach): Keep moist and cool. Pack in moist hessian or paper to retain moisture. Shelf life only 2–3 days at room temperature. Pre-cool before storage.\n\n'
              'CABBAGE: 0–5°C for long storage (weeks). Room temperature 1–2 weeks maximum. Remove outer leaves to prevent rot spread.\n\n'
              'CARROTS: Remove tops immediately — tops pull moisture from the root. Store cool and humid. Shelf life 3–4 weeks room temperature, 3 months cold storage.\n\n'
              'POTATOES: Cool (8–12°C), dark, dry storage. Light causes greening (solanine — poisonous). Properly cured, good varieties store 4–8 weeks without cold storage.',
          tip: 'A simple evaporative cooler (clay pot cooler or brick-and-sand cooler) can extend vegetable shelf life 2–3 times without electricity. Look up "pot-in-pot cooler Zimbabwe".',
        ),
        KbSection(
          heading: 'Value Addition — Increasing Income',
          body: 'VALUE ADDITION means processing raw produce into products that sell for more. Even simple processing can double your income.\n\n'
              'TOMATO PASTE/PUREE:\n'
              'Grade C tomatoes (too ripe or blemished for fresh market) can be processed into paste or sun-dried tomatoes. Equipment needed: large pots, strainer, jars or sachets.\n\n'
              'DRIED HERBS AND VEGETABLES:\n'
              'Coriander, parsley, chillies, spinach, and onions can be dried and sold as dried products. Solar dryers are cheap to build and effective.\n\n'
              'ONION AND GARLIC POWDER:\n'
              'Small-scale grinding and packaging for the local market. High demand in Zimbabwe. Requires grinder and packaging materials.\n\n'
              'BAOBAB AND MORINGA PRODUCTS:\n'
              'Baobab powder, moringa leaf powder — growing export market. These are found wild in Regions III, IV, V.\n\n'
              'PEANUT BUTTER:\n'
              'Groundnut processing into peanut butter is one of the most accessible and profitable value addition activities in rural Zimbabwe.',
          tip: 'Register your value-added products with the Standards Association of Zimbabwe (SAZ) for access to formal retail markets.',
        ),
      ],
    ),

    // ══════════════════════════════════════
    // MARKETING & SELLING
    // ══════════════════════════════════════
    KbArticle(
      id: 'marketing_001',
      title: 'Where to Sell Your Produce in Zimbabwe',
      category: 'Marketing & Selling',
      categoryIcon: '💰',
      summary: 'Zimbabwe has multiple markets from rural roadside to supermarkets to export. Knowing which market suits your crop and volume is key to maximum profit.',
      tags: ['markets', 'selling', 'Mbare', 'supermarkets', 'contract farming', 'export'],
      sections: [
        KbSection(
          heading: 'Market Channels Overview',
          body: 'Zimbabwe\'s main market channels from lowest to highest price:\n\n'
              '1. ROADSIDE / FARM GATE — Lowest effort, lowest price. Customers come to you. No transport cost. Suitable for small volumes and perishables.\n\n'
              '2. RURAL / GROWTH POINT MARKETS — Higher volume than farm gate. Fixed market days. Price negotiated with traders. No formal requirements.\n\n'
              '3. URBAN WHOLESALE MARKETS (Mbare Musika, Bulawayo Market) — Zimbabwe\'s largest food markets. High volume. Prices set daily by supply and demand. Requires transport and large volumes.\n\n'
              '4. SUPERMARKETS (OK, TM, Pick n Pay, Spar) — Best prices for graded produce. Strict quality requirements. Regular supply required. Payment terms 30–60 days (cash flow risk).\n\n'
              '5. HOTELS AND RESTAURANTS — Premium prices for quality produce. Direct relationships. Require consistency and reliability.\n\n'
              '6. PROCESSING COMPANIES — Fixed contract prices. Reliable off-take but prices may be below market peak. Good for large volumes.\n\n'
              '7. EXPORT — Highest prices but very strict quality, certification, and logistics requirements. Currently growing sector for Zimbabwe.',
          tip: 'Do not rely on one market channel. Diversify — sell Grade A to supermarkets/hotels, Grade B to wholesale markets, Grade C to roadside.',
        ),
        KbSection(
          heading: 'Mbare Musika — How It Works',
          body: 'Mbare Musika in Harare is the largest fresh produce market in Zimbabwe. Tonnes of produce change hands here daily.\n\n'
              'HOW TO SELL AT MBARE:\n'
              '1. Arrive early (3am–6am for best prices before market is flooded)\n'
              '2. Negotiate price with traders (middlemen/magombero) or sell directly to retailers\n'
              '3. No formal registration needed for small-scale selling\n'
              '4. Prices vary hourly — know your minimum price before arriving\n\n'
              'PRICE FACTORS AT MBARE:\n'
              '— Time of arrival (early = higher prices)\n'
              '— Quality and grading\n'
              '— Day of week (Monday and Friday are highest volume)\n'
              '— Season (dry season = higher prices for most vegetables)\n\n'
              'TRANSPORT:\n'
              'Organize transport in advance. ZUPCO buses, hired trucks, or farmer groups sharing transport all reduce per-unit transport costs.\n\n'
              'MIDDLEMEN (Magombero):\n'
              'Middlemen buy from farmers and sell to retailers. They take a margin (20–40%). You can bypass them by selling directly to retailers in the market, but this takes more time and relationships.',
          tip: 'Form a farmer group and transport together. Sharing transport can halve your marketing costs and improve your negotiating position.',
        ),
        KbSection(
          heading: 'Selling to Supermarkets',
          body: 'Supermarkets pay the best prices but have strict requirements.\n\n'
              'REQUIREMENTS:\n'
              '— Consistent supply (weekly or twice-weekly deliveries)\n'
              '— Consistent quality (Grade A only)\n'
              '— Packaging (plastic bags, clamshells, or boxes as specified)\n'
              '— Invoicing and record keeping\n'
              '— Sometimes: Good Agricultural Practices (GAP) certification\n\n'
              'HOW TO APPROACH SUPERMARKETS:\n'
              '1. Start with smaller local supermarkets — easier entry than OK or TM\n'
              '2. Prepare a product sample and pricing sheet\n'
              '3. Ask to meet the Fresh Produce Buyer or Store Manager\n'
              '4. Offer a trial delivery at a competitive price\n'
              '5. Deliver consistently and on time — one failed delivery can end the relationship\n\n'
              'PAYMENT TERMS:\n'
              'Most supermarkets pay on 30–60 day terms. This means you deliver today and get paid in 1–2 months. You need cash flow to manage this gap. Some allow weekly payment for small suppliers.',
          tip: 'Never oversell your capacity to a supermarket. If you promise 500kg/week and deliver 200kg, you lose the account. Start small and grow.',
        ),
        KbSection(
          heading: 'Contract Farming',
          body: 'Contract farming is when a company agrees to buy your crop before you plant it, at a fixed price.\n\n'
              'ADVANTAGES:\n'
              '— Guaranteed market — no need to find buyers at harvest\n'
              '— Sometimes includes input finance (seeds, fertilizer on credit)\n'
              '— Fixed price reduces price risk\n'
              '— Technical support often provided\n\n'
              'DISADVANTAGES:\n'
              '— Fixed price means you miss out if market prices rise above contract price\n'
              '— Strict quality requirements — rejected produce is your loss\n'
              '— Some contracts have unfavorable terms — read carefully\n\n'
              'MAJOR CONTRACT FARMING COMPANIES IN ZIMBABWE:\n'
              '— Tobacco: BAT Zimbabwe, Tribac, Alliance One\n'
              '— Cotton: Cottco, Cargill Cotton, Grafax\n'
              '— Sugar cane: Hippo Valley, Triangle\n'
              '— Seed maize: Seed Co, Pannar\n'
              '— Soybean: National Foods, Olivine\n\n'
              'BEFORE SIGNING:\n'
              'Read the contract carefully. Understand the price formula, quality requirements, and what happens with rejected produce. If possible, have someone else read it too.',
          tip: 'Keep copies of all contracts, delivery notes, and receipts. Disputes are common — documentation protects you.',
        ),
        KbSection(
          heading: 'Pricing Your Produce',
          body: 'Many farmers sell at whatever price is offered. This is how they lose money. Know your costs and set a minimum price.\n\n'
              'CALCULATE YOUR COST OF PRODUCTION:\n'
              '1. Seeds\n'
              '2. Fertilizer and chemicals\n'
              '3. Labour (including your own time)\n'
              '4. Irrigation costs\n'
              '5. Transport to market\n'
              '6. Market levies and packaging\n\n'
              'ADD YOUR PROFIT MARGIN:\n'
              'Cost of production + 20–30% minimum profit margin = your minimum selling price.\n\n'
              'KNOW THE MARKET PRICE BEFORE YOU GO:\n'
              'Phone other farmers or buyers before going to market. Know what the crop is selling for today. If the price is below your minimum, negotiate or find another buyer.\n\n'
              'SEASONAL PRICING:\n'
              'Prices crash when supply is highest (rainy season for most crops). Plant to harvest in the dry season when prices are highest.',
          tip: 'A simple notebook recording all your input costs is more valuable than any other farm management tool. You cannot know if you are profitable without tracking costs.',
        ),
      ],
    ),

    KbArticle(
      id: 'marketing_002',
      title: 'Farmer Groups and Cooperatives',
      category: 'Marketing & Selling',
      categoryIcon: '💰',
      summary: 'Individually, small-scale farmers have little power. As a group, they can negotiate better prices, share transport, and access markets they cannot reach alone.',
      tags: ['cooperatives', 'farmer groups', 'collective marketing', 'savings'],
      sections: [
        KbSection(
          heading: 'Benefits of Farmer Groups',
          body: 'WHY JOIN OR FORM A FARMER GROUP:\n\n'
              'VOLUME: Buyers want large, consistent volumes. One farmer with 200kg of tomatoes has little leverage. Ten farmers with 2,000kg can negotiate directly with supermarkets and processors.\n\n'
              'TRANSPORT: Share truck costs. Reduce per-kg marketing cost dramatically.\n\n'
              'INPUT PURCHASING: Buy seeds, fertilizer, and chemicals in bulk at wholesale prices — often 10–20% cheaper than retail.\n\n'
              'KNOWLEDGE SHARING: Learn from each other\'s successes and failures.\n\n'
              'ACCESS TO PROGRAMS: Government programs, NGO support, and financial institutions prefer to work with organized groups rather than individuals.\n\n'
              'SAVINGS AND CREDIT: Many farmer groups run a savings scheme (VSLA — Village Savings and Loan Association) where members save and borrow from the group fund at low interest.',
          tip: 'The most successful farmer groups have a written constitution, elected officers, and regular meetings with minutes. Informal groups often collapse over money disputes.',
        ),
        KbSection(
          heading: 'How to Register a Cooperative',
          body: 'Cooperatives are legally registered entities that give farmer groups legal status, allowing them to open bank accounts, sign contracts, and access government programs.\n\n'
              'REGISTRATION STEPS:\n'
              '1. Form a group of at least 10 members\n'
              '2. Hold a founding meeting — elect officers (chairperson, secretary, treasurer)\n'
              '3. Draft a constitution (rules of the cooperative)\n'
              '4. Apply to the Cooperative Development Department under the Ministry of Public Service, Labour and Social Welfare\n'
              '5. Pay registration fee (\$20–50)\n'
              '6. Receive Certificate of Registration\n\n'
              'BENEFITS OF REGISTRATION:\n'
              '— Can open a bank account in the cooperative name\n'
              '— Can apply for government grants and NGO funding\n'
              '— Legal protection for members\n'
              '— Access to cooperative training from the ministry\n\n'
              'CONTACT: Cooperative Development Department offices are located in every provincial capital.',
          tip: 'Many NGOs in Zimbabwe (like CARE, SNV, Practical Action) support farmer group formation. Ask your local Agritex office who is active in your area.',
        ),
      ],
    ),

    // ══════════════════════════════════════
    // GOVERNMENT PROGRAMS
    // ══════════════════════════════════════
    KbArticle(
      id: 'gov_001',
      title: 'Agritex — Your Free Extension Service',
      category: 'Government Programs',
      categoryIcon: '🏛️',
      summary: 'Agritex (Agricultural Technical and Extension Services) is the government\'s free advisory service for farmers. Most Zimbabweans do not use it fully.',
      tags: ['Agritex', 'extension', 'government', 'training', 'demonstration'],
      sections: [
        KbSection(
          heading: 'What Agritex Provides',
          body: 'Agritex is the Agricultural Technical and Extension Services department under the Ministry of Lands, Agriculture, Fisheries, Water and Rural Development.\n\n'
              'FREE SERVICES:\n'
              '— Crop production advice (planting dates, variety selection, fertilizer recommendations)\n'
              '— Soil testing and interpretation\n'
              '— Pest and disease identification and control advice\n'
              '— Livestock management advice\n'
              '— Conservation agriculture training\n'
              '— Farmer field school facilitation\n'
              '— Market linkage support\n'
              '— Registration assistance for farmer groups\n\n'
              'DEMONSTRATION PLOTS:\n'
              'Agritex maintains demonstration plots at district offices showing best practices for local conditions. Visit your nearest Agritex office to see these.',
          tip: 'Every ward in Zimbabwe has an assigned Agritex extension officer. Find out who yours is and get their phone number. This is a free resource most farmers underuse.',
        ),
        KbSection(
          heading: 'How to Access Agritex Services',
          body: 'CONTACT POINTS:\n'
              '— Ward Level: Extension Officer (EO) — visits farmers, holds field days\n'
              '— District Level: Subject Matter Specialist (SMS) — expert in specific crops or livestock\n'
              '— Provincial Level: Provincial Agricultural Officer (PAO) — overall coordination\n\n'
              'FARMER FIELD SCHOOLS (FFS):\n'
              'Agritex facilitates Farmer Field Schools where 20–25 farmers learn together through a season of practical work on a demonstration plot. Participants learn by doing — not just by listening.\n\n'
              'FIELD DAYS:\n'
              'Regular demonstrations of new technologies, varieties, and practices. Announced through village heads and community notice boards.\n\n'
              'SOIL TESTING:\n'
              'Agritex can arrange soil testing through the Soils Productivity Research Laboratory (SPRL) in Harare. Cost is subsidized. Results come with fertilizer recommendations for your specific soil.',
          tip: 'If your local Agritex officer does not visit regularly, go to the district office and ask for support. You have a right to these free services.',
        ),
        KbSection(
          heading: 'Key Government Agricultural Programs',
          body: 'PFUMVUDZA / INTWASA (Conservation Agriculture):\n'
              'National program promoting conservation agriculture with planting basins, minimum tillage, and crop rotation. Extension support, demonstrations, and sometimes subsidized inputs available.\n\n'
              'COMMAND AGRICULTURE:\n'
              'Government supports farmers with inputs (fertilizer, seed) on credit, recovered at harvest. Check current status and eligibility with Agritex.\n\n'
              'SMALLHOLDER IRRIGATION SCHEME SUPPORT:\n'
              'Government and development partners rehabilitate and support smallholder irrigation schemes. Contact provincial Agritex office.\n\n'
              'WOMEN AND YOUTH IN AGRICULTURE:\n'
              'Programs targeting women and youth farmers for training, inputs, and market access. Contact the Women in Agriculture Development (WAD) section of Agritex.',
          tip: 'Program availability changes yearly. Always verify current program status with your local Agritex office rather than relying on old information.',
        ),
      ],
    ),

    KbArticle(
      id: 'gov_002',
      title: 'GMB — Grain Marketing Board',
      category: 'Government Programs',
      categoryIcon: '🏛️',
      summary: 'The GMB is Zimbabwe\'s strategic grain reserve. It buys maize, wheat, sorghum, and sunflower from farmers at set prices. Understanding how it works protects you.',
      tags: ['GMB', 'grain marketing', 'maize price', 'wheat', 'payment'],
      sections: [
        KbSection(
          heading: 'What is the GMB?',
          body: 'The Grain Marketing Board (GMB) is a government parastatal that:\n\n'
              '1. Maintains the National Strategic Grain Reserve (food security)\n'
              '2. Buys grain from farmers at announced producer prices\n'
              '3. Sells grain to millers and processors\n'
              '4. Has depots in major agricultural districts across Zimbabwe\n\n'
              'CROPS GMB BUYS:\n'
              '— Maize (main crop)\n'
              '— Wheat\n'
              '— Sorghum / Rapoko\n'
              '— Sunflower\n'
              '— Soybean (some seasons)\n\n'
              'PRODUCER PRICES:\n'
              'The GMB announces producer prices at the start of each season. These are the minimum prices GMB will pay. Private buyers may pay more or less.\n\n'
              'PAYMENT:\n'
              'GMB payment has historically been slow. Payment terms and currency (USD vs ZWL) vary by season and government policy. Confirm current payment terms before delivering.',
          tip: 'Never deliver to the GMB without confirming current payment terms, currency, and timelines. Payment delays have been a major issue in past seasons.',
        ),
        KbSection(
          heading: 'How to Sell to the GMB',
          body: 'REGISTRATION:\n'
              '1. Register at your nearest GMB depot with your national ID and farm details\n'
              '2. Receive a Farmer Registration Number\n\n'
              'DELIVERY PROCESS:\n'
              '1. Dry grain to below 12.5% moisture\n'
              '2. Transport to nearest GMB depot\n'
              '3. Grain is weighed, sampled, and graded\n'
              '4. Rejection causes: high moisture, aflatoxin, foreign material, damaged grain\n'
              '5. Accepted grain is ticketed — you receive a delivery receipt\n'
              '6. Payment processed according to current terms\n\n'
              'QUALITY REQUIREMENTS:\n'
              '— Moisture: maximum 12.5%\n'
              '— Foreign matter: maximum 1%\n'
              '— Damaged grain: maximum 5%\n'
              '— No aflatoxin above allowable limit\n'
              '— Free from live insects\n\n'
              'GMB DEPOT LOCATIONS:\n'
              'Major depots in: Harare, Bulawayo, Mutare, Gweru, Masvingo, Bindura, Marondera, Chinhoyi, Zvishavane, and most provincial and district centres.',
          tip: 'Have your grain tested for moisture and aflatoxin before delivery to avoid rejection. Some agro-dealers and Agritex offices have test kits.',
        ),
        KbSection(
          heading: 'Private Grain Buyers vs GMB',
          body: 'Private grain buyers (millers, traders) often offer competitive alternatives to the GMB.\n\n'
              'PRIVATE BUYERS INCLUDE:\n'
              '— National Foods (large miller)\n'
              '— Grain millers in your district\n'
              '— Grain traders and aggregators\n'
              '— Livestock feed manufacturers\n\n'
              'ADVANTAGES OF PRIVATE BUYERS:\n'
              '— Often pay faster than GMB\n'
              '— May pay in USD or offer better rates\n'
              '— May buy at farm gate (no transport cost)\n'
              '— Flexible quality requirements sometimes\n\n'
              'DISADVANTAGES:\n'
              '— Prices may be lower than GMB\n'
              '— No guaranteed off-take — they buy when they need\n'
              '— Some traders are unreliable with payment\n\n'
              'ADVICE: Compare GMB price and payment terms with private buyers every season. The best option changes year to year.',
          tip: 'Always get a written receipt from any buyer — private or GMB. A delivery note with weight, price, and date is your legal proof of sale.',
        ),
      ],
    ),

    KbArticle(
      id: 'gov_003',
      title: 'Financial Support for Farmers',
      category: 'Government Programs',
      categoryIcon: '🏛️',
      summary: 'Grants, loans, and financial support available to Zimbabwean farmers from government and development organizations.',
      tags: ['loans', 'grants', 'finance', 'AFC', 'microfinance', 'subsidies'],
      sections: [
        KbSection(
          heading: 'Agricultural Finance Corporation (AFC)',
          body: 'The Agricultural Finance Corporation (AFC) is the government\'s agricultural development bank, providing loans to farmers.\n\n'
              'AFC PRODUCTS:\n'
              '— Production loans for inputs (seed, fertilizer, chemicals)\n'
              '— Equipment loans (irrigation, tractors, implements)\n'
              '— Land development loans\n\n'
              'ELIGIBILITY:\n'
              '— Must be a Zimbabwean citizen\n'
              '— Must have offer letter or lease agreement for the land\n'
              '— Must have a viable farming plan\n'
              '— Credit history checked\n\n'
              'APPLICATION:\n'
              'Visit nearest AFC branch with: National ID, offer letter/lease, farm plan, previous season records if available.\n\n'
              'AFC OFFICES:\n'
              'Harare (Head Office), Bulawayo, Mutare, Masvingo, Gweru, Chinhoyi, Bindura, Marondera.',
          tip: 'Prepare a simple one-page farm business plan before approaching AFC. It dramatically improves your application success rate.',
        ),
        KbSection(
          heading: 'NGO and Development Partner Support',
          body: 'Many international and local NGOs provide support to Zimbabwean farmers. Programs change frequently — check with your local Agritex office for current programs.\n\n'
              'ACTIVE ORGANIZATIONS (programs vary by year and area):\n'
              '— FAO Zimbabwe: Food security, input support, conservation agriculture\n'
              '— WFP: Food assistance and market linkages\n'
              '— USAID/ZIMVAC: Food security programs\n'
              '— SNV: Horticulture value chains, sanitation\n'
              '— CARE Zimbabwe: Women in agriculture, savings groups\n'
              '— Practical Action: Appropriate technology, market linkages\n'
              '— Heifer International: Livestock programs\n'
              '— World Vision: Community development, agriculture\n\n'
              'HOW TO ACCESS:\n'
              '— Ask your Agritex extension officer about current programs\n'
              '— Contact your village head or ward councillor\n'
              '— Visit district social welfare office\n'
              '— Listen to Radio Zimbabwe and ZBC for program announcements',
          tip: 'NGO programs often require you to be part of a registered farmer group. This is another reason to join or form a group.',
        ),
      ],
    ),

    // ══════════════════════════════════════
    // PEST & DISEASE REFERENCE
    // ══════════════════════════════════════
    KbArticle(
      id: 'pest_001',
      title: 'Fall Armyworm — Identification and Control',
      category: 'Pest & Disease',
      categoryIcon: '🐛',
      summary: 'Fall Armyworm (Spodoptera frugiperda) arrived in Zimbabwe in 2016 and is now the most destructive maize pest. Early detection and rapid response saves crops.',
      tags: ['fall armyworm', 'FAW', 'maize', 'caterpillar', 'pest'],
      sections: [
        KbSection(
          heading: 'Identification',
          body: 'ADULT MOTH:\n'
              '— Wingspan 3–4cm\n'
              '— Greyish-brown front wings, white hindwings\n'
              '— Flies at night — hard to see\n\n'
              'EGGS:\n'
              '— Laid in masses of 100–200 on leaf surface\n'
              '— Cream to grey colour, covered with fluffy scales\n\n'
              'LARVAE (caterpillar — the damaging stage):\n'
              '— 6 instars (stages), grows from 1mm to 40mm\n'
              '— Colour: green when small, darker (brown to black) when large\n'
              '— KEY IDENTIFICATION: Inverted Y shape on head capsule\n'
              '— Four spots forming a square on second-to-last segment\n'
              '— Feeds inside maize whorl (funnel) — look for ragged holes and frass (sawdust-like droppings)\n\n'
              'DAMAGE:\n'
              '— Small larvae: windowing (transparent patches) on leaves\n'
              '— Large larvae: ragged holes, destruction of growing point\n'
              '— Ear damage: larvae bore into cob, destroying grain',
          tip: 'The Y-mark on the head capsule is the definitive identification mark of Fall Armyworm. Learn to recognize it — other caterpillars look similar.',
        ),
        KbSection(
          heading: 'Scouting',
          body: 'WHEN TO SCOUT:\n'
              'From emergence until tasseling. Most critical: V3 to V8 (3–8 leaves).\n\n'
              'HOW TO SCOUT:\n'
              '1. Walk W or X pattern across the field\n'
              '2. Check 20 plants per 0.5ha (40 plants/ha)\n'
              '3. Check the whorl (funnel) of each plant — pull leaves apart slightly\n'
              '4. Look for: eggs, small larvae, windowing damage, frass\n'
              '5. Record number of infested plants\n\n'
              'ACTION THRESHOLD:\n'
              '— Scout 3 times per week in high-risk periods\n'
              '— Treat when 20–30% of plants are infested (especially at V3–V6)\n'
              '— At V7 and beyond, plants can tolerate more damage\n\n'
              'TIME OF SCOUTING:\n'
              'Early morning (6–9am) when larvae are active. Larvae hide deep in whorl during hot daytime hours.',
          tip: 'Scout early morning when larvae are in the whorl and most vulnerable to contact insecticides. Afternoon scouting often underestimates infestation.',
        ),
        KbSection(
          heading: 'Control Methods',
          body: 'BIOLOGICAL CONTROL (First choice where available):\n'
              '— Bacillus thuringiensis (Bt) — a bacteria toxic to caterpillars, safe to humans and beneficial insects. Apply to whorl. Most effective on young larvae (instar 1–3).\n'
              '— SpinTor/Tracer (Spinosad) — derived from soil bacteria. Effective and low toxicity to non-target organisms.\n\n'
              'CHEMICAL CONTROL:\n'
              'Apply into the whorl (funnel) — not on leaves. Emulsifiable concentrates penetrate better than wettable powders.\n'
              '— Lambda-cyhalothrin (Karate) 0.5L/ha\n'
              '— Chlorantraniliprole (Coragen) 0.3L/ha — most effective, also systemic\n'
              '— Emamectin benzoate (Proclaim) 0.5kg/ha\n'
              '— Lufenuron (Mesurol) — insect growth regulator, best on eggs and young larvae\n\n'
              'AVOID: Pyrethroids alone (resistance has developed). Blanket spraying without scouting (wastes money and kills beneficial insects).\n\n'
              'APPLICATION:\n'
              'Mix at correct rate. Apply into whorl using knapsack sprayer with whorl applicator nozzle. Early morning is best. Do not spray if rain expected within 2 hours.',
          tip: 'Sand or wood ash mixed with Bt and applied directly into the whorl is an effective low-cost control used by many smallholder farmers.',
        ),
        KbSection(
          heading: 'Prevention',
          body: 'EARLY PLANTING:\n'
              'Plant at first rains. Early-planted maize is more advanced when FAW populations peak in January–February. More tolerant of damage at later growth stages.\n\n'
              'PUSH-PULL (Intercropping):\n'
              'Plant Napier grass (Pennisetum purpureum) as border crop. Plant Desmodium between maize rows. This intercropping system repels FAW moths and attracts natural enemies. Promoted by CIMMYT and ICIPE.\n\n'
              'NATURAL ENEMIES:\n'
              'Birds (especially cattle egrets), spiders, parasitic wasps, and ants prey on FAW larvae. Avoid broad-spectrum insecticides that kill these. A field with good natural enemies requires less chemical intervention.\n\n'
              'LIGHT TRAPS:\n'
              'FAW moths are attracted to light at night. A simple light trap (white light over a water pan with oil) can help monitor and reduce adult populations.',
          tip: 'FAW does not go away. Build scouting and early response into your seasonal routine every year from crop emergence.',
        ),
      ],
    ),

    KbArticle(
      id: 'pest_002',
      title: 'Striga (Witchweed) — The Hidden Yield Thief',
      category: 'Pest & Disease',
      categoryIcon: '🐛',
      summary: 'Striga is a parasitic weed that attaches to maize roots underground before emerging. By the time you see it, serious damage is done. Prevention is the only effective strategy.',
      tags: ['Striga', 'witchweed', 'parasitic weed', 'maize', 'soil'],
      sections: [
        KbSection(
          heading: 'What is Striga?',
          body: 'Striga asiatica and Striga hermonthica are parasitic flowering plants that attach to the roots of maize, sorghum, and millet. They steal water, nutrients, and sugars directly from the host plant\'s root system.\n\n'
              'DAMAGE:\n'
              '— A single Striga plant can cause 10–30% yield loss\n'
              '— Heavy infestations cause 50–100% yield loss\n'
              '— Underground damage begins before the plant emerges — by emergence, 40+ days of damage has occurred\n'
              '— Each Striga plant produces 50,000–500,000 seeds that remain viable in soil for 15–20 years\n\n'
              'WHERE IT IS FOUND:\n'
              '— Mainly in Regions III, IV, V (drier areas)\n'
              '— Sandy, low-fertility soils most affected\n'
              '— Mashonaland East, Manicaland, Masvingo, Matabeleland North and South',
          tip: 'Never allow Striga to flower and set seed. Each plant allowed to seed makes the problem 500,000 times worse. Remove and burn before flowering.',
        ),
        KbSection(
          heading: 'Control Strategies',
          body: 'PREVENTION (most important):\n'
              '— Do not move soil or grain from infested fields without cleaning equipment\n'
              '— Plant before Striga seeds germinate (early planting)\n'
              '— Use certified clean seed — never farm-saved seed from infested fields\n\n'
              'IMAZAPYR SEED COATING (Imazapyr-Resistant/IR Maize):\n'
              'Seeds of IR maize varieties are coated with Imazapyr herbicide. When Striga attaches to these roots, it absorbs the herbicide and dies. Most effective method available to smallholder farmers.\n'
              'Varieties: DTMV1-IR, SC403 IR. Available from Seed Co and Agritex.\n\n'
              'HAND PULLING:\n'
              'Pull Striga before flowering. DO NOT compost — burn. Hand pulling alone does not reduce the soil seed bank but prevents increase.\n\n'
              'NITROGEN FERTILIZER:\n'
              'High soil nitrogen suppresses Striga germination. Apply CAN/AN as top dress. Compost and manure also help.\n\n'
              'ROTATION WITH NON-HOST CROPS:\n'
              'Plant soybeans, groundnuts, or sunflower for 2–3 seasons. These cause suicidal germination of Striga seeds (seeds germinate but die — no host). Reduces soil seed bank over time.',
          tip: 'IR maize varieties with Imazapyr seed coating are the single most effective smallholder tool against Striga. Ask your Agritex officer or seed supplier about availability.',
        ),
      ],
    ),

    // ══════════════════════════════════════
    // CLIMATE & SEASONS
    // ══════════════════════════════════════
    KbArticle(
      id: 'climate_001',
      title: 'Zimbabwe\'s Agricultural Seasons Explained',
      category: 'Climate & Seasons',
      categoryIcon: '🌦️',
      summary: 'Zimbabwe has two main seasons — rainy and dry. Understanding them determines when to plant, irrigate, and market your produce.',
      tags: ['seasons', 'rainfall', 'climate', 'planning', 'ENSO', 'El Nino'],
      sections: [
        KbSection(
          heading: 'The Three Agricultural Seasons',
          body: 'SUMMER / RAINY SEASON (October–April):\n'
              'The main crop season. Rain-fed crops. High temperature (25–35°C). High humidity. Main risks: flooding, pest pressure, late blight.\n'
              'Main crops: Maize, tobacco, cotton, sorghum, groundnuts, sunflower, soybeans.\n\n'
              'COOL DRY SEASON (May–August):\n'
              'Low temperatures (5–18°C). Frost risk in high-altitude areas (Region I) in June–July. Minimal rainfall. Irrigation required for all crops.\n'
              'Main crops: Wheat, barley, winter vegetables (lettuce, spinach, cabbage, onions, carrots), potatoes.\n'
              'BEST SEASON for horticultural crops — highest prices, lowest disease pressure.\n\n'
              'HOT DRY SEASON (September–October):\n'
              'Hottest and driest period. Pre-season land preparation. High evapotranspiration. Irrigation expensive. Some farmers grow heat-tolerant vegetables (tomatoes, peppers, butternut) for the dry season market.',
          tip: 'The cool dry season (May–August) is the most profitable time for vegetables — lower disease, less competition, higher prices. Invest in irrigation to exploit this window.',
        ),
        KbSection(
          heading: 'Zimbabwe\'s Rainfall Patterns',
          body: 'ANNUAL RAINFALL DISTRIBUTION:\n'
              '— Region I (Eastern Highlands): 1,000–1,500mm/year. Most reliable.\n'
              '— Region IIa (Mashonaland): 750–1,000mm/year. Reliable. Best for maize.\n'
              '— Region IIb: 650–800mm/year. Good for most crops.\n'
              '— Region III: 500–700mm/year. Semi-reliable. Conservation agriculture essential.\n'
              '— Region IV: 400–600mm/year. Unreliable. Drought-tolerant crops preferred.\n'
              '— Region V: 300–450mm/year. Very low and unreliable. Drought-tolerant crops only.\n\n'
              'SEASONAL ONSET:\n'
              'The rainy season typically begins: October–November in Region I and IIa. November–December in Regions III–V.\n\n'
              'FALSE STARTS:\n'
              'Early rains in October are often false starts. Wait for 25mm or more rain in 3 days before planting — or at least two good rains within 10 days. False starts followed by a dry spell (dry spell after planting) kill seedlings and waste seed and fertilizer.',
          tip: 'Never plant after just one good rain. Wait for a second confirming rain within 10 days. A dry spell after planting is more costly than a late start.',
        ),
        KbSection(
          heading: 'El Niño, La Niña, and Drought',
          body: 'El Niño and La Niña are climate phenomena that affect Zimbabwe\'s rainfall every 3–7 years.\n\n'
              'EL NIÑO (drought conditions for Zimbabwe):\n'
              '— Reduced rainfall, especially in southern and central Zimbabwe\n'
              '— Higher temperatures\n'
              '— Higher risk of total crop failure in Regions III–V\n'
              '— Higher risk of mid-season dry spells\n\n'
              'LA NIÑA (above-normal rainfall):\n'
              '— Higher rainfall, especially in southern Zimbabwe\n'
              '— Higher risk of flooding in vlei areas\n'
              '— Better season for dryland farmers\n\n'
              'WHAT TO DO IN AN EL NIÑO YEAR:\n'
              '— Plant drought-tolerant varieties (DT maize, sorghum, millet, cowpeas)\n'
              '— Plant early to use early rains\n'
              '— Reduce planted area — plant less but manage it better\n'
              '— Invest in water harvesting (tied ridges, planting basins)\n'
              '— Plant legumes that can survive dry spells better than maize\n\n'
              'SOURCE: Zimbabwe Meteorological Services Department announces seasonal forecasts in October each year. Listen on ZBC Radio.',
          tip: 'Subscribe to ZimMet (Zimbabwe Meteorological Services) WhatsApp updates or listen to their seasonal forecast in October. Plan your crop mix based on the forecast.',
        ),
        KbSection(
          heading: 'Planning Your Farming Calendar',
          body: 'A BASIC ZIMBABWE FARMING CALENDAR:\n\n'
              'AUGUST–SEPTEMBER:\n'
              '— Plan crops and buy inputs early (before prices rise)\n'
              '— Repair irrigation equipment\n'
              '— Land preparation (plowing, liming)\n\n'
              'OCTOBER–NOVEMBER:\n'
              '— Plant summer crops at first reliable rains\n'
              '— Continue vegetable irrigation for dry season market\n\n'
              'DECEMBER–FEBRUARY:\n'
              '— Main crop management (weeding, fertilizing, scouting)\n'
              '— Peak pest and disease pressure — scout intensively\n\n'
              'MARCH–APRIL:\n'
              '— Begin summer crop harvest (early maize, vegetables)\n'
              '— Cure and store grain carefully\n\n'
              'MAY–JULY:\n'
              '— Harvest and store summer crops\n'
              '— Plant cool-season vegetables and wheat\n'
              '— Best window for horticultural market\n\n'
              'AUGUST:\n'
              '— Harvest wheat and late winter vegetables\n'
              '— Begin planning next season\n'
              '— Soil testing and lime application',
          tip: 'Write your farming calendar on paper and pin it where you see it every day. Farming by calendar prevents costly late decisions.',
        ),
      ],
    ),
  ];

  // ─────────────────────────────────────────
  // GLOSSARY
  // ─────────────────────────────────────────
  static const List<KbGlossaryTerm> glossary = [
    KbGlossaryTerm(term: 'Agro-ecological Region', definition: 'A zone defined by rainfall, temperature, and soil characteristics that determines which crops can be grown. Zimbabwe has 5 regions (I–V).', example: 'Region IIa is best for maize. Region V is only suitable for drought-tolerant crops.'),
    KbGlossaryTerm(term: 'Basal Fertilizer', definition: 'Fertilizer applied at planting time, usually placed in the planting hole or furrow beside the seed. Provides nutrients for early plant establishment.', example: 'Compound D at 200kg/ha is a common basal fertilizer for maize.'),
    KbGlossaryTerm(term: 'Brix', definition: 'A measure of sugar content in fruit or vegetables. Higher Brix means sweeter, better-quality produce that fetches higher market prices.', example: 'Supermarkets may test tomato Brix — target above 4.5.'),
    KbGlossaryTerm(term: 'CAN (Calcium Ammonium Nitrate)', definition: 'A nitrogen fertilizer containing 26% nitrogen plus calcium. Used as a top-dress fertilizer applied 4–6 weeks after planting.', example: 'Apply 150–200kg/ha CAN to maize at knee-high stage.'),
    KbGlossaryTerm(term: 'Conservation Agriculture (CA)', definition: 'A farming system based on three principles: minimum soil disturbance, permanent soil cover, and crop rotation. Improves yields and soil health over time.', example: 'CA uses planting basins instead of full plowing.'),
    KbGlossaryTerm(term: 'Contract Farming', definition: 'An agreement between a farmer and a buyer made before planting, specifying the crop, quantity, quality, and price. Reduces market risk.', example: 'Cottco offers contract farming for cotton growers in Regions III–V.'),
    KbGlossaryTerm(term: 'Cover Crop', definition: 'A crop grown primarily to protect and improve the soil rather than for sale. Usually a legume that fixes nitrogen.', example: 'Mucuna (velvet bean) grown as a cover crop fixes nitrogen and suppresses weeds.'),
    KbGlossaryTerm(term: 'Day-Neutral Variety', definition: 'A plant variety that flowers and fruits regardless of day length. Allows planting at any time of year.', example: 'Day-neutral onion varieties can be planted any month, unlike long-day or short-day varieties.'),
    KbGlossaryTerm(term: 'Determinate Variety', definition: 'A plant variety that sets fruit all at once and stops growing after fruiting. Allows one-time mechanical harvest.', example: 'Processing tomato varieties are usually determinate — all fruit ripens at once.'),
    KbGlossaryTerm(term: 'Earthing Up (Hilling)', definition: 'Pulling soil from between rows up around the base of plants. Done for potatoes (prevents greening), maize (supports stalks), and some vegetables.', example: 'Earth up potatoes when plants are 25cm tall to prevent green tubers.'),
    KbGlossaryTerm(term: 'El Niño', definition: 'A climate pattern that causes reduced rainfall and drought conditions in Zimbabwe and southern Africa, occurring every 3–7 years.', example: 'The 2015–16 El Niño caused major crop failures in Zimbabwe\'s Regions III–V.'),
    KbGlossaryTerm(term: 'Extension Officer (EO)', definition: 'A government agricultural advisor employed by Agritex who provides free technical support to farmers in a specific ward.', example: 'Your ward Extension Officer can advise on fertilizer rates, pest control, and variety selection — free of charge.'),
    KbGlossaryTerm(term: 'F1 Hybrid', definition: 'First generation hybrid seed produced by crossing two parent varieties. F1 hybrids are high-yielding but seeds cannot be saved — must buy new seed each season.', example: 'SC403 maize is an F1 hybrid — do not save seed from it.'),
    KbGlossaryTerm(term: 'Fertigation', definition: 'Applying fertilizers dissolved in irrigation water, typically through a drip irrigation system. Efficient and effective for high-value crops.', example: 'Tomato growers use fertigation to deliver precise nutrition directly to roots.'),
    KbGlossaryTerm(term: 'Germination Rate', definition: 'The percentage of seeds in a batch that germinate and emerge. Good seed should have 85%+ germination.', example: 'Test germination by placing 10 seeds on moist paper towel — count how many sprout in 7 days.'),
    KbGlossaryTerm(term: 'Green Manure', definition: 'A crop that is grown and then cut and incorporated into the soil while still green to improve fertility and organic matter.', example: 'Sunhemp (Crotalaria juncea) grown and plowed in is an excellent green manure.'),
    KbGlossaryTerm(term: 'Hardening Off', definition: 'The process of gradually exposing greenhouse or shade-grown seedlings to outdoor conditions before transplanting, to reduce transplant shock.', example: 'Move tomato seedlings from greenhouse to dappled shade for 5–7 days before transplanting.'),
    KbGlossaryTerm(term: 'Integrated Pest Management (IPM)', definition: 'A holistic approach to pest control that combines biological, cultural, physical, and chemical methods to minimize pesticide use and costs.', example: 'IPM uses scouting, economic thresholds, and targeted spraying rather than calendar-based spraying.'),
    KbGlossaryTerm(term: 'Intercropping', definition: 'Growing two or more crops together in the same field at the same time. Can improve yields, reduce pests, and provide income diversity.', example: 'Maize + cowpea intercropping — the cowpea fixes nitrogen and provides food and income.'),
    KbGlossaryTerm(term: 'La Niña', definition: 'A climate pattern opposite to El Niño — causes above-normal rainfall in Zimbabwe and southern Africa.', example: 'La Niña seasons (like 2020–21) often bring flooding in low-lying areas.'),
    KbGlossaryTerm(term: 'Liming', definition: 'Applying agricultural lime (calcium carbonate) to acidic soil to raise the pH and improve nutrient availability.', example: 'Apply 1–2 tonnes of agricultural lime per hectare on sandy soils with pH below 5.5.'),
    KbGlossaryTerm(term: 'Mulching', definition: 'Covering the soil surface around plants with organic material (crop residues, grass, or plastic) to retain moisture, suppress weeds, and regulate temperature.', example: 'Maize stover used as mulch in CA systems reduces water requirements by 30%.'),
    KbGlossaryTerm(term: 'Mycorrhiza', definition: 'Beneficial fungi that form a symbiotic relationship with plant roots, extending the root network and improving water and nutrient uptake.', example: 'Mycorrhizal fungi are damaged by excessive phosphate fertilizer and soil fumigation.'),
    KbGlossaryTerm(term: 'N, P, K', definition: 'The three primary plant nutrients: Nitrogen (N) for leaf growth, Phosphorus (P) for roots and energy, Potassium (K) for fruit quality and disease resistance.', example: 'The three numbers on a fertilizer bag (e.g., 7:14:7) represent N, P, and K percentages.'),
    KbGlossaryTerm(term: 'Open-Pollinated Variety (OPV)', definition: 'A variety that breeds true — seeds can be saved and replanted. Lower yielding than F1 hybrids but seeds are free each season.', example: 'Some sorghum and cowpea varieties are OPVs — farmers can save and replant seed legally.'),
    KbGlossaryTerm(term: 'pH', definition: 'A measure of soil acidity or alkalinity on a scale of 1–14. Below 7 is acidic, above 7 is alkaline. Most crops prefer pH 5.5–6.5.', example: 'Zimbabwe\'s sandy soils often have pH 4.5–5.5 — too acidic for maize without liming.'),
    KbGlossaryTerm(term: 'Phenology', definition: 'The timing of biological events in plants, such as germination, flowering, and fruiting, in relation to climate and season.', example: 'Maize phenology in Region IIa: planting (Oct–Nov), tasseling (Jan), harvest (Apr–May).'),
    KbGlossaryTerm(term: 'Roguing', definition: 'Removing diseased, off-type, or inferior plants from a crop to prevent disease spread and maintain quality.', example: 'Rogue out virus-infected tomato plants immediately — they infect neighbours through whitefly.'),
    KbGlossaryTerm(term: 'Seed Priming', definition: 'Soaking seeds in water or a nutrient solution before planting to improve and speed up germination.', example: 'Soaking maize seed in water for 8 hours before planting can improve germination speed by 2–3 days.'),
    KbGlossaryTerm(term: 'Soil Structure', definition: 'The arrangement of soil particles into aggregates. Good soil structure allows roots to penetrate, water to drain, and air to circulate.', example: 'Over-plowing destroys soil structure. CA practices rebuild it over 3–5 years.'),
    KbGlossaryTerm(term: 'Sucker', definition: 'A side shoot that grows from the axil (join) between the main stem and a leaf. In tomatoes, suckers are usually removed to focus the plant\'s energy.', example: 'Remove tomato suckers weekly when they are small (under 5cm) for best results.'),
    KbGlossaryTerm(term: 'Thinning', definition: 'Removing excess seedlings to achieve the correct plant spacing. Thinned plants are usually the smallest or weakest.', example: 'Thin maize to one plant per station at V2 (2-leaf) stage. Never thin after V4.'),
    KbGlossaryTerm(term: 'Top Dressing', definition: 'Applying fertilizer to growing crops after establishment, usually broadcast between rows or placed beside plant stems.', example: 'Top dress maize with CAN at knee-high stage (V6) — 150–200kg/ha.'),
    KbGlossaryTerm(term: 'Transplanting Shock', definition: 'The temporary wilting and stress that seedlings experience when moved from nursery to field. Minimized by hardening off, correct timing, and thorough watering.', example: 'Transplant tomatoes in late afternoon to reduce heat-related shock.'),
    KbGlossaryTerm(term: 'Urea (46%N)', definition: 'A high-nitrogen fertilizer. Most concentrated and often cheapest per kg of nitrogen. Must be incorporated into soil — volatilizes (loses nitrogen as ammonia gas) if left on surface.', example: 'Never apply urea to the soil surface without incorporation — you lose 30–50% of the nitrogen.'),
    KbGlossaryTerm(term: 'Wilt', definition: 'The drooping or collapsing of plant tissue due to water stress, disease, or root damage. Wilting in the morning is usually disease — wilting in afternoon is usually water stress.', example: 'Fusarium wilt in tomatoes causes permanent wilting even when soil is moist — the vascular system is blocked.'),
    KbGlossaryTerm(term: 'Yield Gap', definition: 'The difference between the maximum potential yield of a crop and the actual yield achieved. Zimbabwe\'s maize yield gap is among the largest in Africa.', example: 'Maize potential yield in Region IIa: 10–12t/ha. Average smallholder yield: 0.8–1.2t/ha. The gap is the opportunity.'),
    KbGlossaryTerm(term: 'Zimvac', definition: 'Zimbabwe Vulnerability Assessment Committee. Conducts annual surveys to assess food security and vulnerability of rural households. Reports used for targeting food aid.', example: 'Zimvac 2023 report found 3.8 million rural Zimbabweans food insecure.'),
  ];

  // ─────────────────────────────────────────
  // SEARCH
  // ─────────────────────────────────────────
  static List<dynamic> search(String query) {
    if (query.trim().length < 2) return [];
    final q = query.toLowerCase();
    final results = <dynamic>[];

    // Search articles
    for (final article in articles) {
      if (article.title.toLowerCase().contains(q) ||
          article.summary.toLowerCase().contains(q) ||
          article.tags.any((t) => t.toLowerCase().contains(q)) ||
          article.category.toLowerCase().contains(q) ||
          article.sections.any((s) =>
              s.heading.toLowerCase().contains(q) ||
              s.body.toLowerCase().contains(q))) {
        results.add(article);
      }
    }

    // Search glossary
    for (final term in glossary) {
      if (term.term.toLowerCase().contains(q) ||
          term.definition.toLowerCase().contains(q)) {
        results.add(term);
      }
    }

    return results;
  }

  static List<KbArticle> getArticlesByCategory(String category) {
    return articles.where((a) => a.category == category).toList();
  }
}