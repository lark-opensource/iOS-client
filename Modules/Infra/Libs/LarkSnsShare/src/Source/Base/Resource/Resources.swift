//
//  Resources.swift
//  LarkSnsShare
//
//  Created by shizhengyu on 2020/3/15.
//

import UIKit
import Foundation
import LarkLocalizations
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif
import LarkAppResources
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkSnsShare.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: LarkSnsShareBundle, compatibleWith: nil) ?? UIImage()
    }

    private static func localizationsImage(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkSnsShare.\(named)", type: "image") {
            return image
        }
        #endif
        return LanguageManager.image(named: named, in: LarkSnsShareBundle) ?? UIImage()
    }

    static let share_icon_wechat = UDIcon.getIconByKey(.wechatColorful, size: CGSize(width: 24, height: 24))
    static let share_icon_weibo = UDIcon.getIconByKey(.weiboColorful, size: CGSize(width: 24, height: 24))
    static let share_icon_qq = UDIcon.getIconByKey(.qqColorful, size: CGSize(width: 24, height: 24))
    static let share_icon_timeline = UDIcon.getIconByKey(.wechatFriendColorful, size: CGSize(width: 24, height: 24))
    static let share_icon_copy =  UDIcon.getIconByKey(.linkCopyOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let share_icon_more = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let share_icon_save = UDIcon.getIconByKey(.downloadOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconN1)
    static let share_icon_logo = AppResources.share_icon_logo
    static let cta_wechat = Resources.image(named: "cta_wechat")
    static let cta_qq = Resources.image(named: "cta_qq")
    static let cta_weibo = Resources.image(named: "cta_weibo")
}
