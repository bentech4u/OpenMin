//
//  MenuBarView.swift
//  openmin
//
//  Created by Ben George on 01/02/2026.
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Enable/Disable Toggle
            Button(action: {
                appState.isEnabled.toggle()
            }) {
                HStack {
                    if appState.isEnabled {
                        Image(systemName: "checkmark")
                            .frame(width: 16)
                    } else {
                        Spacer().frame(width: 16)
                    }
                    Text("Enable Swipe-to-Minimize")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Launch at Login
            Button(action: {
                appState.launchAtLogin.toggle()
            }) {
                HStack {
                    if appState.launchAtLogin {
                        Image(systemName: "checkmark")
                            .frame(width: 16)
                    } else {
                        Spacer().frame(width: 16)
                    }
                    Text("Launch at Login")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Settings
            Button(action: openSettings) {
                HStack {
                    Image(systemName: "gearshape")
                        .frame(width: 16)
                    Text("Settings...")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)

            Divider()

            // Quit
            Button(action: quit) {
                HStack {
                    Spacer().frame(width: 16)
                    Text("Quit OpenMin")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .frame(width: 220)
    }

    func openSettings() {
        if let url = URL(string: "openmin://settings") {
            NSWorkspace.shared.open(url)
        }

        // Alternative: Open settings window
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func quit() {
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState())
}
