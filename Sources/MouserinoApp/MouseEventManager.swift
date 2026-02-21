import AppKit
import ApplicationServices
import SwiftUI

@MainActor
final class MouseEventManager: ObservableObject {
    @Published var store = SettingsStore()
    @Published var statusMessage = String(localized: "Ready", bundle: .module)
    @Published var hasAccessibilityPermission = false
    @Published var learningControl: MouseControl?

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    nonisolated private static let syntheticSmoothEventTag: Int64 = 0x4D53524E
    nonisolated private static let smoothScrollQueue = DispatchQueue(label: "mouserino.smooth-scroll", qos: .userInteractive)

    init() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        startIfNeeded()
    }

    func requestAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.hasAccessibilityPermission = AXIsProcessTrusted()
                self.startIfNeeded()
            }
        }
    }

    func restart() {
        stop()
        startIfNeeded()
    }

    func saveSettings() {
        store.save()
        restart()
    }

    func persistMappings() {
        store.save()
    }

    func startLearning(control: MouseControl) {
        learningControl = control
        statusMessage = String(localized: "Learning \(control.rawValue): press target mouse button once", bundle: .module)
    }

    func stopLearning() {
        learningControl = nil
        statusMessage = String(localized: "Learning cancelled", bundle: .module)
    }

    func resetLearnedBinding(for control: MouseControl) {
        guard let index = store.mappings.firstIndex(where: { $0.control == control }) else { return }
        store.mappings[index].learnedButtonNumber = nil
        store.save()
        statusMessage = String(localized: "Reset \(control.rawValue) to default binding", bundle: .module)
    }

    private func startIfNeeded() {
        guard store.isEnabled else {
            statusMessage = String(localized: "Disabled", bundle: .module)
            return
        }

        guard AXIsProcessTrusted() else {
            statusMessage = String(localized: "Need Accessibility permission", bundle: .module)
            return
        }

        let mask =
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue)
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            guard type == .otherMouseDown || type == .scrollWheel else {
                return Unmanaged.passUnretained(event)
            }

            guard let refcon else {
                return Unmanaged.passUnretained(event)
            }

            let manager = Unmanaged<MouseEventManager>.fromOpaque(refcon).takeUnretainedValue()
            return manager.handleEvent(proxy: proxy, type: type, event: event)
        }

        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: callback,
            userInfo: selfPointer
        ) else {
            statusMessage = String(localized: "Failed to create event tap", bundle: .module)
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        guard let source = runLoopSource else {
            statusMessage = String(localized: "Failed to create run loop source", bundle: .module)
            return
        }

        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        statusMessage = String(localized: "Listening", bundle: .module)
    }

    private func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }

        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }

        eventTap = nil
        runLoopSource = nil
    }

    nonisolated private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .scrollWheel {
            return handleScrollEvent(event: event)
        }

        let button = event.getIntegerValueField(.mouseEventButtonNumber)
        let shouldConsume: Bool

        if Thread.isMainThread {
            shouldConsume = MainActor.assumeIsolated {
                handleButtonEventOnMain(button: button)
            }
        } else {
            shouldConsume = DispatchQueue.main.sync {
                MainActor.assumeIsolated {
                    handleButtonEventOnMain(button: button)
                }
            }
        }

        return shouldConsume ? nil : Unmanaged.passUnretained(event)
    }

    nonisolated private func handleScrollEvent(event: CGEvent) -> Unmanaged<CGEvent>? {
        let defaults = UserDefaults.standard
        let enabled = defaults.bool(forKey: SettingsKeys.enabled)
        guard enabled else {
            return Unmanaged.passUnretained(event)
        }

        if event.getIntegerValueField(.eventSourceUserData) == Self.syntheticSmoothEventTag {
            return Unmanaged.passUnretained(event)
        }

        let isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous)
        if isContinuous != 0 {
            return Unmanaged.passUnretained(event)
        }

        let invertVertical = defaults.bool(forKey: SettingsKeys.invertVerticalScroll)
        let invertHorizontal = defaults.bool(forKey: SettingsKeys.invertHorizontalScroll)
        let smoothEnabled = defaults.bool(forKey: SettingsKeys.smoothScrollEnabled)
        let smoothStrength = defaults.double(forKey: SettingsKeys.smoothScrollStrength)
        guard invertVertical || invertHorizontal || smoothEnabled else {
            return Unmanaged.passUnretained(event)
        }

        var vertical = readScrollAxis(event: event, intField: .scrollWheelEventDeltaAxis1, pointField: .scrollWheelEventPointDeltaAxis1, fixedField: .scrollWheelEventFixedPtDeltaAxis1)
        var horizontal = readScrollAxis(event: event, intField: .scrollWheelEventDeltaAxis2, pointField: .scrollWheelEventPointDeltaAxis2, fixedField: .scrollWheelEventFixedPtDeltaAxis2)

        if invertVertical {
            vertical = vertical.inverted()
        }

        if invertHorizontal {
            horizontal = horizontal.inverted()
        }

        if !smoothEnabled {
            writeScrollAxis(event: event, axis: vertical, intField: .scrollWheelEventDeltaAxis1, pointField: .scrollWheelEventPointDeltaAxis1, fixedField: .scrollWheelEventFixedPtDeltaAxis1)
            writeScrollAxis(event: event, axis: horizontal, intField: .scrollWheelEventDeltaAxis2, pointField: .scrollWheelEventPointDeltaAxis2, fixedField: .scrollWheelEventFixedPtDeltaAxis2)
            return Unmanaged.passUnretained(event)
        }

        postSmoothScrollEvents(vertical: vertical, horizontal: horizontal, strength: smoothStrength)
        return nil
    }

    nonisolated private func readScrollAxis(
        event: CGEvent,
        intField: CGEventField,
        pointField: CGEventField,
        fixedField: CGEventField
    ) -> ScrollAxisDelta {
        ScrollAxisDelta(
            intValue: event.getIntegerValueField(intField),
            pointValue: event.getIntegerValueField(pointField),
            fixedValue: event.getIntegerValueField(fixedField)
        )
    }

    nonisolated private func writeScrollAxis(
        event: CGEvent,
        axis: ScrollAxisDelta,
        intField: CGEventField,
        pointField: CGEventField,
        fixedField: CGEventField
    ) {
        event.setIntegerValueField(intField, value: axis.intValue)
        event.setIntegerValueField(pointField, value: axis.pointValue)
        event.setIntegerValueField(fixedField, value: axis.fixedValue)
    }

    nonisolated private func postSmoothScrollEvents(vertical: ScrollAxisDelta, horizontal: ScrollAxisDelta, strength: Double) {
        let clampedStrength = min(max(strength, 0.15), 1.0)

        let verticalPixels = vertical.pixelValue
        let horizontalPixels = horizontal.pixelValue
        if verticalPixels == 0 && horizontalPixels == 0 {
            return
        }

        let parts = max(3, min(8, Int(3 + round(clampedStrength * 5))))
        let decay = 0.55 + (clampedStrength * 0.35)
        let interval = 0.0025 + (clampedStrength * 0.0015)
        let weights = Self.normalizedWeights(count: parts, decay: decay)

        let verticalChunks = Self.distribute(value: verticalPixels, weights: weights)
        let horizontalChunks = Self.distribute(value: horizontalPixels, weights: weights)

        Self.smoothScrollQueue.async {
            for index in 0..<parts {
                let v = verticalChunks[index]
                let h = horizontalChunks[index]
                if v == 0 && h == 0 {
                    continue
                }

                guard let scrollEvent = CGEvent(
                    scrollWheelEvent2Source: nil,
                    units: .pixel,
                    wheelCount: 2,
                    wheel1: Int32(v),
                    wheel2: Int32(h),
                    wheel3: 0
                ) else {
                    continue
                }

                scrollEvent.setIntegerValueField(.eventSourceUserData, value: Self.syntheticSmoothEventTag)
                scrollEvent.post(tap: .cghidEventTap)

                if index < parts - 1 {
                    Thread.sleep(forTimeInterval: interval)
                }
            }
        }
    }

    nonisolated private static func normalizedWeights(count: Int, decay: Double) -> [Double] {
        guard count > 0 else { return [] }

        var weights: [Double] = []
        weights.reserveCapacity(count)

        var sum = 0.0
        for i in 0..<count {
            let w = pow(decay, Double(i))
            weights.append(w)
            sum += w
        }

        guard sum != 0 else {
            return Array(repeating: 1.0 / Double(count), count: count)
        }

        return weights.map { $0 / sum }
    }

    nonisolated private static func distribute(value: Int64, weights: [Double]) -> [Int64] {
        guard !weights.isEmpty else { return [] }
        if value == 0 {
            return Array(repeating: 0, count: weights.count)
        }

        var chunks = Array(repeating: Int64(0), count: weights.count)
        var remaining = value

        for index in 0..<weights.count {
            if index == weights.count - 1 {
                chunks[index] = remaining
                break
            }

            let proposed = Int64((Double(value) * weights[index]).rounded())
            chunks[index] = proposed
            remaining -= proposed
        }

        return chunks
    }

    @MainActor
    private func handleButtonEventOnMain(button: Int64) -> Bool {
        guard store.isEnabled else { return false }

        statusMessage = String(localized: "Mouse button: \(button)", bundle: .module)

        if let learningControl {
            applyLearnedBinding(control: learningControl, button: button)
            return true
        }

        guard let mapping = store.mappings.first(where: {
            $0.matchedButtonNumbers.contains(button)
        }) else {
            // Unknown buttons should pass through to keep native behavior.
            return false
        }

        if mapping.action == .none {
            statusMessage = String(localized: "Mapped to: No Action", bundle: .module)
            return true
        }

        trigger(action: mapping.action)
        statusMessage = String(localized: "Triggered: \(mapping.action.rawValue)", bundle: .module)
        return true
    }

    private func applyLearnedBinding(control: MouseControl, button: Int64) {
        guard let index = store.mappings.firstIndex(where: { $0.control == control }) else { return }

        store.mappings[index].learnedButtonNumber = button
        store.save()
        learningControl = nil
        statusMessage = String(localized: "Learned \(control.rawValue) -> Button \(button)", bundle: .module)
    }

    @MainActor
    private func trigger(action: ActionType) {
        let shortcuts: [(CGKeyCode, CGEventFlags)]
        switch action {
        case .none:
            return
        case .missionControl:
            shortcuts = [(160, [])]
        case .appExpose:
            shortcuts = [(125, .maskControl)] // Ctrl + Down
        case .launchpad:
            shortcuts = [(131, [])] // Launchpad key
        case .showDesktop:
            shortcuts = [(160, .maskCommand)] // Cmd + Mission Control
        case .volumeUp:
            postMediaKeyEvent(key: 0, down: true)
            postMediaKeyEvent(key: 0, down: false)
            return
        case .volumeDown:
            postMediaKeyEvent(key: 1, down: true)
            postMediaKeyEvent(key: 1, down: false)
            return
        case .volumeMute:
            postMediaKeyEvent(key: 7, down: true)
            postMediaKeyEvent(key: 7, down: false)
            return
        }

        for (keyCode, flags) in shortcuts {
            postKeyEvent(keyCode: keyCode, flags: flags, down: true)
            postKeyEvent(keyCode: keyCode, flags: flags, down: false)
        }
    }

    private func postKeyEvent(keyCode: CGKeyCode, flags: CGEventFlags, down: Bool) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: down) else {
            return
        }

        if !flags.isEmpty {
            event.flags = flags
        }
        event.post(tap: .cghidEventTap)
    }

    private func postMediaKeyEvent(key: Int32, down: Bool) {
        let keyCommand = (key << 16) | ((down ? 0xa : 0xb) << 8)
        let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int(keyCommand),
            data2: -1
        )?.cgEvent
        event?.post(tap: .cghidEventTap)
    }
}

private struct ScrollAxisDelta {
    let intValue: Int64
    let pointValue: Int64
    let fixedValue: Int64

    var pixelValue: Int64 {
        if pointValue != 0 {
            return pointValue
        }

        if fixedValue != 0 {
            return fixedValue / 65536
        }

        // Line-based wheel events are mapped to pixels with a conservative scale.
        return intValue * 10
    }

    func inverted() -> ScrollAxisDelta {
        ScrollAxisDelta(
            intValue: -intValue,
            pointValue: -pointValue,
            fixedValue: -fixedValue
        )
    }
}
