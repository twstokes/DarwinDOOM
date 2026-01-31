//
//  TouchToKeyManager.swift
//  DarwinDOOMWatch Watch App
//
//  Created by Daniel Colman on 9/26/24.
//

import Foundation

/// A specific region of the screen.
///
/// The screen is divided into a 3x3 grid:
///
///  left  |  up  | right
/// ----------------------
///  left  |  up  | right
/// ----------------------
/// action | down | fire
/// ----------------------
///
/// **Action** changes based on game state: ENTER (Menu) or USE (In-Game)
/// **Fire** also changes based on game state: ESCAPE (Menu) or FIRE (In-Game)
@objc enum ScreenRegion: Int {
    case left
    case right
    case up
    case down
    case action // ENTER (Menu) or USE (In-Game)
    case fire // ESCAPE (Menu) or FIRE (In-Game)
}

@objcMembers
class TouchToKeyManager: NSObject, ObservableObject {
    public  static var keyQueue: [UInt16] = Array(repeating: 0, count: 16)
    public static var currentReadIndex = 0;
    public static var currentWriteIndex = 0;

    public static func getCurrentReadIndex() -> Int {
        TouchToKeyManager.currentReadIndex
    }

    public static func getCurrentWriteIndex() -> Int {
        TouchToKeyManager.currentWriteIndex
    }

    private enum rowNumber {
        case one, two, three
    }

    private enum columnNumber {
        case one, two, three
    }

    // Function to determine the grid region based on tap location
    static func determineGridRegion(for location: CGPoint, screenWidth: CGFloat, screenHeight: CGFloat) -> ScreenRegion {
        let thirdWidth = screenWidth / 3
        let thirdHeight = screenHeight / 3

        let row: rowNumber
        if location.y < thirdHeight {
            row = .one
        } else if location.y < 2 * thirdHeight {
            row = .two
        } else {
            row = .three
        }

        let column: columnNumber
        if location.x < thirdWidth {
            column = .one
        } else if location.x < 2 * thirdWidth {
            column = .two
        } else {
            column = .three
        }

        // Map the row and column to a grid region
        switch (row, column) {
        case (.one, .one), (.two, .one):
            return .left
        case (.one, .two), (.two, .two):
            return .up
        case (.one, .three), (.two, .three):
            return .right
        case (.three, .one):
            return .action
        case (.three, .two):
            return .down
        case (.three, .three):
            return .fire
        }
    }

    static func getNextKey() -> UInt16 {
        let key = TouchToKeyManager.keyQueue[TouchToKeyManager.currentReadIndex]
        TouchToKeyManager.currentReadIndex += 1
        TouchToKeyManager.currentReadIndex %= 16
        return key
    }

    static func addTouchDownToKeyQueue(_ currentGridRegion: ScreenRegion) {
        let key: UInt16 = doomKeyFromRegion(currentGridRegion)
        let value: UInt16 = (1 << 8) | key;
        TouchToKeyManager.keyQueue[currentWriteIndex] = value
        TouchToKeyManager.currentWriteIndex += 1
        TouchToKeyManager.currentWriteIndex %= 16
    }

    static func addTouchUpToKeyQueue(_ currentGridRegion: ScreenRegion) {
        let key: UInt16 = doomKeyFromRegion(currentGridRegion)
        let value: UInt16 = (0 << 8) | key;
        TouchToKeyManager.keyQueue[currentWriteIndex] = value
        TouchToKeyManager.currentWriteIndex += 1
        TouchToKeyManager.currentWriteIndex %= 16
    }

    private static func doomKeyFromRegion(_ region: ScreenRegion) -> UInt16 {
        switch region {
        case .left:
            return UInt16(KEY_LEFTARROW)
        case .right:
            return UInt16(KEY_RIGHTARROW)
        case .up:
            return UInt16(KEY_UPARROW)
        case .down:
            return UInt16(KEY_DOWNARROW)
        case .action:
            // Is the user currently playing a game?
            return usergame.rawValue == 1 ?
                   UInt16(KEY_USE) :
                   UInt16(KEY_ENTER)
        case .fire:
            // Is the user currently playing a game?
            return usergame.rawValue == 1 ?
                   UInt16(KEY_FIRE) :
                   UInt16(KEY_ESCAPE)
        }
    }
}
