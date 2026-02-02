import AVFoundation
import Vision

final class FaceControlCapture: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
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

    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
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
              session.canAddInput(input)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)

        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
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
