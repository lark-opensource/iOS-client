//
//  LarkAvatarTracker.swift
//  LarkAvatar
//
//  Created by Yuri on 2022/4/21.
//

import Foundation
import LKCommonsTracker
import Homeric

public final class LarkAvatarTracker {
    /// 在「个人头像页」页，发生动作事件
    public static func trackAvatarMainClick() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "avatar_change"
        params["target"] = "im_avatar_change_view"
        Tracker.post(TeaEvent(Homeric.IM_AVATAR_MAIN_CLICK, params: params))
    }
    /// 在「修改个人头像弹窗」页，发生动作事件
    public enum AvatarChangeClickType: String {
        case shot = "shot"
        case fromAlbum = "from_album"
        case defaultAvatar = "default_avatar"
        case photoSave = "photo_save"
    }
    public static func trackAvatarChangeClick(clickType: AvatarChangeClickType) {
        var params: [AnyHashable: Any] = [:]
        params["click"] = clickType.rawValue
        params["target"] = (clickType == .defaultAvatar) ? "im_avatar_confirm_view" : "none"
        Tracker.post(TeaEvent(Homeric.IM_AVATAR_CHANGE_CLICK, params: params))
    }

    /// 在「使用默认头像弹窗」页，发生动作事件
    public static func trackAvatarConfirmClick() {
        var params: [AnyHashable: Any] = [:]
        params["click"] = "confirm"
        params["target"] = "none"
        Tracker.post(TeaEvent(Homeric.IM_AVATAR_CONFIRM_CLICK, params: params))
    }
}
