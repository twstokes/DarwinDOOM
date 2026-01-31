//
//  AppDelegate.swift
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 7/8/23.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var faceControlMenuItem: NSMenuItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        UserDefaults.standard.register(defaults: [
            FaceControlSettings.defaultsKey: false
        ])
        configureFaceControlMenuItem()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFaceControlStateDidChange(_:)),
            name: .faceControlStateDidChange,
            object: nil
        )
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    private func configureFaceControlMenuItem() {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }

        if let existing = appMenu.items.first(where: { $0.title == "Face Control" }) {
            faceControlMenuItem = existing
            existing.state = UserDefaults.standard.bool(forKey: FaceControlSettings.defaultsKey) ? .on : .off
            existing.target = self
            existing.action = #selector(toggleFaceControl(_:))
            return
        }

        let toggleItem = NSMenuItem(
            title: "Face Control",
            action: #selector(toggleFaceControl(_:)),
            keyEquivalent: ""
        )
        toggleItem.target = self
        toggleItem.state = UserDefaults.standard.bool(forKey: FaceControlSettings.defaultsKey) ? .on : .off

        let insertIndex: Int
        if let prefsIndex = appMenu.items.firstIndex(where: { $0.title == "Preferences…" }) {
            insertIndex = prefsIndex + 1
        } else {
            insertIndex = min(1, appMenu.items.count)
        }

        if insertIndex < appMenu.items.count, appMenu.items[insertIndex].isSeparatorItem {
            appMenu.insertItem(toggleItem, at: insertIndex)
        } else {
            appMenu.insertItem(NSMenuItem.separator(), at: insertIndex)
            appMenu.insertItem(toggleItem, at: insertIndex + 1)
        }
        faceControlMenuItem = toggleItem
    }

    @objc private func toggleFaceControl(_ sender: NSMenuItem) {
        let shouldEnable = sender.state != .on
        NotificationCenter.default.post(
            name: .faceControlToggleRequested,
            object: nil,
            userInfo: ["enabled": shouldEnable]
        )
    }

    @objc private func handleFaceControlStateDidChange(_ notification: Notification) {
        guard let enabled = notification.userInfo?["enabled"] as? Bool else { return }
        faceControlMenuItem?.state = enabled ? .on : .off
    }
}
