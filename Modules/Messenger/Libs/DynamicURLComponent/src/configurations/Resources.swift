//
//  Resources.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/25.
//

import Foundation
import UIKit
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.DynamicURLComponentBundle, compatibleWith: nil) ?? UIImage()
    }
    static let inline_icon_placeholder = UDIcon.getIconByKey(.globalLinkOutlined, size: CGSize(width: 16, height: 16))
    static let imageDownloadFailed = UDIcon.getIconByKey(.loadfailFilled, size: CGSize(width: 32, height: 32)).ud.withTintColor(UIColor.ud.iconN3)
}
