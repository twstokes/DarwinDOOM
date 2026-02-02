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

    init(viewSize: CGSize = CGSize(width: Int(DOOMGENERIC_RESX), height: Int(DOOMGENERIC_RESY))) {
        self.viewSize = viewSize
        scene = DoomScene(size: viewSize)

        DoomGenericSwift.shared().frameDrawCallback = { [weak self] data in
            guard let self else { return }
            let newTexture = SKTexture(data: data, size: self.viewSize, flipped: true)
            self.scene.doomNode.texture = newTexture
        }
    }

    func attach(to skView: SKView) {
        skView.presentScene(scene)
    }
}
