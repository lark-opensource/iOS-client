//
//  LarkAccountAssembly.swift
//  LarkAccountAssembly
//
//  Created by liuwanlin on 2019/9/26.
//

import Foundation
import RxSwift
import RxCocoa
import Swinject
import LarkAccount
import LarkAccountInterface
import EENavigator
import LarkUIKit
import LarkContainer
import LarkAssembler
import LarkLeanMode
import LarkDynamicResource
import LKCommonsLogging
import CookieManager
import LarkSetting
import LarkRustClientAssembly

#if GadgetMod
import LarkOPInterface
import JsSDK
import WebBrowser
import LarkWebViewContainer
#endif

#if MessengerMod
import LarkMessengerInterface
import LarkFinance
import LarkBytedCert
import LarkTourInterface
import LarkSDKInterface
import LarkLocalizations
#endif

public final class LarkAccountAssembly: LarkAssemblyInterface {

    private let miniMode: Bool

    /// - Parameter miniMode: 表示是否是 minimum mode
    public init(miniMode: Bool = false) {
        self.miniMode = miniMode
    }

    public func registContainer(container: Container) {
        let miniMode = self.miniMode
        container.register(AccountDependency.self) { _ -> AccountDependency in
            if miniMode {
                return LarkAccount.DefaultAccountDependencyImpl()
            } else {
                return AccountDependencyImpl(resolver: container)
            }
        }
    }

    public func getSubAssemblies() -> [LarkAssemblyInterface]? {
        AccountAssembly()
    }

    public func registUnloginWhitelist(container: Swinject.Container) {
#if GadgetMod
        WebBody.pattern
#endif
    }

}

class AccountDependencyImpl: AccountDependency {

    private let resolver: Swinject.Resolver

    @Provider var leanModeService: LeanModeService // user:checked (global-resolve)

    @Provider var webViewFactory: SuiteLoginWebViewFactory // user:checked (global-resolve)

#if MessengerMod
    @Provider var userSettings: UserGeneralSettings // user:checked (global-resolve)
#endif
    static let logger = Logger.log(AccountDependencyImpl.self)

    var notifyDisableDriver: Driver<Bool> {
#if MessengerMod
        userSettings.notifyConfig.notifyDisableDriver
#else
        Driver.empty()
#endif
    }

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    // MARK: LauncherDependency

    // MARK: SuiteLoginConfigurationDependency

    var leanModeStatus: Observable<Bool> { leanModeService.leanModeStatus }
    var deviceInLeanMode: Bool { return leanModeService.currentLeanModeStatusAndAuthority.allDevicesInLeanMode }

    func openURL(_ url: URL, from: UIViewController) {
#if GadgetMod
        Navigator.shared.present( // user:checked (navigator)
            body: SimpleWebBody(url: url),
            wrap: LkNavigationController.self,
            from: from,
            prepare: { $0.modalPresentationStyle = .fullScreen }
        )
#endif
    }

    func createWebViewController(_ url: URL, customUserAgent: String?) -> UIViewController {
        return webViewFactory.createWebViewController(url, customUserAgent: customUserAgent)
    }

    func createFailView() -> UIView {
        return webViewFactory.createFailView()
    }

    func getOpenPlatformDeviceId() -> String {
#if GadgetMod
        do {
            return try resolver.resolve(assert: OpenPlatformService.self).getOpenPlatformDeviceID()
        } catch {
            return ""
        }
#else
        return ""
#endif
    }

    func value(forKey key: String, defaultValue: String) -> String {
#if GadgetMod
        return StoreForDynamic.value(forKey: key, defaultValue: defaultValue)
#else
        return ""
#endif
    }

    func setValue(value: String, forKey key: String) {
#if GadgetMod
        StoreForDynamic.setValue(value: value, forKey: key)
#endif
    }

    func removeValue(key: String) {
#if GadgetMod
        StoreForDynamic.removeValue(key: key)
#endif
    }

    func openDynamicURL(_ url: URL, from: UIViewController) {
#if GadgetMod
        var params = NaviParams()
        params.forcePush = true
        Navigator.shared.push( // user:checked (navigator)
            body: UnloginWebBody(url: url, jsApiMethodScope: .all, webBizType: .passport),  //  新Web全量后要求用UnloginWebBody
            naviParams: params,
            from: from
        )
#endif
    }

    func openDynamicURL(
        _ url: URL,
        from: UIViewController,
        isPresent: Bool,
        prepare: ((UIViewController) -> Void)? = { $0.modalPresentationStyle = .fullScreen }
    ) {
#if GadgetMod
        if isPresent {
            Navigator.shared.present( // user:checked (navigator)
                body: UnloginWebBody(url: url, jsApiMethodScope: .all, webBizType: .passport),
                wrap: LkNavigationController.self,
                from: from,
                prepare: prepare
            )
        } else {
            openDynamicURL(url, from: from)
        }
#endif
    }

    func openCJURL(_ url: String, from: UIViewController) {
#if MessengerMod
        do {
            let service = try resolver.resolve(assert: PayManagerService.self)
            service.open(url: url, referVc: from, closeCallBack: nil)
        } catch {
            return
        }
#endif
    }

    func successUpgradeTeam<T: UIViewController>(path: String?, lastVCType: T.Type?, from: UIViewController?) {
#if MessengerMod
        do {
            let service = try resolver.resolve(assert: TeamConversionService.self)
            service.successUpgradeTeam(
                path: path ?? "",
                sourceScenes: MemberInviteSourceScenes.upgrade.toString(),
                lastVCType: lastVCType,
                from: from
            )
        } catch {
            return
        }
#endif
    }

    func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        mode: String,
        callback: @escaping ([AnyHashable: Any]?, Error?) -> Void
    ) {
#if MessengerMod
        LarkBytedCert().doFaceLiveness(
            appId: appId,
            ticket: ticket,
            scene: scene,
            mode: mode,
            callback: callback
        )
#endif
    }

    func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        identityName: String,
        identityCode: String,
        presentToShow: Bool = false,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ error: Error?) -> Void
    ) {
#if MessengerMod
        LarkBytedCert().doFaceLiveness(
            appId: appId,
            ticket: ticket,
            scene: scene,
            identityName: identityName,
            identityCode: identityCode,
            presentToShow: presentToShow,
            callback: callback
        )
#endif
    }

    func toJoinMeetingController(from: UIViewController) {
        if let url = URL(string: "//client/videochat/meetingno/guestjoin") {
            // 非立即生效，异步行为
            Navigator.shared.present(url, from: from) // user:checked (navigator)
        }
    }

    func updateNotificaitonStatus(notifyDisable: Bool, retry: Int) {
        #if MessengerMod
        userSettings.updateNotificaitonStatus(notifyDisable: notifyDisable, retry: retry)
        #endif
    }

    func updateAppLanguage(model: LanguageModel, from: UIViewController) {
        #if MessengerMod
        do {
            let service = try resolver.resolve(assert: AppLanguageService.self)
            service.updateAppLanguage(model: model, from: from)
        } catch {
            return
        }
        #endif
    }

    func clearCookie() {
        LarkCookieManager.shared.clearCookie(nil)
    }

    func setupCookie(user: User) -> Bool {
        LarkCookieManager.shared.setupCookie(user: user)
    }

    func openProfile(_ userID: String, hostViewController: UIViewController) {
#if MessengerMod
        let body = PersonCardBody(chatterId: userID)
        Navigator.shared.presentOrPush(body: body, // user:checked (navigator)
                                       wrap: LkNavigationController.self,
                                       from: hostViewController,
                                       prepareForPresent: { viewController in
            viewController.modalPresentationStyle = .formSheet
        })
#endif
    }

    func userListChange(userList: [User], foregroundUser: User?, action: PassportUserAction, delegate: LarkContainerManagerFlowProgressDelegate) {
        LarkContainerManager.shared.userListChange(userList: userList, foregroundUser: foregroundUser, action: action, delegate: delegate)
    }
}

extension LarkCookieManager {
    func setupCookie(user: User) -> Bool {
        Self.logger.info("cookie ===>>> Setup cookies")

        if let token = user.sessionKey {
            Self.logger.info("cookie ===>>> Setup cookie for token")

            if !plantCookie(token: token) {
                return false
            }

            //Passport 新增 session_list
            if !plantCookie(token: token, name: "session_list") {
                return false
            }
        }

        if let tokens = user.sessionKeyWithDomains {
            Self.logger.debug("cookie ===>>> Setup cookies for domains, domain count: \(tokens.keys.count)")
            plantCookies(tokens)
        } else {
            Self.logger.error("Setup cookies for domains: no domain found")
        }

        if let clearCNTopLevelStruct = try? SettingManager.shared.setting(with: ClearCookieCNTopLevelStruct.self), // user:checked
           clearCNTopLevelStruct.enable {
            Self.logger.info("clear dirty cookie after \(clearCNTopLevelStruct.asyncAfter)s")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(clearCNTopLevelStruct.asyncAfter)) {
                self.clearDirtyCookie()
            }
        }

        return true
    }
}

struct ClearCookieCNTopLevelStruct: SettingDecodable {
    static let settingKey = UserSettingKey.make(userKeyLiteral: "op_cookie_clear_cntoplevel") 

    let enable : Bool
    let asyncAfter : Int
}
