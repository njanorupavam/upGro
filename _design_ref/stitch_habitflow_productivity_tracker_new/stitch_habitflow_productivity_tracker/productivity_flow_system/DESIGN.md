---
name: Productivity Flow System
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#434655'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#784b00'
  on-tertiary: '#ffffff'
  tertiary-container: '#996100'
  on-tertiary-container: '#ffeedd'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  display:
    fontFamily: Geist
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  headline-md:
    fontFamily: Geist
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Geist
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 40px
  xl: 64px
  container-margin: 20px
  gutter: 16px
---

## Brand & Style

The brand personality of the design system is centered on clarity, momentum, and mental "flow." It aims to reduce cognitive load for users managing complex habits, transforming a chaotic to-do list into a structured, calm environment. The target audience includes high-achievers, students, and wellness-conscious individuals who value efficiency and aesthetic harmony.

The design style is **Modern Minimalism** infused with subtle **Glassmorphism**. By prioritizing generous whitespace and high-quality typography, the UI creates an atmosphere of organized focus. To keep the experience motivating rather than clinical, we utilize soft environmental shadows and vibrant status accents that provide immediate positive reinforcement upon habit completion.

## Colors

The palette is designed to guide the eye toward action and progress.
- **Focus Blue (Primary):** A deep, saturated azure used for primary actions, active states, and navigation. It evokes stability and concentration.
- **Success Green (Secondary):** A vibrant emerald reserved for positive reinforcement—completed habits, "streak" milestones, and growth indicators.
- **Progress Orange (Tertiary):** A warm amber used for "in-progress" states, reminders, and secondary metrics that require attention without the urgency of an error.
- **Neutral:** A range of cool-toned slates that maintain a clean, high-contrast environment.

**Dark Mode Strategy:** In dark mode, the background transitions to a deep navy-charcoal (#0F172A). Primary and semantic colors increase in vibrancy (using 400-500 weight shades) to ensure accessibility and "glow" against the dark canvas.

## Typography

This design system utilizes **Geist** for its technical precision and modern, open letterforms. The typeface bridges the gap between a systematic developer tool and a consumer lifestyle app.

- **Headlines:** Use tighter letter spacing and semi-bold weights to create a strong visual anchor for page titles and habit names.
- **Body:** Standardized at 16px for optimal readability. Paragraph spacing should be generous to maintain the minimalist aesthetic.
- **Labels:** Uppercase styles are reserved for tiny metadata (Label-sm) to ensure they are distinct from body text without requiring a large footprint.

## Layout & Spacing

The layout follows a **fluid grid** logic based on an **8pt spacing system**. This ensures consistent rhythm across various mobile screen dimensions.

- **Mobile Layout:** A single-column vertical stack with a 20px outer margin. Cards and containers should span the full width minus margins.
- **Rhythm:** Use 24px (md) spacing between distinct functional groups (e.g., between the "Daily Progress" chart and the "Habit List"). Use 12px (sm) for internal element spacing within cards.
- **Safe Areas:** Ensure interactive elements are placed at least 16px away from the bottom "home indicator" on modern mobile devices.

## Elevation & Depth

To maintain a "modern and approachable" feel, depth is created through **Tonal Layers** and **Ambient Shadows** rather than harsh borders.

- **Level 0 (Surface):** The main background. Pure white in light mode; deep slate in dark mode.
- **Level 1 (Cards):** Uses a very soft, diffused shadow (Blur: 20px, Y: 4px, Opacity: 4%) to lift the card slightly off the surface.
- **Level 2 (Interactive/Floating):** Used for Floating Action Buttons (FAB) and active modals. Shadows are slightly more pronounced with a subtle tint of the Primary Focus Blue to suggest interactivity.
- **Dark Mode Depth:** Shadows are replaced by thin, 1px semi-transparent inner borders (strokes) and subtle variations in surface luminosity to distinguish layers.

## Shapes

The shape language is consistently **Rounded**, creating a soft, friendly, and non-intimidating user experience.

- **Standard Containers:** Habit cards, input fields, and modals use a 16px (1rem) radius.
- **Small Elements:** Tooltips and checkboxes use a 8px (0.5rem) radius.
- **Interactive Pills:** Primary buttons and status chips utilize a fully rounded (Pill-shaped) 100px radius to differentiate them from static content containers.

## Components

### Buttons
Primary buttons are pill-shaped with a solid Focus Blue background and white text. Secondary buttons use a ghost style with a subtle 1px border. Press states should involve a slight scale-down (0.98x) to provide tactile feedback.

### Habit Cards
The central component of the UI. Cards feature a Success Green "Completion" toggle on the right side. Incomplete habits use a light grey circular outline. Upon completion, the card should subtly shift in background color to a very pale tint of Success Green.

### Input Fields
Fields are minimalist with a soft grey background and a 16px corner radius. On focus, the border transitions to a 2px Focus Blue stroke. Labels should remain visible above the field in a 'label-sm' style.

### Progress Rings
Utilize the Progress Orange for partial completion. These should be visually light, using a thin stroke (2px - 4px) to avoid cluttering the dashboard.

### Chips/Tags
Used for habit categories (e.g., "Health", "Work"). These are small, pill-shaped elements with low-saturation background tints and high-saturation text for readability.