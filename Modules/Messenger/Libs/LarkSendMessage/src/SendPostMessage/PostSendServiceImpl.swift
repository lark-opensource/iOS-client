//
//  PostSendServiceImpl.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/6/18.
//

import UIKit
import Foundation
import RxSwift // DisposeBag
import RxCocoa // Driver
import LarkModel // Message
import LKCommonsLogging // Logger
import LarkSDKInterface // ThreadMessage
import LarkFoundation // FileUtils
import RustPB // Basic_V1_RichText
import ThreadSafeDataStructure // SafeSet
import LarkContainer // InjectedLazy

public protocol PostSendService {
    var sendThreadStatusDriver: Driver<(ThreadMessage, Error?)> { get }

    // swiftlint:disable all
    func sendMessage(
        context: APIContext,
        title: String,
        content: RustPB.Basic_V1_RichText,
        lingoInfo: RustPB.Basic_V1_LingoOption?,
        parentMessage: Message?,
        chatId: String,
        threadId: String?,
        isGroupAnnouncement: Bool,
        isAnonymous: Bool,
        isReplyInThread: Bool,
        transmitToChat: Bool,
        scheduleTime: Int64?,
        sendMessageTracker: SendMessageTrackerProtocol?,
        stateHandler: ((SendMessageState) -> Void)?)
    // swiftlint:enable all

    func patchScheduleMessage(chatID: Int64,
                              cid: String,
                              item: RustPB.Basic_V1_ScheduleMessageItem,
                              messageType: Basic_V1_Message.TypeEnum?,
                              content: QuasiContent,
                              scheduleTime: Int64?,
                              isSendImmediately: Bool,
                              needSuspend: Bool,
                              callback: @escaping (Result<RustPB.Im_V1_PatchScheduleMessageResponse, Error>) -> Void)

    func resend(message: Message)

    // MARK: 以下是Thread
    /// 发送Thread
    /// - Parameter title: String
    /// - Parameter content: RustPB.Basic_V1_RichText
    /// - Parameter chatId: String
    /// - Parameter isGroupAnnouncement: isGroupAnnouncement
    func sendThread(
        title: String,
        content: RustPB.Basic_V1_RichText,
        lingoInfo: RustPB.Basic_V1_LingoOption?,
        chatId: String,
        isGroupAnnouncement: Bool
    )

    func resend(thread: ThreadMessage, to threadType: SendThreadToType)

    func dealPush(thread: ThreadMessage, to threadType: SendThreadToType) -> Bool
}

final class PostSendServiceImpl: PostSendService, UserResolverWrapper {
    let userResolver: UserResolver
    fileprivate enum BoxType {
        case message(Message)
        case thread(ThreadMessage)
    }

    fileprivate struct Box {
        var id: String
        var richText: RustPB.Basic_V1_RichText?
        var type: BoxType

        public  init(message: Message) {
            self.type = .message(message)
            self.id = message.cid
            self.richText = (message.content as? PostContent)?.richText
        }

        public init(thread: ThreadMessage) {
            self.type = .thread(thread)
            self.id = thread.cid
            self.richText = (thread.rootMessage.content as? PostContent)?.richText
        }
    }

    /// 帖子发送状态，ThreadChatController中使用
    public var sendThreadStatusDriver: Driver<(ThreadMessage, Error?)> {
        return self.sendThreadAPI.statusDriver
    }

    private static let logger = Logger.log(PostSendServiceImpl.self, category: "Module.IM.PostSendImpl")
    private let disposeBag = DisposeBag()

    /// 在多线程使用DispatchSemaphore，static使用避免DispatchSemaphore释放时当前信号小于初始信号而引发crash。
    /// https://developer.apple.com/documentation/dispatch/dispatchsemaphore/1452955-init
    static private let semaphore = DispatchSemaphore(value: 1)
    private let queue = DispatchQueue.global(qos: .background)

    private let sendMessageAPI: SendMessageAPI
    private let sendThreadAPI: SendThreadAPI
    private let videoSendService: VideoMessageSendService

    /// 记录正在转码的 tasks
    private var tasks: SafeSet<String> = SafeSet<String>([], synchronization: .semaphore)

    private var messageAPI: MessageAPI
    private var sendingManager: SendingMessageManager

    public init(userResolver: UserResolver, sendMessageAPI: SendMessageAPI, sendThreadAPI: SendThreadAPI, videoSendService: VideoMessageSendService) throws {
        self.userResolver = userResolver
        self.sendingManager = try userResolver.resolve(assert: SendingMessageManager.self)
        self.messageAPI = try userResolver.resolve(assert: MessageAPI.self)
        self.sendMessageAPI = sendMessageAPI
        self.sendThreadAPI = sendThreadAPI
        self.videoSendService = videoSendService
    }

    public func patchScheduleMessage(chatID: Int64,
                                     cid: String,
                                     item: RustPB.Basic_V1_ScheduleMessageItem,
                                     messageType: Basic_V1_Message.TypeEnum?,
                                     content: QuasiContent,
                                     scheduleTime: Int64?,
                                     isSendImmediately: Bool,
                                     needSuspend: Bool,
                                     callback: @escaping (Result<RustPB.Im_V1_PatchScheduleMessageResponse, Error>) -> Void) {
        var needUpload: Bool = false
        for childElement in content.richText.elements.values where childElement.tag == .media {
            let key = childElement.property.media.key
            if key.isEmpty {
                needUpload = true
            }
        }

        self.messageAPI
            .patchScheduleMessageRequest(chatID: chatID,
                                         messageType: messageType,
                                         patchObject: item,
                                         patchType: .updating,
                                         scheduleTime: scheduleTime,
                                         isSendImmediately: isSendImmediately,
                                         needSuspend: needSuspend,
                                         content: content)
            .subscribe(onNext: { [weak self] _ in
                if content.richText.filterMediaPropertys().isEmpty || needUpload == false {
                    self?.updateScheduleMsg(chatID: chatID,
                                            item: item,
                                            messageType: messageType,
                                            content: content,
                                            scheduleTime: scheduleTime,
                                            isSendImmediately: isSendImmediately,
                                            callback: callback)
                } else {
                    // 异步转码发消息
                    self?.asyncSendMessage(richText: content.richText, cid: cid, sender: { [weak self] _ in
                        self?.updateScheduleMsg(chatID: chatID,
                                                item: item,
                                                messageType: messageType,
                                                content: content,
                                                scheduleTime: scheduleTime,
                                                isSendImmediately: isSendImmediately,
                                                callback: callback)
                    })
                }
            }, onError: { error in
                callback(.failure(error))
            }).disposed(by: self.disposeBag)
    }

    func updateScheduleMsg(chatID: Int64,
                           item: RustPB.Basic_V1_ScheduleMessageItem,
                           messageType: Basic_V1_Message.TypeEnum?,
                           content: QuasiContent,
                           scheduleTime: Int64?,
                           isSendImmediately: Bool,
                           callback: @escaping (Result<RustPB.Im_V1_PatchScheduleMessageResponse, Error>) -> Void) {
        self.messageAPI
            .patchScheduleMessageRequest(chatID: chatID,
                                         messageType: messageType,
                                         patchObject: item,
                                         patchType: .update,
                                         scheduleTime: scheduleTime,
                                         isSendImmediately: isSendImmediately,
                                         needSuspend: false,
                                         content: content)
            .subscribe(onNext: { res in
                callback(.success(res))
            }).disposed(by: self.disposeBag)
    }

    // swiftlint:disable all
    /// 发送富文本消息
    public func sendMessage(
        context: APIContext,
        title: String,
        content: RustPB.Basic_V1_RichText,
        lingoInfo: RustPB.Basic_V1_LingoOption?,
        parentMessage: LarkModel.Message?,
        chatId: String,
        threadId: String?,
        isGroupAnnouncement: Bool,
        isAnonymous: Bool,
        isReplyInThread: Bool,
        transmitToChat: Bool,
        scheduleTime: Int64? = nil,
        sendMessageTracker: SendMessageTrackerProtocol? = nil,
        stateHandler: ((SendMessageState) -> Void)?) {

            context.set(key: APIContext.anonymousKey, value: isAnonymous)
            context.set(key: APIContext.replyInThreadKey, value: isReplyInThread)

            // 如果帖子不包含视频，直接当成普通帖子发送
            if content.filterMediaPropertys().isEmpty {
                let params = SendPostParams(title: title,
                                            content: content,
                                            lingoInfo: lingoInfo,
                                            parentMessage: parentMessage,
                                            chatId: chatId,
                                            threadId: threadId,
                                            isGroupAnnouncement: isGroupAnnouncement,
                                            scheduleTime: scheduleTime,
                                            transmitToChat: transmitToChat)
                sendMessageAPI.sendPost(
                    context: context,
                    sendPostParams: params,
                    preprocessingHandler: nil,
                    sendMessageTracker: sendMessageTracker,
                    stateHandler: stateHandler)
                return
            }

            let params = SendPostParams(title: title,
                                        content: content,
                                        lingoInfo: lingoInfo,
                                        parentMessage: parentMessage,
                                        chatId: chatId,
                                        threadId: threadId,
                                        isGroupAnnouncement: isGroupAnnouncement,
                                        scheduleTime: scheduleTime,
                                        transmitToChat: transmitToChat)
            // 先创建假消息
            self.sendMessageAPI.sendPost(
                context: context,
                sendPostParams: params,
                preprocessingHandler: { [weak self] (message, sender) in
                    guard let message = message else { return }

                    let box = Box(message: message)
                    // 异步转码发消息
                    self?.asyncSendMessage(box, sender: { sender($0) })
                },
                sendMessageTracker: sendMessageTracker,
                stateHandler: stateHandler
            )
        }

    // swiftlint:enable all

    /// 重发富文本消息
    public func resend(message: LarkModel.Message) {
        let box = Box(message: message)
        guard let richText = box.richText else { return }

        if richText.filterMediaPropertys().isEmpty {
            self.sendMessageAPI.resendMessage(message: message)
        } else {
            self.sendMessageAPI.updateQuasiMessage(context: nil, cid: message.id, status: .pending)
            self.asyncSendMessage(box) { [weak self] _ in
                self?.sendMessageAPI.resendMessage(message: message)
            }
        }
    }

    /// 小组发帖，支持匿名
    public func sendThread(
        title: String,
        content: RustPB.Basic_V1_RichText,
        lingoInfo: RustPB.Basic_V1_LingoOption?,
        chatId: String,
        isGroupAnnouncement: Bool
    ) {
        self.sendPost(
            to: .threadChat,
            title: title,
            content: content,
            lingoInfo: lingoInfo,
            chatId: chatId,
            isGroupAnnouncement: isGroupAnnouncement
        )
    }

    /// 小组发帖/广场发帖核心逻辑
    private func sendPost(
        to threadType: SendThreadToType,
        title: String,
        content: RustPB.Basic_V1_RichText,
        lingoInfo: RustPB.Basic_V1_LingoOption?,
        chatId: String,
        isGroupAnnouncement: Bool) {

            let context = APIContext(contextID: "")
            // 如果帖子不包含视频，直接当成普通帖子发送
            if content.filterMediaPropertys().isEmpty {
                sendThreadAPI.sendPost(
                    context: context,
                    to: threadType,
                    title: title,
                    content: content,
                    lingoInfo: lingoInfo,
                    chatId: chatId,
                    isGroupAnnouncement: isGroupAnnouncement,
                    preprocessingHandler: nil)
                return
            }

            self.sendThreadAPI.sendPost(
                context: context,
                to: threadType,
                title: title,
                content: content,
                lingoInfo: lingoInfo,
                chatId: chatId,
                isGroupAnnouncement: isGroupAnnouncement
            ) { [weak self] (thread, sender) in
                guard let thread = thread else { return }

                let box = Box(thread: thread)
                // 异步转码发消息
                self?.asyncSendMessage(box, sender: sender)
            }
        }

    /// 重发帖子
    public func resend(thread: ThreadMessage, to threadType: SendThreadToType) {
        let box = Box(thread: thread)
        guard let richText = box.richText else {
            return
        }

        if richText.filterMediaPropertys().isEmpty {
            self.sendThreadAPI.resend(thread: thread, to: threadType)
        } else {
            self.sendMessageAPI.updateQuasiMessage(context: nil, cid: thread.cid, status: .pending)
            self.asyncSendMessage(box) { [weak self] _ in
                self?.sendThreadAPI.resend(thread: thread, to: threadType)
            }
        }
    }

    public func dealPush(thread: ThreadMessage, to threadType: SendThreadToType) -> Bool {
        return self.sendThreadAPI.dealPush(thread: thread, sendThreadType: threadType)
    }
}

private extension PostSendServiceImpl {

    /// 视频批量转码
    ///
    /// - Parameter mediaPropertys: richtext中的视频属性
    /// - Returns: 转码结束信号
    func videoTranscode(_ mediaPropertys: [(String, RustPB.Basic_V1_RichTextElement.MediaProperty)]) -> Observable<(TranscodeInfo)> {
        // 视频信息转为转码信号
        let tasks = mediaPropertys.map { (property) -> Observable<TranscodeInfo> in
            let taskKey = property.1.key
            self.sendingManager.add(task: taskKey)
            return self.videoSendService.transcode(
                key: property.1.key,
                form: property.1.originPath,
                to: property.1.compressPath,
                isOriginal: false,
                videoSize: CGSize(width: Int(property.1.width), height: Int(property.1.height)),
                extraInfo: [:],
                progressBlock: nil,
                dataBlock: nil, retryBlock: nil).do(onNext: { [weak self] (arg) in
                    guard let self = self else { return }
                    self.sendingManager.remove(task: taskKey)

                    // 只处理转码成功的状态
                    guard case .finish = arg.status else { return }

                    let compressPath = property.1.compressPath
                    let fileName = String(URL(string: compressPath)?.path.split(separator: "/").last ?? "")
                    let fileSize = try? FileUtils.fileSize(compressPath)
                    sendVideoCache(userID: self.userResolver.userID).saveFileName(
                        fileName,
                        size: Int(fileSize ?? 0)
                    )
                }, onError: { [weak self] (_) in
                    self?.sendingManager.remove(task: taskKey)
                }) // progress, 暂时没有使用的场景
        }
        return Observable.concat(tasks)
    }

    func asyncSendMessage(_ box: Box, sender: @escaping (_ preprocessCost: TimeInterval?) -> Void) {
        asyncSendMessage(richText: box.richText, cid: box.id, sender: sender)
    }

    /// 异步转码视频消息，所有转码任务串行执行
    ///
    /// - Parameters:
    ///   - message: 消息
    ///   - isResend: 是不是重发
    func asyncSendMessage(richText: RustPB.Basic_V1_RichText?, cid: String, sender: @escaping (_ preprocessCost: TimeInterval?) -> Void) {
        guard let richtext = richText else { return }
        /// 如果cryptoToken(封面的token) 存在了，说明是已经转码过的视频了 无需转码
        if let value = richtext.filterMediaPropertys().first,
           !value.1.cryptoToken.isEmpty {
            sender(0)
            return
        }
        self.queue.async { [weak self] in
            guard let `self` = self else { return }
            PostSendServiceImpl.semaphore.wait()
            let start = CACurrentMediaTime()

            self.videoTranscode(richtext.filterMediaPropertys()).subscribe(onNext: nil, onError: { [weak self] (error) in
                PostSendServiceImpl.logger.error("send media post: 'Transcoding' error ", error: error)
                guard let `self` = self else { return }
                // 转码失败不单独弹错误信息，依赖 消息 状态处理。
                self.sendMessageAPI.updateQuasiMessage(context: nil, cid: cid, status: .failed)
            }, onCompleted: {
                sender(CACurrentMediaTime() - start)
            }, onDisposed: {
                // 开始执行下一个转码任务
                PostSendServiceImpl.semaphore.signal()
            }).disposed(by: self.disposeBag)
        }
    }
}

fileprivate extension RustPB.Basic_V1_RichText {
    func filterMediaPropertys() -> [(String, RustPB.Basic_V1_RichTextElement.MediaProperty)] {
        return self.mediaIds.compactMap({ (id) -> (String, RustPB.Basic_V1_RichTextElement.MediaProperty)? in
            if let element = self.elements[id] {
                return (id, element.property.media)
            }
            return nil
        })
    }
}
