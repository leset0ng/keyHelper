//
//  MacroEditorView.swift
//  keyHelper
//

import SwiftUI
import Carbon
import AppKit

struct MacroEditorView: View {
    @State var macro: Macro
    let onSave: (Macro) -> Void
    let onDelete: (Macro) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingStepPicker = false
    @State private var stepToEditIndex: Int?
    @State private var showingStepEditor = false

    var body: some View {
        ZStack {
            Color(NSColor.windowBackgroundColor).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                        // Name
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Name", systemImage: "tag")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextField("Macro name", text: $macro.name)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Trigger
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Triggers", systemImage: "hand.tap")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    macro.triggers.append(KeyCombo(keyCode: kVK_F6, modifiers: [], name: "F6"))
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.borderless)
                            }

                            if macro.triggers.isEmpty {
                                Text("No triggers. Tap + to add.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 6) {
                                    ForEach(Array(macro.triggers.enumerated()), id: \.offset) { index, _ in
                                        HStack(spacing: 8) {
                                            KeyComboRecorder(combo: Binding(
                                                get: { macro.triggers[index] },
                                                set: { macro.triggers[index] = $0 }
                                            ))

                                            Button {
                                                macro.triggers.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark")
                                                    .font(.caption)
                                                    .foregroundStyle(.red)
                                            }
                                            .buttonStyle(.borderless)
                                        }
                                    }
                                }
                            }
                        }

                        // Steps
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label("Steps", systemImage: "list.number")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button {
                                    showingStepPicker = true
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.borderless)
                            }

                            if macro.steps.isEmpty {
                                Text("No steps yet. Tap + to add.")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 20)
                            } else {
                                VStack(spacing: 6) {
                                    ForEach(Array(macro.steps.enumerated()), id: \.offset) { index, step in
                                        StepRow(
                                            index: index + 1,
                                            step: step,
                                            onEdit: {
                                                stepToEditIndex = index
                                                showingStepEditor = true
                                            },
                                            onDelete: {
                                                macro.steps.remove(at: index)
                                            }
                                        )
                                    }
                                }
                            }
                        }

                        // Delete Button
                        Button(role: .destructive) {
                            onDelete(macro)
                        } label: {
                            Label("Delete Macro", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .padding(.top, 20)

                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                }
        }
        .frame(minWidth: 460, minHeight: 500)
        .navigationTitle("Edit Macro")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { dismiss() }) {
                    Label("Cancel", systemImage: "xmark")
                        .labelStyle(.iconOnly)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: { onSave(macro) }) {
                    Label("Save", systemImage: "checkmark")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showingStepPicker) {
            StepPickerSheet { selectedStep in
                macro.steps.append(selectedStep)
                showingStepPicker = false
            }
        }
        .sheet(isPresented: $showingStepEditor) {
            if let index = stepToEditIndex, index < macro.steps.count {
                let step = macro.steps[index]
                StepEditorSheet(step: step, onSave: { updatedStep in
                    macro.steps[index] = updatedStep
                    showingStepEditor = false
                    stepToEditIndex = nil
                })
            }
        }
    }
}

// MARK: - Key Combo Recorder

struct KeyComboRecorder: View {
    @Binding var combo: KeyCombo
    @State private var isRecording = false
    @State private var localMonitor: Any?

    var body: some View {
        HStack {
            Text(isRecording ? "Press a key combination..." : combo.modifiersMatch + combo.name)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(isRecording ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isRecording ? Color.red.opacity(0.08) : Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isRecording ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )
                .onTapGesture {
                    toggleRecording()
                }

            Button(action: toggleRecording) {
                Image(systemName: isRecording ? "stop.circle.fill" : "record.circle")
                    .font(.title2)
                    .foregroundStyle(isRecording ? .red : Color.accentColor)
            }
            .buttonStyle(.borderless)
        }
        .onAppear {
            if isRecording {
                startLocalMonitor()
            }
        }
        .onDisappear {
            stopLocalMonitor()
        }
    }

    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            startLocalMonitor()
        } else {
            stopLocalMonitor()
        }
    }

    private func startLocalMonitor() {
        stopLocalMonitor()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = Int(event.keyCode)
            let flags = event.modifierFlags
            var cgFlags: CGEventFlags = []
            if flags.contains(.command) { cgFlags.insert(.maskCommand) }
            if flags.contains(.shift) { cgFlags.insert(.maskShift) }
            if flags.contains(.option) { cgFlags.insert(.maskAlternate) }
            if flags.contains(.control) { cgFlags.insert(.maskControl) }
            if flags.contains(.function) { cgFlags.insert(.maskSecondaryFn) }

            let name = KeyNames.cgFormattedName(keyCode: keyCode, flags: cgFlags)
            combo = KeyCombo(keyCode: keyCode, modifiers: cgFlags, name: name)

            isRecording = false
            stopLocalMonitor()
            return nil
        }
    }

    private func stopLocalMonitor() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
    }
}

// MARK: - Step Row

struct StepRow: View {
    let index: Int
    let step: MacroStep
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text("\(index)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.secondary.opacity(0.1)))

            Image(systemName: step.icon)
                .font(.body)
                .foregroundStyle(.tint)
                .frame(width: 20)

            Text(step.displayName)
                .font(.body)
                .lineLimit(1)

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.borderless)

            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
    }
}

// MARK: - Step Picker Sheet

struct StepPickerSheet: View {
    let onSelect: (MacroStep) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Add Step")
                .font(.headline)
                .padding(.top, 16)

            VStack(spacing: 8) {
                Button {
                    onSelect(.keyCombo(KeyCombo(keyCode: kVK_ANSI_A, modifiers: [], name: "A")))
                } label: {
                    stepButtonLabel(icon: "keyboard", title: "Key Combination", subtitle: "Simulate a keyboard shortcut")
                }
                .buttonStyle(.plain)

                Button {
                    onSelect(.text(""))
                } label: {
                    stepButtonLabel(icon: "textformat", title: "Text Input", subtitle: "Type a string of text")
                }
                .buttonStyle(.plain)

                Button {
                    onSelect(.delay(0.1))
                } label: {
                    stepButtonLabel(icon: "timer", title: "Delay", subtitle: "Wait for a specified time")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .padding(.bottom, 16)
        }
        .frame(width: 320)
    }

    private func stepButtonLabel(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Step Editor Sheet

struct StepEditorSheet: View {
    let step: MacroStep
    let onSave: (MacroStep) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var textValue: String = ""
    @State private var delayValue: Double = 0.1
    @State private var keyCombo: KeyCombo = KeyCombo(keyCode: kVK_ANSI_A, modifiers: [], name: "A")

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Step")
                .font(.headline)
                .padding(.top, 16)

            switch step {
            case .keyCombo(let combo):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Combination")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    VirtualKeyboardView(combo: $keyCombo)
                }
                .padding(.horizontal, 16)
                .onAppear {
                    keyCombo = combo
                }

            case .text(let str):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Text to Type")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    TextField("Enter text", text: $textValue)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal, 16)
                .onAppear {
                    textValue = str
                }

            case .delay(let seconds):
                VStack(alignment: .leading, spacing: 8) {
                    Text("Delay (seconds)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    HStack {
                        Slider(value: $delayValue, in: 0.01...2.0, step: 0.01)
                        Text(String(format: "%.2fs", delayValue))
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 60)
                    }
                }
                .padding(.horizontal, 16)
                .onAppear {
                    delayValue = seconds
                }
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Save") {
                    switch step {
                    case .keyCombo:
                        onSave(.keyCombo(keyCombo))
                    case .text:
                        onSave(.text(textValue))
                    case .delay:
                        onSave(.delay(delayValue))
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 420)
    }
}

// MARK: - Virtual Keyboard

struct VirtualKey: Identifiable {
    var id: Int { keyCode }
    let keyCode: Int
    let label: String
    let widthMultiplier: CGFloat
    let modifierFlag: CGEventFlags?
}

struct VirtualKeyboardView: View {
    @Binding var combo: KeyCombo
    @State private var activeModifiers: CGEventFlags

    private let baseKeyWidth: CGFloat = 24
    private let keyHeight: CGFloat = 26
    private let keySpacing: CGFloat = 3

    init(combo: Binding<KeyCombo>) {
        self._combo = combo
        self._activeModifiers = State(initialValue: combo.wrappedValue.modifiers)
    }

    private var keyboardRows: [[VirtualKey]] {
        [
            // F-keys
            [
                VirtualKey(keyCode: kVK_F1, label: "F1", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F2, label: "F2", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F3, label: "F3", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F4, label: "F4", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F5, label: "F5", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F6, label: "F6", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F7, label: "F7", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F8, label: "F8", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F9, label: "F9", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F10, label: "F10", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F11, label: "F11", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_F12, label: "F12", widthMultiplier: 1, modifierFlag: nil),
            ],
            // Number row
            [
                VirtualKey(keyCode: kVK_ANSI_Grave, label: "`", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_1, label: "1", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_2, label: "2", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_3, label: "3", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_4, label: "4", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_5, label: "5", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_6, label: "6", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_7, label: "7", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_8, label: "8", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_9, label: "9", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_0, label: "0", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Minus, label: "-", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Equal, label: "=", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_Delete, label: "⌫", widthMultiplier: 1.25, modifierFlag: nil),
            ],
            // QWERTY row
            [
                VirtualKey(keyCode: kVK_Tab, label: "Tab", widthMultiplier: 1.25, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Q, label: "Q", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_W, label: "W", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_E, label: "E", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_R, label: "R", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_T, label: "T", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Y, label: "Y", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_U, label: "U", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_I, label: "I", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_O, label: "O", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_P, label: "P", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_LeftBracket, label: "[", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_RightBracket, label: "]", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Backslash, label: "\\", widthMultiplier: 1, modifierFlag: nil),
            ],
            // ASDF row
            [
                VirtualKey(keyCode: kVK_ANSI_A, label: "A", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_S, label: "S", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_D, label: "D", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_F, label: "F", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_G, label: "G", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_H, label: "H", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_J, label: "J", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_K, label: "K", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_L, label: "L", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Semicolon, label: ";", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Quote, label: "'", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_Return, label: "↩", widthMultiplier: 1.5, modifierFlag: nil),
            ],
            // ZXCV row
            [
                VirtualKey(keyCode: kVK_ANSI_Z, label: "Z", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_X, label: "X", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_C, label: "C", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_V, label: "V", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_B, label: "B", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_N, label: "N", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_M, label: "M", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Comma, label: ",", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Period, label: ".", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_ANSI_Slash, label: "/", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_Shift, label: "⇧", widthMultiplier: 1.5, modifierFlag: .maskShift),
            ],
            // Bottom row
            [
                VirtualKey(keyCode: kVK_Escape, label: "Esc", widthMultiplier: 1.25, modifierFlag: nil),
                VirtualKey(keyCode: kVK_Control, label: "⌃", widthMultiplier: 1.25, modifierFlag: .maskControl),
                VirtualKey(keyCode: kVK_Option, label: "⌥", widthMultiplier: 1.25, modifierFlag: .maskAlternate),
                VirtualKey(keyCode: kVK_Command, label: "⌘", widthMultiplier: 1.25, modifierFlag: .maskCommand),
                VirtualKey(keyCode: kVK_Space, label: "Space", widthMultiplier: 3.5, modifierFlag: nil),
                VirtualKey(keyCode: kVK_LeftArrow, label: "←", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_DownArrow, label: "↓", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_UpArrow, label: "↑", widthMultiplier: 1, modifierFlag: nil),
                VirtualKey(keyCode: kVK_RightArrow, label: "→", widthMultiplier: 1, modifierFlag: nil),
            ],
        ]
    }

    var body: some View {
        VStack(spacing: 8) {
            // Selected combo display
            HStack {
                Text(combo.name.isEmpty ? "Press a key..." : combo.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(combo.name.isEmpty ? .secondary : .primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
            )

            // Keyboard
            VStack(spacing: keySpacing) {
                ForEach(Array(keyboardRows.enumerated()), id: \.offset) { rowIndex, row in
                    HStack(spacing: keySpacing) {
                        if rowIndex == 3 {
                            Spacer().frame(width: baseKeyWidth * 0.5)
                        } else if rowIndex == 4 {
                            Spacer().frame(width: baseKeyWidth * 1.0)
                        }

                        ForEach(row) { key in
                            KeyButton(
                                key: key,
                                baseWidth: baseKeyWidth,
                                height: keyHeight,
                                combo: combo,
                                activeModifiers: activeModifiers,
                                onTap: { selectKey(key) }
                            )
                        }

                        Spacer()
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.underPageBackgroundColor))
            )
        }
    }

    private func selectKey(_ key: VirtualKey) {
        if let flag = key.modifierFlag {
            // Toggle modifier
            if activeModifiers.contains(flag) {
                activeModifiers.remove(flag)
            } else {
                activeModifiers.insert(flag)
            }
            // Update combo name with current modifiers
            let name = KeyNames.cgFormattedName(keyCode: combo.keyCode, flags: activeModifiers)
            combo = KeyCombo(keyCode: combo.keyCode, modifiers: activeModifiers, name: name)
        } else {
            let name = KeyNames.cgFormattedName(keyCode: key.keyCode, flags: activeModifiers)
            combo = KeyCombo(keyCode: key.keyCode, modifiers: activeModifiers, name: name)
        }
    }
}

struct KeyButton: View {
    let key: VirtualKey
    let baseWidth: CGFloat
    let height: CGFloat
    let combo: KeyCombo
    let activeModifiers: CGEventFlags
    let onTap: () -> Void

    var isSelected: Bool {
        if let flag = key.modifierFlag {
            return activeModifiers.contains(flag)
        }
        return combo.keyCode == key.keyCode
    }

    var body: some View {
        Button(action: onTap) {
            Text(key.label)
                .font(.system(size: 11, weight: .medium))
                .frame(width: baseWidth * key.widthMultiplier, height: height)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MacroEditorView(
        macro: Macro(
            name: "Test",
            trigger: KeyCombo(keyCode: kVK_F6, modifiers: [], name: "F6"),
            steps: [
                .keyCombo(KeyCombo(keyCode: kVK_ANSI_V, modifiers: .maskCommand, name: "⌘V")),
                .delay(0.1),
                .text("Hello")
            ],
            isEnabled: true
        ),
        onSave: { _ in },
        onDelete: { _ in }
    )
}
