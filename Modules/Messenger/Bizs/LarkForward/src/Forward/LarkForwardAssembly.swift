//
//  LarkForward+Component.swift
//  LarkForward
//
//  Created by zc09v on 2018/8/1.
//

import Foundation
import LarkContainer
import LarkModel
import LarkExtensionCommon
import Swinject
import LarkCore
import EENavigator
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import RxSwift
import Homeric
import LKCommonsTracker
import LKCommonsLogging
import LarkQRCode
import LarkFeatureGating
import LarkUIKit
import LarkAccountInterface
import ByteWebImage
import LarkAssembler
import BootManager
import LarkNavigator
import LarkSetting

public final class LarkForwardAssembly: LarkAssemblyInterface {

    public func registContainer(container: Container) {
        let resolver = container
        let userScope = container.inObjectScope(ForwardUserScope.userScope)
        let userGraph = container.inObjectScope(ForwardUserScope.userGraph)

        container.inObjectScope(.userV2).register(ForwardViewControllerRouter.self) { r -> ForwardViewControllerRouter in
            return ForwardViewControllerRouterImpl(userResolver: r)
        }

        container.inObjectScope(.userV2).register(ForwardViewControllerRouterProtocol.self) { r -> ForwardViewControllerRouterProtocol in
            return ForwardViewControllerRouterImpl(userResolver: r)
        }

        userGraph.register(ForwardViewControllerService.self) { r -> ForwardViewControllerService in
            return ForwardViewControllerServiceImpl(resolver: r)
        }

        userScope.register(ForwardService.self) { r in
            let chatAPI = try r.resolve(assert: ChatAPI.self)
            let sendMessageAPI = try r.resolve(assert: SendMessageAPI.self)
            let imageProcessor = try r.resolve(assert: SendImageProcessor.self)
            let sendThreadAPI = try r.resolve(assert: SendThreadAPI.self)
            let messageAPI = try r.resolve(assert: MessageAPI.self)
            let rustService = try r.resolve(assert: SDKRustService.self)
            let passportUserService = try r.resolve(assert: PassportUserService.self)
            return ForwardServiceImpl(chatAPI: chatAPI,
                                      sendMessageAPI: sendMessageAPI,
                                      imageProcessor: imageProcessor,
                                      sendThreadAPI: sendThreadAPI,
                                      messageAPI: messageAPI,
                                      rustService: rustService,
                                      passportUserService: passportUserService)
        }
    }

    public func registRouter(container: Container) {
        let resolver = container

        /// TODO: 暂时先wrappper下做注册
        let wrapperURL: () -> Router = {
            LarkQRCode.appendForcePresentURL("feishu:" + ShareMeetingBody.pattern)
            return Router()
        }
        wrapperURL()

        Navigator.shared.registerRoute.type(ForwardLocalFileBody.self).factory(ForwardLocalFileHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ForwardMessageBody.self).factory(ForwardMessageHandler.init(resolver:))
        Navigator.shared.registerRoute.type(MergeForwardMessageBody.self).factory(MergeForwardHandler.init(resolver:))
        Navigator.shared.registerRoute.type(BatchTransmitMessageBody.self).factory(BatchTransmitHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ForwardCopyFromFolderMessageBody.self).factory(ForwardCopyFromFolderMessageHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ChatChooseBody.self).factory(ChatChooseHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ShareChatBody.self).factory(cache: true, ShareChatHandler.init)
        Navigator.shared.registerRoute.type(ShareChatViaLinkBody.self).factory(cache: true, ShareChatViaLinkHandler.init)
        Navigator.shared.registerRoute.type(EventShareBody.self).factory(EventShareHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ShareContentBody.self).factory(ShareContentHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ForwardTextBody.self).factory(ForwardTextHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ForwardLingoBody.self).factory(ForwardLingoHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ForwardFileBody.self).factory(ForwardFileHandler.init(resolver:))
        Navigator.shared.registerRoute.type(OpenShareBody.self).factory(OpenShareHandler.init(resolver:))
        Navigator.shared.registerRoute.type(AppCardShareBody.self).factory(ShareAppCardHandler.init(resolver:))
        Navigator.shared.registerRoute.type(MailMessageShareBody.self).factory(ShareMailMessageHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ShareMailAttachementBody.self).factory(ShareMailAttachmentHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ShareExtensionBody.self).factory(cache: true, { ShareExtensionHandler(userResolver: $0, config: ShareExtensionConfig.share) })
        Navigator.shared.registerRoute.type(ShareImageBody.self).factory(ShareImageHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ShareThreadTopicBody.self).factory(ShareThreadTopicHandler.init(resolver:))
        Navigator.shared.registerRoute.type(EmotionShareBody.self).factory(EmotionShareHandler.init(resolver:))
        Navigator.shared.registerRoute.type(SendSingleEmotionBody.self).factory(SendSingleEmotionHandler.init(resolver:))
        Navigator.shared.registerRoute.type(EmotionShareToPanelBody.self).factory(EmotionShareToPanelHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ShareUserCardBody.self).factory(cache: true, ShareUserCardHandler.init)
        Navigator.shared.registerRoute.type(ShareMomentsPostBody.self).factory(ShareMomentsPostHandler.init(resolver:))
        Navigator.shared.registerRoute.type(AtUserBody.self).factory(AtUserHandler.init(resolver:))
        Navigator.shared.registerRoute.type(ForwardMentionBody.self).factory(ForwardMentionHandler.init(resolver:))
    }

    public func registURLInterceptor(container: Container) {
        // 分享
        (ShareContentBody.pattern, { (url: URL, from: NavigatorFrom) in
            container.getCurrentUserResolver(compatibleMode: ForwardUserScope.userScopeCompatibleMode).navigator.present(
                url,
                from: from,
                prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
            )
        })
        // h5 h5app 小程序 分享
        (AppCardShareBody.pattern, { (url: URL, from: NavigatorFrom) in
            container.getCurrentUserResolver(compatibleMode: ForwardUserScope.userScopeCompatibleMode).navigator.present(
                url,
                from: from,
                prepare: { $0.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen }
            )
        })
        // 系统分享
        (ShareExtensionBody.pattern, { (url: URL, from: NavigatorFrom) in
            container.getCurrentUserResolver(compatibleMode: ForwardUserScope.userScopeCompatibleMode).navigator.open(url, from: from)
        })

        // 外部通过飞书SDK分享
        (OpenShareBody.pattern, { (url: URL, from: NavigatorFrom) in
            func dissAll(completion: (() -> Void)? = nil) {
                if let alert = container.getCurrentUserResolver(compatibleMode: ForwardUserScope.userScopeCompatibleMode).navigator.navigation?.presentedViewController {
                    alert.dismiss(animated: false) {
                        dissAll(completion: completion)
                    }
                } else {
                    if let completion = completion {
                        completion()
                    }
                }
            }
            dissAll {
                //防止启动时forward页面拿不到最近聊天记录白屏,
                // nolint: magic_number
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.4) {
                    container.getCurrentUserResolver(compatibleMode: ForwardUserScope.userScopeCompatibleMode).navigator.present(
                        url,
                        from: from,
                        prepare: { $0.modalPresentationStyle = .fullScreen }
                    )
                }
                //enable-lint: magic_number
            }
        })
    }

    /// 用来注册AlertProvider的类型
    @_silgen_name("Lark.LarkForward_LarkForwardMessageAssembly_regist.LarkForwardAssembly")
    public static func providerRegister() {
        ForwardAlertFactory.register(type: MergeForwardAlertProvider.self)
        ForwardAlertFactory.register(type: MessageForwardAlertProvider.self)
        ForwardAlertFactory.register(type: BatchTransmitAlertProvider.self)
        ForwardAlertFactory.register(type: ForwardCopyFromFolderMessageAlertProvider.self)
        ForwardAlertFactory.register(type: ChatChooseAlertProvider.self)
        ForwardAlertFactory.register(type: ShareChatAlertProvider.self)
        ForwardAlertFactory.register(type: ShareContentAlertProvider.self)
        ForwardAlertFactory.register(type: ForwardTextAlertProvider.self)
        ForwardAlertFactory.register(type: ShareExtensionAlertProvider.self)
        ForwardAlertFactory.register(type: ShareImageAlertProvider.self)
        ForwardAlertFactory.register(type: EventShareAlertProvider.self)
        ForwardAlertFactory.register(type: ShareAppCardAlertProvider.self)
        ForwardAlertFactory.register(type: ShareThreadTopicAlertProvider.self)
        ForwardAlertFactory.register(type: EmotionShareProvider.self)
        ForwardAlertFactory.register(type: EmotionShareToPanelProvider.self)
        ForwardAlertFactory.register(type: SendSingleEmotionProvider.self)
        ForwardAlertFactory.register(type: ShareMailMessageProvider.self)
        ForwardAlertFactory.register(type: OpenShareForwardAlertProvider.self)
        ForwardAlertFactory.register(type: ShareUserCardAlertProvider.self)
        ForwardAlertFactory.register(type: ShareMailAttachmentProvider.self)
        ForwardAlertFactory.register(type: ForwardFileAlertProvider.self)
        ForwardAlertFactory.register(type: ForwardLingoAlertProvider.self)
        //转发组件新参数结构
        ForwardAlertFactory.registerAlertConfig(alertConfigType: MessageForwardAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: MergeForwardAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: BatchTransmitAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: ShareImageAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: ShareChatAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: ShareContentAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: ForwardTextAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: SendSingleEmotionConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: ShareUserCardAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: ForwardFileAlertConfig.self)
        ForwardAlertFactory.registerAlertConfig(alertConfigType: ForwardLingoAlertConfig.self)
    }

    public func registLaunch(container: Swinject.Container) {
        NewBootManager.register(ForwardSetupTask.self)
    }

    public init() {}
}

public enum ForwardUserScope {
    static let enableUserScope: Bool = {
        let flag = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.forward") //Global
        return flag
    }()

    static var userScopeCompatibleMode: Bool { !enableUserScope }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。旧的注册没有指定 scope 的默认为 .graph
    static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
