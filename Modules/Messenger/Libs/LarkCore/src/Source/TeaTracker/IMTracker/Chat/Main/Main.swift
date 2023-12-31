//
//  Main.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2021/5/11.
//

import Foundation
import LKCommonsTracker
import Homeric
import LarkModel
import LarkMessengerInterface
import LarkMessageBase
import LarkFeatureGating
import LarkBaseKeyboard
import LarkContainer

/// 会话主界面相关埋点
public extension IMTracker.Chat {
    struct Main {}
}

/// 会话主界面显示
public extension IMTracker.Chat.Main {
    static func View(_ chat: Chat, params: [AnyHashable: Any], _ fromWhere: ChatFromWhere?) {
        var params = params
        params += IMTracker.Param.chat(chat)
        if let fromWhere = fromWhere {
            params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
        }
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_VIEW,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }

    static func viewExtension(_ chat: Chat, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
        var params: [AnyHashable: Any] = params
        params += IMTracker.Param.chat(chat)
        params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
        Tracker.post(TeaEvent(Homeric.IM_AI_EXTENSIONS_VIEW,
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

/// 会话主界面点击
public extension IMTracker.Chat.Main {

    static let ChatFromWhereKey: String = "ChatFromWhereKey"

    struct Click {
        public static func Sidebar(_ chat: Chat, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "setting_sidebar", "target": "im_chat_setting_view"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 长按消息
        public static func MsgPress(_ chat: Chat, _ message: Message, _ fromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = ["click": "msg_press", "target": "im_msg_menu_view"]
            params += IMTracker.Param.message(message)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 点击分享的群名片的「群名字」或「群头像」
        public static func groupCardTitleShare(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "group_card_title_share", "target": "im_chat_group_card_view"]
            params += IMTracker.Param.message(message)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 点击分享的群名片的「加入该群」按钮
        public static func groupCardButtonShare(_ chat: Chat, _ message: Message, _ chatScene: String?, isToastRemind: Bool, toastRemind: String?) {
            var params: [AnyHashable: Any] = ["click": "group_card_button_share",
                                              "target": "none",
                                              "is_toast_remind": isToastRemind ? "true" : "false"]
            if isToastRemind, let toastRemind = toastRemind {
                params["toast_remind"] = toastRemind
            }
            params += IMTracker.Param.message(message)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func InputEmoji(_ chat: Chat?, isFullScreen: Bool, _ threadId: String?, _ chatFromWhere: ChatFromWhere?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "input_emoji",
                                              "is_full_screen": isFullScreen ? "true" : "false",
                                              "target": "public_emoji_panel_select_view"]
            if chat.chatMode == .threadV2, let threadId = threadId {
                params["thread_id"] = threadId
            }
            if let chatFromWhere = chatFromWhere {
                params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            }
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func VoiceMsg(_ chat: Chat, _ threadId: String?, _ chatFromWhere: ChatFromWhere?) {
            var params: [AnyHashable: Any] = ["click": "voice_msg", "target": "im_chat_voice_msg_view"]
            if let threadId = threadId {
                params["thread_id"] = threadId
            }
            if let chatFromWhere = chatFromWhere {
                params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            }
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ImageSelect(_ chat: Chat?, isFulllScreen: Bool, _ threadId: String?, _ chatFromWhere: ChatFromWhere?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "image_select",
                                              "target": "im_chat_image_send_view",
                                              "is_full_screen": isFulllScreen ? "true" : "false"]
            if chat.chatMode == .threadV2, let threadId = threadId {
                params["thread_id"] = threadId
            }
            if let chatFromWhere = chatFromWhere {
                params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            }
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func InputPlus(_ chat: Chat, _ chatFromWhere: ChatFromWhere?) {
            var params: [AnyHashable: Any] = ["click": "input_plus", "target": "im_chat_input_plus_view"]
            params += IMTracker.Param.chat(chat)
            if let chatFromWhere = chatFromWhere {
                params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            }
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Post(_ chat: Chat, _ chatFromWhere: ChatFromWhere?) {
            var params: [AnyHashable: Any] = ["click": "post", "target": "im_chat_post_view"]
            params += IMTracker.Param.chat(chat)
            if let chatFromWhere = chatFromWhere {
                params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            }
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Meeting(_ chat: Chat, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "meeting", "target": "vc_meeting_pre_view"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func MutipleCall(_ chat: Chat, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "multiple_call", "target": "im_call_select_view"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 话题群，点击[我订阅的]
        public static func MySubscribe(_ chat: Chat) {
            var params: [AnyHashable: Any] = ["click": "my_subscribe", "target": "none"]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 点击大拇指reaction
        public static func ReactionClick(_ chat: Chat, _ threadId: String, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "topic_reaction_click", "target": "none", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TopicReply(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "topic_reply", "target": "none", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TopicForward(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "topic_forward", "target": "public_multi_select_share_view", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TopicSubscribe(_ chat: Chat, _ threadId: String) {
            var params: [AnyHashable: Any] = ["click": "topic_subscribe", "target": "none", "thread_id": threadId]
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 发送消息
        public static func MsgSend(_ chat: Chat, _ message: Message, _ chatFromWhere: String?) {
            var params: [AnyHashable: Any] = ["click": "msg_send", "target": "none"]
            params += IMTracker.Param.message(message)
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 阅读消息
        public static func MsgRead(_ chat: Chat, _ id: String, _ cid: String, _ type: String, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "msg_read", "target": "none", "msg_id": id, "cid": cid, "msg_type": type]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 点击聊天中私有话题群卡片
        public static func threadCardClick(_ chat: Chat, tapCardGroup: Bool, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": !tapCardGroup ? "topic_card_msg" : "topic_card_group",
                                              "target": !tapCardGroup ? "im_chat_main_view" : "channel_topic_detail_view"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabAdd(_ chat: Chat, _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = ["click": "tab_add",
                                              "target": "im_chat_doc_page_add_view",
                                              "location": "tab_more"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabMore(_ chat: Chat, _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = ["click": "tab_more",
                                              "target": "none"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabManagement(_ chat: Chat, _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = ["click": "tab_manage",
                                              "target": "im_chat_doc_page_manage_view"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TabClick(_ chat: Chat, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var md5AllowList: [String] = []
            var params = params
            params += ["target": "none",
                       "click": "single_tab"]
            if params["file_id"] != nil {
                md5AllowList = ["file_id"]
            } else {
                params["file_id"] = "NA"
            }
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: md5AllowList,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public enum TranslateStatus: String {
            case all //全部使用自动翻译
            case part //部分使用自动翻译
            case none //未使用自动翻译
        }
        public static func InputMsgSend(_ chat: Chat?,
                                        message: Message,
                                        isFullScreen: Bool,
                                        useSendBtn: Bool,
                                        translateStatus: TranslateStatus,
                                        _ threadId: String? = nil,
                                        _ fromWhere: ChatFromWhere?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "input_box_msg_send",
                                              "target": "none",
                                              "type": useSendBtn ? "button_send" : "hotkey_send",
                                              "is_full_screen": isFullScreen ? "true" : "false",
                                              "have_typing_translation": chat.typingTranslateSetting.isOpen ? "true" : "false",
                                              "is_translated": translateStatus.rawValue]
            if chat.chatMode == .threadV2, let threadId = threadId {
                params["thread_id"] = threadId
            }
            if let fromWhere = fromWhere {
                params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            }
            params += IMTracker.Param.message(message)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ImageMediaInsert(_ chat: Chat?, isFullScreen: Bool, isImage: Bool, _ fromWhere: ChatFromWhere) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "image_media_insert",
                                              "target": "none",
                                              "is_full_screen": isFullScreen ? "true" : "false",
                                              "insert_type": !isImage ? "media" : "image：图片"]
            params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Toolbar(_ chat: Chat?, isFullScreen: Bool, _ threadId: String? = nil, _ fromWhere: ChatFromWhere?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "toolbar",
                                              "target": "im_chat_toolbar_view",
                                              "is_full_screen": isFullScreen ? "true" : "false"]
            if chat.chatMode == .threadV2, let threadId = threadId {
                params["thread_id"] = threadId
            }
            if let fromWhere = fromWhere {
                params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            }
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func TextEdit(_ chat: Chat,
                                    isFullScreen: Bool,
                                    isUserClick: Bool,
                                    _ fromWhere: ChatFromWhere?,
                                    item: FontToolBarStatusItem? = nil,
                                    type: FontActionType? = nil) {
            var types: [FontActionType] = []
            if let item = item {
                if item.isBold {
                    types.append(.bold)
                }
                if item.isItalic {
                    types.append(.italic)
                }
                if item.isUnderline {
                    types.append(.underline)
                }
                if item.isStrikethrough {
                    types.append(.strikethrough)
                }
            } else if let type = type {
                types.append(type)
            }

            let fontStyles = types.map { type -> String in
                var style = ""
                switch type {
                case .bold:
                    style = "bold"
                case .italic:
                    style = "italic"
                case .underline:
                    style = "underline"
                case .strikethrough:
                    style = "strikethrough"
                default:
                    style = "none"
                }
                return style
            }

            guard !fontStyles.isEmpty else {
                return
            }
            let upload: (String) -> Void = { style in
                var params: [AnyHashable: Any] = ["click": "text_edit",
                                                  "target": "none",
                                                  "edit_function": style,
                                                  "trigger_method": isUserClick ? "aa_toolbar_action" : "bubble_toolbar_action",
                                                  "is_full_screen": isFullScreen ? "true" : "false"]
                params += IMTracker.Param.chat(chat)
                if let fromWhere = fromWhere {
                    params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
                }
                Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                      params: params,
                                      bizSceneModels: [IMTracker.Transform.chat(chat)]))
            }
            fontStyles.forEach { style in
                upload(style)
            }
        }

        public static func AtMention(_ chat: Chat, isFullScreen: Bool, _ chatScene: String?, threadId: String? = nil) {
            var params: [AnyHashable: Any] = ["click": "at_mention",
                                              "target": "public_at_mention_select_view",
                                              "is_full_screen": isFullScreen ? "true" : "false"]
            if let threadId = threadId {
                params["thread_id"] = threadId
            }
            params += IMTracker.Param.chatSceneDic(chatScene)
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func FullScreen(_ chat: Chat?, _ fromWhere: ChatFromWhere?, open: Bool, _ threadId: String? = nil) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "full_screen",
                                              "target": "none",
                                              "action_type": open ? "open" : "close"]
            if chat.chatMode == .threadV2, let threadId = threadId {
                params["thread_id"] = threadId
            }
            if let fromWhere = fromWhere {
                params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            }
            params += IMTracker.Param.chat(chat)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        //关闭翻译时，点击的位置
        public enum CloseTranslationClickLocation: String {
            case chat_view
            case input_box_view
        }
        public static func closeTranslation(_ chat: Chat, _ chatScene: String?, location: CloseTranslationClickLocation) {
            var params: [AnyHashable: Any] = ["click": "close_translation",
                                              "target": "none",
                                              "location": location.rawValue,
                                              "have_typing_translation": "true"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func NavigationTitle(_ chat: Chat, _ fromWhere: String) {
            let userResolver = Container.shared.getCurrentUserResolver()
            guard userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "im.chat.titlebar.tabs.202203")) else { return }
            var params: [AnyHashable: Any] = ["click": "name",
                                              "target": "none"]
            params += IMTracker.Param.chatSceneDic(fromWhere)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK, userID: userResolver.userID,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        //关闭翻译时，点击的位置
        public enum FoldCardClickType {
            case repeat_plus_button(UInt)
            case repeat_card

            var rawValue: String {
                switch self {
                case .repeat_plus_button(_): return "repeat_plus_button"
                case .repeat_card: return "repeat_card"
                }
            }

            var repeatCnt: UInt? {
                switch self {
                case .repeat_plus_button(let count): return count
                case .repeat_card: return nil
                }
            }
        }

        public static func FoldCard(_ chat: Chat, _ chatScene: String?, type: FoldCardClickType) {
            var params: [AnyHashable: Any] = ["click": type.rawValue,
                                              "target": "none"]
            if let count = type.repeatCnt {
                params["repeat_cnt"] = count
            }
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ChatMenuSwitch(_ chat: Chat, switchToInput: Bool, _ fromWhere: ChatFromWhere?) {
            var params: [AnyHashable: Any] = ["click": "switch_menu",
                                              "target": "none",
                                              "menu_type": switchToInput ? "app_menu_to_input_box" : "input_box_to_app_menu"]
            if let fromWhere {
                params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            }
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func CreateTopicClick(_ chat: Chat, _ fromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = ["click": "create_topic", "target": "im_thread_detail_view"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ChatWidgetFrame(_ chat: Chat, widetIds: [Int64], isFold: Bool) {
            var params: [AnyHashable: Any] = ["widget_id": widetIds,
                                              "target": "none",
                                              "click": "chat_widget_frame"]
            params += ["action_type": isFold ? "fold" : "expand"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ChatWidgetPress(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "chat_widget_frame",
                                              "action_type": "press"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ChatWidgetEdit(_ chat: Chat) {
            let params: [AnyHashable: Any] = ["click": "chat_widget_frame",
                                              "action_type": "edit"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ChatWidgetDrag(_ chat: Chat, widetIds: [Int64]) {
            let params: [AnyHashable: Any] = ["widget_id": widetIds,
                                              "click": "chat_widget_frame",
                                              "action_type": "drag"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ChatWidgetRemove(_ chat: Chat, widetIds: [Int64]) {
            let params: [AnyHashable: Any] = ["widget_id": widetIds,
                                              "click": "chat_widget_frame",
                                              "action_type": "remove"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func stopResponding(_ chat: Chat, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = params
            params += ["click": "stop_responding", "target": "none"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func regenerate(_ chat: Chat, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = params
            params += ["click": "regenerate", "target": "none"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func newTopic(_ chat: Chat, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = params
            params += ["click": "new_topic", "target": "none"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 点击键盘上方「场景对话」按钮
        public static func sceneList(_ chat: Chat, _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = [:]
            params += ["click": "scene_chat_main", "target": "im_ai_scene_chat_view"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func clickExtension(_ chat: Chat, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = params
            params += ["click": "add_extension", "target": "none"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func selectExtension(_ chat: Chat, params: [AnyHashable: Any], _ chatFromWhere: ChatFromWhere) {
            var params: [AnyHashable: Any] = params
            params += ["click": "confirm", "target": "none"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            Tracker.post(TeaEvent(Homeric.IM_AI_EXTENSIONS_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

/// Msg的点击比较复杂，再扩展一层
public extension IMTracker.Chat.Main.Click {

    enum ReplyThreadMsgClickType: String {
        case threadReply = "thread_reply" //点击话题回复
        case threadCard = "thread_card" ///点击话题卡片
    }
    /// 点击消息某个具体位置
    struct Msg {
        private static func urlParams(_ message: Message, _ url: URL?) -> [AnyHashable: Any] {
            guard let url = url else { return ["is_url": "false", "url_id": "none", "url_domain_path": "none"] }
            var params: [AnyHashable: Any] = ["is_url": "true"]
            var domainPath = url.absoluteString
            if let domain = url.host {
                domainPath = domain.appending(url.path)
            }
            params["url_domain_path"] = domainPath
            if let point = message.urlPreviewHangPointMap.first(where: { $0.value.url == url.absoluteString })?.value {
                params["url_id"] = point.previewID
            } else {
                params["url_id"] = "none"
            }
            return params
        }

        public static func URL(_ chat: Chat, _ message: Message, _ chatScene: String?, _ url: URL) {
            var params: [AnyHashable: Any] = ["click": "url", "target": "none"]
            params += IMTracker.Param.message(message, doc: false)
            params += urlParams(message, url)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// URL中台埋点：https://bytedance.feishu.cn/sheets/shtcnd9NLwJ68HwANMeYSe4ykRg
        public static func URLPreviewClick(_ chat: Chat, _ message: Message, _ scene: ContextScene, _ url: URL) {
            let entities = Array(MessageInlineViewModel.getInlinePreviewBody(message: message).values)
            let entity = entities.first(where: { $0.url?.tcURL == url.absoluteString })
            // 埋点需求，URLRenderClick和URLParseClick无法合并
            if entity != nil {
                URLRenderClick(chat, message, url)
            }

            let occasion: String
            switch scene {
            case .threadChat, .threadDetail, .replyInThread, .threadPostForwardDetail: occasion = "topic"
            case .newChat, .messageDetail: occasion = "msg"
            case .mergeForwardDetail: occasion = "multi_forward"
            case .pin: occasion = "pin"
            }
            URLParseClick(message, occasion, entity, url)
        }

        /// URL渲染成超链接时，点击超链接上报IM_URL_RENDER_CLICK
        public static func URLRenderClick(_ chat: Chat, _ message: Message, _ url: URL) {
            var urlParams = urlParams(message, url)
            var params: [AnyHashable: Any] = ["click": "open_url",
                                              "url_domain_path": urlParams["url_domain_path"] ?? url.absoluteString,
                                              "url_id": urlParams["url_id"] ?? "none",
                                              "target": "none"]
            params += IMTracker.Param.chat(chat)
            params += IMTracker.Param.message(message, doc: false)
            // URL预览，额外上报IM_URL_RENDER_CLICK埋点
            Tracker.post(TeaEvent(Homeric.IM_URL_RENDER_CLICK,
                                  params: params))
        }

        /// URL解析链接点击
        public static func URLParseClick(_ message: Message, _ scene: String, _ entity: InlinePreviewEntity?, _ url: URL) {
            var params: [AnyHashable: Any] = [:]
            if !message.urlPreviewHangPointMap.contains(where: { $0.value.url == url.absoluteString }) {
                params["is_succeed_parse"] = "none" // 未接入中台上报none
            } else if let title = entity?.title, !title.isEmpty { // 无title时表示解析失败
                params["is_succeed_parse"] = "true"
            } else {
                params["is_succeed_parse"] = "false"
            }
            var urlParams = urlParams(message, url)
            params["url_domain_path"] = urlParams["url_domain_path"] ?? url.absoluteString
            params["url_id"] = urlParams["url_id"] ?? "none"
            params["target"] = "none"
            params["click"] = "open_url"
            params["occasion"] = scene
            Tracker.post(TeaEvent(Homeric.IM_URL_PARSE_CLICK, params: params))
        }

        public static func Doc(_ chat: Chat, _ message: Message, _ url: URL, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "docs", "target": "ccm_docs_page_view"]
            params += IMTracker.Param.message(message, doc: true, docUrl: url.absoluteString)
            params += urlParams(message, url)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Image(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "image", "target": "public_picbrowser_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Media(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "media", "target": "public_picbrowser_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Sticker(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "sticker", "target": "public_picbrowser_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Reaction(_ chat: Chat, _ message: Message, _ chatScene: String?, effect: String, type: String) {
            var params: [AnyHashable: Any] = ["click": "reaction", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params["effect"] = effect
            params["reaction_type"] = type
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func MergeForward(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "mergeforward", "target": "im_msg_mergeforward_detail_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ShareGroupChat(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "shareGroupChat", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func ShareUserCard(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "self_user_card", "target": "profile_main_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Someone(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "@someone", "target": "profile_main_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Icon(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "icon", "target": "profile_main_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Vote(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "card", "target": "none"]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func File(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "file",
                                              "msg_id": "\(message.id)",
                                              "target": "ccm_local_page_view"]
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func Folder(_ chat: Chat, _ message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "file_card",
                                              "file_type": "folder",
                                              "msg_id": "\(message.id)",
                                              "target": "im_chat_file_manage_view"]
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func AvatarMedal(_ userID: String, _ medalID: String, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "icon",
                                              "to_user_id": userID,
                                              "is_medal": medalID.isEmpty ? "false" : "true",
                                              "target": "profile_main_view"]
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["to_user_id"]))
        }
        public static func ReplyThread(_ chat: Chat, _ message: Message, _ chatScene: String?, type: ReplyThreadMsgClickType) {
            var params: [AnyHashable: Any] = ["click": type.rawValue,
                                              "target": "im_thread_detail_view",
                                              "thread_id": message.threadId.isEmpty ? message.id : message.threadId]
            params += IMTracker.Param.message(message, doc: true)
            params += urlParams(message, nil)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  md5AllowList: ["file_id"],
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public enum SaveEditMsgTriggerMethod: String {
            case hotkey_action
            case click_save
        }
        public static func saveEditMsg(_ chat: Chat?, _ message: Message?, triggerMethod: SaveEditMsgTriggerMethod, _ chatFromWhere: ChatFromWhere?) {
            guard let chat = chat,
                  let message = message else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "save_edit_msg",
                                              "trigger_method": triggerMethod.rawValue,
                                              "target": "none"]
            if let chatFromWhere = chatFromWhere {
                params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
            }
            params += urlParams(message, nil)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func delayedMsgEdit(_ chat: Chat?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "delayed_msg_edit",
                                              "target": "none"]
        }

        public static func replyTopicClick(_ chat: Chat, message: Message, _ chatScene: String?) {
            var params: [AnyHashable: Any] = ["click": "reply_topic",
                                              "thread_id": message.threadId.isEmpty ? message.id : message.threadId,
                                              "target": "im_thread_detail_view"]
            params += IMTracker.Param.message(message, doc: true)
            params += IMTracker.Param.chatSceneDic(chatScene)
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func delayedSendMobile(_ chat: Chat?, _ fromWhere: ChatFromWhere?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "delayed_send_mobile",
                                              "target": "im_msg_delayed_send_time_view"]
            if let fromWhere = fromWhere {
                params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            }
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        //用户点击“设为星标联系人”的系统消息
        public static func setStarredContactByClickSystemMessage(_ chat: Chat?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "starred_contact",
                                              "target": "profile_more_action_view"]
            Tracker.post(TeaEvent(Homeric.IM_CHAT_MAIN_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func msgDelayedSendClick(_ chat: Chat?, click: String, _ fromWhere: ChatFromWhere?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": click,
                                              "target": "none"]
            if let fromWhere = fromWhere {
                params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            }
            Tracker.post(TeaEvent(Homeric.IM_MSG_DELAYED_SEND_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func msgDelayedSendTimeClick(_ chat: Chat?, _ fromWhere: ChatFromWhere?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = ["click": "confirm",
                                              "target": "none"]
            if let fromWhere = fromWhere {
                params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            }
            Tracker.post(TeaEvent(Homeric.IM_MSG_DELAYED_SEND_TIME_CLICK,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        public static func msgDelayedSendToastView(_ chat: Chat?, _ fromWhere: ChatFromWhere?) {
            guard let chat = chat else {
                return
            }
            var params: [AnyHashable: Any] = [:]
            if let fromWhere = fromWhere {
                params += IMTracker.Param.chatSceneDic(fromWhere.rawValue)
            }
            Tracker.post(TeaEvent(Homeric.IM_MSG_DELAYED_SEND_TOAST_VIEW,
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 消息粘贴
        public static func copyClick(_ chat: Chat?,
                                     _ message: Message?,
                                     byCommand: Bool,
                                     allSelect: Bool,
                                     imageCount: Int,
                                     videoCount: Int) {
            guard let chat = chat,
                  let message = message else {
                      return
                  }
            var params: [AnyHashable: Any] = ["copy_type": byCommand ? "hotkey" : "button_click",
                                              "image_cnt": imageCount,
                                              "file_cnt": 0,
                                              "video_cnt": videoCount,
                                              "is_full_select": allSelect ? "true" : "false"]
            params += IMTracker.Param.message(message, doc: true)
            Tracker.post(TeaEvent("im_msg_copy_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }

        /// 消息粘贴
        public static func pasteClick(_ chat: Chat?,
                                     imageCount: Int,
                                     videoCount: Int) {
            guard let chat = chat else {
                      return
                  }
            var params: [AnyHashable: Any] = ["paste_type": "button_click",
                                              "image_cnt": imageCount,
                                              "file_cnt": 0,
                                              "video_cnt": videoCount]
            Tracker.post(TeaEvent("im_msg_paste_click",
                                  params: params,
                                  bizSceneModels: [IMTracker.Transform.chat(chat)]))
        }
    }
}

public extension IMTracker.Chat {
    //会话主页面里文件卡片（目前只有excel）曝光事件
    public static func imChatExcelShowClick(_ chat: Chat?) {
        guard let chat = chat else {
            return
        }
        var params: [AnyHashable: Any] = ["click": "excel_show",
                                          "target": "none",
                                          "edit_type": "none"]
        Tracker.post(TeaEvent("im_chat_excel_show_click",
                              params: params,
                              bizSceneModels: [IMTracker.Transform.chat(chat)]))
    }
}

// MARK: - MyAI 快捷指令

public extension IMTracker.Chat.Main {

    /// 快捷指令曝光
    static func QuickActionView(params: [AnyHashable: Any], chat: Chat?, chatFromWhere: ChatFromWhere?) {
        var bizSceneModels: [TeaBizSceneProtocol] = []
        var params: [AnyHashable: Any] = params
        if let chat = chat {
            params += IMTracker.Param.chat(chat)
            bizSceneModels.append(IMTracker.Transform.chat(chat))
        }
        if let chatFromWhere = chatFromWhere {
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
        }
        Tracker.post(TeaEvent("im_ai_shortcut_command_view",
                              params: params,
                              bizSceneModels: bizSceneModels))
    }
}

public extension IMTracker.Chat.Main.Click {

    /// 快捷指令点击事件（点击 & 发送）
    static func QuickAction(params: [AnyHashable: Any], chat: Chat?, chatFromWhere: ChatFromWhere?) {
        var bizSceneModels: [TeaBizSceneProtocol] = []
        var params: [AnyHashable: Any] = params
        params += ["target": "none"]
        if let chat = chat {
            params += IMTracker.Param.chat(chat)
            bizSceneModels.append(IMTracker.Transform.chat(chat))
        }
        if let chatFromWhere = chatFromWhere {
            params += IMTracker.Param.chatSceneDic(chatFromWhere.rawValue)
        }
        Tracker.post(TeaEvent("im_ai_shortcut_command_click",
                              params: params,
                              bizSceneModels: bizSceneModels))
    }
}
