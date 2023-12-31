//
//  Resources.swift
//  LarkSceneManager
//
//  Created by Saafo on 2021/4/7.
//

import UIKit
import Foundation

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkSceneManagerBundle, compatibleWith: nil) ?? UIImage()
    }
    static let mainSceneIcon = Resources.image(named: "icon_sidebar_home")
}
