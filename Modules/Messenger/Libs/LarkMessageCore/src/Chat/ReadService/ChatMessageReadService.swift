//
//  ChatMessageReadService.swift
//  LarkChat
//
//  Created by KT on 2019/7/1.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkModel
import LarkSetting
import LarkMessengerInterface
import LarkCore
import LarkContainer
import LarkSDKInterface
import LKCommonsLogging

public protocol ChatMessageReadService {
    func set(enable: Bool)
    func putRead(element: PutReadElement, urgentConfirmed: ((Int32) -> Void)?)
}

public struct PutReadInfo {
    /// [(ChatID, MessageID)]
    public let ids: [(chatID: String, messageID: String)]
    public let maxPosition: Int32
    public let maxBadgeCount: Int32
    public let foldIds: [Int64]
}

public enum PutReadScene: CustomStringConvertible {
    case chat(Chat)
    case thread(Chat)
    case messageDetail(Chat)
    case replyInThread(Chat)

    public var description: String {
        switch self {
        case .chat(let chat):
            return "chat_" + chat.id
        case .thread(let chat):
            return "thread_" + chat.id
        case .replyInThread(let chat):
            return "replyInThread_" + chat.id
        case .messageDetail(let chat):
            return "messageDetail_" + chat.id
        }
    }
}

public protocol PutReadElement {
    var chatID: String { get }
    var id: String { get }
    var cid: String { get }
    var foldId: Int64 { get }
    var isIntermediate: Bool { get }
    var type: Message.TypeEnum { get }
    var content: MessageContent { get }
    var isUrgent: Bool { get }
    var trackContext: [String: Any] { get }
    func meRead(scene: PutReadScene, currentReadPosition: Int32) -> Bool
    func position(_ scene: PutReadScene) -> Int32
    func badgeCount(_ scene: PutReadScene) -> Int32
}

struct WaitPutReadElement {
    let chatId: String
    let id: String
    let cid: String
    let foldId: Int64
    let type: Message.TypeEnum
    /// 是否依赖已读服务发送已读
    let putReadByService: Bool
    /// 卡片自定义analytics信息，用来判断是否是活动红包
    let cardAnalytics: String
    let trackContext: [String: Any]
}

public final class ChatMessageReadServiceImpl: NSObject, ChatMessageReadService {
    static let logger = Logger.log(ChatMessageReadServiceImpl.self, category: "ChatMessageReadService")
    private var enable: Bool
    // 因为enable有可能中间会改变状态，所以引入forceDisable，让其不可更改
    private let forceDisable: Bool
    private var waitPutReadElements: [WaitPutReadElement] = []
    private let audioShowTextEnable: Bool
    private var maxPositionAndBadgeCount: (position: Int32, badgeCount: Int32) = (position: -1, badgeCount: -1)
    private let currentReadPosition: () -> Int32
    private let putReadAction: (PutReadInfo) -> Void
    private let scene: PutReadScene
    /// 避免创建很多线程，串行执行高频操作
    private let serialOperationQueue: OperationQueue
    private let urgencyCenter: UrgencyCenter
    private var urgentConfirmCache: [(id: String, position: Int32)] = []
    /// 判断「不通过已读服务发送已读」的 element 是否插入到 waitPutReadElements 数组里
    private let supportPutReadV2: Bool
    /// 埋点字段
    private let isRemind: Bool
    private let isInBox: Bool
    private var debouncer: Debouncer = Debouncer()
    private let trackContext: [String: Any]
    public init(scene: PutReadScene,
                forceDisable: Bool = false,
                audioShowTextEnable: Bool,
                isRemind: Bool,
                isInBox: Bool,
                trackContext: [String: Any],
                currentReadPosition: @escaping () -> Int32,
                putReadAction: @escaping (PutReadInfo) -> Void,
                urgencyCenter: UrgencyCenter,
                supportPutReadV2: Bool) {
        self.currentReadPosition = currentReadPosition
        self.putReadAction = putReadAction
        self.audioShowTextEnable = audioShowTextEnable
        self.scene = scene
        self.enable = !forceDisable
        self.forceDisable = forceDisable
        self.serialOperationQueue = OperationQueue()
        self.serialOperationQueue.qualityOfService = .background
        self.serialOperationQueue.maxConcurrentOperationCount = 1
        self.isRemind = isRemind
        self.isInBox = isInBox
        self.trackContext = trackContext
        self.urgencyCenter = urgencyCenter
        self.supportPutReadV2 = supportPutReadV2
    }

    deinit {
        Self.logger.info("ChatMessageReadServiceImpl deinit \(self.scene) \(self.supportPutReadV2)")
    }

    public func set(enable: Bool) {
        if forceDisable {
            return
        }
        self.enable = enable
    }

    public func putRead(element: PutReadElement, urgentConfirmed: ((Int32) -> Void)?) {
        // 后台不发送已读
        guard enable, UIApplication.shared.applicationState != .background else { return }

        if self.supportPutReadV2 {
            self.putReadV2(element: element, urgentConfirmed: urgentConfirmed)
            return
        }

        let isMeRead = element.meRead(scene: scene, currentReadPosition: currentReadPosition())
        // need chcek intermediate state. if isIntermediate = true not put read
        if !isMeRead,
            !element.isIntermediate,
            !waitPutReadElements.contains(where: { (waitElement) -> Bool in
                return waitElement.id == element.id
            }) {
            //语音不通过已读服务发送已读，但也要入waitPutReadElements数组，后续要判断是否此次是否有未读消息
            var putReadByService = true
            // 卡片自定义analytics信息
            var cardAnalytics: String = ""
            if element.type == .audio {
                // 语音消息且没有显示出识别文字的话，不标记为已读
                if let content = element.content as? AudioContent,
                    (content.showVoiceText.isEmpty ||
                        !self.audioShowTextEnable) {
                    putReadByService = false
                }
            } else if element.type == .card {
                cardAnalytics = (element.content as? CardContent)?.extraInfo.customConfig.analyticsData ?? ""
            }
            self.waitPutReadElements.append(WaitPutReadElement(chatId: element.chatID,
                                                               id: element.id,
                                                               cid: element.cid,
                                                               foldId: element.foldId,
                                                               type: element.type,
                                                               putReadByService: putReadByService,
                                                               cardAnalytics: cardAnalytics,
                                                               trackContext: element.trackContext))
        }
        if element.position(scene) > self.maxPositionAndBadgeCount.position {
            self.maxPositionAndBadgeCount = (position: element.position(scene), badgeCount: element.badgeCount(scene))
        }
        if urgentConfirmed != nil, element.isUrgent, !self.urgentConfirmCache.contains(where: { return $0.id == element.id }) {
            self.urgentConfirmCache.append((id: element.id, position: element.position(scene)))
        }

        debouncer.debounce(indentify: "putRead", duration: 0.3) { [weak self] in
            self?.putReads(urgentConfirmed)
        }
    }

    private func putReadV2(element: PutReadElement, urgentConfirmed: ((Int32) -> Void)?) {
        let isMeRead = element.meRead(scene: scene, currentReadPosition: currentReadPosition())
        // need chcek intermediate state. if isIntermediate = true not put read
        if !isMeRead,
            !element.isIntermediate,
            !waitPutReadElements.contains(where: { (waitElement) -> Bool in
                return waitElement.id == element.id
            }),
            checkPutReadByService(element) {
            // 卡片自定义analytics信息
            var cardAnalytics: String = ""
            if element.type == .card {
                cardAnalytics = (element.content as? CardContent)?.extraInfo.customConfig.analyticsData ?? ""
            }
            self.waitPutReadElements.append(WaitPutReadElement(chatId: element.chatID,
                                                               id: element.id,
                                                               cid: element.cid,
                                                               foldId: element.foldId,
                                                               type: element.type,
                                                               putReadByService: true,
                                                               cardAnalytics: cardAnalytics,
                                                               trackContext: element.trackContext))
        }
        if element.position(scene) > self.maxPositionAndBadgeCount.position {
            self.maxPositionAndBadgeCount = (position: element.position(scene), badgeCount: element.badgeCount(scene))
        }
        if urgentConfirmed != nil, element.isUrgent, !self.urgentConfirmCache.contains(where: { return $0.id == element.id }) {
            self.urgentConfirmCache.append((id: element.id, position: element.position(scene)))
        }

        debouncer.debounce(indentify: "putRead", duration: 0.3) { [weak self] in
            self?.putReads(urgentConfirmed)
        }
    }

    private func checkPutReadByService(_ element: PutReadElement) -> Bool {
        if element.type == .audio, let content = element.content as? AudioContent {
            if content.showVoiceText.isEmpty || !self.audioShowTextEnable {
                //语音不通过已读服务发送已读
                return false
            }
        }
        return true
    }

    @objc
    private func putReads(_ urgentConfirmed: ((Int32) -> Void)?) {
        if let urgentConfirmed = urgentConfirmed {
            self.urgentConfirmCache.forEach { (messageId, position) in
                self.urgencyCenter.confirmUrgency(messageId: messageId, urgentConfirmSuccess: {
                    urgentConfirmed(position)
                })
            }
            self.urgentConfirmCache = []
        }

        let readPositionChange = self.maxPositionAndBadgeCount.position > self.currentReadPosition()
        let hasUnreadElements = !waitPutReadElements.isEmpty
        // 未读变化或有没发送未读的消息
        guard readPositionChange || hasUnreadElements else { return }
        var foldIds: [Int64] = []
        let elementIds = waitPutReadElements.filter { (element) -> Bool in
            if element.putReadByService {
                if let chat = trackContext["chat"] as? Chat {
                    IMTracker.Chat.Main.Click.MsgRead(chat, element.id, element.cid, IMTracker.Base.messageType(element.type), trackContext["chatFromWhere"] as? String)
                }
                ChatMessageReadServiceTracker.trackReadMessage(chat: trackContext["chat"] as? Chat,
                                                               chatId: element.chatId,
                                                               messageId: element.id,
                                                               messageType: element.type,
                                                               isMute: !self.isRemind,
                                                               isInBox: self.isInBox,
                                                               trackContext: element.trackContext)
                // 已读活动红包需额外打点
                self.serialOperationQueue.addOperation {
                    ChatMessageReadServiceTracker.trackCardAanalyticsIfNeed(analytics: element.cardAnalytics)
                }
            }
            return element.putReadByService
        }.map { (element) -> (String, String) in
            /// 需要过滤掉 foldId == 0 的无效case
            if element.foldId > 0 {
                foldIds.append(element.foldId)
            }
            return (element.chatId, element.id)
        }
        self.putReadAction(PutReadInfo(ids: elementIds,
                                       maxPosition: maxPositionAndBadgeCount.position,
                                       maxBadgeCount: maxPositionAndBadgeCount.badgeCount,
                                       foldIds: foldIds))
        waitPutReadElements.removeAll()
        self.maxPositionAndBadgeCount = (position: -1, badgeCount: -1)
    }
}

extension Message: PutReadElement {
    public var trackContext: [String: Any] {
        return ["notice": trackAtType]
    }

    public func meRead(scene: PutReadScene, currentReadPosition: Int32) -> Bool {
        switch scene {
        case .chat(let chat), .messageDetail(let chat), .replyInThread(let chat):
            /// 聚合消息的话 默认未读
            if self.isFoldRootMessage, self.foldDetailInfo != nil {
                return false
            }
            //超大群不发已读，默认已读
            return chat.isSuper ? true : self.meRead
        default:
            return self.meRead
        }
    }

    public var chatID: String {
        return self.channel.id
    }

    public var isIntermediate: Bool {
        return self.isCryptoIntermediate
    }

    public func position(_ scene: PutReadScene) -> Int32 {
        switch scene {
        case .chat:
            if self.isFoldRootMessage, let foldDetailInfo = message?.foldDetailInfo {
                return foldDetailInfo.lastMessagePosition
            }
            return self.position
        case .thread, .replyInThread:
            return self.threadPosition
        case .messageDetail:
            return self.position
        }
    }

    public func badgeCount(_ scene: PutReadScene) -> Int32 {
        switch scene {
        case .chat:
            if self.isFoldRootMessage, let foldDetailInfo = message?.foldDetailInfo {
                return foldDetailInfo.lastMessageBadgeCount
            }
            return self.badgeCount
        case .thread, .replyInThread:
            return self.threadBadgeCount
        case .messageDetail:
            return self.badgeCount
        }
    }
}

extension ThreadMessage: PutReadElement {
    public var foldId: Int64 {
        return 0
    }

    public var trackContext: [String: Any] {
        return [:]
    }

    public var chatID: String {
        return self.rootMessage.channel.id
    }

    public var isIntermediate: Bool {
        return false
    }

    public func position(_ scene: PutReadScene) -> Int32 {
        return self.thread.position
    }

    public func badgeCount(_ scene: PutReadScene) -> Int32 {
        return self.thread.originBadgeCount
    }

    public func meRead(scene: PutReadScene, currentReadPosition: Int32) -> Bool {
        switch scene {
        case .thread(let chat):
            // 小组
            // 需要判断chatReadPostion已读位置，用于消badge && rootMessage已读 才是ThreadMessage已读。
            // SDK在处理thread已读时会处理message已读，更新badge。
            return chat.isSuper ? true : currentReadPosition >= self.thread.position && self.rootMessage.meRead
        default:
            return self.rootMessage.meRead
        }
    }

    public var type: Message.TypeEnum {
        return self.rootMessage.type
    }

    public var content: MessageContent {
        return self.rootMessage.content
    }

    public var isUrgent: Bool {
        return false
    }
}
