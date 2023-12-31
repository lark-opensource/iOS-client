//
//  ChatNewPinConfig.swift
//  LarkMessageCore
//
//  Created by zhaojiachen on 2023/7/12.
//

import Foundation
import LarkSetting
import LarkModel
import SuiteAppConfig

public struct ChatNewPinConfig {

    public static let pinnedUrlKey: FeatureGatingManager.Key = "im.chat.pinned.url"
    public static let oldPinKey: FeatureGatingManager.Key = "im.chat.pin.from.earlier.version.to.back"

    public static func checkEnable(chat: Chat, _ featureGatingService: FeatureGatingService) -> Bool {
        if !featureGatingService.staticFeatureGatingValue(with: pinnedUrlKey) {
            return false
        }
        if AppConfigManager.shared.leanModeIsOn {
            return false
        }
        return !chat.isCrypto && !chat.isPrivateMode && !chat.isTeamVisitorMode && chat.chatMode != .threadV2 && !chat.isOncall
    }

    public static func supportPinMessage(chat: Chat, _ featureGatingService: FeatureGatingService) -> Bool {
        if !checkEnable(chat: chat, featureGatingService) {
            return false
        }
        return featureGatingService.staticFeatureGatingValue(with: "im.chat.pinned.msg")
    }

    public static func supportPinToTop(_ featureGatingService: FeatureGatingService) -> Bool {
        return featureGatingService.staticFeatureGatingValue(with: "im.chat.pinned.msg")
    }
}

public struct ChatPinPermissionUtils {

    public static func supportNewPermission(_ featureGatingService: FeatureGatingService) -> Bool {
        return featureGatingService.staticFeatureGatingValue(with: "im.chat.pin.permission")
    }

    public static func checkPinMessagePermission(chat: Chat, userID: String, featureGatingService: FeatureGatingService) -> Bool {
        if supportNewPermission(featureGatingService) {
            return checkChatPinPermission(chat: chat, userID: userID, featureGatingService: featureGatingService)
        } else {
            if chat.pinPermissionSetting == .allMembers {
                return true
            } else if chat.pinPermissionSetting == .onlyManager {
                if chat.isGroupAdmin || chat.ownerId == userID {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }

    public static func checkChatTabsMenuWidgetsPermission(chat: Chat, userID: String, featureGatingService: FeatureGatingService) -> Bool {
        if supportNewPermission(featureGatingService) {
            return checkChatPinPermission(chat: chat, userID: userID, featureGatingService: featureGatingService)
        } else {
            if chat.chatTabPermissionSetting == .allMembers {
                return true
            } else if chat.chatTabPermissionSetting == .onlyManager {
                if chat.isGroupAdmin || chat.ownerId == userID {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }

    public static func checkTopNoticePermission(chat: Chat, userID: String, featureGatingService: FeatureGatingService) -> Bool {
        if supportNewPermission(featureGatingService) {
            return checkChatPinPermission(chat: chat, userID: userID, featureGatingService: featureGatingService)
        } else {
            if chat.topNoticePermissionSetting == .allMembers {
                return true
            } else if chat.topNoticePermissionSetting == .onlyManager {
                if chat.isGroupAdmin || chat.ownerId == userID {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }

    private static func checkChatPinPermission(chat: Chat, userID: String, featureGatingService: FeatureGatingService) -> Bool {
        if chat.chatPinPermissionSetting == .allMembers {
            return true
        } else if chat.chatPinPermissionSetting == .onlyManager {
            if chat.isGroupAdmin || chat.ownerId == userID {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
}

public extension Message {
    func isSupportChatPin(cardSupportFg: Bool) -> Bool {
        let type = self.type

        switch type {
        case .audio, .shareCalendarEvent, .generalCalendar, .file, .folder,
             .image, .sticker, .media, .mergeForward, .text, .post, .shareGroupChat, .shareUserCard,
             .location, .todo, .vote, .hongbao, .commercializedHongbao, .calendar, .videoChat:
            return true
        case .unknown, .system, .diagnose, .email:
            return false
        case .card:
            guard let content = self.content as? LarkModel.CardContent else {
                return false
            }
            // 卡片中的 vote 可以pin
            if content.type == .vote {
                return true
            } else if cardSupportFg,
                      content.type == .text || content.type == .openCard,
                      // 不支持临时消息和 v1 旧版卡片的 pin 功能(样式不符合预期)
                      !isEphemeral, content.version >= 2 {
                return true
            } else {
                return false
            }
        @unknown default:
            return false
        }
    }
}
