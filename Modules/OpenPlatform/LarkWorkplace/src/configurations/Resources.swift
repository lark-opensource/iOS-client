//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import UniverseDesignIcon

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkWorkplaceBundle, compatibleWith: nil) ?? UIImage()
    }
    /// 下面请按照字典顺序排序，而且不要有冗余的资源文件
    static let add_app = Resources.image(named: "add_app")
    static let back_home = Resources.image(named: "back_home")
    static let close = Resources.image(named: "close")
    static let demo_api = Resources.image(named: "demo_api")
    static let demo_component = Resources.image(named: "demo_component")
    static let demo_api_highlighted = Resources.image(named: "demo_api_highlighted")
    static let demo_component_highlighted = Resources.image(named: "demo_component_highlighted")
    static let left_shadow = Resources.image(named: "left_shadow")
    static let right_shadow = Resources.image(named: "right_shadow")
    static let more_app = Resources.image(named: "more_app")
    static let workplace_nomore = Resources.image(named: "workplace_nomore")
    static let menu_cancel_common = Resources.image(named: "menu_cancel_common")
    static let menu_cancel_disable = Resources.image(named: "menu_cancel_disable")
    static let menu_rank = Resources.image(named: "menu_rank")
    static let menu_setting = Resources.image(named: "menu_setting")
    static let menu_rank_disable = Resources.image(named: "menu_rank_disable")
    static let menu_share = Resources.image(named: "menu_share")
    static let menu_share_disable = Resources.image(named: "menu_share_disable")
    static let menu_add_common = Resources.image(named: "menu_add_common")
    static let rank_delete = Resources.image(named: "rank_delete")
    static let rank_drag = Resources.image(named: "rank_drag")
    static let explain_icon = Resources.image(named: "explain_icon")
    static let blue_dot = Resources.image(named: "blue_dot")
    static let onboarding_background_dot = UIImage.dynamic(
        light: Resources.image(named: "onboarding_background_dot_light"),
        dark: Resources.image(named: "onboarding_background_dot_dark")
    )
    static let onboarding_background_circle = UIImage.dynamic(
        light: Resources.image(named: "onboarding_background_circle_light"),
        dark: Resources.image(named: "onboarding_background_circle_dark")
    )
    static let blue_bubble_arrow = Resources.image(named: "blue_bubble_arrow")
    static let template_update = Resources.image(named: "template_update")
    static let tab_category_icon = Resources.image(named: "tab_category_icon")
    static let tab_right_shadow = Resources.image(named: "tab_right_shadow")
    static let mutil_scene_web_icon = Resources.image(named: "mutil_scene_web_icon")
    static let icon_player_play_solid = Resources.image(named: "icon_player_play_solid")
    static let icon_player_pause_outlined = Resources.image(named: "icon_player_pause_outlined")
    static let icon_player_speaker_enable_filled = Resources.image(named: "icon_player_speaker_enable_filled")
    static let icon_player_speaker_mute_filled = Resources.image(named: "icon_player_speaker_mute_filled")
    static let icon_placeholder = Resources.image(named: "icon_placeholder")
    
    static let workplace_badge_guide = BundleI18n.localizedImage(
        named: "workplace_badge_guide",
        in: BundleConfig.LarkWorkplaceBundle,
        compatibleWith: nil
    ) ?? Resources.image(named: "workplace_badge_guide_en-US")
}

extension UIImage {
    var alwaysLight: UIImage {
        if #available(iOS 13.0, *) {
            if let config = configuration?.withTraitCollection(.light) {
                return withConfiguration(config)
            }
        }
        return self
    }
}
