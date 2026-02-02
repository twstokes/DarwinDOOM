//
//  ViewController.swift
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 7/8/23.
//

import AVFoundation
import Cocoa
import SpriteKit

class ViewController: NSViewController {
    private let renderCoordinator = DoomRenderCoordinator()
    private let webcamCapture = FaceControlCapture()
    private var isFaceControlEnabled = false
    private var didConfigureWindowAutosave = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let skview = DoomSKView(frame: .init(origin: .zero, size: .zero))
        skview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skview)

        /// Add anchors
        NSLayoutConstraint.activate([
            skview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skview.topAnchor.constraint(equalTo: view.topAnchor),
            skview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        /// Maintain the aspect ratio
        let viewSize = renderCoordinator.viewSize
        let aspect = view.widthAnchor.constraint(
            equalTo: view.heightAnchor,
            multiplier: viewSize.width / viewSize.height
        )

        NSLayoutConstraint.activate([
            aspect,
            skview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        renderCoordinator.attach(to: skview)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFaceControlToggleRequested(_:)),
            name: .faceControlToggleRequested,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFaceControlCameraChanged(_:)),
            name: .faceControlCameraDidChange,
            object: nil
        )
        let preferredCamera = UserDefaults.standard.string(forKey: FaceControlSettings.cameraDefaultsKey)
        webcamCapture.setPreferredCamera(uniqueID: preferredCamera)
        let shouldEnable = UserDefaults.standard.bool(forKey: FaceControlSettings.defaultsKey)
        setFaceControlEnabled(shouldEnable, userInitiated: false)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(view.subviews.first)
        if let window = view.window, !didConfigureWindowAutosave {
            didConfigureWindowAutosave = true
            let autosaveName = NSWindow.FrameAutosaveName("DarwinDOOM.MainWindow")
            let restored = window.setFrameUsingName(autosaveName)
            if !restored {
                if let contentSize = window.contentView?.frame.size {
                    window.setContentSize(NSSize(width: contentSize.width * 1.5,
                                                 height: contentSize.height * 1.5))
                }
                window.center()
            }
            window.setFrameAutosaveName(autosaveName)
        }

        if let window = view.window {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleWindowDidMiniaturize(_:)),
                name: NSWindow.didMiniaturizeNotification,
                object: window
            )
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleWindowDidDeminiaturize(_:)),
                name: NSWindow.didDeminiaturizeNotification,
                object: window
            )
            renderCoordinator.setWindowMiniaturized(window.isMiniaturized)
        }
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        webcamCapture.stop()
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    deinit {
        webcamCapture.stop()
    }
}

private extension ViewController {
    @objc func handleFaceControlToggleRequested(_ notification: Notification) {
        guard let enabled = notification.userInfo?["enabled"] as? Bool else { return }
        setFaceControlEnabled(enabled, userInitiated: true)
    }

    @objc func handleFaceControlCameraChanged(_ notification: Notification) {
        let uniqueID = notification.userInfo?["uniqueID"] as? String
        webcamCapture.setPreferredCamera(uniqueID: uniqueID)
    }

    @objc func handleWindowDidMiniaturize(_ notification: Notification) {
        renderCoordinator.setWindowMiniaturized(true)
    }

    @objc func handleWindowDidDeminiaturize(_ notification: Notification) {
        renderCoordinator.setWindowMiniaturized(false)
    }

    func setFaceControlEnabled(_ enabled: Bool, userInitiated: Bool) {
        if enabled == isFaceControlEnabled { return }

        if enabled {
            requestCameraAccessIfNeeded(userInitiated: userInitiated)
        } else {
            stopFaceControl()
        }
    }

    func requestCameraAccessIfNeeded(userInitiated: Bool) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            startFaceControl()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if granted {
                        self.startFaceControl()
                    } else {
                        self.disableFaceControlDueToAuthorization(userInitiated: userInitiated)
                    }
                }
            }
        case .denied, .restricted:
            disableFaceControlDueToAuthorization(userInitiated: userInitiated)
        @unknown default:
            disableFaceControlDueToAuthorization(userInitiated: userInitiated)
        }
    }

    func startFaceControl() {
        isFaceControlEnabled = true
        UserDefaults.standard.set(true, forKey: FaceControlSettings.defaultsKey)
        NotificationCenter.default.post(
            name: .faceControlStateDidChange,
            object: nil,
            userInfo: ["enabled": true]
        )
        webcamCapture.start()
    }

    func stopFaceControl() {
        isFaceControlEnabled = false
        UserDefaults.standard.set(false, forKey: FaceControlSettings.defaultsKey)
        NotificationCenter.default.post(
            name: .faceControlStateDidChange,
            object: nil,
            userInfo: ["enabled": false]
        )
        DG_SetFaceExpression(Int32(-1))
        webcamCapture.stop()
    }

    func disableFaceControlDueToAuthorization(userInitiated: Bool) {
        stopFaceControl()
        if userInitiated {
            showCameraAccessAlert()
        }
    }

    func showCameraAccessAlert() {
        let alert = NSAlert()
        alert.messageText = "Camera Access Required"
        alert.informativeText = "Enable camera access in System Settings to use face tracking."
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
