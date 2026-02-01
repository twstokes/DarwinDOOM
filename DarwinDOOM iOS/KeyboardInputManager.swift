import Foundation
import GameController

final class KeyboardInputManager {
    private var isActive = false
    private var keyboard: GCKeyboard?

    func start() {
        guard !isActive else { return }
        isActive = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardDidConnect(_:)),
            name: .GCKeyboardDidConnect,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleKeyboardDidDisconnect(_:)),
            name: .GCKeyboardDidDisconnect,
            object: nil
        )

        if let current = GCKeyboard.coalesced {
            attachKeyboard(current)
        }
    }

    func stop() {
        guard isActive else { return }
        isActive = false

        NotificationCenter.default.removeObserver(self)
        keyboard?.keyboardInput?.keyChangedHandler = nil
        keyboard = nil
    }

    @objc private func handleKeyboardDidConnect(_ notification: Notification) {
        guard let kb = notification.object as? GCKeyboard else { return }
        attachKeyboard(kb)
    }

    @objc private func handleKeyboardDidDisconnect(_ notification: Notification) {
        keyboard?.keyboardInput?.keyChangedHandler = nil
        keyboard = nil
    }

    private func attachKeyboard(_ kb: GCKeyboard) {
        keyboard = kb
        kb.keyboardInput?.keyChangedHandler = { _, _, keyCode, pressed in
            guard let doomKey = Self.doomKey(for: keyCode) else { return }
            DG_PushKey(pressed ? 1 : 0, doomKey)
        }
    }

    private static func doomKey(for keyCode: GCKeyCode) -> UInt8? {
        let textInputActive = DG_IsTextInputActive() != 0

        switch keyCode {
        case .returnOrEnter: return UInt8(KEY_ENTER)
        case .escape: return UInt8(KEY_ESCAPE)
        case .tab: return UInt8(KEY_TAB)
        case .spacebar:
            return textInputActive ? UInt8(ascii: " ") : UInt8(KEY_FIRE)
        case .leftArrow: return UInt8(KEY_LEFTARROW)
        case .rightArrow: return UInt8(KEY_RIGHTARROW)
        case .upArrow: return UInt8(KEY_UPARROW)
        case .downArrow: return UInt8(KEY_DOWNARROW)
        case .leftShift, .rightShift: return UInt8(KEY_RSHIFT)
        case .leftControl, .rightControl: return UInt8(KEY_RCTRL)
        case .deleteOrBackspace: return UInt8(KEY_BACKSPACE)
        case .keyE:
            return textInputActive ? UInt8(ascii: "e") : UInt8(KEY_USE)
        case .keyA: return UInt8(ascii: "a")
        case .keyB: return UInt8(ascii: "b")
        case .keyC: return UInt8(ascii: "c")
        case .keyD: return UInt8(ascii: "d")
        case .keyF: return UInt8(ascii: "f")
        case .keyG: return UInt8(ascii: "g")
        case .keyH: return UInt8(ascii: "h")
        case .keyI: return UInt8(ascii: "i")
        case .keyJ: return UInt8(ascii: "j")
        case .keyK: return UInt8(ascii: "k")
        case .keyL: return UInt8(ascii: "l")
        case .keyM: return UInt8(ascii: "m")
        case .keyN: return UInt8(ascii: "n")
        case .keyO: return UInt8(ascii: "o")
        case .keyP: return UInt8(ascii: "p")
        case .keyQ: return UInt8(ascii: "q")
        case .keyR: return UInt8(ascii: "r")
        case .keyS: return UInt8(ascii: "s")
        case .keyT: return UInt8(ascii: "t")
        case .keyU: return UInt8(ascii: "u")
        case .keyV: return UInt8(ascii: "v")
        case .keyW: return UInt8(ascii: "w")
        case .keyX: return UInt8(ascii: "x")
        case .keyY: return UInt8(ascii: "y")
        case .keyZ: return UInt8(ascii: "z")
        case .one: return UInt8(ascii: "1")
        case .two: return UInt8(ascii: "2")
        case .three: return UInt8(ascii: "3")
        case .four: return UInt8(ascii: "4")
        case .five: return UInt8(ascii: "5")
        case .six: return UInt8(ascii: "6")
        case .seven: return UInt8(ascii: "7")
        case .eight: return UInt8(ascii: "8")
        case .nine: return UInt8(ascii: "9")
        case .zero: return UInt8(ascii: "0")
        default:
            return nil
        }
    }
}
