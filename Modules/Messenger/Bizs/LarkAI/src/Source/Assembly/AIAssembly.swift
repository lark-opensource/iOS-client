//
//  AIAssembly.swift
//  LarkAI
//
//  Created by bytedance on 2020/9/21.
//

import Foundation
import UIKit
import Swinject
import LarkMessengerInterface
import LarkQRCode
import LarkRustClient
import LarkAssembler
import EENavigator
import LarkSearchCore
import LarkAppLinkSDK
import LarkContainer
import LarkOpenSetting
import LarkKAFeatureSwitch
import LarkQuickLaunchBar
import LarkSDKInterface
import LarkAIInfra
import LarkOpenChat
import LarkFeatureGating
import LarkMessageBase
import LarkMessageCore
import LKCommonsLogging

public final class AIAssembly: LarkAssemblyInterface {
    var logger = Logger.log(AIAssembly.self, category: "LarkAI.Assembly")
    public init() { }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(AIContainer.userScope)
        let userGraph = container.inObjectScope(AIContainer.userGraph)
        user.register(TranslateFeedbackService.self) { (r) in
            let translateDependency = try TranslateServiceDependency(resolver: r)
            return TranslateServiceImp(dependency: translateDependency)
        }
        user.register(SelectTranslateService.self) { (r) in
            return SelectTranslateServiceImp(resolver: r)
        }
        user.register(EnterpriseEntityWordService.self) { (r) in
            return EnterpriseEntityWordServiceImpl(resolver: r)
        }
        userGraph.register(SmartCorrectService.self) { (r) in
            return SmartCorrectServiceImpl(resolver: r)
        }
        userGraph.register(LingoHighlightService.self) { (r) in
            return LingoHighlightServiceImpl(resolver: r)
        }
        userGraph.register(SmartComposeService.self) { (r) in
            return SmartComposeServiceImpl(resolver: r)
        }
        userGraph.register(AICalendarDependency.self) { (r) -> AICalendarDependency in
            let context = try r.resolve(assert: AIDependency.self)
            return context
        }
        userGraph.register(OCRDependency.self) { (r) -> OCRDependency in
            let context = try r.resolve(assert: AIDependency.self)
            return context
        }
        // MyAIQuickLaunchBar服务
        user.register(MyAIQuickLaunchBarService.self) { _ in
            return MyAIQuickLaunchBarServiceImpl()
        }
        // MyAI服务
        user.register(MyAIService.self) { (r) in MyAIServiceImpl(userResolver: r) }
        user.register(MyAIOnboardingService.self) { (r) in try r.resolve(assert: MyAIService.self) }
        user.register(MyAIInfoService.self) { (r) in try r.resolve(assert: MyAIService.self) }
        user.register(MyAIChatModeService.self) { (r) in try r.resolve(assert: MyAIService.self) }
        user.register(MyAIExtensionService.self) { (r) in try r.resolve(assert: MyAIService.self) }
        user.register(MyAISceneService.self) { (r) in try r.resolve(assert: MyAIService.self) }
        // MyAI接口
        user.register(MyAIAPI.self) { (r) in RustMyAIAPI(userResolver: r) }
        user.register(MyAIToolsService.self) { _ in MyAIToolsServiceImp() }
        user.register(RustMyAIToolServiceAPI.self) { (r) in RustMyAIToolServiceImpl(userResolver: r) }
        // 浮窗组件at人
        user.register(InlineAIMentionUserService.self) { (r) in InlineAIMentionUserServiceImpl(userResolver: r) }
    }

    @_silgen_name("Lark.ChatCellFactory.Messenger.LarkAI")
    static public func cellFactoryRegister() {
        // NewChat - 消息Cell
        ChatMessageSubFactoryRegistery.register(ActionButtonComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(FeedbackRegenerateComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(ReferenceListComponentFactory.self)
        ChatMessageSubFactoryRegistery.register(SelectTranslateFactory.self)
        ChatMessageSubFactoryRegistery.register(QuickActionComponentFactory.self)
        // NewChat - 导航栏，left复用Chat的，content自己定制，right没有任何按钮
        ChatModeNavigationBarModule.registerLeftSubModule(ChatNavigationBarLeftItemSubModule.self)
        ChatModeNavigationBarModule.registerLeftSubModule(NavigationBarCloseSceneItemSubModule.self)
        ChatModeNavigationBarModule.registerContentSubModule(ChatModeNavgationBarContentSubModule.self)
    }

    public func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: "/client/abbreviation/open") { (appLink) in
            var queryString = ""
            var abbrId = ""
            var params = ""
            if let query = appLink.url.queryParameters["query"] {
                queryString = query
            }
            if let abbId = appLink.url.queryParameters["abbrId"] {
                abbrId = abbId
            }

            if let analysisParams = appLink.url.queryParameters["analysisParams"] {
                params = analysisParams
            }
            let userResolver = container.getCurrentUserResolver()
            if let from = appLink.context?.from()?.fromViewController {
                (try? userResolver.resolve(assert: EnterpriseEntityWordService.self))?.showEnterpriseTopic(
                    abbrId: abbrId,
                    query: queryString,
                    chatId: nil,
                    sense: .messenger,
                    targetVC: from,
                    completion: nil,
                    analysisParams: params,
                    passThroughAction: nil,
                    didTapApplink: nil
                )
            } else {
                assertionFailure()
            }

        }
        LarkAppLinkSDK.registerHandler(path: "/client/myai/onboarding") { (appLink) in
            guard let aiService = try? container.getCurrentUserResolver().resolve(assert: MyAIService.self) else { return }
            // MyAI FG 关闭情况下，不响应 AppLink
            guard aiService.enable.value else { return }
            guard let from = appLink.context?.from() else { return }
            aiService.openOnboarding(from: from, onSuccess: nil, onError: nil, onCancel: nil)
        }
        LarkAppLinkSDK.registerHandler(path: "/client/myai/link") { [weak self, weak container] applink in
            guard let type = applink.url.queryParameters["type"] else {
                self?.logger.error("applink /client/myai/link no type")
                return
            }
            guard let userResolver = container?.getCurrentUserResolver() else {
                self?.logger.error("applink /client/myai/link no userResolver")
                return
            }
            guard let fromVC = applink.fromControler else {
                self?.logger.error("applink /client/myai/link no userResolver")
                return
            }

            if type == "link" {
                self?.logger.info("applink /client/myai/link type: link")
                guard let value = applink.url.queryParameters["value"] else {
                    self?.logger.error("applink /client/myai/link type: link, but no value")
                    return
                }
                guard let url = try? URL.forceCreateURL(string: value) else {
                    self?.logger.error("applink /client/myai/link type: link, but trans to URL fail")
                    return
                }
                userResolver.navigator.open(url, context: applink.context ?? [:], from: fromVC)
            } else if type == "file" {
                self?.logger.info("applink /client/myai/link type: file")
                assertionFailure("Not yet implemented")
            } else {
                self?.logger.error("applink /client/myai/link unknown type")
            }
        }
        // 通过 AppLink 收藏场景（外显 AppLink，myai -> ai-companion，7.6 以前版本兼容）
        LarkAppLinkSDK.registerHandler(path: "/client/myai/scene/add") { [weak container] appLink in
            guard let container = container else { return }
            // 判断 MyAI 的开关
            guard let aiService = try? container.getCurrentUserResolver().resolve(assert: MyAIService.self) else { return }
            // 执行收藏行为
            guard let from = appLink.context?.from() else { return }
            aiService.handleSceneAddByApplink(appLink.url, from: from)
        }
        // 通过 AppLink 收藏场景（外显 AppLink，myai -> ai-companion，7.7 及以后版本生效）
        LarkAppLinkSDK.registerHandler(path: "/client/ai-companion/scene/add") { [weak container] appLink in
            guard let container = container else { return }
            // 判断 MyAI 的开关
            guard let aiService = try? container.getCurrentUserResolver().resolve(assert: MyAIService.self) else { return }
            // 执行收藏行为
            guard let from = appLink.context?.from() else { return }
            aiService.handleSceneAddByApplink(appLink.url, from: from)
        }
    }

    public func registServerPushHandlerInUserSpace(container: Container) {
        (ServerCommand.pushAsSetting, EnterpriseEntityWordSettingPushHandler.init(resolver:))
        (ServerCommand.pushGecSetting, SmartCorrectPushHandler.init(resolver:))
        (ServerCommand.pushComposerSetting, SmartComposePushHandler.init(resolver:))
    }

    @_silgen_name("Lark.OpenSetting.AISetting")
    public static func pageFactoryRegister() {
        // 内容翻译
        PageFactory.shared.register(page: .general, moduleKey: ModulePair.General.translation.moduleKey) { userResolver in
            guard AIFeatureGating.enableTranslate.isUserEnabled(userResolver: userResolver) else {
                return nil
            }
            return GeneralBlockModule(
                userResolver: userResolver,
                title: BundleI18n.LarkAI.Lark_NewSettings_ContentTranslationMobile) { (userResolver, from) in
                    userResolver.navigator.push(body: TranslateSettingBody(), from: from)
            }
        }
        // 企业百科
        PageFactory.shared.register(page: .efficiency, moduleKey: ModulePair.Efficiency.enterpriseEntity.moduleKey, provider: { userResolver in
            EnterpriseEntityModule(userResolver: userResolver)
        })
        // 智能纠错
        PageFactory.shared.register(page: .efficiency, moduleKey: ModulePair.Efficiency.smartCorrection.moduleKey, provider: { userResolver in
            SmartCorrectionModule(userResolver: userResolver)
        })

        /// 智能补全
        PageFactory.shared.register(page: .efficiency, moduleKey: ModulePair.Efficiency.smartComposeMessenger.moduleKey, provider: { userResolver in
            SmartComposeModule(userResolver: userResolver)
        })
    }

    public func registRouter(container: Container) {
        // AI Onboarding 页面
        Navigator.shared.registerRoute.type(MyAIOnboardingBody.self)
            .factory(MyAIOnboardingHandler.init(resolver:))
        // AI 头像/名称设置页面
        Navigator.shared.registerRoute.type(MyAISettingBody.self)
            .factory(MyAIProfileSettingHandler.init(resolver:))
        // AITools选择页面
        Navigator.shared.registerRoute.type(MyAIToolsBody.self)
            .factory(MyAIToolsHandler.init(resolver:))
        // AITools已选择页面
        Navigator.shared.registerRoute.type(MyAIToolsSelectedBody.self)
            .factory(MyAIToolsSelectedHandler.init(resolver:))
        // MyAI踩反馈页面
        Navigator.shared.registerRoute.type(MyAIAnswerFeedbackBody.self)
            .factory(MyAIAnswerFeedbackHandler.init(resolver:))
        // AITools详情页面
        Navigator.shared.registerRoute.type(MyAIToolsDetailBody.self)
            .factory(MyAIToolsDetailHandler.init(resolver:))
    }
}

public enum AIContainer {
    private static var userScopeFG: Bool {

        let v = Container.shared.getCurrentUserResolver().fg.dynamicFeatureGatingValue(with: "ios.container.scope.user.ai")
        return v
    }
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}
