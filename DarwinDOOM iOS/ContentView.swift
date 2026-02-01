//
//  ContentView.swift
//  DarwinDOOM iOS
//
//  Created by Tanner W. Stokes on 1/31/26.
//

import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var renderCoordinator = DoomRenderCoordinator()
    @State private var keyboardManager = KeyboardInputManager()
    private static let targetAspect: CGFloat = 640.0 / 400.0

    var body: some View {
        GeometryReader { proxy in
            let container = proxy.size
            let fitted = Self.aspectFitSize(container, aspect: Self.targetAspect)

            ZStack {
                Color.black
                    .ignoresSafeArea()
                SpriteView(scene: renderCoordinator.scene)
                    .frame(width: fitted.width, height: fitted.height)
                TouchControlOverlay()
            }
            .frame(width: container.width, height: container.height, alignment: .center)
        }
        .onAppear {
            keyboardManager.start()
        }
        .onDisappear {
            keyboardManager.stop()
        }
    }

    private static func aspectFitSize(_ size: CGSize, aspect: CGFloat) -> CGSize {
        guard size.width > 0, size.height > 0, aspect > 0 else { return .zero }
        let containerAspect = size.width / size.height
        if containerAspect > aspect {
            let height = size.height
            return CGSize(width: height * aspect, height: height)
        } else {
            let width = size.width
            return CGSize(width: width, height: width / aspect)
        }
    }
}

#Preview {
    ContentView()
}
