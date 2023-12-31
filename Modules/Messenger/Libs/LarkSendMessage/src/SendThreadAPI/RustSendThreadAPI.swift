//
//  RustSendThreadAPI.swift
//  LarkSDK
//
//  Created by zc09v on 2019/2/27.
//

import Foundation
import RustPB // Basic_V1_RichText
import LKCommonsLogging // Logger
import RxCocoa // Driver
import RxSwift // ImmediateSchedulerType
import LarkSDKInterface // ThreadMessage
import LarkContainer // InjectedLazy

/// send post to type
public enum SendThreadToType {
    /// to thread chat
    case threadChat
}

public protocol SendThreadAPI {
    typealias PreprocessingHandler = (_ thread: ThreadMessage?, _ sender: @escaping (_ preprocessCost: TimeInterval?) -> Void) -> Void
    var statusDriver: Driver<(ThreadMessage, Error?)> { get }

    /// 发送带视频的帖子需要分两步，第一步创建假消息，然后压缩， 第二步是发送
    /// - Parameter threadType: SendThreadToType.
    /// - Parameter title: String
    /// - Parameter content: RustPB.Basic_V1_RichText
    /// - Parameter chatId: String
    /// - Parameter isGroupAnnouncement: Bool
    /// - Parameter preprocessingHandler: PreprocessingHandler?
    func sendPost(
        context: APIContext?,
        to threadType: SendThreadToType,
        title: String,
        content: RustPB.Basic_V1_RichText,
        chatId: String,
        isGroupAnnouncement: Bool,
        preprocessingHandler: PreprocessingHandler?)
    func sendPost(
        context: APIContext?,
        to threadType: SendThreadToType,
        title: String,
        content: RustPB.Basic_V1_RichText,
        lingoInfo: RustPB.Basic_V1_LingoOption?,
        chatId: String,
        isGroupAnnouncement: Bool,
        preprocessingHandler: PreprocessingHandler?)

    func resend(thread: ThreadMessage, to threadType: SendThreadToType)

    func dealPush(thread: ThreadMessage, sendThreadType: SendThreadToType) -> Bool

    // 单测工程中使用，CI中单测包是DEBUG环境
    #if ALPHA
    func sendError(value: (ThreadMessage, SendThreadToType, Error?))
    func addSendingCids(cid: String)
    func dealSending(thread: ThreadMessage, sendThreadType: SendThreadToType)
    #endif
}

/// 话题群发帖
final class RustSendThreadAPI: SendThreadAPI, UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(RustSendThreadAPI.self, category: "RustSendThreadAPI")
    private let client: SDKRustService
    private let scheduler: ImmediateSchedulerType
    /// 状态变更通知
    private var statusPubSub = PublishSubject<(ThreadMessage, SendThreadToType, Error?)>()
    /// 发送消息状态监听
    var statusDriver: Driver<(ThreadMessage, Error?)> {
        return self.statusPubSub.map({ (statusInfo) -> (ThreadMessage, Error?) in
            return (statusInfo.0, statusInfo.2)
        }).asDriver { _ in
            return Driver<(ThreadMessage, Error?)>.empty()
        }
    }
    private let queue = DispatchQueue(label: "RustSendThreadAPI", qos: .utility)
    private let sendLock = NSLock()
    private let resendLock = NSLock()
    // 正在发送的消息
    private var _sendingCids: Set<String> = Set<String>()
    private var sendingCids: Set<String> {
        get {
            sendLock.lock()
            defer { sendLock.unlock() }
            return _sendingCids
        }
        set {
            sendLock.lock()
            defer { sendLock.unlock() }
            _sendingCids = newValue
        }
    }
    // 重发的消息
    private var _resendingCids: Set<String> = Set<String>()
    private var resendingCids: Set<String> {
        get {
            resendLock.lock()
            defer { resendLock.unlock() }
            return _resendingCids
        }
        set {
            resendLock.lock()
            defer { resendLock.unlock() }
            _resendingCids = newValue
        }
    }
    private var disposeBag = DisposeBag()
    private let pushCenter: PushNotificationCenter
    private let chatAPI: ChatAPI
    private let dependency: RustSendThreadAPIDependency

    private var sendingManager: SendingMessageManager

    init(userResolver: UserResolver,
         chatAPI: ChatAPI,
         pushCenter: PushNotificationCenter,
         client: SDKRustService,
         onScheduler: ImmediateSchedulerType,
         dependency: RustSendThreadAPIDependency) throws {
        self.userResolver = userResolver
        self.sendingManager = try userResolver.resolve(assert: SendingMessageManager.self)
        self.chatAPI = chatAPI
        self.pushCenter = pushCenter
        self.dependency = dependency
        self.client = client
        self.scheduler = onScheduler
        self.statusPubSub
            .subscribe(onNext: { [weak self] (thread, sendThreadType, _) in
                switch sendThreadType {
                case .threadChat:
                    self?.pushCenter.post(PushThreadMessages(messages: [thread]))
                }
                LarkSendMessageTracker.trackEndSendMessage(message: thread.rootMessage)
            }).disposed(by: disposeBag)
    }

    func sendPost(
        context: APIContext?,
        to threadType: SendThreadToType,
        title: String,
        content: RustPB.Basic_V1_RichText,
        chatId: String,
        isGroupAnnouncement: Bool,
        preprocessingHandler: PreprocessingHandler?) {
            self.sendPost(context: context,
                          to: threadType,
                          title: title,
                          content: content,
                          lingoInfo: nil,
                          chatId: chatId,
                          isGroupAnnouncement: isGroupAnnouncement,
                          preprocessingHandler: preprocessingHandler)
        }

    func sendPost(
        context: APIContext?,
        to threadType: SendThreadToType,
        title: String,
        content: RustPB.Basic_V1_RichText,
        lingoInfo: RustPB.Basic_V1_LingoOption?,
        chatId: String,
        isGroupAnnouncement: Bool,
        preprocessingHandler: PreprocessingHandler?) {
        queue.async {
            var quasiContent = QuasiContent()
            quasiContent.richText = content
            quasiContent.title = title
            quasiContent.isGroupAnnouncement = isGroupAnnouncement
            quasiContent.lingoOption = lingoInfo ?? RustPB.Basic_V1_LingoOption()
            guard let thread = try? RustSendMessageModule.createQuasiThreadMessage(
                to: threadType,
                chatId: chatId,
                type: .post,
                content: quasiContent,
                client: self.client,
                context: context
                ) else { return }

            if let handler = preprocessingHandler {
                self.dealSending(thread: thread, sendThreadType: threadType)
                handler(thread) { [weak self] _ in
                    self?.sendMessage(context: context, thread: thread, sendThreadType: threadType)
                }
            } else {
                self.sendMessage(context: context, thread: thread, sendThreadType: threadType)
                self.dealSending(thread: thread, sendThreadType: threadType)
            }
        }
    }

    func resend(thread: ThreadMessage, to threadType: SendThreadToType) {
        var thread = thread
        let cid = thread.cid
        thread.rootMessage.localStatus = .process
        resendingCids.insert(cid)
        sendingManager.add(task: cid)
        statusPubSub.onNext((thread, threadType, nil))
        RustSendMessageModule
            .resendMessage(cid: cid, client: client, context: nil)
            .subscribe(onError: { [weak self] (error) in
                thread.localStatus = .fail
                self?.sendError(value: (thread, threadType, error))
                RustSendThreadAPI.logger.error("消息重发失败", additionalData: ["Cid": cid], error: error)
            })
            .disposed(by: disposeBag)
    }

    func dealPush(thread: ThreadMessage, sendThreadType: SendThreadToType) -> Bool {
        let key = thread.cid
        if resendingCids.contains(key) {
            statusPubSub.onNext((thread, sendThreadType, nil))
            resendingCids.remove(key)
            sendingManager.remove(task: key)
            return true
        }
        if sendingCids.contains(key) {
            statusPubSub.onNext((thread, sendThreadType, nil))
            sendingCids.remove(key)
            sendingManager.remove(task: key)
            return true
        }
        return false
    }

    func sendError(value: (ThreadMessage, SendThreadToType, Error?)) {
        // TODO: 修改Thread发送失败的逻辑,下掉这里的特化
        // DLP对于发消息失败时的临时特化逻辑, 防止quasiMessage的字段被端上创建的假消息覆盖
        if let error = value.2?.underlyingError as? APIError {
            if error.code == 311_120 {
                Self.logger.info("ErrorCode:<\(error.code)>, Messageid:<\(value.0.id)>, send no threadMessage with error.")
                return
            }
        }
        self.statusPubSub.onNext(value)
    }

    func addSendingCids(cid: String) {
        self.sendingCids.insert(cid)
    }

    private func sendMessage(context: APIContext?, thread: ThreadMessage, sendThreadType: SendThreadToType) {
        var thread = thread
        let cid = thread.cid
        sendingCids.insert(cid)
        sendingManager.add(task: cid)
        RustSendMessageModule
            .sendMessage(cid: cid, client: client, context: context)
            .subscribeOn(scheduler)
            .subscribe(onError: { [weak self] (error) in
                guard let `self` = self else { return }
                thread.localStatus = .fail
                self.sendError(value: (thread, sendThreadType, error))
                RustSendThreadAPI.logger.error("消息发送失败", additionalData: ["MsgCid": cid], error: error)
            })
            .disposed(by: disposeBag)
    }

    func dealSending(thread: ThreadMessage, sendThreadType: SendThreadToType) {
        self.statusPubSub.onNext((thread, sendThreadType, nil))
        DispatchQueue.global().async {
            if let chat = (try? self.chatAPI.getLocalChats([thread.channel.id]))?.first?.value {
                LarkSendMessageTracker.trackSendMessage(thread.rootMessage,
                                                        chat: chat,
                                                        messageSummerize: self.dependency.messageSummerize,
                                                        isSupportURLType: self.dependency.isSupportURLType,
                                                        chatFromWhere: nil)
                self.dependency.trackClickMsgSend(chat, thread.rootMessage, chatFromWhere: nil)
            }
        }
    }
}
