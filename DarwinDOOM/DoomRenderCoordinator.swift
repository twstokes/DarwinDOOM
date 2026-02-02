//
//  DoomRenderCoordinator.swift
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 1/31/26.
//

import Foundation
import SpriteKit

final class DoomRenderCoordinator {
    let scene: DoomScene
    let viewSize: CGSize
    private let dockRenderer = DoomDockRenderer()
    private var isDockRenderingEnabled: Bool
    private var isWindowMiniaturized = false

    init(viewSize: CGSize = CGSize(width: Int(DOOMGENERIC_RESX), height: Int(DOOMGENERIC_RESY))) {
        self.viewSize = viewSize
        scene = DoomScene(size: viewSize)
        isDockRenderingEnabled = UserDefaults.standard.bool(forKey: FaceControlSettings.dockRenderDefaultsKey)
        dockRenderer?.setEnabled(isDockRenderingEnabled && isWindowMiniaturized)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDockRenderToggleRequested(_:)),
            name: .dockRenderToggleRequested,
            object: nil
        )

        DoomGenericSwift.shared().frameDrawCallback = { [weak self] data in
            guard let self else { return }
            let newTexture = SKTexture(data: data, size: self.viewSize, flipped: true)
            self.scene.doomNode.texture = newTexture
            if self.isDockRenderingEnabled && self.isWindowMiniaturized {
                self.dockRenderer?.update(with: data, size: self.viewSize)
            }
        }
    }

    @objc private func handleDockRenderToggleRequested(_ notification: Notification) {
        guard let enabled = notification.userInfo?["enabled"] as? Bool else { return }
        isDockRenderingEnabled = enabled
        dockRenderer?.setEnabled(enabled && isWindowMiniaturized)
    }

    func setWindowMiniaturized(_ miniaturized: Bool) {
        isWindowMiniaturized = miniaturized
        dockRenderer?.setEnabled(isDockRenderingEnabled && isWindowMiniaturized)
    }

    func attach(to skView: SKView) {
        skView.presentScene(scene)
    }
}
