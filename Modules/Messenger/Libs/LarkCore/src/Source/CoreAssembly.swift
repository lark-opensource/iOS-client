//
//  CoreAssembly.swift
//  LarkCore
//
//  Created by liuwanlin on 2018/8/15.
//

import UIKit
import Foundation
import LarkContainer
import Swinject
import LarkModel
import EENavigator
import LarkFeatureGating
import LarkAccountInterface
import LarkSDKInterface
import LarkAppConfig
import LarkMessengerInterface
import LarkNavigation
import AnimatedTabBar
import RustPB
import ByteWebImage
import LarkRustClient
import LarkRichTextCore
import LarkShareContainer
import LarkSnsShare
import LarkSegmentedView
import LarkAssembler
import LarkEnv
import LarkReleaseConfig
import LarkKeyboardView
import LarkBaseKeyboard
import LarkSetting

public final class CoreAssembly: LarkAssemblyInterface {
    public init() {}

    public func registContainer(container: Container) {
        let user = container.inObjectScope(M.userScope)
        let userGraph = container.inObjectScope(M.userGraph)
        /// 拨打电话服务
        user.register(CallRequestService.self) { r in
            return CallRequest(userResolver: r, userAPI: try r.resolve(assert: ChatterAPI.self))
        }

        user.register(SubscribeChatEventService.self) { r in
            let subCenter = try r.resolve(assert: SubscriptionCenter.self)
            let chatAPI = try r.resolve(assert: ChatAPI.self)
            return SubscribeChatEventService(subCenter: subCenter, chatAPI: chatAPI)
        }

        userGraph.register(ChatPushWrapper.self) { (r, chat: Chat) in
            return try ChatPushWrapperImpl(userResolver: r, chat: chat)
        }

        userGraph.register(ThreadPushWrapper.self) { (r, thread: RustPB.Basic_V1_Thread, chat: Chat, forNormalChatMessage: Bool) in
            return ThreadPushWrapperImpl(userResolver: r, thread: thread, pushCenter: try r.userPushCenter, chat: chat, forNormalChatMessage: forNormalChatMessage)
        }

        userGraph.register(InAppShareService.self) { (r) in
            return InAppShareServiceImp(userResolver: r)
        }

        userGraph.register(TextToInlineService.self) { r in
            return try r.resolve(assert: MessageTextToInlineService.self)
        }
        userGraph.register(MessageTextToInlineService.self) { r in
            return try MessageTextToInlineService(userResolver: r)
        }

        userGraph.register(FontStyleInputService.self) { (_, supportCopyStyle: Bool) -> FontStyleInputService in
            return FontStyleInputServiceImp(supportCopyStyle: supportCopyStyle)
        }

        userGraph.register(LarkCoreVCDependency.self) { r -> LarkCoreVCDependency in
            try r.resolve(assert: LarkCoreDependency.self)
        }

        userGraph.register(LarkCoreAvatarDependency.self) { r -> LarkCoreAvatarDependency in
            try r.resolve(assert: LarkCoreDependency.self)
        }
    }

    public func registRouter(container: Container) {
        Navigator.shared.registerRoute.type(URLPreviewBody.self)
            .factory(URLPreviewHandler.init(resolver:))

        Navigator.shared.registerRoute.type(PlayWebVideoBody.self)
        .factory(cache: true, PlayWebVideoHandler.init(resolver:))
    }

    public func assembleShareContainer(resolver: Resolver) {
        LarkShareContainer.dependency = ShareContainerDependencyImpl(resolver: resolver) // TODO: 用户隔离
    }
}

final class ShareContainerDependencyImpl: ShareContainerDependency {

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    public func getShareViaChooseChatResource(
        by material: ShareViaChooseChatMaterial
    ) -> JXSegmentedListContainerViewListDelegate? {
        let config = material.config

        var body = ChatChooseBody(
            isWithinContainer: true,
            allowCreateGroup: config.allowCreateGroup,
            multiSelect: config.multiSelect,
            ignoreSelf: config.ignoreSelf,
            ignoreBot: config.ignoreBot,
            needSearchOuterTenant: config.needSearchOuterTenant,
            includeOuterChat: config.includeOuterChat,
            selectType: config.selectType.rawValue,
            confirmTitle: config.confirmTitle,
            confirmDesc: config.confirmDesc,
            showInputView: config.showInputView,
            blockingCallback: { (dict, _) in
                guard let dict = dict else { return .just(()) }

                let items = dict["items"] as? [[String: Any]]
                if let items = items {
                    let contexts = items.compactMap { (kv) -> ShareViaChooseChatMaterial.SelectContext? in
                        guard let type = kv["type"] as? Int,
                              let chatId = kv["chatid"] as? String else {
                            return nil
                        }
                        return ShareViaChooseChatMaterial.SelectContext(
                            itemType: ShareViaChooseChatMaterial.ItemType(rawValue: type) ?? .unknown,
                            chatId: chatId,
                            chatterId: kv["chatterid"] as? String,
                            avatarKey: kv["avatarKey"] as? String
                        )
                    }
                    if let attributedStr = dict["attributedInput"] as? NSAttributedString {
                        let input = dict["input"] as? String
                        var shareInput = ShareViaChooseChatMaterial.ShareInput()
                        shareInput.string = input
                        shareInput.attributedString = attributedStr
                        if attributedStr.length != 0 {
                            var richText = RichTextTransformKit.transformStringToRichText(string: attributedStr)
                            richText?.richTextVersion = 1
                            shareInput.richText = richText
                        }
                        return material.selectHandlerWithShareInput?(contexts, shareInput) ??
                        material.selectHandler(contexts, input)
                    }
                    return material.selectHandler(contexts, dict["input"] as? String)
                }

                return .just(())
            }
        )
        body.includeMyAI = true

        let resource = Navigator.shared.response(for: body).resource as? JXSegmentedListContainerViewListDelegate  // TODO: 用户隔离
        return resource
    }

    public func inappShareContext(
        with name: String,
        image: UIImage,
        needFilterExternal: Bool
    ) -> CustomShareContext {
        let inappShareService = resolver.resolve(InAppShareService.self)! // TODO: 用户隔离
        let content = ImageContentInLark(
            name: name,
            image: image,
            type: .normal,
            needFilterExternal: needFilterExternal,
            cancelCallBack: nil,
            successCallBack: nil
        )
        return inappShareService.genInAppShareContext(
            content: .image(content: content)
        )
    }

    public func inappShareContext(
        with name: String,
        image: UIImage,
        needFilterExternal: Bool,
        shareResultsCallBack: (([(String, Bool)]?) -> Void)?
    ) -> CustomShareContext {
        let inappShareService = resolver.resolve(InAppShareService.self)! // TODO: 用户隔离
        var content = ImageContentInLark(
            name: name,
            image: image,
            type: .normal,
            needFilterExternal: needFilterExternal,
            cancelCallBack: nil,
            successCallBack: nil
        )
        content.shareResultsCallBack = shareResultsCallBack
        return inappShareService.genInAppShareContext(
            content: .image(content: content)
        )
    }

    public func inappShareContext(with text: String) -> CustomShareContext {
        let inappShareService = resolver.resolve(InAppShareService.self)! // TODO: 用户隔离
        let content = TextContentInLark(
            text: text,
            sendHandler: nil
        )
        return inappShareService.genInAppShareContext(
            content: .text(content: content)
        )
    }

    public func inappShareContext(
        with text: String,
        shareResultsCallBack: (([(String, Bool)]?) -> Void)?
    ) -> CustomShareContext {
        let inappShareService = resolver.resolve(InAppShareService.self)! // TODO: 用户隔离
        var content = TextContentInLark(
            text: text,
            sendHandler: nil
        )
        content.shareResultsCallBack = shareResultsCallBack
        return inappShareService.genInAppShareContext(
            content: .text(content: content)
        )
    }
}

/// 用于FG控制UserResolver的迁移, 控制Resolver类型.
/// 使用UserResolver后可能抛错，需要控制对应的兼容问题
enum M {
    private static var userScopeFG: Bool {
        return FeatureGatingManager.shared.featureGatingValue(with: "lark.ios.messeger.userscope.refactor") // Global
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
