//
//  MacroExecutor.swift
//  keyHelper
//

import Foundation
import CoreGraphics

class MacroExecutor {
    static func execute(macro: Macro) {
        print("Executing macro: \(macro.name)")
        for step in macro.steps {
            switch step {
            case .keyCombo(let combo):
                KeySimulator.simulate(combo: combo)
            case .text(let str):
                KeySimulator.typeText(str)
            case .delay(let seconds):
                usleep(useconds_t(seconds * 1_000_000))
            }
        }
    }
}
