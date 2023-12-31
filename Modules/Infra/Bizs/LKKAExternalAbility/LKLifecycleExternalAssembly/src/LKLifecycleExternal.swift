import UIKit
import Foundation
import LKKACore
import LarkAccountInterface
import LarkContainer
import LKCommonsLogging

public struct LKLifecycleExternal {
    static let logger = Logger.log(LKLifecycleExternal.self, category: "Module.LKLifecycleExternal")
    let notiCenter = NotificationCenter.default
    init() {
        startObserver()
    }

    public static func startApp() {
        logger.info("KA---Watch: App start")
        let startNoti = Notification.Name(LKLifecycle.start)
        NotificationCenter.default.post(name: startNoti, object: nil)
    }

    func onLogout() {
        Self.logger.info("KA---Watch: App onlogout")
        let onLogoutNoti = Notification.Name(LKLifecycle.onLogout)
        notiCenter.post(name: onLogoutNoti, object: nil)
    }

    func onlogin(isSuccess: Bool, isFast: Bool) {
        Self.logger.info("KA---Watch: App onlogin, is fast: \(isFast)")
        let loginNoti = Notification.Name(isSuccess ? LKLifecycle.onLoginSuccess : LKLifecycle.onLoginFail)
        let obj = ["isFastLogin": isFast ? "true" : "false"]
        notiCenter.post(name: loginNoti, object: obj)
    }

    public func onloginFailed(isFast: Bool) {
        Self.logger.info("KA---Watch: App onlogin failed, is fast: \(isFast)")
        onlogin(isSuccess: false, isFast: isFast)
    }
    
    func beforeSwitchAccount() {
        Self.logger.info("KA---Watch: App before switch account")
        let beforeSwitchAccoutNoti = Notification.Name(LKLifecycle.beforeSwitchAccout)
        notiCenter.post(name: beforeSwitchAccoutNoti, object: nil)
    }
    
    func switchAccountSucceed() {
        Self.logger.info("KA---Watch: App switch account succeed")
        let switchAccountSucceedNoti = Notification.Name(LKLifecycle.switchAccountSucceed)
        notiCenter.post(name: switchAccountSucceedNoti, object: nil)
    }

    func startObserver() {
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in
            let backgoundNoti = Notification.Name(LKLifecycle.pause)
            notiCenter.post(name: backgoundNoti, object: nil)
        }
        _ = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { _ in
            let resumeNoti = Notification.Name(LKLifecycle.resume)
            notiCenter.post(name: resumeNoti, object: nil)
        }
    }
}

public class KALifecycleExternalLauncherDelegate: LauncherDelegate {
    public var name: String { "KALifecycleExternalLauncherDelegate" }
    @Injected var lifecycle: LKLifecycleExternal
    public init() {

    }

    public func afterLogout(_ context: LauncherContext) {
        lifecycle.onLogout()
    }

    public func fastLoginAccount(_ account: Account) {
        lifecycle.onlogin(isSuccess: true, isFast: true)
    }

    public func afterSetAccount(_ account: Account) {
        lifecycle.onlogin(isSuccess: true, isFast: false)
    }
    
    public func beforeSwitchAccout() {
        lifecycle.beforeSwitchAccount()
    }
    
    public func switchAccountSucceed(context: LauncherContext) {
        lifecycle.switchAccountSucceed()
    }

}
