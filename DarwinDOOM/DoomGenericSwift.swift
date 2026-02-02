//
//  DoomGenericSwift.swift
//  DarwinDOOM
//
//  Created by Tanner W. Stokes on 7/9/23.
//

import Foundation

@objc class DoomGenericSwift: NSObject {
    private static var sharedDoomGenericSwift: DoomGenericSwift = .init()

    var frameDrawCallback: ((Data) -> Void)?

    @objc func DG_DrawFrame() {
        let data = Data(bytes: DG_ScreenBuffer, count: Int(DOOMGENERIC_RESX) * Int(DOOMGENERIC_RESY) * 4)
        frameDrawCallback?(data)
    }

    // we use a singleton pattern to avoid passing around an instance
    @objc class func shared() -> DoomGenericSwift {
        return sharedDoomGenericSwift
    }

    // returns the full path of the first file found in the bundled WADs directory
    static func getFirstWadLocation() -> String? {
        guard let resourcePath = Bundle.main.resourcePath else {
            return nil
        }

        let fileManager = FileManager.default
        let wadsPath = resourcePath.appending("/WADs")

        guard let firstFileName = try? fileManager.contentsOfDirectory(atPath: wadsPath).first else {
            return nil
        }

        return wadsPath.appending("/" + firstFileName)
    }
}
