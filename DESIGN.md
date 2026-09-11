# Ride Tracking Mobile — Design System & Spec

> Source of truth untuk visual design Flutter mobile app. Dipakai untuk copy-paste ke web design tool, LLM prompting (Claude Artifact, v0, Bolt, Figma AI), atau review konsistensi UI.

---

## 1. Identity & Mood

- **Industry**: Real-time group ride & fleet tracking.
- **Mood**: Fungsional, tenang, terpercaya, outdoors-aware (kontras tinggi di bawah sinar matahari).
- **Core aesthetic**:
  - **Bukan**: Neon tech / dark-crypto / AI-slop (bukan gradient berlebih, bukan glowing borders, bukan floaty cards).
  - **Adalah**: Utilitarian modern. Flat surfaces, borders hairline, satu warna brand (moss green) dominan, ilustrasi line-art presisi dengan fill aksen.

---

## 2. Color Tokens

Semua warna turunan dari `mobile/lib/core/theme/app_theme.dart`.

### Brand Palette
| Token | Hex | Role | Usage |
|---|---|---|---|
| `brand` | `#1F6F4A` | Moss green (primary) | CTA button, active icons, selected state, brand dots |
| `brandDark` | `#0E3B27` | Deep pine | Gradient avatar, high-contrast text accents |
| `brandSoft` | `#E3F1E9` | Mint tint (background) | Badge background, selected pill container, icon box background |
| `accent` | `#E6A23C` | Amber / warm sun | Role badge (Admin), secondary highlight, marker non-active |

### Neutral & Surfaces (Light Theme)
| Token | Hex | Role | Usage |
|---|---|---|---|
| `background` | `#F6F7F4` | Canvas off-white | Halaman background (ada dot grid di atasnya) |
| `surface` | `#FFFFFF` | Pure white | Card, bottom nav, dialog, modal sheet |
| `surfaceMuted` | `#EFF1EC` | Off-white muted | Input fill, disabled container |
| `line` | `#E2E5DE` | Hairline border | Card border, divider, textfield border un-focused |
| `ink` | `#0F1A14` | High-contrast dark green-black | Headline, body primary text, floating snackbar background |
| `muted` | `#6B7368` | Slate-grey olive | Subtitle, helper text, empty-state copy, unselected nav |

### Semantic
| Token | Hex | Background | Usage |
|---|---|---|---|
| `warn` | `#B42318` | `#FEE4E2` (`warnFill`) | Logout button, leave ride, delete confirmation |
| `info` | `#1849A9` | `#EFF4FF` (`infoFill`) | System announcement, tip pill |

---

## 3. Typography Scale

Sistem type mengikuti **Material 3 Typography Scale** dengan font default platform (SF Pro di iOS, Roboto di Android, Inter/system di Web).

| Role | Size | Weight | Line Height | Tracking | Usage |
|---|---|---|---|---|---|
| `displaySmall` | 30px | 600 (SemiBold) | 1.25 | -0.5px | Halaman auth title (Login, Register) |
| `headlineMedium` | 24px | 600 (SemiBold) | 1.30 | -0.3px | Section title ("Pilih aksi", "Akun kamu") |  
| `titleLarge` | 20px | 600 (SemiBold) | 1.35 | -0.2px | Bottom sheet title ("Gabung ride") |
| `titleMedium` | 16px | 600 (SemiBold) | 1.40 | 0 | Card title ("Mulai ride"), user name |
| `bodyMedium` | 14px | 400 (Regular) | 1.50 | 0 | Body text, instruksi, empty state text |
| `bodySmall` | 12px | 400 (Regular) | 1.45 | 0.1px | Subtitle, metadata, helper text ("Halo,") |
| `labelLarge` | 15px | 600 (SemiBold) | 1.20 | 0.1px | Button text ("Mulai ride", "Gabung") |

---

## 4. Spacing & Elevation

### Spacing Scale (4pt grid)
- `xs`: 4px (micro-spacing antar teks)
- `sm`: 8px (icon-to-text, chip spacing)
- `md`: 12px (inner card padding kecil, antar form field)
- `lg`: 16px (horizontal screen padding, card padding)
- `xl`: 24px (antar section di halaman)
- `xxl`: 32px (top offset halaman, ilustrasi hero)

### Radius Scale
- `xs`: 6px (tag/badge kecil)
- `sm`: 10px (inner elements)
- `md`: 14px (buttons, textfield, snackbar, icon boxes)
- `lg`: 20px (cards, profile rows)
- `xl`: 28px (bottom sheets, dialogs, floating panels)

### Elevation & Shadow
- **Elevation**: Flat by default (`elevation: 0`). Tidak pakai drop shadow tebal.
- **Border**: 1px solid `AppColors.line` (`#E2E5DE`) sebagai pemisah card dari background.
- **Satu-satunya shadow**: Avatar profile punya subtle glow `BoxShadow(color: brand.withAlpha(0.25), blurRadius: 8, offset: (0, 2))`.

---

## 5. Background: Gradasi Hijau Daun + Topografi Vektor

Background seluruh tab dibungkus `AppBackground`:
- **Gradasi daun**: `LinearGradient` diagonal dari `#EAF4EC` (mint pucat) → `#E3F1E9` (`brandSoft`) → `#CFE5D5` (sage dalam). Cukup hijau untuk memberi karakter outdoors, cukup terang agar kartu putih kontras dan teks terbaca.
- **Dot grid**: Spacing 16px, radius 1.1px, color `brand` opacity 0.10.
- **Kontur topografi**: Dua set cincin topografi samar (stroke `#1F6F4A` alpha 0.10) di sudut kiri atas dan kanan bawah.
- **Rendering**: Vektor via `CustomPainter`, nol file asset, tajam di semua densitas layar.

---

## 6. Iconography & Illustrations

### Icons (Material Symbols / Outlined)
- Navigasi unselected: Outlined (`Icons.home_outlined`, `Icons.map_outlined`, `Icons.history_outlined`, `Icons.person_outlined`).
- Navigasi selected: Filled + tinted `brand` (`#1F6F4A`).
- Ukuran: 20px (action card), 24px (bottom nav).

### Custom Illustrations (Vektor Animasi + Interaktif)
Ilustrasi digambar via `CustomPainter` di `lib/core/widgets/illustrations.dart` (zero asset), palet brand. Beranda tidak memakai widget ilustrasi karena `assets/background_beranda.png` sudah mencakup peta rute dan pegunungan. Tab yang masih memakai ilustrasi:
1. **History** (`HistoryIllustration`, 14:10 max 320px): kartu berisi kompas (12 tick, jarum accent/ink bergoyang) + rute dashed yang mengalir ke bendera finish accent yang berkibar. Tap kompas = spin + chip info, tap bendera = chip status jujur.
2. **Profile** (`ProfileIllustration`, 14:10 max 320px): kartu berisi badge identitas (siluet + bahu brand, bintang accent) yang bernapas, orbit elips + 3 satelit (brand/accent/ink) beredar. Tap badge = boost orbit + chip, tap satelit = chip status sesi.

---

## 7. Component Library

### 1. Action Cards Beranda (Row Card)
- **Primary CTA (`Mulai ride`)**: Card warna `AppColors.brand` (`#1F6F4A`), icon map box putih transparan, teks putih, trailing circle arrow gelap.
- **Secondary Card (`Gabung ride`)**: White card surface, icon group-add box `brandSoft`, teks ink/muted, trailing circle arrow hijau lembut.
- **Info Card (`Tips`)**: Light blue surface (`#EFF4FF`), icon lightbulb putih, teks info (`#1849A9`), info GPS dialog.

### 2. Initials Avatar dengan Status Dot
- Avatar size: 52px lingkaran + 2.5px border putih.
- Fill: `AppColors.brand`.
- Inisial: 18px Bold uppercase putih.
- Status dot: 14px lingkaran di bottom-right, fill `#1F6F4A`, 2px border putih.

### 3. Navigation Bar (Material 3 — Floating Rounded)
- 3 Destinations: **Beranda**, **Riwayat**, **Profil**.
- Style: **Floating melayang** dengan margin kiri-kanan 16 dp, bawah 12 dp.
- Shape: Rounded penuh di semua sisi (`BorderRadius.circular(28)`).
- Surface: `AppColors.surface` dengan border 1 dp `AppColors.line` + bayangan lembut melayang (`blurRadius: 16`, opacity 0.08).
- Height: 64 dp (compact).
- Indicator pill: `AppColors.brandSoft` (`#E3F1E9`).
- Selected icon & label: `AppColors.brand`. Unselected: `AppColors.muted`.
- Label 11 dp, Icon 22 dp.
- Map bukan tab: peta selalu terikat ke satu sesi ride, dibuka dari Beranda (`Mulai ride` / `Gabung ride`).

### 4. Primary Button (Filled)
- Height: 52px (full-width di mobile).
- Background: `AppColors.brand` (`#1F6F4A`).
- Foreground: Putih, font 15px SemiBold.
- Radius: 14px (`AppRadius.md`).
- Disabled: Opacity 0.5.

### 5. Outlined Button
- Height: 52px.
- Background: Transparent.
- Border: 1px solid `AppColors.line`.
- Text: `AppColors.ink`.
- Radius: 14px.

---

## 8. Screen Hierarchy

### Screen 1: Beranda (Home) — Skala Compact
```
[SafeArea]
  [CustomScrollView horizontal 20 dp, max-width 430 dp, clearance 112 dp]
    Header: [Avatar 40dp + Dot] "Halo, [Nama]" + [Bell Notif 40dp brandSoft + dot amber]
    SizedBox(36)
    Hero:
      Row: [Headline 23dp "Jalan lebih seru bersama."] (55%)
           + [Callout 10.5dp "Jarak bukan penghalang untuk tetap bersama."] (45%)
      Subtitle 13dp: "Pantau perjalanan konvoi secara real-time."
      Accent Line: 36x3.5 dp #1F6F4A
    SizedBox(20)
    Pilih aksi: [Title 19dp] + [Desc 12.5dp]
    SizedBox(12)
    Primary Card (~72dp): [Box 46dp] "Mulai ride" 14.5dp + [Arrow Circle 38dp] (#1F6F4A radius 16)
    SizedBox(10)
    Secondary Card (~72dp): [Box 46dp brandSoft] "Gabung ride" + [Chevron Circle 38dp] (#FFFFFF)
    SizedBox(10)
    Tips Card (~72dp): [Box 46dp #D9E9FF] "Tips GPS" (#EFF4FF border #B2DDFF)
[Floating Nav: 3 Tab, radius 28, margin 16/12, height 64]
```

### Screen 2: Map (Ride Active)
- Fullscreen FlutterMap (OpenStreetMap / CartoDB Voyager tiles).
- Top Overlay: Card floating dengan nama ride + badge kode 8-karakter + status rider online.
- Markers:
  - User: Lingkaran biru/brand dengan heading arrow.
  - Other riders: Lingkaran dengan nama / inisial + speed pill.
- Bottom Controls: Tombol share kode, toggle center-to-me, tombol keluar ride.

### Screen 3: Riwayat
- Center: `HistoryIllustration` (14:10 vektor animasi kompas + bendera).
- Headline: "Riwayat belum tersedia" (24px SemiBold).
- Subtitle: Copy jujur bahwa data perjalanan (jarak, kecepatan, rute) akan muncul begitu backend endpoint siap.
- Footer: "v1.0 · Ride Tracking" (bodySmall, muted).

### Screen 4: Profil
- Center: `ProfileIllustration` (14:10 vektor animasi badge + orbit satelit).
- Headline: "Akun kamu" (24px SemiBold).
- Subtitle: "Info login dan sesi yang lagi aktif di device ini."
- 3 Info Rows (Card berjejer):
  - Nama: `[Nama User]`
  - Email: `[user@email.com]`
  - Role: `[user / admin]`
- Danger Button: `FilledButton.tonalIcon` warna merah (`#B42318` on `#FEE4E2`) dengan konfirmasi dialog "Keluar?".

---

## 9. Copywriting Rules (Anti-Slop)

1. **Jujur tentang status data**: Jika endpoint belum ada, katakan "belum tersedia", jangan buat fake item atau skeleton loader tanpa akhir.
2. **Konteks sebelum aksi**: Jelaskan *benefit* dan *format*, bukan teknis backend.
   - Contoh: *"Punya kode 8 karakter?"* (jelas) vs *"Enter UUID string"* (salah).
3. **Personal tapi tidak berlebihan**: "Halo, [Nama]" cukup. Hindari "Selamat datang kembali di platform terhebat untuk komunitas petualang Anda!".
4. **Error message human-readable**: Selalu bungkus pesan error network dengan icon dan penjelasan aksi yang harus diambil user (mis. "GPS belum aktif, silakan nyalakan di pengaturan").
