# 🔑 KeyHelper

> A lightweight macOS macro automation tool — bind custom key shortcuts to execute keyboard combos, type text, or insert delays. No scripting, no bloat, just keyboard magic.

![macOS](https://img.shields.io/badge/macOS-15%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ Features

- **🎯 Multi-Trigger Shortcuts** — One macro, multiple hotkeys. Bind any key combination (e.g., `F6`, `⌘+Shift+P`, `⌥+Space`) to trigger the same macro.
- **🎹 Visual Keyboard Editor** — No need to fight with real key capture. Edit macro steps using a beautiful on-screen virtual keyboard with modifier toggles (⌘⌥⌃⇧Fn).
- **📝 Step-by-Step Macros** — Compose macros from three types of steps:
  - **Key Combo** — Simulate keyboard shortcuts (e.g., `⌘V` for paste)
  - **Text Input** — Type a string of text automatically
  - **Delay** — Wait for a specified time between steps
- **🛡️ Global Key Monitoring** — Works system-wide using macOS Accessibility API (event tap). Your macros fire no matter which app is active.
- **⚙️ Settings Panel** — Configure launch at login, hide dock icon, and auto-start monitoring from a dedicated settings window.
  - **Launch at Login** — Register as a login item via `SMAppService`.
  - **Hide Dock Icon** — Switch to `.accessory` activation policy for a menu-bar-style experience.
  - **Auto-start Monitoring** — Begin global key monitoring immediately on app launch.
- **🔒 Accessibility Status Bar** — A prominent banner at the top of the macro list shows whether Accessibility permission has been granted, with a one-click shortcut to System Settings.
- **🎨 Native macOS Design** — Built with SwiftUI, grouped form sections, SF Symbols, and clean dark-mode-ready UI.

---

## 🖥️ Screenshots

```
┌──────────────────────────────────────────────────┐
│  ✅ Accessibility access granted                  │
├──────────────────────────────────────────────────┤
│                                                  │
│  ┌──────────────────────────────────────────────┐│
│  │ 🔘 Copy Paste    ⌘V         8 steps     ▸  ││
│  └──────────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────────┐│
│  │ 🔘 Code Snippet   ⌘+Shift+P    3 steps   ▸  ││
│  └──────────────────────────────────────────────┘│
│  ┌──────────────────────────────────────────────┐│
│  │ 🔘 Type Email     ⌥+Space      1 step    ▸  ││
│  └──────────────────────────────────────────────┘│
│                                                  │
│  [➕]                         [⚙️]  [▶️ Start]  │
└──────────────────────────────────────────────────┘
```

| Macro List | Macro Editor | Settings |
|:---:|:---:|:---:|
| *Coming soon* | *Coming soon* | *Coming soon* |

---

## 🚀 Getting Started

### Requirements
- macOS 15+ (Sequoia)
- Xcode 16+
- Accessibility permissions (required for global key monitoring)

### Build & Run
```bash
git clone https://github.com/lset0ng/keyHelper.git
cd keyHelper
open keyHelper.xcodeproj
```

Or build from command line:
```bash
xcodebuild -project keyHelper.xcodeproj -scheme keyHelper -destination 'platform=macOS' build
```

### Package as DMG
```bash
# Install create-dmg for prettier output (optional)
brew install create-dmg

# Build and package
./scripts/package-dmg.sh
```

### Grant Accessibility Permission
On first launch, macOS will prompt you to grant Accessibility access. This is required for the app to listen to global key events. Go to **System Settings → Privacy & Security → Accessibility** and enable **KeyHelper**.

Alternatively, click **Open Settings…** in the app's Accessibility banner or the Settings panel to jump directly there.

---

## 🎮 Usage

1. **Create a Macro** — Click the `+` button in the toolbar.
2. **Set Triggers** — In the editor, click `+` next to **Triggers** to add hotkeys. You can have multiple triggers for the same macro.
3. **Add Steps** — Click `+` next to **Steps** to choose the step type:
   - **Key Combo** — Use the virtual keyboard to select keys and modifiers
   - **Text Input** — Type the string you want to auto-insert
   - **Delay** — Set the wait time in seconds
4. **Start Monitoring** — Click the **Start** button in the toolbar. Your macros are now active system-wide!
5. **Stop Monitoring** — Click the **Stop** button to pause all macro execution.
6. **Customize Behavior** — Open **Settings → General** from the toolbar gear icon to configure:
   - Launch at login
   - Hide dock icon (app becomes a background process)
   - Auto-start monitoring on launch

---

## 🏗️ Architecture

```
keyHelper/
├── keyHelperApp.swift          # App entry point, Settings scene, AppDelegate
├── ContentView.swift           # Root view container
├── MacroListView.swift         # Macro list, monitoring control, accessibility bar
│   └── MacroRow                # Individual macro row with toggle & badges
│   └── TriggerBadge            # Trigger key display capsule
├── MacroEditorView.swift       # Macro editor (triggers, steps, virtual keyboard)
├── SettingsView.swift          # Settings panel (launch at login, hide dock, auto-start)
├── Models.swift                # Macro, KeyCombo, MacroStep data models
├── MacroStore.swift            # UserDefaults persistence layer
├── GlobalKeyMonitor.swift      # CGEventTap global key listener
├── MacroExecutor.swift         # Macro step execution engine
├── KeySimulator.swift          # CGEvent key simulation
├── Assets.xcassets/            # App icons & accent colors
├── scripts/
│   └── package-dmg.sh          # DMG packaging script (local unsigned build)
├── .gitignore
└── keyHelper.xcodeproj/
```

---

## 🛠️ Technical Details

### Global Key Monitoring
Uses `CGEvent.tapCreate` with `CGSessionEventTap` to intercept system-wide key events. The monitor filters for `keyDown` events and matches them against all enabled macro triggers. Matching events are consumed (`return nil`) to prevent the original key from being passed to other apps.

### Key Simulation
Uses `CGEvent` with `CGEventSourceStateHIDSystemState` to simulate key presses at the HID level. This ensures the simulated keys are treated as real hardware input by all applications.

### Virtual Keyboard
The on-screen keyboard renders a compact QWERTY layout with clickable keys and modifier toggles. Selected keys are highlighted with the system accent color. Modifier keys (⌘⌥⌃⇧Fn) toggle on click and affect the combo display in real-time.

### Persistence
Macros are serialized to JSON and stored in `UserDefaults`. The `Macro` model supports backward-compatible decoding: old data with a single `trigger` field is automatically migrated to the new `triggers` array format.

### Dock-less Mode
Supports `.accessory` activation policy to hide the Dock icon and menu bar, running entirely as a background process. Toggle via **Settings → Hide Dock Icon**. When enabled, the toolbar still provides a **Settings** button (via `SettingsLink`) so you can always get back to preferences.

### Auto-start Monitoring
The app remembers whether monitoring was active and can auto-start on launch via `UserDefaults` (`autoStartMonitoring` key), checked in `AppDelegate.applicationDidFinishLaunching`.

### Login Item Registration
Uses `SMAppService.mainApp` from the `ServiceManagement` framework to register/unregister as a launch-at-login item. Changes take effect immediately.

### DMG Packaging
`scripts/package-dmg.sh` builds a Release configuration and packages the `.app` into a DMG. Uses `create-dmg` if available (recommended, install via `brew install create-dmg`), falling back to `hdiutil`. Useful for local distribution or testing.

---

## 📝 License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">Made with ❤️ by <a href="https://github.com/lset0ng">lset0ng</a></p>
