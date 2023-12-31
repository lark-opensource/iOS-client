//
//  Resources.swift
//  LarkFeedPlugin
//
//  Created by panbinghua on 2021/8/18.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import LarkFeed

//swiftlint:disable all
final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkFeedPluginBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkFeedPlugin {
        static let feed_encryptied_icon = UDIcon.getIconByKey(.callSecretOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        static let feed_meeting_end_icon = UDIcon.getIconByKey(.videoOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        static let feed_meeting_start_icon = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulGreen)
        static let feed_room_icon = UDIcon.getIconByKey(.virtualOfficeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        static let feed_voice_icon = UDIcon.getIconByKey(.callNetOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        static let feed_thread_message_icon = UDIcon.getIconByKey(.callNetOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        static let right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
        static let feedTeamOutline = UDIcon.getIconByKey(.belongOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.iconN3)
        static let feed_read_icon = LarkFeed.Resources.feed_read_icon
        static let feed_unread_icon = LarkFeed.Resources.feed_unread_icon
        static let sending_message = LarkFeed.Resources.sending_message
        static let send_message_failed = UDIcon.getIconByKey(.warningOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.R500)
        static let feed_draft_icon = UDIcon.getIconByKey(.editContinueOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.R500)
        static let badge_at_icon = UDIcon.getIconByKey(.atOutlined, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.staticWhite)
        static let badge_urgent_icon = UDIcon.getIconByKey(.buzzFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.staticWhite)

        static let light_secret_chat = UIImage.generate(.lockFilled, bgColor: UDColor.N700)
        static let dark_secret_chat = UIImage.generate(.lockFilled, bgColor: UDColor.N200)
        static let secret_chat = UIImage.dynamic(light: Resources.LarkFeedPlugin.light_secret_chat, dark: Resources.LarkFeedPlugin.dark_secret_chat)

        static let light_private_chat = UIImage.generate(.safeFilled, bgColor: UDColor.N700)
        static let dark_private_chat = UIImage.generate(.safeFilled, bgColor: UDColor.N200)
        static let private_chat = UIImage.dynamic(light: Resources.LarkFeedPlugin.light_private_chat, dark: Resources.LarkFeedPlugin.dark_private_chat)

        // 话题帖头像右下角icon
        public static let thread_topic = UIImage.generate(.numberOutlined,
                                                          withIconColor: UDColor.staticWhite,
                                                          bgColor: UDColor.rgb(0x2DBEAB),
                                                          iconSize: CGSize(width: 8, height: 8),
                                                          bgSize: CGSize(width: 16, height: 16),
                                                          isCircular: true)
        // 话题帖头像
        public static let msg_thread = UIImage.generate(.threadChatOutlined,
                                                        withIconColor: UDColor.rgb(0x04B49C),
                                                        bgColor: UDColor.staticWhite,
                                                        borderColor: UDColor.rgb(0x04B49C),
                                                        borderWidth: 1,
                                                        iconSize: CGSize(width: 22, height: 22),
                                                        bgSize: CGSize(width: 46, height: 46),
                                                        isCircular: true)
        // feed action icon
        static let alertsOffOutlined = UDIcon.getIconByKey(.alertsOffOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
        static let bellOutlined = UDIcon.getIconByKey(.bellOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
        static let clearUnreadOutlined = UDIcon.getIconByKey(.clearUnreadOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
        static let chatOutlined = UDIcon.getIconByKey(.chatOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
        static let chatForbiddenOutlined = UDIcon.getIconByKey(.chatForbiddenOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN1)
        static let doneOutlined = UDIcon.getContextMenuIconBy(key: .doneOutlined).ud.withTintColor(UIColor.ud.iconN1)
        static let setTopCancelOutlined = UDIcon.getContextMenuIconBy(key: .setTopCancelOutlined).ud.withTintColor(UIColor.ud.iconN1)
        static let setTopOutlined = UDIcon.getContextMenuIconBy(key: .setTopOutlined).ud.withTintColor(UIColor.ud.iconN1)
        static let flagUnavailableOutlined = UDIcon.getContextMenuIconBy(key: .flagUnavailableOutlined).ud.withTintColor(UIColor.ud.iconN1)
        static let flagOutlined = UDIcon.getContextMenuIconBy(key: .flagOutlined).ud.withTintColor(UIColor.ud.iconN1)
        static let labelCustomOutlined = UDIcon.getContextMenuIconBy(key: .labelCustomOutlined).ud.withTintColor(UIColor.ud.iconN1)
        static let communityTabOutlined = UDIcon.getContextMenuIconBy(key: .communityTabOutlined).ud.withTintColor(UIColor.ud.iconN1)
        static let visibleLockOutlined = UDIcon.getIconByKey(.visibleLockOutlined).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
        static let visibleOutlined = UDIcon.getIconByKey(.visibleOutlined).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    }
}
//swiftlint:enable all

extension UIImage {
    /// 生成带有背景色的
    static func generate(_ key: UniverseDesignIcon.UDIconType,
                         withIconColor color: UIColor = UDColor.primaryOnPrimaryFill,
                         bgColor: UIColor = .clear,
                         borderColor: UIColor = .clear,
                         borderWidth: CGFloat = 0,
                         iconSize: CGSize = CGSize(width: 11, height: 11),
                         bgSize: CGSize = CGSize(width: 16, height: 16),
                         isCircular: Bool = false) -> UIImage {
        let rawIcon = UDIcon.getIconByKey(key, iconColor: color, size: iconSize)
        let rect = CGRect(x: 0, y: 0, width: bgSize.width, height: bgSize.height)
        let imageOrigin = CGPoint(x: (bgSize.width - iconSize.width) / 2, y: (bgSize.height - iconSize.height) / 2)
        UIGraphicsBeginImageContextWithOptions(bgSize, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(bgColor.cgColor)
        if isCircular {
            context?.fillEllipse(in: rect)
        } else {
            context?.fill(rect)
        }

        if borderWidth > 0 {
            context?.setStrokeColor(borderColor.cgColor)
            context?.setLineWidth(borderWidth)
            let borderRect = rect.insetBy(dx: borderWidth / 2, dy: borderWidth / 2)
            if isCircular {
                context?.strokeEllipse(in: borderRect)
            } else {
                context?.stroke(borderRect)
            }
        }

        rawIcon.draw(in: CGRect(origin: imageOrigin, size: iconSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let contextMenuIcon = result ?? rawIcon
        return contextMenuIcon
    }
}
