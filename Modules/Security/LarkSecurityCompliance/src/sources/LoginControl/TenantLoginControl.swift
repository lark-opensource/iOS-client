//
//  TenantLoginControl.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/2/2.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkAccountInterface
import LarkContainer
import UniverseDesignDialog
import EENavigator
import ByteDanceKit
import RxSwift
import UniverseDesignToast
import LarkSetting
import LarkTracker

protocol TenantLoginControlProtocol {
    func start()
}

final class TenantLoginControl: TenantLoginControlProtocol, UserResolverWrapper {
    
    enum RequestType: String {
        case timer
        case network
    }
    
    private let monitor: NetworkChangeMonitor
    
    fileprivate var sessionValid: Bool = false
    
    private var timer: SCTimer?
    
    private var dialogTimer: Timer?
    
    private let probeFetcher: PingTenantRestrictFetcher
    
    private weak var dialog: UDDialog?
    
    private var isLogout: Bool = false
    
    @Provider private var passportService: PassportService // Global
    @ScopedProvider private var userService: PassportUserService?
    
    private var retryCount: Int = 2
    
    private var lastRequestTime: TimeInterval?
    
    private let settings: Settings
    
    private var window: UIWindow?
    
    var disposable: Disposable?
    
    let fgObserver = FeatureGatingManager.realTimeManager.fgObservable // Global
    var fgDisposable: Disposable?
    
    var isLoaded: Bool = false
    let userResolver: UserResolver

    var timerInteval: Int {
        guard settings.enableSecuritySettingsV2.isTrue else {
            SCLogger.info("\(SettingsImp.CodingKeys.loginRestrictionHeatbeatInterval.rawValue) \(settings.loginRestrictionHeatbeatInterval ?? 900)",
                          tag: SettingsImp.logTag)
            return settings.loginRestrictionHeatbeatInterval ?? 900
        }
        do {
            let service = try userResolver.resolve(assert: SCSettingService.self)
            SCLogger.info("\(SCSettingKey.loginRestrictionHeatbeatInterval.rawValue) \(service.int(.loginRestrictionHeatbeatInterval))",
                          tag: SCSetting.logTag)
            return service.int(.loginRestrictionHeatbeatInterval)
        } catch {
            SCLogger.error("SCSettingsService resolve error \(error)")
            return 900
        }
    }

    var enableTenantRestriction: Bool {
        guard settings.enableSecuritySettingsV2.isTrue else {
            let service = try? userResolver.resolve(assert: FeatureGatingService.self)
            SCLogger.info("lark.security.login_restrict_switch \(service?.dynamicFeatureGatingValue(with: "lark.security.login_restrict_switch") ?? false)", tag: SettingsImp.logTag)
            return service?.dynamicFeatureGatingValue(with: "lark.security.login_restrict_switch") ?? false
        }
        return SCSetting.realTimeFG(scKey: .enableLoginRestrict, userResolver: userResolver)
    }

    var disableTenantLoginSessionInvalidOpt: Bool {
        guard settings.enableSecuritySettingsV2.isTrue else {
            SCLogger.info("\(SettingsImp.CodingKeys.disableTenantLoginSessionInvalidOpt.rawValue) \(settings.disableTenantLoginSessionInvalidOpt ?? false)", tag: SettingsImp.logTag)
            return settings.disableTenantLoginSessionInvalidOpt ?? false
        }
        return SCSetting.staticBool(scKey: .disableTenantLoginSessionInvalidOpt, userResolver: userResolver)
    }
    
    deinit {
        stop()
    }
    
    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        settings = try userResolver.resolve(assert: Settings.self)
        probeFetcher = try PingTenantRestrictFetcher(userResolver: userResolver)
        let config = try NetWorkMonitorConfig(userResolver: userResolver, method: .pathMonitor)
        monitor = NetworkChangeMonitor(config: config)
        monitor.updateHandler = { [weak self] _ in
            guard let self else { return }
            self.sendProbeRequest(.network)
        }

        timer = SCTimer(config: TimerCongfig(timerInterval: timerInteval, disableWhileBackground: true))
        timer?.handler = { [weak self] in
            DispatchQueue.runOnMainQueue { [weak self] in
                guard let self else { return }
                self.sendProbeRequest(.timer)
            }
        }
        
        fgDisposable = fgObserver.subscribe(onNext: { [weak self] in
            guard let self else { return }
            self.start()
        })
    }
    
    func start() {
        guard enableTenantRestriction else {
            SCLogger.info("Tenant login Control: FG disabled")
            return
        }
        
        guard !isLoaded else { return }
        
        isLoaded = true
        monitor.start()
        timer?.startTimer()
        self.disposable?.dispose()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.sendProbeRequest(.timer)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        if !disableTenantLoginSessionInvalidOpt {
            SCLogger.info("Tenant login Control: register passport interrupt operation")
            passportService.register(interruptOperation: TenantLoginControlWeakProxy(self))
        }
    }
    
    func stop() {
        SCLogger.info("Tenant login Control: stop")
        if dialog?.view.window != nil {
            dialog?.dismiss(animated: false)
        }
        self.timer?.stopTimer()
        self.dialogTimer?.invalidate()
        self.disposable?.dispose()
        self.fgDisposable?.dispose()
        monitor.stop()
    }
    
    private func shouldSendRequest(_ requestType: TenantLoginControl.RequestType) -> Bool {
        if let lastRequestTime = lastRequestTime, (Date().timeIntervalSince1970 - lastRequestTime) * 1000 < 1500, requestType == .timer {
            SCLogger.info("Tenant login Control: ping time limit", additionalData: ["request_type": requestType.rawValue])
            return false
        }
        if sessionValid && !disableTenantLoginSessionInvalidOpt {
            SCLogger.info("Tenant login Control: session invalid")
            return false
        }
        return true
    }
    
    private func sendProbeRequest(_ requestType: TenantLoginControl.RequestType) {
        guard shouldSendRequest(requestType) else { return }
        disposable?.dispose()
        disposable = self.probeFetcher.pingTenantRestrict()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] resp in
                self?.lastRequestTime = Date().timeIntervalSince1970
                let additionalData: [String: String] = ["request_type": requestType.rawValue,
                                                        "foreground_tenant_id": self?.userService?.user.tenant.tenantID ?? "null",
                                                        "restrict_tenant_id": resp.data.tenantId ?? "",
                                                        "should_kick_off": resp.data.shouldKickOff?.stringValue ?? "",
                                                        "ping_result": "success"]
                SCLogger.info("Tenant login Control: ping response", additionalData: additionalData)
                SCMonitor.info(business: .tenant_restrict, eventName: "ping", category: additionalData)
                guard let self, self.isCurrentTenant(resp.data.tenantId), resp.data.shouldKickOff ?? false else {
                    SCLogger.info("Tenant restrict: tenant doesn't need to log out", additionalData: additionalData)
                    return
                }
                guard UIApplication.shared.applicationState != .background else {
                    SCLogger.info("Tenant login Control: APP is background", additionalData: additionalData)
                    return
                }
                guard !self.isLogout else {
                    SCLogger.info("Tenant login Control: current tenant is logging out", additionalData: additionalData)
                    return
                }
                
                self.isLogout = true
                self.showDialogIfNeeded()
                self.dialogTimer?.invalidate()
                self.dialogTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
                    guard let self, self.isCurrentTenant(resp.data.tenantId) else { return }
                    self.logout()
                })
            }, onError: { [weak self] error in
                guard let self else { return }
                var additionalData: [String: String] = ["ping_result": "error", "request_type": requestType.rawValue]
                if let lscError = error as? LSCError {
                    switch lscError {
                    case .httpStatusError(let code, let bodyJson):
                        additionalData["error_code"] = "\(code)"
                        additionalData["error_msg"] = bodyJson.debugDescription
                    case .domainInvalid, .unsupportHTTPMethod, .dataIsNil, .responseIsNil, .selfIsNil: break
                    @unknown default: break
                    }
                }
                additionalData["error"] = "\(error)"
                SCLogger.error("Tenant login Control: ping error", additionalData: additionalData)
                SCMonitor.info(business: .tenant_restrict, eventName: "ping", category: additionalData)
                self.disposable?.dispose()
            }, onCompleted: { [weak self] in
                self?.disposable?.dispose()
            })
    }
    
    private func isCurrentTenant(_ tenantId: String?) -> Bool {
        guard let tenantId = tenantId else { return false }
        let currentTenantId = userService?.user.tenant.tenantID
        return tenantId == currentTenantId
    }
    
    private enum LogoutResult: String {
        case interrupt
        case success
        case error
    }
    
    private func failLogoutCallback(_ logoutResult: LogoutResult, additionalData: [String: String]?) {
        var additionalParams: [String: String] = additionalData ?? [:]
        additionalParams["stage"] = logoutResult.rawValue
        additionalParams["retry_count"] = String(self.retryCount)
        if self.retryCount > 0 {
            self.logout()
            self.retryCount -= 1
        } else {
            SCMonitor.info(business: .tenant_restrict, eventName: "logout", category: additionalParams)
            self.isLogout = false
            self.retryCount = 2
        }
    }
    
    private func logout() {
        var additionData = ["tenant_id": userService?.user.tenant.tenantID ?? ""]
        SCLogger.info("Tenant login Control: Logout begin", additionalData: additionData)
        SCMonitor.info(business: .tenant_restrict, eventName: "logout", category: ["stage": "begin"])
        self.dialogTimer?.invalidate()
        let config = LogoutConf(forceLogout: true, trigger: .tenantRestrict, destination: .switchUser, type: .foreground)
        let userId = userService?.user.userID ?? ""
        let tenantId = userService?.user.tenant.tenantID ?? ""
        let params: [String: String] = [
            "tenant_id": Encrypto.encryptoId(tenantId),
            "device_id": passportService.deviceID,
            "user_unique_id": Encrypto.encryptoId(userId),
            "os_name": "ios"
        ]
        self.passportService.logout(conf: config) { [weak self] in
            guard let self else { return }
            SCLogger.info("Tenant login Control: Logout interrupt", additionalData: additionData)
            self.failLogoutCallback(.interrupt, additionalData: additionData)
        } onError: { [weak self] message in
            guard let self else { return }
            additionData["error_message"] = message
            SCLogger.info("Tenant login Control: Logout error", additionalData: additionData)
            self.failLogoutCallback(.error, additionalData: additionData)
        } onSuccess: { [weak self] _, _ in
            SCLogger.info("Tenant login Control: Logout success", additionalData: additionData)
            Events.track("scs_unable_to_switch_popup_view", params: params)
            additionData["stage"] = "success"
            SCMonitor.info(business: .tenant_restrict, eventName: "logout", category: additionData)
            guard let self else { return }
            self.isLogout = false
            self.retryCount = 2
        } onSwitch: { _ in
            
        }
    }
    
    private func showDialogIfNeeded() {
        SecuritySceneManager.closeAllAssitantScenes()
        guard let topVC = BTDResponder.topViewController() else {
            SCLogger.info("Tenant login Control: topVC is nil")
            return
        }
        let config = UDDialogUIConfig()
        config.style = .vertical
        let dialog: UDDialog = UDDialog(config: config)
        dialog.setTitle(text: BundleI18n.TenantRestriction.Lark_SwitchTenant_Title_Notice)
        dialog.setContent(text: BundleI18n.TenantRestriction.Lark_SwitchTenant_Title_UnableToSwitch)
        dialog.addPrimaryButton(text: BundleI18n.TenantRestriction.Lark_SwitchTenant_Button_ExitNow, dismissCompletion: { [weak self] in
            guard let self else { return }
            self.logout()
        })
        self.dialog = dialog
        self.userResolver.navigator.present(dialog, from: topVC)
        SCLogger.info("Tenant login Control: show dialog")
        // 不可删除，不持有window，会存在dialog和window上的AppLockSettingVerifyViewController的循环引用
        window = topVC.view.window
    }
    
    private func pauseTimer() {
        guard let dialogTimer = dialogTimer else { return }
        dialogTimer.btd_pause()
        SCLogger.info("Tenant login Control: pause dialog timer")
    }
    
    @objc
    private func onDidEnterBackground() {
        self.pauseTimer()
    }
    
    @objc
    private func onWillResignActive() {
        self.pauseTimer()
    }
    
    private func resumeTimer() {
        guard let dialogTimer = dialogTimer else { return }
        dialogTimer.btd_resume()
        SCLogger.info("Tenant login Control: resume dialog timer")
    }
    
    @objc
    private func onWillEnterForeground() {
        self.resumeTimer()
    }
    
    @objc
    private func onDidBecomeActive() {
        self.resumeTimer()
    }
}

private class TenantLoginControlWeakProxy: InterruptOperation {
    private weak var loginControl: TenantLoginControl?
    
    var description: String {
        "TenantLoginControl"
    }
    
    init(_ loginControl: TenantLoginControl?) {
        self.loginControl = loginControl
    }
    
    func getInterruptObservable(type: InterruptOperationType) -> Single<Bool> {
        if type == InterruptOperationType.sessionInvalid {
            loginControl?.sessionValid = true
            SCLogger.info("Tenant login Control: set session invalid true")
        }
        return .just(true)
    }

}
