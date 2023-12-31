//
//  MessageActionType.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/1/18.
//

import Foundation
import LarkMessageBase
import LarkSetting
import LKCommonsLogging
public typealias MessageActionType = LarkMessageBase.MessageActionType

public struct MessageActionOrder {
    static let logger = Logger.log(MessageActionOrder.self, category: "LarkOpenChat.Menu.MessageActionOrder")
    #if DEBUG || ALPHA
    /// 白名单，不需要处理的菜单项放这里
    public static let unusedHoverAction: [MessageActionType] = [
        .forwardThread, .saveTo, .unknown
    ]
    public static let unusedSheetAction: [MessageActionType] = [
        .forwardThread, .saveTo, .unknown
    ]
    public static let unusedSettingAction: [MessageActionType] = [
        .forwardThread, .saveTo, .unknown, .reaction
    ]
    #endif
    /// 这个列表需要校验一下
    public static let defaultSheet: [[MessageActionType]] = [
        /// 第一组 高频消息操作
        [
            .reaction,
            .reply,
            .forward,
            .createThread,
            .openThread,
            .copy,
            .cardCopy,
            .debug
        ],
        /// 第二组 场景类消息操作
        [
            .like,
            .dislike,
            .audioPlayMode,
            .audioText,
            .mutePlay,
            .imageEdit,
            .addToSticker,
        ],
        /// 第三组 次高频消息操作
        [
            .recall,
            .multiEdit,
            .urgent,
            .viewGenerationProcess,
            .multiSelect,
            .quickActionInfo
        ],
        /// 第四组 整理操作
        [
            .flag,
            .favorite
        ],
        /// 第五组 低频消息操作
        [
            .chatPin,
            .pin,
            .topMessage,
            .messageLink,
            .toOriginal,
            .jumpToChat,
            .restrict,
            .translate,
            .selectTranslate,
            .switchLanguage,
            .search,
            .delete
        ],
        /// 第六组 应用扩展
        [
            .todo,
            .meego,
            .ka,
            .takeActionV2
        ]
    ]

    public static let defaultPartialSheet: [MessageActionType] = [
        .copy,
        .reply,
        .cardCopy,
        .selectTranslate,
        .search
    ]

    public static let hover: [MessageActionType] = [
        .like,
        .dislike,
        .mutePlay,
        .audioPlayMode,
        .audioText,
        .urgent,
        .recall,
        .multiEdit,
        .reply,
        .forward,
        .createThread,
        .openThread,
        .viewGenerationProcess,
        .multiSelect,
        .quickActionInfo,
        .copy,
        .cardCopy,
        .flag,
        .favorite,
        .chatPin,
        .pin,
        .topMessage,
        .messageLink,
        .addToSticker,
        .todo,
        .jumpToChat,
        .toOriginal,
        .restrict,
        .translate,
        .switchLanguage,
        .meego,
        .search,
        .reaction,
        .imageEdit,
        .delete,
        .ka,
        .takeActionV2,
        .selectTranslate,
        .debug
    ]

    public static let partialHover: [MessageActionType] = [
        .copy,
        .reply,
        .cardCopy,
        .selectTranslate,
        .search
    ]

    /// 远端setting到本地菜单项的映射
    /// https://bytedance.feishu.cn/docx/DXSXd1qProXkMzxGfMVccCMFn7n
    public static let settingToMenuType: [String: [MessageActionType]] = [
        "reply": [.reply],
        "forward": [.forward],
        "reply_in_thread": [.createThread, .openThread],
        "copy": [.copy, .cardCopy],
        "audio_play_mode": [.audioPlayMode],
        "audio_to_text": [.audioText],
        "mute_play_video": [.mutePlay],
        "edit_image": [.imageEdit],
        "add_sticker": [.addToSticker],
        "recall": [.recall],
        "reedit": [.multiEdit],
        "ding": [.urgent],
        "multi_select": [.multiSelect],
        "my_ai_debug_mode": [.quickActionInfo],
        "flag": [.flag],
        "favorite": [.favorite],
        "pin": [.pin],
        "chat_pin": [.chatPin],
        "pin_to_top": [.topMessage],
        "copy_link": [.messageLink],
        "back_to_chat": [.jumpToChat, .toOriginal],
        "message_restrict": [.restrict],
        "translate": [.translate],
        "hyper_translate": [.selectTranslate],
        "switch_translate_language": [.switchLanguage],
        "search": [.search],
        "delete": [.delete],
        "add_task": [.todo],
        "meego": [.meego],
        "shortcuts": [.takeActionV2],
        "debug": [.debug],
        "my_ai_up_vote": [.like],
        "my_ai_down_vote": [.dislike],
        "my_ai_answer_process": [.viewGenerationProcess],
        "ka": [.ka]
    ]

    static func abTestSheetOrderForShowSaveTo(_ menuSheet: [[MessageActionType]]) -> [[MessageActionType]] {
        var abTestSheetArr: [[MessageActionType]] = [[MessageActionType]]()
        for (idx, item) in menuSheet.enumerated() {
            if idx == 0 {
                abTestSheetArr.append(MessageActionOrder.abTextReorderMenus(item))
            } else {
                abTestSheetArr.append(item)
            }
        }
        return abTestSheetArr
    }


    static var abTestHover: [MessageActionType]  = {
        return MessageActionOrder.abTextReorderMenus(MessageActionOrder.hover)
    }()

    static func abTextReorderMenus(_ menus: [MessageActionType]) -> [MessageActionType] {
        var newArr: [MessageActionType]  = []
        var hasReply = false
        var hasOpenThread = false
        var hasCreateThread = false
        menus.forEach { value in
            if value == MessageActionType.reply {
                newArr.append(contentsOf: [.createThread, .openThread])
                hasReply = true
            } else if value == MessageActionType.openThread {
                hasOpenThread = true
            } else if value == MessageActionType.createThread {
                newArr.append(contentsOf: [.reply])
                hasCreateThread = true
            } else {
                newArr.append(value)
            }
        }
        guard hasReply, hasOpenThread, hasCreateThread else {
            assertionFailure("error data")
            return menus
        }
        return newArr
    }

    static func settingToActionType(settingName: String) -> [MessageActionType] {
        if let result = settingToMenuType[settingName] {
            return result
        } else {
            Self.logger.info("this setting key (\(settingName)) is not defined in client.")
            return []
        }
    }

    /// 遍历 mobileConfig 数组中的每个项，将其中的 actionName 转换为本地的菜单类型
    static func formatSetting(config: [MessageActionOrderSetting.MessageActionOrderSection]) -> [[MessageActionType]] {
        var actionTypeArray: [[MessageActionType]] = []
        var gridActionTypes: [MessageActionType] = []
        for section in config {
            var sectionActionTypes: [MessageActionType] = []
            if section.arrangement == "grid" {
                /// 处理宫格数据
                for item in section.actionList {
                    let itemActionTypes = settingToActionType(settingName: item)
                    gridActionTypes += itemActionTypes
                }
            } else {
                /// 处理栅格数据
                for item in section.actionList {
                    let itemActionTypes = settingToActionType(settingName: item)
                    sectionActionTypes += itemActionTypes
                }
                if !sectionActionTypes.isEmpty {
                    actionTypeArray.append(sectionActionTypes)
                }
            }
        }
        #if DEBUG || BETA || ALPHA
        /// 测试包允许展示消息debug按钮
        actionTypeArray.insert([.debug], at: 0)
        #endif
        /// 宫格数据放在第一个
        actionTypeArray.insert(gridActionTypes, at: 0)
        return actionTypeArray
    }
}

struct MessageActionOrderSetting: SettingDecodable {
    static let settingKey: UserSettingKey = .make(userKeyLiteral: "message_menu_list_normal")

    var mobileConfig: [MessageActionOrderSection]
    var mobilePartialConfig: [String]

    struct MessageActionOrderSection: Decodable {
        /// section中item集合
        var actionList: [String]
        /// 区分宫格/sheet两类排布方式
        var arrangement: String
        /// 二级菜单
        var childActionMap: [String: [String]]
    }
}

