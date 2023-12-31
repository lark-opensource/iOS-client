//
//  DefaultInputViewModel.swift
//  Pods
//
//  Created by lichen on 2018/8/15.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import Photos
import LarkFoundation
import LarkModel
import LarkCore
import LarkKeyboardView
import LKCommonsLogging
import EENavigator
import LarkAudio
import LarkAlertController
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkMessageCore
import LarkFeatureSwitch
import LarkMessageBase
import LarkFeatureGating
import SuiteAppConfig
import LarkContainer
import LarkNavigation
import RustPB
import LarkAttachmentUploader
import LarkOpenChat
import LarkBaseKeyboard
import LarkChatOpenKeyboard

public class DefaultInputViewModel: AfterFirstScreenMessagesRenderDelegate, UserResolverWrapper {
    public let userResolver: UserResolver
    static let logger = Logger.log(DefaultInputViewModel.self, category: "Module.Inputs")

    private let _chatWrapper: () -> ChatPushWrapper
    lazy var chatWrapper: ChatPushWrapper = {
        return self._chatWrapper()
    }()

    // 仅详情页有使用
    var rootMessage: LarkModel.Message?

    public var replyMessage: LarkModel.Message? {
        return replyMessageInfo?.message
    }

    public var replyMessageInfo: KeyboardJob.ReplyInfo? {
        return keyboardStatusManagerBlock?()?.getReplyInfo()
    }

    var keyboardStatusManagerBlock: (() -> KeyboardStatusManager?)?

    var keyboardJob: KeyboardJob? {
        let keyboardStatusManager = keyboardStatusManagerBlock?()
        if keyboardStatusManager == nil {
            Self.logger.warn("keyboardStatusManager found nil, keyboardStatusManagerBlock: \(keyboardStatusManagerBlock)")
        }
        return keyboardStatusManager?.currentKeyboardJob
    }
    var scheduleTime: Int64? {
        if let time = self.scheduleDate?.timeIntervalSince1970 {
            return Int64(time)
        }
        return nil
    }
    var scheduleDate: Date?
    var scheduleInitDate: Date?

    /// 群名称发生变化时数据回调
    var chatDisplayNameChangeCallback: (() -> Void)?

    /// 群发言权限发生变化时进行数据回调
    var chatIsAllowPostChangeCallback: (() -> Void)?

    //自动翻译开关状态变化
    var chatTypingTranslateEnableChanged: (() -> Void)?

    //自动翻译目标语言变化
    var chatTypingTranslateLanguageChanged: (() -> Void)?

    //会话模式变化
    var chatModeChanged: (() -> Void)?

    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var multiEditService: MultiEditService?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var resourceAPI: ResourceAPI?
    @ScopedInjectedLazy var userAPI: UserAPI?
    @ScopedInjectedLazy var microAppService: ChatMicroAppDependency?
    @ScopedInjectedLazy var userAppConfig: UserAppConfig?
    @ScopedInjectedLazy var appConfigService: AppConfigService?

    lazy var draftCache: DraftCache? = {
        return self.supportDraft ? (try? self.userResolver.resolve(type: DraftCache.self)) : nil
    }()

    @ScopedInjectedLazy var scheduleSendService: ScheduleSendService?

    var messageSender: ChatKeyboardMessageSendService?

    let pushChannelMessage: Driver<PushChannelMessage>
    let pushChat: Driver<PushChat>
    var keyboardNewStyleEnable: Bool = false
    var chatModel: Chat {
        return chatWrapper.chat.value
    }
    let disposeBag = DisposeBag()

    let supportDraft: Bool
    let getAttachmentUploader: ((String) -> AttachmentUploader?)
    private var didRunAfterMessagesRender: Bool = false
    init(userResolver: UserResolver,
         chatWrapper: @escaping () -> ChatPushWrapper,
         messageSender: ChatKeyboardMessageSendService?,
         pushChannelMessage: Driver<PushChannelMessage>,
         pushChat: Driver<PushChat>,
         rootMessage: LarkModel.Message?,
         itemsTintColor: UIColor? = nil,
         supportAfterMessagesRender: Bool,
         getAttachmentUploader: @escaping ((String) -> AttachmentUploader?),
         supportDraft: Bool = true) {
        self.userResolver = userResolver
        self._chatWrapper = chatWrapper
        self.messageSender = messageSender
        self.pushChannelMessage = pushChannelMessage
        self.pushChat = pushChat
        self.rootMessage = rootMessage
        self.getAttachmentUploader = getAttachmentUploader
        self.supportDraft = supportDraft
        // supportAfterMessagesRender: 是否支持首屏消息渲染后代理回调,目前普通会话页面做了支持
        if !supportAfterMessagesRender {
            //如果不支持，要内部自己调用回调函数
            self.addObservers()
        }
    }

    func getCurrentDraftContent() -> Observable<(content: String, partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?)> {
        guard let draftCache else { return .just(("", nil)) }
        if let replyMessage = self.replyMessage {
            return draftCache.getDraft(key: replyMessage.textDraftId)
        } else if let rootMessage = self.rootMessage {
            return draftCache.getDraft(key: rootMessage.textDraftId)
        } else {
            return draftCache.getDraft(key: chatWrapper.chat.value.textDraftId)
        }
    }

    func addObservers() {
        self.pushChannelMessage
            .drive(onNext: { [weak self] push in
                guard let `self` = self else { return }
                if push.message.id == self.rootMessage?.id {
                    self.rootMessage = push.message
                }
                if let keyboardStatusManager = self.keyboardStatusManagerBlock?() {
                    keyboardStatusManager.onReceivedPushMessage(push.message)
                }
            }).disposed(by: self.disposeBag)

        chatWrapper.chat.distinctUntilChanged { $0.displayName == $1.displayName }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self,
                    self.replyMessage == nil,
                    self.rootMessage == nil else { return }
                self.chatDisplayNameChangeCallback?()
            }).disposed(by: disposeBag)

        chatWrapper.chat.distinctUntilChanged { $0.isAllowPost == $1.isAllowPost }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.chatIsAllowPostChangeCallback?()
            }).disposed(by: disposeBag)

        chatWrapper.chat.distinctUntilChanged { $0.typingTranslateSetting.isOpen == $1.typingTranslateSetting.isOpen }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (_) in
            self?.chatTypingTranslateEnableChanged?()
        }).disposed(by: disposeBag)

        chatWrapper.chat.distinctUntilChanged { $0.typingTranslateSetting.targetLanguage == $1.typingTranslateSetting.targetLanguage }
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: { [weak self] (_) in
            self?.chatTypingTranslateLanguageChanged?()
        }).disposed(by: disposeBag)

        chatWrapper.chat.distinctUntilChanged { $0.displayInThreadMode == $1.displayInThreadMode }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.chatModeChanged?()
            }).disposed(by: disposeBag)
    }

    func getDraftMessageBy(lastDraftId: String, callback: @escaping (DraftId?, Message?, RustPB.Basic_V1_Draft?) -> Void) {
        let onError = { callback(nil, nil, nil) }
        guard let draftCache, let messageAPI else { return onError() }

        let currentChatterID = userResolver.userID
        draftCache.getDraftModel(draftID: lastDraftId)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (draft) in
                guard let self = self else { return }
                if let draft = draft {
                    /// 直接调用draft.partialReplyInfo. 如果没有的话 会声场一个默认空的
                    let partialReplyInfo: PartialReplyInfo? = draft.hasPartialReplyInfo ? draft.partialReplyInfo : nil
                    if !draft.editMessageID.isEmpty {
                        messageAPI.fetchMessage(id: draft.editMessageID)
                            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { (message) in
                                callback(.multiEditMessage(messageId: draft.editMessageID, chatId: draft.chatID), message, draft)
                            }, onError: { (error) in
                                DefaultInputViewModel.logger.error("get message failed", error: error)
                                callback(nil, nil, nil)
                            }).disposed(by: self.disposeBag)
                        // 定时消息草稿
                    } else if draft.type == .scheduleMessage {
                        handleScheduleDraft(replyInfo: partialReplyInfo)
                    } else if !draft.messageID.isEmpty {
                        guard let messageAPI = self.messageAPI else { return onError() }
                        /// 获取上一次退出会话时回复的 message
                        messageAPI.fetchMessage(id: draft.messageID)
                            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { (message) in
                                callback(.replyMessage(messageId: draft.messageID, partialReplyInfo: partialReplyInfo), message, draft)
                            }, onError: { (error) in
                                DefaultInputViewModel.logger.error("get message failed", error: error)
                                callback(nil, nil, nil)
                            }).disposed(by: self.disposeBag)
                    } else {
                        callback(.chat(chatId: draft.chatID), nil, draft)
                    }
                } else {
                    callback(nil, nil, nil)
                }
                func handleScheduleDraft(replyInfo: PartialReplyInfo?) {
                    guard let draft = draft else { return }
                    // 有messageId去拉message，否则直接返回
                    if draft.scheduleInfo.item.itemID.isEmpty == false {
                        let fetchScheduleMsgOb = messageAPI.getScheduleMessages(chatId: Int64(draft.chatID) ?? 0,
                                                                                                                        threadId: nil,
                                                                                                                     rootId: nil,
                                                                                     isForceServer: false,
                                                                                                                     scene: .chatOnly)
                        fetchScheduleMsgOb
                            .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { (res) in
                                let message: Message?
                                if let msg = try? Message.transform(entity: res.entity, id: draft.scheduleInfo.item.itemID, currentChatterID: currentChatterID) {
                                    message = msg
                                } else if let msg = try? Message.transformQuasi(entity: res.entity, cid: draft.scheduleInfo.item.itemID) {
                                    message = msg
                                } else {
                                    message = nil
                                }
                                let status = ChatScheduleSendTipViewModel.getScheduleTypeFrom(messageItems: res.messageItems, entity: res.entity)
                                Self.logger.info("draft.scheduleInfo.scheduleTime: \(draft.scheduleInfo.scheduleTime), status: \(status)")
                                // 如果草稿时间为空，不进入定时发送状态
                                if draft.scheduleInfo.scheduleTime == 0 {
                                    callback(nil, nil, nil)
                                    return
                                }
                                callback(.schuduleSend(chatId: draft.chatID,
                                                       time: draft.scheduleInfo.scheduleTime,
                                                       partialReplyInfo: replyInfo,
                                                       parentMessage: message?.parentMessage,
                                                       item: draft.scheduleInfo.item),
                                         message,
                                         draft)
                            }, onError: { (error) in
                                DefaultInputViewModel.logger.error("get message failed", error: error)
                                callback(nil, nil, nil)
                            }).disposed(by: self.disposeBag)
                    } else {
                        if !draft.messageID.isEmpty {
                            /// 获取上一次退出会话时回复的 message
                            messageAPI.fetchMessage(id: draft.messageID)
                                .timeout(.milliseconds(500), scheduler: MainScheduler.instance)
                                .observeOn(MainScheduler.instance)
                                .subscribe(onNext: { (msg) in
                                    callback(.schuduleSend(chatId: draft.chatID,
                                                           time: draft.scheduleInfo.scheduleTime,
                                                           partialReplyInfo: replyInfo,
                                                           parentMessage: msg,
                                                           item: draft.scheduleInfo.item),
                                         nil,
                                         draft)
                                }, onError: { (error) in
                                    DefaultInputViewModel.logger.error("get message failed", error: error)
                                    callback(nil, nil, nil)
                                }).disposed(by: self.disposeBag)
                            return
                        }
                        callback(.schuduleSend(chatId: draft.chatID,
                                               time: draft.scheduleInfo.scheduleTime,
                                               partialReplyInfo: nil,
                                               parentMessage: nil,
                                               item: draft.scheduleInfo.item),
                             nil,
                             draft)
                    }
                }
            }, onError: { (error) in
                DefaultInputViewModel.logger.error("get draft failed", error: error)
                callback(nil, nil, nil)
            }).disposed(by: self.disposeBag)
    }

    //draft相关
    func saveInputViewDraft(content: String, callback: DraftCallback?) {
        guard let keyboardJob = self.keyboardJob else {
            return
        }

        if !self.chatModel.isAllowPost {
            switch keyboardJob {
            case .multiEdit(let multiEditMessage):
                // 如果被禁言则删除草稿
                self.save(draft: "",
                          id: .multiEditMessage(messageId: multiEditMessage.id, chatId: self.chatModel.id),
                          type: .editMessage,
                          callback: callback)
            case .scheduleSend, .scheduleMsgEdit:
                assertionFailure("bussiness error")
            default:
                if let rootMessage = self.rootMessage {
                    self.save(draft: "",
                              id: .replyMessage(messageId: rootMessage.id),
                              type: .text,
                              callback: callback)
                } else {
                    self.save(draft: "",
                              id: .chat(chatId: self.chatModel.id),
                              type: .text,
                              callback: callback)
                }
            }
        } else {
            switch keyboardJob {
            case .multiEdit(let multiEditMessage):
                self.save(draft: content,
                          id: .multiEditMessage(messageId: multiEditMessage.id, chatId: self.chatModel.id),
                          type: .editMessage,
                          callback: callback)
            case .quickAction:
                assertionFailure("not implemented")
            case .reply(let info):
                self.save(draft: content,
                          id: .replyMessage(messageId: info.message.id, partialReplyInfo: info.partialReplyInfo),
                          type: .text,
                          callback: callback)
            case .scheduleSend, .scheduleMsgEdit:
                assertionFailure("bussiness error")
            case .normal:
                if let rootMessage = self.rootMessage {
                    self.save(draft: content,
                              id: .replyMessage(messageId: rootMessage.id),
                              type: .text,
                              callback: callback)
                } else {
                    self.save(draft: content,
                              id: .chat(chatId: self.chatModel.id),
                              type: .text,
                              callback: callback)
                }
            }
        }
    }

    func save(draft: String,
              id: DraftId,
              type: RustPB.Basic_V1_Draft.TypeEnum,
              callback: DraftCallback?) {
        guard let draftCache else { return }
        switch id {
        case .chat(let chatId):
            draftCache.saveDraft(chatId: chatId, type: type, content: draft, callback: callback)
        case .replyMessage(let messageId, let partialReplyInfo):
            draftCache.saveDraft(messageId: messageId, type: type, partialReplyInfo: partialReplyInfo, content: draft, callback: callback)
        case .multiEditMessage(let messageId, let chatId):
            draftCache.saveDraft(editMessageId: messageId, chatId: chatId, content: draft, callback: callback)
        case .schuduleSend(let chatId, let time, let partialReplyInfo, let parentMsg, let item):
            draftCache.saveScheduleMsgDraft(chatId: chatId,
                                            parentMessageId: parentMsg?.id ?? "",
                                            content: draft,
                                            partialReplyInfo: partialReplyInfo,
                                            time: time,
                                            item: item,
                                            callback: callback)
        case .replyInThread:
            break
        @unknown default:
            break
        }
    }

    public func getDraft(key: String) -> Observable<(content: String, partialReplyInfo: RustPB.Basic_V1_Message.PartialReplyInfo?)> {
        return draftCache?.getDraft(key: key) ?? .just(("", nil))
    }

    func cleanReplyMessage() {
        if let replyMessage = self.replyMessage {
            self.keyboardStatusManagerBlock?()?.switchToDefaultJob()
            draftCache?.deleteDraft(key: replyMessage.textDraftId, messageID: replyMessage.id, type: .text)
        }
    }

    func postDraftKey() -> String {
        var key = self.chatModel.postDraftId
        if case .multiEdit(let message) = self.keyboardJob {
            key = message.editDraftId
        } else if let replyMessage = self.replyMessage {
            key = replyMessage.postDraftId
        } else if let rootMessage = self.rootMessage {
            key = rootMessage.postDraftId
        }
        return key
    }

    public func afterMessagesRender() {
        guard !didRunAfterMessagesRender else {
            return
        }
        didRunAfterMessagesRender = true
        self.addObservers()
    }

    func getCurrentAttachmentServer() -> PostAttachmentServer? {
        return nil
    }
}
