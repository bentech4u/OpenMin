//
//  OnboardingView.swift
//  openmin
//
//  Created by Ben George on 01/02/2026.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var hasPermissions = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("Welcome to OpenMin")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Swipe Down to Minimize")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)

            // Instructions
            VStack(alignment: .leading, spacing: 20) {
                Text("To get started, OpenMin needs Accessibility permissions:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 16) {
                    InstructionRow(
                        number: "1",
                        text: "Click the 'Open System Settings' button below"
                    )

                    InstructionRow(
                        number: "2",
                        text: "Click the + button at the bottom left"
                    )

                    InstructionRow(
                        number: "3",
                        text: "Navigate to Applications and select OpenMin"
                    )

                    InstructionRow(
                        number: "4",
                        text: "Toggle the switch to ON"
                    )
                }
                .padding(.leading, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.vertical, 20)

            // Permission Status
            HStack(spacing: 8) {
                Image(systemName: hasPermissions ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(hasPermissions ? .green : .orange)

                Text(hasPermissions ? "Accessibility permissions granted" : "Accessibility permissions required")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 12)

            Spacer()

            // Buttons
            HStack(spacing: 12) {
                if hasPermissions {
                    Button("Get Started") {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("Open System Settings") {
                        appState.openAccessibilitySettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("I'll Do This Later") {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .frame(width: 500, height: 520)
        .onAppear {
            checkPermissions()

            // Poll for permission changes
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                checkPermissions()
            }
        }
    }

    func checkPermissions() {
        hasPermissions = appState.hasAccessibilityPermissions()
    }
}

struct InstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.blue)
                )

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
