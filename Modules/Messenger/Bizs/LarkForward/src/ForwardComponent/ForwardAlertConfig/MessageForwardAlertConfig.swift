//
//  MessageForwardAlertConfig.swift
//  LarkForward
//
//  Created by ByteDance on 2023/5/18.
//

import LarkModel
import LarkUIKit
import RxSwift
import LarkMessengerInterface
import EENavigator
import LKCommonsLogging
import LKCommonsTracker
import Homeric
import LarkAccountInterface

// nolint: duplicated_code,long_function -- 代码可读性治理无QA，不做复杂修改
// TODO: 转发内容预览能力组件内置时优化该逻辑
final class MessageForwardAlertConfig: ForwardMessageContentPreviewAlertConfig {
    private static let logger = Logger.log(MessageForwardAlertConfig.self, category: "MessageForwardAlertConfig")

    override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? MessageForwardAlertContent != nil {
            return true
        }
        return false
    }

    override func getContentView() -> UIView? {
        guard let messageContent = content as? MessageForwardAlertContent else { return nil }
        var view: UIView?
        if messageContent.message.isOnTimeDel {
            view = ForwardMessageBurnConfirmFooter()
        } else if !forwardDialogContentFG {
            view = getOldContentPreview(messageContent)
        } else {
            view = getNewContentPreview(messageContent)
        }
        return view
    }

    func getOldContentPreview(_ messageContent: MessageForwardAlertContent) -> UIView? {
        guard let modelService = try? userResolver.resolve(assert: ModelService.self),
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
            view = ForwardContentPreviewUtils.calendarEventShareView(message: message, modelService: modelService)
        case .generalCalendar:
            switch message.content {
            case is GeneralCalendarEventRSVPContent:
                view = ForwardContentPreviewUtils.calendarEventRSVPView(message: message, modelService: modelService)
            case is SchedulerAppointmentCardContent:
                view = ForwardContentPreviewUtils.calendarSchedulerAppointmentView(message: message, modelService: modelService)
            case is RoundRobinCardContent:
                view = ForwardContentPreviewUtils.calendarSchedulerRoundRobinView(message: message, modelService: modelService)
            default:
                break
            }
        case .todo:
            view = ForwardContentPreviewUtils.todoShareView(message: message)
        case .audio:
            view = ForwardAudioMessageConfirmFooter(message: message, userResolver: userResolver)
        case .card:
            switch (message.content as? CardContent)?.type {
            case .vote?:
                return nil
            default:
                break
            }
        case .videoChat:
            view = ForwardContentPreviewUtils.videoChatFooterView(message: message)
        case .calendar:
            view = ForwardContentPreviewUtils.calendarBotFooterView(message: message, modelService: modelService)
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

    func getNewContentPreview(_ messageContent: MessageForwardAlertContent) -> UIView? {
        guard let modelService = try? userResolver.resolve(assert: ModelService.self),
              let mergeForwardContentService = self.mergeForwardContentService,
              let chatSecurity = self.chatSecurity
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
            view = ForwardContentPreviewUtils.calendarEventShareView(message: message, modelService: modelService)
        case .generalCalendar:
            switch message.content {
            case is GeneralCalendarEventRSVPContent:
                view = ForwardContentPreviewUtils.calendarEventRSVPView(message: message, modelService: modelService)
            case is SchedulerAppointmentCardContent:
                view = ForwardContentPreviewUtils.calendarSchedulerAppointmentView(message: message, modelService: modelService)
            case is RoundRobinCardContent:
                view = ForwardContentPreviewUtils.calendarSchedulerRoundRobinView(message: message, modelService: modelService)
            default:
                break
            }
        case .todo:
            view = ForwardContentPreviewUtils.todoShareView(message: message)
        case .audio:
            view = ForwardAudioMessageConfirmFooter(message: message, newStyle: true, userResolver: userResolver)
        case .card:
            switch (message.content as? CardContent)?.type {
            case .vote?:
                return nil
            case .text:
                view = ForwardCardMessageConfirmFooter(message: message, previewFg: forwardContentPreviewFG)
            default:
                break
            }
        case .videoChat:
            view = ForwardContentPreviewUtils.videoChatFooterView(message: message)
        case .calendar:
            view = ForwardContentPreviewUtils.calendarBotFooterView(message: message, modelService: modelService)
        case .shareGroupChat:
            view = ForwardNewShareGroupConfirmFooter(message: message, modelService: modelService)
        case .unknown, .system, .email, .hongbao,
                .commercializedHongbao:
            view = ForwardUnknownMessageConfirmFooter()
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
                                         shouldDetectFile: previewBodyInfo?.chat.shouldDetectFile ?? false,
                                         canSaveImage: false,
                                         canShareImage: false,
                                         canEditImage: false,
                                         hideSavePhotoBut: true,
                                         canTranslate: false,
                                         translateEntityContext: (nil, .other))
            if let fromVC = self.targetVc {
                self.userResolver.navigator.present(body: body, from: fromVC)
            }
        case .media:
            guard let content = message.content as? MediaContent else { return }
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
                self.userResolver.navigator.present(body: body, from: fromVC)
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
            self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
        case .unknown, .system, .email, .hongbao,
                .commercializedHongbao, .generalCalendar,
                .shareGroupChat, .calendar, .videoChat,
                .shareUserCard, .audio, .todo, .shareCalendarEvent, .diagnose, .vote:
            break
        @unknown default:
            assert(false, "new value")
        }
    }

    private func openFile(chat: Chat, message: Message) {
        guard let content = message.content as? FileContent else { return }
        let body = MessageFileBrowseBody(message: message, scene: .forwardPreview)
        guard let fromVC = self.targetVc else { return }
        Self.logger.info("message forward open File fileId:\(content.key)")
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }

    func openContenPreview(previewBodyInfo: ForwardContentPreviewBodyInfo?) {
        guard let bodyInfo = previewBodyInfo else { return }
        let body = MessageForwardContentPreviewBody(messages: bodyInfo.messages, chat: bodyInfo.chat, title: bodyInfo.title)
        guard let fromVC = self.targetVc else { return }
        self.userResolver.navigator.present(body: body, wrap: LkNavigationController.self, from: fromVC)
    }
}
