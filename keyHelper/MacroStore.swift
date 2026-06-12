//
//  MacroStore.swift
//  keyHelper
//

import Foundation
import Combine
import Carbon
import SwiftUI

class MacroStore: ObservableObject {
    static let shared = MacroStore()
    private let defaults = UserDefaults.standard
    private let key = "keyhelper.macros"

    @Published var macros: [Macro] = []

    private init() {
        load()
    }

    func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Macro].self, from: data) else {
            // Default demo macro
            macros = [
                Macro(
                    name: "Paste",
                    triggers: [KeyCombo(keyCode: kVK_F6, modifiers: [], name: "F6")],
                    steps: [
                        .keyCombo(KeyCombo(keyCode: kVK_ANSI_V, modifiers: .maskCommand, name: "⌘V"))
                    ],
                    isEnabled: true
                )
            ]
            return
        }
        macros = decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(macros) {
            defaults.set(data, forKey: key)
        }
    }

    func add(_ macro: Macro) {
        macros.append(macro)
        save()
    }

    func update(_ macro: Macro) {
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            macros[index] = macro
            save()
        }
    }

    func delete(_ macro: Macro) {
        macros.removeAll { $0.id == macro.id }
        save()
    }

    func delete(at offsets: IndexSet) {
        macros.removeAll { macro in
            guard let index = macros.firstIndex(where: { $0.id == macro.id }) else { return false }
            return offsets.contains(index)
        }
        save()
    }

    func toggleEnabled(_ macro: Macro) {
        if let index = macros.firstIndex(where: { $0.id == macro.id }) {
            macros[index].isEnabled.toggle()
            save()
        }
    }

    func enabledMacros() -> [Macro] {
        macros.filter { $0.isEnabled }
    }
}
