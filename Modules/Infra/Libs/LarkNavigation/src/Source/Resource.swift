//
//  Resource.swift
//  LarkNavigation
//
//  Created by Aslan on 2021/9/14.
//

import Foundation
import UIKit
import UniverseDesignIcon

// swiftlint:disable all
final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkNavigationBundle, compatibleWith: nil) ?? UIImage()
    }
    /*
    * you can load image like that:
    *
    * static let tabbar_conversation_shadow = BundleResources.image(named: "tabbar_conversation_shadow")
    */
    final class LarkNavigation {
        static let tenant_cell_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
        static let navibar_button_search = UDIcon.searchOutlined.ud.withTintColor(UIColor.ud.iconN1)
        static let navibar_title_arrow = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 10, height: 10))
        static let tab_more_button_normal = UDIcon.getIconByKey(.moreOutlined, size: CGSize(width: 22, height: 22)).ud.withTintColor(UIColor.ud.iconN2)
        static let tab_more_button_selected = UDIcon.getIconByKey(.tabMoreColorful, size: CGSize(width: 22, height: 22))
        static let tab_tenant_add = UDIcon.getIconByKey(.addOutlined, size: CGSize(width: 32, height: 32)).ud.withTintColor(UIColor.ud.iconN1)

        final class QuickTab {
            static let quicktab_appcenter = UDIcon.tabAppFilled.ud.withTintColor(UIColor.ud.colorfulTurquoise)
            static let quicktab_calendar = UDIcon.calendarFilled.ud.withTintColor(UIColor.ud.colorfulOrange)
            static let quicktab_contact = UDIcon.tabContactsFilled.ud.withTintColor(UIColor.ud.colorfulYellow)
            static let quicktab_feed = UDIcon.tabChatFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
            static let quicktab_mail = UDIcon.tabMailFilled.ud.withTintColor(UIColor.ud.colorfulIndigo)
            static let quicktab_space = UDIcon.tabDriveFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
            static let quicktab_moment =  UDIcon.tabCommunityFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
            static let quicktab_video_conference = UDIcon.tabVideoFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
            static let quicktab_minutes = UDIcon.tabMinutesFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
            static let quicktab_wiki = UDIcon.tabWikiFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
            static let quicktab_microApp = UDIcon.gadgetFilled.ud.withTintColor(UIColor.ud.colorfulBlue)
            static let quicktab_todo = UDIcon.tabTodoFilled.ud.withTintColor(UIColor.ud.colorfulIndigo)
            static let quicktab_bitable = UDIcon.getIconByKey(.tabMoreBaseColorful, size: CGSize(width: 96, height: 96))
        }

        final class MainTab {
            @inline(__always)
            private static var size: CGSize { CGSize(width: 22, height: 22) }

            static var tabbar_feed_shadow: UIImage { UDIcon.getIconByKey(.tabChatFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_feed_light: UIImage { UDIcon.getIconByKey(.tabChatColorful, size: size) }

            static var tabbar_calendar_shadow: UIImage { UDIcon.getIconByKey(.calendarFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_calendar_light: UIImage { UDIcon.getIconByKey(.calendarFilled, size: size).ud.withTintColor(UIColor.ud.colorfulBlue) }

            static var tabbar_appcenter_shadow: UIImage { UDIcon.getIconByKey(.tabAppFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_appcenter_light: UIImage { UDIcon.getIconByKey(.tabAppColorful, size: size) }

            static var tabbar_docs_shadow: UIImage { UDIcon.getIconByKey(.tabDriveFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_docs_light: UIImage { UDIcon.getIconByKey(.tabDriveColorful, size: size) }
            
            static var tabbar_wiki_shadow: UIImage { UDIcon.getIconByKey(.tabWikiFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_wiki_light: UIImage { UDIcon.getIconByKey(.tabWikiColorful, size: size) }

            static var tabbar_contacts_shadow: UIImage { UDIcon.getIconByKey(.tabContactsFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_contacts_light: UIImage { UDIcon.getIconByKey(.tabContactsColorful, size: size) }

            static var tabbar_mail_shadow: UIImage { UDIcon.getIconByKey(.tabMailFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_mail_light: UIImage { UDIcon.getIconByKey(.tabMailColorful, size: size) }

            static var tabbar_moment_shadow: UIImage { UDIcon.getIconByKey(.tabCommunityFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_moment_light: UIImage { UDIcon.getIconByKey(.tabCommunityColorful, size: size) }

            static var tabbar_byteview_shadow: UIImage { UDIcon.getIconByKey(.tabVideoFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_byteview_light: UIImage { UDIcon.getIconByKey(.tabVideoColorful, size: size) }

            static var tabbar_minutes_shadow: UIImage { UDIcon.getIconByKey(.tabMinutesFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_minutes_light: UIImage { UDIcon.getIconByKey(.tabMinutesColorful, size: size) }

            static var tabbar_todo_shadow: UIImage { UDIcon.getIconByKey(.tabTodoFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_todo_light: UIImage { UDIcon.getIconByKey(.tabTodoColorful, size: size) }

            static var tabbar_microApp_shadow: UIImage { UDIcon.getIconByKey(.gadgetFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_microApp_light: UIImage { UDIcon.getIconByKey(.gadgetFilled, size: size).ud.withTintColor(UIColor.ud.colorfulBlue) }
            
            static var tabbar_bitable_shadow: UIImage { UDIcon.getIconByKey(.tabBitableFilled, size: size).ud.withTintColor(UIColor.ud.iconN2) }
            static var tabbar_bitable_light: UIImage { UDIcon.getIconByKey(.tabBitableColorful, size: size) }
        }

        final class EdgeTab {
            static let hide_tab = UDIcon.getIconByKey(.tabFixOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.primaryContentDefault)
            static let hide_tab_contextmenu = UDIcon.getIconByKey(.tabFixOutlined, size: CGSize(width: 35, height: 35)).ud.withTintColor(UIColor.ud.iconN1)
            static let show_tab_contextmenu = UDIcon.getIconByKey(.tabReleaseOutlined, size: CGSize(width: 35, height: 35)).ud.withTintColor(UIColor.ud.iconN1)
            static let refresh_icon = getMenuIconWithBgColorBy(key: .replaceOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, bgColor: UIColor.ud.primaryContentDefault)
        }

        private static func getMenuIconWithBgColorBy(key: UDIconType, iconColor: UIColor? = nil, bgColor: UIColor = .clear) -> UIImage {
            let imageSize = CGSize(width: 12, height: 12)
            let fullSize = CGSize(width: 20, height: 20)
            let rawIcon = UDIcon.getIconByKey(key, size: imageSize).ud.withTintColor(iconColor ?? UIColor.ud.primaryOnPrimaryFill)
            let imageOrigin = CGPoint(x: 4, y: 4) // (20 - 12) / 2
            UIGraphicsBeginImageContextWithOptions(fullSize, false, 0)
            let context = UIGraphicsGetCurrentContext()
            let rect = CGRect(x: 0, y: 0, width: fullSize.width, height: fullSize.height)
            let imageView: UIImageView = UIImageView(frame: rect)
            imageView.backgroundColor = bgColor
            let layer = imageView.layer
            layer.masksToBounds = true
            layer.cornerRadius = fullSize.height/2
            layer.render(in: context!)
            rawIcon.draw(in: CGRect(origin: imageOrigin, size: imageSize))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let contextMenuIcon = result ?? rawIcon
            return contextMenuIcon
        }
    }
}
//swiftlint:enable all
