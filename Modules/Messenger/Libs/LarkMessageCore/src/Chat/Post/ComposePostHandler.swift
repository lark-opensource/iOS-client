//
//  ComposePostHandler.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/2/27.
//

import Foundation
import Swinject
import EENavigator
import LarkModel
import LarkCore
import LarkAttachmentUploader
import LarkUIKit
import LarkSDKInterface
import LarkMessengerInterface
import LarkSendMessage
import LarkMessageBase
import LarkAccountInterface
import LarkStorage
import ByteWebImage
import LarkBaseKeyboard
import LarkOpenKeyboard
import AppContainer
import LarkOpenIM
import LarkChatOpenKeyboard
import LarkNavigator

/// Chat&ThreadDetail键盘发送富文本
public final class ComposePostHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MessageCore.userScopeCompatibleMode }

    public func handle(_ body: ComposePostBody, req: EENavigator.Request, res: Response) throws {
        let chat: Chat = body.chat
        let draftId: DraftId
        if let editMessage = body.dataService.keyboardStatusManager.getMultiEditMessage() {
            draftId = .multiEditMessage(messageId: editMessage.id, chatId: chat.id)
        } else if let replyMessage = body.dataService.keyboardStatusManager.getReplyMessage() {
            draftId = body.isFromMsgThread ? .replyInThread(messageId: replyMessage.id) : .replyMessage(messageId: replyMessage.id)
        } else {
            draftId = .chat(chatId: chat.id)
        }
        let postDraftName = ComposePostViewModel.postDraftFileKey(id: draftId)
        let attachmentServer: PostAttachmentServer
        if let server = body.attachmentServer {
            attachmentServer = server
        } else {
            let attachmentUploader = try resolver.resolve(assert: AttachmentUploader.self, argument: postDraftName)
            attachmentServer = PostAttachmentManager(attachmentUploader: attachmentUploader)
        }
        let draftCache = try resolver.resolve(assert: DraftCache.self)
        let modelService = try resolver.resolve(assert: ModelService.self)
        let transcodeService = try resolver.resolve(assert: VideoTranscodeService.self)
        let pushChannelMessage = try resolver.userPushCenter
            .driver(for: PushChannelMessage.self)
        let docAPI = try resolver.resolve(assert: DocAPI.self)
        let context = IMComposeKeyboardContext(parent: Container(parent: BootLoader.container),
                                               store: Store(), userStorage: userResolver.storage,
                                               compatibleMode: userResolver.compatibleMode)
        IMChatComposeKeyboardModule.onLoad(context: context)
        IMChatComposeKeyboardModule.registGlobalServices(container: context.container)
        let keyboardModule = IMChatComposeKeyboardModule(context: context)
        let wrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
        let viewModel = ComposePostViewModel(
            userResolver: self.userResolver,
            module: keyboardModule,
            optionalChatWrapper: wrapper,
            dataService: body.dataService,
            defaultContent: body.defaultContent,
            draftCache: body.dataService.supportDraft ? draftCache : nil,
            modelService: modelService,
            transcodeService: transcodeService,
            docAPI: docAPI,
            attachmentServer: attachmentServer,
            pushChannelMessage: pushChannelMessage,
            reeditContent: body.reeditContent,
            userSpaceURL: try resolver.resolve(assert: UserSpaceService.self).currentUserDirectory,
            supportVideoContent: body.sendVideoEnable,
            isKeyboardNewStyleEnable: KeyboardDisplayStyleManager.isNewKeyboadStyle(),
            placeholder: body.placeholder,
            postItem: body.postItem,
            pasteBoardToken: body.pasteBoardToken,
            chatFromWhere: body.chatFromWhere)

        let vc = ComposePostViewContainer(resolver: userResolver, viewModel: viewModel, chatFromWhere: body.chatFromWhere)
        viewModel.completeCallback = body.callbacks?.completeCallback
        viewModel.cancelCallback = body.callbacks?.cancelCallback
        viewModel.multiEditFinishCallback = body.callbacks?.multiEditFinishCallback
        viewModel.patchScheduleMsgFinishCallback = body.callbacks?.patchScheduleMsgFinishCallback
        viewModel.selectMyAICallBack = body.callbacks?.selectMyAICallBack
        viewModel.setScheduleTipStatus = body.callbacks?.setScheduleTipStatus
        viewModel.getScheduleMsgSendTime = body.callbacks?.getScheduleMsgSendTime
        viewModel.getSendScheduleMsgIds = body.callbacks?.getSendScheduleMsgIds
        viewModel.autoFillTitle = body.autoFillTitle
        viewModel.supportRealTimeTranslate = body.supportRealTimeTranslate
        viewModel.translateService = body.translateService
        viewModel.applyTranslationCallback = body.callbacks?.applyTranslationCallback
        viewModel.recallTranslationCallback = body.callbacks?.recallTranslationCallback
        viewModel.isFromMsgThread = body.isFromMsgThread
        let swipContainer = SwipeContainerViewController(subViewController: vc)
        swipContainer.delegate = vc
        viewModel.rootVC = swipContainer

        let childController = vc.childController
        context.container.register(OpenKeyboardService.self) { [weak childController] (_) -> OpenKeyboardService in
            return childController ?? ComposeOpenKeyboardServiceEmptyIMP()
        }

        context.container.register(ComposeOpenKeyboardService.self) { [weak childController] (_) -> ComposeOpenKeyboardService in
            return childController ?? ComposeOpenKeyboardServiceEmptyIMP()
        }

        if let myAIInlineService = body.dataService.myAIInlineService {
            context.container.register(IMMyAIInlineService.self) { _ in
                return myAIInlineService
            }
        }

        let navContainer = LkNavigationController()
        navContainer.setViewControllers([swipContainer], animated: false)
        navContainer.modalPresentationStyle = .overFullScreen
        navContainer.navigationBar.isHidden = true
        res.end(resource: navContainer)
    }
}
