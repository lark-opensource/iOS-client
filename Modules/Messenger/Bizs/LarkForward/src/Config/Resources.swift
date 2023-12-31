//
//  Resources.swift
//  Module
//
//  Created by chengzhipeng-bytedance on 2018/3/15.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignEmpty

final class Resources {
    private static func image(named: String) -> UIImage {
        return UIImage(named: named, in: BundleConfig.LarkForwardBundle, compatibleWith: nil) ?? UIImage()
    }

    static let imageForwardFolder = Resources.image(named: "image_forward_folder")
    static let messageThreadIcon = Resources.image(named: "messageThreadIcon")
    static let post_share = Resources.image(named: "post__share")
    static let shareOk = Resources.image(named: "shareOk")
    static let eventShare = Resources.image(named: "event_share")
    static let todoShare = Resources.image(named: "todo_share")
    static let small_video_icon = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
    static let creat_chat = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 14, height: 14)).ud.withTintColor(UIColor.ud.iconN3)
    static let table_fold = UDIcon.getIconByKey(.downExpandOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
    static let table_unfold = Resources.image(named: "table_unfold")
    static let mail_icon = Resources.image(named: "mail_icon")
    static let mine_right_arrow = UDIcon.getIconByKey(.rightOutlined, size: CGSize(width: 13, height: 13)).ud.withTintColor(UIColor.ud.iconN3)
    static let imageDownloadFailed = Resources.image(named: "image_download_failed")
    static let videoChat = Resources.image(named: "videoChat")
    static let share_success = Resources.image(named: "share_success")
    static let search_empty = UDEmptyType.noSearchResult.defaultImage()
    static let no_preview_permission = UDIcon.getIconByKey(.banOutlined, size: CGSize(width: 24, height: 24)).ud.withTintColor(UIColor.ud.iconDisabled)
    static let forwardNext = Resources.image(named: "forward_next")
    static let forwardPlay = Resources.image(named: "forward_play")
    static let forward_video_icon = UDIcon.getIconByKey(.videoFilled, size: CGSize(width: 12, height: 12)).ud.withTintColor(UIColor.ud.primaryOnPrimaryFill)
}
