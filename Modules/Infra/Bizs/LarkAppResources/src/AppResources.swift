//
//  Resources.swift
//  Module
//
//  Created by Kongkaikai on 2018/12/23.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

import Foundation
import UIKit
import LarkLocalizations
import LarkSetting
import LarkReleaseConfig
import UniverseDesignTheme
import LarkAccountInterface
import LarkContainer
#if USE_DYNAMIC_RESOURCE
import LarkResource
#endif

// swiftlint:disable all
public final class AppResources {
    private struct ThemeSetting: SettingDecodable {
        static let settingKey  = UserSettingKey.make(userKeyLiteral: "client_ka_darkmode_support")
        
        let channelList: [String]
        let tenantList: [String]
    }
    
    @LazySetting private static var themeSetting: ThemeSetting?
    
    private static func image(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        let list = (themeSetting?.channelList ?? []) + (themeSetting?.tenantList ?? [])
        @Injected var passport: PassportService
        
        let env = list.contains(ReleaseConfig.kaChannelForAligned) || list.contains(passport.foregroundUser?.tenant.tenantID ?? "") ? {
            if #available(iOS 13.0, *) {
                return UDThemeManager.getRealUserInterfaceStyle() == .dark ? Env(theme: "dark") : Env()
            } else { return Env() }
        }() : Env()
        
        if let image: UIImage = ResourceManager.get(key: "LarkAppResources.\(named)", type: "image", env: env) {
            return image
        }
        #endif
        return UIImage(named: named, in: LarkAppResourcesBundle, compatibleWith: nil) ?? UIImage()
    }

    private static func localizationsImage(named: String) -> UIImage {
        #if USE_DYNAMIC_RESOURCE
        if let image: UIImage = ResourceManager.get(key: "LarkAppResources.\(named)", type: "image") {
            return image
        }
        #endif
        return LanguageManager.image(named: named, in: LarkAppResourcesBundle) ?? UIImage()
    }

    // LarkChat
    public static var logo : UIImage { AppResources.image(named: "logo") }

    // LarkWeb
    public static var docs_detail_share_lark : UIImage { AppResources.image(named: "docs_detail_share_lark") }

    // LarkMine
    public static var ios_icon: UIImage { AppResources.image(named: "ios_icon") }
    public static var notification_hide_detail: UIImage { Self.localizationsImage(named: "notification_hide_detail") }
    public static var notification_show_detail: UIImage { Self.localizationsImage(named: "notification_show_detail") }
    public static let gray_num_badge_back = AppResources.image(named: "gray_num_badge_back")
    public static let red_dot_badge_back = AppResources.image(named: "red_dot_badge_back")

    // LarkSearch
    public static var searchMessageInChatInitPlaceHolder : UIImage { AppResources.image(named: "searchMessageInChatInitPlaceHolder") }

    // LarkTour
    public static var tour_logo : UIImage { Self.localizationsImage(named: "tour_logo") }

    public static var tour_oversea_logo : UIImage { AppResources.image(named: "tour_oversea_logo") }

    // LarkCalendar
    public static var calendar_share_logo : UIImage { AppResources.image(named: "calendar_share_logo") }

    // feed UG Guide
    public static var feishu_logo : UIImage { AppResources.image(named: "feishu_logo") }
    
    /// sns share icon
    public static var share_icon_logo : UIImage { AppResources.image(named: "share_lark_logo") }
    
    /// passport logo
    public static var lark_logo : UIImage { AppResources.image(named: "lark_logo") }

    /// byteview callkit logo
    public static var callkit_logo : UIImage { AppResources.image(named: "callkit_logo") }
}
// swiftlint:enable all
