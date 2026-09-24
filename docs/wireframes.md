# Lokal UX Wireframes (MVP)

Mobile-first screens. Warm Scandinavian feel: forest green, beige, white, dark gray.

## 1. Browse / Home

```text
┌─────────────────────────────┐
│ Lokal            (user) │
├─────────────────────────────┤
│ Lokal                   │
│ From nearby.   │
│ ┌─────────────────────────┐ │
│ │ 🔍 Otsi maasikaid…      │ │
│ └─────────────────────────┘ │
│ [🏡Kõik][🍎Toit][🌱][🍯][🎨]│
│ Raadius [5] [20*] [50] km   │
│ ┌─────────────────────────┐ │
│ │     OSM map (Estonia)   │ │
│ │     • producer pins     │ │
│ └─────────────────────────┘ │
│ Lähedal                     │
│ ┌──────────┐ ┌──────────┐   │
│ │  photo   │ │  photo   │   │
│ │ Title    │ │ Title    │   │
│ │ Farm·2km │ │ Farm·5km │   │
│ │ 8.50 €/kg│ │ 4.50 €   │   │
│ └──────────┘ └──────────┘   │
├─────────────────────────────┤
│ Avasta | Tellimused | Profiil│
└─────────────────────────────┘
```

## 2. Product detail

```text
┌─────────────────────────────┐
│ ← Toode                     │
│████████ full-bleed photo ███│
│ Mahepõllumajanduslikud      │
│ maasikad                    │
│ 8.50 € / kg                 │
│ Tammemäe Aed · ★4.8 · 1.7km │
│ Description…                │
│                             │
│ Telli                       │
│ Kogus [ 1 ]                 │
│ Kättesaamine [Järeletulemine]│
│ Sõnum […………]                │
│ Maksad tootjale kohapeal…   │
│ [        Telli        ]     │
│                             │
│ Arvustused                  │
│ Anna ★5 “Super maasikad!”   │
└─────────────────────────────┘
```

## 3. Auth

```text
┌─────────────────────────────┐
│ Lokal                   │
│ From nearby.   │
│ [Sisselogimine*][Registreeru]│
│ E-post                      │
│ Parool                      │
│ Roll (register): Ostja/…    │
│ [ Logi sisse ]              │
│ [ Jätka Google'iga (demo) ] │
│ Demo: anna@ / mari@ / juri@ │
└─────────────────────────────┘
```

## 4. Producer dashboard

```text
┌─────────────────────────────┐
│ Müüja töölaud    [Lisa toode]│
│ Tammemäe Aed                │
│                             │
│ + Form: name, photos, price,│
│   unit, qty, pickup/delivery│
│                             │
│ Sinu tooted                 │
│ [img] Maasikad  8.50€  [x]  │
│ [img] Leib      5.00€  [x]  │
└─────────────────────────────┘
```

## 5. Orders

```text
┌─────────────────────────────┐
│ Tellimused                  │
│ [Ostan*] [Müün]             │
│ ┌─────────────────────────┐ │
│ │ photo  Product          │ │
│ │        Farm · 1 kg · €  │ │
│ │        PENDING          │ │
│ │ [Võta vastu][Keeldu]    │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

## Interaction notes

- One job per screen: discover, inspect/order, manage listings, manage orders
- Hero on browse is brand + tagline only (no stats clutter)
- Map is an atmosphere + discovery tool, not a dashboard widget wall
- Motion: soft fade on brand, staggered product rise-in, chip active lift
