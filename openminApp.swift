//
//  openminApp.swift
//  openmin
//
//  Created by Ben George on 01/02/2026.
//

import SwiftUI

@main
struct openminApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("OpenMin", systemImage: "arrow.down.circle.fill") {
            MenuBarView()
                .environmentObject(appState)
        }

        // Onboarding window - shown on first launch
        Window("Welcome to OpenMin", id: "onboarding") {
            OnboardingView()
                .environmentObject(appState)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .handlesExternalEvents(matching: Set(arrayLiteral: "onboarding"))

        // Settings window - hidden by default
        Window("OpenMin Settings", id: "settings") {
            SettingsView()
                .environmentObject(appState)
                .frame(minWidth: 400, minHeight: 300)
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
