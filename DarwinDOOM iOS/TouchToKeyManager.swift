import Foundation
import SwiftUI

enum ScreenRegion {
    case left
    case right
    case up
    case down
    case action
    case fire
}

enum TouchToKeyManager {
    static func region(for location: CGPoint, in size: CGSize) -> ScreenRegion {
        let thirdWidth = size.width / 3
        let thirdHeight = size.height / 3

        let row: Int
        if location.y < thirdHeight {
            row = 1
        } else if location.y < 2 * thirdHeight {
            row = 2
        } else {
            row = 3
        }

        let column: Int
        if location.x < thirdWidth {
            column = 1
        } else if location.x < 2 * thirdWidth {
            column = 2
        } else {
            column = 3
        }

        switch (row, column) {
        case (1, 1), (2, 1):
            return .left
        case (1, 2), (2, 2):
            return .up
        case (1, 3), (2, 3):
            return .right
        case (3, 1):
            return .action
        case (3, 2):
            return .down
        case (3, 3):
            return .fire
        default:
            return .up
        }
    }

    static func press(_ region: ScreenRegion) {
        DG_PushKey(1, doomKey(from: region))
    }

    static func release(_ region: ScreenRegion) {
        DG_PushKey(0, doomKey(from: region))
    }

    private static func doomKey(from region: ScreenRegion) -> UInt8 {
        switch region {
        case .left:
            return UInt8(KEY_LEFTARROW)
        case .right:
            return UInt8(KEY_RIGHTARROW)
        case .up:
            return UInt8(KEY_UPARROW)
        case .down:
            return UInt8(KEY_DOWNARROW)
        case .action:
            return usergame.rawValue == 1 ? UInt8(KEY_USE) : UInt8(KEY_ENTER)
        case .fire:
            return usergame.rawValue == 1 ? UInt8(KEY_FIRE) : UInt8(KEY_ESCAPE)
        }
    }
}

struct TouchControlOverlay: View {
    @State private var activeRegion: ScreenRegion?

    var body: some View {
        GeometryReader { proxy in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let region = TouchToKeyManager.region(for: value.location, in: proxy.size)
                            if region != activeRegion {
                                if let current = activeRegion {
                                    TouchToKeyManager.release(current)
                                }
                                TouchToKeyManager.press(region)
                                activeRegion = region
                            }
                        }
                        .onEnded { _ in
                            if let current = activeRegion {
                                TouchToKeyManager.release(current)
                            }
                            activeRegion = nil
                        }
                )
        }
    }
}
