//
//  ChatExtensionFunctionsFactory.swift
//  LarkChatSetting
//
//  Created by zc09v on 2020/5/18.
//

import Foundation
import RxSwift
import LarkBadge
import LarkCore
import LarkModel
import LKCommonsTracker
import LarkAccountInterface
import LarkContainer
import LarkOpenChat

typealias ChatExtensionFunctionType = ChatSettingFunctionItemType
typealias ExtensionFunctionImageInfo = ChatSettingItemImageInfo
typealias ChatExtensionFunction = ChatSettingFunctionItem

protocol ChatExtensionFunctionsFactory: NSObject, UserResolverWrapper {
    init(userResolver: UserResolver)
    func createExtensionFuncs(chatWrapper: ChatPushWrapper,
                              pushCenter: PushNotificationCenter,
                              rootPath: Path) -> Observable<[ChatExtensionFunction]>
    func badgeShow(for path: Path, show: Bool, type: BadgeType)
}

extension ChatExtensionFunctionsFactory {
    func trackSidebarClick(chat: Chat, type: ChatExtensionFunctionType) {
        let isGroupOwner = (userResolver.userID == chat.ownerId)
        var params = [
                "chat_type": chat.trackType,
                "chat_id": chat.id,
                "source": "sidebar",
                "is_admin": isGroupOwner ? "true" : "false"
            ]
        switch type {
        case .pin:
            params["is_meeting_chat"] = chat.isMeeting ? "true" : "false"
            params["is_bot_chat"] = chat.isSingleBot ? "true" : "false"
            params["is_secret_chat"] = chat.isCrypto ? "true" : "false"
        default:
            break
        }

        Tracker.post(TeaEvent(teaEventKey(for: type), params: params)
        )
    }

    private func teaEventKey(for functionType: ChatExtensionFunctionType) -> String {
        switch functionType {
        case .announcement:
            return "announcement_sidebar"
        case .event:
            return "cal_sidebar"
        case .freeBusyInChat:
            return "cal_freebusy"
        case .meetingSummary:
            return "minutes"
        case .pin:
            return "pin_sidebar"
        case .pinCard:
            return ""
        case .remote:
            return "remote_sidebar"
        case .search:
            return "chat_history_sidebar"
        case .setting:
            return "chat_config_sidebar"
        case .todo:
            return "todo"
        }
    }

    func badgeShow(for path: Path, show: Bool, type: BadgeType = .dot(.pin)) {
        if show {
            BadgeManager.setBadge(path, type: type)
        } else {
            BadgeManager.clearBadge(path)
        }
    }
}
