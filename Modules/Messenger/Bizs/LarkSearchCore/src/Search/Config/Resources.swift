//
//  Resources.swift
//  LarkSearchCore
//
//  Created by panbinghua on 2021/8/18.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor

#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

//swiftlint:disable all
final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkSearchCore.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkSearchCoreBundle, compatibleWith: nil) ?? UIImage()
    }
    static var doc_sharefolder_circle: UIImage { return UDIcon.getIconByKey(.fileRoundSharefolderColorful) }
    static var wikibook_circle: UIImage { return UDIcon.getIconByKey(.wikibookCircleColorful) }
    final class LarkSearchCore {
        final class Calendar {
            static let invite_mail_attendee = UDIcon.mailOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
        }
        final class Messenger {
            static let picker_selected_close = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3)
            static let right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN3)
        }
        final class Picker {
            static let table_fold = UDIcon.getIconByKey(.downExpandOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
        }
    }
    static let light_private_chat = UIImage.generate(.safeFilled, bgColor: UDColor.N700)
    static let dark_private_chat = UIImage.generate(.safeFilled, bgColor: UDColor.N200)
    static let private_chat = UIImage.dynamic(light: Resources.light_private_chat, dark: Resources.dark_private_chat)
    static let target_info = UDIcon.getIconByKey(.infoOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 20, height: 20))
}

private extension UIImage {
    /// 生成带有背景色的
    static func generate(_ key: UniverseDesignIcon.UDIconType,
                         withIconColor color: UIColor = UDColor.primaryOnPrimaryFill,
                         bgColor: UIColor = .clear,
                         iconSize: CGSize = CGSize(width: 11, height: 11),
                           bgSize: CGSize = CGSize(width: 16, height: 16)) -> UIImage {
        let rawIcon = UDIcon.getIconByKey(key, iconColor: color, size: iconSize)
        let rect = CGRect(x: 0, y: 0, width: bgSize.width, height: bgSize.height)
        let imageOrigin = CGPoint(x: (bgSize.width - iconSize.width) / 2, y: (bgSize.height - iconSize.height) / 2)
        UIGraphicsBeginImageContextWithOptions(bgSize, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(bgColor.cgColor)
        context?.fill(rect)
        rawIcon.draw(in: CGRect(origin: imageOrigin, size: iconSize))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let contextMenuIcon = result ?? rawIcon
        return contextMenuIcon
      }
}

//swiftlint:enable all
