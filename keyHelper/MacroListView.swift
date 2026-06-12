//
//  MacroListView.swift
//  keyHelper
//

import SwiftUI
import Carbon

struct MacroListView: View {
    @StateObject private var store = MacroStore.shared
    @StateObject private var monitor = GlobalKeyMonitor.shared

    @State private var showingEditor = false
    @State private var editingMacro: Macro?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(NSColor.windowBackgroundColor)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    accessibilityBar
                    if store.macros.isEmpty {
                        emptyState
                    } else {
                        macroList
                    }
                }
            }
            .navigationTitle("KeyHelper")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addNewMacro) {
                        Label("Add Macro", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.bordered)
                }
                ToolbarItem(placement: .automatic) {
                    SettingsLink {
                        Label("Settings", systemImage: "gear")
                            .labelStyle(.iconOnly)
                    }
                    .buttonStyle(.bordered)
                }
                ToolbarItem(placement: .automatic) {
                    Button(action: toggleGlobalMonitoring) {
                        HStack(spacing: 4) {
                            Image(systemName: monitor.isMonitoring ? "stop.fill" : "play.fill")
                            Text(monitor.isMonitoring ? "Stop" : "Start")
                        }
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(monitor.isMonitoring ? .red : .green)
                    .disabled(!monitor.accessibilityGranted)
                }
            }
            .navigationDestination(isPresented: $showingEditor) {
                if let macro = editingMacro {
                    MacroEditorView(
                        macro: macro,
                        onSave: { updated in
                            if store.macros.contains(where: { $0.id == updated.id }) {
                                store.update(updated)
                            } else {
                                store.add(updated)
                            }
                            showingEditor = false
                            editingMacro = nil
                            refreshMonitoring()
                        },
                        onDelete: { macroToDelete in
                            store.delete(macroToDelete)
                            showingEditor = false
                            editingMacro = nil
                            refreshMonitoring()
                        }
                    )
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            monitor.checkAccessibility()
        }
    }

    private var accessibilityBar: some View {
        HStack(spacing: 8) {
            Image(systemName: monitor.accessibilityGranted ? "checkmark.shield.fill" : "exclamationmark.shield")
                .foregroundStyle(monitor.accessibilityGranted ? .green : .orange)
                .font(.caption)

            Text(monitor.accessibilityGranted ? "Accessibility access granted" : "Accessibility access required")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            if !monitor.accessibilityGranted {
                Button("Open Settings") {
                    openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
                .tint(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            monitor.accessibilityGranted
                ? Color.green.opacity(0.06)
                : Color.orange.opacity(0.06)
        )
    }

    private var macroList: some View {
        List {
            ForEach(Array(store.macros.enumerated()), id: \.element.id) { index, macro in
                MacroRow(
                    macro: macro,
                    isOn: Binding(
                        get: { store.macros[index].isEnabled },
                        set: { newValue in
                            store.macros[index].isEnabled = newValue
                            store.save()
                            refreshMonitoring()
                        }
                    ),
                    onTap: {
                        editingMacro = store.macros[index]
                        showingEditor = true
                    }
                )
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .onDelete { offsets in
                store.delete(at: offsets)
                refreshMonitoring()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tertiary)
                .symbolRenderingMode(.hierarchical)
            Text("No Macros")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Click the + button to create your first macro")
                .font(.callout)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func toggleGlobalMonitoring() {
        if monitor.isMonitoring {
            monitor.stopMonitoring()
        } else {
            monitor.startMonitoring()
        }
    }

    private func addNewMacro() {
        let newMacro = Macro(
            name: "New Macro",
            triggers: [KeyCombo(keyCode: kVK_F6, modifiers: [], name: "F6")],
            steps: [],
            isEnabled: true
        )
        editingMacro = newMacro
        showingEditor = true
    }

    private func refreshMonitoring() {
        if monitor.isMonitoring {
            monitor.stopMonitoring()
            monitor.startMonitoring()
        }
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            monitor.checkAccessibility()
        }
    }
}

struct MacroRow: View {
    let macro: Macro
    @Binding var isOn: Bool
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.85)

            VStack(alignment: .leading, spacing: 4) {
                Text(macro.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    TriggerBadge(text: macro.triggerDisplay)

                    Text("·")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text("\(macro.stepCount) step\(macro.stepCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.forward")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
                .opacity(isHovered ? 1 : 0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(NSColor.separatorColor).opacity(0.4), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 1, x: 0, y: 0.5)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Trigger Badge

struct TriggerBadge: View {
    let text: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "hand.tap")
                .font(.system(size: 9, weight: .medium))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.accentColor.opacity(0.1))
        .foregroundColor(.accentColor)
        .clipShape(Capsule())
    }
}

#Preview {
    MacroListView()
}
