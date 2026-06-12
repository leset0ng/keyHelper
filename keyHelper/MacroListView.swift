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
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
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
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.4))
            Text("No Macros Yet")
                .font(.title3.bold())
                .foregroundStyle(.secondary)
            Text("Click + to create your first macro")
                .font(.callout)
                .foregroundStyle(.secondary.opacity(0.7))
            Spacer()
        }
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

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.8)

            VStack(alignment: .leading, spacing: 2) {
                Text(macro.name)
                    .font(.system(.body, design: .default).weight(.medium))

                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Image(systemName: "hand.tap")
                            .font(.caption2)
                        Text(macro.triggerDisplay)
                            .font(.caption)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)

                    Text("·")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(macro.stepCount) step\(macro.stepCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(0.03), radius: 2, x: 0, y: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    MacroListView()
}
