//
//  MessageForwardAlertProvider.swift
//  LarkForward
//
//  Created by 姚启灏 on 2019/2/21.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import UniverseDesignToast
import RxSwift
import LarkSDKInterface
import LarkMessengerInterface
import LarkAlertController
import EENavigator
import AppReciableSDK
import LarkContainer
import LarkMessageBase
import LarkCore
import LKCommonsLogging
import LKCommonsTracker
import LarkSetting
import Homeric
import LarkAccountInterface

struct MessageForwardAlertContent: ForwardAlertContent {
    let message: Message
    let type: TransmitType
    let from: ForwardMessageBody.From
    let traceChatType: ForwardAppReciableTrackChatType
    let context: [String: Any]
    /// originMergeForwardId: 私有话题群转发的详情页传入 其他业务传入nil
    /// 私有话题群帖子转发 走的合并转发的消息，在私有话题群转发的详情页，不在群内的用户是可以转发或者收藏这些消息的 会有权限问题，需要originMergeForwardId
    let originMergeForwardId: String?
    /// 支持转发到帖子(不置灰)
    let supportToThread: Bool
    var getForwardContentCallback: GetForwardContentCallback {
        let param = MessageForwardParam(type: self.type,
                                        originMergeForwardId: self.originMergeForwardId)
        let forwardContent = ForwardContentParam.transmitSingleMessage(param: param)
        let callback = {
            let observable = Observable.just(forwardContent)
            return observable
        }
        return callback
    }

    init(
        originMergeForwardId: String?,
        message: Message,
        type: TransmitType,
        from: ForwardMessageBody.From,
        traceChatType: ForwardAppReciableTrackChatType,
        supportToThread: Bool,
        context: [String: Any] = [:]) {
            self.originMergeForwardId = originMergeForwardId
            self.message = message
            self.type = type
            self.from = from
            self.context = context
            self.traceChatType = traceChatType
            self.supportToThread = supportToThread
        }
}

// nolint: duplicated_code,long_function -- v2转发代码，v3转发全业务GA后可删除
final class MessageForwardAlertProvider: ForwardAlertProvider {
    @ScopedInjectedLazy var chatSecurity: ChatSecurityControlService?
    @ScopedInjectedLazy var chatAPI: ChatAPI?
    @ScopedInjectedLazy var messageAPI: MessageAPI?
    @ScopedInjectedLazy var chatterAPI: ChatterAPI?
    @ScopedInjectedLazy var mergeForwardContentService: MergeForwardContentService?
    private var disposeBag: DisposeBag = DisposeBag()
    private static let logger = Logger.log(MessageForwardAlertProvider.self, category: "MessageForwardAlertProvider")
    /// 转发内容一级预览FG开关
    private lazy var forwardDialogContentFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.dialog_content_new"))
    }()
    /// 转发内容二级预览FG开关
    private lazy var forwardContentPreviewFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core_forward_content_preview"))
    }()

    lazy var contentPreviewHandler: LarkForwardContentPreviewHandler? = {
        guard let chatAPI = self.chatAPI,
              let messageAPI = self.messageAPI,
              let chatterAPI = self.chatterAPI
        else { return nil }
        let contentPreviewHandler = LarkForwardContentPreviewHandler(chatAPI: chatAPI,
                                                                     messageAPI: messageAPI,
                                                                     chatterAPI: chatterAPI,
                                                                     userResolver: userResolver)
        return contentPreviewHandler
    }()

    override var isSupportMention: Bool {
        return true
    }

    override var pickerTrackScene: String? {
        return "msg_forward"
    }

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? MessageForwardAlertContent != nil {
            return true
        }
        return false
    }

    override var shouldCreateGroup: Bool {
        if ((content as? MessageForwardAlertContent)?.message.content as? EventShareContent) != nil {
            return false
        }
        return true
    }

    override func getFilter() -> ForwardDataFilter? {
        // 日历的日程分享 只能搜索到本租户以内的人 needSearchOuterTenant = false
        guard let messageContent = content as? MessageForwardAlertContent else { return nil }
        var cannotSearchOuterTenant = messageContent.message.type == .shareCalendarEvent
        if let content = (messageContent.message.content as? EventShareContent) {
            //仅在日程是内部日程且有会议群的情况下过滤掉外部用户
            cannotSearchOuterTenant = content.isMeeting && !content.isCrossTenant
        }

        return { (item) -> Bool in
            if messageContent.message.type == .calendar || messageContent.message.type == .shareCalendarEvent {
                //这里的isCrossTenant指的是每个用户是否是外部用户，上面的isCrossTenant指的是日程是否跨租户
                if item.isCrossTenant && cannotSearchOuterTenant { return false }
            }
            return true
        }
    }

    override func getForwardItemsIncludeConfigs() -> IncludeConfigs? {
        // 所有类型都不过滤（包括myai）
        return [
            ForwardUserEntityConfig(),
            ForwardGroupChatEntityConfig(),
            ForwardBotEntityConfig(),
            ForwardThreadEntityConfig(),
            ForwardMyAiEntityConfig()
        ]
    }

    override func getForwardItemsIncludeConfigsForEnabled() -> IncludeConfigs? {
        guard let messageContent = content as? MessageForwardAlertContent else { return nil }
        var cannotShowOuterTenant = messageContent.message.type == .shareCalendarEvent
        if let content = (messageContent.message.content as? EventShareContent) {
            //仅在日程是内部日程且有会议群的情况下置灰外部用户
            cannotShowOuterTenant = content.isMeeting && !content.isCrossTenant
        }
        //产品预期日历消息置灰话题对齐日历分享
        let notCalendarMessage = !(messageContent.message.type == .calendar || messageContent.message.type == .shareCalendarEvent)
        let supprotToThread = notCalendarMessage && messageContent.supportToThread

        var includeConfigs: IncludeConfigs = [
            ForwardUserEnabledEntityConfig(tenant: cannotShowOuterTenant ? .inner : .all),
            ForwardGroupChatEnabledEntityConfig(tenant: cannotShowOuterTenant ? .inner : .all),
            ForwardBotEnabledEntityConfig(),
            ForwardMyAiEnabledEntityConfig()
        ]
        if supprotToThread {
            includeConfigs.append(ForwardThreadEnabledEntityConfig())
        }
        return includeConfigs
    }

    override func getContentView(by items: [ForwardItem]) -> UIView? {
        var view: UIView?
        if !forwardDialogContentFG {
            view = getOldContentPreview(by: items)
        } else {
            view = getNewContentPreview(by: items)
        }
        return view
    }

    override func containBurnMessage() -> Bool {
        guard let messageContent = content as? MessageForwardAlertContent else { return false }
        return messageContent.message.isOnTimeDel
    }

    func getOldContentPreview(by items: [ForwardItem]) -> UIView? {
        guard let messageContent = content as? MessageForwardAlertContent,
              let modelService = try? resolver.resolve(assert: ModelService.self),
              let chatSecurity = self.chatSecurity
        else { return nil }
        let message = messageContent.message

        var view: UIView?
        switch message.type {
        case .text:
            view = ForwardTextMessageConfirmFooter(message: message, modelService: modelService)
        case .location:
            view = ForwardOldLocationMessageConfirmFooter(message: message, modelService: modelService)
        case .sticker:
            let image = messageContent.context[ForwardMessageBody.forwardImageThumbnailKey] as? UIImage
            view = ForwardImageMessageConfirmFooter(message: message, modelService: modelService, image: image, hasPermissionPreview: true)
        case .image:
            let image = messageContent.context[ForwardMessageBody.forwardImageThumbnailKey] as? UIImage
            var anonymousId = ""
            if let chat = self.chatAPI?.getLocalChat(by: message.channel.id) {
                anonymousId = chat.anonymousId
            }
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: anonymousId, message: message)
            view = ForwardImageMessageConfirmFooter(message: message, modelService: modelService, image: image, hasPermissionPreview: permissionPreview.0)
        case .shareUserCard:
            view = ForwardUserCardMessageConfirmFooter(message: message)
        case .media:
            var anonymousId = ""
            if let chat = self.chatAPI?.getLocalChat(by: message.channel.id) {
                anonymousId = chat.anonymousId
            }
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: anonymousId, message: message)
            view = ForwardVideoMessageConfirmFooter(message: message, modelService: modelService, hasPermissionPreview: permissionPreview.0)
        case .file, .folder:
            var anonymousId = ""
            if let chat = self.chatAPI?.getLocalChat(by: message.channel.id) {
                anonymousId = chat.anonymousId
            }
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: anonymousId, message: message)
            view = ForwardFileAndFolderMessageConfirmFooter(message: message, hasPermissionPreview: permissionPreview.0)
        case .post:
            view = ForwardOldPostMessageConfirmFooter(message: message, modelService: modelService)
        case .mergeForward:
            if (message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false {
                return nil
            }
            view = MergeForwardConfirmFooter(message: message)
        case .shareCalendarEvent:
            view = self.calendarEventShareView(message: message, modelService: modelService)
        case .generalCalendar:
            switch message.content {
            case is GeneralCalendarEventRSVPContent:
                view = self.calendarEventRSVPView(message: message, modelService: modelService)
            case is SchedulerAppointmentCardContent:
                view = self.calendarSchedulerAppointmentView(message: message, modelService: modelService)
            case is RoundRobinCardContent:
                view = self.calendarSchedulerRoundRobinView(message: message, modelService: modelService)
            default:
                break
            }
        case .todo:
            view = self.todoShareView(message: message)
        case .audio:
            view = ForwardAudioMessageConfirmFooter(message: message, userResolver: userResolver)
        case .card:
            switch (message.content as? CardContent)?.type {
            case .vote?:
                return nil
            @unknown default:
                break
            }
        case .videoChat:
            view = self.videoChatFooterView(message: message)
        case .calendar:
            view = self.calendarBotFooterView(message: message, modelService: modelService)
        case .shareGroupChat:
            view = ForwardShareGroupConfirmFooter(message: message, modelService: modelService)
        case .unknown, .system, .email, .hongbao,
                .commercializedHongbao:
            // TODO: todo 适配
            break
        case .diagnose, .vote:
            return nil
        @unknown default:
            assert(false, "new value")
            return nil
        }
        return view
    }

    func getNewContentPreview(by items: [ForwardItem]) -> UIView? {
        guard let messageContent = content as? MessageForwardAlertContent,
              let modelService = try? resolver.resolve(assert: ModelService.self),
              let chatSecurity = self.chatSecurity,
              let mergeForwardContentService = self.mergeForwardContentService
        else { return nil }
        let message = messageContent.message

        var hasPermissionPreviewContent: Bool = true
        var previewBodyInfo: ForwardContentPreviewBodyInfo?

        contentPreviewHandler?.generateForwardContentPreviewBodyInfo(message: message)
            .subscribe(onNext: { (previewBody) in
                guard let previewBody = previewBody else { return }
                previewBodyInfo = previewBody
            }, onError: { (error) in
                Self.logger.error("message forward alert generate messages: \(error)")
            }).disposed(by: self.disposeBag)
        var view: UIView?
        Self.logger.info("getContentView messageType \(message.type)")
        switch message.type {
        case .text:
            view = ForwardNewTextMessageConfirmFooter(message: message, modelService: modelService, previewFg: forwardContentPreviewFG)
        case .location:
            view = ForwardNewLocationMessageConfirmFooter(message: message, modelService: modelService, previewFg: forwardContentPreviewFG)
        case .sticker:
            let image = messageContent.context[ForwardMessageBody.forwardImageThumbnailKey] as? UIImage
            view = ForwardNewImageMessageConfirmFooter(message: message, image: image, hasPermissionPreview: true)
        case .image:
            let image = messageContent.context[ForwardMessageBody.forwardImageThumbnailKey] as? UIImage
            var anonymousId = ""
            if let chat = self.chatAPI?.getLocalChat(by: message.channel.id) {
                anonymousId = chat.anonymousId
            }
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: anonymousId, message: message)
            hasPermissionPreviewContent = permissionPreview.0
            view = ForwardNewImageMessageConfirmFooter(message: message, image: image, hasPermissionPreview: permissionPreview.0)
        case .shareUserCard:
            view = ForwardNewUserCardMessageConfirmFooter(message: message)
        case .media:
            var anonymousId = ""
            if let chat = self.chatAPI?.getLocalChat(by: message.channel.id) {
                anonymousId = chat.anonymousId
            }
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: anonymousId, message: message)
            hasPermissionPreviewContent = permissionPreview.0
            view = ForwardNewVideoConfirmFooter(message: message, hasPermissionPreview: permissionPreview.0)
        case .file, .folder:
            var anonymousId = ""
            if let chat = self.chatAPI?.getLocalChat(by: message.channel.id) {
                anonymousId = chat.anonymousId
            }
            let permissionPreview = chatSecurity.checkPermissionPreview(anonymousId: anonymousId, message: message)
            hasPermissionPreviewContent = permissionPreview.0
            view = ForwardNewFileAndFolderMessageConfirmFooter(message: message, hasPermissionPreview: permissionPreview.0)
        case .post:
            if let content = message.content as? PostContent {
                view = ForwardNewPostMessageConfirmFooter(message: message, modelService: modelService, previewFg: forwardContentPreviewFG)
            }
        case .mergeForward:
            if (message.content as? MergeForwardContent)?.isFromPrivateTopic ?? false {
                view = ForwardThreadMessageConfirmFooter(message: message, mergeForwardContentService: mergeForwardContentService, previewFg: forwardContentPreviewFG)
            } else {
                view = ForwardMergeMessageConfirmFooter(message: message, previewFg: forwardContentPreviewFG)
            }
        case .shareCalendarEvent:
            view = self.calendarEventShareView(message: message, modelService: modelService)
        case .generalCalendar:
            switch message.content {
            case is GeneralCalendarEventRSVPContent:
                view = self.calendarEventRSVPView(message: message, modelService: modelService)
            case is SchedulerAppointmentCardContent:
                view = self.calendarSchedulerAppointmentView(message: message, modelService: modelService)
            case is RoundRobinCardContent:
                view = self.calendarSchedulerRoundRobinView(message: message, modelService: modelService)
            default:
                break
            }
        case .todo:
            view = self.todoShareView(message: message)
        case .audio:
            view = ForwardAudioMessageConfirmFooter(message: message, newStyle: true, userResolver: userResolver)
        case .card:
            switch (message.content as? CardContent)?.type {
            case .vote?:
                return nil
            case .text:
                view = ForwardCardMessageConfirmFooter(message: message, previewFg: forwardContentPreviewFG)
            @unknown default:
                break
            }
        case .videoChat:
            view = self.videoChatFooterView(message: message)
        case .calendar:
            view = self.calendarBotFooterView(message: message, modelService: modelService)
        case .shareGroupChat:
            view = ForwardNewShareGroupConfirmFooter(message: message, modelService: modelService)
        case .unknown, .system, .email, .hongbao,
                .commercializedHongbao:
            view = ForwardUnknownMessageConfirmFooter()
            break
        case .diagnose, .vote:
            return  nil
        @unknown default:
            assert(false, "new value")
            return nil
        }
        guard let baseView = view as? BaseTapForwardConfirmFooter,
              hasPermissionPreviewContent else { return view }
        baseView.didClickAction = { [weak self] in
            guard let self = self else { return }
            self.didClickMessageForwardAlert(message: message, previewBodyInfo: previewBodyInfo)
        }
        return view
    }

    func didClickMessageForwardAlert(message: Message, previewBodyInfo: ForwardContentPreviewBodyInfo?) {
        Tracker.post(TeaEvent(Homeric.IM_MSG_FORWARD_SELECT_CLICK,
                              params: ["click": "msg_detail",
                                       "target": "none"]))
        if !forwardContentPreviewFG {
            Self.logger.info("didClick forwardContentPreview \(forwardContentPreviewFG)")
            return
        }
        guard let messageContent = content as? MessageForwardAlertContent else { return }
        switch message.type {
        case .text, .location, .mergeForward, .card, .post:
            guard let bodyInfo = previewBodyInfo else {
                self.contentPreviewHandler?.generateForwardContentPreviewBodyInfo(message: message)
                    .subscribe(onNext: { [weak self] (previewBody) in
                        guard let self = self else { return }
                        guard let previewBody = previewBody else { return }
                        self.openContenPreview(previewBodyInfo: previewBody)
                    }, onError: { (error) in
                        Self.logger.error("message forward alert generate messages again: \(error)")
                    }).disposed(by: self.disposeBag)
                return
            }
            openContenPreview(previewBodyInfo: previewBodyInfo)
        case .image, .sticker:
            var imageSet = ImageSet()
            var imageKey = ""
            if let imageContent = message.content as? LarkModel.ImageContent {
                imageKey = imageContent.image.origin.key
            } else if let imageContent = message.content as? LarkModel.StickerContent {
                imageKey = imageContent.key
            }
            imageSet.key = imageKey
            imageSet.origin.key = imageKey
            var asset = Asset(sourceType: .image(imageSet))
            /// 这个key是用户用来保存图片的key 使用原图的
            asset.key = imageKey
            asset.originKey = imageKey
            asset.forceLoadOrigin = true
            asset.isAutoLoadOrigin = true
            let body = PreviewImagesBody(assets: [asset],
                                         pageIndex: 0,
                                         scene: .normal(assetPositionMap: [:], chatId: nil),
                                         shouldDetectFile: previewBodyInfo?.chat.shouldDetectFile ?? true,
                                         canSaveImage: false,
                                         canShareImage: false,
                                         canEditImage: false,
                                         hideSavePhotoBut: true,
                                         canTranslate: false,
                                         translateEntityContext: (nil, .other))
            if let fromVC = self.targetVc {
                userResolver.navigator.present(body: body, from: fromVC)
            }
        case .media:
            let result = LKDisplayAsset.createAssetExceptForSticker(
                messages: [message],
                selected: message.id,
                cid: message.cid,
                isMeSend: { _ in false },
                checkPreviewPermission: { _ in .allow }
            )
            guard !result.assets.isEmpty else { return }
            let userService = try? resolver.resolve(assert: PassportUserService.self)
            let body = PreviewImagesBody(assets: result.assets.map { $0.transform() },
                                         pageIndex: 0,
                                         scene: .normal(assetPositionMap: result.assetPositionMap, chatId: nil),
                                         shouldDetectFile: previewBodyInfo?.chat.shouldDetectFile ?? false,
                                         canSaveImage: false,
                                         canShareImage: false,
                                         canEditImage: false,
                                         hideSavePhotoBut: true,
                                         showSaveToCloud: false,
                                         canTranslate: false,
                                         translateEntityContext: (nil, .other),
                                         session: userService?.user.sessionKey,
                                         videoShowMoreButton: false
            )
            if let fromVC = self.targetVc {
                userResolver.navigator.present(body: body, from: fromVC)
            }
        case .file:
            guard let chat = self.chatAPI?.getLocalChat(by: message.channel.id) else { return }
            openFile(chat: chat, message: message)
        case .folder:
            guard let chat = self.chatAPI?.getLocalChat(by: message.channel.id) else { return }
            let body = FolderManagementBody(
                message: message,
                messageId: nil,
                scene: .forwardPreview,
                chatFromTodo: chat
            )
            guard let fromVC = self.targetVc else { return }
            userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
        case .unknown, .system, .email, .hongbao,
                .commercializedHongbao, .generalCalendar,
                .shareGroupChat, .calendar, .videoChat,
                .shareUserCard, .audio, .todo, .shareCalendarEvent, .diagnose, .vote:
            break
        @unknown default:
            assert(false, "new value")
            break
        }
    }

    private func openFile(chat: Chat, message: Message) {
        guard let content = message.content as? FileContent else { return }
        let body = MessageFileBrowseBody(message: message, scene: .forwardPreview)
        guard let fromVC = self.targetVc else { return }
        Self.logger.info("message forward open File fileId:\(content.key)")
        userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    func openContenPreview(previewBodyInfo: ForwardContentPreviewBodyInfo?) {
        guard let bodyInfo = previewBodyInfo else { return }
        let body = MessageForwardContentPreviewBody(messages: bodyInfo.messages, chat: bodyInfo.chat, title: bodyInfo.title)
        guard let fromVC = self.targetVc else { return }
        userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    override func sureAction(items: [ForwardItem], input: String?, from: UIViewController) -> Observable<[String]> {
        guard let content = self.content as? MessageForwardAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else {
            return .just([])
        }

        // ids表示chatID/messageID，取决于type是否是threadMessage
        let ids = self.itemsToIds(items)
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        let hud = UDToast.showLoading(on: window)
        trackStickerForwardIfNeeded(content: content)

        //发送埋点
        let reciableKey = AppReciableSDK.shared.start(biz: .Messenger, scene: .Chat, event: .forwardMessage, page: "ForwardViewController")
        let beforeSend = CACurrentMediaTime()
        return forwardService.forward(originMergeForwardId: content.originMergeForwardId,
                                      type: content.type,
                                      message: content.message,
                                      checkChatIDs: ids.chatIds,
                                      to: items.filter { $0.type == .chat }.map { $0.id },
                                      to: threadIDAndChatIDs,
                                      userIds: ids.userIds,
                                      extraText: input ?? "",
                                      from: content.from)
        .observeOn(MainScheduler.instance)
        .do(onNext: { [weak window] (_, filePermCheck) in
            hud.remove()
            if let window = window,
               let filePermCheck = filePermCheck {
                UDToast.showTips(with: filePermCheck.toast, on: window)
            }
            if content.message.type == .shareCalendarEvent {
                Tracer.trackEventShareForwardDone()
            }

            //发送成功埋点
            let sdk_cost = CACurrentMediaTime() - beforeSend
            let extra = Extra(
                isNeedNet: true,
                latencyDetail: [
                    "sdk_cost": Int(sdk_cost * 1000)
                ],
                metric: nil,
                category: [
                    "message_type": "\((content as MessageForwardAlertContent).message.type.rawValue)",
                    "chat_type": "\((content as MessageForwardAlertContent).traceChatType.rawValue)"
                ],
                extra: [
                    "context_id": ""
                ]
            )
            AppReciableSDK.shared.end(key: reciableKey, extra: extra)
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            //失败埋点
            AppReciableSDK.shared.error(
                params: ErrorParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .forwardMessage,
                    errorType: .SDK,
                    errorLevel: .Exception,
                    errorCode: (error as NSError).code,
                    userAction: nil,
                    page: "ForwardViewController",
                    errorMessage: (error as NSError).description,
                    extra: Extra(
                        isNeedNet: true,
                        category: [
                            "message_type": "\((content as MessageForwardAlertContent).message.type.rawValue)",
                            "chat_type": "\((content as MessageForwardAlertContent).traceChatType.rawValue)",
                            "transmit_type": "\(content.type.rawValue)"
                        ],
                        extra: [
                            "context_id": "",
                            "chat_count": "\(ids.chatIds.count + ids.userIds.count)",
                            "origin_id": "\(content.message.id)",
                            "include_static_resource": content.message.hasResource
                        ]
                    )
                )
            )
        }).map({ (chatIds, _) in return chatIds })
    }

    override func sureAction(items: [ForwardItem], attributeInput: NSAttributedString?, from: UIViewController) -> Observable<[String]> {
        guard let content = self.content as? MessageForwardAlertContent,
              let forwardService = try? self.resolver.resolve(assert: ForwardService.self),
              let window = from.view.window else {
            return .just([])
        }

        // ids表示chatID/messageID，取决于type是否是threadMessage
        let ids = self.itemsToIds(items)
        let threadIDAndChatIDs = items.filter { $0.type.isThread }.map { ($0.id, $0.channelID ?? "") }
        let hud = UDToast.showLoading(on: window)
        trackStickerForwardIfNeeded(content: content)

        //发送埋点
        let reciableKey = AppReciableSDK.shared.start(biz: .Messenger, scene: .Chat, event: .forwardMessage, page: "ForwardViewController")
        let beforeSend = CACurrentMediaTime()
        return forwardService.forward(originMergeForwardId: content.originMergeForwardId,
                                      type: content.type,
                                      message: content.message,
                                      checkChatIDs: ids.chatIds,
                                      to: items.filter { $0.type == .chat }.map { $0.id },
                                      to: threadIDAndChatIDs,
                                      userIds: ids.userIds,
                                      attributeExtraText: attributeInput ?? NSAttributedString(string: ""),
                                      from: content.from)
        .observeOn(MainScheduler.instance)
        .do(onNext: { [weak window] (_, filePermCheck) in
            hud.remove()
            if let window = window,
               let filePermCheck = filePermCheck {
                UDToast.showTips(with: filePermCheck.toast, on: window)
            }
            if content.message.type == .shareCalendarEvent {
                Tracer.trackEventShareForwardDone()
            }

            //发送成功埋点
            let sdk_cost = CACurrentMediaTime() - beforeSend
            let extra = Extra(
                isNeedNet: true,
                latencyDetail: [
                    "sdk_cost": Int(sdk_cost * 1000)
                ],
                metric: nil,
                category: [
                    "message_type": "\((content as MessageForwardAlertContent).message.type.rawValue)",
                    "chat_type": "\((content as MessageForwardAlertContent).traceChatType.rawValue)"
                ],
                extra: [
                    "context_id": ""
                ]
            )
            AppReciableSDK.shared.end(key: reciableKey, extra: extra)
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            forwardErrorHandler(userResolver: self.userResolver, hud: hud, on: from, error: error)
            //失败埋点
            AppReciableSDK.shared.error(
                params: ErrorParams(
                    biz: .Messenger,
                    scene: .Chat,
                    event: .forwardMessage,
                    errorType: .SDK,
                    errorLevel: .Exception,
                    errorCode: (error as NSError).code,
                    userAction: nil,
                    page: "ForwardViewController",
                    errorMessage: (error as NSError).description,
                    extra: Extra(
                        isNeedNet: true,
                        category: [
                            "message_type": "\((content as MessageForwardAlertContent).message.type.rawValue)",
                            "chat_type": "\((content as MessageForwardAlertContent).traceChatType.rawValue)",
                            "transmit_type": "\(content.type.rawValue)"
                        ],
                        extra: [
                            "context_id": "",
                            "chat_count": "\(ids.chatIds.count + ids.userIds.count)",
                            "origin_id": "\(content.message.id)",
                            "include_static_resource": content.message.hasResource
                        ]
                    )
                )
            )
        }).map({ (chatIds, _) in return chatIds })
    }

    private func calendarEventShareView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? EventShareContent else {
            return nil
        }
        var title = ""
        if content.isInvalid {
            title = BundleI18n.LarkForward.Lark_Legacy_EventShareExpired
        } else {
            title = content.title.isEmpty ? BundleI18n.LarkForward.Lark_Legacy_NoTitle : content.title
        }
        let subMessage = modelService.getEventTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title,
                                               subMessage: subMessage,
                                               image: Resources.eventShare)
    }

    private func calendarEventRSVPView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? GeneralCalendarEventRSVPContent else {
            return nil
        }
        var title = ""
        if content.cardStatus == .invalid {
            title = BundleI18n.LarkForward.Lark_Legacy_EventShareExpired
        } else {
            title = content.title.isEmpty ? BundleI18n.LarkForward.Lark_Legacy_NoTitle : content.title
        }
        let subMessage = modelService.getEventTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title,
                                               subMessage: subMessage,
                                               image: Resources.eventShare)
    }

    private func calendarSchedulerAppointmentView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? SchedulerAppointmentCardContent else {
            return nil
        }
        var title = BundleI18n.LarkForward.Calendar_Scheduling_EventNoAvailable_Bot
        if content.status == .statusActive {
            if content.action == .actionReschedule {
                title = BundleI18n.LarkForward.Calendar_Scheduling_HostRescheduledByInvitee(invitee: content.guestName, host: content.hostName)
            } else if content.action == .actionCancel {
                title = BundleI18n.LarkForward.Calendar_Scheduling_HostCanceledByInvitee(invitee: content.altOperatorName, host: content.hostName)
            } else {
                title = BundleI18n.LarkForward.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
            }
        }
        let subMessage = modelService.getEventTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title,
                                               subMessage: subMessage,
                                               image: Resources.eventShare)
    }

    private func calendarSchedulerRoundRobinView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? RoundRobinCardContent else {
            return nil
        }
        var title = BundleI18n.LarkForward.Calendar_Scheduling_EventNoAvailable_Bot
        if content.status == .statusActive {
            title = BundleI18n.LarkForward.Calendar_Scheduling_WhoDidEvent_Bot(host: content.hostName, invitee: content.guestName)
        }
        let subMessage = modelService.getEventTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title,
                                               subMessage: subMessage,
                                               image: Resources.eventShare)
    }

    private func videoChatFooterView(message: Message) -> ForwardVideoChatMessageConfirmFooter? {
        guard let content = message.content as? VChatMeetingCardContent else { return  nil }
        return ForwardVideoChatMessageConfirmFooter(content: content)
    }

    private func calendarBotFooterView(message: Message, modelService: ModelService) -> CalendarEventShareConfirmFooter? {
        guard let content = message.content as? CalendarBotCardContent else { return nil }
        var title = ""
        if content.isInvalid {
            title = BundleI18n.LarkForward.Lark_Legacy_EventShareExpired
        } else {
            title = content.summary.isEmpty ? BundleI18n.LarkForward.Lark_Legacy_NoTitle : content.summary
        }
        let time = modelService.getCalendarBotTimeSummerize(message)
        return CalendarEventShareConfirmFooter(message: title, subMessage: time, image: Resources.eventShare)
    }

    private func todoShareView(message: Message) -> TodoShareConfirmFooter? {
        guard let content = message.content as? TodoContent else {
            return nil
        }
        var title: String
        let isInvalid = content.pbModel.msgStatus == .deleted
        let isDeleted = content.pbModel.todoDetail.deletedMilliTime > 0
        if isInvalid {
            title = BundleI18n.LarkForward.Todo_Task_BotMsgTaskCardExpired
        } else if isDeleted {
            title = BundleI18n.LarkForward.Todo_Task_MsgTypeTask
        } else {
            title = content.pbModel.todoDetail.summary
        }

        return TodoShareConfirmFooter(
            message: title,
            image: Resources.todoShare
        )
    }

    private func trackStickerForwardIfNeeded(content: MessageForwardAlertContent) {
        //这个埋点有点蛋疼,产品要求转发表情包记录一下
        if content.message.content is StickerContent {
            Tracer.trackStickerForward(from: .chat)
        }
    }
}
