# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Delegated: vanilla HTML/CSS/JS, no framework, no build step. Reasoning:
the surface is hosted inside a WebView2 control embedded in a native
PowerShell/.NET shell (compiled to a single `Genesis.exe` via ps2exe) —
there is no server and no bundler in this environment, and the whole
point is a portable folder of plain files sitting next to the exe. The
HTML/JS talks to the existing PowerShell automation engine
(`modules/Pipeline.ps1`) through WebView2's `postMessage` bridge.

## Users

Single user (the machine's owner) running this once per Windows
reformat, immediately after a fresh install with only the bare minimum
present (just enough to run Claude Code). The job: replace hand-editing
JSON config files with an actual guided wizard — pick which apps/steps to
include, adjust a couple of paths, then watch a live progress screen, and
finally choose which freshly installed apps to open.

## Product Purpose

Genesis is a personal, fully offline post-format Windows setup wizard — the
"planeta-matriz" (terraformer) of the Theroverse ecosystem. It exists so
that reformatting a PC stops being "run a script and hope the JSON was
edited right" and becomes an actual choice-driven installer: welcome ->
pick components -> review/configure -> live progress -> done, opening
whichever apps the user wants.

## Positioning

Not a commercial product — the meaningful difference is against the
project's own previous state (a plain-text PowerShell console script,
then a bare WinForms progress window): this surface gives the same
one-time ritual a real, polished, guided flow without adding any backend,
telemetry, or hosted component. Everything still runs 100% local and
offline.

## Operating Context

- Runs right after a fresh Windows 11 format/install, as Administrator
  (UAC elevation), on a machine that may not even have winget yet.
- The actual system changes (winget installs, scheduled tasks,
  VirtualBox VM, SSH keys, etc.) are performed by the existing
  `modules/Pipeline.ps1` PowerShell engine — this new UI is a front-end
  only, replacing the current `gui/App.ps1` WinForms shell, not the
  automation underneath it.
- Must keep working as a single portable artifact: `Genesis.exe` plus
  its sibling folders (`modules/`, `python/`, `config/`,
  `raycast-installer.exe`) — no installer-of-installers, nothing hosted
  remotely, nothing that requires Node/npm to build.
- Interface language is Portuguese (pt-BR), matching every existing
  script string in the project.

## Capabilities and Constraints

- WebView2 Runtime ships built into Windows 11 by default; if it's
  somehow missing (e.g. a stripped/LTSC image), the shell must explain
  that plainly instead of crashing silently.
- JS <-> PowerShell communication goes through WebView2's
  `postMessage`/`WebMessageReceived` bridge: JS sends the user's final
  choices to start the run; PowerShell pushes live per-step
  status/log/progress events back to JS.
- Wizard must expose real choices instead of requiring JSON edits:
  - which winget apps to install (checkboxes, grouped by category,
    sourced from `config/winget-apps.json`);
  - which optional steps to enable/disable (mirrors `config/tasks.json`
    — e.g. Autologin, Home Assistant, Windows-Search-redirect);
  - a couple of editable paths/values (Home Assistant `.vdi` path,
    projects to clone).
- The run stays unattended once the wizard's choices are confirmed and
  installation starts — same philosophy as today, including the one
  known deliberate pause (`gh auth login` needs a browser confirmation).
- No image-generation tool is available in this environment. All visual
  assets (app icon, any illustration/banner) must be supplied externally
  by the user, from prompts written for an image generator.

## Evidence on Hand

- `modules/Pipeline.ps1` and `config/*.json` are the real, working
  source of truth for what steps exist and what they do — not to be
  reinvented, only exposed through a better front-end.
- The current `gui/App.ps1` (WinForms) is the incumbent implementation:
  useful as a behavioral reference (what data exists, what the log/
  progress feed looks like) but explicitly NOT a visual reference — it's
  being replaced for being plain/unpolished.
- No brand assets, logo, or existing visual identity exist yet for this
  tool; a name/mark can be established as part of this new surface.

## Product Principles

1. The wizard is a front-end only: it edits config JSON and starts the
   existing PowerShell pipeline — it must never duplicate or reimplement
   installation logic.
2. Choices happen once, up front; nothing after "Instalar" prompts the
   user again (except the one known GitHub auth pause).
3. Stays a single portable offline artifact: no telemetry, no hosted
   assets, no dependency the user has to install beyond what the setup
   itself already provisions.
4. Runs on a machine that just got wiped — degrade gracefully and explain
   clearly when a prerequisite (WebView2, admin rights) is missing,
   rather than failing silently.

## Accessibility & Inclusion

No specific accessibility requirement was raised; keep standard good
practice (contrast, keyboard focus order, readable type scale) since it's
a single named user's own tool, not a public-facing product.
