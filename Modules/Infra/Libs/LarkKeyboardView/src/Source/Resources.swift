//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

// swiftlint:disable all

import Foundation
import UIKit
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif
import UniverseDesignIcon

public final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkKeyboardView.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkKeyboardViewBundle, compatibleWith: nil) ?? UIImage()
    }

    public static let others_plus = UDIcon.moreAddOutlined.ud.withTintColor(UIColor.ud.iconN3)
    public static let others_close = UDIcon.moreCloseOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)

    public static let expand_selected = UDIcon.expandOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    public static let expand = UDIcon.expandOutlined.ud.withTintColor(UIColor.ud.iconN3)

    // Keyboard
    public static let sent_shadow = Resources.image(named: "sent_shadow")
}

// swiftlint:enable all
