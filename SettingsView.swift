//
//  SettingsView.swift
//  openmin
//
//  Created by Ben George on 01/02/2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var hasPermissions = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("OpenMin")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Click-to-Minimize for macOS")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            Divider()

            // Settings
            VStack(alignment: .leading, spacing: 16) {
                // Enable/Disable
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Enable Click-to-Minimize", isOn: $appState.isEnabled)
                        .toggleStyle(.switch)
                        .font(.headline)

                    Text("When enabled, clicking a dock icon of an active app will minimize all its windows.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                // Accessibility Permissions
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: hasPermissions ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(hasPermissions ? .green : .orange)

                        Text("Accessibility Permissions")
                            .font(.headline)

                        Spacer()

                        if !hasPermissions {
                            Button("Open System Settings") {
                                appState.openAccessibilitySettings()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }

                    if hasPermissions {
                        Text("✅ Accessibility access granted")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Text("⚠️ OpenMin needs Accessibility permissions to minimize other apps' windows. Click the button to grant access in System Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Divider()

                // Launch at Login
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Launch at Login", isOn: $appState.launchAtLogin)
                        .toggleStyle(.switch)
                        .font(.headline)

                    Text("Automatically start OpenMin when you log in to your Mac.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Footer
            Text("Made with ❤️ for macOS")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            checkPermissions()
        }
        .onChange(of: appState.isEnabled) { _ in
            checkPermissions()
        }
    }

    func checkPermissions() {
        hasPermissions = appState.hasAccessibilityPermissions()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .frame(width: 500, height: 500)
}
