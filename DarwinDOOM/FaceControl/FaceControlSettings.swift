import Foundation

enum FaceControlSettings {
    static let defaultsKey = "FaceControlEnabled"
    static let cameraDefaultsKey = "FaceControlCameraUniqueID"
    static let dockRenderDefaultsKey = "DockRenderEnabled"
}

extension Notification.Name {
    static let faceControlToggleRequested = Notification.Name("FaceControlToggleRequested")
    static let faceControlStateDidChange = Notification.Name("FaceControlStateDidChange")
    static let faceControlCameraDidChange = Notification.Name("FaceControlCameraDidChange")
    static let dockRenderToggleRequested = Notification.Name("DockRenderToggleRequested")
}
