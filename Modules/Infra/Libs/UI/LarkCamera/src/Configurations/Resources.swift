//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import UIKit
import Foundation
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkCameraBundle, compatibleWith: nil) ?? UIImage()
    }

    static let cancel = Resources.image(named: "cancel")
    static let `switch` = Resources.image(named: "switch")
    static let back = Resources.image(named: "back")
    static let sure = UDIcon.doneOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let focusing = Resources.image(named: "focusing")
}
