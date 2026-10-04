# Lab Rat 🐀

A native macOS research companion built with SwiftUI and AppKit. Requires **macOS 14 or newer**. Build the source on an Apple silicon or Intel Mac to produce an app for that architecture.

## Start

Run `./build.sh` from the repository root and open **dist/Lab Rat.app**. You can copy it to Applications if you want to keep it there.

1. Create an experiment and enter one checklist step per line.
2. Start a **run** for focused work. The default is 25 minutes, followed by a 5-minute recovery phase. Each phase waits for you to start it; there is no automatic restart.
3. Add an incubation timer with a sample name, temperature label, and your protocol’s check time. Turn on **Already started** to enter an earlier start date.
4. Click **Float buddy** to show the draggable companion. Close the main workspace and use the menu bar to reopen it. Closing windows keeps the app running; **Quit Lab Rat** exits.
5. Enable macOS notifications from **Settings** if you want system alerts. Permission is requested only when you click that button.

The menu bar shows the active experiment and the running focus countdown. An exclamation mark indicates an overdue sample. The companion shows the next sample due and a playful reminder after its deadline. Click **Checked** to acknowledge an overdue sample, or **Finish** to end one early; it remains in the checked-sample history.

Completed experiments can be archived and restored. Archive an experiment whenever you want to start fresh; its timers continue to run independently. Editing protocol steps preserves completed steps when their text is unchanged.

## Calculators

Results update while you type and can be copied.

| Tool | Inputs | Output |
| --- | --- | --- |
| Dilution | Stock and target in mM; final volume in mL | Stock and diluent volumes in mL |
| Mass to weigh | mM, mL, MW in g/mol | mg and g |
| Molarity | mg, mL, MW in g/mol | mM and mol/L |
| OD600 | Reading, dilution factor, blank | Blank-corrected undiluted OD |
| Protein / MW | mg/mL, MW in kDa | µM and mM |

Use the units shown beside each input. Scientific notation such as `1e-3` is supported. Dilution assumes additive volumes. OD600 conversion uses `(reading − blank) × dilution factor`; it does not infer cell density. The protein calculator uses a supplied MW rather than calculating one from a chemical formula or sequence.

## Data and timing

Experiments, sample timers, preferences, and focus state save locally and atomically to:

`~/Library/Application Support/LabRat/state.json`

No accounts, analytics, or network requests. The fact source links open in your browser only if clicked. **Settings → Show saved data** opens the storage folder for backup. An unreadable notebook is preserved instead of overwritten, and a visible error explains the problem.

Running timers store absolute deadlines. They stay accurate through sleep, closed windows, and a relaunch. A paused focus timer stays paused. If a focus phase expires while asleep or quit, the app advances once to the next phase when resumed; it does not count fictitious extra runs. Overdue samples stay visible until checked.

While running, Lab Rat checks deadlines every second. Notification permission is optional; in-app reminders still work. Existing scheduled system notifications may be delivered after quitting, subject to macOS settings, Focus modes, and sleep. Lab Rat does not monitor a refrigerator or infer sample stability: temperature is your label, and reminders use the time you selected.

The **PI ✓** button is intentionally fake. Toggle it in Settings. It only shows a joke.

## Build and edit

Open `Package.swift` in Xcode, or run:

```sh
./build.sh
```

This builds an optimized app in `dist/`, generates its mouse icon, and applies a local ad hoc signature. It uses a temporary build/cache directory; set `LABRAT_BUILD_DIR` to reuse one. No third-party dependencies or downloads are required. Building requires Xcode or compatible Swift tools with the macOS SDK.

```sh
./test.sh
```

Six tests cover unit conversions, dilution conservation and invalid inputs, blank correction, absolute incubation deadlines, single focus completion, notebook persistence, and preserving unreadable data. The native build-system option is used because this installed Swift version’s default engine attempts to sign XCTest bundles and can reject Finder metadata in Documents folders.

The included app is **locally signed, not notarized for public distribution**. For distributing outside this Mac, use your own Developer ID and Apple notarization.

## Science facts

The small fact collection has clickable primary-source references from the [BIPM](https://www.bipm.org/en/measurement-units), including [the mole](https://www.bipm.org/en/history-si/mole), [SI base units](https://www.bipm.org/en/measurement-units/si-base-units), and [Resolution 1 (2018)](https://www.bipm.org/en/committees/cg/cgpm/26-2018/resolution-1).

## Source map

- `Models.swift`: notebook types, timer state, unit-tested calculations, facts.
- `LabStore.swift`: persistence, run transitions, reminders, notification scheduling.
- `Dashboard.swift`: workspace, checklist, sample cards, archive.
- `Editors.swift`: experiment and sample forms, calculators, settings.
- `Companion.swift`: floating buddy.
- `Theme.swift`: colors, controls, rat illustration.
- `App.swift`: native windows, menu-bar integration, app lifecycle.

Built and tested on this Mac on October 3, 2026.
