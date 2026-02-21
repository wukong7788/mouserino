import SwiftUI
import ServiceManagement

// MARK: - Card Style

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(.background.opacity(0.6))
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let icon: String
    let title: LocalizedStringKey
    let bundle: Bundle

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title, bundle: bundle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .padding(.bottom, 6)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject private var manager: MouseEventManager
    @AppStorage("startAtLogin") private var startAtLogin = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                globalSection
                mappingSection
                scrollSection
                smoothSection
                permissionSection
                statusBar
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { manager.restart() }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "computermouse.fill")
                .font(.system(size: 32))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Mouserino", bundle: .module))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(String(localized: "Minimal Logitech Options alternative for MX Master 3", bundle: .module))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.bottom, 4)
    }

    // MARK: Global Section

    private var globalSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "power.circle.fill", title: "Global Switch", bundle: .module)
            VStack(spacing: 2) {
                modernToggleRow(icon: "computermouse", title: "Enable MX Master 3 mappings", isOn: $manager.store.isEnabled, onChange: { manager.saveSettings() })
                Divider().padding(.vertical, 4)
                modernStartAtLoginRow
            }
        }
        .cardStyle()
    }

    private var modernStartAtLoginRow: some View {
        HStack {
            Image(systemName: "arrow.up.right.circle")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(String(localized: "Start at Login", bundle: .module))
            Spacer()
            Toggle("", isOn: $startAtLogin)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: startAtLogin) { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        startAtLogin = false
                        manager.statusMessage = String(localized: "Failed to set login item: \(error.localizedDescription)", bundle: .module)
                    }
                }
                .onAppear {
                    startAtLogin = SMAppService.mainApp.status == .enabled
                }
        }
    }

    // MARK: Mapping Section

    private var mappingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "hand.tap.fill", title: "Button Mapping", bundle: .module)
            VStack(spacing: 8) {
                ForEach($manager.store.mappings) { $mapping in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(LocalizedStringKey(mapping.control.rawValue), bundle: .module)
                                .font(.system(size: 13, weight: .medium))
                                .frame(width: 140, alignment: .leading)

                            Picker(String(localized: "Action", bundle: .module), selection: $mapping.action) {
                                ForEach(ActionType.allCases) { action in
                                    Text(LocalizedStringKey(action.rawValue), bundle: .module).tag(action)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }

                        HStack {
                            Text(mapping.bindingSummary)
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)

                            Spacer()

                            let isLearning = manager.learningControl == mapping.control
                            Button {
                                manager.startLearning(control: mapping.control)
                            } label: {
                                HStack(spacing: 4) {
                                    if isLearning {
                                        ProgressView().controlSize(.mini)
                                    }
                                    Text(isLearning ? String(localized: "Learning...", bundle: .module) : String(localized: "Learn", bundle: .module))
                                }
                            }
                            .disabled(manager.learningControl != nil && !isLearning)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(isLearning ? Color.orange : Color.accentColor)

                            Button(String(localized: "Reset", bundle: .module)) {
                                manager.resetLearnedBinding(for: mapping.control)
                            }
                            .disabled(mapping.learnedButtonNumber == nil)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                    if mapping.control != manager.store.mappings.last?.control {
                        Divider()
                    }
                }
            }
            .onChange(of: manager.store.mappings) { _ in manager.persistMappings() }
        }
        .cardStyle()
    }

    // MARK: Scroll Section

    private var scrollSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "scroll.fill", title: "Scroll Direction", bundle: .module)
            VStack(spacing: 2) {
                modernToggleRow(icon: "arrow.up.arrow.down", title: "Invert Vertical Scroll", isOn: $manager.store.invertVerticalScroll, onChange: { manager.saveSettings() })
                Divider().padding(.vertical, 2)
                modernToggleRow(icon: "arrow.left.arrow.right", title: "Invert Horizontal Scroll", isOn: $manager.store.invertHorizontalScroll, onChange: { manager.saveSettings() })
            }
        }
        .cardStyle()
    }

    // MARK: Smooth Scroll Section

    private var smoothSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "waveform.path.ecg", title: "Smooth Scroll", bundle: .module)
            VStack(spacing: 8) {
                modernToggleRow(icon: "slider.horizontal.3", title: "Enable Smooth Scrolling", isOn: $manager.store.smoothScrollEnabled, onChange: { manager.persistMappings() })

                HStack(spacing: 10) {
                    Text(LocalizedStringKey("Strength"), bundle: .module)
                        .font(.system(size: 13))
                        .foregroundStyle(manager.store.smoothScrollEnabled ? .primary : .secondary)
                    Slider(value: $manager.store.smoothScrollStrength, in: 0.15...1.0, step: 0.05)
                        .disabled(!manager.store.smoothScrollEnabled)
                        .onChange(of: manager.store.smoothScrollStrength) { _ in manager.persistMappings() }
                    Text("\(Int(manager.store.smoothScrollStrength * 100))%")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)
                }
                .animation(.easeInOut(duration: 0.2), value: manager.store.smoothScrollEnabled)
            }
        }
        .cardStyle()
    }

    // MARK: Permission Section

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(icon: "lock.shield.fill", title: "Permissions", bundle: .module)
            HStack(spacing: 10) {
                Image(systemName: manager.hasAccessibilityPermission ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(manager.hasAccessibilityPermission ? .green : .orange)
                Text(manager.hasAccessibilityPermission
                     ? String(localized: "Accessibility: Granted", bundle: .module)
                     : String(localized: "Accessibility: Missing", bundle: .module))
                    .font(.system(size: 13))
                Spacer()
                if !manager.hasAccessibilityPermission {
                    Button(String(localized: "Request Permission", bundle: .module)) {
                        manager.requestAccessibilityPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .controlSize(.small)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Status Bar

    private var statusBar: some View {
        HStack(spacing: 8) {
            if manager.learningControl != nil {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Circle()
                    .fill(manager.hasAccessibilityPermission && manager.store.isEnabled ? .green : .secondary)
                    .frame(width: 7, height: 7)
            }

            if let learningControl = manager.learningControl {
                Text(String(localized: "Learning mode: press the physical button for \(learningControl.rawValue), once.", bundle: .module))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.orange)
            } else {
                Text(String(localized: "Status: \(manager.statusMessage)"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 2)
    }

    // MARK: Helpers

    private func modernToggleRow(icon: String, title: LocalizedStringKey, isOn: Binding<Bool>, onChange: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(title, bundle: .module)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: isOn.wrappedValue) { _ in onChange() }
        }
    }
}
