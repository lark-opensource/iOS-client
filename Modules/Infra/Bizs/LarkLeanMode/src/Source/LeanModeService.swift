//
//  LeanModeService.swift
//  LarkLeanMode
//
//  Created by 袁平 on 2020/3/6.
//

import UIKit
import Foundation
import RxSwift
import RustPB
import EENavigator
import LarkAccountInterface
import LarkSetting
import LarkStorage
import LKCommonsLogging
import SuiteAppConfig
import LarkRustClient
import UniverseDesignToast
import UniverseDesignDialog
import LarkSceneManager
import LarkContainer

public protocol LeanModeService {
    /// 当前精简模式状态
    var currentLeanModeStatusAndAuthority: LeanModeStatusAndAuthority { get }

    /// 当前精简模式状态监听
    var leanModeStatus: Observable<Bool> { get }

    /// 定时数据清理
    var dataClean: Observable<PushCleanDataResponse> { get }

    ///  锁屏状态（只有精简模式可用时有数据-canUseLeanMode为true）
    var lockScreenStatus: Observable<LockScreenConfig> { get }

    /// 切换精简模式退出前的信号
    var beforeExit: Observable<Void> { get }

    /// 主动开关精简模式
    func switchLeanModeStatus()

    /// 拉取当前设备精简模式状态和权限
    func fetchLeanModeStatusAndAuthority()

    /// 通过接口关闭精简模式
    func closeLeanModeStatus()

    /// 通过接口开启精简模式
    func openLeanModeStatus()

    /// 更新精简模式状态和权限
    func updateLeanModeStatusAndAuthority(statusAndAuthority: LeanModeStatusAndAuthority, scene: LeanModeDataScene)

    /// 修改锁屏密码 & 锁屏是否开启
    /// - Parameters:
    ///   - password: 锁屏密码
    ///   - isEnabled: 锁屏密码是否开启
    func patchLockScreenConfig(password: String?, isEnabled: Bool?) -> Observable<PatchLockScreenCfgResponse>
}

final class LeanModeServiceImpl: LeanModeService {
    private static let logger = Logger.log(LeanModeServiceImpl.self,
                                           category: "LarkLeanMode.LeanModeServiceImpl")
    private let remindSecurityPwdTime: TimeInterval = 60 * 60 // 进入前台，时间间隔大于1小时，提醒设置安全验证码

    private let leanModeAPI: LeanModeAPI
    private var leanModeDependency: LeanModeDependency
    private let disposeBag: DisposeBag
    private let passportService: PassportUserService
    private let fgService: FeatureGatingService

    var currentLeanModeStatusAndAuthority: LeanModeStatusAndAuthority {
        return leanModeAPI.currentLeanModeStatusAndAuthority
    }

    var leanModeStatus: Observable<Bool> {
        return leanModeAPI.leanModeStatusAndAuthorityObservable
            .map({ $0.0.allDevicesInLeanMode })
            .distinctUntilChanged()
            .asObservable()
    }

    var lockScreenStatus: Observable<LockScreenConfig> {
        return leanModeAPI.leanModeStatusAndAuthorityObservable.filter {
            $0.0.canUseLeanMode
        } .map {
            var config = LockScreenConfig()
            config.lockScreenPassword = $0.0.lockScreenPassword
            config.isLockScreenEnabled = $0.0.isLockScreenEnabled
            config.lockScreenCfgUpdatedAtMicroSec = $0.0.lockScreenUpdateTime
            return config
        }.asObservable()
    }

    var dataClean: Observable<PushCleanDataResponse> {
        return leanModeAPI.dataCleanObservable
    }

    private let beforeExitSubject: PublishSubject<Void> = PublishSubject()
    var beforeExit: Observable<Void> {
        return beforeExitSubject.asObserver()
    }

    private var isAddForegroundNotify: Bool = false
    private var isPatching: Bool = false // 是否正在patch网络请求

    // KV存储部分
    private lazy var userStore = KVStores.LeanMode.user(id: passportService.user.userID)
    private static let userStore = \LeanModeServiceImpl.userStore
    @KVBinding(to: userStore, key: "TimeInterval", default: 0)
    private var leanModeTimeInterval: Double
    @KVBinding(to: userStore, key: "SecurityPwdStatus", default: false)
    private var securityPwdStatus: Bool
    let userResolver: UserResolver
    var navigator: Navigatable {
        if fgService.dynamicFeatureGatingValue(with: "lark.security.enable_security_user_container_opt") {
            Self.logger.info("lean mode use userResolver.navigator")
            return userResolver.navigator
        }
        return Navigator.shared // global
    }

    init(userResolver: UserResolver,
         leanModeAPI: LeanModeAPI,
         leanModeDependency: LeanModeDependency,
         passportService: PassportUserService,
         fgService: FeatureGatingService) {
        self.userResolver = userResolver
        self.leanModeAPI = leanModeAPI
        self.leanModeDependency = leanModeDependency
        self.passportService = passportService
        self.fgService = fgService
        self.disposeBag = DisposeBag()
        bindObserver()
    }

    private func bindObserver() {
        self.leanModeAPI.leanModeStatusAndAuthorityObservable
            .distinctUntilChanged({ (new, old) -> Bool in
                return new.0.allDevicesInLeanMode == old.0.allDevicesInLeanMode
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (status) in
                guard let `self` = self else { return }
                if status.1 == .push, !self.isPatching {
                    self.passivelySwitchLeanMode(status: status.0.allDevicesInLeanMode)
                }
            })
            .disposed(by: disposeBag)

        self.leanModeAPI.leanModeStatusAndAuthorityObservable
            .distinctUntilChanged({ (old, new) -> Bool in
                return old.0.deviceHaveAuthority == new.0.deviceHaveAuthority
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (authority) in
                guard let `self` = self else { return }
                if authority.1 == .push, !self.isPatching {
                    // 管理员授权使用权限
                    if authority.0.deviceHaveAuthority {
                        // 1. 检查安全验证码状态
                        self.checkSecurityPwdStatus()
                        // 2. 添加前台监听
                        self.notifySecurityPwdStatus()
                    }
                }
            })
            .disposed(by: disposeBag)

        self.leanModeAPI.offlineSwitchFailed
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (_) in
                self?.offlineSwitchFailed()
            })
            .disposed(by: disposeBag)
    }

    /// 主动开关精简模式
    func switchLeanModeStatus() {
        let statusAndAuthority = leanModeAPI.currentLeanModeStatusAndAuthority
        LeanModeServiceImpl.logger.info("LeanMode: user switch leanmode status",
                                        additionalData: ["statusAndAuthority": "\(statusAndAuthority)"])
        if statusAndAuthority.allDevicesInLeanMode {
            self.userCloseLeanMode(status: statusAndAuthority)
        } else {
            self.userOpenLeanMode(status: statusAndAuthority)
        }
    }

    /// 拉取精简模式状态和权限
    func fetchLeanModeStatusAndAuthority() {
        LeanModeServiceImpl.logger.info("LeanMode: fetchLeanModeStatusAndAuthority")
        return leanModeAPI.fetchLeanModeStatusAndAuthority(syncDataStrategy: .tryLocal)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                // 每次拉取都同步一次到Appconfig
                self.syncAppConfig(shouldExit: false)
            })
            .disposed(by: disposeBag)
    }

    // 直接关闭精简模式
    func closeLeanModeStatus() {
        let statusAndAuthority = leanModeAPI.currentLeanModeStatusAndAuthority
        // 已经关闭不处理
        if !statusAndAuthority.allDevicesInLeanMode {
            return
        }
        self.patchLeanMode(on: false)
    }

    // 直接开启精简模式
    func openLeanModeStatus() {
        let statusAndAuthority = leanModeAPI.currentLeanModeStatusAndAuthority
        // 已经开启不做处理
        if statusAndAuthority.allDevicesInLeanMode {
            return
        }
        self.patchLeanMode(on: true)
    }

    /// 更新精简模式状态和权限
    func updateLeanModeStatusAndAuthority(statusAndAuthority: LeanModeStatusAndAuthority, scene: LeanModeDataScene) {
        leanModeAPI.updateLeanModeStatusAndAuthority(statusAndAuthority: statusAndAuthority, scene: scene)
        self.syncAppConfig(shouldExit: false)
    }

    /// 修改锁屏密码
    func patchLockScreenConfig(password: String?, isEnabled: Bool?) -> Observable<PatchLockScreenCfgResponse> {
        return leanModeAPI.patchLockScreenConfig(password: password, isEnabled: isEnabled).do(onError: { [weak self] error in
            guard let self else { return }
            guard let window = self.navigator.mainSceneWindow else {
                assertionFailure("缺少Window")
                return
            }
            UDToast.showFailure(with: I18n.Lark_Security_LeanModeSomethingWentWrongGeneralToast, on: window)
            LeanModeServiceImpl.logger.error("LeanMode: patchLockScreenConfig fail", error: error)
        })
    }

    /// 用户主动开启精简模式
    private func userOpenLeanMode(status: LeanModeStatusAndAuthority) {
        // 鉴权，是否有权限开启
        guard status.canUseLeanMode else { return }
        let alert = UDDialog()
        alert.setTitle(text: I18n.Lark_Security_LeanModeConfirmTurnOnPopUpTitle)
        alert.addCancelButton()
        alert.addPrimaryButton(text: I18n.Lark_Security_LeanModePopUpGeneralButtonConfirm, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            self.patchLeanMode(on: true)
            LeanModeTrackUtil.confirmOpenLeanMode(syncAllDevice: true)
        })
        navigator.present(alert, from: leanModeDependency.routerFromProvider)
        LeanModeServiceImpl.logger.info("LeanMode: user open leanmode")
        LeanModeTrackUtil.attemptOpenLeanMode()
    }

    /// 用户主动关闭精简模式
    private func userCloseLeanMode(status: LeanModeStatusAndAuthority) {
        // 鉴权，是否有权限关闭
        guard status.deviceHaveAuthority else {
            promptAlert(content: I18n.Lark_Security_LeanModeTurnOffNoAccessContent)
            LeanModeServiceImpl.logger.info("LeanMode: deviceHaveAuthority = false ")
            return
        }
        let alert = UDDialog()
        alert.setTitle(text: I18n.Lark_Security_LeanModeConfirmTurnOffPopUpTitle)
        alert.addCancelButton()
        alert.addPrimaryButton(text: I18n.Lark_Security_LeanModePopUpGeneralButtonConfirm, dismissCompletion: { [weak self] in
            guard let `self` = self else { return }
            let verifySuccess: VerifySuccess = { controller in
                controller.dismiss(animated: true) { [weak self] in
                    self?.patchLeanMode(on: false)
                }
                LeanModeTrackUtil.closeAllDevice()
                LeanModeTrackUtil.securityPwdVerifySuccess()
                LeanModeServiceImpl.logger.info("LeanMode: security pwd verify success")
            }
            let verifyFail: VerifyFail = { _ in
                LeanModeServiceImpl.logger.info("LeanMode: security pwd verify fail")
            }
            let controller = LeanModeVerifyController(verifySuccess: verifySuccess,
                                                      verifyFail: verifyFail,
                                                      passportService: self.passportService)
            navigator.present(controller,
                                     from: self.leanModeDependency.routerFromProvider,
                                     prepare: { $0.modalPresentationStyle = .fullScreen })
        })
        navigator.present(alert, from: leanModeDependency.routerFromProvider)
        LeanModeServiceImpl.logger.info("LeanMode: user close leanmode")
        LeanModeTrackUtil.attemptCloseLeanMode()
    }

    /// 离线开启精简模式，在线之后失去权限
    private func offlineSwitchFailed() {
        promptAlert(content: I18n.Lark_Security_LeanModeAccessRemovedPopUpContent) { [weak self] in
            LeanModeServiceImpl.logger.info("LeanMode: offlineSwitchFailed")
            self?.syncAppConfig(shouldExit: true)
        }
    }

    private func promptAlert(title: String = I18n.Lark_Security_LeanModePopUpGeneralTitle,
                             content: String,
                             buttonText: String = I18n.Lark_Security_LeanModePopUpGeneralAckButton,
                             from: UIViewController? = nil,
                             completion: (() -> Void)? = nil) {
        let from = from ?? leanModeDependency.routerFromProvider
        let alert = UDDialog()
        alert.setTitle(text: title)
        alert.setContent(text: content)
        alert.addPrimaryButton(text: buttonText, dismissCompletion: {
            completion?()
        })
        navigator.present(alert, from: from)
    }

    private func patchLeanMode(on: Bool) {
        func isNotPermitted(error: Error) -> Bool {
            if let error = error as? RCError, case .businessFailure(let errorInfo) = error, errorInfo.code == 4500 {
                return true
            }
            return false
        }

        LeanModeServiceImpl.logger.info("LeanMode: patchLeanMode", additionalData: ["on": "\(on)"])
        func switchLeanMode() {
            // 1. Loading
            showLoading(show: true)
            isPatching = true
            // 2. 网络请求开/关
            self.leanModeAPI.patchLeanModeStatus(on: on)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] (_) in
                    LeanModeServiceImpl.logger.info("LeanMode: patch success")
                    self?.syncAppConfig(shouldExit: true)
                }, onError: { [weak self] (error) in
                    self?.showLoading(show: false)
                    self?.isPatching = false
                    guard let window = self?.navigator.mainSceneWindow else {
                        assertionFailure("缺少Window")
                        return
                    }
                    // 4500 未没权限，不显示错误
                    if !isNotPermitted(error: error) {
                        UDToast.showFailure(with: I18n.Lark_Security_LeanModeSomethingWentWrongGeneralToast, on: window)
                    }
                    LeanModeServiceImpl.logger.error("LeanMode: patch error", error: error)
                    // 打开精简模式失败的时候直接退出应用
                    if on {
                        exit(0)
                    }
                })
                .disposed(by: self.disposeBag)

        }
        if enableCloseOtherScene {
            // 1. 关闭其他 Scene
            closeOtherAssitantScenes()
            // 2. iPad 支持多Scene时，需要 delay 一定时间执行后面的逻辑，不然关闭Scene会和exit方法同时执行，多屏下导致exit方法不生效
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: switchLeanMode)
        } else {
            switchLeanMode()
        }
    }
    
    /// FG: 精简模式切换时是否关闭 iPad 上其他Scene，true: 关闭，false：不关闭
    private var enableCloseOtherScene: Bool {
        SceneManager.shared.supportsMultipleScenes && !fgService.dynamicFeatureGatingValue(with: "disable_lean_mode_close_scene")
    }
    
    /// 精简模式切换时关闭iPad上其他Scene，此方法受上面开关控制
    private func closeOtherAssitantScenes() {
        guard enableCloseOtherScene else { return }
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            for uiScene in scenes {
                let scene = uiScene.sceneInfo
                if !scene.isMainScene() {
                    SceneManager.shared.deactive(scene: scene)
                }
            }
            LeanModeServiceImpl.logger.info("LeanMode: close other scene", additionalData: ["count": "\(scenes.count - 1)"])
        }
    }

    /// 检查是否添加设置安全验证码提醒
    private func notifySecurityPwdStatus() {
        guard !isAddForegroundNotify else { return }
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                self.isAddForegroundNotify = true
                let lastTimeInterval = self.leanModeTimeInterval
                let curTimeInterval = Date().timeIntervalSince1970
                if lastTimeInterval <= 0 || (curTimeInterval - lastTimeInterval) >= self.remindSecurityPwdTime {
                    self.checkSecurityPwdStatus()
                }
            })
            .disposed(by: disposeBag)
    }

    /// 被动开关精简模式
    private func passivelySwitchLeanMode(status: Bool) {
        func switchLeanMode() {
            guard UIApplication.shared.applicationState != .background else {
                // 后台直接重启
                LeanModeServiceImpl.logger.info("LeanMode: app is background, exit(0)")
                self.syncAppConfig(shouldExit: true)
                return
            }
            // 被动开启时直接退出，不弹框
            if status {
                self.syncAppConfig(shouldExit: true)
            } else {
                self.promptAlert(content: I18n.Lark_Security_LeanModeConfirmForcedOffPopUpContent,
                            buttonText: I18n.Lark_Security_LeanModeConfirmForcedOffPopUpButtonConfirm) { [weak self] in
                    self?.syncAppConfig(shouldExit: true)
                }
            }
            LeanModeServiceImpl.logger.info("LeanMode: passivelySwitchLeanMode, status = \(status)")
        }
        if enableCloseOtherScene {
            // 1. 关闭其他 Scene
            closeOtherAssitantScenes()
            // 2. iPad 支持多Scene时，需要 delay 一定时间执行后面的逻辑，不然关闭Scene会和exit方法同时执行，多屏下导致exit方法不生效
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: switchLeanMode)
        } else {
            switchLeanMode()
        }
    }

    /// 检查当前安全验证码状态
    private func checkSecurityPwdStatus() {
        guard !securityPwdStatus else { return }
        LeanModeServiceImpl.logger.info("LeanMode: checkSecurityPwdStatus")
        self.passportService
            .getCurrentSecurityPwdStatus()
            .map({ $0.0 && $0.1 })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (isCompleteSercurityPwd) in
                guard let `self` = self else { return }
                guard !isCompleteSercurityPwd else {
                    // 设置过安全验证码就移除监听，否则每次进入前台都会检查
                    NotificationCenter.default.removeObserver(self)
                    self.isAddForegroundNotify = false
                    self.securityPwdStatus = true
                    LeanModeServiceImpl.logger.info("LeanMode: security pwd has set")
                    return
                }
                // 尚未设置安全验证码
                self.remindCompleteSecurityPwd()
            })
            .disposed(by: self.disposeBag)
    }

    /// 提醒设置安全验证码
    private func remindCompleteSecurityPwd() {
        let alert = UDDialog()
        alert.setTitle(text: I18n.Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpTitle)
        alert.setContent(text: I18n.Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpContentMobile)
        alert.addSecondaryButton(text: I18n.Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonRemindLater, dismissCompletion: { [weak self] in
            self?.updateRemindTime()
        })
        alert.addPrimaryButton(text: I18n.Lark_Security_LeanModePleaseSetSecurityVerificationCodePopUpButtonSetNow, dismissCompletion: { [weak self] in
            // 立即设置
            guard let mainSceneTopMost = self?.navigator.mainSceneTopMost else {
                assertionFailure()
                return
            }
            self?.passportService.pushSecurityPwdSettingViewController(from: mainSceneTopMost)
            self?.updateRemindTime()
        })
        navigator.present(alert, from: leanModeDependency.routerFromProvider)
    }

    private func updateRemindTime() {
        let curTimeInterval = Date().timeIntervalSince1970
        self.leanModeTimeInterval = curTimeInterval
    }

    private func showLoading(show: Bool) {
        if show {
            leanModeDependency.showLoading = true
        } else {
            leanModeDependency.showLoading = false
        }
    }


    /// 同步精简模式状态到appconfig
    /// - Parameter shouldExit: 更新完成后是否退出app
    private func syncAppConfig(shouldExit: Bool) {
        let userId = passportService.user.userID
        // 获取当前状态更新
        let status = currentLeanModeStatusAndAuthority.allDevicesInLeanMode
        LeanModeServiceImpl.logger.info("LeanMode: sync AppConfig success and will exit",
                                        additionalData: ["status": "\(status)",
                                                         "exit": "\(shouldExit)"])
        AppConfigManager.shared.updateLocalConfigStatus(status: status, userId: userId)
        if shouldExit {
            beforeExitSubject.onNext(())
            exit(0)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
