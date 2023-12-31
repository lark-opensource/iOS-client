//
//  BundleResources.swift
//  LarkBaseService
//
//  Created by 李晨 on 2021/6/1.
//

import Foundation
import UIKit
import UniverseDesignIcon

// swiftlint:disable all
final class BundleResources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkBaseServiceBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkBaseService {
        static let closeIcon = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 19, height: 19)).ud.withTintColor(UIColor.ud.iconN3)
    }

}
//swiftlint:enable all
