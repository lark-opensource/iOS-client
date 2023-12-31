//
//  Resources.swift
//  LarkVersion
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkLocalizations
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif
import UniverseDesignIcon

// swiftlint:disable all
final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkVersion.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkVersionBundle, compatibleWith: nil) ?? UIImage()
    }

    static let upgrade_header = Resources.image(named: "upgrade_header")
}
// swiftlint:enable all
