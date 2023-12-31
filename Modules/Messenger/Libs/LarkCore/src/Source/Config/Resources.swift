//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif
import UniverseDesignIcon
import UniverseDesignEmpty

public final class Resources {
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkCore.\(named)", type: "image") {
            return image
        }
        #endif
        return UIImage(named: named, in: BundleConfig.LarkCoreBundle, compatibleWith: nil) ?? UIImage()
    }

    public static let loading = Resources.image(named: "loading")
    public static let avatar_default = Resources.image(named: "avatar_default")

    // chat
    public static let goChatSettingArrow = UDIcon.getIconByKey(.expandRightFilled, size: CGSize(width: 10, height: 10)).ud.withTintColor(UIColor.ud.iconN1)

    // thread
    public static let thread_topic = Resources.image(named: "thread_topic")

    public static let web_failed = UDEmptyType.loadingFailure.defaultImage()

    /// megreForward
    static let replyInThreadForward = UDIcon.getIconByKey(.threadChatOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.T600)
    // AlertController
    static let right_arrow = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 14, height: 14))

    public static let verticalLineImage = getVerticalLineImage()

    private static func getVerticalLineImage() -> UIImage {
         let containerView = UIView()
         containerView.frame = CGRect(x: 0, y: 0, width: 1, height: 16)
         let view = UIView()
         view.frame = CGRect(x: 0, y: 2, width: 1, height: 12)
         view.backgroundColor = UIColor.ud.lineDividerDefault
         containerView.addSubview(view)
         UIGraphicsBeginImageContextWithOptions(containerView.frame.size, false, 0)
         guard let context = UIGraphicsGetCurrentContext() else {
             return UIImage()
         }
         containerView.layer.render(in: context)
         let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
         UIGraphicsEndImageContext()
         return image
     }
}
