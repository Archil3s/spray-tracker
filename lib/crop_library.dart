// Crop family library foundation for Spray Tracker.
//
// Flow: Family -> Vegetable -> Optional variety -> Add to bed.
// Icons point to custom glossy app-ready SVG assets.

class VegetableFamilyDefinition {
  const VegetableFamilyDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
  });
  final String id;
  final String name;
  final String description;
  final String iconPath;
}

class VegetableDefinition {
  const VegetableDefinition({
    required this.id,
    required this.familyId,
    required this.name,
    required this.iconPath,
    required this.commonPests,
    required this.commonDiseases,
    required this.preventativeTips,
    required this.maintenanceTips,
    this.varieties = const [],
  });
  final String id;
  final String familyId;
  final String name;
  final String iconPath;
  final List<String> commonPests;
  final List<String> commonDiseases;
  final List<String> preventativeTips;
  final List<String> maintenanceTips;
  final List<VegetableVarietyDefinition> varieties;
}

class VegetableVarietyDefinition {
  const VegetableVarietyDefinition({
    required this.id,
    required this.vegetableId,
    required this.name,
    this.subtitle,
  });
  final String id;
  final String vegetableId;
  final String name;
  final String? subtitle;
}

const vegetableFamilies = [
  VegetableFamilyDefinition(
    id: 'solanaceae',
    name: 'Nightshades',
    description: 'Tomatoes, capsicums, chillies, eggplants, potatoes.',
    iconPath: 'assets/veg_icons/gfx_tomato.svg',
  ),
  VegetableFamilyDefinition(
    id: 'brassicas',
    name: 'Brassicas',
    description: 'Broccoli, cauliflower, cabbage, kale, bok choy, rocket.',
    iconPath: 'assets/veg_icons/gfx_broccoli.svg',
  ),
  VegetableFamilyDefinition(
    id: 'alliums',
    name: 'Alliums',
    description: 'Onion, garlic, leek, spring onion, chives.',
    iconPath: 'assets/veg_icons/gfx_onion.svg',
  ),
  VegetableFamilyDefinition(
    id: 'cucurbits',
    name: 'Cucurbits',
    description: 'Cucumber, zucchini, pumpkin, squash, melons.',
    iconPath: 'assets/veg_icons/gfx_pumpkin.svg',
  ),
  VegetableFamilyDefinition(
    id: 'legumes',
    name: 'Legumes',
    description: 'Peas, snow peas, beans, runner beans, broad beans.',
    iconPath: 'assets/veg_icons/gfx_peas.svg',
  ),
  VegetableFamilyDefinition(
    id: 'leafy_greens',
    name: 'Leafy Greens',
    description: 'Lettuce, spinach, silverbeet, endive, chicory.',
    iconPath: 'assets/veg_icons/gfx_lettuce.svg',
  ),
  VegetableFamilyDefinition(
    id: 'root_vegetables',
    name: 'Root Vegetables',
    description: 'Carrot, beetroot, radish, parsnip, turnip, swede.',
    iconPath: 'assets/veg_icons/gfx_carrot.svg',
  ),
  VegetableFamilyDefinition(
    id: 'apiaceae',
    name: 'Apiaceae',
    description: 'Celery, parsley, coriander, dill, fennel, carrot, parsnip.',
    iconPath: 'assets/veg_icons/gfx_celery.svg',
  ),
  VegetableFamilyDefinition(
    id: 'corn_grasses',
    name: 'Sweetcorn',
    description: 'Sweetcorn and popcorn corn.',
    iconPath: 'assets/veg_icons/gfx_sweetcorn.svg',
  ),
  VegetableFamilyDefinition(
    id: 'specialty',
    name: 'Specialty',
    description: 'Asparagus, okra, kumara, and specialty garden crops.',
    iconPath: 'assets/veg_icons/gfx_asparagus.svg',
  ),
  VegetableFamilyDefinition(
    id: 'berries',
    name: 'Berries',
    description: 'Strawberries, raspberries, blackberries, blueberries.',
    iconPath: 'assets/veg_icons/gfx_strawberry.svg',
  ),
];

const vegetableLibrary = [
  VegetableDefinition(
    id: 'tomato',
    familyId: 'solanaceae',
    name: 'Tomato',
    iconPath: 'assets/veg_icons/gfx_tomato.svg',
    commonPests: [
      'Aphids',
      'Whitefly',
      'Psyllid',
      'Mites',
      'Thrips',
      'Caterpillars',
    ],
    commonDiseases: [
      'Early blight',
      'Late blight',
      'Powdery mildew',
      'Botrytis',
      'Leaf spot',
    ],
    preventativeTips: [
      'Prune lower leaves for airflow',
      'Avoid wet foliage late in the day',
      'Mulch soil',
      'Rotate beds',
    ],
    maintenanceTips: [
      'Stake regularly',
      'Remove diseased leaves',
      'Check leaf undersides weekly',
    ],
    varieties: [
      VegetableVarietyDefinition(
        id: 'tomato_cherry',
        vegetableId: 'tomato',
        name: 'Cherry',
        subtitle: 'Small fruiting',
      ),
      VegetableVarietyDefinition(
        id: 'tomato_roma',
        vegetableId: 'tomato',
        name: 'Roma',
        subtitle: 'Paste tomato',
      ),
      VegetableVarietyDefinition(
        id: 'tomato_beefsteak',
        vegetableId: 'tomato',
        name: 'Beefsteak',
        subtitle: 'Large slicing',
      ),
      VegetableVarietyDefinition(
        id: 'tomato_sweet_100',
        vegetableId: 'tomato',
        name: 'Sweet 100',
        subtitle: 'Cherry tomato',
      ),
      VegetableVarietyDefinition(
        id: 'tomato_san_marzano',
        vegetableId: 'tomato',
        name: 'San Marzano',
        subtitle: 'Sauce tomato',
      ),
      VegetableVarietyDefinition(
        id: 'tomato_green_zebra',
        vegetableId: 'tomato',
        name: 'Green Zebra',
        subtitle: 'Striped specialty',
      ),
    ],
  ),
  VegetableDefinition(
    id: 'capsicum',
    familyId: 'solanaceae',
    name: 'Capsicum / Sweet Pepper',
    iconPath: 'assets/veg_icons/gfx_capsicum.svg',
    commonPests: ['Aphids', 'Thrips', 'Whitefly', 'Mites'],
    commonDiseases: ['Powdery mildew', 'Botrytis', 'Leaf spot'],
    preventativeTips: [
      'Keep plants warm',
      'Improve airflow',
      'Avoid overhead watering',
    ],
    maintenanceTips: [
      'Stake heavy plants',
      'Remove damaged fruit',
      'Monitor new growth',
    ],
  ),
  VegetableDefinition(
    id: 'chilli',
    familyId: 'solanaceae',
    name: 'Chilli',
    iconPath: 'assets/veg_icons/gfx_chilli.svg',
    commonPests: ['Aphids', 'Thrips', 'Whitefly', 'Mites'],
    commonDiseases: ['Powdery mildew', 'Leaf spot', 'Root rot'],
    preventativeTips: [
      'Avoid cold stress',
      'Keep foliage dry',
      'Check young tips',
    ],
    maintenanceTips: [
      'Stake if needed',
      'Remove damaged leaves',
      'Feed lightly during fruiting',
    ],
  ),
  VegetableDefinition(
    id: 'eggplant',
    familyId: 'solanaceae',
    name: 'Eggplant',
    iconPath: 'assets/veg_icons/gfx_eggplant.svg',
    commonPests: ['Aphids', 'Whitefly', 'Mites', 'Thrips'],
    commonDiseases: ['Powdery mildew', 'Leaf spot', 'Botrytis'],
    preventativeTips: ['Keep plants warm', 'Avoid wet foliage', 'Mulch soil'],
    maintenanceTips: [
      'Stake fruiting plants',
      'Remove yellowing leaves',
      'Watch for mites',
    ],
  ),
  VegetableDefinition(
    id: 'potato',
    familyId: 'solanaceae',
    name: 'Potato',
    iconPath: 'assets/veg_icons/gfx_potato.svg',
    commonPests: ['Aphids', 'Psyllid', 'Tuber moth', 'Slugs'],
    commonDiseases: ['Late blight', 'Early blight', 'Scab', 'Rot'],
    preventativeTips: [
      'Hill soil around plants',
      'Avoid wet foliage',
      'Remove volunteer potatoes',
    ],
    maintenanceTips: [
      'Monitor foliage for blight',
      'Water evenly',
      'Harvest damaged tubers early',
    ],
  ),
  VegetableDefinition(
    id: 'broccoli',
    familyId: 'brassicas',
    name: 'Broccoli',
    iconPath: 'assets/veg_icons/gfx_broccoli.svg',
    commonPests: [
      'Cabbage white caterpillar',
      'Aphids',
      'Flea beetles',
      'Slugs',
    ],
    commonDiseases: ['Downy mildew', 'Clubroot', 'Black rot'],
    preventativeTips: [
      'Use insect netting',
      'Remove lower damaged leaves',
      'Rotate beds',
    ],
    maintenanceTips: [
      'Check leaf undersides',
      'Keep plants growing evenly',
      'Remove caterpillars early',
    ],
  ),
  VegetableDefinition(
    id: 'cauliflower',
    familyId: 'brassicas',
    name: 'Cauliflower',
    iconPath: 'assets/veg_icons/gfx_cauliflower.svg',
    commonPests: ['Cabbage white caterpillar', 'Aphids', 'Slugs'],
    commonDiseases: ['Downy mildew', 'Clubroot', 'Black rot'],
    preventativeTips: [
      'Use netting',
      'Avoid water stress',
      'Rotate brassica beds',
    ],
    maintenanceTips: [
      'Keep soil evenly moist',
      'Inspect heads',
      'Remove damaged leaves',
    ],
  ),
  VegetableDefinition(
    id: 'cabbage',
    familyId: 'brassicas',
    name: 'Cabbage',
    iconPath: 'assets/veg_icons/gfx_cabbage.svg',
    commonPests: [
      'Cabbage white caterpillar',
      'Aphids',
      'Flea beetles',
      'Slugs',
    ],
    commonDiseases: ['Downy mildew', 'Black rot', 'Clubroot'],
    preventativeTips: ['Use netting', 'Rotate crops', 'Avoid crowded planting'],
    maintenanceTips: [
      'Remove lower yellow leaves',
      'Check tight heads',
      'Water consistently',
    ],
  ),
  VegetableDefinition(
    id: 'kale',
    familyId: 'brassicas',
    name: 'Kale',
    iconPath: 'assets/veg_icons/gfx_leaf.svg',
    commonPests: [
      'Aphids',
      'Cabbage white caterpillar',
      'Whitefly',
      'Flea beetles',
    ],
    commonDiseases: ['Downy mildew', 'Leaf spot', 'Black rot'],
    preventativeTips: [
      'Net young plants',
      'Thin for airflow',
      'Remove old leaves',
    ],
    maintenanceTips: [
      'Harvest outer leaves',
      'Wash aphids from clusters',
      'Remove diseased foliage',
    ],
  ),
  VegetableDefinition(
    id: 'bok_choy',
    familyId: 'brassicas',
    name: 'Bok choy / Pak choi',
    iconPath: 'assets/veg_icons/gfx_leaf.svg',
    commonPests: ['Flea beetles', 'Aphids', 'Caterpillars', 'Slugs'],
    commonDiseases: ['Downy mildew', 'Leaf spot', 'Soft rot'],
    preventativeTips: [
      'Use netting',
      'Avoid overhead watering',
      'Harvest before bolting',
    ],
    maintenanceTips: [
      'Remove damaged leaves',
      'Keep evenly watered',
      'Check new leaves',
    ],
  ),
  VegetableDefinition(
    id: 'rocket',
    familyId: 'brassicas',
    name: 'Rocket / Arugula',
    iconPath: 'assets/veg_icons/gfx_leaf.svg',
    commonPests: ['Flea beetles', 'Aphids', 'Slugs'],
    commonDiseases: ['Downy mildew', 'Leaf spot'],
    preventativeTips: [
      'Use fine mesh',
      'Keep plants growing quickly',
      'Avoid overcrowding',
    ],
    maintenanceTips: [
      'Harvest regularly',
      'Remove damaged leaves',
      'Resow often',
    ],
  ),
  VegetableDefinition(
    id: 'onion',
    familyId: 'alliums',
    name: 'Onion',
    iconPath: 'assets/veg_icons/gfx_onion.svg',
    commonPests: ['Thrips', 'Onion fly', 'Aphids'],
    commonDiseases: ['Rust', 'Downy mildew', 'Neck rot', 'Bulb rot'],
    preventativeTips: [
      'Avoid excess nitrogen',
      'Keep weeds down',
      'Rotate allium beds',
    ],
    maintenanceTips: [
      'Water evenly',
      'Inspect leaves for rust',
      'Remove diseased foliage',
    ],
  ),
  VegetableDefinition(
    id: 'garlic',
    familyId: 'alliums',
    name: 'Garlic',
    iconPath: 'assets/veg_icons/gfx_garlic.svg',
    commonPests: ['Thrips', 'Aphids'],
    commonDiseases: ['Rust', 'White rot', 'Bulb rot'],
    preventativeTips: [
      'Plant clean cloves',
      'Rotate beds',
      'Avoid overwatering',
    ],
    maintenanceTips: [
      'Remove scapes if desired',
      'Monitor rust',
      'Keep beds weed-free',
    ],
  ),
  VegetableDefinition(
    id: 'leek',
    familyId: 'alliums',
    name: 'Leek',
    iconPath: 'assets/veg_icons/gfx_leek.svg',
    commonPests: ['Thrips', 'Leek moth', 'Aphids'],
    commonDiseases: ['Rust', 'Downy mildew', 'Rot'],
    preventativeTips: [
      'Hill soil around stems',
      'Avoid crowding',
      'Rotate beds',
    ],
    maintenanceTips: [
      'Water consistently',
      'Remove rusted leaves',
      'Check folded leaves',
    ],
  ),
  VegetableDefinition(
    id: 'spring_onion',
    familyId: 'alliums',
    name: 'Spring onion',
    iconPath: 'assets/veg_icons/gfx_spring_onion.svg',
    commonPests: ['Thrips', 'Aphids'],
    commonDiseases: ['Rust', 'Downy mildew', 'Rot'],
    preventativeTips: ['Avoid overcrowding', 'Keep weeds down', 'Water evenly'],
    maintenanceTips: [
      'Harvest regularly',
      'Remove damaged leaves',
      'Rotate beds',
    ],
  ),
  VegetableDefinition(
    id: 'chives',
    familyId: 'alliums',
    name: 'Chives',
    iconPath: 'assets/veg_icons/gfx_chives.svg',
    commonPests: ['Thrips', 'Aphids'],
    commonDiseases: ['Rust', 'Downy mildew'],
    preventativeTips: [
      'Avoid overcrowding',
      'Trim tired growth',
      'Keep weeds down',
    ],
    maintenanceTips: [
      'Cut regularly',
      'Remove damaged leaves',
      'Divide clumps when crowded',
    ],
  ),
  VegetableDefinition(
    id: 'cucumber',
    familyId: 'cucurbits',
    name: 'Cucumber',
    iconPath: 'assets/veg_icons/gfx_cucumber.svg',
    commonPests: ['Aphids', 'Whitefly', 'Mites', 'Cucumber beetles'],
    commonDiseases: ['Powdery mildew', 'Downy mildew', 'Rot'],
    preventativeTips: [
      'Improve airflow',
      'Avoid wet leaves late',
      'Trellis where possible',
    ],
    maintenanceTips: [
      'Remove mildewed leaves',
      'Water evenly',
      'Harvest regularly',
    ],
  ),
  VegetableDefinition(
    id: 'zucchini',
    familyId: 'cucurbits',
    name: 'Zucchini / Courgette',
    iconPath: 'assets/veg_icons/gfx_zucchini.svg',
    commonPests: ['Aphids', 'Whitefly', 'Mites', 'Caterpillars'],
    commonDiseases: ['Powdery mildew', 'Downy mildew', 'Rot'],
    preventativeTips: [
      'Space for airflow',
      'Avoid watering foliage',
      'Remove old leaves',
    ],
    maintenanceTips: [
      'Harvest often',
      'Remove diseased leaves',
      'Check flower ends for rot',
    ],
  ),
  VegetableDefinition(
    id: 'pumpkin',
    familyId: 'cucurbits',
    name: 'Pumpkin',
    iconPath: 'assets/veg_icons/gfx_pumpkin.svg',
    commonPests: ['Aphids', 'Whitefly', 'Caterpillars', 'Mites'],
    commonDiseases: ['Powdery mildew', 'Downy mildew', 'Rot'],
    preventativeTips: [
      'Keep vines spaced',
      'Avoid overhead watering',
      'Mulch fruit off wet soil',
    ],
    maintenanceTips: [
      'Remove mildewed leaves',
      'Check vines weekly',
      'Support fruit if vertical',
    ],
  ),
  VegetableDefinition(
    id: 'melon',
    familyId: 'cucurbits',
    name: 'Melon / Watermelon',
    iconPath: 'assets/veg_icons/gfx_melon.svg',
    commonPests: ['Aphids', 'Whitefly', 'Mites', 'Caterpillars'],
    commonDiseases: ['Powdery mildew', 'Downy mildew', 'Rot'],
    preventativeTips: [
      'Grow warm and sunny',
      'Improve airflow',
      'Keep fruit off wet soil',
    ],
    maintenanceTips: [
      'Water consistently',
      'Reduce leaf wetness',
      'Inspect vines for mites',
    ],
  ),
  VegetableDefinition(
    id: 'peas',
    familyId: 'legumes',
    name: 'Peas / Snow peas',
    iconPath: 'assets/veg_icons/gfx_peas.svg',
    commonPests: ['Aphids', 'Thrips', 'Caterpillars'],
    commonDiseases: ['Powdery mildew', 'Downy mildew', 'Root rot'],
    preventativeTips: [
      'Trellis for airflow',
      'Avoid water stress',
      'Remove old vines',
    ],
    maintenanceTips: [
      'Pick regularly',
      'Monitor tips for aphids',
      'Remove mildewed leaves',
    ],
  ),
  VegetableDefinition(
    id: 'beans',
    familyId: 'legumes',
    name: 'Beans',
    iconPath: 'assets/veg_icons/gfx_beans.svg',
    commonPests: ['Aphids', 'Thrips', 'Bean fly', 'Caterpillars'],
    commonDiseases: ['Rust', 'Mildew', 'Blight', 'Leaf spot'],
    preventativeTips: [
      'Avoid overhead watering',
      'Provide airflow',
      'Rotate beds',
    ],
    maintenanceTips: [
      'Pick regularly',
      'Remove rusted leaves',
      'Check young growth',
    ],
  ),
  VegetableDefinition(
    id: 'broad_beans',
    familyId: 'legumes',
    name: 'Broad beans',
    iconPath: 'assets/veg_icons/gfx_broad_beans.svg',
    commonPests: ['Black aphids', 'Thrips', 'Caterpillars'],
    commonDiseases: ['Rust', 'Chocolate spot', 'Mildew'],
    preventativeTips: [
      'Pinch tips if aphids build up',
      'Space for airflow',
      'Avoid water stress',
    ],
    maintenanceTips: [
      'Stake if exposed',
      'Remove diseased leaves',
      'Harvest pods promptly',
    ],
  ),
  VegetableDefinition(
    id: 'lettuce',
    familyId: 'leafy_greens',
    name: 'Lettuce',
    iconPath: 'assets/veg_icons/gfx_lettuce.svg',
    commonPests: ['Aphids', 'Slugs', 'Snails', 'Caterpillars'],
    commonDiseases: ['Downy mildew', 'Leaf spot', 'Rot'],
    preventativeTips: [
      'Avoid overcrowding',
      'Keep foliage dry',
      'Use slug barriers',
    ],
    maintenanceTips: [
      'Harvest outer leaves',
      'Remove damaged leaves',
      'Water consistently',
    ],
  ),
  VegetableDefinition(
    id: 'spinach',
    familyId: 'leafy_greens',
    name: 'Spinach',
    iconPath: 'assets/veg_icons/gfx_spinach.svg',
    commonPests: ['Aphids', 'Slugs', 'Leaf miners'],
    commonDiseases: ['Downy mildew', 'Leaf spot', 'Rot'],
    preventativeTips: [
      'Grow cooler',
      'Thin for airflow',
      'Avoid wet leaves overnight',
    ],
    maintenanceTips: [
      'Harvest regularly',
      'Remove yellow leaves',
      'Watch for mildew',
    ],
  ),
  VegetableDefinition(
    id: 'silverbeet',
    familyId: 'leafy_greens',
    name: 'Silverbeet / Swiss chard',
    iconPath: 'assets/veg_icons/gfx_silverbeet.svg',
    commonPests: ['Aphids', 'Slugs', 'Leaf miners'],
    commonDiseases: ['Leaf spot', 'Mildew', 'Rot'],
    preventativeTips: [
      'Remove old leaves',
      'Allow airflow',
      'Avoid late leaf wetness',
    ],
    maintenanceTips: [
      'Harvest outer stems',
      'Remove damaged leaves',
      'Feed lightly after harvest',
    ],
  ),
  VegetableDefinition(
    id: 'carrot',
    familyId: 'root_vegetables',
    name: 'Carrot',
    iconPath: 'assets/veg_icons/gfx_carrot.svg',
    commonPests: ['Carrot fly', 'Aphids', 'Soil pests'],
    commonDiseases: ['Leaf blight', 'Root rot', 'Damping off'],
    preventativeTips: [
      'Use fine mesh if carrot fly pressure exists',
      'Avoid overwatering',
      'Rotate beds',
    ],
    maintenanceTips: [
      'Thin early',
      'Keep soil evenly moist',
      'Avoid fresh manure',
    ],
  ),
  VegetableDefinition(
    id: 'beetroot',
    familyId: 'root_vegetables',
    name: 'Beetroot',
    iconPath: 'assets/veg_icons/gfx_beetroot.svg',
    commonPests: ['Aphids', 'Leaf miners', 'Slugs'],
    commonDiseases: ['Leaf spot', 'Downy mildew', 'Root rot'],
    preventativeTips: [
      'Thin seedlings',
      'Avoid overhead watering',
      'Rotate beds',
    ],
    maintenanceTips: [
      'Harvest young roots',
      'Remove spotted leaves',
      'Water evenly',
    ],
  ),
  VegetableDefinition(
    id: 'radish',
    familyId: 'root_vegetables',
    name: 'Radish',
    iconPath: 'assets/veg_icons/gfx_radish.svg',
    commonPests: ['Flea beetles', 'Aphids', 'Slugs'],
    commonDiseases: ['Damping off', 'Root rot', 'Leaf spot'],
    preventativeTips: [
      'Grow quickly',
      'Use mesh for flea beetles',
      'Avoid overcrowding',
    ],
    maintenanceTips: [
      'Harvest promptly',
      'Keep soil moist',
      'Remove damaged leaves',
    ],
  ),
  VegetableDefinition(
    id: 'parsnip',
    familyId: 'root_vegetables',
    name: 'Parsnip',
    iconPath: 'assets/veg_icons/gfx_parsnip.svg',
    commonPests: ['Aphids', 'Carrot fly', 'Soil pests'],
    commonDiseases: ['Leaf spot', 'Root rot'],
    preventativeTips: [
      'Use fresh seed',
      'Thin carefully',
      'Avoid overwatering',
    ],
    maintenanceTips: [
      'Keep bed weed-free',
      'Water evenly',
      'Harvest after maturity',
    ],
  ),
  VegetableDefinition(
    id: 'celery',
    familyId: 'apiaceae',
    name: 'Celery',
    iconPath: 'assets/veg_icons/gfx_celery.svg',
    commonPests: ['Aphids', 'Leaf miners', 'Slugs'],
    commonDiseases: ['Leaf spot', 'Rot', 'Mildew'],
    preventativeTips: [
      'Keep evenly watered',
      'Avoid late leaf wetness',
      'Improve airflow',
    ],
    maintenanceTips: [
      'Remove damaged stalks',
      'Mulch soil',
      'Monitor leaf spot',
    ],
  ),
  VegetableDefinition(
    id: 'parsley',
    familyId: 'apiaceae',
    name: 'Parsley',
    iconPath: 'assets/veg_icons/gfx_parsley.svg',
    commonPests: ['Aphids', 'Caterpillars', 'Leaf miners'],
    commonDiseases: ['Leaf spot', 'Mildew', 'Rot'],
    preventativeTips: [
      'Thin for airflow',
      'Avoid overhead watering',
      'Harvest regularly',
    ],
    maintenanceTips: [
      'Remove yellow leaves',
      'Watch for aphids',
      'Cut back tired growth',
    ],
  ),
  VegetableDefinition(
    id: 'coriander',
    familyId: 'apiaceae',
    name: 'Coriander',
    iconPath: 'assets/veg_icons/gfx_coriander.svg',
    commonPests: ['Aphids', 'Leaf miners'],
    commonDiseases: ['Leaf spot', 'Mildew'],
    preventativeTips: [
      'Succession sow',
      'Keep cool in heat',
      'Avoid overcrowding',
    ],
    maintenanceTips: [
      'Harvest before bolting',
      'Remove damaged leaves',
      'Water evenly',
    ],
  ),
  VegetableDefinition(
    id: 'fennel',
    familyId: 'apiaceae',
    name: 'Fennel',
    iconPath: 'assets/veg_icons/gfx_fennel.svg',
    commonPests: ['Aphids', 'Caterpillars'],
    commonDiseases: ['Leaf spot', 'Rot'],
    preventativeTips: [
      'Avoid overcrowding',
      'Keep evenly moist',
      'Provide airflow',
    ],
    maintenanceTips: [
      'Remove old fronds',
      'Monitor aphids',
      'Harvest bulbs before woody',
    ],
  ),
  VegetableDefinition(
    id: 'sweetcorn',
    familyId: 'corn_grasses',
    name: 'Sweetcorn',
    iconPath: 'assets/veg_icons/gfx_sweetcorn.svg',
    commonPests: ['Caterpillars', 'Aphids', 'Armyworm'],
    commonDiseases: ['Rust', 'Smut', 'Leaf blight'],
    preventativeTips: [
      'Plant in blocks',
      'Avoid water stress',
      'Remove diseased leaves',
    ],
    maintenanceTips: [
      'Water during tasselling',
      'Monitor silks',
      'Feed during growth',
    ],
  ),
  VegetableDefinition(
    id: 'asparagus',
    familyId: 'specialty',
    name: 'Asparagus',
    iconPath: 'assets/veg_icons/gfx_asparagus.svg',
    commonPests: ['Aphids', 'Beetles', 'Slugs'],
    commonDiseases: ['Rust', 'Crown rot'],
    preventativeTips: [
      'Keep bed weed-free',
      'Avoid waterlogging',
      'Remove diseased fern',
    ],
    maintenanceTips: [
      'Let ferns recharge crowns',
      'Cut back old fern',
      'Mulch lightly',
    ],
  ),
  VegetableDefinition(
    id: 'kumara',
    familyId: 'specialty',
    name: 'Kumara / Sweet potato',
    iconPath: 'assets/veg_icons/gfx_kumara.svg',
    commonPests: ['Caterpillars', 'Aphids', 'Beetles'],
    commonDiseases: ['Rot', 'Mildew', 'Leaf spot'],
    preventativeTips: [
      'Grow warm and free-draining',
      'Avoid overwatering',
      'Rotate beds',
    ],
    maintenanceTips: [
      'Keep vines managed',
      'Check leaves for chewing',
      'Harvest before cold damage',
    ],
  ),
  VegetableDefinition(
    id: 'okra',
    familyId: 'specialty',
    name: 'Okra',
    iconPath: 'assets/veg_icons/gfx_okra.svg',
    commonPests: ['Aphids', 'Whitefly', 'Mites', 'Caterpillars'],
    commonDiseases: ['Powdery mildew', 'Leaf spot', 'Rot'],
    preventativeTips: ['Grow warm', 'Allow airflow', 'Avoid wet foliage'],
    maintenanceTips: [
      'Harvest pods young',
      'Remove damaged leaves',
      'Monitor mites',
    ],
  ),
  VegetableDefinition(
    id: 'strawberry',
    familyId: 'berries',
    name: 'Strawberry',
    iconPath: 'assets/veg_icons/gfx_strawberry.svg',
    commonPests: ['Aphids', 'Mites', 'Slugs', 'Birds'],
    commonDiseases: ['Botrytis', 'Powdery mildew', 'Leaf spot', 'Crown rot'],
    preventativeTips: [
      'Keep fruit off wet soil',
      'Improve airflow',
      'Remove old fruit',
    ],
    maintenanceTips: [
      'Remove runners if needed',
      'Trim diseased leaves',
      'Net before ripening',
    ],
  ),
  VegetableDefinition(
    id: 'raspberry',
    familyId: 'berries',
    name: 'Raspberry',
    iconPath: 'assets/veg_icons/gfx_raspberry.svg',
    commonPests: ['Aphids', 'Mites', 'Fruit fly', 'Birds'],
    commonDiseases: ['Botrytis', 'Cane spot', 'Rust', 'Mildew'],
    preventativeTips: [
      'Prune for airflow',
      'Remove old canes',
      'Keep fruit dry',
    ],
    maintenanceTips: [
      'Tie canes',
      'Remove infected canes',
      'Net fruit before ripening',
    ],
  ),
  VegetableDefinition(
    id: 'blueberry',
    familyId: 'berries',
    name: 'Blueberry',
    iconPath: 'assets/veg_icons/gfx_blueberry.svg',
    commonPests: ['Aphids', 'Mites', 'Birds'],
    commonDiseases: ['Botrytis', 'Leaf spot', 'Root rot'],
    preventativeTips: [
      'Maintain acidic soil',
      'Avoid waterlogging',
      'Improve airflow',
    ],
    maintenanceTips: [
      'Mulch with acidic mulch',
      'Prune old wood',
      'Net before ripening',
    ],
  ),
];

List<VegetableDefinition> vegetablesForFamily(String familyId) =>
    vegetableLibrary
        .where((vegetable) => vegetable.familyId == familyId)
        .toList();

VegetableFamilyDefinition familyById(String familyId) =>
    vegetableFamilies.firstWhere(
      (family) => family.id == familyId,
      orElse: () => vegetableFamilies.first,
    );
