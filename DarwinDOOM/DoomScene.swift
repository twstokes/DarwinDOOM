//
//  DoomScene.swift
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 7/9/23.
//

import Foundation
import SpriteKit

class DoomScene: SKScene {
    private(set) var doomNode = SKSpriteNode()

    init(size: CGSize, wadPath: String? = DoomGenericSwift.getFirstWadLocation()) {
        super.init(size: size)

        scaleMode = .resizeFill
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(doomNode)

        guard let wadPath else {
            print("No WAD path provided!")
            return
        }

        let args = ["foo", "-iwad", wadPath]

        // h/t https://stackoverflow.com/a/29469618
        var cargs = args.map { strdup($0) }
        doomgeneric_Create(Int32(args.count), &cargs)
        // free the duplicated strings
        for ptr in cargs {
            free(ptr)
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        doomNode.size = size
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)
        doomgeneric_Tick()
    }
}
