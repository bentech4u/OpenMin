//
//  AppState.swift
//  openmin
//
//  Created by Ben George on 01/02/2026.
//

import SwiftUI
import ServiceManagement
import Combine

class AppState: ObservableObject {
    @Published var isEnabled: Bool = true
    @Published var launchAtLogin: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load saved preference or default to true
        let savedEnabled = UserDefaults.standard.object(forKey: "clickToMinimizeEnabled") as? Bool ?? true
        self.isEnabled = savedEnabled

        // Set default value if first launch
        if UserDefaults.standard.object(forKey: "clickToMinimizeEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "clickToMinimizeEnabled")
        }

        checkLaunchAtLogin()

        // Observe changes to isEnabled
        $isEnabled
            .dropFirst() // Skip initial value
            .sink { [weak self] enabled in
                UserDefaults.standard.set(enabled, forKey: "clickToMinimizeEnabled")
                print("Click-to-Minimize: \(enabled ? "✅ Enabled" : "❌ Disabled")")
            }
            .store(in: &cancellables)

        // Observe changes to launchAtLogin
        $launchAtLogin
            .dropFirst() // Skip initial value
            .sink { [weak self] enabled in
                self?.setLaunchAtLogin(enabled)
            }
            .store(in: &cancellables)
    }

    // MARK: - Launch at Login

    func checkLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    print("✅ Launch at Login enabled")
                } else {
                    try SMAppService.mainApp.unregister()
                    print("❌ Launch at Login disabled")
                }
            } catch {
                print("⚠️ Failed to set Launch at Login: \(error)")
            }
        } else {
            print("⚠️ Launch at Login requires macOS 13.0 or later")
        }
    }

    // MARK: - Accessibility Permissions

    func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
