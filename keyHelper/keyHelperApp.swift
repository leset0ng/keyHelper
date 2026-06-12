//
//  keyHelperApp.swift
//  keyHelper
//

import SwiftUI
import ServiceManagement

@main
struct keyHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 520, minHeight: 420)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About KeyHelper") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            .applicationName: "KeyHelper",
                            .applicationVersion: "1.0",
                            .credits: NSAttributedString(string: "Global key macro automation")
                        ]
                    )
                }
            }
        }

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        GlobalKeyMonitor.shared.checkAccessibility()

        // Apply dock icon preference
        let hideDock = UserDefaults.standard.bool(forKey: "hideDockIcon")
        if hideDock {
            NSApp.setActivationPolicy(.accessory)
        }

        // Auto-start monitoring if enabled
        let autoStart = UserDefaults.standard.bool(forKey: "autoStartMonitoring")
        if autoStart {
            GlobalKeyMonitor.shared.startMonitoring()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
