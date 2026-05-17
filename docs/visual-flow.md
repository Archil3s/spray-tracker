# Spray Tracker — Visual App Flow

This document tracks the current app flow and the crop icons used in the Garden selector and bed map.

## Main Navigation

```mermaid
flowchart LR
  A[Home] --> B[Garden]
  B --> C[Spray]
  C --> D[Records]
  D --> E[Products]
```

## Core User Flow

```mermaid
flowchart TD
  A[Open app] --> B[Garden tab]
  B --> C[Tap bed]
  C --> D[Add vegetable]
  D --> E[Choose family]
  E --> F[Choose vegetable]
  F --> G[Vegetable icon appears on bed]
  G --> H[Spray guide]
  H --> I[Choose affected vegetable]
  I --> J[Choose spray target]
  J --> K[Choose product]
  K --> L[Review]
  L --> M[Save spray record]
  M --> N[Record shows bed + vegetable + target + product]
```

## Add Vegetable Flow

```mermaid
flowchart TD
  A[Tap Add vegetable] --> B[Family selector]
  B --> C[Vegetable list]
  C --> D[Tap ADD]
  D --> E[CropProfile created from crop_library.dart]
  E --> F[Added to selected bed]
  F --> G[Icon shown on bed map]
```

## Spray Logging Flow

```mermaid
flowchart TD
  A[Tap Spray or Quick log] --> B[Select bed]
  B --> C[Select vegetable or all vegetables]
  C --> D[Select spray target]
  D --> E[Product suggestions filter by target]
  E --> F[Add optional issue and notes]
  F --> G[Review]
  G --> H[Save]
  H --> I[Records screen]
```

## Spray Targets

| Target | Marker | Meaning |
|---|---:|---|
| Pest pressure | `P` | Visible insects, mites, chewing damage, webbing, sticky residue |
| Fungal pressure | `F` | Leaf spots, mildew, rust, blight risk, humid disease weather |
| Preventative | `PR` | No outbreak yet; risk reduction before pressure builds |
| Maintenance | `M` | Plant support, stress recovery, pruning, airflow, crop care |

## Current Icon Assets

These are the current icons used by the app. Some vegetable families still share placeholder icons until custom individual icons are created.

| Icon | Asset | Current use |
|---|---|---|
| <img src="../assets/veg_icons/tomato.svg" width="32" height="32" /> | `assets/veg_icons/tomato.svg` | Tomato, capsicum, chilli, eggplant, Nightshades placeholder |
| <img src="../assets/veg_icons/leafy.svg" width="32" height="32" /> | `assets/veg_icons/leafy.svg` | Brassicas, leafy greens, legumes, herbs placeholder |
| <img src="../assets/veg_icons/onion.svg" width="32" height="32" /> | `assets/veg_icons/onion.svg` | Onion, garlic, leek, alliums |
| <img src="../assets/veg_icons/root.svg" width="32" height="32" /> | `assets/veg_icons/root.svg` | Root vegetables, cucurbits, sweetcorn, specialty placeholder |
| <img src="../assets/veg_icons/berry.svg" width="32" height="32" /> | `assets/veg_icons/berry.svg` | Berries |

## Garden Bed Icon Sizes

| Location | Size |
|---|---:|
| Bed map icon ribbon | `22 x 22` |
| Selected bed chips | `18 x 18` |
| Add vegetable family card | `28 x 28` |
| Add vegetable card | `34 x 34` |
| Spray guide crop selector | `20 x 20` |
| Spray pressure cards | `28 x 28` |

## Current Family Selector Flow

```mermaid
flowchart LR
  A[Family card] --> B[Family detail]
  B --> C[Vegetable card]
  C --> D[ADD]
  D --> E[Bed map icon]
```

## Current Crop Families

| Family | Description | Current icon |
|---|---|---|
| Nightshades | Tomatoes, capsicums, chillies, eggplants, potatoes | <img src="../assets/veg_icons/tomato.svg" width="28" /> |
| Brassicas | Broccoli, cauliflower, cabbage, kale, bok choy, rocket | <img src="../assets/veg_icons/leafy.svg" width="28" /> |
| Alliums | Onion, garlic, leek, spring onion, chives | <img src="../assets/veg_icons/onion.svg" width="28" /> |
| Cucurbits | Cucumber, zucchini, pumpkin, squash, melons | <img src="../assets/veg_icons/root.svg" width="28" /> |
| Legumes | Peas, beans, runner beans, broad beans | <img src="../assets/veg_icons/leafy.svg" width="28" /> |
| Leafy Greens | Lettuce, spinach, silverbeet, endive, chicory | <img src="../assets/veg_icons/leafy.svg" width="28" /> |
| Root Vegetables | Carrot, beetroot, radish, parsnip, turnip, swede | <img src="../assets/veg_icons/root.svg" width="28" /> |
| Apiaceae | Celery, parsley, coriander, dill, fennel | <img src="../assets/veg_icons/root.svg" width="28" /> |
| Sweetcorn | Sweetcorn and popcorn corn | <img src="../assets/veg_icons/root.svg" width="28" /> |
| Specialty | Asparagus, okra, kumara, specialty crops | <img src="../assets/veg_icons/root.svg" width="28" /> |
| Berries | Strawberries, raspberries, blueberries | <img src="../assets/veg_icons/berry.svg" width="28" /> |

## Next Icon Work

Replace placeholder/shared icons with individual animated-style SVGs:

```text
tomato.svg
capsicum.svg
chilli.svg
eggplant.svg
potato.svg
broccoli.svg
cauliflower.svg
cabbage.svg
kale.svg
bok_choy.svg
onion.svg
garlic.svg
leek.svg
cucumber.svg
zucchini.svg
pumpkin.svg
pea.svg
bean.svg
lettuce.svg
spinach.svg
silverbeet.svg
carrot.svg
beetroot.svg
radish.svg
corn.svg
asparagus.svg
kumara.svg
strawberry.svg
raspberry.svg
blueberry.svg
```

## Design Direction

- Animated/cartoon style, not realistic.
- No background.
- Transparent SVG or PNG.
- Must read clearly at `22 x 22` on garden beds.
- More detailed versions can be used at `34 x 34` in selector cards.
- Each family should have distinct silhouettes so the map is readable at a glance.
