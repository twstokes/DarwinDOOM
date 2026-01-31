//
//  ContentView.swift
//  DarwinDOOMWatch Watch App
//
//  Created by Tanner W. Stokes on 7/9/23.
//

import SwiftUI

struct ContentView: View {
    @State private var currentGridRegion: ScreenRegion = .up

    var body: some View {
            GeometryReader { geometry in
                ZStack {
                    // Display the SpriteKit scene, without re-rendering
                    SpriteViewContainer()

                    // Gesture handling
                    Color.clear
                        .contentShape(Rectangle()) // Ensure the entire area can detect taps
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let location = value.location
                                    let screenWidth = geometry.size.width
                                    let screenHeight = geometry.size.height
                                    let region = TouchToKeyManager.determineGridRegion(for: location,
                                                                                        screenWidth: screenWidth,
                                                                                    screenHeight: screenHeight)

                                    if currentGridRegion != region {
                                        TouchToKeyManager.addTouchUpToKeyQueue(currentGridRegion)
                                    }
                                    currentGridRegion = region
                                    TouchToKeyManager.addTouchDownToKeyQueue(region)
                                }
                                .onEnded { value in
                                    TouchToKeyManager.addTouchUpToKeyQueue(currentGridRegion)
                                }
                        )
                        .ignoresSafeArea()
                }
            }
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
