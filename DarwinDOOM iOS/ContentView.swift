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

    var body: some View {
        ZStack {
            SpriteView(scene: renderCoordinator.scene)
                .ignoresSafeArea()
            TouchControlOverlay()
        }
        .onAppear {
            keyboardManager.start()
        }
        .onDisappear {
            keyboardManager.stop()
        }
    }
}

#Preview {
    ContentView()
}
