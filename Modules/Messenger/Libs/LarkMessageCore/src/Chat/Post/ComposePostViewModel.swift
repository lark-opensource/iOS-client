//
//  ComposePostViewModel.swift
//  LarkChat
//
//  Created by lichen on 2018/8/5.
//

import UIKit
import Foundation
import LarkModel
import LarkCore
import RxCocoa
import RxSwift
import LarkUIKit
import LKCommonsLogging
import LarkAttachmentUploader
import LarkSDKInterface
import LarkMessengerInterface
import LarkSendMessage
import TangramService
import LarkContainer
import RustPB
import ByteWebImage
import LarkSetting
import LarkMessageBase
import LarkAccountInterface
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import LarkBaseKeyboard
import LarkChatKeyboardInterface

public final class ComposePostViewModel: UserResolverWrapper {
    public let userResolver: LarkContainer.UserResolver
    @ScopedInjectedLazy var myAIService: MyAIService?

    static let logger = Logger.log(ComposePostViewModel.self, category: "Module.ComposePost.ViewModel")

    let disposeBag = DisposeBag()

    public var keyboardStatusManager: KeyboardStatusManager {
        return dataService.keyboardStatusManager
    }

    public var isMyAIChatMode: Bool {
        return dataService.isMyAIChatMode
    }

    public var unsupportPasteTypes: [KeyboardSupportPasteType] {
        return dataService.unsupportPasteTypes
    }

    public lazy var syncToChatOptionView: UIView? = {
        return dataService.forwardToChatSerivce.getView(isInComposeView: true, chat: chatModel)
    }()

    public var supportAtMyAI: Bool {
        guard fgService?.dynamicFeatureGatingValue(with: "im.chat.my_ai_inline") ?? false,
              let chat = self.chatModel,
              chat.supportMyAIInlineMode,
              myAIService?.enable.value == true,
              myAIService?.needOnboarding.value == false else { return false }
        return self.dataService.myAIInlineService != nil
    }

    let dataService: KeyboardShareDataService
    public var completeCallback: ((RichTextContent, Int64?) -> Void)?
    public var cancelCallback: ((ComposePostItem?) -> Void)?
    public var multiEditFinishCallback: (() -> Void)?
    public var patchScheduleMsgFinishCallback: (() -> Void)?
    public var selectMyAICallBack: (() -> Void)?
    public var setScheduleTipStatus: ((ScheduleMessageStatus) -> Void)?
    public var getScheduleMsgSendTime: (() -> Int64?)?
    public var getSendScheduleMsgIds: (() -> ([String], [String]))?
    public weak var rootVC: UIViewController?

    var autoFillTitle: Bool = true

    /// 是否是来自MsgThread
    public var isFromMsgThread: Bool = false {
        didSet {
            let item: ComposeKeyboardPageItem? = self.module.context.store.getValue(for: ComposeKeyboardPageItem.key)
            item?.isFromMsgThread = isFromMsgThread
        }
    }

    /// 业务上是否允许 支持边写边译 defalut is false
    public var supportRealTimeTranslate: Bool = false

    var chatId: String {
        return self.chatModel?.id ?? ""
    }

    var supportFontStyle: Bool {
        return !(self.chatModel?.isCrypto ?? false)
    }

    var threadId: String? {
        if chatModel?.chatMode == .threadV2 {
            switch keyboardStatusManager.currentKeyboardJob {
            case .multiEdit(let message):
                return message.parentMessage?.id ?? message.id
            case .reply(let info):
                return info.message.id
            default:
                return nil
            }
        }
        return nil
    }

    private var _chatModel: LarkModel.Chat?
    private var topicGroup: TopicGroup?
    /// 图片发送逻辑统一FG
    lazy var IsCompressCameraPhotoFG: Bool = fgService?.staticFeatureGatingValue(with: "feature_key_camera_photo_compress") ?? false

    public var chatModel: LarkModel.Chat? {
        get {
            return chatWrapper?.chat.value ?? _chatModel
        }

        set {
            if chatWrapper != nil {
                //仅当没有chatWrapper时可以直接修改chatModel
                assertionFailure()
                return
            }
            _chatModel = newValue
        }
    }

    var chatType: LarkModel.Chat.TypeEnum {
        return self.chatModel?.type ?? .p2P
    }

    private let chatWrapper: ChatPushWrapper?
    /// 是否是在广场发帖
    public var isNewTopic: Bool {
        return chatWrapper == nil
    }

    var isMeetingChat: Bool {
        return self.chatModel?.isMeeting ?? false
    }

    var isBotChat: Bool {
        if let chatter = chatModel?.chatter, chatter.type == .bot {
            return true
        } else {
            return false
        }
    }

    public var multiEditCountdownService: MultiEditCountdownService {
        return self.dataService.countdownService
    }

    public var isForwardToChat: Bool {
        return self.dataService.forwardToChatSerivce.forwardToChat
    }

    let transcodeService: VideoTranscodeService

    @ScopedInjectedLazy public var threadAPI: ThreadAPI?
    @ScopedInjectedLazy public var reactionAPI: ReactionAPI?
    @ScopedInjectedLazy public var userGeneralSettings: UserGeneralSettings?
    @ScopedInjectedLazy var videoSendService: VideoMessageSendService?
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy public var messageAPI: MessageAPI?
    @ScopedInjectedLazy public var multiEditService: MultiEditService?
    @ScopedInjectedLazy public var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy public var tenantUniversalSettingService: TenantUniversalSettingService?
    // 定时发送服务
    @ScopedInjectedLazy public var scheduleSendService: ScheduleSendService?
    @ScopedInjectedLazy var postSendService: PostSendService?

    @ScopedInjectedLazy var urlPreviewAPI: URLPreviewAPI?
    @ScopedInjectedLazy var abTestService: MenuInteractionABTestService?

    @ScopedInjectedLazy var pictureHandlerService: KeyboardPanelPictureHandlerService?
    @ScopedInjectedLazy var postRouter: ComposePostRouter?
    @ScopedInjectedLazy var smartCorrectService: SmartCorrectService?
    @ScopedInjectedLazy var fgService: FeatureGatingService?
    @ScopedInjectedLazy var messageBurntService: MessageBurnService?

    let docAPI: DocAPI

    public var attachmentServer: PostAttachmentServer

    let defaultContent: String?

    let modelService: ModelService

    let pushChannelMessage: Driver<PushChannelMessage>

    var translateService: RealTimeTranslateService?
    var applyTranslationCallback: ((_ title: String?, _ content: RustPB.Basic_V1_RichText?) -> Void)?
    var recallTranslationCallback: (() -> Void)?

    public var attachmentUploader: AttachmentUploader {
        return attachmentServer.attachmentUploader
    }
    let placeholder: NSAttributedString

    var placeHolderUpdateCallBack: ((NSAttributedString) -> Void)?

    var reeditContent: RichTextContent?

    var userActualNameInfoDic: [String: String]?

    var hiddeTitleTextView: Bool = false

    let supportVideoContent: Bool

    let isKeyboardNewStyleEnable: Bool

    let userSpaceURL: URL?

    let draftCache: DraftCache?

    let postItem: ComposePostItem?

    let pasteBoardToken: String

    private let chatFromWhere: ChatFromWhere

    public lazy var currentUserId: String = {
        return self.userResolver.userID
    }()

    deinit {
        multiEditCountdownService.stopMultiEditTimer()
    }

    let module: BaseKeyboardModule<IMComposeKeyboardContext, IMKeyboardMetaModel>

    init(
        userResolver: UserResolver,
        module: BaseKeyboardModule<IMComposeKeyboardContext, IMKeyboardMetaModel>,
        optionalChatWrapper: ChatPushWrapper?,
        dataService: KeyboardShareDataService,
        defaultContent: String?,
        draftCache: DraftCache?,
        modelService: ModelService,
        transcodeService: VideoTranscodeService,
        docAPI: DocAPI,
        attachmentServer: PostAttachmentServer,
        pushChannelMessage: Driver<PushChannelMessage>,
        reeditContent: RichTextContent?,
        userSpaceURL: URL?,
        supportVideoContent: Bool,
        isKeyboardNewStyleEnable: Bool,
        placeholder: NSAttributedString?,
        postItem: ComposePostItem?,
        pasteBoardToken: String,
        chatFromWhere: ChatFromWhere) {
        self.userResolver = userResolver
        self.module = module
        self.chatWrapper = optionalChatWrapper
        self.dataService = dataService
        self.defaultContent = defaultContent
        self.modelService = modelService
        self.draftCache = draftCache
        self.attachmentServer = attachmentServer
        self.pushChannelMessage = pushChannelMessage
        self.reeditContent = reeditContent
        self.transcodeService = transcodeService
        self.supportVideoContent = supportVideoContent
        self.isKeyboardNewStyleEnable = isKeyboardNewStyleEnable
        self.userSpaceURL = userSpaceURL
        self.docAPI = docAPI
        self.postItem = postItem
        self.pasteBoardToken = pasteBoardToken
        self.placeholder = placeholder ?? NSAttributedString(string: BundleI18n.LarkMessageCore.Lark_Legacy_ComposePostWriteSomething)
        self.chatFromWhere = chatFromWhere
        self.pushChannelMessage
            .drive(onNext: { [weak self] (push) in
                guard let `self` = self else { return }
                self.keyboardStatusManager.onReceivedPushMessage(push.message)
            })
            .disposed(by: self.disposeBag)
        if let chatModel = chatModel,
            chatModel.chatMode == .threadV2 {
            hiddeTitleTextView = true
        } else {
            hiddeTitleTextView = false
        }

    }

    // chat，小组使用必须有chatPushWrapper
    public convenience init(
        userResolver: UserResolver,
        module: BaseKeyboardModule<IMComposeKeyboardContext, IMKeyboardMetaModel>,
        chatWrapper: ChatPushWrapper,
        defaultContent: String?,
        draftCache: DraftCache,
        modelService: ModelService,
        transcodeService: VideoTranscodeService,
        docAPI: DocAPI,
        attachmentServer: PostAttachmentServer,
        pushChannelMessage: Driver<PushChannelMessage>,
        reeditContent: RichTextContent?,
        userSpaceURL: URL?,
        supportVideoContent: Bool,
        isKeyboardNewStyleEnable: Bool,
        placeholder: NSAttributedString?,
        pasteBoardToken: String,
        chatFromWhere: ChatFromWhere) {
            self.init(userResolver: userResolver,
                      module: module,
                      optionalChatWrapper: chatWrapper,
                      dataService: KeyboardShareDataManager(),
                      defaultContent: defaultContent,
                      draftCache: draftCache,
                      modelService: modelService,
                      transcodeService: transcodeService,
                      docAPI: docAPI,
                      attachmentServer: attachmentServer,
                      pushChannelMessage: pushChannelMessage,
                      reeditContent: reeditContent,
                      userSpaceURL: userSpaceURL,
                      supportVideoContent: supportVideoContent,
                      isKeyboardNewStyleEnable: isKeyboardNewStyleEnable,
                      placeholder: placeholder,
                      postItem: nil,
                      pasteBoardToken: pasteBoardToken,
                      chatFromWhere: chatFromWhere)
    }

    func setupModule() {
        let pageItem = ComposeKeyboardPageItem(chatFromWhere: chatFromWhere,
                                               isFromMsgThread: self.isFromMsgThread,
                                               attachmentServer: attachmentServer,
                                               supportAtMyAI: self.supportAtMyAI)
        module.context.store.setValue(pageItem, for: ComposeKeyboardPageItem.key)
        if let wrapper = chatWrapper {
            let model = IMKeyboardMetaModel(chat: wrapper.chat.value)
            module.handler(model: model)
        }
        module.keyboardPanelInit()
        chatWrapper?.chat
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chat in
                self?.module.modelDidChange(model: IMKeyboardMetaModel(chat: chat))
            }).disposed(by: disposeBag)
    }

    func upload(image: UIImage, imageData: Data?, useOriginal: Bool, extraInfo: [String: AnyHashable]? = nil) -> String? {
        var imageInfo: [String: String] = [
            "width": "\(Int32(image.size.width))",
            "height": "\(Int32(image.size.height))",
            "type": "post",
            "useOriginal": useOriginal ? "1" : "0"
        ]
        // 额外信息，为了不破坏原有结构，所以转jsonString放进去
        if let extra = extraInfo,
           let jsonData = try? JSONSerialization.data(withJSONObject: extra, options: .fragmentsAllowed) {
            let string = String(data: jsonData, encoding: .utf8)
            imageInfo["extraInfo"] = string
        }

        guard let data = imageData else {
            ComposePostViewModel.logger.info("image 无法转化为对应 data")
            return nil
        }

        let imageAttachment = self.attachmentUploader.attachemnt(data: data, type: .secureImage, info: imageInfo)
        ComposePostViewModel.logger.info("use custom uploader imageAttachment.key: \(imageAttachment.key)")
        // 使用自定义上传attachment接口
        self.attachmentUploader.customUpload(attachment: imageAttachment)
        return imageAttachment.key
    }

    func upload(videoInfo: VideoParseInfo) -> String? {
        let priview = videoInfo.preview
        // 这里添加 isVideo 是为了提示上传者 不上传视频首帧图片，只使用缓存能力
        let info: [String: String] = [
            "isVideo": "1"
        ]

        var imageData = (priview as? ByteImage)?.animatedImageData
        if imageData == nil {
            if let firstFrameData = videoInfo.firstFrameData {
                imageData = firstFrameData
            } else {
                imageData = priview.jpegData(compressionQuality: 0.75)
            }
        }
        guard let data = imageData else {
            ComposePostViewModel.logger.info("video image 无法转化为对应 data")
            return nil
        }
        let imageAttachment = self.attachmentUploader.attachemnt(data: data, type: .secureImage, info: info)
        guard self.attachmentUploader.upload(attachment: imageAttachment) else {
            ComposePostViewModel.logger.error("没有注册 image 类型的 attachment uptrueload handler")
            return nil
        }
        return imageAttachment.key
    }

    public static func postDraftFileKey(id: DraftId,
                                        isNewTopic: Bool = false) -> String {
        switch id {
        case .replyInThread(let messageId):
            return "thread" + messageId
        case .replyMessage(let messageId, _):
            return "message" + messageId
        case .multiEditMessage(let messageId, _):
            return "editMessage" + messageId
        case .schuduleSend(let chatId, _, _, _, _):
            return "schuduleSend" + chatId
        case .chat(let chatId):
            if isNewTopic {
                return "draftForNewTopic"
            } else {
                return "chat" + chatId
            }
        }
    }

    func draftKey() -> String {
        if let editMessage = self.keyboardStatusManager.getMultiEditMessage() {
            return editMessage.editDraftId
        } else if let message = self.keyboardStatusManager.getReplyMessage() {
            return isFromMsgThread ? message.msgThreadDraftId : message.postDraftId
        } else if isNewTopic {
            return "draftForNewTopic"
        } else {
            return self.chatModel?.postDraftId ?? ""
        }
    }

    /// 匿名时候 更新占位文案
   public func updateAnonymousPlaceholderTextWithMaxCount(_ count: Int64) {
        let text = BundleI18n.LarkMessageCore.Lark_Groups_PostAnonymouslyPlaceholder(count)
        self.placeHolderUpdateCallBack?(NSAttributedString(string: text))
    }

    /// 实名时候 切会原有文案
    public func updateRealNamePlaceholderText() {
        self.placeHolderUpdateCallBack?(self.placeholder)
    }

    public func fetchDraftModel() -> Observable<PostDraftModel> {
        guard let draftCache = self.draftCache else {
            return .just(PostDraftModel.default)
        }
        return draftCache.getDraft(key: self.draftKey())
            .map { [weak self] (draft) -> PostDraftModel in
                guard let self = self else { return PostDraftModel() }
                var postDraft = draft.content.isEmpty ? PostDraftModel() : PostDraftModel.parse(draft.content)
                if draft.content.isEmpty, let defaultContent = self.defaultContent {
                    postDraft.content = defaultContent
                    postDraft.userInfoDic = self.userActualNameInfoDic ?? [:]
                }

                if let reeditContent = self.reeditContent {
                    postDraft.title = reeditContent.title
                    postDraft.content = (try? reeditContent.richText.jsonString()) ?? ""
                    postDraft.processProvider = reeditContent.processProvider
                    postDraft.userInfoDic = self.userActualNameInfoDic ?? [:]
                }
                return postDraft
            }
    }

    public func cleanPostDraft() {
        let draftKey = self.draftKey()
        if let editMessage = self.keyboardStatusManager.getMultiEditMessage() {
            self.draftCache?.deleteDraft(key: draftKey, editMessageId: editMessage.id, chatId: self.chatId)
        } else if self.isNewTopic {
            self.draftCache?.deleteThreadTabDraft()
        } else if let message = self.keyboardStatusManager.getReplyMessage() {
            if self.isFromMsgThread {
                self.draftCache?.deleteDraft(key: draftKey, threadId: message.id)
            } else {
                self.draftCache?.deleteDraft(key: draftKey, messageID: message.id, type: .post)
            }
        } else if self.keyboardStatusManager.currentKeyboardJob.isScheduleSendState {
            self.draftCache?.deleteScheduleDraft(key: getScheduleDraftId(),
                                                messageId: keyboardStatusManager.getReplyMessage()?.id,
                                                chatId: self.chatId)
        } else {
            self.draftCache?.deleteDraft(key: draftKey, chatId: self.chatId, type: .post)
        }
        self.attachmentUploader.cleanPostDraftAttachment()
    }

    func getScheduleDraftId() -> String {
        let key = keyboardStatusManager.getReplyMessage() == nil ? chatModel?.scheduleMessageDraftID : keyboardStatusManager.getReplyMessage()?.scheduleMessageDraftId
        return key ?? ""
    }

    public func saveChatPostDraft(_ draft: String,
                                  attachmentKeys: [String],
                                  async: Bool,
                                  type: RustPB.Basic_V1_Draft.TypeEnum = .post) {
        guard !keyboardStatusManager.currentKeyboardJob.isScheduleSendState else { return }
        if let message = keyboardStatusManager.getMultiEditMessage() {
            self.draftCache?.saveDraft(editMessageId: message.id, chatId: self.chatId, content: draft, callback: nil)
        } else if let message = keyboardStatusManager.getReplyMessage() {
            if self.isFromMsgThread {
                self.draftCache?.saveDraft(msgThreadId: message.id,
                                          content: draft,
                                          callback: nil)
            } else {
                self.draftCache?.saveDraft(messageId: message.id,
                                          type: type,
                                          content: draft,
                                          callback: nil)
            }
        } else {
            self.draftCache?.saveDraft(chatId: self.chatId,
                                      type: type,
                                      content: draft,
                                      callback: nil)
        }
        self.savePostDraftAttachment(attachmentKeys: attachmentKeys, async: async)
    }

    fileprivate func savePostDraftAttachment(attachmentKeys: [String], async: Bool = true) {
        let draftId: DraftId
        if let editMessage = keyboardStatusManager.getMultiEditMessage() {
            draftId = .multiEditMessage(messageId: editMessage.id, chatId: self.chatModel?.id ?? "")
        } else if let replyMessage = keyboardStatusManager.getReplyMessage() {
            draftId = isFromMsgThread ? .replyInThread(messageId: replyMessage.id) : .replyMessage(messageId: replyMessage.id)
        } else {
            draftId = .chat(chatId: self.chatModel?.id ?? "")
        }
        let key = ComposePostViewModel.postDraftFileKey(id: draftId,
                                                        isNewTopic: self.isNewTopic)
        var allTasks: [AttachmentUploadTask] = []
        attachmentKeys.forEach { id in
            if let task = self.attachmentUploader.allTasks.task(key: id) {
                allTasks.append(task)
            } else {
                ComposePostViewModel.logger.error("缺少贴子 image or imageId草稿信息", additionalData: ["key": key])
            }
        }
        let checkTaskAttachment = { (task: AttachmentUploadTask) in
            if task.isInvalid(in: self.attachmentUploader.cache.root, domain: key) {
                ComposePostViewModel.logger.error("attachment task 数据丢失")
                assertionFailure("attachment data 数据丢失")
            }
        }

        let taskKeys = allTasks.map({ (task) -> String in
            return task.key
        })
        self.attachmentUploader.cleanPostDraftAttachment(excludeKeys: taskKeys) {
            allTasks.forEach({ (task) in
                checkTaskAttachment(task)
            })
        }
    }

    func closeTranslation(succeed: @escaping () -> Void, fail: @escaping (Error) -> Void) {
        guard let chat = self.chatModel else { return }
        IMTracker.Chat.Main.Click.closeTranslation(chat, self.chatFromWhere.rawValue, location: .chat_view)
        chatAPI?.updateChat(chatId: self.chatId, isRealTimeTranslate: false, realTimeTranslateLanguage: chat.typingTranslateSetting.targetLanguage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
                succeed()
            }, onError: { (error) in
                // 把服务器返回的错误显示出来
                fail(error)
            }).disposed(by: self.disposeBag)
    }
}
