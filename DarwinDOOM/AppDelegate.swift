//
//  AppDelegate.swift
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 7/8/23.
//

import AVFoundation
import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private var faceControlMenuItem: NSMenuItem?
    private var faceControlCameraMenuItem: NSMenuItem?
    private var faceControlCameraItems: [NSMenuItem] = []

    func applicationDidFinishLaunching(_: Notification) {
        UserDefaults.standard.register(defaults: [
            FaceControlSettings.defaultsKey: false,
        ])
        configureFaceControlMenuItem()
        configureFaceControlCameraMenuItem()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFaceControlStateDidChange(_:)),
            name: .faceControlStateDidChange,
            object: nil
        )
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_: NSApplication) -> Bool {
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

    private func configureFaceControlCameraMenuItem() {
        guard let appMenu = NSApp.mainMenu?.items.first?.submenu else { return }

        let devices = FaceControlCamera.availableDevices()
        guard !devices.isEmpty else {
            removeFaceControlCameraMenuItem(from: appMenu)
            return
        }

        let storedUniqueID = UserDefaults.standard.string(forKey: FaceControlSettings.cameraDefaultsKey)
        let selectedDevice = FaceControlCamera.resolvedDevice(for: storedUniqueID, in: devices)
        let selectedUniqueID = selectedDevice?.uniqueID

        if let selectedUniqueID, selectedUniqueID != storedUniqueID {
            UserDefaults.standard.set(selectedUniqueID, forKey: FaceControlSettings.cameraDefaultsKey)
        }

        guard devices.count > 1 else {
            removeFaceControlCameraMenuItem(from: appMenu)
            return
        }

        let cameraMenuItem = faceControlCameraMenuItem ?? NSMenuItem(
            title: "Face Control Camera",
            action: nil,
            keyEquivalent: ""
        )
        let submenu = NSMenu(title: "Face Control Camera")
        faceControlCameraItems = devices.map { device in
            let item = NSMenuItem(
                title: device.localizedName,
                action: #selector(selectFaceControlCamera(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = device.uniqueID
            item.state = device.uniqueID == selectedUniqueID ? .on : .off
            return item
        }
        faceControlCameraItems.forEach { submenu.addItem($0) }
        cameraMenuItem.submenu = submenu

        if faceControlCameraMenuItem == nil {
            let insertIndex: Int
            if let faceControlIndex = appMenu.items.firstIndex(where: { $0.title == "Face Control" }) {
                insertIndex = faceControlIndex + 1
            } else if let prefsIndex = appMenu.items.firstIndex(where: { $0.title == "Preferences…" }) {
                insertIndex = prefsIndex + 1
            } else {
                insertIndex = min(1, appMenu.items.count)
            }
            appMenu.insertItem(cameraMenuItem, at: min(insertIndex, appMenu.items.count))
        }

        faceControlCameraMenuItem = cameraMenuItem
    }

    private func removeFaceControlCameraMenuItem(from appMenu: NSMenu) {
        if let cameraMenuItem = faceControlCameraMenuItem,
           let index = appMenu.items.firstIndex(of: cameraMenuItem)
        {
            appMenu.removeItem(at: index)
        }
        faceControlCameraMenuItem = nil
        faceControlCameraItems.removeAll()
    }

    @objc private func toggleFaceControl(_ sender: NSMenuItem) {
        let shouldEnable = sender.state != .on
        NotificationCenter.default.post(
            name: .faceControlToggleRequested,
            object: nil,
            userInfo: ["enabled": shouldEnable]
        )
    }

    @objc private func selectFaceControlCamera(_ sender: NSMenuItem) {
        guard let uniqueID = sender.representedObject as? String else { return }
        UserDefaults.standard.set(uniqueID, forKey: FaceControlSettings.cameraDefaultsKey)
        for item in faceControlCameraItems {
            item.state = item.representedObject as? String == uniqueID ? .on : .off
        }
        NotificationCenter.default.post(
            name: .faceControlCameraDidChange,
            object: nil,
            userInfo: ["uniqueID": uniqueID]
        )
    }

    @objc private func handleFaceControlStateDidChange(_ notification: Notification) {
        guard let enabled = notification.userInfo?["enabled"] as? Bool else { return }
        faceControlMenuItem?.state = enabled ? .on : .off
    }
}
