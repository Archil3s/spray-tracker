# Feature Log

## Product goal

Build a utility-first iOS-style Flutter app that helps a home vegetable gardener track spray applications, withholding periods, and harvest safety.

The app should answer the main question quickly:

> What did I spray, where did I spray it, and when can I safely harvest?

## Design direction

- Platform feel: iOS / Cupertino
- Visual style: soft grouped cards, large headers, simple bottom tabs
- Mood: practical, clean, calm, garden-focused
- Priority: fast recording and clear safety state
- Avoided for MVP: account login, cloud sync, heavy farm-management workflows

## Current committed features

### 1. Main dashboard

**Status:** Scaffolded

**Purpose:** The primary landing screen. It shows harvest safety and recent spray activity at a glance.

**Current UI elements:**

- Large `Spray Tracker` title
- Subtitle: `Garden safety at a glance`
- Two safety metric cards:
  - Safe now
  - Do not harvest
- Primary action card: `Log a spray now`
- Recent spray cards
- Next check reminder card

**Design notes:**

- Uses `CupertinoPageScaffold`
- Uses large iOS-style heading typography
- Uses rounded white cards on a light grouped background
- Uses green as the primary action/safety colour

**Mockup:** [`docs/mockups/dashboard.svg`](mockups/dashboard.svg)

---

### 2. Quick spray logging

**Status:** Scaffolded

**Purpose:** Let the user record a spray application with minimal taps.

**Current fields represented:**

- Product
- Crop
- Beds
- Reason
- Withholding period
- Safe harvest date

**Important decision:**

The utility flow now supports bed selection conceptually, but full bed editing is still a later feature. The app can use the mapped 17-bed layout before allowing user-edited bed shapes.

**Mockup:** [`docs/mockups/log-spray.svg`](mockups/log-spray.svg)

---

### 3. Interactive garden map

**Status:** First functional prototype scaffolded

**Purpose:** Make the GrowVeg-based bed layout interactive inside the app.

**Current behaviour:**

- Adds a `Map` tab to the iOS-style bottom navigation
- Draws a simplified custom map using `CustomPainter`
- Represents 17 beds from the supplied GrowVeg screenshots
- Supports tap detection for each mapped bed
- Updates a selected-bed detail card after tapping a bed
- Shows demo safety state:
  - `Safe`
  - `Wait`
- Provides a button placeholder: `Log spray for Bed X`

**Technical notes:**

- First implementation uses normalized coordinate rectangles for each bed
- The map is vector-rendered in Flutter, not dependent on a static screenshot
- This makes future spray overlays, selected states, and dashboard integration easier

**Mockup:** [`docs/mockups/garden-map.svg`](mockups/garden-map.svg)

---

### 4. Spray history

**Status:** Scaffolded

**Purpose:** Review past spray applications and identify what is still under withholding.

**Current UI elements:**

- Search bar placeholder
- Recent spray record cards
- Status pill: `Safe` or `Wait`
- Product, crop, location, and safe-harvest date display

**Mockup:** [`docs/mockups/history.svg`](mockups/history.svg)

---

### 5. Product library

**Status:** Scaffolded

**Purpose:** Store commonly used spray products and their default withholding periods.

**Current sample products:**

- Neem oil — Pest control — 3 days
- Copper spray — Fungicide — 7 days
- Seaweed tonic — Plant health — 0 days

**Future fields:**

- Active ingredient
- Homemade/organic/chemical category
- Notes
- Default dilution rate
- Re-spray interval

**Mockup:** [`docs/mockups/products.svg`](mockups/products.svg)

---

## Data model direction

### Spray record

```dart
class SprayRecord {
  final String product;
  final String crop;
  final List<int> bedNumbers;
  final DateTime sprayedAt;
  final int withholdingDays;
  final String reason;
  final String notes;
}
```

### Product

```dart
class SprayProduct {
  final String name;
  final String type;
  final int defaultWithholdingDays;
  final String notes;
}
```

### Garden bed

```dart
class GardenBedZone {
  final int number;
  final Rect bounds;
  final String status;
  final String cropSummary;
  final String lastSpray;
}
```

## Build phases

### Phase 1 — Current scaffold

- [x] Flutter config
- [x] README
- [x] iOS-style Cupertino app
- [x] Dashboard tab
- [x] Log Spray tab
- [x] Spray History tab
- [x] Product Library tab
- [x] Static mockups
- [x] Feature log

### Phase 2 — Interactive garden map

- [x] Add Map tab
- [x] Add 17 mapped beds
- [x] Add tappable bed zones
- [x] Add selected bed detail card
- [x] Add Garden Map mockup
- [ ] Connect map selection to Log Spray screen
- [ ] Add multi-bed selection for spray logging

### Phase 3 — Make spray logging functional

- [ ] Add form state for logging sprays
- [ ] Add in-memory spray record list
- [ ] Calculate safe harvest date from withholding days
- [ ] Add basic edit/delete actions
- [ ] Add empty states

### Phase 4 — Persistence

- [ ] Add local database
- [ ] Save spray records locally
- [ ] Save product library locally
- [ ] Load dashboard from saved records

### Phase 5 — Utility upgrades

- [ ] Local notification for safe harvest date
- [ ] Re-check reminder
- [ ] Filter history by crop/product/status
- [ ] Export log as CSV

### Phase 6 — Manual bed editing

- [ ] Add bed list
- [ ] Add bed creation form
- [ ] Attach spray record to one or more beds
- [ ] Dashboard grouping by bed
- [ ] Add editable bed names and crops

## Current repo state

The app is scaffolded in `lib/main.dart` as a single-file prototype. This is intentional for early design speed. Once the utility flow is approved, it should be split into feature folders.
