import Foundation

enum SettingsKeys {
    static let enabled = "mouserino.enabled"
    static let mappings = "mouserino.mappings"
    static let invertVerticalScroll = "mouserino.scroll.invertVertical"
    static let invertHorizontalScroll = "mouserino.scroll.invertHorizontal"
    static let smoothScrollEnabled = "mouserino.scroll.smooth.enabled"
    static let smoothScrollStrength = "mouserino.scroll.smooth.strength"
}

@MainActor
final class SettingsStore: ObservableObject {
    @Published var isEnabled = true
    @Published var invertVerticalScroll = false
    @Published var invertHorizontalScroll = false
    @Published var smoothScrollEnabled = false
    @Published var smoothScrollStrength = 0.65
    @Published var mappings: [MouseMapping] = [
        MouseMapping(control: .sideBack, action: .missionControl),
        MouseMapping(control: .sideForward, action: .appExpose),
        MouseMapping(control: .middleClick, action: .showDesktop)
    ]

    private let defaults = UserDefaults.standard
    init() {
        load()
    }

    func save() {
        defaults.set(isEnabled, forKey: SettingsKeys.enabled)
        defaults.set(invertVerticalScroll, forKey: SettingsKeys.invertVerticalScroll)
        defaults.set(invertHorizontalScroll, forKey: SettingsKeys.invertHorizontalScroll)
        defaults.set(smoothScrollEnabled, forKey: SettingsKeys.smoothScrollEnabled)
        defaults.set(smoothScrollStrength, forKey: SettingsKeys.smoothScrollStrength)

        do {
            let data = try JSONEncoder().encode(mappings)
            defaults.set(data, forKey: SettingsKeys.mappings)
        } catch {
            print("Failed to save mappings: \(error)")
        }
    }

    private func load() {
        if defaults.object(forKey: SettingsKeys.enabled) != nil {
            isEnabled = defaults.bool(forKey: SettingsKeys.enabled)
        }

        if defaults.object(forKey: SettingsKeys.invertVerticalScroll) != nil {
            invertVerticalScroll = defaults.bool(forKey: SettingsKeys.invertVerticalScroll)
        }

        if defaults.object(forKey: SettingsKeys.invertHorizontalScroll) != nil {
            invertHorizontalScroll = defaults.bool(forKey: SettingsKeys.invertHorizontalScroll)
        }

        if defaults.object(forKey: SettingsKeys.smoothScrollEnabled) != nil {
            smoothScrollEnabled = defaults.bool(forKey: SettingsKeys.smoothScrollEnabled)
        }

        if defaults.object(forKey: SettingsKeys.smoothScrollStrength) != nil {
            smoothScrollStrength = defaults.double(forKey: SettingsKeys.smoothScrollStrength)
        }

        guard let data = defaults.data(forKey: SettingsKeys.mappings) else { return }
        do {
            mappings = try JSONDecoder().decode([MouseMapping].self, from: data)
        } catch {
            print("Failed to decode mappings: \(error)")
        }
    }
}
