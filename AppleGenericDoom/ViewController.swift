//
//  ViewController.swift
//  AppleGenericDoom
//
//  Created by Tanner W. Stokes on 7/8/23.
//

import Cocoa
import SpriteKit
import AVFoundation
import Vision

class ViewController: NSViewController {
    private let viewSize = NSSize(
        width: Int(DOOMGENERIC_RESX),
        height: Int(DOOMGENERIC_RESY)
    )

    private var scene: DoomScene!
    private let webcamCapture = WebcamCapture()

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
        let aspect = view.widthAnchor.constraint(
            equalTo: view.heightAnchor,
            multiplier: viewSize.width / viewSize.height
        )

        NSLayoutConstraint.activate([
            aspect,
            skview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skview.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        scene = DoomScene(size: view.bounds.size)
        skview.presentScene(scene)
        webcamCapture.start()
        startDoom()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(view.subviews.first)
    }

    override func viewWillDisappear() {
        super.viewWillDisappear()
        webcamCapture.stop()
    }

    private func startDoom() {
        DoomGenericSwift.shared().frameDrawCallback = { [weak self] data in
            guard let self else { return }
            let newTexture = SKTexture(data: data, size: self.viewSize, flipped: true)
            scene.doomNode.texture = newTexture
        }
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
        switch event.keyCode {
        case 36, 76: return UInt8(KEY_ENTER)
        case 48: return UInt8(KEY_TAB)
        case 14: return UInt8(KEY_USE) // E = use
        case 123: return UInt8(KEY_LEFTARROW)
        case 124: return UInt8(KEY_RIGHTARROW)
        case 125: return UInt8(KEY_DOWNARROW)
        case 126: return UInt8(KEY_UPARROW)
        case 49: return UInt8(KEY_FIRE) // spacebar = fire
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
            return nil
        }
    }
}

private final class WebcamCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let captureQueue = DispatchQueue(label: "WebcamCaptureQueue")
    private let detectionQueue = DispatchQueue(label: "WebcamCaptureDetectionQueue")
    private var frameCounter = 0
    private let detectionInterval = 3
    private var lastExpression = 0
    private var lastExpressionTime = CFAbsoluteTimeGetCurrent()

    func start() {
        captureQueue.async { [weak self] in
            self?.configureAndStart()
        }
    }

    func stop() {
        captureQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
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

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
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

    private func detectExpression(in pixelBuffer: CVPixelBuffer) {
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

    private func setExpression(_ value: Int) {
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
}
