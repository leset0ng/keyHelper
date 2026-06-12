//
//  GlobalKeyMonitor.swift
//  keyHelper
//

import Cocoa
import CoreGraphics
import Carbon
import Combine

class GlobalKeyMonitor: ObservableObject {
    static let shared = GlobalKeyMonitor()

    @Published var isMonitoring = false
    @Published var accessibilityGranted = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var monitorQueue: DispatchQueue?

    private var store: MacroStore { MacroStore.shared }

    private init() {
        checkAccessibility()
    }

    func checkAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        accessibilityGranted = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    func startMonitoring() {
        guard accessibilityGranted else {
            checkAccessibility()
            return
        }

        stopMonitoring()

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                GlobalKeyMonitor.handleEvent(proxy: proxy, type: type, event: event, refcon: refcon)
            },
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        ) else {
            print("Failed to create event tap. Please grant Accessibility permission.")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        let queue = DispatchQueue(label: "com.keyhelper.monitor", qos: .userInteractive)
        monitorQueue = queue
        queue.async { [weak self] in
            guard let self = self, let source = self.runLoopSource else { return }
            let runLoop = CFRunLoopGetCurrent()
            let mode = CFRunLoopMode.commonModes
            CFRunLoopAddSource(runLoop, source, mode)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }

        isMonitoring = true
        print("Started monitoring \(store.enabledMacros().count) enabled macros")
    }

    func stopMonitoring() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopSourceInvalidate(source)
        }
        eventTap = nil
        runLoopSource = nil
        isMonitoring = false
        print("Stopped monitoring")
    }

    private static func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
        let monitor = Unmanaged<GlobalKeyMonitor>.fromOpaque(refcon!).takeUnretainedValue()

        guard type == .keyDown || type == .keyUp else {
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let modifierFlags: CGEventFlags = [.maskCommand, .maskShift, .maskAlternate, .maskControl, .maskSecondaryFn, .maskAlphaShift]
        let filteredFlags = flags.intersection(modifierFlags)

        // Check against all enabled macros
        for macro in monitor.store.enabledMacros() {
            for trigger in macro.triggers {
                let triggerModifiers = trigger.modifiers.intersection(modifierFlags)
                let modifiersMatch = triggerModifiers.isEmpty || filteredFlags == triggerModifiers

                if keyCode == Int64(trigger.keyCode), modifiersMatch, type == .keyDown {
                    // Consume the trigger and execute the macro
                    DispatchQueue.global(qos: .userInitiated).async {
                        MacroExecutor.execute(macro: macro)
                    }
                    return nil // Consume the event
                }
            }
        }

        return Unmanaged.passUnretained(event)
    }
}
