//
//  BundleResource.swift
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/24.
//

import UIKit
import Foundation

// swiftlint:disable identifier_name
let SceneAlgorithmConfig = "ScenealgorithmConfig"
let SceneAlgorithmConfigExtension = "json"
// swiftlint:enable identifier_name

public final class LVDResources: NSObject {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkVideoDirectorBundle, compatibleWith: nil) ?? UIImage()
    }

    // Asset Browser
    @objc
    public static let videoDownload = image(named: "download")
}
// swiftlint: enable all
