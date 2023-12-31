//
//  AppLockSettingService.swift
//  LarkMine
//
//  Created by thinkerlj on 2021/12/31.
//

import Foundation
import RxSwift
import EENavigator
import LarkContainer
import Swinject
import LarkFoundation
import UniverseDesignToast
import UniverseDesignColor
import UniverseDesignActionPanel
import LarkAccountInterface
import LarkSceneManager
import LarkBlur
import UniverseDesignDialog
import LarkSecurityComplianceInfra
import LarkSetting
import LarkSecurityComplianceInterface
import LarkExtensions

@available(iOS 13.0, *)
fileprivate extension UIScene {
    var isAppMainScene: Bool {
        session.role == .windowApplication && sceneInfo.isMainScene()
    }
}

protocol AppLockSettingService {
    var formatTenantNameDesc: String { get }
    var blurService: AppLockSettingBlurService { get }
    var configInfo: AppLockSettingConfigInfo { get }
    var biometryAuth: AppLockSettingBiometryAuthentication { get }
    /// 是否开启iPad多Scene优化，true：开启，false：关闭
    var supportMultiSceneOpt: Bool { get }
    func start()
    func stop()
    func checkVerification()
    func checkAppLockSetting()
}

final class AppLockVerifyAlert: UserResolverWrapper {
    private var window: UIWindow?

    private var observers = [NSObjectProtocol]()

    let userResolver: UserResolver
    
    private var isSupportMultiSceneOpt: Bool {
        (try? resolver.resolve(type: AppLockSettingService.self).supportMultiSceneOpt) ?? true
    }
    
    private let windowService: WindowService?

    @ScopedProvider private var settings: SCRealTimeSettingService?
    
    init(resolver: UserResolver) {
        self.userResolver = resolver
        self.windowService = try? resolver.resolve(assert: ExternalDependencyService.self).windowService
        if #available(iOS 13.0, *) {
            observeSceneNotification()
        }
    }

    deinit {
        observers.forEach({ NotificationCenter.default.removeObserver($0) })
        SCLogger.info("AppLock deinit")
    }

    func show(rootVC: UIViewController) {
        if #available(iOS 13.0, *) {
            setupWindowByConnectScene(rootVC: rootVC)
        } else {
            setupWindowByApplicationDelegate(rootVC: rootVC)
        }

        window?.isHidden = false
    }

    func dismiss() {
        window?.isHidden = true
    }

    private func createWindow(rootWindow: UIWindow, rootVC: UIViewController) -> UIWindow {
        let window: UIWindow
        if let windowService {
            window = windowService.createLSCWindow(frame: rootWindow.bounds)
        } else {
            window = UIWindow(frame: rootWindow.bounds)
        }
        if #available(iOS 13.0, *) {
            window.windowScene = rootWindow.windowScene
        }
        let disableWindowLevelOpt = settings?.bool(.disableAppLockWindowLevelOpt) ?? false
        if disableWindowLevelOpt {
            Logger.info("app lock: create window with level: alert-2")
            window.windowLevel = .alert - 2
        } else {
            Logger.info("app lock: create window with level: max-1")
            window.windowLevel = UIWindow.Level(.greatestFiniteMagnitude - 1)
        }
        window.rootViewController = rootVC
        window.isHidden = true
        window.windowIdentifier = "LarkEMM.window"

        return window
    }

    @available(iOS 13.0, *)
    private func setupWindowByConnectScene(rootVC: UIViewController) {
        let scenes = UIApplication.shared.windowApplicationScenes
        let scene: UIScene?
        if isSupportMultiSceneOpt {
            scene = scenes.first(where: { $0.session.role == .windowApplication })
        } else {
            closeAllAssitantScenes()
            scene = scenes.first(where: { $0.isAppMainScene })
        }
        if let scene, let rootWindow = rootWindowForScene(scene: scene) {
            window = createWindow(rootWindow: rootWindow, rootVC: rootVC)
            Logger.info("applock: setupWindowByConnectScene: \(scene) \(rootWindow)")
        } else {
            Logger.error("applock: setupWindowByConnectScene failed.")
            SCMonitor.error(business: .app_lock, eventName: "create_window_failed")
        }
    }
    
    @available(iOS 13.0, *)
    private func closeAllAssitantScenes() {
        for uiScene in UIApplication.shared.windowApplicationScenes {
            let scene = uiScene.sceneInfo
            if !scene.isMainScene() {
                SceneManager.shared.deactive(scene: scene)
            }
        }
    }

    private func setupWindowByApplicationDelegate(rootVC: UIViewController) {
        guard let delegate = UIApplication.shared.delegate,
            let weakWindow = delegate.window,
            let rootWindow = weakWindow else {
            return
        }

        window = createWindow(rootWindow: rootWindow, rootVC: rootVC)
    }

    @available(iOS 13.0, *)
    private func observeSceneNotification() {
        observers.forEach({ NotificationCenter.default.removeObserver($0) })
        let didActivateObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                guard let self,
                      let scene = noti.object as? UIWindowScene,
                      let windowScene = self.window?.windowScene else {
                    return
                }
                if self.isSupportMultiSceneOpt {
                    guard scene.session.role == .windowApplication else { return }
                    if windowScene.activationState != .foregroundActive && windowScene != scene {
                        self.window?.windowScene = scene
                    }
                } else {
                    if scene.isAppMainScene, scene != windowScene {
                        self.window?.windowScene = scene
                    }
                }
                if windowScene != scene {
                    Logger.info("applock: didActivateNotification: \(scene), currentWindowScene: \(windowScene)")
                }
        }
        
        let didDisconnectObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didDisconnectNotification,
            object: nil,
            queue: nil) { [weak self] (noti) in
                guard let scene = noti.object as? UIWindowScene,
                let windowScene = self?.window?.windowScene else {
                    return
                }
                if windowScene == scene {
                    self?.window?.windowScene = self?.findForegroundActiveScene()
                }
                Logger.info("applock: didDisconnectNotification: \(scene) current: \(windowScene)")
        }
        observers = [didActivateObserver, didDisconnectObserver]
    }

    @available(iOS 13.0, *)
    private func findForegroundActiveScene() -> UIWindowScene? {
        if isSupportMultiSceneOpt {
            return UIApplication.shared.windowApplicationScenes.first {
                let isVisible = [.foregroundActive, .foregroundInactive].contains($0.activationState)
                return isVisible
            } as? UIWindowScene
        } else {
            return UIApplication.shared.windowApplicationScenes.first { $0.isAppMainScene } as? UIWindowScene
        }
    }

    @available(iOS 13.0, *)
    private func rootWindowForScene(scene: UIScene) -> UIWindow? {
        guard let scene = scene as? UIWindowScene else {
            return nil
        }
        if let delegate = scene.delegate as? UIWindowSceneDelegate,
            let rootWindow = delegate.window.flatMap({ $0 }) {
            return rootWindow
        }
        return scene.windows.first
    }
}

final class AppLockSettingServiceImp: AppLockSettingService, AppLockSettingDependency, UserResolverWrapper {
    let blurService: AppLockSettingBlurService
    lazy var configInfo = {
        let userID = userService?.user.userID ?? ""
        let tenantID = userService?.user.tenant.tenantID ?? ""
        let key = "AppLockSettingConfigInfoKey"
        let info = AppLockSettingConfigInfo(for: key, userID: userID, tenantID: tenantID)
        return info
    }()
    var supportMultiSceneOpt: Bool { blurService.isSupportMultiSceneOpt }
    let enableAppLockSettingsV2: Bool
    let biometryAuth: AppLockSettingBiometryAuthentication
    private var disposeBag = DisposeBag()
    private var pushDisposeBag = DisposeBag()
    private var lastBackgroundTime = darwinTime()
    private var verifyAlert: AppLockVerifyAlert?

    let userResolver: UserResolver

    private var skipedFirstForgroundExent: Bool = false

    let leanModeService: LeanModeSecurityService?
    @ScopedProvider private var userService: PassportUserService?

    var formatTenantNameDesc: String {
        var tenantName = userService?.user.tenant.tenantName ?? ""
        if tenantName.count > 16 {
            let prefix = tenantName[tenantName.startIndex...tenantName.index(tenantName.startIndex, offsetBy: 7)]
            let suffix = tenantName[tenantName.index(tenantName.endIndex, offsetBy: -8)..<tenantName.endIndex]
            tenantName = "\(prefix)...\(suffix)"
        }
        return tenantName
    }

    init(resolver: UserResolver) throws {
        self.userResolver = resolver
        self.blurService = try AppLockSettingBlurService(userResolver: resolver)
        self.biometryAuth = AppLockSettingBiometryAuthentication(resolver: resolver)
        self.leanModeService = try? resolver.resolve(assert: ExternalDependencyService.self).leanModeService
        let settingService = try? resolver.resolve(assert: SCRealTimeSettingService.self)
        self.enableAppLockSettingsV2 = settingService?.bool(.enableAppLockSettingV2) ?? false
        Logger.info("AppLockSettingServiceImp enableAppLockSettingsV2 \(enableAppLockSettingsV2)")
        start()
        observeDataChange()
    }

    func checkAppLockSettingStatus(completed: ((Bool) -> Void)?) {
        DispatchQueue.runOnMainQueue { [weak self] in
            guard let self else { return }
            completed?(self.configInfo.isActive)
        }
    }

    func checkVerification() {
        if Thread.isMainThread {
            self.showVerifyVCIfNeeded(enterForeground: false)
        } else {
            DispatchQueue.main.async {
                self.showVerifyVCIfNeeded(enterForeground: false)
            }
        }
    }

    func checkAppLockSetting() {
        if Thread.isMainThread {
            self.showAppLockSettingIfNeeded()
        } else {
            DispatchQueue.main.async {
                self.showAppLockSettingIfNeeded()
            }
        }
    }

    func start() {
        SCMonitor.info(business: .app_lock, eventName: "service_action", category: ["action": "start"])

        stop()
        
        // Fix 首次登录完成，开启锁屏保护，退后台回前台，锁屏保护不生效问题，未登录下冷启动系统发Foreground 通知时该 Service 还未初始化，所以 skipedFirstForgroundExent 一直是false
        if UIDevice.current.userInterfaceIdiom == .pad, UIApplication.shared.applicationState != .background, !skipedFirstForgroundExent {
            skipedFirstForgroundExent = true
        }

        NotificationCenter.default.rx
            .notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                self?.triggerEnterBackgroundAction()
            }).disposed(by: self.disposeBag)

        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.checkBiometryStatus()
                // iPad上启动会触发一次进前台时间，需要跳过，否则会导致自动退出1min逻辑失效
                if UIDevice.current.userInterfaceIdiom == .pad && !self.skipedFirstForgroundExent {
                    self.skipedFirstForgroundExent = true
                    return
                }
                self.triggerEnterForegroundAction()
            }).disposed(by: self.disposeBag)
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .map { _ in }
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                Logger.info("app_lock_service_notification: type: didBecomeActiveNotification")
                if self.supportMultiSceneOpt {
                    if self.verifyAlert == nil {
                        self.blurService.removeBlurViews()
                    }
                } else {
                    self.blurService.removeBlurViews()
                }
            })
            .disposed(by: disposeBag)
        NotificationCenter.default.rx
            .notification(UIApplication.willResignActiveNotification)
            .map { _ in }
            .subscribe(onNext: { [weak self] in
                let requestingBiometric = self?.blurService.isRequestBiometric ?? false
                guard let self, self.configInfo.isActive, !requestingBiometric else { return }
                Logger.info("app_lock_service_notification: type: willResignActiveNotification")
                self.blurService.addBlurViews()
            })
            .disposed(by: disposeBag)
        
        if #available(iOS 13.0, *), supportMultiSceneOpt {
            NotificationCenter.default.rx
                .notification(UIScene.willDeactivateNotification)
                .subscribe(onNext: { [weak self] noti in
                    let requestingBiometric = self?.blurService.isRequestBiometric ?? false
                    guard let self,
                          let scene = noti.object as? UIWindowScene,
                          self.configInfo.isActive,
                          !requestingBiometric else { return }
                    self.blurService.addBlurView(forScene: scene)
                    Logger.info("app_lock_service_notification: type: UIScene.didEnterBackgroundNotification")
                })
                .disposed(by: disposeBag)
            
            NotificationCenter.default.rx
                .notification(UIScene.didActivateNotification)
                .subscribe(onNext: { [weak self] noti in
                    guard let self, let scene = noti.object as? UIWindowScene else { return }
                    if self.verifyAlert != nil {
                        self.blurService.showCoverView(forScene: scene)
                    } else {
                        self.blurService.removeBlurView(forScene: scene)
                    }
                    Logger.info("applock: scene did active: \(scene)")
                })
                .disposed(by: disposeBag)
            
            NotificationCenter.default.rx
                .notification(UIScene.willConnectNotification)
                .subscribe(onNext: { [weak self] noti in
                    guard let scene = noti.object as? UIWindowScene else { return }
                    if self?.verifyAlert != nil {
                        self?.blurService.addBlurView(forScene: scene)
                    }
                    Logger.info("applock: scene willConnect: \(scene)")

                })
                .disposed(by: disposeBag)
        }

    }

    func stop() {
        SCMonitor.info(business: .app_lock, eventName: "service_action", category: ["action": "stop"])

        self.disposeBag = DisposeBag()
        blurService.removeBlurViews()
    }

    private func observeDataChange() {
        // 监听锁屏密码变更
        leanModeService?.lockScreenStatus.subscribe(onNext: { [weak self] status in
            guard let `self` = self else { return }
            // 直接更新锁屏密码，已加密
            self.configInfo.updateServerPinCodeIfNeeded(
                encyptPinCode: status.encyptPinCode ?? "",
                isActive: status.isActive,
                updateTime: status.updateTime
            )
            // 服务端推送关闭密码之后直接关闭alert
            if !self.configInfo.isActive {
                self.dismissVerifyAlert()
            }
        }).disposed(by: self.pushDisposeBag)

        leanModeService?.beforeExit.subscribe {  [weak self]  _ in
            guard let `self` = self else { return }
            Logger.info("LeanMode: before exit, update auto exit time")
            self.configInfo.renewLastAutoExitTime()
        }.disposed(by: self.pushDisposeBag)
    }

    private func triggerEnterBackgroundAction() {
        if !configInfo.isActive || verifyAlert != nil {
            return
        }
        Logger.info("app_lock_service_notification: type: didEnterBackgroundNotification")

        self.blurService.addBlurViews()
        self.lastBackgroundTime = darwinTime()
    }

    private func triggerEnterForegroundAction() {
        self.showAppLockSettingIfNeeded()
        self.showVerifyVCIfNeeded(enterForeground: true)
        Logger.info("app_lock_service_notification: type: enterForegroundAction")

    }

    private func showVerifyVCIfNeeded(enterForeground: Bool) {
        blurService.removeVisibleVCs()

        SCMonitor.info(business: .app_lock, eventName: "service_action", category: ["action": "check_verification"])

        // 检查Face ID/Touch ID授权状态
        checkBiometryStatus()

        if !self.configInfo.isActive || self.verifyAlert != nil {
            return
        }

        // 如果没有超出自动退出时限，不用显示验证vc，此时会重置时间
        if !self.configInfo.isExceedAutoExitTimeAndReset() {
            return
        }
        // 进前台的时候判断上次进后台的时间间隔
        if enterForeground, darwinTime() - self.lastBackgroundTime < self.configInfo.timerFlag * 60 {
            return
        }

        self.showVerifyVC()
    }

    private func showVerifyVC() {
        SCMonitor.info(business: .app_lock, eventName: "service_action", category: ["action": "show_verify_vc"])

        let viewModel = AppLockSettingVerifyViewModel(userResolver: userResolver)
        viewModel.privacyModeEnable = { [weak self] in
            return self?.privacyModeEnable() ?? false
        }
        verifyAlert = AppLockVerifyAlert(resolver: userResolver)

        let dismissCallback: ((_ pinType: AppLockSettingPinType) -> Void)? = { [weak self] pinType in
            // 传入隐私模式回调
            guard let `self` = self else { return }
            self.dismissVerifyAlert()
            // 只有隐私保护模式有权限
            if pinType == .backward && self.privacyModeEnable() {
                self.openLeanMode()
            }
        }
        let vc: AppLockSettingVerifyViewControllerProtocol
        if enableAppLockSettingsV2 {
            vc = AppLockSettingV2.AppLockSettingVerifyViewController(resolver: userResolver, viewModel: viewModel, dismissCallback: dismissCallback)
        } else {
            vc = AppLockSettingVerifyViewController(resolver: userResolver, viewModel: viewModel, dismissCallback: dismissCallback)
        }
        verifyAlert?.show(rootVC: vc)
        blurService.addBlurViews()
        // 开始人脸识别检测
        vc.startVerify()
    }

    private func dismissVerifyAlert() {
        let action: () -> Void = { [weak self] in
            guard let `self` = self else { return }
            self.verifyAlert?.dismiss()
            self.verifyAlert = nil
            self.blurService.removeBlurViews()
        }
        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async {
                action()
            }
        }
    }

    // 检测biometry状态，当用户在外部将飞书的Face ID/Touch ID权限关闭后，飞书内也关闭；如果用户重新在外部打开权限，飞书内仍然关闭
    private func checkBiometryStatus() {
        Logger.info("app_lock_service_checkBiometryStatus")
        guard self.configInfo.isActive else {
            return
        }

        if self.configInfo.isBiometryEnable && !biometryAuth.isBiometryAvailable() {
            self.configInfo.isBiometryEnable = false
        }
    }
}

// 扩展隐私保护模式的能力-lean mode
extension AppLockSettingServiceImp {
    func privacyModeEnable() -> Bool {
        return leanModeService?.canUseLeanMode() ?? false
    }

    func openLeanMode() {
        leanModeService?.openLeanModeStatus()
        Logger.info("open lean mode")
    }

    @discardableResult
    func showAppLockSettingIfNeeded() -> Bool {
        let service = try? userResolver.resolve(assert: FeatureGatingService.self)
        let fgOpen = service?.staticFeatureGatingValue(with: "messenger.leanmode.privacymode") ?? false
        if !fgOpen {
            return false
        }

        if self.configInfo.isActive || !self.privacyModeEnable() {
            return false
        }

        if !self.configInfo.isExceedShowLockSettingTime() {
            return false
        }

        guard let vc = Navigator.shared.navigation else { // Global
            // 找不到root
            assertionFailure("Navigator.shared.navigation must have value") // Global
            return false
        }

        // 显示弹窗，更新上次显示设置的时间
        self.configInfo.lastShowLockSettingTimeStamp = Date().timeIntervalSince1970

        let alert = UDDialog()
        alert.setTitle(text: BundleI18n.PrivacyMode.Lark_Core_PrivacyProtectionMode_SafetyReminder_Title)
        alert.setContent(text: BundleI18n.PrivacyMode.Lark_Core_PrivacyProtectionMode_SafetyReminder_Desc)
        alert.addCancelButton()
        alert.addPrimaryButton(
            text: BundleI18n.PrivacyMode.Lark_Core_PrivacyProtectionMode_SafetyReminderGoToSettings_Button,
            dismissCompletion: { [weak self] in
                guard let self else { return }
                self.navigator.push(body: AppLockSettingBody(), from: vc)
            }
        )

        vc.present(alert, animated: true)

        return true
    }
}

// 使用系统时间，防止用户修改时间导致密码失效的漏洞
func darwinTime() -> Int {
    var uptime = timespec()
    if 0 != clock_gettime(CLOCK_MONOTONIC_RAW, &uptime) {
        fatalError("Could not execute clock_gettime, errno: \(errno)")
    }

    return uptime.tv_sec
}

final class AppLockSettingConfigInfo: Codable {

    enum CodingKeys: String, CodingKey {
        case isActive
        case timerFlag
        case pinCode
        case pinCodeVersion
        case isBiometryEnable
        case isPINExceedLimit
        case modifyLimitTimeStamp
        case lastAutoExitTime
        case lastShowLockSettingTimeStamp
        case serverUpdateTime
        case lastUsePinCodeTimeStamp
    }

    var appLockSettingConfigInfoKey: String = ""
    var userID = ""
    var tenantID = ""
    private var udkv: SCKeyValueStorage?

    let firstBiometricKey = "AppLockSettingFirstBiometricKey"

    var isFirstOpenBiometric: Bool {
        get {
            udkv?.bool(forKey: firstBiometricKey) ?? false
        }
        set {
            udkv?.set(newValue, forKey: firstBiometricKey)
        }
    }

    var isActive: Bool = false {
        didSet { setLocalConfigInfo() }
    }

    var timerFlag: Int = 1 {
        didSet { setLocalConfigInfo() }
    }

    var pinCode: String = "" {
        didSet { setLocalConfigInfo() }
    }

    // pinCode 加密方法的版本号
    var pinCodeVersion: String = "" {
        didSet { setLocalConfigInfo() }
    }

    var isBiometryEnable: Bool = false {
        didSet { setLocalConfigInfo() }
    }

    var isPINExceedLimit: Bool = false {
        didSet { setLocalConfigInfo() }
    }

    var modifyLimitTimeStamp: TimeInterval = 0 {
        didSet { setLocalConfigInfo() }
    }

    // 上次自动退出app的时间（系统时间）
    var lastAutoExitTime: Int = 0 {
        didSet { setLocalConfigInfo() }
    }

    // 上次显示应用锁的时间
    var lastShowLockSettingTimeStamp: TimeInterval = 0 {
        didSet { setLocalConfigInfo() }
    }

    // 服务端存储的数字密码和开关状态的更新时间
    var serverUpdateTime: Int64 = 0 {
        didSet { setLocalConfigInfo() }
    }

    // 上次使用密码解锁时间
    var lastUsePinCodeTimeStamp: TimeInterval = 0 {
        didSet { setLocalConfigInfo() }
    }

    // 更新上次使用密码解锁时间
    func renewUsePinCodeTimeStamp() {
        self.lastUsePinCodeTimeStamp = Date().timeIntervalSince1970
    }

    /// 更新自动退出时间错
    func renewLastAutoExitTime() {
        self.lastAutoExitTime = darwinTime()
    }

    // 检测是否上次自动退出时间是否超出，并重置（调用之后会重置时间）
    func isExceedAutoExitTimeAndReset() -> Bool {
        // 时间设定为1分钟
        let current = darwinTime()
        // current<lastAutoExitTime 表示重启过，是不合规的数据
        let result = current <= self.lastAutoExitTime || current - self.lastAutoExitTime > 60
        // 比较后清零
        if self.lastAutoExitTime != 0 {
            self.lastAutoExitTime = 0
        }
        return result
    }

    // 是否超出上次展示设置的时限
    func isExceedShowLockSettingTime() -> Bool {
        let secondsFromGMT = TimeInterval(TimeZone.current.secondsFromGMT())
        let current = Int(ceil((Date().timeIntervalSince1970 + secondsFromGMT) / (24 * 60 * 60)))
        let last = Int(ceil((self.lastShowLockSettingTimeStamp + secondsFromGMT) / (24 * 60 * 60)))
        // 天数相差一天时为超限，前面考虑了时区，加上时区时间差
        return current - last >= 1
    }

    /// 更改服务端下发的密码
    /// - Parameters:
    ///   - encyptPinCode: 已经通过sha256 hash的密码
    ///   - isActive: 开关状态
    ///   - updateTime: 服务端更新时间（单位ms）
    func updateServerPinCodeIfNeeded(encyptPinCode: String, isActive: Bool, updateTime: Int64) {
        if updateTime <= self.serverUpdateTime {
            return
        }
        if isActive && encyptPinCode.isEmpty {
            SCMonitor.error(business: .app_lock, eventName: "invalid_data_pin_code_is_empty_but_active")
            return
        }

        self.pinCode = encyptPinCode
        self.pinCodeVersion = PinCodeEncryptionFactory.getNewestEncryptionTypeString() // 已经更新直接更新为V3
        self.isActive = isActive
        self.serverUpdateTime = updateTime
    }

    /// 是否只能使用数字密码
    func shouldUsePinCode() -> Bool {
        // 超过14天时，只能用数字密码解锁
        return Date().timeIntervalSince1970 - self.lastUsePinCodeTimeStamp > 14 * 24 * 60 * 60
    }

    func timerFlagDesc(flag: Int? = nil) -> String {
        let f = flag ?? timerFlag
        if f == 0 {
            return BundleI18n.AppLock.Lark_Screen_TimeOptionsSoon
        } else {
            return BundleI18n.AppLock.Lark_Screen_TimeOptions(f)
        }
    }

    func isModifyLimitValid() -> Bool {
        if modifyLimitTimeStamp == 0 {
            return false
        }
        if Date().timeIntervalSince1970 - modifyLimitTimeStamp < 0 {
            return true
        }
        modifyLimitTimeStamp = 0
        return false
    }

    func updatePinCodeAndPinCodeVersion(pinCode: String) {
        SCMonitor.info(business: .app_lock, eventName: "config_info", category: ["action": "set_pincode_and_version"])

        self.pinCode = PinCodeEncryptionFactory.getNewestEncryptionType().encryptedValue(pinCode: pinCode) // 总是使用最新的加密方式
        self.pinCodeVersion = PinCodeEncryptionFactory.getNewestEncryptionTypeString() // 总是使用最新的version
    }

    // 验证比较 pinCode 值是否与存储值一致
    func comparePinCode(pinCode: String) -> Bool {
        SCMonitor.info(business: .app_lock, eventName: "config_info", category: ["action": "compare_pincode", "pincode_version": self.pinCodeVersion])

        var version: PinCodeVersion
        if self.pinCodeVersion.isEmpty {
            version = .noVersion
        } else {
            if let tempVersion = PinCodeVersion(rawValue: self.pinCodeVersion) {
                version = tempVersion
            } else {
                Logger.error("error pinCode version of config info")
                return false
            }
        }
        // 使用 pinCode 对应的加密方式加密
        let encryptedPinCode = PinCodeEncryptionFactory.getEncryptionType(pinCodeVersion: version).encryptedValue(pinCode: pinCode)
        let comparingResult = self.pinCode == encryptedPinCode
        // 如果验证成功 && 密码版本不是最新的版本，则使用新加密方式存储pinCode
        if self.pinCodeVersion != PinCodeEncryptionFactory.getNewestEncryptionTypeString() && comparingResult {
            SCMonitor.info(business: .app_lock, eventName: "config_info", category: ["action": "update_pincode_version"])

            Logger.info("switch pinCode encryption type")
            updatePinCodeAndPinCodeVersion(pinCode: pinCode)
        }

        return comparingResult
    }

    private func getLocalConfigInfo(for key: String) -> AppLockSettingConfigInfo? {
        var info: AppLockSettingConfigInfo?
        if let data = udkv?.data(forKey: key) {
            do {
                let decoder = JSONDecoder()
                info = try decoder.decode(AppLockSettingConfigInfo.self, from: data)
                info?.appLockSettingConfigInfoKey = key
            } catch {
                Logger.info("Unable to Decode Note (\(error))")
            }
        }
        return info
    }

    private func setLocalConfigInfo() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            udkv?.set(data, forKey: appLockSettingConfigInfoKey)
        } catch {
            Logger.info("Unable to Encode Note (\(error))")
        }
    }

    init(for key: String, userID: String, tenantID: String) {
        self.appLockSettingConfigInfoKey = key
        self.userID = userID
        self.tenantID = tenantID
        self.udkv = SCKeyValue.userDefaultEncrypted(userId: userID, business: .appLock)
        reset(for: key)
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isActive = try values.decode(Bool.self, forKey: .isActive)
        timerFlag = try values.decode(Int.self, forKey: .timerFlag)
        let code = try values.decode(String.self, forKey: .pinCode)
        // 如果存的是明文(老版本)，立即进行加密处理
        if code.count == 4 {
            pinCode = code.md5()
        } else {
            pinCode = code
        }
        // 兼容考虑，老版本没有以下字段，给默认值 ""
        pinCodeVersion = (try? values.decode(String.self, forKey: .pinCodeVersion)) ?? ""
        isBiometryEnable = try values.decode(Bool.self, forKey: .isBiometryEnable)
        isPINExceedLimit = try values.decode(Bool.self, forKey: .isPINExceedLimit)
        modifyLimitTimeStamp = try values.decode(TimeInterval.self, forKey: .modifyLimitTimeStamp)
        // 新增字段，默认为0
        lastAutoExitTime = (try? values.decode(Int.self, forKey: .lastAutoExitTime)) ?? 0
        lastShowLockSettingTimeStamp = (try? values.decode(TimeInterval.self, forKey: .lastShowLockSettingTimeStamp)) ?? 0
        serverUpdateTime = (try? values.decode(Int64.self, forKey: .serverUpdateTime)) ?? 0
        lastUsePinCodeTimeStamp = (try? values.decode(TimeInterval.self, forKey: .lastUsePinCodeTimeStamp)) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(timerFlag, forKey: .timerFlag)
        // 如果长度为4，进行md5加密
        let code = pinCode.count == 4 ? pinCode.md5() : pinCode
        try container.encode(code, forKey: .pinCode)
        try container.encode(pinCodeVersion, forKey: .pinCodeVersion)
        try container.encode(isBiometryEnable, forKey: .isBiometryEnable)
        try container.encode(isPINExceedLimit, forKey: .isPINExceedLimit)
        try container.encode(modifyLimitTimeStamp, forKey: .modifyLimitTimeStamp)
        try container.encode(lastAutoExitTime, forKey: .lastAutoExitTime)
        try container.encode(lastShowLockSettingTimeStamp, forKey: .lastShowLockSettingTimeStamp)
        try container.encode(serverUpdateTime, forKey: .serverUpdateTime)
        try container.encode(lastUsePinCodeTimeStamp, forKey: .lastUsePinCodeTimeStamp)
    }

    private func reset(for key: String) {
        let info = getLocalConfigInfo(for: key)
        // 如果解析失败，所有字段给默认值
        isActive = info?.isActive ?? false
        pinCode = info?.pinCode ?? ""
        pinCodeVersion = info?.pinCodeVersion ?? ""
        timerFlag = info?.timerFlag ?? 1
        isBiometryEnable = info?.isBiometryEnable ?? false
        isPINExceedLimit = info?.isPINExceedLimit ?? false
        modifyLimitTimeStamp = info?.modifyLimitTimeStamp ?? 0
        lastAutoExitTime = info?.lastAutoExitTime ?? 0
        lastShowLockSettingTimeStamp = info?.lastShowLockSettingTimeStamp ?? 0
        serverUpdateTime = info?.serverUpdateTime ?? 0
        lastUsePinCodeTimeStamp = info?.lastUsePinCodeTimeStamp ?? 0
    }

    static func clean(configInfoKey: String, userID: String?) {
        guard let userID else { return }
        SCKeyValue.userDefaultEncrypted(userId: userID, business: .appLock).removeObject(forKey: configInfoKey)
    }
}
