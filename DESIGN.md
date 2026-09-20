# Design

<!-- impeccable:design-schema 1 -->

## World

Dark engineering console, anchored directly on the user's own product
(Nexo's landing page: near-black navy field, a single cyan→violet
gradient as the signature accent, monospace technical labels, card
panels with hairline borders). Mode: **Operate** — the visitor is
completing a real task (choosing what to install, watching it install),
not being persuaded or entertained. Every screen keeps the task legible;
the gradient is spent once per screen (a headline word, the primary
button, the active nav indicator, checked-state fill), never as ambient
decoration.

Runs inside a WebView2 control hosted by a native, borderless Windows
form (`gui/WizardHost.ps1`) — Chromium rendering, but no browser chrome,
so the page owns its own custom titlebar and window controls.

## Palette

| Token | Value | Use |
|---|---|---|
| `--bg` | `#0a0e1a` | Base field |
| `--bg-elevated` | `#10162a` | Panels/cards |
| `--bg-elevated-2` | `#161d36` | Hover/active surface |
| `--bg-inset` | `#070a13` | Inputs, log panel, checkbox well |
| `--border` / `--border-strong` | `rgba(148,163,209,.14 / .26)` | Hairlines |
| `--text` | `#eef2fb` | Primary text |
| `--text-dim` | `#93a1c4` | Secondary text (tinted, not gray — meets 4.5:1 on `--bg`/`--bg-elevated`) |
| `--text-faint` | `#5b6688` | Tertiary/meta (mono ids, step counters) |
| `--cyan` / `--violet` | `#22d3ee` / `#8b5cf6` | The one signature gradient |
| `--teal` | `#2dd9b9` | Success / "done" state |
| `--amber` | `#fbbf5b` | Warning / risk chip |
| `--danger` | `#f8717a` | Fail state |

Category swatches (the small color bar on each app row) each get one hue
from this same family, extended per category so the "Aplicativos" section
reads as a coherent set rather than random color-coding — see
`CATEGORY_COLORS` in `gui/wizard/app.js`.

Color strategy: **Committed**, not Restrained — the dark field carries
the whole surface, not just an accent on a light ground. This is a
deliberate deviation from Operate mode's usual restrained default,
justified because the world itself is pinned evidence (the user's own
product), not an invented aesthetic.

## Type

- Display/headings: `Segoe UI Variable Display` → `Segoe UI Semibold` → `Segoe UI` (Windows 11's own native display face; ships with the OS, no embedding needed since this only ever runs on Windows 11).
- Body: `Segoe UI Variable Text` → `Segoe UI`.
- Technical (ids, log, category chips, step counters): `Cascadia Code` → `Cascadia Mono` → `Consolas` (ships with Windows Terminal, present by default on Windows 11).

No web fonts, no downloads — everything resolves to a font already on the
target OS, which matters because this is a portable offline artifact.

## Components

- **Sidebar nav** (`gui/wizard/style.css` `.sidebar`/`.side-*`): grouped by
  section (início, aplicativos, sistema, claude code suite, revisão,
  instalação), a 2px cyan inset border marks the current step, a teal dot
  marks a completed one. Never a numbered stepper — the groups carry the
  information a "01/02/03" kicker would have faked.
- **Check rows** (`.check-row`): the app/task checklist is a dense list,
  not icon-cards — a drafted checkbox (gradient fill + drawn checkmark
  SVG when active), an optional category-color swatch, label + mono id.
  Chosen specifically to avoid the "same-size icon+heading+text card"
  default the craft floor bans.
- **Chips** (`.chip`): mono, uppercase, pill-bordered — used for the
  category tag on app screens and the "risco" flag on Autologin. Not used
  as a kicker above any heading.
- **Suite screens** (`.suite-cover`/`.suite-icon`/`.suite-name`): thero,
  Athena and Zeus each get their OWN real brand identity, pulled straight
  from their own landing pages (`netovieira/{thero,athena,zeus}` →
  `landing/src/styles.css`'s `--primary` token) rather than a wizard-
  invented color: thero `#f4652c` (its real raster mark + a real product
  screenshot as the cover background), Athena `#eb445b` (a drawn network-
  graph glyph, matching its landing page's `AthenaMark`), Zeus `#ff8800`
  (a drawn lightning-bolt glyph, matching its `ZeusMark`). Version and
  "updated" date are real (`__init__.py` / last commit date), not
  placeholder copy. Athena and Zeus don't have a dedicated product
  screenshot in their landing repos yet, so their cover uses a generated
  radial-gradient mesh in the app's own color instead of a fabricated
  photo — see `docs/design-assets-prompts.md` §3 for swapping in a real
  one later.
- Only on these three screens, "Avançar" becomes **"Continuar"** (or
  "Continuar e instalar" for thero, which has a real pipeline toggle) and
  a subtle **"Pular"** button appears next to Voltar — the navigation
  itself is the opt-in/opt-out control, not a separate checkbox, since
  the whole screen IS the pitch for that one decision.
- **Progress** (`.progress-bar-track`, `.step-row`, `.step-status`,
  `.log-panel`): real functional progress (not a decorative ring or
  sparkline) — a filled track plus a per-step status list plus a live
  mono log feed, all backed by the same event stream the console
  (`genesis.ps1`) prints.

## Motion

One authored moment: the checkbox fill/checkmark transition
(`.check-box` background + `svg` opacity/scale, ~100ms) and the sidebar's
current-step inset border. No entrance animations, no scroll-triggered
reveals — this is a task surface the user re-runs maybe once a year; the
motion budget goes to feedback, not spectacle.

## Provenance

Two raster assets ship, both real product artifacts, not generated: 
`gui/wizard/assets/thero-mark.png` and `thero-system.jpg`, copied verbatim
from `netovieira/thero`'s own landing page (`landing/src/assets/`) — the
actual logo and an actual product screenshot, not stock art or an AI
generation standing in for either. Athena and Zeus have no equivalent
real screenshot yet (see `docs/design-assets-prompts.md` §3), so their
suite screens use a generated CSS gradient mesh in the app's own brand
color instead of fabricating a photo. Every other visual element is CSS
or inline SVG (checkmark, network and zap glyphs, all under the icon-size
budget). The `Genesis.exe` application icon is `gui/Genesis.ico`, generated
from the shipped `genesis-icon-app-512x512.png` by
`scripts/make-exe-icon.ps1` (`build.ps1` runs it automatically whenever the
`.ico` is missing), so no external image generation is required anymore —
see `docs/design-assets-prompts.md` §1 only if you want to replace the art.

## Finish

Verified via a live click-through in Chrome (the page loads unmodified
in any Chromium engine, including WebView2's) covering: welcome, about,
one category-app screen with toggling, the tasks screen, all three suite
screens, review, a simulated install run, and the done screen with
launchable-app tiles. One defect found and fixed in that pass: the
progress screen never advanced to "done" because `stepIndex` was not
updated on the `done` bridge event (see `gui/wizard/app.js`,
`onBridgeMessage`).

Not verified: the real WebView2 hosting inside the compiled
`Genesis.exe` (window drag via `WM_NCLBUTTONDOWN`, the JS↔PowerShell
message bridge, `gh auth login`'s browser hand-off mid-run) — this
sandbox has no interactive Windows session to click through a compiled,
UAC-elevated GUI. `gui/WizardHost.ps1` compiles cleanly and follows the
documented WebView2 WinForms pattern, but its first real run on the
target machine is the actual verification; treat that run as the
finish review this build could not perform itself.
