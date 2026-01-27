//
//  ViewController.swift
//  AppleGenericDoom
//
//  Created by Tanner W. Stokes on 7/8/23.
//

import Cocoa
import SpriteKit

class ViewController: NSViewController {
    private let viewSize = NSSize(
        width: Int(DOOMGENERIC_RESX),
        height: Int(DOOMGENERIC_RESY)
    )

    private var scene: DoomScene!

    override func viewDidLoad() {
        super.viewDidLoad()
        let skview = DoomSKView(frame: .init(origin: .zero, size: viewSize))
        view.addSubview(skview)
        scene = DoomScene(size: view.bounds.size)
        skview.presentScene(scene)
        startDoom()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        preferredContentSize = viewSize
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(view.subviews.first)
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
