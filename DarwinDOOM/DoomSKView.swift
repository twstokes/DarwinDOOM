//
//  DoomSKView.swift
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 2/1/26.
//

import AVFoundation
import Cocoa
import SpriteKit

final class DoomSKView: SKView {
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
        let textInputActive = DG_IsTextInputActive() != 0

        switch event.keyCode {
        case 36, 76: return UInt8(KEY_ENTER)
        case 48: return UInt8(KEY_TAB)
        case 14:
            if !textInputActive {
                return UInt8(KEY_USE) // E = use
            }
        case 123: return UInt8(KEY_LEFTARROW)
        case 124: return UInt8(KEY_RIGHTARROW)
        case 125: return UInt8(KEY_DOWNARROW)
        case 126: return UInt8(KEY_UPARROW)
        case 49:
            if !textInputActive {
                return UInt8(KEY_FIRE) // spacebar = fire
            }
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
            break
        }

        if let characters = event.characters, characters.count == 1,
           let scalar = characters.unicodeScalars.first, scalar.isASCII
        {
            let value = scalar.value
            if value >= 32, value <= 126 {
                return UInt8(value)
            }
        }

        return nil
    }
}
