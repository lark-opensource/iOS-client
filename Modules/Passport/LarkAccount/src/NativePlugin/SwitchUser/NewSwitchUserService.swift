//
//  NewSwitchUserService.swift
//  LarkAccount
//
//  Created by bytedance on 2021/8/31.
//

import Foundation
import LarkContainer
import RxSwift
import RoundedHUD
import EENavigator
import LKCommonsLogging
import LarkAccountInterface
import ThreadSafeDataStructure
import ECOProbeMeta
import LarkAlertController
import BootManager

class NewSwitchUserService {

    //当前处理中的 flow
    private var currentFlow: SwitchUserFlow?

    @Provider private var launcher: Launcher
    @Provider var stateService: PassportStateService
    @Provider var userManager: UserManager

    @Provider private var logoutService: LogoutService

    //flow处理状态
    var stage: SafeAtomic<SwitchUserStage> = .idle + .readWriteLock

    private let logger = Logger.plog(NewSwitchUserService.self, category: "NewSwitchUserService")

    private let disposeBag = DisposeBag()

    //passport 通用 error 处理
    private var errorHandler: V3ErrorHandler? {
        if let vc = Navigator.shared.navigation { // user:checked (navigator)
            return V3ErrorHandler(vc: vc, context: UniContextCreator.create(.switchUser), showToastOnWindow: true)
        }
        logger.error(SULogKey.switchCommon, body: "error handler has no viewController", method: .local)
        return nil
    }

    /// 切换用户
    /// - Parameters:
    ///   - userID: 目标用户的 userId
    ///   - complete: 切换成功,失败的回调
    ///   - additionInfo: 切换行为的附加信息
    ///   - context: passport 的 context 上下文
    public func switchTo(userID: String, complete: SwitchUserCompletionCallback?, additionInfo: SwitchUserContextAdditionInfo? = nil, context: UniContextProtocol) {
        logger.info(SULogKey.switchStart, body: "userID, switchReason: \(context.from.rawValue)",
                    additionalData: ["current_userID": UserManager.shared.foregroundUser?.userID ?? "", "target_userID": userID, // user:current
                                     "current_session": (UserManager.shared.foregroundUser?.suiteSessionKey ?? "").desensitized(), // user:current
                                     "target_session": (UserManager.shared.getUser(userID: userID)?.suiteSessionKey ?? "").desensitized()])

        let flow = SwitchUserDefaultFlow(userID: userID, additionInfo: additionInfo, monitorContext: SwitchUserMonitorContext(type: .onDemand, reason: context.from), passportContext: context)
        commitFlow(flow, complete: complete)
    }

    /// 切换用户
    /// - Parameters:
    ///   - userID: 目标用户的 userId
    ///   - complete: 切换成功,失败的回调
    ///   - additionInfo: 切换行为的附加信息
    ///   - context: passport 的 context 上下文
    public func switchTo(userID: String, credentialID: String? = nil, complete: SwitchUserCompletionCallback?, additionInfo: SwitchUserContextAdditionInfo? = nil, context: UniContextProtocol) {
        logger.info(SULogKey.switchStart, body: "userID and credentialID, switchReason: \(context.from.rawValue)",
                    additionalData: ["current_userID": UserManager.shared.foregroundUser?.userID ?? "", "target_userID": userID, // user:current
                                     "current_session": (UserManager.shared.foregroundUser?.suiteSessionKey ?? "").desensitized(), // user:current
                                     "target_session": (UserManager.shared.getUser(userID: userID)?.suiteSessionKey ?? "").desensitized(),
                                     "credential_id": credentialID ?? "empty"
                                    ])
        let flow = SwitchUserDefaultFlow(userID: userID, credentialID: credentialID, additionInfo: additionInfo, monitorContext: SwitchUserMonitorContext(type: .onDemand, reason: context.from), passportContext: context)
        commitFlow(flow, complete: complete)
    }


    /// 切换用户
    /// - Parameters:
    ///   - userInfo: 目标用户的 userInfo
    ///   - complete: 切换成功,失败的回调
    ///   - additionInfo: 切换行为的附加信息
    ///   - context: passport 的 context 上下文
    public func switchTo(userInfo: V4UserInfo, complete: SwitchUserCompletionCallback?, additionInfo: SwitchUserContextAdditionInfo? = nil, context: UniContextProtocol) {
        logger.info(SULogKey.switchStart, body: "userInfo, switchReason: \(context.from.rawValue)",
                    additionalData: ["current_userID": UserManager.shared.foregroundUser?.userID ?? "", "target_userID": userInfo.userID, // user:current
                                     "current_session": (UserManager.shared.foregroundUser?.suiteSessionKey ?? "").desensitized(), // user:current
                                     "target_session": (UserManager.shared.getUser(userID: userInfo.userID)?.suiteSessionKey ?? "").desensitized()])
    
        let flow = SwitchUserDefaultFlow(userInfo: userInfo, additionInfo: additionInfo, monitorContext: SwitchUserMonitorContext(type: .onDemand, reason: context.from), passportContext: context)
        commitFlow(flow, complete: complete)
    }

    /// 切换用户
    /// - Parameters:
    ///   - enterApp: enterAppInfo
    ///   - complete: 切换成功,失败的回调
    ///   - additionInfo: 切换行为的附加信息
    ///   - context: passport 的 context 上下文
    public func switchTo(enterApp: V4EnterAppInfo, complete: SwitchUserCompletionCallback?, additionInfo: SwitchUserContextAdditionInfo? = nil, context: UniContextProtocol) {
        guard let userInfo = enterApp.userList.first else {
            self.logger.error(SULogKey.switchFail, body: "enterApp has no target userInfo")
            complete?(false)
            return
        }
        logger.info(SULogKey.switchStart, body: "enterApp, switchReason: \(context.from.rawValue)",
                    additionalData: ["current_userID": UserManager.shared.foregroundUser?.userID ?? "", "target_userID": userInfo.userID, // user:current
                                     "current_session": (UserManager.shared.foregroundUser?.suiteSessionKey ?? "").desensitized(), // user:current
                                     "target_session": (UserManager.shared.getUser(userID: userInfo.userID)?.suiteSessionKey ?? "").desensitized()])

        var flow: SwitchUserFlow
        //目标租户是有效的, 且不是对端的情况, 走fast切换逻辑
        if userInfo.isActive {
            self.logger.info(SULogKey.switchStart, body: "use enterAppFlow", method: .local)
            flow = SwitchUserWithoutServerInteractionFlow(userInfo: userInfo, additionInfo: additionInfo, monitorContext: SwitchUserMonitorContext(type: .fast, reason: context.from), passportContext: context)
        } else {
            self.logger.info(SULogKey.switchStart, body: "use defaultFlow", method: .local)
            flow = SwitchUserDefaultFlow(userInfo: userInfo, additionInfo: additionInfo, monitorContext: SwitchUserMonitorContext(type: .passive, reason: context.from), passportContext: context)
        }
        commitFlow(flow, complete: complete)
    }

    /// 快速切换用户
    /// - Parameters:
    ///   - enterApp: enterAppInfo
    ///   - complete: 切换成功,失败的回调
    ///   - additionInfo: 切换行为的附加信息
    ///   - context: passport 的 context 上下文
    public func fastSwitch(userInfo: V4UserInfo, complete: SwitchUserCompletionCallback?, additionInfo: SwitchUserContextAdditionInfo? = nil, context: UniContextProtocol) {

        logger.info(SULogKey.switchStart, body: "fastSwitch, switchReason: \(context.from.rawValue)",
                    additionalData: ["current_userID": UserManager.shared.foregroundUser?.userID ?? "", "target_userID": userInfo.userID, // user:current
                                     "current_session": (UserManager.shared.foregroundUser?.suiteSessionKey ?? "").desensitized(), // user:current
                                     "target_session": (UserManager.shared.getUser(userID: userInfo.userID)?.suiteSessionKey ?? "").desensitized()])

        var flow: SwitchUserFlow
        //目标租户是有效的, 且不是对端的情况, 走fast切换逻辑
        if userInfo.isActive {
            self.logger.info(SULogKey.switchStart, body: "use enterAppFlow", method: .local)
            flow = SwitchUserWithoutServerInteractionFlow(userInfo: userInfo, additionInfo: additionInfo, monitorContext: SwitchUserMonitorContext(type: .fast, reason: context.from), passportContext: context)
        } else {
            self.logger.info(SULogKey.switchStart, body: "use defaultFlow", method: .local)
            flow = SwitchUserDefaultFlow(userInfo: userInfo, additionInfo: additionInfo, monitorContext: SwitchUserMonitorContext(type: .passive, reason: context.from), passportContext: context)
        }
        commitFlow(flow, complete: complete)
    }

    /// 不需要请求 switch_identity 接口的切换
    open func switchWithoutServerInteraction(userInfo: V4UserInfo, complete: SwitchUserCompletionCallback?, additionInfo: SwitchUserContextAdditionInfo? = nil, context: UniContextProtocol) {
        self.logger.info(SULogKey.switchStart, body: "use withoutServerInteractionFlow",
                         additionalData: ["current_userID": UserManager.shared.foregroundUser?.userID ?? "", "target_userID": userInfo.userID, // user:current
                                          "current_session": (UserManager.shared.foregroundUser?.suiteSessionKey ?? "").desensitized()]) // user:current
        let flow = SwitchUserWithoutServerInteractionFlow(userInfo: userInfo, additionInfo: additionInfo, monitorContext: SwitchUserMonitorContext(type: .fast, reason: context.from), passportContext: context)
        commitFlow(flow, complete: complete)
    }

    /// 自动切换到下一个有效的用户
    /// - Parameters:
    ///   - additionInfo: 切换行为的附加信息
    ///   - complete: 切换成功,失败的回调
    ///   - context: passport 的 context 上下文
    public func autoSwitch(additionInfo: SwitchUserContextAdditionInfo? = nil, complete: SwitchUserCompletionCallback?, context: UniContextProtocol) {
        logger.info(SULogKey.switchStart, body: "switch to valid, switchReason: \(context.from.rawValue)",
                    additionalData: ["current_userID": UserManager.shared.foregroundUser?.userID ?? "", // user:current
                                     "current_session": (UserManager.shared.foregroundUser?.suiteSessionKey ?? "").desensitized()]) // user:current

        let flow = SwitchUserAutoSwitchFlow(passportContext: context, monitorContext: SwitchUserMonitorContext(type: .auto, reason: context.from), additionInfo: additionInfo)
        commitFlow(flow, complete: complete)
    }

    /// 继续切换用户流程; 目前用于自动切换时,目标用户还需要进行额外的验证
    /// - Parameter enterAppInfo: 服务端返回的 enterAppInfo
    public func continueSwitch(enterAppInfo: V4EnterAppInfo) {
        if let block = currentFlow?.switchContext?.continueSwitchBlock {
            block(enterAppInfo)
            logger.info(SULogKey.switchContinue)
        } else {
            //log
            logger.error(SULogKey.switchContinue, body: "fatal")
            assertionFailure("fatal error; please contact passport")
        }
    }

    //提交 flow, 开始执行切换
    private func commitFlow(_ flow: SwitchUserFlow, complete: SwitchUserCompletionCallback?) {
        guard stage.value == .idle else {
            logger.error(SULogKey.switchFail, body: "switching", additionalData: ["from": String(flow.passportContext.from.rawValue)])
            complete?(false)
            return
        }

        updateStage(.ready)
        logger.info(SULogKey.switchStart, body: "committed", method: .local)

        flow.lifeCycle = self
        currentFlow = flow

        flow.completionCallback = complete

        flow.executeFlow { [weak self] in
            complete?(true)
            self?.logger.info(SULogKey.switchSucc, body: "callback done")
        } failCallback: { [weak self] error in
            complete?(false)
            self?.logger.info(SULogKey.switchFail, body: "callback done")
        }

        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchUserEntry, context: flow.monitorContext)
    }
}

extension NewSwitchUserService: SwitchUserLifeCycle {

    private func updateStage(_ newValue: SwitchUserStage) {
        guard newValue != stage.value else { return }

        stage.value = newValue

        switch stage.value {
        case .executing: showHud()
        case .finished: clean()
        default: break
        }

        logger.info(SULogKey.switchStage, body: stage.value.rawValue, method: .local)
    }

    func beginSwitchAccount(flow: SwitchUserFlow) { SuiteLoginUtil.runOnMain { self._beginSwitchAccount(flow: flow)} }
    private func _beginSwitchAccount(flow: SwitchUserFlow) {
        logger.info(SULogKey.switchNotifyStart)
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchUserStart, categoryValueMap: ["uni_did": PassportStore.shared.universalDeviceServiceUpgraded ? 1: 0], timerStart: .switchUser, context: flow.monitorContext)

        updateStage(.executing)

        launcher.execute(.beforeSwitchAccount, block: { $0.beforeSwitchAccout() })
    }

    func switchAccountSucceed(flow: SwitchUserFlow, switchContext: SwitchUserContext) {
        SuiteLoginUtil.runOnMain { self._switchAccountSucceed(flow: flow, switchContext: switchContext) }
    }
    private func _switchAccountSucceed(flow: SwitchUserFlow, switchContext: SwitchUserContext) {
        guard let userInfo = switchContext.switchUserInfo else {
            //理论上不存在这种情况
            let error = AccountError.notFoundTargetUser
            self.afterSwitchAccout(error: error)
                .subscribe().disposed(by: self.disposeBag)
            logger.error(SULogKey.switchNotifyFail, body: "not found target user info")
            flow.failCallback?(error)
            return
        }
        //call block callback
        //新版本直接使用completionCallback回调，
        flow.completionCallback?(true)

        //call launcher delegates
        logger.info(SULogKey.switchNotifySucc,
                    additionalData: ["target_userID": userInfo.userID,
                                     "target_session": (UserManager.shared.getUser(userID: userInfo.userID)?.suiteSessionKey ?? "").desensitized()])
        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.afterSwitchNotifyStart, categoryValueMap: ["notify_type": "success"], timerStart: .afterSwitchNotify, context: flow.monitorContext)

        afterSwitchAccout(error: nil).subscribe(onCompleted: { [weak self] in
            guard let self = self else { return }

            let launcherContext = self.launcher.launcherContext
                .merge(userInfo: userInfo, isFastLogin: false)
            self.launcher.execute(.switchAccountSucceed, block: {
                $0.switchAccountSucceed(context: launcherContext)
            })

            //监控
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.afterSwitchNotifyComplete, categoryValueMap: ["notify_type": "success"], timerStop: .afterSwitchNotify, isSuccessResult: true, context: flow.monitorContext)

            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchUserResult, categoryValueMap: ["uni_did": PassportStore.shared.universalDeviceServiceUpgraded ? 1: 0], timerStop: .switchUser, isSuccessResult: true, context: flow.monitorContext)

            /// 应当在 switchAccountSucceed 之后执行，不要调整调用顺序
            self.updateBootManagerAfterSwitch(userID: userInfo.userID)

        }).disposed(by: self.disposeBag)
    }

    func switchAccountFailed(flow: SwitchUserFlow, error: Error) { SuiteLoginUtil.runOnMain { self._switchAccountFailed(flow: flow, error: error) } }
    private func _switchAccountFailed(flow: SwitchUserFlow, error: Error) {
        logger.error(SULogKey.switchFail, error: error)

        //call block callback
        //新版本直接使用completionCallback回调，
        //老版本的failCallback在重试场景下无法比较好的兼容，后期灰度完成后下掉
        flow.completionCallback?(false)

        handleSwitchError(error)

        logger.info(SULogKey.switchNotifyFail)

        // 切换失败状态流转
        // 状态的流转应该写在 switch 回调，暂时放在这里
        // 仅在 Rust 切换失败时更新状态，业务方不需要感知因为 switch_identity 导致的切换失败
        var isSwitchRustError = false
        if case .switchUserRustFailed(_)  = error as? AccountError {
            isSwitchRustError = true
        } else if case .switchUserFatalError = error as? AccountError {
            isSwitchRustError = true
        }

        if case .autoSwitchFail = error as? AccountError {
            // 自动切换用户失败时，无论是不是 Rust 错误，都将状态流转到前台用户为 nil
            logger.info(SULogKey.switchCommon, body: "auto switch failed, update state to offline", method: .local)
            let newState = PassportState(user: nil, loginState: .offline, action: .switch)
            stateService.updateState(newState: newState)
        } else if isSwitchRustError {
            if let user = userManager.foregroundUser { // user:current
                // 主动切换用户失败时，需要将状态更新为前台用户 online
                logger.info(SULogKey.switchCommon, body: "switch failed, restore state to online")
                let newState = PassportState(user: user.makeUser(), loginState: .online, action: .switch)
                stateService.updateState(newState: newState)
            } else {
                // 跨端登录时走切换流程，前台用户为空
                logger.info(SULogKey.switchCommon, body: "switch failed, foreground user is nil")
                let newState = PassportState(user: nil, loginState: .offline, action: .switch)
                stateService.updateState(newState: newState)
            }
        }

        //监控
        SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.afterSwitchNotifyStart, categoryValueMap: ["notify_type": "fail"], timerStart: .afterSwitchNotify, context: flow.monitorContext)

        self.afterSwitchAccout(error: error)
            .observeOn(MainScheduler.instance)
            .subscribe(onError: { [weak self] error in
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.afterSwitchNotifyComplete, categoryValueMap: ["notify_type": "fail"], timerStop: .afterSwitchNotify, isFailResult: true, context: flow.monitorContext, error: error)

                self?.retrySwitchFlowWhenRollbackError(error, flow: flow)

                // 应该写在 switch 回调，暂时放在这里
                self?.onSwitchError(error: error, monitorContext: flow.monitorContext)
            }, onCompleted: { [weak self] in
                //监控
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.afterSwitchNotifyComplete, categoryValueMap: ["notify_type": "fail"], timerStop: .afterSwitchNotify, isSuccessResult: true, context: flow.monitorContext)

                self?.retrySwitchFlowWhenRollbackError(error, flow: flow)

                // 应该写在 switch 回调，暂时放在这里
                self?.onSwitchError(error: error, monitorContext: flow.monitorContext)
            }).disposed(by: disposeBag)
    }

    /// 通过 launcher 派发切换的结果给各个监听方
    func afterSwitchAccout(error: Error?) -> Observable<Void> {
        var observalbes: [Observable<Void>] = []
        launcher.execute(.afterSwitchAccount, block: {
            let observalbe = $0.afterSwitchAccout(error: error)
                .catchErrorJustReturn(())
                .do(onCompleted: {
                })
            observalbes.append(observalbe)
        })

        return Observable<Void>
            .combineLatest(observalbes)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .do(onError: { [weak self] _ in
                guard let self = self else { return }
                //TODO: 追加监控
                self.updateStage(.finished)
            }, onCompleted: { [weak self] in
                //TODO: 追加监控
                self?.updateStage(.finished)
            })
            .catchError({ (error) -> Observable<[Void]> in
                Launcher.logger.error("afterSwitchAccount error", additionalData: nil, error: error)
                return .just([])
            })
            .map { _ in () }
    }

    private func handleSwitchError(_ error: Error) {
        if let accountError = error as? AccountError {
            switch accountError {
            case .switchUserCrossEnvFailed, .dataParseError, .notFoundTargetUser, .switchUserFatalError, .switchUserDeviceInfoError,.switchUserRustFailed(_), .switchUserGetDeviceDomainError, .switchUserTimeout:
                errorHandler?.showToast(BundleI18n.suiteLogin.Lark_Passport_SwitchTeamFailToast)
                logger.info(SULogKey.switchCommon, body: "show switch fail toast")
            default:
                break
            }
        }
        errorHandler?.handle(error)
    }

    private func showHud() {

        guard let view = PassportNavigator.keyWindow else {
            logger.error(SULogKey.switchCommon, body: "can not show loading")
            return
        }

        guard let flow = self.currentFlow else {
            logger.error(SULogKey.switchCommon, body: "not found switch flow")
            return
        }
        logger.info(SULogKey.switchCommon, body: "show loading", method: .local)

        PassportLoadingService.shared.showHud(tip: flow.additionInfo?.toast ?? BundleI18n.LarkAccount.Lark_Setting_SwitchUserLoadingTip,
                                              view: view)
    }
    
    private func removeHud() {
        logger.info(SULogKey.switchCommon, body: "remove loading", method: .local)
        PassportLoadingService.shared.removeHud()
    }

    private func clean() {
        logger.info(SULogKey.switchCommon, body: "clean", method: .local)
        removeHud()
        currentFlow?.lifeCycle = nil
        currentFlow = nil

        updateStage(.idle)
    }

}

extension NewSwitchUserService {

    private func retrySwitchFlowWhenRollbackError(_ error: Error, flow: SwitchUserFlow) {

        guard let uid = flow.switchContext?.switchUserID,
              (flow is SwitchUserAutoSwitchFlow) == false,
              let accountError = error as? AccountError else {
            logger.info(SULogKey.switchCommon, body: "no need to retry switch", method: .local)
            return
        }

        switch accountError {
        case .switchUserRollbackError(rawError: let error):
            guard flow.passportContext.from != .switchRollback,
                  let topMostVC = PassportNavigator.topMostVC else {

                //显示toast
                errorHandler?.showToast(BundleI18n.suiteLogin.Lark_Passport_SwitchFailedRollback_ActionFailedLogOut_Toast)

                //已经回滚过了，本次登出所有
                logger.error(SULogKey.switchCommon, body: "rollback error after retry logout all user")
                //登出所有租户
                let logger = logger
                logoutService.relogin(conf: LogoutConf.toLogin) { errorMsg in
                    logger.error(SULogKey.switchCommon, body: "rollback error after retry logout all user error\(errorMsg)")
                } onSuccess: { _ in
                    logger.info(SULogKey.switchCommon, body: "rollback error after retry logout all user succ")
                } onInterrupt: {
                    logger.info(SULogKey.switchCommon, body: "rollback error after retry logout all user interruptted")
                }

                return
            }

            //显示重试的弹窗
            logger.info(SULogKey.switchCommon, body: "show retry switch dialog")

            let dialogVC = LarkAlertController()
            dialogVC.setContent(text: BundleI18n.suiteLogin.Lark_Passport_SwitchFailedRollback_ActionFailedPopUp_Text)
            dialogVC.addPrimaryButton(text: BundleI18n.suiteLogin.Lark_Passport_SwitchFailedRollback_ActionFailedPopUp_GotItButton) { [weak self] in

                let retrySwitchFlow = SwitchUserDefaultFlow(userID: uid, credentialID: flow.switchContext?.credentialId, additionInfo: flow.additionInfo, monitorContext: SwitchUserMonitorContext(type: .retry, reason: flow.passportContext.from), passportContext: UniContextCreator.create(.switchRollback))
                self?.commitFlow(retrySwitchFlow, complete: flow.completionCallback)
            }
            topMostVC.present(dialogVC, animated: true)
        default:
            break
        }
    }

    private func onSwitchError(error: Error, monitorContext: SwitchUserMonitorContext) {
        // 对于 PassportDelegate(enableUserScope=true)：新状态不包含 switch 出错的 case，因此需要在这里处理
        // 对于 LauncherDelegate(enableUserScope=false)：BootManagerLauncherDelegate 里面包含了下面的逻辑
        if PassportUserScope.enableUserScope {
            if case .switchUserRustFailed(_)  = error as? AccountError {
                guard let userID = UserManager.shared.foregroundUser?.userID else { // user:current
                    assertionFailure("switch should have userID")
                    logger.error("switch should have userID")
                    return
                }
                // rust执行出错，进行回滚的初始化操作
                NewBootManager.shared.switchAccountV2(userID: userID, isRollbackSwitchUser: true, isSessionFirstActive: false)
            } else if case .autoSwitchFail = error as? AccountError {
                // 自动切换失败时，登出所有用户
                let loadingHUD = PassportLoadingService.showLoading()
                logoutService.relogin(conf: LogoutConf.toLogin) {[weak self] message in
                    self?.logger.error(SULogKey.switchCommon, body: "autoSwitchFail logout error\(message)")
                    loadingHUD?.remove()
                } onSuccess: { [weak self] _ in
                    self?.logger.info(SULogKey.switchCommon, body: "autoSwitchFail logout succ")
                    loadingHUD?.remove()
                } onInterrupt: { [weak self] in
                    self?.logger.error(SULogKey.switchCommon, body: "autoSwitchFail logout interruptted")
                    loadingHUD?.remove()
                }
            }
        }

        //监控
        var monitorReason: String
        if let accountError = error as? AccountError {
            if case .switchUserNeedVerify = accountError {
                // 验证算成功
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchUserResult, categoryValueMap: ["uni_did": PassportStore.shared.universalDeviceServiceUpgraded ? 1: 0], isSuccessResult: true, context: monitorContext)
            } else if case .switchUserInterrupted = accountError {
                // 中断场景不统计
            } else if case .switchUserCheckNetError = accountError {
                // 网络检测场景不统计
            } else {
                SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchUserResult, categoryValueMap: ["uni_did": PassportStore.shared.universalDeviceServiceUpgraded ? 1: 0], isFailResult: true, context: monitorContext, error: error)
            }
        } else {
            SwitchUserMonitorHelper.flush(PassportMonitorMetaSwitchUser.switchUserResult, categoryValueMap: ["uni_did": PassportStore.shared.universalDeviceServiceUpgraded ? 1: 0],  isFailResult: true, context: monitorContext, error: error)
        }

    }

    private func updateBootManagerAfterSwitch(userID: String) {
        //新账号模型支持同一个 userid 的切换, 如果 userid 一样, 重置 bootmanager 的 userid,从而重新初始化 user scope 的 services
        NewBootManager.shared.switchAccountV2(userID: userID,
                                              isRollbackSwitchUser: false,
                                              isSessionFirstActive: userManager.getUser(userID: userID)?.isSessionFirstActive ?? false)
        logger.info(
            "switchAccountSucceed update BootManager context",
            additionalData: ["uid": userID], method: .local
        )
    }
}
