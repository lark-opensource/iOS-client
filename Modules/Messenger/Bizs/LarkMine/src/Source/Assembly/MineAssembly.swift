//
//  MineAssembly.swift
//  Lark
//
//  Created by 姚启灏 on 2018/6/20.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkModel
import LarkUIKit
import LarkRustClient
import LarkContainer
import RxSwift
import Swinject
import EENavigator
import LarkSetting
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkAppConfig
import LarkKeyCommandKit
import LarkNavigator
import LarkExtensions
import LarkGuide
import LarkCustomerService
import LarkLeanMode
import ServerPB
import LarkCore
import LarkReleaseConfig
import LarkNavigation
import LarkFocus
import RustPB
import ThreadSafeDataStructure
import UGBadge
import UGReachSDK
import LarkAppLinkSDK
import LarkVersion
import LarkAssembler
import EENotification
import LarkOpenSetting
import LarkContactComponent
import TangramService
import LarkPrivacySetting

public final class MineAssembly: LarkAssemblyInterface {
    public init() { }

    public func registContainer(container: Container) {
        let user = container.inObjectScope(.userV2)
        let userGraph = container.inObjectScope(.userGraph)

        user.register(MineSettingBadgeDependency.self) { (resolver) in
            let reachServiceImp = try resolver.resolve(assert: UGReachSDKService.self)
            let updateServiceImp = try resolver.resolve(assert: VersionUpdateService.self)
            return MineSettingBadgeDependencyImp(reachServiceImp: reachServiceImp, updateServiceImp: updateServiceImp)
        }

        user.register(MineSidebarService.self) { (resolver) in
            let passportAPI = try resolver.resolve(assert: PassportAPI.self)
            let pushCenter = try resolver.userPushCenter
            return MineSidebarServiceImpl(passportAPI: passportAPI, pushCenter: pushCenter)
        }

        user.register(SettingStoreService.self) { (resolver) in
            let passportUserService = try resolver.resolve(assert: PassportUserService.self)
            let provider = {
                return passportUserService.user.userID
            }
            return SettingStoreService(userIdProvider: provider)
        }

        user.register(AppLanguageService.self) { (resolver) in
            let configurationAPI = try resolver.resolve(assert: ConfigurationAPI.self)
            let navigator = resolver.navigator
            return AppLanguageServiceImpl(userNavigator: navigator, configurationAPI: configurationAPI)
        }

        user.register(LarkFocusAPI.self) { (resolver) in
            let rustService = try resolver.resolve(assert: RustService.self)
            return LarkFocusAPIImpl(client: rustService)
        }

        userGraph.register(MineMainRouter.self) { (resolver) -> MineMainRouter in
            return MineRouterFactory.create(with: resolver)
        }

        user.register(MinePersonalInformationRouter.self) { (resolver) -> MinePersonalInformationRouter in
            return MineRouterFactory.create(with: resolver)
        }

        user.register(MineTranslateSettingRouter.self) { (resolver) -> MineTranslateSettingRouter in
            return MineRouterFactory.create(with: resolver)
        }

        userGraph.register(MinePersonalInformationViewController.self) { resolver in
            let passportUserService = try resolver.resolve(assert: PassportUserService.self)
            let chatterAPI = try resolver.resolve(assert: ChatterAPI.self)
            let chatterManager = try resolver.resolve(assert: ChatterManagerProtocol.self)
            let minedataVM = MinePersonalInformationViewModel(
                userResolver: resolver,
                passportService: passportUserService,
                chatterAPI: chatterAPI,
                chatterManager: chatterManager
            )
            let vc = MinePersonalInformationViewController(viewModel: minedataVM)
            let router = try resolver.resolve(assert: MinePersonalInformationRouter.self)
            vc.router = router
            return vc
        }

        userGraph.register(WorkDescriptionSetController.self) { resolver in
            let viewModel = try WorkDescriptionViewModel(userResolver: resolver)
            let vc = WorkDescriptionSetController(viewModel: viewModel)
            return vc
        }

        userGraph.register(MineMainViewController.self) { resolver in
            let featureGatingService = try resolver.resolve(assert: FeatureGatingService.self)
            let featureSwitchEnable = featureGatingService.staticFeatureGatingValue(with: .ttPay)
            let featureGatingEnable = featureGatingService.staticFeatureGatingValue(with: .redPacket)
            // 租户维度的，非飞书租户即海外租户
            // See: https://bytedance.feishu.cn/docx/doxcnvLecLOb5K8uTcSvYYsnnHe
            let passportUserService = try resolver.resolve(assert: PassportUserService.self)
            let passportService = try resolver.resolve(assert: PassportService.self)
            let isOversea = !passportUserService.isFeishuBrand
            let isFeishu = ReleaseConfig.isFeishu
            let isByteDancer = passportUserService.userTenant.isByteDancer
            // 获取权限SDK支付开关，默认打开，无权限则不显示钱包入口
            let isPay = LarkPayAuthority.checkPayAuthority()

            let walletEnable: Bool = featureSwitchEnable && isFeishu &&
                (!isOversea || isByteDancer || featureGatingEnable) && isPay
            let authAPI = try resolver.resolve(assert: AuthAPI.self)
            let deviceService = try resolver.resolve(assert: DeviceManageServiceProtocol.self)
            let userGeneralSettings = try resolver.resolve(assert: UserGeneralSettings.self)
            let versionUpdateService = try resolver.resolve(assert: VersionUpdateService.self)
            let chatterAPI = try resolver.resolve(assert: ChatterAPI.self)
            let guideService = try resolver.resolve(assert: NewGuideService.self)
            let oncallAPI = try resolver.resolve(assert: OncallAPI.self)
            let customerServiceAPI = try resolver.resolve(assert: LarkCustomerServiceAPI.self)
            let mineSidebarService = try resolver.resolve(assert: MineSidebarService.self)
            let leanModeStatus = try resolver.resolve(assert: LeanModeService.self).leanModeStatus
            let chatterManager = try resolver.resolve(assert: ChatterManagerProtocol.self)
            let badgeDependency = try resolver.resolve(assert: MineSettingBadgeDependency.self)
            let tenantNameService = try resolver.resolve(assert: LarkTenantNameService.self)
            let inlineService = try resolver.resolve(assert: MessageTextToInlineService.self)
            let payManagerService = try resolver.resolve(assert: PayManagerService.self)

            let mineMainVM = MineMainViewModel(
                walletEnable: walletEnable,
                authAPI: authAPI,
                passportService: passportService,
                passportUserService: passportUserService,
                deviceService: deviceService,
                userGeneralSettings: userGeneralSettings,
                versionUpdateService: versionUpdateService,
                chatterAPI: chatterAPI,
                guideService: guideService,
                oncallAPI: oncallAPI,
                customerServiceAPI: customerServiceAPI,
                mineSidebarService: mineSidebarService,
                leanModeStatus: leanModeStatus,
                chatterManager: chatterManager,
                badgeDependency: badgeDependency,
                inlineService: inlineService,
                tenantNameService: tenantNameService,
                payManagerService: payManagerService,
                userResolver: resolver
            )
            let vc = MineMainViewController(viewModel: mineMainVM)
            return vc
        }
    }

    public func registRouter(container: Container) {
        getRegistRouter(container: container)
    }

    private func getRegistRouter(container: Container) -> Router {
        Navigator.shared.registerRoute.type(MineMainBody.self)
                    .factory(MineMainHandler.init(resolver:))

        // 翻译设置
        Navigator.shared.registerRoute.type(TranslateSettingBody.self)
            .factory(TranslateSettingHandler.init(resolver:))

        // 翻译目标语言设置
        Navigator.shared.registerRoute.type(TranslateTargetLanguageSettingBody.self)
            .factory(TranslateTargetLanguageSettingHandler.init(resolver:))

        // 对外时区设置设置
        Navigator.shared.registerRoute.type(ShowTimeZoneWithOtherBody.self)
            .factory(cache: true, ShowTimeZoneWithOtherHandler.init(resolver:))

        // 个人信息
        Navigator.shared.registerRoute.type(MinePersonalInformationBody.self)
            .factory(MinePersonalInformationViewControllerHandler.init(resolver:))

        // 修改name
        Navigator.shared.registerRoute.type(SetNameControllerBody.self)
            .factory(SetNameViewControllerHandler.init(resolver:))

        // 工作状态
        Navigator.shared.registerRoute.type(WorkDescriptionSetBody.self)
            .factory(WorkDescriptionSetViewControllerHandler.init(resolver:))

        // 语言与文字
        Navigator.shared.registerRoute.type(MineLanguageSettingBody.self)
            .factory(MineLanguageSettingViewControllerHandler.init(resolver:))

        // 不自动翻译语言设置
        Navigator.shared.registerRoute.type(DisableAutoTranslateLanguagesSettingBody.self)
            .factory(DisableAutoTranslateLanguagesSettingControllerHandler.init(resolver:))

        // 翻译效果高级设置
        Navigator.shared.registerRoute.type(LanguagesConfigurationSettingBody.self)
            .factory(LanguagesConfigurationSettingControllerHandler.init(resolver:))

        // setText
        Navigator.shared.registerRoute.type(SetTextBody.self)
            .factory(SetTextHandler.init(resolver:))

        // setWebLink
        Navigator.shared.registerRoute.type(SetWebLinkBody.self)
            .factory(SetWebLinkHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MineAboutLarkBody.self)
            .factory(MineAboutLarkHandler.init(resolver:))

        Navigator.shared.registerRoute.type(MineCapabilityPermissionBody.self)
            .factory(MineCapabilityPermissionHandler.init(resolver:))

        // 效率设置
        Navigator.shared.registerRoute.type(EfficiencySettingBody.self)
            .factory(EfficiencySettingHandler.init(resolver:))

        // 通用设置
        Navigator.shared.registerRoute.type(MineGeneralSettingBody.self)
            .factory(MineGeneralSettingHandler.init(resolver:))

        // 隐私设置
        Navigator.shared.registerRoute.type(PrivacySettingBody.self)
            .factory(PrivacySettingSettingHandler.init(resolver:))

        // 添加我的方式设置
        Navigator.shared.registerRoute.type(AddMeWaySettingBody.self)
            .factory(AddMeWaySettingHandler.init(resolver:))

        // 系统设置
        Navigator.shared.registerRoute.type(MineSettingBody.self)
            .factory(MineSettingViewControllerHandler.init(resolver:))

        // 内部设置
        Navigator.shared.registerRoute.type(InnerSettingBody.self)
            .factory(InnerSettingViewControllerHandler.init(resolver:))

        // 字体大小设置
        Navigator.shared.registerRoute.type(MineFontSettingBody.self)
            .factory(FontSettingControllerHandler.init(resolver:))

        // 星标联系人(特别关注)
        Navigator.shared.registerRoute.type(SpecialFocusSettingBody.self)
            .factory(SpecialFocusSettingHandler.init(resolver:))

        // 接收其他账号消息
        Navigator.shared.registerRoute.type(MultiUserNotificationBody.self)
            .factory(MultiUserNotificationSettingHandler.init(resolver:))

        // 通知诊断
        Navigator.shared.registerRoute.type(NotificationDiagnosisBody.self)
            .factory(NotificationDiagnosisHandler.init(resolver:))

        // 通知设置
        Navigator.shared.registerRoute.type(MineNotificationSettingBody.self)
            .factory(MineSettingNotificationHandler.init(resolver:))

        // 网络诊断
        return Navigator.shared.registerRoute.type(NetDiagnoseSettingBody.self)
            .factory(NetDiagnoseSettingControllerHandler.init(resolver:))
    }

    public func registRustPushHandlerInUserSpace(container: Container) {
        (Command.pushUserSidebar, PushMineSidebarHandler.init(resolver:))
        (Command.pushLarkApiReachable, PushLarkApiReachableHandler.init(resolver:))
        (Command.pushMultiNetStateChanged, PushMultiNetChangedHandler.init(resolver:))
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            MineLauncherDelegate(resolver: container)
        }, LauncherDelegateRegisteryPriority.low)
    }

    public func registLarkAppLink(container: Container) {
        /// 添加我的方式设置
        LarkAppLinkSDK.registerHandler(path: AddMeWaySettingBody.appLinkPattern, handler: { (appLink) in
            guard let from = appLink.context?.from() else { return }
            let body = AddMeWaySettingBody()
            Navigator.shared.push(body: body, from: from)
        })

        /// 对外展示时区设置
        LarkAppLinkSDK.registerHandler(path: ShowTimeZoneWithOtherBody.appLinkPattern, handler: { (appLink) in
            guard let from = appLink.context?.from() else { return }
            let body = ShowTimeZoneWithOtherBody()
            Navigator.shared.push(body: body, from: from)
        })

        // MARK: 飞书设置页面支持 Applink 跳转链接 一期 https://bytedance.feishu.cn/docx/doxcnFuoaGTyCQgBlprR1v9Siwf
        /// 设置页 appLink 注册
        /// 三端设置页 applink 使用统一跳转规则。https://bytedance.feishu.cn/docx/doxcn6zNMwG1QHSpMPQqyugjge8
        /// `MineSettingBody.appLinkPattern` 为设置页统一路由，其他页面作为参数传入
        LarkAppLinkSDK.registerHandler(path: MineSettingBody.appLinkPattern, handler: { (appLink) in
            guard let from = appLink.context?.from() else { return }

            guard let page = MineAppLinkPage.mapping(url: appLink.url.absoluteString) else { return }
            switch page {
            case .general:
                let body = MineGeneralSettingBody()
                Navigator.shared.push(body: body, from: from)
            case .fontSize:
                let body = MineFontSettingBody()
                Navigator.shared.present(body: body,
                                         wrap: LkNavigationController.self,
                                         from: from,
                                         prepare: { $0.modalPresentationStyle = .formSheet })
            case .netDiagnose:
                let body = NetDiagnoseSettingBody(from: .app_link)
                Navigator.shared.push(body: body, from: from)
            case .notification:
                let body = MineNotificationSettingBody()
                Navigator.shared.push(body: body, from: from)
            case .pushDiagnose:
                let body = NotificationDiagnosisBody()
                Navigator.shared.push(body: body, from: from)
            case .innerSetting:
                let body = InnerSettingBody()
                Navigator.shared.push(body: body, from: from)
            case .about:
                let body = MineAboutLarkBody()
                Navigator.shared.push(body: body, from: from)
            }
        })
    }
}
