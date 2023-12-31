//
//  Resources.swift
//  LarkAI
//
//  Created by bytedance on 2020/9/21.
//

import Foundation
import UIKit
import LarkUIKit
import LarkAppResources
import UniverseDesignIcon

public final class Resources {
    public static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkAIBundle, compatibleWith: nil) ?? UIImage()
    }

    // MyAI 头像
    /// 头像尺寸小于 32pt 使用
    static let my_ai_avatar_small = UDIcon.myaiColorful
    /// 头像尺寸大于 32pt 使用
    static let my_ai_avatar_large = Resources.image(named: "my_ai_avatar_large")

    // 翻译反馈
    static let translate_arrow = Resources.image(named: "translate_arrow")
    static let translate_close = UDIcon.getIconByKey(.closeOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN1)
    static let translate_star_dark = Resources.image(named: "translate_star_dark")
    static let translate_star_light = Resources.image(named: "translate_star_light")
    static let translate_suggesion_normal = Resources.image(named: "translate_suggesion_nomal")
    static let translate_suggesion_selected = Resources.image(named: "translate_suggesion_selected")
    // 网页翻译
    static let web_icon_done = UDIcon.doneOutlined.ud.withTintColor(UIColor.ud.colorfulBlue)
    static let web_icon_setting = UDIcon.settingOutlined.ud.withTintColor(UIColor.ud.iconN2)
    static let web_icon_close = UDIcon.closeOutlined.ud.withTintColor(UIColor.ud.iconN2)
    static let web_icon_translate = UDIcon.translateColorful
    static let menu_icon_translate = Resources.image(named: "web_translate_icon")
    static let menu_icon_translate_disable = Resources.image(named: "web_translate_disable")
    static let menu_icon_translate_new = Resources.image(named: "web_translate_icon_new")
    static let menu_icon_translate_disable_new = UDIcon.translateOutlined.ud.withTintColor(UIColor.ud.iconN3)
    static let menu_select_translate_language = UDIcon.getIconByKey(.leftSmallCcmOutlined, size: CGSize(width: 24, height: 24))
    // 划词翻译
    static let translate_card_pronunciation = UDIcon.getIconByKey(.speakerFilled, size: CGSize(width: 15, height: 13))
    static let translate_card_changeLanguage = UDIcon.getIconByKey(.transSwitchOutlined, size: CGSize(width: 24, height: 24))
    static let translate_card_feedback = UDIcon.getIconByKey(.feedbackOutlined, size: CGSize(width: 24, height: 24))
    static let translate_card_copy = UDIcon.getIconByKey(.copyOutlined, size: CGSize(width: 24, height: 24))
    // 企业实体词
    static let eew_like_hightlight = UDIcon.getIconByKey(.thumbsupFilled, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let eew_like_nomal = UDIcon.getIconByKey(.thumbsupOutlined, size: CGSize(width: 16, height: 16)).ud.withTintColor(UIColor.ud.iconN2)
    static let eew_dislike_hightlight = Resources.image(named: "eew_dislike_hightlight")
    static let eew_dislike_nomal = Resources.image(named: "eew_dislike_nomal")
    static let eew_right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN1)
    static let eew_baike_logo = Resources.image(named: "eew_baike_logo")
    static let eew_right_arrow_blue = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.colorfulBlue)
    static let eew_link_icon = Resources.image(named: "eew_link_icon")
    static let eew_doc_icon = Resources.image(named: "eew_doc_icon")

    // Smart Correct
    static let smart_correct_abandon = UDIcon.getIconByKey(.visibleLockOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2)
    static let my_ai_tool_add = UDIcon.getIconByKey(.addOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let imageDownloadFailed = UDIcon.getIconByKey(.loadfailFilled).ud.withTintColor(UIColor.ud.iconN3)
}
