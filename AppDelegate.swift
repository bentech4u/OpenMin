//
//  AppDelegate.swift
//  openmin
//
//  Created by Ben George on 01/02/2026.
//

import Cocoa
import ApplicationServices

// MARK: - MultitouchSupport finger data structures

struct MTPoint {
    var x: Float
    var y: Float
}

struct MTVector {
    var pos: MTPoint
    var vel: MTPoint
}

struct MTFinger {
    var frame: Int32
    var timestamp: Double
    var identifier: Int32
    var state: Int32
    var foo3: Int32
    var foo4: Int32
    var normalized: MTVector
    var size: Float
    var zero1: Int32
    var angle: Float
    var majorAxis: Float
    var minorAxis: Float
    var mm: MTVector
    var zero2a: Int32
    var zero2b: Int32
    var density: Float
}

// MARK: - Swipe detection state (accessed from MT callback thread)

private nonisolated(unsafe) var swipeIsTracking = false
private nonisolated(unsafe) var swipeStartY: Float = 0
private nonisolated(unsafe) var swipeTriggered = false
/// Timestamp of the last detected 3-finger swipe up (Exposé trigger)
private nonisolated(unsafe) var lastSwipeUpTime: CFAbsoluteTime = 0

/// Multi-touch callback - reads raw finger positions to detect 3-finger swipe down.
/// Also detects swipe up to know when Exposé was triggered.
private nonisolated(unsafe) let mtCallback: @convention(c) (
    UnsafeMutableRawPointer,  // device
    UnsafeMutableRawPointer,  // finger data array
    Int32,                     // number of fingers
    Double,                    // timestamp
    Int32                      // frame
) -> Void = { _, data, nFingers, _, _ in
    let stride = MemoryLayout<MTFinger>.stride
    var totalY: Float = 0
    var activeCount: Int32 = 0

    for i in 0..<Int(nFingers) {
        let finger = data.advanced(by: i * stride).load(as: MTFinger.self)
        // state >= 4 means finger is touching the trackpad surface
        if finger.state >= 4 {
            totalY += finger.normalized.pos.y
            activeCount += 1
        }
    }

    // Need 3+ fingers touching
    guard activeCount >= 3 else {
        if swipeIsTracking {
            swipeIsTracking = false
            swipeTriggered = false
        }
        return
    }

    let avgY = totalY / Float(activeCount)

    if !swipeIsTracking {
        // Start tracking a potential swipe
        swipeIsTracking = true
        swipeStartY = avgY
        swipeTriggered = false
    } else if !swipeTriggered {
        // Normalized Y: 0 = bottom of trackpad, 1 = top
        let deltaY = swipeStartY - avgY

        if deltaY > 0.08 {
            // Fingers moved DOWN
            swipeTriggered = true
            print("3-finger swipe down detected! delta: \(deltaY), fingers: \(activeCount)")
            DispatchQueue.main.async {
                AppDelegate.shared?.handleSwipeDown()
            }
        } else if deltaY < -0.08 {
            // Fingers moved UP — Exposé is being triggered
            swipeTriggered = true
            lastSwipeUpTime = CFAbsoluteTimeGetCurrent()
            print("3-finger swipe up detected (Exposé) delta: \(deltaY), fingers: \(activeCount)")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    nonisolated(unsafe) static var shared: AppDelegate?
    private var mtLoaded = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched")
        AppDelegate.shared = self

        // Request Accessibility permissions
        checkAccessibilityPermissions()

        let isEnabled = UserDefaults.standard.bool(forKey: "clickToMinimizeEnabled")
        print("Feature enabled: \(isEnabled)")

        // Setup multi-touch gesture detection from raw finger data
        setupMultitouch()

        // Show onboarding window on first launch
        showOnboardingIfNeeded()
    }

    func showOnboardingIfNeeded() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        if !hasCompletedOnboarding {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let url = URL(string: "openmin://onboarding") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
    }

    // MARK: - Multi-touch Setup

    private func setupMultitouch() {
        let path = "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport"
        guard let handle = dlopen(path, RTLD_LAZY) else {
            print("WARNING: Could not load MultitouchSupport framework")
            return
        }

        typealias CreateListFn = @convention(c) () -> Unmanaged<CFArray>
        typealias RegisterFn = @convention(c) (
            UnsafeMutableRawPointer,
            @convention(c) (UnsafeMutableRawPointer, UnsafeMutableRawPointer, Int32, Double, Int32) -> Void
        ) -> Void
        typealias StartFn = @convention(c) (UnsafeMutableRawPointer, Int32) -> Int32

        guard let createListSym = dlsym(handle, "MTDeviceCreateList"),
              let registerSym = dlsym(handle, "MTRegisterContactFrameCallback"),
              let startSym = dlsym(handle, "MTDeviceStart") else {
            print("WARNING: Could not find MultitouchSupport symbols")
            return
        }

        let createList = unsafeBitCast(createListSym, to: CreateListFn.self)
        let register = unsafeBitCast(registerSym, to: RegisterFn.self)
        let start = unsafeBitCast(startSym, to: StartFn.self)

        let deviceArray = createList().takeRetainedValue()
        let count = CFArrayGetCount(deviceArray)
        print("Found \(count) multi-touch device(s)")

        for i in 0..<count {
            guard let device = CFArrayGetValueAtIndex(deviceArray, i) else { continue }
            let mutableDevice = UnsafeMutableRawPointer(mutating: device)
            register(mutableDevice, mtCallback)
            _ = start(mutableDevice, 0)
        }

        mtLoaded = count > 0
        if mtLoaded {
            print("Multi-touch gesture detection active")
        }
    }

    // MARK: - Accessibility Permissions

    func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !accessEnabled {
            print("WARNING: Accessibility permissions not granted. Please grant in System Settings.")
        }
    }

    func hasAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    // MARK: - Swipe Handler

    /// Cooldown in seconds after a swipe-up (Exposé trigger) during which
    /// swipe-down actions are suppressed.
    private let exposeCooldown: CFAbsoluteTime = 4.0

    func handleSwipeDown() {
        let isEnabled = UserDefaults.standard.bool(forKey: "clickToMinimizeEnabled")
        if !isEnabled { return }
        if !hasAccessibilityPermissions() { return }

        // Suppress if a 3-finger swipe up (Exposé) was detected recently
        let timeSinceSwipeUp = CFAbsoluteTimeGetCurrent() - lastSwipeUpTime
        if timeSinceSwipeUp < exposeCooldown {
            print("Suppressed — recent swipe up \(String(format: "%.1f", timeSinceSwipeUp))s ago (Exposé likely active)")
            return
        }

        minimizeFrontmostApp()
    }

    func minimizeFrontmostApp() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost app")
            return
        }

        let appName = frontApp.localizedName ?? "Unknown"
        print("Minimizing: \(appName)")
        minimizeApp(frontApp)
    }

    // MARK: - Window Minimize

    func minimizeApp(_ app: NSRunningApplication) {
        let appName = app.localizedName ?? "Unknown"
        let pid = app.processIdentifier

        let appElement = AXUIElementCreateApplication(pid)

        var windowList: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowList)

        if result != .success {
            print("Failed to get windows for \(appName)")
            return
        }

        guard let windows = windowList as? [AXUIElement], !windows.isEmpty else {
            print("No windows found for \(appName)")
            return
        }

        var minimizedCount = 0

        for window in windows {
            // Check if window is already minimized
            var isMinimized: CFTypeRef?
            AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &isMinimized)

            if let minimizedValue = isMinimized as? Bool, minimizedValue {
                continue
            }

            // Try to press the minimize button for genie animation
            var minimizeButtonRef: CFTypeRef?
            let buttonResult = AXUIElementCopyAttributeValue(
                window,
                kAXMinimizeButtonAttribute as CFString,
                &minimizeButtonRef
            )

            if buttonResult == .success, let minimizeButton = minimizeButtonRef {
                let button = minimizeButton as! AXUIElement
                let pressResult = AXUIElementPerformAction(button, kAXPressAction as CFString)

                if pressResult == .success {
                    minimizedCount += 1
                    Thread.sleep(forTimeInterval: 0.05)
                } else {
                    let fallbackResult = AXUIElementSetAttributeValue(
                        window,
                        kAXMinimizedAttribute as CFString,
                        kCFBooleanTrue
                    )
                    if fallbackResult == .success {
                        minimizedCount += 1
                    }
                }
            } else {
                let minimizeResult = AXUIElementSetAttributeValue(
                    window,
                    kAXMinimizedAttribute as CFString,
                    kCFBooleanTrue
                )
                if minimizeResult == .success {
                    minimizedCount += 1
                }
            }
        }

        if minimizedCount > 0 {
            print("Minimized \(minimizedCount) window(s) for \(appName)")
        } else {
            print("Could not minimize any windows for \(appName)")
        }
    }
}
