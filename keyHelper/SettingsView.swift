//
//  SettingsView.swift
//  keyHelper
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("hideDockIcon") private var hideDockIcon = false
    @AppStorage("autoStartMonitoring") private var autoStartMonitoring = false

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gear")
                }
        }
        .padding()
        .frame(width: 420, height: 260)
    }

    private var generalTab: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLoginItem(enabled: newValue)
                    }

                Toggle("Hide Dock Icon", isOn: $hideDockIcon)
                    .onChange(of: hideDockIcon) { _, newValue in
                        NSApp.setActivationPolicy(newValue ? .accessory : .regular)
                    }

                Toggle("Auto-start Monitoring", isOn: $autoStartMonitoring)
            } header: {
                Text("General")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accessibility")
                            .font(.headline)
                        Text("KeyHelper requires Accessibility permission to monitor global key events.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Button("Open Settings…") {
                        openAccessibilitySettings()
                    }
                    .controlSize(.small)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Permissions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func setLoginItem(enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "register" : "unregister") login item: \(error)")
            launchAtLogin = !enabled
        }
    }

    private func openAccessibilitySettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        )
    }
}
