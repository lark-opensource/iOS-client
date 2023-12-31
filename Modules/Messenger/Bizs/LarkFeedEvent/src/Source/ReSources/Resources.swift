//
//  Resources.swift
//  LarkFeedEvent
//
//  Created by 夏汝震 on 2020/6/7.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

// swiftlint:disable identifier_name
let SelfBundle: Bundle = {
    if let url = Bundle.main.url(forResource: "Frameworks/LarkFeedEventEvent", withExtension: "framework") {
        return Bundle(url: url)!
    } else {
      // 单测会有问题，所以DEBUG模式不动
      #if DEBUG
        return Bundle(for: BundleConfig.self)
      #else
        return Bundle.main
      #endif
    }
}()

let LarkFeedEventBundle = Bundle(url: SelfBundle.url(forResource: "LarkFeedEvent", withExtension: "bundle")!)!
// swiftlint:enable identifier_name

final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkFeedEvent.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: LarkFeedEventBundle, compatibleWith: nil) ?? UIImage()
    }

    static let event_close = UDIcon.getIconByKey(.closeSmallOutlined).ud.withTintColor(UIColor.ud.iconN3)
    static let event_more = UDIcon.getIconByKey(.rightOutlined).ud.withTintColor(UIColor.ud.iconN3)
}
