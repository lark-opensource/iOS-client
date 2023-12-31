//
//  Reply.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/1/10.
//

import Foundation
import Homeric
import LarkModel
import LarkMessageBase
import LKCommonsTracker
import LarkCore
import LarkOpenChat
import LarkReleaseConfig
import LarkSetting
import LarkAccountInterface
import LarkContainer
import LarkMessengerInterface
import LKCommonsLogging

public class ReplyMessageActionSubModule: MessageActionSubModule {
    static let logger = Logger.log(ReplyMessageActionSubModule.self, category: "ReplyMessageActionSubModule")

    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy private var abTestService: MenuInteractionABTestService?

    public override var type: MessageActionType {
        return .reply
    }

    func abTestTitleForChat(_ chat: Chat?) -> String? {
        return abTestService?.replyMenuTitle(chat: chat)
    }

    func abTestIconForChat(_ chat: Chat?) -> UIImage? {
        return abTestService?.replyMenuIcon(chat: chat)
    }

    public override static func canInitialize(context: MessageActionContext) -> Bool {
        return true
    }

    func supportPartialSelectFor(model: MessageActionMetaModel) -> Bool {
        return false
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if model.isInPartialSelect, !supportPartialSelectFor(model: model) {
            return false
        }
        switch model.message.type {
        case .text, .post, .audio, .image, .sticker, .media, .file, .folder, .mergeForward,
            .card, .location, .todo, .shareGroupChat, .shareUserCard, .shareCalendarEvent, .hongbao, .videoChat, .commercializedHongbao, .vote:
            return true
        case .unknown, .system, .email, .calendar, .diagnose:
            return false
        case .generalCalendar:
            switch model.message.content {
            case is GeneralCalendarEventRSVPContent,
                is RoundRobinCardContent,
                is SchedulerAppointmentCardContent:
                return true
            default:
                return false
            }
        }
    }

    private func handle(message: Message,
                        chat: Chat,
                        copyType: CopyMessageType,
                        selectedType: CopyMessageSelectedType) {
        guard let pageAPI = try? self.context.userResolver.resolve(assert: ChatMessagesOpenService.self).pageAPI else { return }
        if message.type == .hongbao || message.type == .commercializedHongbao {
            Tracker.post(TeaEvent(Homeric.MOBILE_HONGBAO_REPLY))
        }
        var replyInfo: PartialReplyInfo?
        if case .richView(let callback) = selectedType,
           let (attr, position) = callback(),
           position != .all {

            if attr.string.isEmpty {
                Self.logger.info("ReplyMessageActionSubModule richView Partial attr isEmpty")
                return
            }

            replyInfo = PartialReplyInfo()
            replyInfo?.content = RichViewAttributedStringConverter.richTextFor(attr: attr, copyMessage: message)
            Self.logger.info("ReplyMessageActionSubModule richView Partial \(attr.length) -- \(position)")
            switch position {
            case .all:
                break
            case .head:
                replyInfo?.position = .head
            case .middle:
                replyInfo?.position = .middle
            case .tail:
                replyInfo?.position = .tail
            default:
                break
            }
        } else {
            if case .richView(let callback) = selectedType {
                Self.logger.info("ReplyMessageActionSubModule richView all \(callback()?.0.length) -- \(callback()?.1)")
            }
        }
        pageAPI.reply(message: message, partialReplyInfo: replyInfo)
    }

    public override func createActionItem(model: MessageActionMetaModel) -> MessageActionItem? {
        let text = abTestTitleForChat(model.chat) ?? BundleI18n.LarkMessageCore.Lark_Legacy_Reply
        let icon = abTestIconForChat(model.chat) ?? (ReleaseConfig.isLark ?
                             BundleResources.Menu.menu_reply :
                             BundleResources.Menu.menu_reply_feishu)

        return MessageActionItem(text: text,
                                 icon: icon,
                                 enable: !(model.chat.displayInThreadMode && !model.message.displayInThreadMode),
                                 trackExtraParams: getTrackExtraParams(chat: model.chat)) { [weak self] in
            self?.handle(message: model.message,
                         chat: model.chat,
                         copyType: model.copyType, selectedType: model.selected())
        }
    }

    private func getTrackExtraParams(chat: Chat) -> [AnyHashable: Any] {
        if chat.isCrypto {
            return ["click": "reply", "target": "none"]
        }
        guard let abTestService = abTestService else {
            return [:]
        }
        switch abTestService.abTestResult {
        case .radical:
            return ["click": "quote", "target": "none", "ab_version": 2]
        case .gentle:
            return ["click": "quote", "target": "none", "ab_version": 1]
        case .none:
            return ["click": "reply", "target": "none", "ab_version": 0]
        }
    }
}

public final class ChatReplyMessageActionSubModule: ReplyMessageActionSubModule {

    override func supportPartialSelectFor(model: MessageActionMetaModel) -> Bool {
        guard !model.chat.isCrypto, !model.chat.isPrivateMode else {
            return false
        }
        var support = true
        switch model.copyType {
        case .message, .origin:
            support = true
        default:
            support = false
        }
        if support, model.message.type == .post || model.message.type == .text {
            return true
        }
        return false
    }

    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if !model.chat.isAllowPost {
            return false
        }
        guard model.message.threadMessageType == .unknownThreadMessage else {
            return false
        }
        return super.canHandle(model: model)
    }
}

public final class ThreadReplyMessageActionSubModule: ReplyMessageActionSubModule {
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if self.context.userResolver.userID == model.message.fromId {
            return false
        }
        return super.canHandle(model: model)
    }
    override func abTestIconForChat(_ chat: Chat?) -> UIImage? {
        return nil
    }
    override func abTestTitleForChat(_ chat: Chat?) -> String? {
        return nil
    }
}

public final class ReplyMessageActionSubModuleInReplyInThread: ReplyMessageActionSubModule {
    public override func canHandle(model: MessageActionMetaModel) -> Bool {
        if self.context.userResolver.userID == model.message.fromId {
            return false
        }
        if !model.chat.isAllowPost {
            return false
        }
        return super.canHandle(model: model)
    }

    override func abTestIconForChat(_ chat: Chat?) -> UIImage? {
        return nil
    }
    override func abTestTitleForChat(_ chat: Chat?) -> String? {
        return nil
    }
}
