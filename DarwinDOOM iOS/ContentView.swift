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

    var body: some View {
        SpriteView(scene: renderCoordinator.scene)
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
