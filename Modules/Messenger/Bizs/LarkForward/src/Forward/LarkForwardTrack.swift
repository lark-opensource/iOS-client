//
//  LarkForwardTrack.swift
//  LarkForward
//
//  Created by 姚启灏 on 2018/12/4.
//

import Foundation
import Homeric
import LarkCore
import LKCommonsTracker
import LarkModel
import LarkMessengerInterface
import LarkSDKInterface
import enum AppReciableSDK.Event
import struct AppReciableSDK.Extra
import class AppReciableSDK.DisposedKey
import class AppReciableSDK.AppReciableSDK
import struct AppReciableSDK.ErrorParams

final class Tracer {

    static func trackTapFlod(isFlod: Bool) {
        Tracker.post(TeaEvent(Homeric.MESSAGE_FORWARD_CLICK_MORE, params: ["action": isFlod ? "open" : "close"]))
    }

    static func trackSingleClick(location: String, position: Int, chatId: String, source: String? = nil) {
        var param: [String: Any] = ["location": location, "sort_position": position, "chat_id": chatId]
        if let source = source {
            param["source"] = source
        }
        Tracker.post(TeaEvent(Homeric.MESSAGE_FORWARD_SINGLE_CLICK, params: param))
    }

    static func trackMultiClick(location: String, position: Int, chatId: String, source: String? = nil) {
        var param: [String: Any] = ["location": location, "sort_position": position, "chat_id": chatId]
        if let source = source {
            param["source"] = source
        }
        Tracker.post(TeaEvent(Homeric.MESSAGE_FORWARD_MULTI_CLICK, params: param))
    }

    static func trackMessageForweardCreateGroup(
        isExternal: Bool,
        isPublic: Bool,
        isThread: Bool,
        chatterNumbers: Int,
        source: String? = nil
    ) {
        var type = ""
        if isExternal {
            type = "external"
        } else {
            type = isPublic ? "public" : "private"
        }
        var mode = isThread ? "topic" : "classic"
        var params: [String: Any] = [
            "type": type,
            "mode": mode,
            "members_number": chatterNumbers
        ]
        if let source = source {
            params["source"] = source
        }
        Tracker.post(TeaEvent(Homeric.MESSAGE_FORWARD_CREATE_GROUP, params: params))
    }

    static func trackMergeForwardConfirm() {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_FORWARD_CONFIRM))
    }

    static func trackMergeForwardCancel() {
        Tracker.post(TeaEvent(Homeric.MULTISELECT_FORWARD_CANCEL, params: ["location": "forward_list"]))
    }

    static func trackEventShareForwardDone() {
        Tracker.post(TeaEvent(Homeric.CAL_SHARE_FORWARD))
    }

    static func trackChatConfigShareConfirmed(isExternal: Bool, isPublic: Bool) {
        var type = ""
        if isExternal {
            type = "external"
        } else {
            type = isPublic ? "public" : "private"
        }
        Tracker.post(TeaEvent(Homeric.CHAT_CONFIG_SHARE_CONFIRMED, params: ["type": type]))
    }

    // 转发数目
    static func trackForwardNum(_ chats: [Chat], isPostscript: Bool, from: ForwardMessageBody.From, message: Message) {
        let fromLocation: String
        switch from {
        case .chat:
            fromLocation = "chat"
        case .favorite:
            fromLocation = "favorite"
        case .flag:
            fromLocation = "flag"
        case .file:
            fromLocation = "in_file_page"
        case .pin:
            fromLocation = "pin"
        case .thread:
            fromLocation = "thread"
        case .location:
            fromLocation = "location"
        case .preview:
            fromLocation = "image_view"
        @unknown default:
            fromLocation = ""
        }
        var params: [String: Any] = [
            "receiver_num": chats.count,
            "is_postscript": isPostscript ? "y" : "n",
            "location": fromLocation,
            "message_type": "\(message.type)",
            "cid": message.cid,
            "chat_id": message.channel.id,
            "message_id": message.id,
            "chat_aim_id": chats.map { $0.id }
        ]
        if from == .thread {
            params["chat_type"] = "group_topic"
            params["thread_id"] = message.threadId
        }
        Tracker.post(TeaEvent(Homeric.MESSAGE_FORWARD, category: "message", params: params))
    }

    // 系统分享
    static func trackSysShare(shareType: String) {
        Tracker.post(TeaEvent(Homeric.SYS_SHARE, params: ["message_type": shareType]))
    }

    // 转发新建群聊打开选人界面
    static func trackMessageForwardCreateGroupAttempt() {
        Tracker.post(TeaEvent(Homeric.MESSAGE_FORWARD_CREATE_GROUP_ATTEMPT))
    }
    // 转发出现错误
    static func trackForwardError(event: Event,
                                  traceChatType: ForwardAppReciableTrackChatType,
                                  error: Error,
                                  chatIds: [String],
                                  userIds: [String]) {
        AppReciableSDK.shared.error(params: ErrorParams(biz: .Messenger,
                                                        scene: .Chat,
                                                        event: event,
                                                        errorType: .SDK,
                                                        errorLevel: .Exception,
                                                        errorCode: (error as NSError).code,
                                                        userAction: nil,
                                                        page: "ForwardComponentViewController",
                                                        errorMessage: (error as NSError).description,
                                                        extra: Extra(isNeedNet: true,
                                                                     category: ["chat_type": "\(traceChatType.rawValue)"],
                                                                     extra: ["chat_count": "\(chatIds.count + userIds.count)"])))
    }
}

extension Tracer {
    static func trackStickerSetForward() {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_FORWARD))
    }

    enum EmotionForwardForm: String {
        case chat = "1"
        case emotionDetailPage = "2"
    }
    static func trackStickerForward(from: EmotionForwardForm) {
        Tracker.post(TeaEvent(Homeric.STICKERPACK_STICKERFORWARD, params: ["stickerpack_stickerforward_location": from.rawValue]))
    }
}

//OpenShareSdk
extension Tracer {
    static func trackEnterOpenShareForward(source: String, type: String) {
        Tracker.post(TeaEvent(Homeric.ENTER_FORWARD_SDK, params: [source: source, type: type]))
    }

    static func trackOpenShareForwardConfirmed(source: String, type: String) {
        Tracker.post(TeaEvent(Homeric.FORWARD_CONFIRM_SDK, params: ["type": type,
                                                                     "source": source ]))
    }

    static func trackForwardSelectChat(source: String) {
        Tracker.post(TeaEvent(Homeric.FORWARD_SELECT_CHAT, params: ["source": source]))
    }

    // 查看群名片分享页面
    static func imShareGroupView(chat: Chat) {
        ///「群分享」页面(82)
        Tracker.post(TeaEvent(Homeric.IM_SHARE_GROUP_VIEW, params: IMTracker.Param.chat(chat)))
    }

    // 查看群名片分享页面
    static func trackImChatSettingChatForwardPageView(chatId: String,
                                                      isAdmin: Bool,
                                                      chat: Chat) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CHAT_FORWARD_PAGE_VIEW,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue
                              ]))
        ///「群分享」页面(83)
        var params: [AnyHashable: Any] = [ "click": "group_profile",
                                           "target": "public_multi_select_share_view" ]
        params += IMTracker.Param.chat(chat)
        Tracker.post(TeaEvent(Homeric.IM_SHARE_GROUP_CLICK, params: params))
    }

    // 转发群名片
    static func trackImChatSettingChatForwardClick(chatId: String,
                                                   isAdmin: Bool,
                                                   chatCount: Int,
                                                   msgCount: Int,
                                                   isMsg: Bool) {
        let memberType = MessengerMemberType.getTypeWithIsAdmin(isAdmin)
        Tracker.post(TeaEvent(Homeric.IM_CHAT_SETTING_CHAT_FORWARD_CLICK,
                              params: ["chat_id": chatId,
                                       "member_type": memberType.rawValue,
                                       "input_msg": isMsg,
                                       "chat_count": "\(chatCount)",
                                       "msg_char_count": "\(msgCount)"
                              ]))
    }

    // 创建群组并转发建群成功
    static func trackForwardCreateGroupSuccess(chat: Chat) {
        Tracker.post(TeaEvent(Homeric.IM_CHAT_CREATE_SUCCESS,
                              params: ["source": CreateGroupFromWhere.forward.rawValue,
                                       "type": MessengerChatType.getTypeWithChat(chat).rawValue,
                                       "mode": MessengerChatMode.getTypeWithIsPublic(chat.isPublic).rawValue,
                                       "is_external": chat.isCrossTenant ? 1 : 0])
        )
    }

    // 开始创建群组
    static func tarckCreateGroup(chatID: String,
                                 isCustom: Bool,
                                 isExternal: Bool,
                                 isPublic: Bool,
                                 modeType: String,
                                 count: Int) {
        func trackType() -> String {
            if isExternal {
                return "external"
            }
            return isPublic ? "public" : "private"
        }
        Tracker.post(TeaEvent(Homeric.GROUP_CREATE, params: ["chat_id": chatID,
                                                             "type": trackType(),
                                                             "mode": modeType,
                                                             "avatar": "default",
                                                             "members_number": count,
                                                             "group_name": isCustom ? "custom" : "default"]))
    }
}

struct ShareAppreciableTracker {
    enum FromType: Int {
        case unknown = 0
        case userCard
        case groupCard
        case topic
        case web
        case h5app
    }

    private var disposedKey: DisposedKey?
    private let pageName: String
    private let fromType: FromType

    init(pageName: String, fromType: FromType) {
        self.pageName = pageName
        self.fromType = fromType
    }

    mutating func start() {
        self.disposedKey = AppReciableSDK.shared.start(
            biz: .Messenger, scene: .Chat, event: .shareOperation, page: pageName, userAction: nil, extra: nil
        )
    }

    func end(sdkCost: CFTimeInterval) {
        guard let disposedKey = self.disposedKey else {
            return
        }
        AppReciableSDK.shared.end(key: disposedKey, extra: Extra(
            isNeedNet: true,
            latencyDetail: [
                "sdk_cost": Int(sdkCost * 1000)
            ],
            metric: nil,
            category: [
                "from_type": fromType.rawValue
            ]
        ))
    }

    func error(_ error: Error) {
        var errorCode = 0
        var errorMessage: String?
        if let error = error.underlyingError as? APIError {
            errorCode = Int(error.code)
            errorMessage = error.localizedDescription
        } else {
            let error = error as NSError
            errorCode = error.code
            errorMessage = error.localizedDescription
        }
        AppReciableSDK.shared.error(params: ErrorParams(
            biz: .Messenger, scene: .Chat, event: .shareOperation, errorType: .SDK, errorLevel: .Fatal,
            errorCode: errorCode, userAction: nil, page: pageName, errorMessage: errorMessage,
            extra: Extra(
                isNeedNet: true, latencyDetail: nil, metric: nil, category: ["from_type": fromType.rawValue])
        ))
    }
}

extension Message {
    var hasResource: Bool {
        switch self.type {
        case .text:
            guard let content = self.content as? TextContent else {
                return false
            }
            return !content.richText.mediaIds.isEmpty || !content.richText.imageIds.isEmpty
        case .post:
            guard let content = self.content as? PostContent else {
                return false
            }
            return !content.richText.mediaIds.isEmpty || !content.richText.imageIds.isEmpty
        case .mergeForward:
            guard let content = self.content as? MergeForwardContent else {
                return false
            }
            return content.messages.contains { (msg) -> Bool in
                return msg.hasResource
            }
        case .file, .folder, .audio, .media, .image, .sticker:
            return true
        case .unknown, .email, .calendar, .shareCalendarEvent, .hongbao,
             .generalCalendar, .videoChat, .commercializedHongbao, .shareUserCard,
             .system, .shareGroupChat, .card, .location, .todo, .diagnose, .vote:
            break
        @unknown default:
            break
        }
        return false
    }
}
