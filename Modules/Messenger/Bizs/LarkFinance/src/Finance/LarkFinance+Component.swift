//
//  LarkFinance+Component.swift
//  Pods
//
//  Created by ChalrieSu on 2018/10/18.
//

import LarkEnv
import RxRelay
import Foundation
import LarkContainer
import Swinject
import EENavigator
import LarkReleaseConfig
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkModel
import LarkFeatureGating
import LarkAppLinkSDK
import LarkSetting
import LarkAssembler
import LarkNavigator
import BootManager
import AppContainer
#if canImport(CJPay)
import Lynx
#endif
#if canImport(DouyinOpenPlatformSDK)
import DouyinOpenPlatformSDK
#endif

public enum FinanceSetting {
    private static var userScopeFG: Bool {
        let v = FeatureGatingManager.shared.featureGatingValue(with: "ios.container.scope.user.finance") // Global
        return v
    }
    //是否开启兼容
    public static var userScopeCompatibleMode: Bool { !userScopeFG }
    /// 替换.user, FG控制是否开启兼容模式。兼容模式和.user一致
    public static let userScope = UserLifeScope { userScopeCompatibleMode }
    /// 替换.graph, FG控制是否开启兼容模式。
    public static let userGraph = UserGraphScope { userScopeCompatibleMode }
}

final class WalletHandler: UserTypedRouterHandler {

    func handle(_ body: WalletBody, req: EENavigator.Request, res: Response) throws {
        let onlineUrlString: String = "sslocal://lynxview?hide_nav_bar=1&hide_status_bar=0&dynamic=0&trans_status_bar=1&preferred_width=375&preferred_height=620&surl=https://lf-sourcecdn-tos.bytegecko.com/obj/byte-gurd-source/lark/feoffline/lynx/wallet_portal_lynx/pages/Home/template.js"
        let BOEUrlString: String = "sslocal://lynxview?hide_nav_bar=1&hide_status_bar=0&dynamic=1&trans_status_bar=1&preferred_width=375&preferred_height=620&surl=https://tosv.byted.org/obj/gecko-internal/lark/feoffline/lynx/wallet_portal_lynx/pages/Home/template.js"
        var urlString: String = ""
        if let walletUrl = body.walletUrl, !walletUrl.isEmpty {
            urlString = walletUrl
        } else if let settingDic = try? userResolver.settings.setting(with: UserSettingKey.make(userKeyLiteral: "money_config")),
            let string = settingDic["wallet_lynx_url_non_dynamic"] as? String {
            urlString = string
        } else {
            if EnvManager.env.isStaging {
                urlString = BOEUrlString
            } else {
                urlString = onlineUrlString
            }
        }
        if let url = URL(string: urlString) {
            res.redirect(url, context: req.context)
        }
    }
}

final class WithdrawHandler: UserTypedRouterHandler {

    func handle(_ body: WithdrawBody, req: EENavigator.Request, res: Response) throws {
        let vc = WithdrawViewController(testEnv: EnvManager.env.isStaging,
                                        redPacketAPI: try userResolver.resolve(assert: RedPacketAPI.self),
                                        payManagerService: try userResolver.resolve(assert: PayManagerService.self))
        res.end(resource: vc)
    }
}

final class RedPacketResultHandler: UserTypedRouterHandler {

    func handle(_ body: RedPacketResultBody, req: EENavigator.Request, res: Response) throws {
        let vc = try RedPacketResultViewController(redPacketInfo: body.redPacketInfo,
                                                   receiveInfo: body.receiveInfo,
                                                   redPacketAPI: try userResolver.resolve(assert: RedPacketAPI.self),
                                                   payManagerService: try userResolver.resolve(assert: PayManagerService.self),
                                                   userResolver: userResolver)
        vc.dismissBlock = body.dismissBlock
        res.end(resource: vc)
    }
}

/// 红包历史记录
final class RedPacketHistoryHandler: UserTypedRouterHandler {

    func handle(_ body: RedPacketHistoryBody, req: EENavigator.Request, res: Response) throws {
        let vc = RedPacketHistoryViewController(redPacketAPI: try userResolver.resolve(assert: RedPacketAPI.self),
                                                userResolver: userResolver)
        res.end(resource: vc)
    }
}

/// 红包收发历史记录
final class RedPacketReceivedHistoryHandler: UserTypedRouterHandler {

    func handle(_ body: RedPacketReceivedHistoryBody,
                         req: EENavigator.Request,
                         res: Response) throws {
        let passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        let vc = SendReceiveViewController(type: .receive,
                                           currentUserID: userResolver.userID,
                                           currentUserAvatarKey: passportUserService.user.avatarKey,
                                           redPacketAPI: try userResolver.resolve(assert: RedPacketAPI.self),
                                           userResolver: userResolver)
        res.end(resource: vc)
    }
}

/// 发红包历史记录
final class RedPacketSentHistoryHandler: UserTypedRouterHandler {

    func handle(_ body: RedPacketSentHistoryBody,
                         req: EENavigator.Request,
                         res: Response) throws {
        let passportUserService = try userResolver.resolve(assert: PassportUserService.self)
        let vc = SendReceiveViewController(type: .send,
                                           currentUserID: userResolver.userID,
                                           currentUserAvatarKey: passportUserService.user.avatarKey,
                                           redPacketAPI: try userResolver.resolve(assert: RedPacketAPI.self),
                                           userResolver: userResolver)
        res.end(resource: vc)
    }
}

final class SendRedPacketHandler: UserTypedRouterHandler {

    func handle(_ body: SendRedPacketBody, req: EENavigator.Request, res: Response) throws {
        let passportUserService = try resolver.resolve(assert: PassportUserService.self)
        if body.chat.type == .p2P {
            let vc = SendRedPacketController(isByteDancer: passportUserService.userTenant.isByteDancer,
                                             pageType: .equal,
                                             chat: body.chat,
                                             redPacketAPI: try userResolver.resolve(assert: RedPacketAPI.self),
                                             redPacketPageModelRelay: BehaviorRelay<RedPacketPageModel?>(value: nil),
                                             pushRedPacketCoverChange: try userResolver.userPushCenter.observable(for: PushRedPacketCoverChange.self),
                                             payManager: try userResolver.resolve(assert: PayManagerService.self),
                                             userResolver: userResolver)
            res.end(resource: vc)
        } else {
            let vc = SendRedPacketContainerController(isByteDancer: passportUserService.userTenant.isByteDancer,
                                                      chat: body.chat,
                                                      redPacketAPI: try userResolver.resolve(assert: RedPacketAPI.self),
                                                      pushRedPacketCoverChange: try userResolver.userPushCenter.observable(for: PushRedPacketCoverChange.self),
                                                      payManager: try userResolver.resolve(assert: PayManagerService.self),
                                                      userResolver: userResolver)
            res.end(resource: vc)
        }
    }
}

// MARK: 发送红包鉴权
final class SendRedPacketCheckAutHandler: UserTypedRouterHandler {

    func handle(_ body: SendRedPacketCheckAuthBody, req: EENavigator.Request, res: Response) throws {
        guard let from = req.context.from() else {
            assertionFailure("缺少 From")
            return
        }
        // 联系人二期fg
        let chat = body.chat
        let contactControlService = try userResolver.resolve(assert: ContactControlService.self)
        let canOpenRedPacketPage = contactControlService.getCanOpenRedPacketPage(chat: chat) ?? true
        if !canOpenRedPacketPage {
            var source = Source()
            source.sourceType = .chat
            source.sourceID = chat.id
            let chatter = chat.chatter
            let addContactBody = AddContactApplicationAlertBody(userId: chatter?.id ?? "",
                                                                chatId: chat.id,
                                                                source: source,
                                                                displayName: chatter?.displayName ?? "",
                                                                content: body.alertContent,
                                                                targetVC: from.fromViewController
                                                                )
            userResolver.navigator.present(body: addContactBody, from: from)
        } else {
            // 跳转到发红包页面
            let body = SendRedPacketBody(chat: chat)
            res.redirect(body: body)
        }
    }
}

public final class FinanceAssembly: LarkAssemblyInterface {

    public func registContainer(container: Container) {
        let user = container.inObjectScope(FinanceSetting.userScope)
#if canImport(DouyinOpenPlatformSDK)
        user.register(FinanceLaunchLogService.self) { (r) -> FinanceLaunchLogService in
            return FinanceLaunchLogImpl(resolver: r)
        }
#endif
        user.register(FinanceOpenSDKService.self) { (r) -> FinanceOpenSDKService in
            return FinanceOpenSDKManager(resolver: r)
        }
        #if canImport(CJPay)
        user.register(PayManagerService.self) { (r) -> PayManagerService in
            let deviceService = try r.resolve(assert: DeviceService.self)
            return FinancePayManager(
                appID: ReleaseConfig.appId,
                deviceID: deviceService.deviceId,
                installID: deviceService.installId,
                currentUserID: r.userID,
                redPacketAPI: try r.resolve(assert: RedPacketAPI.self),
                testEnv: (EnvManager.env.isStaging),
                resolver: r)
        }
        #else
        user.register(PayManagerService.self) { (r) -> PayManagerService in
            return MockPayManagerService(resolver: r)
        }
        #endif
    }

    public func registRouter(container: Container) {

        Navigator.shared.registerRoute.type(SendRedPacketBody.self)
                    .factory(SendRedPacketHandler.init(resolver:))

        // 发送红包鉴权
        Navigator.shared.registerRoute.type(SendRedPacketCheckAuthBody.self)
                    .factory(SendRedPacketCheckAutHandler.init(resolver:))

        Navigator.shared.registerRoute.type(OpenRedPacketBody.self)
                    .factory(cache: true, OpenRedPacketHandler.init(resolver:))

        // 红包封面
        Navigator.shared.registerRoute.type(RedPacketCoverBody.self)
                    .factory(cache: true, RedPacketCoverHandler.init(resolver:))

        // 红包封面详情
        Navigator.shared.registerRoute.type(RedPacketCoverDetailBody.self)
                    .factory(cache: true, RedPacketCoverDetailHandler.init(resolver:))

        Navigator.shared.registerRoute.type(AlertAddPhoneBody.self)
                    .factory(AlertAddPhoneHandler.init(resolver:))

        Navigator.shared.registerRoute.type(RedPacketResultBody.self)
                    .factory(RedPacketResultHandler.init(resolver:))

        Navigator.shared.registerRoute.type(RedPacketHistoryBody.self)
                    .factory(RedPacketHistoryHandler.init(resolver:))

        Navigator.shared.registerRoute.type(RedPacketReceivedHistoryBody.self)
                    .factory(RedPacketReceivedHistoryHandler.init(resolver:))

        Navigator.shared.registerRoute.type(RedPacketSentHistoryBody.self)
                    .factory(RedPacketSentHistoryHandler.init(resolver:))

        Navigator.shared.registerRoute.type(WalletBody.self)
                    .factory(WalletHandler.init(resolver:))

        Navigator.shared.registerRoute.type(WithdrawBody.self)
                    .factory(WithdrawHandler.init(resolver:))

        #if canImport(CJPay)
        FinancePayManager.setupBulletRouter(container: container)
        #endif

    }

    public func registLarkAppLink(container: Container) {
        LarkAppLinkSDK.registerHandler(path: "/client/pay/open", handler: { (applink: AppLink) in
            guard let authString = applink
                    .url
                    .queryParameters["openUrl"],
                  let data = Data(base64Encoded: authString),
                  let authURL = String(data: data, encoding: .utf8) else { return }
            guard let from = applink.context?.from(), let fromVC = from.fromViewController else { return }
            try? container.resolve(type: PayManagerService.self).open(url: authURL, referVc: fromVC, closeCallBack: nil)
        })
    }

    public func registBootLoader(container: Container) {
#if canImport(DouyinOpenPlatformSDK)
        (FinanceApplicationDelegate.self, DelegateLevel.default)
#endif
    }

    public func registLaunch(container: Container) {
#if canImport(DouyinOpenPlatformSDK)
        NewBootManager.register(FinanceLaunchTask.self)
#endif
    }

    public init() {}
}
