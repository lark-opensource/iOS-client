//
//  MessageViewModelHandler.swift
//  Action
//
//  Created by KT on 2019/6/3.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import TangramService
import LarkAccountInterface
import LarkSetting
import LarkContainer

public typealias NameProvider = (Chatter, Chat, GetChatterDisplayNameScene) -> String

public final class MessageViewModelHandler {
    /// 获取指定消息的描述,主要用于回复(NewChat用到这部分逻辑)
    /// text消息😊上屏后在回复区以😊存在，post消息😊上屏后在回复区以[微笑]存在，和pm确认过，先保持现状，后续会统一
    /// text消息支持docsUrl转icon+title，post不支持
    /// - Parameter message: message
    /// - Returns: NSAttributedString
    public static func getReplyMessageSummerize(
        _ message: Message?,
        chat: Chat,
        textColor: UIColor,
        nameProvider: @escaping NameProvider,
        needFromName: Bool = true,
        isBurned: Bool,
        partialReplyInfo: PartialReplyInfo? = nil,
        userResolver: UserResolver,
        urlPreviewProvider: LarkCoreUtils.URLPreviewProvider? = nil) -> NSAttributedString {
            guard let message = message else {
                return NSAttributedString(string: "")
            }
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            let textFont = UIFont.ud.body2
            let attribute: [NSAttributedString.Key: Any] = [
                .foregroundColor: textColor,
                .font: textFont,
                .paragraphStyle: paragraphStyle
            ]
            var appendPartialReply = false
            /// attributeText内容前添加名字
            func addNameAttriubuteString(attributeText: NSAttributedString) -> NSAttributedString {
                guard needFromName, let fromChatter = message.fromChatter else { return attributeText }
                let nameInfo: String
                if partialReplyInfo != nil, appendPartialReply {
                    nameInfo = "\(nameProvider(fromChatter, chat, .reply)): "
                } else if message.displayRule == .onlyTranslation, message.translateContent != nil {
                    nameInfo = "\(nameProvider(fromChatter, chat, .reply)): \(BundleI18n.LarkMessageCore.Lark_Legacy_TranslateInChat)"
                } else if chat.isCrypto, chat.type == .p2P, fromChatter.id != userResolver.userID {
                    nameInfo = "\(BundleI18n.LarkMessageCore.Lark_IM_SecureChatUser_Title): "
                } else {
                    nameInfo = "\(nameProvider(fromChatter, chat, .reply)): "
                }
                var mutableAttributedString = NSMutableAttributedString(attributedString: attributeText)
                mutableAttributedString.insert(NSAttributedString(string: nameInfo, attributes: attribute), at: 0)
                if let partialReplyInfo = partialReplyInfo, appendPartialReply {
                    mutableAttributedString = TextPostPartialReplyGenerator.insertLinkDefalutIconIfNeedFor(attr: mutableAttributedString, font: textFont, color: textColor)
                    mutableAttributedString = TextPostPartialReplyGenerator.partialReplyForPosition(partialReplyInfo.position,
                                                                                                    headInsertIdx: nameInfo.utf16.count,
                                                                                                    muAttr: mutableAttributedString, textAttribute: attribute)
                }
                return mutableAttributedString
            }
            var recallerName = ""
            if let recaller = message.recaller {
                recallerName = nameProvider(recaller, chat, .reply)
            }
            let groupownerName = "@\(recallerName)"
            var messageInfo = ""
            if message.isDeleted {
                messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageAlreadyDeleted
            } else if message.isRecalled {
                if !message.recallerId.isEmpty {
                    switch message.recallerIdentity {
                    case .unknownIdentity:
                        messageInfo = String(
                            format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecalledByGroupOwner,
                            arguments: [BundleI18n.LarkMessageCore.Lark_Legacy_GroupOwnerTag, groupownerName]
                        )
                    case .owner:
                        messageInfo = String(
                            format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecalledByGroupOwner,
                            arguments: [BundleI18n.LarkMessageCore.Lark_Legacy_GroupOwnerTag, groupownerName]
                        )
                    case .administrator:
                        messageInfo = String(
                            format: BundleI18n.LarkMessageCore.Lark_Legacy_MessageRecalledByGroupOwner,
                            arguments: [BundleI18n.LarkMessageCore.Lark_Legacy_Administrator, groupownerName]
                        )
                    case .groupAdmin:
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_GroupAdminRecalledMsg(groupownerName)
                    case .enterpriseAdministrator:
                        break
                    @unknown default:
                        assert(false, "new value")
                        break
                    }
                } else if message.recallerId.isEmpty, case .enterpriseAdministrator = message.recallerIdentity {
                    messageInfo = BundleI18n.LarkMessageCore.Lark_IM_MessageRecalledByAdmin_Text
                } else {
                    messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageIsrecalled
                }
            } else if isBurned {
                messageInfo = message.isOnTimeDel ? BundleI18n.LarkMessageCore.Lark_IM_MsgDeleted_Desc : BundleI18n.LarkMessageCore.Lark_Legacy_MessageIsburned
            } else if message.isSecretChatDecryptedFailed {
                messageInfo = BundleI18n.LarkMessageCore.Lark_IM_SecureChat_UnableLoadMessage_Text
            } else {
                appendPartialReply = true
                switch message.type {
                case .text:
                    let textContent: TextContent
                    /// 只展示译文时展示译文，其他情况展示原文
                    if message.displayRule == .onlyTranslation, message.translateContent != nil {
                        guard let content = message.translateContent as? TextContent else {
                            return NSAttributedString(string: "")
                        }
                        textContent = content
                    } else {
                        guard let content = message.content as? TextContent else {
                            return NSAttributedString(string: "")
                        }
                        textContent = content
                    }
                    let textDocsVM = TextDocsViewModel(userResolver: userResolver,
                                                       richText: partialReplyInfo?.content ?? textContent.richText,
                                                       docEntity: textContent.docEntity,
                                                       hangPoint: message.urlPreviewHangPointMap)
                    let customAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: textColor,
                                                                           .font: textFont,
                                                                           MessageInlineViewModel.iconColorKey: textColor,
                                                                           MessageInlineViewModel.tagTypeKey: TagType.normal]
                    let parseRichText = textDocsVM.parseRichText(
                        checkIsMe: nil,
                        needNewLine: false,
                        iconColor: textColor,
                        customAttributes: customAttributes,
                        urlPreviewProvider: { elementID, _ in
                            return urlPreviewProvider?(elementID, customAttributes)
                        }
                    )
                    let attriubuteText = parseRichText.attriubuteText
                    attriubuteText.addAttributes(attribute, range: NSRange(location: 0, length: attriubuteText.length))
                    return addNameAttriubuteString(attributeText: attriubuteText)
                case .post:
                    appendPartialReply = true
                    let postContent: PostContent
                    /// 只展示译文时展示译文，其他情况展示原文
                    if message.displayRule == .onlyTranslation, message.translateContent != nil {
                        guard let content = message.translateContent as? PostContent else {
                            return NSAttributedString(string: "")
                        }
                        postContent = content
                    } else {
                        guard let content = message.content as? PostContent else {
                            return NSAttributedString(string: "")
                        }
                        postContent = content
                    }
                    // 无标题帖子展示内容
                    if postContent.isUntitledPost || partialReplyInfo != nil {
                        let richText = partialReplyInfo?.content ?? postContent.richText
                        let fixRichText = richText.lc.convertText(tags: [.img, .media])
                        let textDocsVM = TextDocsViewModel(userResolver: userResolver,
                                                           richText: fixRichText, docEntity: postContent.docEntity,
                                                           hangPoint: message.urlPreviewHangPointMap)
                        let customAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: textColor,
                                                                               .font: textFont,
                                                                               MessageInlineViewModel.iconColorKey: textColor,
                                                                               MessageInlineViewModel.tagTypeKey: TagType.normal]
                        let parseRichText = textDocsVM.parseRichText(
                            checkIsMe: nil,
                            needNewLine: false,
                            iconColor: textColor,
                            customAttributes: customAttributes,
                            urlPreviewProvider: urlPreviewProvider
                        )
                        let attriubuteText = parseRichText.attriubuteText
                        attriubuteText.addAttributes(attribute, range: NSRange(location: 0, length: attriubuteText.length))
                        return addNameAttriubuteString(attributeText: attriubuteText)
                    }
                    messageInfo = postContent.title
                case .file:
                    if let content = message.content as? FileContent {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_FileHolder + " " + content.name
                    } else {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_FileHolder
                    }
                case .folder:
                    if let content = message.content as? FolderContent {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_FileHolder + " " + content.name
                    } else {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_FileHolder
                    }
                case .audio:
                    messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MsgFormatAudio
                case .calendar:
                    messageInfo = BundleI18n.LarkMessageCore.Lark_Pin_Calendar
                case .generalCalendar:
                    if let content = message.content as? CalendarBotContent {
                        if !content.summary.isEmpty {
                            messageInfo = BundleI18n.LarkMessageCore.Calendar_Detail_ReplyRSVPTitle(content.summary)
                        } else {
                            messageInfo = BundleI18n.LarkMessageCore.Calendar_Push_EventNoName
                        }
                    } else if let content = message.content as? RoundRobinCardContent {
                        if content.status == .statusActive {
                            messageInfo = BundleI18n.LarkMessageCore.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
                        } else {
                            messageInfo = BundleI18n.LarkMessageCore.Calendar_Scheduling_EventNoAvailable_Bot
                        }
                    } else if let content = message.content as? SchedulerAppointmentCardContent {
                        if content.status == .statusActive {
                            if content.action == .actionReschedule {
                                messageInfo = BundleI18n.LarkMessageCore.Calendar_Scheduling_HostRescheduledByInvitee(invitee: content.guestName, host: content.hostName)
                            } else if content.action == .actionCancel {
                                messageInfo = BundleI18n.LarkMessageCore.Calendar_Scheduling_HostCanceledByInvitee(invitee: content.altOperatorName, host: content.hostName)
                            } else {
                                messageInfo = BundleI18n.LarkMessageCore.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
                            }
                        } else {
                            messageInfo = BundleI18n.LarkMessageCore.Calendar_Scheduling_EventNoAvailable_Bot
                        }
                    } else {
                        if let content = message.content as? GeneralCalendarEventRSVPContent {
                            messageInfo = !content.title.isEmpty ? BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoShareEvent + " " + content.title :
                            BundleI18n.LarkMessageCore.Calendar_Push_EventNoName
                        } else {
                            messageInfo = BundleI18n.LarkMessageCore.Lark_Pin_Calendar
                        }
                    }

                case .image, .sticker:
                    messageInfo = ""
                case .location:
                    if let content = message.content as? LocationContent {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Chat_MessageReplyStatusLocation(content.location.name)
                    } else {
                        messageInfo = ""
                    }
                case .shareUserCard:
                    let content = message.content as? ShareUserCardContent
                    messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_PreviewUserCard(content?.chatter?.localizedName ?? "")
                case .mergeForward:
                    guard let content = message.content as? MergeForwardContent else {
                        return NSAttributedString(string: "")
                    }
                    if content.isFromPrivateTopic {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoMergeforward
                    } else {
                        messageInfo = content.title
                    }
                case .card:
                    guard let cardContent = message.content as? CardContent else {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageSummerizeCard
                        break
                    }
                    switch cardContent.type {
                    case .unknownType:
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_UnknownMessageTypeTip()
                    case .vote:
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageSummerizeCardVote
                    case .text:
                        var cardContent = cardContent
                        if message.displayRule == .onlyTranslation &&
                            TranslateControl.isTranslatableMessageCardType(message),
                           let cardTranslateContent = message.translateContent as? CardContent {
                            cardContent = cardTranslateContent
                        }
                        let lynxcardRenderFG = userResolver.fg.staticFeatureGatingValue(with: "lynxcard.client.render.enable")
                        if let summary = MessageSummarizeUtil.getMesssageCardSummary(cardContent, lynxcardRenderFG: lynxcardRenderFG) {
                            messageInfo = summary
                        } else {
                            messageInfo = !cardContent.header.title.isEmpty ?
                            cardContent.header.title :
                            cardContent.richText.lc.summerize()
                        }
                    case .openCard:
                        if !cardContent.header.title.isEmpty {
                            messageInfo = cardContent.header.title
                        } else {
                            messageInfo = cardContent.richText.lc.summerize()
                        }
                        if messageInfo.isEmpty {
                            messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoCard
                        }
                    case .vchat:
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_VchatCardContentHolder
                    @unknown default:
                        assert(false, "new value")
                        break
                    }
                case .shareGroupChat:
                    if let content = message.content as? ShareGroupChatContent {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_ShareGroupHolder + " " + (content.chat?.displayName ?? "")
                    } else {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessagePoSystemError
                    }
                case .email, .system, .unknown:
                    messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_UnknownMessageTypeTip()
                case .media:
                    messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MediaHolder
                case .todo:
                    messageInfo = BundleI18n.LarkMessageCore.Todo_Task_MsgTypeTask
                case .hongbao, .commercializedHongbao:
                    messageInfo = ""
                case .videoChat:
                    if let content = message.content as? VChatMeetingCardContent {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_View_VideoMeetingInviteLabel + " " + content.topic
                    } else {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_View_VideoMeetingInviteLabel
                    }
                case .shareCalendarEvent:
                    if let content = message.content as? EventShareContent {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageSummerizeShareCalendar + " " + content.title
                    } else {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageSummerizeShareCalendar
                    }
                case .vote:
                    if let content = message.content as? VoteContent {
                        messageInfo = BundleI18n.LarkMessageCore.Lark_Legacy_MessageSummerizeCardVote
                    }
                case .diagnose:
                    assert(false, "new value")
                    break
                @unknown default:
                    assert(false, "new value")
                    break
                }
            }

            let attributeText = NSAttributedString(string: messageInfo, attributes: attribute)
            return addNameAttriubuteString(attributeText: attributeText)
        }
}
