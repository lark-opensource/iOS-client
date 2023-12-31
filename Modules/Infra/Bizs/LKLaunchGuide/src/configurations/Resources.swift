import Foundation
import UIKit
import UniverseDesignIcon

// swiftlint:disable all
final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LKLaunchGuideBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LKLaunchGuide {
        static let close = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN1)
        static let vc_guide = Resources.image(named: "vc_guide")
        static let bg_guide = Resources.image(named: "bg_guide")
        static let iphone_background = Resources.image(named: "iphone_background")
        static let ipad_background = Resources.image(named: "ipad_background")
        static let guide_background = Resources.image(named: "guide_background")
    }

}
//swiftlint:enable all
