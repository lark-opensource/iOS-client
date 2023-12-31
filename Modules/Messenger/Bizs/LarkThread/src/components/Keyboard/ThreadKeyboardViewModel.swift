//
//  ThreadKeyboardViewModel.swift
//  LarkThread
//
//  Created by 李晨 on 2019/2/26.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import LarkFoundation
import LarkModel
import LarkCore
import LarkKeyboardView
import LKCommonsLogging
import EENavigator
import LarkAudio
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkSendMessage
import LarkFeatureGating
import LarkContainer
import RustPB
import LarkMessageCore
import LarkMessageBase
import TangramService
import ByteWebImage
import LarkAttachmentUploader
import LarkGuide
import LarkBaseKeyboard
import LarkChatOpenKeyboard

protocol ThreadKeyboardViewModelDelegate: AnyObject {
    func saveDraft(draft: String, id: DraftId)
    func cleanPostDraftWith(key: String, id: DraftId)
    func defaultInputSendTextMessage(_ content: RustPB.Basic_V1_RichText,
                                     lingoInfo: RustPB.Basic_V1_LingoOption?,
                                     parentMessage: LarkModel.Message?,
                                     scheduleTime: Int64?,
                                     transmitToChat: Bool,
                                     isFullScreen: Bool)
    func defaultInputSendPost(content: RichTextContent,
                              parentMessage: LarkModel.Message?,
                              scheduleTime: Int64?,
                              transmitToChat: Bool,
                              isFullScreen: Bool)
}

class ThreadKeyboardViewModel: UserResolverWrapper {
    private static let logger = Logger.log(ThreadKeyboardViewModel.self, category: "Module.LarkThread.Keyboard")
    let userResolver: LarkContainer.UserResolver

    weak var delegate: ThreadKeyboardViewModelDelegate?
    var replyMessage: LarkModel.Message? {
        return keyboardStatusManagerBlock?()?.getReplyMessage() ?? rootMessage
    }
    var rootMessage: Message?

    var keyboardStatusManagerBlock: (() -> KeyboardStatusManager?)?

    var keyboardJob: KeyboardJob? {
        let keyboardStatusManager = keyboardStatusManagerBlock?()
        if keyboardStatusManager == nil {
            if let rootMessage = rootMessage {
                return .reply(info: KeyboardJob.ReplyInfo(message: rootMessage, partialReplyInfo: nil))
            }
            Self.logger.warn("keyboardStatusManager found nil, keyboardStatusManagerBlock: \(keyboardStatusManagerBlock)")
        }
        return keyboardStatusManager?.currentKeyboardJob
    }
    var chat: Chat {
        return chatWrapper.chat.value
    }
    let chatWrapper: ChatPushWrapper
    let threadWrapper: ThreadPushWrapper
    let chatAPI: ChatAPI
    @ScopedInjectedLazy var threadAPI: ThreadAPI?
    @ScopedInjectedLazy var reactionAPI: ReactionAPI?
    @ScopedInjectedLazy var urlPreviewAPI: URLPreviewAPI?
    @ScopedInjectedLazy var resourceAPI: ResourceAPI?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var multiEditService: MultiEditService?
    @ScopedInjectedLazy var newGuideManager: NewGuideService?
    @ScopedInjectedLazy var scheduleSendService: ScheduleSendService?
    @ScopedInjectedLazy var postSendService: PostSendService?

    let chatterAPI: ChatterAPI
    let docAPI: DocAPI
    let draftCache: DraftCache
    let stickerService: StickerService
    let pushChannelMessage: Driver<PushChannelMessage>
    let router: ThreadKeyboardRouter
    var isShowAtAll: Bool = true
    /// 当前键盘是否是isReplyInThread
    var isReplyInThread: Bool = false
    let disposeBag = DisposeBag()
    var getAttachmentUploader: (String) -> AttachmentUploader? {
        return { [userResolver] key in
            try? userResolver.resolve(assert: AttachmentUploader.self, argument: key)
        }
    }

    //自动翻译开关状态变化
    var chatTypingTranslateEnableChanged: (() -> Void)?

    //自动翻译目标语言变化
    var chatTypingTranslateLanguageChanged: (() -> Void)?

    init(userResolver: UserResolver,
         chatWrapper: ChatPushWrapper,
         threadWrapper: ThreadPushWrapper,
         draftCache: DraftCache,
         chatterAPI: ChatterAPI,
         chatAPI: ChatAPI,
         docAPI: DocAPI,
         stickerService: StickerService,
         pushChannelMessage: Driver<PushChannelMessage>,
         router: ThreadKeyboardRouter,
         delegate: ThreadKeyboardViewModelDelegate
         ) {
        self.userResolver = userResolver
        self.threadWrapper = threadWrapper
        self.chatWrapper = chatWrapper
        self.draftCache = draftCache
        self.chatterAPI = chatterAPI
        self.chatAPI = chatAPI
        self.docAPI = docAPI
        self.stickerService = stickerService
        self.pushChannelMessage = pushChannelMessage
        self.delegate = delegate
        self.router = router
        self.addObservers()
    }

    func addObservers() {
        self.pushChannelMessage
            .drive(onNext: { [weak self] push in
                guard let `self` = self,
                      let keyboardStatusManager = self.keyboardStatusManagerBlock?() else { return }
                keyboardStatusManager.onReceivedPushMessage(push.message)
            }).disposed(by: self.disposeBag)

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
    }

    func saveDraft(draftContent: String) {
        guard let keyboardJob = keyboardJob else {
            return
        }

        let draftId: DraftId
        switch keyboardJob {
        case .multiEdit(let editMessage):
            draftId = .multiEditMessage(messageId: editMessage.id, chatId: self.chat.id)
        case .reply(let info):
            draftId = .replyMessage(messageId: info.message.id)
        case .scheduleSend:
            assertionFailure("error entrance")
            draftId = .chat(chatId: self.chat.id)
        case .scheduleMsgEdit(let message):
            assertionFailure("error entrance")
            draftId = .chat(chatId: self.chat.id)
        case .normal:
            draftId = .chat(chatId: self.chat.id)
        case .quickAction:
            draftId = .chat(chatId: self.chat.id)
        }
        self.delegate?.saveDraft(draft: draftContent, id: draftId)
    }

    func postDraftKey() -> String {
        guard let keyboardJob = keyboardJob else {
            return self.chat.postDraftId
        }

        switch keyboardJob {
        case .multiEdit(let editMessage):
            return editMessage.editDraftId
        case .reply(let info):
            return info.message.postDraftId
        case .scheduleSend:
            assertionFailure("error entrance")
            return self.chat.postDraftId
        case .scheduleMsgEdit(let message):
            assertionFailure("error entrance")
            return self.chat.postDraftId
        case .normal:
            return self.chat.postDraftId
        case .quickAction:
            return self.chat.postDraftId
        }
    }

    func getCurrentAttachmentServer() -> PostAttachmentServer? {
        return nil
    }
}
