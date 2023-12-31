//
//  MessageSummarizeUtil.swift
//  LarkMessageCore
//
//  Created by bytedance on 2021/2/8.
//

import Foundation
import LarkModel
import LarkCore
import LarkSetting

public enum MessageSummarizeUtil {
    /// 这个地方生成回复
    public static func getSummarize(message: Message,
                                    isBurned: Bool = false,
                                    partialReplyInfo: PartialReplyInfo? = nil,
                                    lynxcardRenderFG: Bool) -> String {
        if message.isDeleted {
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessageRemove
        } else if message.isRecalled {
            // 企业管理员撤回展示特定的文案
            if message.recallerId.isEmpty, case .enterpriseAdministrator = message.recallerIdentity {
                return BundleI18n.LarkMessageCore.Lark_IM_MessageRecalledByAdmin_Text
            }
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessageWithdrawMessage
        } else if message.channel.type == .chat && isBurned {
            return message.isOnTimeDel ? BundleI18n.LarkMessageCore.Lark_IM_MsgDeleted_Desc : BundleI18n.LarkMessageCore.Lark_Legacy_MessageBurned
        } else if message.isSecretChatDecryptedFailed {
            return BundleI18n.LarkMessageCore.Lark_IM_SecureChat_UnableLoadMessage_Text
        }
        switch message.type {
        case .text:
            guard let content = message.content as? TextContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
            if let richText = partialReplyInfo?.content {
                return richText.lc.summerize()
            }
            return content.richText.lc.summerize()
        case .post:
            guard let content = message.content as? PostContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
            if let richText = partialReplyInfo?.content {
                return richText.lc.summerize()
            }
            if message.parentId.isEmpty && !content.isUntitledPost {
                return content.title
            } else {
                return content.richText.lc.summerize()
            }
        case .file:
            guard let content = message.content as? FileContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
            return BundleI18n.LarkMessageCore.Lark_Legacy_FileHolder + " " + content.name
        case .folder:
            guard let content = message.content as? FolderContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
            return BundleI18n.LarkMessageCore.Lark_Legacy_FileHolder + " " + content.name
        case .audio:
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoVoice
        case .image:
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoPhoto
        case .system:
            guard let content = message.content as? SystemContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
            return content.parseContent()
        case .shareUserCard:
            guard let content = message.content as? ShareUserCardContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
            return BundleI18n.LarkMessageCore.Lark_Legacy_PreviewUserCard(content.chatter?.localizedName ?? "")
        case .shareGroupChat:
            guard let content = message.content as? ShareGroupChatContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
            return BundleI18n.LarkMessageCore.Lark_Legacy_ShareGroupHolder + " " + (content.chat?.displayName ?? "")
        case .sticker:
            //如果是表情包表情,则直接返回表情包描述
            let stickerContent = message.content as? StickerContent
            let sticker = stickerContent?.transformToSticker()
            if sticker?.mode == .meme, let desc = sticker?.description_p, !desc.isEmpty {
                return "[" + desc + "]"
            }
            return BundleI18n.LarkMessageCore.Lark_Legacy_StickerHolder
        case .email:
            return ""
        case .calendar, .generalCalendar:
            if let content = message.content as? CalendarBotCardContent {
                return BundleI18n.LarkMessageCore.Calendar_CreateTaskFromEvent_TaskTitle(content.summary)
            } else if let content = message.content as? RoundRobinCardContent {
                if content.status == .statusActive {
                    return BundleI18n.LarkMessageCore.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
                } else {
                    return BundleI18n.LarkMessageCore.Calendar_Scheduling_EventNoAvailable_Bot
                }
            } else if let content = message.content as? SchedulerAppointmentCardContent {
                if content.status == .statusActive {
                    if content.action == .actionReschedule {
                        return BundleI18n.LarkMessageCore.Calendar_Scheduling_HostRescheduledByInvitee(invitee: content.guestName, host: content.hostName)
                    } else if content.action == .actionCancel {
                        return BundleI18n.LarkMessageCore.Calendar_Scheduling_HostCanceledByInvitee(invitee: content.altOperatorName, host: content.hostName)
                    } else {
                        return BundleI18n.LarkMessageCore.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
                    }
                } else {
                    return BundleI18n.LarkMessageCore.Calendar_Scheduling_EventNoAvailable_Bot
                }
            } else if let content = message.content as? GeneralCalendarEventRSVPContent {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoShareEvent + content.title
            } else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
        case .mergeForward:
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoMergeforward
        case .card:
            guard let cardContent = message.content as? CardContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard
            }
            switch cardContent.type {
            case .unknownType:
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard
            case .vote:
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCardVote
            case .vchat:
                return BundleI18n.LarkMessageCore.Lark_Legacy_VideoCall
            case .text:
                if let summerize = Self.getMesssageCardSummary(cardContent, lynxcardRenderFG: lynxcardRenderFG) {
                    return summerize
                }
                if !cardContent.header.title.isEmpty {
                    return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard + " " + cardContent.header.title
                } else {
                    let summerize = cardContent.richText.lc.summerize()
                    if !summerize.isEmpty {
                        return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard + " " + summerize
                    } else {
                        return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard
                    }
                }
            case .openCard:
                var summerize: String
                let lan = BundleI18n.currentLanguage.identifier.lowercased()
                if !cardContent.header.title.isEmpty {
                    summerize = BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard + " " + cardContent.header.title
                } else {
                    summerize = BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard
                }
                return summerize
            @unknown default:
                assert(false, "new value")
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
        case .location:
            guard let content = message.content as? LocationContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
            }
            return BundleI18n.LarkMessageCore.Lark_Chat_MessageReplyStatusLocation(content.location.name)
        case .unknown, .diagnose:
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
        case .media:
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoVideo
        case .shareCalendarEvent:
            guard let content = message.content as? EventShareContent else {
                return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoShareEvent
            }
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoShareEvent + " " + content.title
        case .hongbao, .commercializedHongbao:
            return BundleI18n.LarkMessageCore.Lark_Legacy_RedPacketHolder
        case .videoChat:
            if let content = message.content as? VChatMeetingCardContent {
                return BundleI18n.LarkMessageCore.Lark_View_VideoMeetingInviteLabel + " " + content.topic
            }
            return BundleI18n.LarkMessageCore.Lark_View_VideoMeetingInviteLabel
        case .todo:
            if let content = message.content as? TodoContent, content.pbModel.todoDetail.deletedMilliTime == 0 {
                return BundleI18n.LarkMessageCore.Todo_Task_MsgTypeTask + " " + content.pbModel.todoDetail.richSummary.richText.lc.summerize()
            }
            return BundleI18n.LarkMessageCore.Todo_Task_MsgTypeTask
        case .vote:
            return BundleI18n.LarkMessageCore.Lark_IM_Poll_PollMessage_Text
        @unknown default:
            assert(false, "new value")
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
        }
    }

    public static func getMesssageCardSummary(_ content: CardContent, lynxcardRenderFG: Bool) -> String? {
        guard content.jsonBody != nil,
              let hasSummary = content.jsonAttachment?.hasSummary,
              let items = content.jsonAttachment?.summary.items,
              hasSummary, lynxcardRenderFG else {
            return nil
        }
        var result = ""
        for item in items {
            switch item.entry {
            case .text(let textStr):
                result += textStr
            case .atUser(let atProperty):
                result += "@" + atProperty.content
            case .emotion(let emotionStr):
                result += emotionStr.key
            case .image(_):
                result += BundleI18n.LarkMessageCore.Lark_Legacy_ImageSummarize
            @unknown default:
                break
            }
        }
        if result.isEmpty {
            return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard
        }
        return BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard + " " + result
    }
}
