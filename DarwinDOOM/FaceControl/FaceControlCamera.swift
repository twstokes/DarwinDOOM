import AVFoundation

enum FaceControlCamera {
    private static let deviceTypes: [AVCaptureDevice.DeviceType] = {
        var types: [AVCaptureDevice.DeviceType] = [
            .builtInWideAngleCamera,
            .externalUnknown,
        ]
        if #available(macOS 14.0, *) {
            types.append(.continuityCamera)
        }
        return types
    }()

    static func availableDevices() -> [AVCaptureDevice] {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: deviceTypes,
            mediaType: .video,
            position: .unspecified
        )
        return session.devices.sorted { $0.localizedName < $1.localizedName }
    }

    static func resolvedDevice(for preferredUniqueID: String?, in devices: [AVCaptureDevice]) -> AVCaptureDevice? {
        if let preferredUniqueID,
           let match = devices.first(where: { $0.uniqueID == preferredUniqueID })
        {
            return match
        }
        return defaultDevice(in: devices)
    }

    static func defaultDevice(in devices: [AVCaptureDevice]) -> AVCaptureDevice? {
        guard !devices.isEmpty else { return nil }
        if devices.count == 1 { return devices[0] }
        if let front = devices.first(where: { $0.position == .front }) {
            return front
        }
        return devices[0]
    }
}
