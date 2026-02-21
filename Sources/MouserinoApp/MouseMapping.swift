import Foundation

enum MouseControl: String, CaseIterable, Identifiable, Codable {
    case sideForward = "Side Forward"
    case sideBack = "Side Back"
    case middleClick = "Middle Click"

    var id: String { rawValue }

    var buttonNumber: Int64 {
        switch self {
        case .middleClick: return 2
        case .sideBack: return 3
        case .sideForward: return 4
        }
    }

    // MX Master series can report side buttons differently across firmware/connection modes.
    // Keep a small compatibility set so forward/back can still be matched before learning.
    var compatibleButtonNumbers: Set<Int64> {
        switch self {
        case .middleClick:
            return [2]
        case .sideBack:
            return [3, 4, 8]
        case .sideForward:
            return [4, 5, 9]
        }
    }
}

enum ActionType: String, CaseIterable, Identifiable, Codable {
    case none = "No Action"
    case missionControl = "Mission Control"
    case appExpose = "App Expose"
    case launchpad = "Launchpad"
    case showDesktop = "Show Desktop"
    case volumeUp = "Volume Up"
    case volumeDown = "Volume Down"
    case volumeMute = "Volume Mute"

    var id: String { rawValue }
}

struct MouseMapping: Identifiable, Codable, Equatable {
    var id: String { control.id }
    var control: MouseControl
    var action: ActionType
    var learnedButtonNumber: Int64?

    var matchedButtonNumbers: Set<Int64> {
        if let learnedButtonNumber {
            return [learnedButtonNumber]
        }
        return control.compatibleButtonNumbers
    }

    var bindingSummary: String {
        if let learnedButtonNumber {
            return String(localized: "Button \(learnedButtonNumber) (Learned)", bundle: .module)
        }
        let sortedDefaults = control.compatibleButtonNumbers.sorted()
        let numbers = sortedDefaults.map(String.init).joined(separator: ", ")
        return String(localized: "Buttons \(numbers) (Default)", bundle: .module)
    }
}
