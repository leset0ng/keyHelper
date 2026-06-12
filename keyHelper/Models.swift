//
//  Models.swift
//  keyHelper
//

import Foundation
import CoreGraphics
import Carbon
import AppKit

enum MacroStep: Codable, Identifiable, Equatable {
    case keyCombo(KeyCombo)
    case text(String)
    case delay(Double)

    var id: String {
        switch self {
        case .keyCombo(let combo):
            return "key_\(combo.keyCode)_\(combo.modifiers.rawValue)"
        case .text(let str):
            return "text_\(str.hashValue)"
        case .delay(let seconds):
            return "delay_\(Int(seconds * 1000))"
        }
    }

    enum CodingKeys: String, CodingKey {
        case type, value, text, delay
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .keyCombo(let combo):
            try container.encode("keyCombo", forKey: .type)
            try container.encode(combo, forKey: .value)
        case .text(let str):
            try container.encode("text", forKey: .type)
            try container.encode(str, forKey: .text)
        case .delay(let seconds):
            try container.encode("delay", forKey: .type)
            try container.encode(seconds, forKey: .delay)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "keyCombo":
            let combo = try container.decode(KeyCombo.self, forKey: .value)
            self = .keyCombo(combo)
        case "text":
            let str = try container.decode(String.self, forKey: .text)
            self = .text(str)
        case "delay":
            let seconds = try container.decode(Double.self, forKey: .delay)
            self = .delay(seconds)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown step type: \(type)")
        }
    }

    var displayName: String {
        switch self {
        case .keyCombo(let combo):
            return combo.name
        case .text(let str):
            return "Text: \"\(str)\""
        case .delay(let seconds):
            return "Delay \(String(format: "%.2f", seconds))s"
        }
    }

    var icon: String {
        switch self {
        case .keyCombo: return "keyboard"
        case .text: return "textformat"
        case .delay: return "timer"
        }
    }
}

struct KeyCombo: Codable, Equatable, Hashable {
    let keyCode: Int
    let modifiers: CGEventFlags
    let name: String

    enum CodingKeys: String, CodingKey {
        case keyCode, modifiers, name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keyCode)
        hasher.combine(modifiers.rawValue)
        hasher.combine(name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(UInt64(modifiers.rawValue), forKey: .modifiers)
        try container.encode(name, forKey: .name)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try container.decode(Int.self, forKey: .keyCode)
        let rawValue = try container.decode(UInt64.self, forKey: .modifiers)
        modifiers = CGEventFlags(rawValue: rawValue)
        name = try container.decode(String.self, forKey: .name)
    }

    init(keyCode: Int, modifiers: CGEventFlags, name: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.name = name
    }

    var modifiersMatch: String {
        var parts: [String] = []
        if modifiers.contains(.maskCommand) { parts.append("⌘") }
        if modifiers.contains(.maskShift) { parts.append("⇧") }
        if modifiers.contains(.maskAlternate) { parts.append("⌥") }
        if modifiers.contains(.maskControl) { parts.append("⌃") }
        if modifiers.contains(.maskSecondaryFn) { parts.append("Fn") }
        return parts.joined()
    }
}

struct Macro: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var triggers: [KeyCombo]
    var steps: [MacroStep]
    var isEnabled: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, triggers, steps, isEnabled, createdAt
    }
    enum LegacyCodingKeys: String, CodingKey {
        case id, name, trigger, steps, isEnabled, createdAt
    }

    init(id: UUID = UUID(), name: String, triggers: [KeyCombo], steps: [MacroStep] = [], isEnabled: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.triggers = triggers
        self.steps = steps
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    init(id: UUID = UUID(), name: String, trigger: KeyCombo, steps: [MacroStep] = [], isEnabled: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.triggers = [trigger]
        self.steps = steps
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(triggers, forKey: .triggers)
        try container.encode(steps, forKey: .steps)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(createdAt, forKey: .createdAt)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        if container.contains(.triggers) {
            triggers = try container.decode([KeyCombo].self, forKey: .triggers)
        } else {
            let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)
            let trigger = try legacy.decode(KeyCombo.self, forKey: .trigger)
            triggers = [trigger]
        }
        steps = try container.decode([MacroStep].self, forKey: .steps)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    var stepCount: Int { steps.count }
    var triggerDisplay: String {
        triggers.map { $0.modifiersMatch + $0.name }.joined(separator: " / ")
    }
}

// MARK: - Key Name Utilities

struct KeyNames {
    static func name(for keyCode: Int) -> String {
        switch keyCode {
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        case kVK_Space: return "Space"
        case kVK_Return: return "Return"
        case kVK_Tab: return "Tab"
        case kVK_Delete: return "Delete"
        case kVK_ForwardDelete: return "Fwd Del"
        case kVK_Escape: return "Esc"
        case kVK_Home: return "Home"
        case kVK_End: return "End"
        case kVK_PageUp: return "PgUp"
        case kVK_PageDown: return "PgDn"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_ANSI_Minus: return "-"
        case kVK_ANSI_Equal: return "="
        case kVK_ANSI_LeftBracket: return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Backslash: return "\\"
        case kVK_ANSI_Semicolon: return ";"
        case kVK_ANSI_Quote: return "'"
        case kVK_ANSI_Comma: return ","
        case kVK_ANSI_Period: return "."
        case kVK_ANSI_Slash: return "/"
        case kVK_ANSI_Grave: return "`"
        default: return "Key \(keyCode)"
        }
    }

    static func formattedName(keyCode: Int, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.function) { parts.append("Fn") }
        parts.append(name(for: keyCode))
        return parts.joined()
    }

    static func cgFormattedName(keyCode: Int, flags: CGEventFlags) -> String {
        var parts: [String] = []
        if flags.contains(.maskCommand) { parts.append("⌘") }
        if flags.contains(.maskShift) { parts.append("⇧") }
        if flags.contains(.maskAlternate) { parts.append("⌥") }
        if flags.contains(.maskControl) { parts.append("⌃") }
        if flags.contains(.maskSecondaryFn) { parts.append("Fn") }
        parts.append(name(for: keyCode))
        return parts.joined()
    }
}
