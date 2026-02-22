import SwiftUI
import AppKit

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @StateObject private var keyboardManager = KeyboardRemapManager.shared
    
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case battery = "Battery"
        case keyboard = "Keyboard"
    }
    
    var body: some View {
        HStack(spacing: 0) {
            sidebar

            contentView
        }
        .frame(width: 700, height: 460)
        .background(
            ZStack {
                Color(nsColor: NSColor(calibratedWhite: 0.10, alpha: 1.0))
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.06),
                        Color.black.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .preferredColorScheme(.dark)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 0.9)
        )
        .background(SettingsWindowConfigurator())
        .onAppear {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Settings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.bottom, 8)

            ForEach(SettingsTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    HStack {
                        Image(systemName: iconForTab(tab))
                            .font(.system(size: 14))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 13))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedTab == tab ? Color.white.opacity(0.18) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(selectedTab == tab ? 0.25 : 0), lineWidth: 0.7)
                    )
                    .foregroundColor(.white.opacity(selectedTab == tab ? 0.96 : 0.72))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .padding(14)
        .frame(width: 210)
        .background(
            ZStack {
                Color.white.opacity(0.06)
                GlassBackground(material: .sidebar)
                    .opacity(0.55)
            }
        )
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .battery:
                    BatterySettingsView()
                case .keyboard:
                    KeyboardSettingsView()
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color.black.opacity(0.22)
                GlassBackground(material: .menu)
                    .opacity(0.45)
            }
            .overlay(
                Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 0.7)
            )
        )
    }
    
    private func iconForTab(_ tab: SettingsTab) -> String {
        switch tab {
        case .general:
            return "gearshape"
        case .battery:
            return "battery.100"
        case .keyboard:
            return "keyboard"
        }
    }
}

struct GeneralSettingsView: View {
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("General")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            glassCard {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                Toggle("Enable Haptic Feedback", isOn: $settings.hapticFeedbackEnabled)
            }

            glassCard {
                Text("About")
                    .font(.system(size: 16, weight: .semibold))

                HStack {
                    Text("Version:")
                    Text("1.0.0")
                        .foregroundColor(.white.opacity(0.72))
                }

                Text("Changes are saved automatically.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.66))
            }
        }
        .foregroundColor(.white.opacity(0.92))
    }
}

struct BatterySettingsView: View {
    @StateObject private var settings = AppSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Battery")
                .font(.system(size: 20, weight: .bold))

            glassCard {
                Toggle("Show Battery Notifications", isOn: $settings.showBatteryNotifications)

                Toggle("Show Charging Animation", isOn: $settings.showChargingAnimation)

                Divider()

                Text("Notifications will appear when:")
                    .font(.system(size: 13, weight: .medium))

                VStack(alignment: .leading, spacing: 8) {
                    Text("• Power adapter is connected/disconnected")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))

                    Text("• Battery reaches low power mode")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .foregroundColor(.white.opacity(0.92))
    }
}

struct KeyboardSettingsView: View {
    @StateObject private var keyboardManager = KeyboardRemapManager.shared
    @State private var firstKey: String = ""
    @State private var secondKey: String = ""
    @State private var selectedKeyboardType: Int? = nil
    @State private var focusedRuleID: UUID?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Keyboard")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            glassCard {
                Toggle("Enable Key Remapping", isOn: $keyboardManager.isRemapEnabled)

                if !keyboardManager.accessibilityGranted {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessibility permission is required for global remapping.")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)

                        HStack(spacing: 8) {
                            Button("Open Permission Prompt") {
                                _ = keyboardManager.ensureAccessibilityPermission(prompt: true)
                            }
                            .buttonStyle(.borderedProminent)

                            Button("Refresh") {
                                keyboardManager.refreshAccessibilityStatus()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                if let lastStartError = keyboardManager.lastStartError {
                    Text(lastStartError)
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }

                Text("Type two letters to swap, like fg. Pressing f becomes g, and pressing g becomes f.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("First")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        TextField("f", text: $firstKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 56)
                            .onChange(of: firstKey) { _, newValue in
                                firstKey = normalizedSingleLetter(from: newValue)
                            }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Second")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                        TextField("g", text: $secondKey)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 56)
                            .onChange(of: secondKey) { _, newValue in
                                secondKey = normalizedSingleLetter(from: newValue)
                            }
                    }

                    Picker("Keyboard", selection: $selectedKeyboardType) {
                        Text("All Keyboards").tag(Int?.none)
                        ForEach(keyboardManager.seenKeyboardTypes, id: \.self) { keyboardType in
                            Text("Keyboard Type \(keyboardType)").tag(Int?.some(keyboardType))
                        }
                    }
                    .frame(width: 180)

                    Button("Add") {
                        if keyboardManager.addRule(firstKey: firstKey, secondKey: secondKey, keyboardType: selectedKeyboardType) {
                            focusedRuleID = keyboardManager.rules.last?.id
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(firstKey.count != 1 || secondKey.count != 1 || firstKey == secondKey)
                }
            }

            glassCard {
                if keyboardManager.rules.isEmpty {
                    Text("No key swaps yet.")
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    ForEach(keyboardManager.rules) { rule in
                        HStack {
                            Toggle("", isOn: Binding(
                                get: { rule.isEnabled },
                                set: { newValue in
                                    var updated = rule
                                    updated.isEnabled = newValue
                                    keyboardManager.updateRule(updated)
                                }
                            ))
                            .toggleStyle(.switch)
                            .labelsHidden()

                            Button {
                                focusedRuleID = rule.id
                            } label: {
                                Text("\(rule.firstKey.uppercased()) ↔ \(rule.secondKey.uppercased())")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(focusedRuleID == rule.id ? .white : .white.opacity(0.9))
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(focusedRuleID == rule.id ? Color.white.opacity(0.18) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)

                            Text(keyboardManager.keyboardLabel(for: rule.keyboardType))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))

                            if !rule.isEnabled {
                                Text("Off")
                                    .font(.system(size: 11, weight: .semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(Color.white.opacity(0.12))
                                    )
                            }

                            Spacer()

                            Button("Remove") {
                                keyboardManager.removeRule(id: rule.id)
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red.opacity(0.85))
                        }

                        if rule.id != keyboardManager.rules.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .foregroundColor(.white.opacity(0.92))
        .onAppear {
            keyboardManager.refreshAccessibilityStatus()
            if firstKey.isEmpty { firstKey = "f" }
            if secondKey.isEmpty { secondKey = "g" }
        }
    }

    private func normalizedSingleLetter(from input: String) -> String {
        let filtered = input.lowercased().filter { $0.isLetter || $0.isNumber }
        guard let first = filtered.first else { return "" }
        return String(first)
    }
}

@ViewBuilder
private func glassCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        content()
    }
    .padding(14)
    .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
            )
    )
    .shadow(color: Color.black.opacity(0.16), radius: 10, y: 4)
}

struct GlassBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.state = .active
        view.blendingMode = .behindWindow
        view.material = material
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
    }
}

struct SettingsWindowConfigurator: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.delegate = context.coordinator
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.isOpaque = true
                window.backgroundColor = NSColor(calibratedWhite: 0.10, alpha: 1.0)
                window.toolbarStyle = .unified
                window.hasShadow = true
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.delegate = context.coordinator
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.isOpaque = true
                window.backgroundColor = NSColor(calibratedWhite: 0.10, alpha: 1.0)
                window.toolbarStyle = .unified
                window.hasShadow = true
            }
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        func windowWillClose(_ notification: Notification) {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
