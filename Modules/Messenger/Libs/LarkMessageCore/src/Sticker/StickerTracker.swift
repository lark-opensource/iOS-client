//
//  StickerTracker.swift
//  LarkMessageCore
//
//  Created by lizhiqiang on 2019/6/5.
//

import Foundation
import LarkModel
import LKCommonsTracker
import Homeric

public final class StickerTracker {
    /// 表情商店点击
    public static func trackEmotionShopListShow() {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_STORE_CLICK))
    }

    public static func trackImageEditEvent(_ event: String, params: [String: Any]?) {
        Tracker.post(TeaEvent(event, params: params ?? [:]))
    }

    static func tranckStickerDelet(stickerSetID: String, stickerPackCount: Int, stickersCount: Int) {
        let info = ["num_of_ stickerpack": stickerPackCount, // 该用户已有的表情专辑数
                    "num_of_stickers": stickersCount, //该表情专辑有多少表情
                    "stickerpack_id": stickerSetID] as [String: Any]
        Tracker.post(TeaEvent(Homeric.STICKERPACK_DELETE, params: info))
    }

    static func trackStickerRecorder() {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_REORDER))
    }

    static func trackStickerRecorderSave() {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_REORDER_SAVE))
    }

    static func trackStickerSetUsed() {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_USE))
    }

    enum EmotionAddStickerSetForm: String {
        case emotionShop = "1"
        case emotionDetail = "2"
        case emotionSingleDetail = "3"
    }
    static func trackStickerSetAdded(from: EmotionAddStickerSetForm, stickerID: String, stickersCount: Int) {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_ADD,
                              params: ["stickerpack_add_location": from.rawValue,
                                       "stickerpack_id": stickerID,
                                       "num_of_stickers": stickersCount]))
    }

    enum EmotionSettingPageFrom: String {
        case fromPannel = "1"
        case fromEmotionShop = "2"
    }
    /// 表情包管理页面展示
    static func trackEmotionSettingShow(from: EmotionSettingPageFrom) {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_MANAGE,
                              params: ["stickerpack_manage_location": from.rawValue]))
    }

    /// 用户点击 IM 中输入框表情栏的添加的单个表情
    public static func trackSwitchSticker() {
        Tracker.post(
            TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR_STICKER,
                     params: ["click_button": "stickerpack"]
            )
        )
    }

    /// 用户点击 IM 中输入框表情栏的 emoji
    public static func trackSwitchEmoji() {
        Tracker.post(
            TeaEvent(Homeric.IM_CHAT_INPUT_TOOLBAR_STICKER,
                     params: ["click_button": "emoji"]
            )
        )
    }
}
