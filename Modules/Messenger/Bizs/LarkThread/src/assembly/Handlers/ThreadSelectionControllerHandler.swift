//
//  ThreadSelectionControllerHandler.swift
//  LarkThread
//
//  Created by lizhiqiang on 2020/1/6.
//

import UIKit
import Foundation
import Swinject
import LarkCore
import LarkUIKit
import LarkModel
import EENavigator
import LarkMessageBase
import LarkMessageCore
import LarkSDKInterface
import LarkFeatureGating
import LarkAccountInterface
import LarkAttachmentUploader
import LarkMessengerInterface
import LarkSendMessage
import LarkStorage
import ByteWebImage
import LarkBaseKeyboard
import LarkOpenKeyboard
import LarkChatOpenKeyboard
import AppContainer
import LarkOpenIM
import LarkNavigator
import LarkSetting

/// 小组界面，发帖
final class ThreadChatComposePostHandler: UserTypedRouterHandler {
    static func compatibleMode() -> Bool { Thread.userScopeCompatibleMode }
    func handle(_ body: ThreadChatComposePostBody, req: Request, res: Response) throws {
        let userPushCenter = try userResolver.userPushCenter
        let docAPI = try userResolver.resolve(assert: DocAPI.self)
        let featureGating = try userResolver.resolve(assert: FeatureGatingService.self)
        let userSpaceService = try resolver.resolve(assert: UserSpaceService.self)

        let chat = body.chat
        let chatWrapper = try resolver.resolve(assert: ChatPushWrapper.self, argument: chat)
        let postDraftName = ComposePostViewModel.postDraftFileKey(id: .chat(chatId: chat.id))
        let attachmentUploader = try resolver.resolve(assert: AttachmentUploader.self, argument: postDraftName)
        let attachmentServer = PostAttachmentManager(attachmentUploader: attachmentUploader)
        let draftCache = try resolver.resolve(assert: DraftCache.self)
        let modelService = try resolver.resolve(assert: ModelService.self)
        let transcodeService = try resolver.resolve(assert: VideoTranscodeService.self)
        let pushChannelMessage = userPushCenter.driver(for: PushChannelMessage.self)
        let postSendService = try resolver.resolve(assert: PostSendService.self)
        let tenantUniversalSettingService = try resolver.resolve(assert: TenantUniversalSettingService.self)
        // 小组需要不同的占位符
        var placeholder = NSAttributedString(string: BundleI18n.LarkThread.Lark_Group_NewTopicRichtextTip)
        if body.multiEditingMessage != nil {
            placeholder = NSAttributedString(string: BundleI18n.LarkThread.Lark_IM_EditMessage_DeleteAllAndRecall_EnterNewMessage_Placeholder)
        } else if let tenantPlaceholder = tenantUniversalSettingService.getInputBoxPlaceholder() {
            if tenantUniversalSettingService.replaceTenantPlaceholderEnable() {
                placeholder = NSAttributedString(string: tenantPlaceholder)
            } else {
                let muattr = NSMutableAttributedString(attributedString: placeholder)
                let font = ComposePostViewController.Cons.textFont
                muattr.append(TextSplitConstructor.splitTextAttributeStringFor(font: font))
                muattr.append(NSAttributedString(string: tenantPlaceholder))
                placeholder = muattr
            }
        }

        let isKeyboardNewStyleEnable = KeyboardDisplayStyleManager.isNewKeyboadStyle()

        let context = IMComposeKeyboardContext(parent: Container(parent: BootLoader.container), store: .init(),
                                               userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        IMTopicComposeKeyboardModule.onLoad(context: context)
        IMTopicComposeKeyboardModule.registGlobalServices(container: context.container)
        let keyboardModule = IMTopicComposeKeyboardModule(context: context)

        let viewModel = ComposePostViewModel(
            userResolver: self.userResolver,
            module: keyboardModule,
            chatWrapper: chatWrapper,
            defaultContent: nil,
            draftCache: draftCache,
            modelService: modelService,
            transcodeService: transcodeService,
            docAPI: docAPI,
            attachmentServer: attachmentServer,
            pushChannelMessage: pushChannelMessage,
            reeditContent: nil,
            userSpaceURL: userSpaceService.currentUserDirectory,
            supportVideoContent: true,
            isKeyboardNewStyleEnable: isKeyboardNewStyleEnable,
            placeholder: placeholder,
            pasteBoardToken: body.pasteBoardToken,
            chatFromWhere: .ignored
        )
        if let editMessage = body.multiEditingMessage {
            viewModel.keyboardStatusManager.switchJob(.multiEdit(message: editMessage))
        }

        let router = try resolver.resolve(assert: ComposePostRouter.self)
        let chatAPI = try resolver.resolve(assert: ChatAPI.self)

        let isPad = Display.pad
        let rootVC = TopicController(
            userResolver: userResolver,
            chatApi: chatAPI,
            router: router,
            viewModel: viewModel,
            postSendService: postSendService,
            isDefaultTopicGroup: body.isDefaultTopicGroup,
            isPadPageStyle: isPad
        )
        let composePostController = rootVC.composePostController
        context.container.register(ComposeOpenKeyboardService.self) { [weak composePostController] (_) -> ComposeOpenKeyboardService in
            return composePostController ?? ComposeOpenKeyboardServiceEmptyIMP()
        }

        context.container.register(OpenKeyboardService.self) { [weak composePostController] (_) -> OpenKeyboardService in
            return composePostController ?? ComposeOpenKeyboardServiceEmptyIMP()
        }

        if isPad {
            let container = PadLargeModalViewController()
            container.childVC = rootVC
            container.delegate = rootVC
            weak var containerWeak = container
            rootVC.dismissCallBack = {
                containerWeak?.dismissSelf()
            }
            router.rootVCBlock = { [weak container] in
                return container
            }
            res.end(resource: container)
        } else {
            let container = LkNavigationController()
            container.modalPresentationStyle = .fullScreen
            container.setViewControllers([rootVC], animated: false)
            router.rootVCBlock = { [weak rootVC] in
                return rootVC
            }
            res.end(resource: container)
        }
    }
}
