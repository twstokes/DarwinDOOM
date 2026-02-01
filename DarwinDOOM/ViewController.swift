//
//  ViewController.swift
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 7/8/23.
//

import Cocoa
import SpriteKit
import AVFoundation
import Vision

class ViewController: NSViewController {
    private let renderCoordinator = DoomRenderCoordinator()
    private let webcamCapture = WebcamCapture()
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
            skview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
            skview.trailingAnchor.constraint(equalTo: view.trailingAnchor)
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

private final class DoomSKView: SKView {
    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if let key = Self.doomKey(from: event) {
            DG_PushKey(1, key)
        }
    }

    override func keyUp(with event: NSEvent) {
        if let key = Self.doomKey(from: event) {
            DG_PushKey(0, key)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        switch event.keyCode {
        case 56, 60: // shift
            let pressed = event.modifierFlags.contains(.shift) ? 1 : 0
            DG_PushKey(Int32(pressed), UInt8(KEY_RSHIFT))
        default:
            break
        }
    }

    private static func doomKey(from event: NSEvent) -> UInt8? {
        let textInputActive = DG_IsTextInputActive() != 0

        switch event.keyCode {
        case 36, 76: return UInt8(KEY_ENTER)
        case 48: return UInt8(KEY_TAB)
        case 14:
            if !textInputActive {
                return UInt8(KEY_USE) // E = use
            }
        case 123: return UInt8(KEY_LEFTARROW)
        case 124: return UInt8(KEY_RIGHTARROW)
        case 125: return UInt8(KEY_DOWNARROW)
        case 126: return UInt8(KEY_UPARROW)
        case 49:
            if !textInputActive {
                return UInt8(KEY_FIRE) // spacebar = fire
            }
        case 53: return UInt8(KEY_ESCAPE)
        case 18: return UInt8(ascii: "1")
        case 19: return UInt8(ascii: "2")
        case 20: return UInt8(ascii: "3")
        case 21: return UInt8(ascii: "4")
        case 23: return UInt8(ascii: "5")
        case 22: return UInt8(ascii: "6")
        case 26: return UInt8(ascii: "7")
        case 28: return UInt8(ascii: "8")
        case 25: return UInt8(ascii: "9")
        case 29: return UInt8(ascii: "0")
        default:
            break
        }

        if let characters = event.characters, characters.count == 1,
           let scalar = characters.unicodeScalars.first, scalar.isASCII {
            let value = scalar.value
            if value >= 32 && value <= 126 {
                return UInt8(value)
            }
        }

        return nil
    }
}

private final class WebcamCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let captureQueue = DispatchQueue(label: "WebcamCaptureQueue")
    private let detectionQueue = DispatchQueue(label: "WebcamCaptureDetectionQueue")
    private let stateQueue = DispatchQueue(label: "WebcamCaptureStateQueue")
    private var frameCounter = 0
    private let detectionInterval = 3
    private var lastExpression = 0
    private var lastExpressionTime = CFAbsoluteTimeGetCurrent()
    private var isEnabled = false
    private var preferredDeviceUniqueID: String?

    func start() {
        captureQueue.async { [weak self] in
            self?.setEnabled(true)
            self?.configureAndStart()
        }
    }

    func stop() {
        captureQueue.async { [weak self] in
            self?.setEnabled(false)
            self?.session.stopRunning()
        }
    }

    func setPreferredCamera(uniqueID: String?) {
        captureQueue.async { [weak self] in
            guard let self else { return }
            self.preferredDeviceUniqueID = uniqueID
            if self.session.isRunning {
                self.session.stopRunning()
                self.configureAndStart()
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isCaptureEnabled() else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        frameCounter = (frameCounter + 1) % detectionInterval
        if frameCounter == 0 {
            detectionQueue.async { [weak self] in
                self?.detectExpression(in: pixelBuffer)
            }
        }
    }

    private func configureAndStart() {
        session.beginConfiguration()
        session.sessionPreset = .low

        resetSessionConfiguration()

        let devices = FaceControlCamera.availableDevices()
        guard let device = FaceControlCamera.resolvedDevice(for: preferredDeviceUniqueID, in: devices),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: captureQueue)

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        if let connection = output.connection(with: .video) {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }

        session.commitConfiguration()
        session.startRunning()
    }

    private func resetSessionConfiguration() {
        for input in session.inputs {
            session.removeInput(input)
        }
        for output in session.outputs {
            session.removeOutput(output)
        }
    }

    private func detectExpression(in pixelBuffer: CVPixelBuffer) {
        guard isCaptureEnabled() else { return }
        let faceRequest = VNDetectFaceLandmarksRequest { request, _ in
            guard let face = (request.results as? [VNFaceObservation])?.first else {
                return
            }

            if let yaw = face.yaw?.doubleValue, abs(yaw) > 0.18 {
                self.setExpression(yaw > 0 ? 1 : 2)
                return
            }

            if Self.isMouthOpen(face) {
                self.setExpression(4)
                return
            }

            if let eyebrowExpression = Self.eyebrowRaiseExpression(face) {
                self.setExpression(eyebrowExpression)
                return
            }

            if Self.isGrinning(face) {
                self.setExpression(3)
                return
            }

            self.setExpression(0)
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:])
        try? handler.perform([faceRequest])
    }

    private static func isMouthOpen(_ face: VNFaceObservation) -> Bool {
        guard let lips = face.landmarks?.outerLips?.normalizedPoints, lips.count >= 6 else { return false }

        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for p in lips {
            minX = min(minX, p.x)
            maxX = max(maxX, p.x)
            minY = min(minY, p.y)
            maxY = max(maxY, p.y)
        }

        let width = maxX - minX
        let height = maxY - minY
        if width <= 0.0 || height <= 0.0 { return false }

        let ratio = height / max(width, 0.001)
        return height > 0.10 && ratio > 0.42
    }

    private static func isGrinning(_ face: VNFaceObservation) -> Bool {
        guard let lips = face.landmarks?.outerLips?.normalizedPoints, lips.count >= 6 else { return false }

        var minX = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude

        for p in lips {
            minX = min(minX, p.x)
            maxX = max(maxX, p.x)
            minY = min(minY, p.y)
            maxY = max(maxY, p.y)
        }

        let width = maxX - minX
        let height = maxY - minY
        if width <= 0.0 || height <= 0.0 { return false }

        let ratio = width / max(height, 0.001)
        return width > 0.36 && ratio > 3.8
    }

    private static func eyebrowRaiseExpression(_ face: VNFaceObservation) -> Int? {
        guard
            let leftBrow = face.landmarks?.leftEyebrow?.normalizedPoints,
            let rightBrow = face.landmarks?.rightEyebrow?.normalizedPoints,
            let leftEye = face.landmarks?.leftEye?.normalizedPoints,
            let rightEye = face.landmarks?.rightEye?.normalizedPoints,
            !leftBrow.isEmpty,
            !rightBrow.isEmpty,
            !leftEye.isEmpty,
            !rightEye.isEmpty
        else {
            return nil
        }

        let leftBrowY = leftBrow.map(\.y).reduce(0, +) / CGFloat(leftBrow.count)
        let rightBrowY = rightBrow.map(\.y).reduce(0, +) / CGFloat(rightBrow.count)
        let leftEyeY = leftEye.map(\.y).reduce(0, +) / CGFloat(leftEye.count)
        let rightEyeY = rightEye.map(\.y).reduce(0, +) / CGFloat(rightEye.count)

        let leftGap = leftBrowY - leftEyeY
        let rightGap = rightBrowY - rightEyeY
        let delta = leftGap - rightGap

        if delta > 0.04 {
            return 5
        }
        if delta < -0.04 {
            return 6
        }
        return nil
    }

    private func setExpression(_ value: Int) {
        guard isCaptureEnabled() else { return }
        let now = CFAbsoluteTimeGetCurrent()
        if value == lastExpression {
            lastExpressionTime = now
            DG_SetFaceExpression(Int32(value))
            return
        }

        // Small hysteresis to prevent flicker between forward/mouth-open.
        if now - lastExpressionTime < 0.20 {
            DG_SetFaceExpression(Int32(lastExpression))
            return
        }

        lastExpression = value
        lastExpressionTime = now
        DG_SetFaceExpression(Int32(value))
    }

    private func setEnabled(_ enabled: Bool) {
        stateQueue.sync {
            isEnabled = enabled
        }
    }

    private func isCaptureEnabled() -> Bool {
        stateQueue.sync {
            isEnabled
        }
    }
}
