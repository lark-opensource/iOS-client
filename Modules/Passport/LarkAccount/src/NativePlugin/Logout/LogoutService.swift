//
//  LogoutService.swift
//  LarkAccount
//
//  Created by Yiming Qu on 2021/1/10.
//

import Foundation
import RxSwift
import LarkContainer
import LarkAccountInterface
import LKCommonsLogging
import RxRelay
import LarkAlertController
import EENavigator
import Reachability
import ECOProbeMeta
import BootManager

class LogoutService {

    static let logger = Logger.plog(LogoutService.self, category: "SuiteLogin.LogoutService")

    @Provider private var logoutAPI: LogoutAPI // user:checked (global-resolve)
    @Provider private var apiHelper: V3APIHelper
    private var offlineLogoutHelper: OfflineLogoutHelper { OfflineLogoutHelper.shared }
    private let disposeBag = DisposeBag()
    @Provider private var envManager: EnvironmentInterface
    @Provider private var loginService: V3LoginService
    private var loginStateSub: BehaviorRelay<V3LoginState> { loginService.loginStateSub }
    private var userManager: UserManager { UserManager.shared }
    @Provider private var launcher: Launcher
    @Provider var stateService: PassportStateService
    @Provider var passportService: PassportService

    private lazy var uniContext = UniContextCreator.create(.logout)

    init() {
        offlineLogoutHelper.start()
    }

    func relogin(
        conf: LogoutConf,
        onError: @escaping (_ message: String) -> Void,
        onSuccess: @escaping (_ message: String?) -> Void,
        onInterrupt: @escaping () -> Void
    ) {
        var logoutType = ""
        switch conf.type {
        case .all:
            logoutType = "all_logout"
        case .foreground:
            logoutType = "single_logout"
        case .background:
            logoutType = "multiple_logout"
        default:
            logoutType = "unknown"
        }
        setupUnicontext(conf: conf)
        Self.logger.info("n_action_logout_start", body: "type: \(logoutType), trigger: \(conf.trigger.monitorDescription), currentUID: \(self.userManager.foregroundUser?.userID ?? "")")
        PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_start, categoryValueMap: ["type": logoutType], context: uniContext)
        
        let successBlock: (String?) -> Void = { message in
            Self.logger.info("n_action_logout_succ")
            PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_end_succ, categoryValueMap: ["type": logoutType], context: self.uniContext)
            onSuccess(message)
        }
        
        // 已经退出
        /// 当 存在多个身份 & 已经登出前台身份 & 自动切换身份失败 时，BootManagerLauncherDelegate 会强制登出，此时前台用户为 nil，但应该继续登出流程，否则无法返回登录页面
        /// https://meego.feishu.cn/larksuite/issue/detail/5409734
        if !conf.forceLogoutAll && userManager.foregroundUser == nil {
            Self.logger.warn("n_action_logout_succ_skipped", body: "foreground user is nil")
            PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_end_succ, categoryValueMap: ["type": logoutType], context: uniContext)
            successBlock(nil)
            return
        }

        // 无网 并且登出单个用户时直接返回错误
        let netUnavailable = (Reachability()?.connection ?? Reachability.Connection.none) == Reachability.Connection.none
        if netUnavailable && conf.type == .foreground  {
            Self.logger.error("n_action_logout_fail_no_network")
            onError(I18N.Lark_Core_LoginNoInternetConnection_Toast)
            return
        }

        /// 如果不存在中断退出信号，或者是强制退出的话，就直接退出
        let interruptOperations = loginService.interruptOperations
        if interruptOperations.isEmpty || conf.forceLogout {
            Self.logger.info("n_action_logout_direct_logout", additionalData: [
                "inerruptSignalsCount": String(describing: interruptOperations.count),
                "forceLogout": String(describing: conf.forceLogout)
            ])
            self.confirmRelogin(
                conf: conf,
                onSuccess: successBlock,
                onError: onError
            )
            return
        }

        let interruptObservable = interruptOperations.map { (interrupt) -> Single<Bool> in
            return interrupt.getInterruptObservable(type: .relogin)
        }

        Self.logger.info("n_native_logout_check_interrupt", additionalData: [
            "signals": String(describing: interruptObservable.map({ String(describing: $0) }))
        ])
        Single
            .zip(interruptObservable)
            .catchError({ (error) -> Single<[Bool]> in
                Self.logger.error("n_native_logout_check_interrupt_error", error: error)
                // 忽略中断信号的错误，继续登出流程
                return Single.just([true])
            })
            .flatMap { (result) -> Single<Bool> in
                for res in result where res == false {
                    return Single.just(false)
                }
                return Single.just(true)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (isNeedLogout) in
                Self.logger.info("n_action_logout_interrupt_end", additionalData: [
                    "isNeedLogout": String(describing: isNeedLogout)
                ])
                if isNeedLogout {
                    self?.confirmRelogin(
                        conf: conf,
                        onSuccess: successBlock,
                        onError: onError
                    )
                } else {
                    Self.logger.info("n_action_logout_interrupted")
                    onInterrupt()
                }
            }).disposed(by: disposeBag)
    }

    private func confirmRelogin(
        conf: LogoutConf,
        onSuccess: @escaping (_ message: String?) -> Void,
        onError: @escaping (_ message: String) -> Void) {

        let needAlert = conf.needAlert
        guard needAlert, let message = conf.message, !message.isEmpty else {
            Self.logger.info("n_action_logout_no_message")
            internalRelogin(
                conf: conf,
                onSuccess: onSuccess,
                onError: onError
            )
            return
        }
            guard let mainSceneWindow = PassportNavigator.keyWindow else {
            Self.logger.errorWithAssertion("n_action_logout_no_scene")
            return
        }

        Self.logger.info("n_action_logout_alert")
        let alertController = LarkAlertController()
        alertController.setContent(text: message)
        alertController.addPrimaryButton(text: BundleI18n.LarkAccount.Lark_Legacy_Sure, dismissCompletion: { [weak self] in
            self?.internalRelogin(
                conf: conf,
                onSuccess: onSuccess,
                onError: onError)
        })
        Navigator.shared.present(alertController, from: mainSceneWindow) // user:checked (navigator)
    }

    private func internalRelogin(
        conf: LogoutConf,
        onSuccess: @escaping (String?) -> Void,
        onError: @escaping (String) -> Void
    ) {
        PassportMonitor.flush(PassportMonitorMetaLogout.startLogout,
                              eventName: ProbeConst.monitorEventName,
                              context: uniContext)
        ProbeDurationHelper.startDuration(ProbeDurationHelper.logoutPrimaryFlow)

        if !conf.forceLogoutAll && userManager.foregroundUser == nil {
            Self.logger.warn("n_action_logout_succ_internal_skipped", body: "Foreground user is nil")
            PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_end_succ, context: uniContext)
            monitorLogoutEventResult(isSucceeded: true)
            onSuccess(nil)
            return
        }
        
        self.launcher.execute(.beforeLogout, block: {
            $0.beforeLogout()
            $0.beforeLogout(conf: conf)
        })

        if let foregroundUserID = userManager.foregroundUser?.userID {
            logoutAPI.barrier(userID: foregroundUserID,
                              enter: { leave in
                DispatchQueue.main.async {
                    if MultiUserActivitySwitch.enableMultipleUser {
                        self.logoutMultiUserVersion(
                            conf: conf,
                            leave: leave,
                            onSuccess: onSuccess,
                            onError: onError)
                    } else {
                        self.logout(
                            conf: conf,
                            leave: leave,
                            onSuccess: onSuccess,
                            onError: onError
                        )
                    }
                }
            })
        } else {
            Self.logger.warn("n_action_logout_succ_internal_skipped", body: "Foreground user has no id")
        }
    }

    private func logout(
        conf: LogoutConf,
        leave: @escaping (_ finish: Bool) -> Void,
        onSuccess: @escaping (String?) -> Void,
        onError: @escaping (String) -> Void
    ) {
        var logoutUsers = [V4UserInfo]()
        switch conf.type {
        case .foreground:
            if let foregroundUser = userManager.foregroundUser {
                logoutUsers = [foregroundUser]
            } else {
                // 当用户在账号安全中心注销账号时，会在短时间内触发 session 失效和 PassportUnRegisterHandler（JSAPI）中的登出逻辑
                // 有一定概率前面的 logout 将 foreground user 置空，后面的 logout 走到此分支
                assertionFailure("n_action_logout_error_nil_foreground_user")
                Self.logger.warn("n_action_logout_error_nil_foreground_user")
                monitorLogoutEventResult(isSucceeded: false, errorMsg: BundleI18n.LarkAccount.Lark_Legacy_NetUnavailableNow)
                leave(false)
                onError(BundleI18n.LarkAccount.Lark_Legacy_NetUnavailableNow)
                return
            }
        case .all:
            logoutUsers = userManager.getUserList()
        case .background:
            logoutUsers = userManager.getUserList().filter({ user in
                user.userID != userManager.foregroundUser?.userID
            })
        default:
            assertionFailure("Unknown logout type")
        }
        
        let sessionKeys = logoutUsers.map({ $0.suiteSessionKey ?? "" })
        let logoutTokens = logoutUsers.map({ $0.logoutToken ?? "" })
        let userIds = logoutUsers.map({ $0.userID })
        
        let desensitizedTokens = logoutTokens.map { $0.desensitized() }
        Self.logger.info("n_action_logout_request_start", body: "tokens: \(desensitizedTokens)")
        PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_app_request_start, context: uniContext)
        let makeOffline = conf.type != .background
        let logoutType: CommonConst.LogoutType = conf.trigger.getLogoutType()
        // logout实现包含了native服务端接口调用和rust makeoffline
        var request = logoutAPI.logout(sessionKeys: sessionKeys, makeOffline: makeOffline, logoutType: logoutType, context: uniContext)
        if logoutType == .onDemand {
            // 登出体验优化：用户主动登出时增加 10s 超时
            Self.logger.info("n_action_logout_ondemand_add_timeout")
            request = request.timeout(.seconds(10), scheduler: MainScheduler.instance)
        }
        request
            .observeOn(MainScheduler.instance)
            .map({ () -> String? in
                return nil
            })
            .catchError({ [weak self] (error) -> Observable<String?> in
                guard let self = self else { return .just(nil) }

                Self.logger.error("n_action_logout_request_fail", error: error)

                // *** 注意！ ***
                // *** catch error 内部 return 时，需要确保 offline 操作被执行 ***
                func onOffline() {
                    if makeOffline {
                        Self.logger.error("n_action_logout_request_fail", body: "make offline")
                        self.logoutAPI.makeOffline()
                            .subscribe()
                            .disposed(by: self.disposeBag)
                    }
                    self.offlineLogoutHelper.append(logoutTokens: logoutTokens)
                }

                /// 登出体验优化
                /// https://bytedance.feishu.cn/docx/BdGmdBsSEo4f6HxAQbkccoLXnhg
                /// 1. 弱网 10s 超时
                /// 登出所有身份：退到登录页
                /// 登出部分身份：中断登出，toast 提示
                /// 2. 无网络
                /// 登出所有身份：退到登录页，toast 提示
                /// 登出部分身份：中断登出，toast 提示
                if logoutType == .onDemand {
                    let isLogoutAll = conf.type == .all
                    let isTimeoutError: Bool
                    if let error = error as? RxError, case .timeout = error {
                        isTimeoutError = true
                    } else {
                        isTimeoutError = false
                    }
                    let isUnreachableError: Bool
                    if let error = error as? NSError, error.domain == NSURLErrorDomain {
                        isUnreachableError = true
                    } else if case V3LoginError.server(let error) = error,
                              let nsError = error as? NSError,
                              nsError.domain == NSURLErrorDomain {
                        isUnreachableError = true
                    } else {
                        isUnreachableError = false
                    }

                    Self.logger.error("n_action_logout_request_fail", body: "logout all: \(isLogoutAll), unreachable: \(isUnreachableError)")

                    if isTimeoutError {
                        if !isLogoutAll {
                            throw V3LoginError.networkTimeout
                        }
                    } else if isUnreachableError {
                        if isLogoutAll {
                            onOffline()
                            return .just(I18N.Lark_Core_LoginNoInternetConnection_Toast)
                        } else {
                            throw V3LoginError.networkNotReachable(true)
                        }
                    }
                }

                // 其他错误
                onOffline()
                return .just(nil)
            })
            .do(onDispose: {
                leave(false)
            }) // always finish when complete or error or disposed
            .subscribe(onNext: { [weak self] message in
                guard let self = self else { return }
                Self.logger.info("n_action_logout_request_succ")
                PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_app_request_succ, context: self.uniContext)

                //发送确认登出的userList通知
                self.launcher.execute(.logoutUserList, block: { $0.logoutUserList(by: userIds) })

                self.processLogoutSuccess(
                    conf: conf,
                    complete: {
                        self.logout(conf, userIds, releaseBarrier: {
                            // 这个回调如果传 true 会 dispose rust client，导致后续的登出接口调用失败
                            leave(conf.type != .background)
                        })

                        onSuccess(message)
                    })
            }, onError: { [weak self] error in
                guard let self = self else { return }
                leave(false)

                if let error = error as? V3LoginError {
                    switch error {
                    case .networkTimeout:
                        self.monitorLogoutEventResult(isSucceeded: false, errorMsg: I18N.Lark_Core_LoginNetworkErroe_Toast)
                        onError(I18N.Lark_Core_LoginNetworkErroe_Toast)
                    case .networkNotReachable:
                        self.monitorLogoutEventResult(isSucceeded: false, errorMsg: I18N.Lark_Core_LoginNoInternetConnection_Toast)
                        onError(I18N.Lark_Core_LoginNoInternetConnection_Toast)
                    default:
                        self.monitorLogoutEventResult(isSucceeded: false, error: error)
                        onError(error.localizedDescription)
                    }
                } else {
                    self.monitorLogoutEventResult(isSucceeded: false, error: error)
                    onError(error.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }

    private func logout(_ conf: LogoutConf, _ userIds: [String], releaseBarrier: () -> Void) {
        Self.logger.info("n_action_logout_all_clear_data", body: "clear_data")
        
        if MultiUserActivitySwitch.enableMultipleUser {
            removeLogoutUserListMultiUserVersion(by: userIds)
        } else {
            removeLogoutUserList(by: userIds)
        }

        if conf.type == .all {
            // 登出全部时，清空本地的
            userManager.resetStoredUser()
        }
        releaseBarrier()
        
        // 退出后台用户不执行切面
        if conf.type == .background {
            return
        }
        
        Self.logger.info("n_action_logout_afterlogout_task")
        
        let context = self.launcher.launcherContext
        self.launcher.execute(
            .afterLogout,
            block: {
                $0.afterLogout(context)
                $0.afterLogout(context: context, conf: conf)
            }
        )
        context.reset()

        // 只在 UserScope 生效时执行，否则在 BootManagerLauncherDelegate 中执行
        if PassportUserScope.enableUserScope {
            goToDestination(conf: conf)
        }
    }

    private func processLogoutSuccess(
        conf: LogoutConf,
        complete: @escaping () -> Void
    ) {
        PassportMonitor.flush(PassportMonitorMetaLogout.startLogoutTaskHandle,
                              eventName: ProbeConst.monitorEventName,
                              context: uniContext)
        ProbeDurationHelper.startDuration(ProbeDurationHelper.logoutPostTaskFlow)
        if conf.type == .background {
            Self.logger.info("n_action_logout_multiple_end", body: "background logout")
            monitorLogoutPostTaskResult(isSucceeded: true)
            monitorLogoutEventResult(isSucceeded: true)
            complete()
            return
        }

        UploadLogManager.shared.userId = nil
        PassportProbeHelper.shared.userID = nil
        PassportProbeHelper.shared.tenantID = nil

        self.apiHelper.cleanCache()
        
        #if ONE_KEY_LOGIN
        Self.logger.info("n_action_logout_notify_onekeylogin")
        OneKeyLogin.logoutSucceed()
        #endif
        
        func internalComplete() {
            loginStateSub.accept(.notLogin)
            complete()
        }

        /// 退出单个用户不切环境，否则makeonline会报错，makeoffline的时候rust内部会切环境
        if conf.type == .foreground {
            Self.logger.info("n_action_logout_single_end")
            monitorLogoutPostTaskResult(isSucceeded: true)
            monitorLogoutEventResult(isSucceeded: true)
            internalComplete()
            return
        }

        Self.logger.info("n_action_logout_all_clear_data", body: "reset_env")

        /// SET\_ENV 在弱网下最多会等待 120s，影响用户体验
        /// 目前 Android/PC 没有等待回调，此处保险起见只在跨端时等待回调
        if SwitchEnvironmentManager.shared.isCrossUnit {
            envManager.resetEnv { [weak self] isSucceeded in
                guard let self = self else { return }
                if isSucceeded {
                    self.monitorLogoutPostTaskResult(isSucceeded: true)
                    self.monitorLogoutEventResult(isSucceeded: true)
                } else {
                    self.monitorLogoutPostTaskResult(isSucceeded: false, errorMsg: "logout reset env error, cross unit")
                    self.monitorLogoutEventResult(isSucceeded: false, errorMsg: "logout reset env error, cross unit")
                }
                /// 不管重置环境成功或者失败，都回调
                Self.logger.info("n_action_logout_all_end")
                internalComplete()
            }
        } else {
            envManager.resetEnv { [weak self] isSucceeded in
                guard let self = self else { return }
                if isSucceeded {
                    self.monitorLogoutPostTaskResult(isSucceeded: true)
                    self.monitorLogoutEventResult(isSucceeded: true)
                } else {
                    self.monitorLogoutPostTaskResult(isSucceeded: false, errorMsg: "logout reset env error, not cross unit")
                    self.monitorLogoutEventResult(isSucceeded: false, errorMsg: "logout reset env error, not cross unit")
                }
            }
            internalComplete()
            Self.logger.info("n_action_logout_all_end_cross_unit")
        }
    }

    /// 移除已经登出的 user
    func removeLogoutUserList(by userIDs: [String]) {
        guard let foregroundUser = userManager.foregroundUser else {
            Self.logger.warn("n_action_logout_all_clear_data", body: "Foreground user is nil")
            userManager.removeUsers(by: userIDs)
            return
        }

        // 某些 KA 不允许多账号同时登录，登出的用户不一定包含前台用户 https://bytedance.feishu.cn/docs/doccnfLmKuFekUh9p7kbH3XvPMb
        let foregroundLogout = userIDs.contains(foregroundUser.userID)
        if foregroundLogout {
            Self.logger.info("n_action_logout_all_clear_data", body: "Removing foreground user")
            userManager.updateForegroundUser(nil)
        }

        // 只有在前台用户登出时执行切面
        let foregroundAccount = foregroundUser.makeAccount()
        if foregroundLogout {
            Self.logger.info("n_action_logout_all_clear_data", body: "Execute .beforeLogoutClearAccount")
            launcher.execute(.beforeLogoutClearAccount, block: { $0.beforeLogoutClearAccount(foregroundAccount) })
        }
        userManager.removeUsers(by: userIDs)
        if foregroundLogout {
            Self.logger.info("n_action_logout_all_clear_data", body: "Execute .afterLogoutClearAccount")

            let newState = PassportState(user: foregroundUser.makeUser(), loginState: .offline, action: .logout)
            stateService.updateState(newState: newState)
            
            launcher.execute(.afterLogoutClearAccoount, block: { $0.afterLogoutClearAccoount(foregroundAccount) })

            let finalState = PassportState(user: nil, loginState: .offline, action: .logout)
            stateService.updateState(newState: finalState)
        }
    }

    private func goToDestination(conf: LogoutConf) {
        switch conf.destination {
        case .login:
            if conf.needEraseData {
                NewBootManager.shared.logoutAndLogin(isRollback: conf.isRollbackLogout)
            } else {
                NewBootManager.shared.login(conf.isRollbackLogout)
            }
        case .launchGuide:
            NewBootManager.shared.launchGuide(conf.isRollbackLogout)
        case .switchUser:
            Self.logger.info("n_action_logout", body: "switch user")
            if userManager.getActiveUserList().isEmpty {
                Self.logger.info("n_action_logout", body: "no available user to switch, go to login")
                NewBootManager.shared.login(conf.isRollbackLogout)
            }
        @unknown default:
            Self.logger.error("unhandled logout destination \(conf.description)")
        }
    }

    // MARK: - Monitor

    // 登出主流程
    private func monitorLogoutEventResult(isSucceeded: Bool, errorMsg: String? = nil, error: Error? = nil) {
        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.logoutPrimaryFlow)
        if isSucceeded {
            PassportMonitor.monitor(PassportMonitorMetaLogout.logoutSuccess, eventName: ProbeConst.monitorEventName, categoryValueMap: [ProbeConst.duration: duration], context: uniContext).setResultTypeSuccess().flush()
            
            return
        }

        let monitor = PassportMonitor.monitor(PassportMonitorMetaLogout.logoutFail,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.duration: duration],
                                              context: uniContext)
        let message: String? = (errorMsg != nil) ? errorMsg : "logout primary flow error \(error?.localizedDescription ?? "")"
        if let error = error {
            _ = monitor.setPassportErrorParams(error: error)
        }
        monitor.setResultTypeFail().setErrorMessage(message).flush()
    }

    // 网络请求后登出业务处理
    private func monitorLogoutPostTaskResult(isSucceeded: Bool, errorMsg: String? = nil, error: Error? = nil) {
        let duration = ProbeDurationHelper.stopDuration(ProbeDurationHelper.logoutPostTaskFlow)
        let monitor = PassportMonitor.monitor(PassportMonitorMetaLogout.logoutTaskHandleResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.duration: duration],
                                              context: uniContext)

        if isSucceeded {
            monitor.setResultTypeSuccess().flush()
        } else {
            monitor.setResultTypeFail()
            let message: String? = (errorMsg != nil) ? errorMsg : "logout post task flow error \(error?.localizedDescription ?? "")"
            if let error = error {
                monitor.setPassportErrorParams(error: error)
            }
            monitor.setErrorMessage(message).flush()
        }
    }

    // https://bytedance.feishu.cn/wiki/UJR8wrK0PiuBSFkXsdGcVo9Lnbg?scene=multi_page&sub_scene=message
    private func setupUnicontext(conf: LogoutConf) {
        // 主动退出 0，被动退出 1
        let type = (conf.trigger == .manual || conf.trigger == .setting || conf.trigger == .debugSwitchEnv) ? 0 : 1
        let userType = conf.type == .all ? "all" : "single"
        let reason = conf.trigger.monitorDescription
        uniContext.params.updateValue(type, forKey: ProbeConst.logoutType)
        uniContext.params.updateValue(userType, forKey: ProbeConst.logoutUserType)
        uniContext.params.updateValue(reason, forKey: ProbeConst.logoutReason)
    }
}

// TODO: MultiUser
// Logout MultiUser Version
extension LogoutService {
    private func logoutMultiUserVersion(
        conf: LogoutConf,
        leave: @escaping (_ finish: Bool) -> Void,
        onSuccess: @escaping (String?) -> Void,
        onError: @escaping (String) -> Void
    ) {
        Self.logger.info("n_action_logout: logoutMultiUserVersion")
        var logoutUsers = [V4UserInfo]()
        switch conf.type {
        case .foreground:
            if let foregroundUser = userManager.foregroundUser {
                logoutUsers = [foregroundUser]
            } else {
                // 当用户在账号安全中心注销账号时，会在短时间内触发 session 失效和 PassportUnRegisterHandler（JSAPI）中的登出逻辑
                // 有一定概率前面的 logout 将 foreground user 置空，后面的 logout 走到此分支
                assertionFailure("n_action_logout_error_nil_foreground_user")
                Self.logger.warn("n_action_logout_error_nil_foreground_user")
                monitorLogoutEventResult(isSucceeded: false, errorMsg: BundleI18n.LarkAccount.Lark_Legacy_NetUnavailableNow)
                leave(false)
                onError(BundleI18n.LarkAccount.Lark_Legacy_NetUnavailableNow)
                return
            }
        case .all:
            logoutUsers = userManager.getUserList()
        case .background:
            logoutUsers = userManager.getUserList().filter({ user in
                user.userID != userManager.foregroundUser?.userID
            })
        default:
            assertionFailure("Unknown logout type")
        }

        let sessionKeys = logoutUsers.map({ $0.suiteSessionKey ?? "" })
        let logoutTokens = logoutUsers.map({ $0.logoutToken ?? "" })
        let userIds = logoutUsers.map({ $0.userID })

        let desensitizedTokens = logoutTokens.map { $0.desensitized() }
        Self.logger.info("n_action_logout_request_start", body: "tokens: \(desensitizedTokens)")
        PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_app_request_start, context: uniContext)
        let makeOffline = conf.type != .background
        let logoutType: CommonConst.LogoutType = conf.trigger.getLogoutType()
        // logout实现包含了native服务端接口调用和rust makeoffline
        // 跨租户消息通知版本，不聚合 make offline
        var request = logoutAPI.logout(sessionKeys: sessionKeys, makeOffline: false, logoutType: logoutType, context: uniContext)
        if logoutType == .onDemand {
            // 登出体验优化：用户主动登出时增加 10s 超时
            Self.logger.info("n_action_logout_ondemand_add_timeout")
            request = request.timeout(.seconds(10), scheduler: MainScheduler.instance)
        }
        request
            .observeOn(MainScheduler.instance)
            .flatMap({ [weak self] _ -> Observable<Void> in
                Self.logger.info("n_action_logout_rust_offline")
                guard let self = self else { return .just(()) }
                return removeLogoutUsers(ids: userIds, action: .logout, context: self.uniContext)
            })
            .map({ () -> String? in
                return nil
            })
            .catchError({ [weak self] (error) -> Observable<String?> in
                guard let self = self else { return .just(nil) }

                Self.logger.error("n_action_logout_request_fail", error: error)

                // *** 注意！ ***
                // *** catch error 内部 return 时，需要确保 offline 操作被执行 ***
                func onOffline() {
                    Self.logger.error("n_action_logout_request_fail", body: "make offline")
                    removeLogoutUsers(ids: userIds, action: .logout, context: self.uniContext)
                        .subscribe()
                        .disposed(by: self.disposeBag)
                    self.offlineLogoutHelper.append(logoutTokens: logoutTokens)
                }

                /// 登出体验优化
                /// https://bytedance.feishu.cn/docx/BdGmdBsSEo4f6HxAQbkccoLXnhg
                /// 1. 弱网 10s 超时
                /// 登出所有身份：退到登录页
                /// 登出部分身份：中断登出，toast 提示
                /// 2. 无网络
                /// 登出所有身份：退到登录页，toast 提示
                /// 登出部分身份：中断登出，toast 提示
                if logoutType == .onDemand {
                    let isLogoutAll = conf.type == .all
                    let isTimeoutError: Bool
                    if let error = error as? RxError, case .timeout = error {
                        isTimeoutError = true
                    } else {
                        isTimeoutError = false
                    }
                    let isUnreachableError: Bool
                    if let error = error as? NSError, error.domain == NSURLErrorDomain {
                        isUnreachableError = true
                    } else if case V3LoginError.server(let error) = error,
                              let nsError = error as? NSError,
                              nsError.domain == NSURLErrorDomain {
                        isUnreachableError = true
                    } else {
                        isUnreachableError = false
                    }

                    Self.logger.error("n_action_logout_request_fail", body: "logout all: \(isLogoutAll), unreachable: \(isUnreachableError)")

                    if isTimeoutError {
                        if !isLogoutAll {
                            throw V3LoginError.networkTimeout
                        }
                    } else if isUnreachableError {
                        if isLogoutAll {
                            onOffline()
                            return .just(I18N.Lark_Core_LoginNoInternetConnection_Toast)
                        } else {
                            throw V3LoginError.networkNotReachable(true)
                        }
                    }
                }

                // 其他错误
                onOffline()
                return .just(nil)
            })
            .do(onDispose: {
                leave(false)
            }) // always finish when complete or error or disposed
            .subscribe(onNext: { [weak self] message in
                guard let self = self else { return }
                Self.logger.info("n_action_logout_request_succ")
                PassportMonitor.flush(EPMClientPassportMonitorLogoutCode.passport_logout_app_request_succ, context: self.uniContext)

                //发送确认登出的userList通知
                self.launcher.execute(.logoutUserList, block: { $0.logoutUserList(by: userIds) })

                self.processLogoutSuccess(
                    conf: conf,
                    complete: {
                        self.logout(conf, userIds, releaseBarrier: {
                            // 这个回调如果传 true 会 dispose rust client，导致后续的登出接口调用失败
                            leave(conf.type != .background)
                        })

                        onSuccess(message)
                    })
            }, onError: { [weak self] error in
                guard let self = self else { return }
                leave(false)

                if let error = error as? V3LoginError {
                    switch error {
                    case .networkTimeout:
                        self.monitorLogoutEventResult(isSucceeded: false, errorMsg: I18N.Lark_Core_LoginNetworkErroe_Toast)
                        onError(I18N.Lark_Core_LoginNetworkErroe_Toast)
                    case .networkNotReachable:
                        self.monitorLogoutEventResult(isSucceeded: false, errorMsg: I18N.Lark_Core_LoginNoInternetConnection_Toast)
                        onError(I18N.Lark_Core_LoginNoInternetConnection_Toast)
                    default:
                        self.monitorLogoutEventResult(isSucceeded: false, error: error)
                        onError(error.localizedDescription)
                    }
                } else {
                    self.monitorLogoutEventResult(isSucceeded: false, error: error)
                    onError(error.localizedDescription)
                }
            }).disposed(by: disposeBag)
    }

    private func removeLogoutUserListMultiUserVersion(by userIDs: [String]) {
        Self.logger.info("n_action_logout: removeLogoutUserListMultiUserVersion")
        userManager.removeUsers(by: userIDs)
    }

    private func removeLogoutUsers(ids: [String], action: PassportUserAction, context: UniContextProtocol) -> Observable<Void> {
        return Observable.create { (ob) -> Disposable in
            let workflow = (removeUsersHasSideEffectTask(context: context, action: action))
            workflow.runnable(ids).execute { _ in
                // 暂不关注成功的返回结果
                ob.onNext(())
                ob.onCompleted()
            } failureCallback: { error in
                ob.onError(error)
            }
            return Disposables.create()
        }
    }
}

extension LogoutConf {
    /// 遇到某些错误（如登出前台用户后自动切换用户失败）时强制登出所有用户
    var forceLogoutAll: Bool {
        return forceLogout && type == .all && destination == .login
    }
}

extension LogoutTrigger {
    func getLogoutType() -> CommonConst.LogoutType {
        switch self {
        case .setting:
            return .onDemand
        case .sessionRiskCountdown:
            return .sessionRisk
        default:
            return .passive
        }
    }
}
