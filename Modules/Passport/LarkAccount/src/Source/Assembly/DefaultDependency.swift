//
//  MockDependency.swift
//  LarkAccountAssembly
//
//  Created by CharlieSu on 10/11/19.
//

import Foundation
import RxSwift
import RxCocoa
import LarkAccountInterface
import EENavigator
import LarkUIKit
import LarkEnv

open class DefaultAccountDependencyImpl: AccountDependency {

    public init() { }

    public func openURL(_ url: URL, from: UIViewController) {
        let vc = PassportWebViewController(url: url)
        let navi = LkNavigationController(rootViewController: vc)
        navi.modalPresentationStyle = .fullScreen
        Navigator.shared.present(navi, from: from) // user:checked (navigator)
    }

    public func createWebViewController(_ url: URL, customUserAgent: String?) -> UIViewController {
        /// 你是踩到这个坑的第3个人。IDP登录打开Web登录页需要在 ios-client 工程里面运行 :-)
        return UIViewController()
    }

    public func createFailView() -> UIView { return UIView() }

    public func getOpenPlatformDeviceId() -> String { return "" }

    public func value(forKey key: String, defaultValue: String) -> String { return "" }

    public func setValue(value: String, forKey key: String) { }

    public func removeValue(key: String) { }

    public func openDynamicURL(_ url: URL, from: UIViewController) {
        openURL(url, from: from)
    }

    public func openDynamicURL(_ url: URL,
                        from: UIViewController,
                        isPresent: Bool,
                        prepare: ((UIViewController) -> Void)? = { $0.modalPresentationStyle = .fullScreen }){

        if isPresent {
            let vc = PassportWebViewController(url: url)
            let navi = LkNavigationController(rootViewController: vc)
            prepare?(vc)
            Navigator.shared.present(navi, from: from) // user:checked (navigator)
        }else{
            openDynamicURL(url, from: from)
        }
    }

    public func openCJURL(_ url: String, from: UIViewController) { }

    public func successUpgradeTeam<T: UIViewController>(path: String?, lastVCType: T.Type?, from: UIViewController?) { }

    public func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        mode: String,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ error: Error?) -> Void) {}

    public func doFaceLiveness(
        appId: String,
        ticket: String,
        scene: String,
        identityName: String,
        identityCode: String,
        presentToShow: Bool,
        callback: @escaping (_ data: [AnyHashable: Any]?, _ error: Error?) -> Void) {}

    public func toJoinMeetingController(from: UIViewController) { }

    public var leanModeStatus: Observable<Bool> { .just(false) }
    
    public var deviceInLeanMode: Bool { return false }

    public var avatarPath: String { "" }

    public var notifyDisableDriver: Driver<Bool> { .just(false) }

    public func updateNotificaitonStatus(notifyDisable: Bool, retry: Int) {}

    public func updateAppLanguage(model: LanguageModel, from: UIViewController) {}

    public func clearCookie() {}

    public func setupCookie(user: User) -> Bool { false }

    public func openProfile(_ userID: String, hostViewController: UIViewController) { }

    public func userListChange(userList: [User], foregroundUser: User?, action: PassportUserAction, delegate: LarkContainerManagerFlowProgressDelegate) { }
}
