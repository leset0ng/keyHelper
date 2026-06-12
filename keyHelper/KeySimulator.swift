//
//  KeySimulator.swift
//  keyHelper
//

import CoreGraphics
import Carbon

class KeySimulator {
    static func simulate(combo: KeyCombo) {
        let keyCode = CGKeyCode(UInt16(combo.keyCode))
        let modifiers = combo.modifiers

        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else { return }
        keyDown.flags = modifiers

        guard let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else { return }
        keyUp.flags = modifiers

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }

    static func typeText(_ text: String) {
        for char in text {
            if let keyCode = keyCodeForCharacter(char) {
                let down = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
                let up = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
                down?.post(tap: .cghidEventTap)
                up?.post(tap: .cghidEventTap)
                usleep(5000) // 5ms between chars
            }
        }
    }

    private static func keyCodeForCharacter(_ char: Character) -> CGKeyCode? {
        let uppercase = String(char).uppercased()
        switch uppercase {
        case "A": return CGKeyCode(kVK_ANSI_A)
        case "B": return CGKeyCode(kVK_ANSI_B)
        case "C": return CGKeyCode(kVK_ANSI_C)
        case "D": return CGKeyCode(kVK_ANSI_D)
        case "E": return CGKeyCode(kVK_ANSI_E)
        case "F": return CGKeyCode(kVK_ANSI_F)
        case "G": return CGKeyCode(kVK_ANSI_G)
        case "H": return CGKeyCode(kVK_ANSI_H)
        case "I": return CGKeyCode(kVK_ANSI_I)
        case "J": return CGKeyCode(kVK_ANSI_J)
        case "K": return CGKeyCode(kVK_ANSI_K)
        case "L": return CGKeyCode(kVK_ANSI_L)
        case "M": return CGKeyCode(kVK_ANSI_M)
        case "N": return CGKeyCode(kVK_ANSI_N)
        case "O": return CGKeyCode(kVK_ANSI_O)
        case "P": return CGKeyCode(kVK_ANSI_P)
        case "Q": return CGKeyCode(kVK_ANSI_Q)
        case "R": return CGKeyCode(kVK_ANSI_R)
        case "S": return CGKeyCode(kVK_ANSI_S)
        case "T": return CGKeyCode(kVK_ANSI_T)
        case "U": return CGKeyCode(kVK_ANSI_U)
        case "V": return CGKeyCode(kVK_ANSI_V)
        case "W": return CGKeyCode(kVK_ANSI_W)
        case "X": return CGKeyCode(kVK_ANSI_X)
        case "Y": return CGKeyCode(kVK_ANSI_Y)
        case "Z": return CGKeyCode(kVK_ANSI_Z)
        case "0": return CGKeyCode(kVK_ANSI_0)
        case "1": return CGKeyCode(kVK_ANSI_1)
        case "2": return CGKeyCode(kVK_ANSI_2)
        case "3": return CGKeyCode(kVK_ANSI_3)
        case "4": return CGKeyCode(kVK_ANSI_4)
        case "5": return CGKeyCode(kVK_ANSI_5)
        case "6": return CGKeyCode(kVK_ANSI_6)
        case "7": return CGKeyCode(kVK_ANSI_7)
        case "8": return CGKeyCode(kVK_ANSI_8)
        case "9": return CGKeyCode(kVK_ANSI_9)
        case " ": return CGKeyCode(kVK_Space)
        case "\n": return CGKeyCode(kVK_Return)
        case "\t": return CGKeyCode(kVK_Tab)
        case ".": return CGKeyCode(kVK_ANSI_Period)
        case ",": return CGKeyCode(kVK_ANSI_Comma)
        case ";": return CGKeyCode(kVK_ANSI_Semicolon)
        case "'": return CGKeyCode(kVK_ANSI_Quote)
        case "/": return CGKeyCode(kVK_ANSI_Slash)
        case "\\": return CGKeyCode(kVK_ANSI_Backslash)
        case "[": return CGKeyCode(kVK_ANSI_LeftBracket)
        case "]": return CGKeyCode(kVK_ANSI_RightBracket)
        case "-": return CGKeyCode(kVK_ANSI_Minus)
        case "=": return CGKeyCode(kVK_ANSI_Equal)
        case "`": return CGKeyCode(kVK_ANSI_Grave)
        default: return nil
        }
    }
}
