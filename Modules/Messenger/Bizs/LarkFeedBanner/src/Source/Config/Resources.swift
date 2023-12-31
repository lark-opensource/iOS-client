//
//  Resources.swift
//  LarkFeedBanner
//
//  Created by panbinghua on 2021/8/18.
//

import Foundation
import UIKit
import UniverseDesignIcon

//swiftlint:disable all
final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkFeedBannerBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkFeedBanner {
        final class Invite_member_guide {
            static let invite_banner_close = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        }
        final class Upgrade_team {
            static let upgrade_team_close = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        }
    }

}
//swiftlint:enable all
