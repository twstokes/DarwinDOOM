//
//  SpriteViewContainer.swift
//  DarwinDOOMWatch Watch App
//
//  Created by Daniel Colman on 9/26/24.
//

import SpriteKit
import SwiftUI

// A container to hold the SpriteView and prevent re-rendering
struct SpriteViewContainer: View {
    var doomScene: DoomScene {
        let size = WKInterfaceDevice.current().screenBounds.size
        let scene = DoomScene(size: size)

        DoomGenericSwift.shared().frameDrawCallback = { data in
            let newTexture = SKTexture(data: data, size: .init(width: Int(DOOMGENERIC_RESX), height: Int(DOOMGENERIC_RESY)), flipped: true)
            scene.doomNode.texture = newTexture
        }

        return scene
    }

    var body: some View {
        SpriteView(scene: doomScene)
    }
}

#Preview {
    SpriteViewContainer()
}
