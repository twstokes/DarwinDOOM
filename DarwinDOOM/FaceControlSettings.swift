import Foundation

enum FaceControlSettings {
    static let defaultsKey = "FaceControlEnabled"
}

extension Notification.Name {
    static let faceControlToggleRequested = Notification.Name("FaceControlToggleRequested")
    static let faceControlStateDidChange = Notification.Name("FaceControlStateDidChange")
}
