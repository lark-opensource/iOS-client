//
//  UserCheckSessionAPI.swift
//  LarkAccount
//
//  Created by bytedance on 2021/7/7.
//

import Foundation
import LKCommonsLogging
import RxSwift
import Reachability
import EENavigator
import LarkContainer
import RoundedHUD
import LarkCache
import UniverseDesignToast
import LarkUIKit
import ECOProbeMeta
import LarkAccountInterface

enum CheckSessionReason: String {
    case autoSwitch = "switch_next_valid"
    case http = "401"
    case retry = "retry"
    case rust = "push"
    case networkResume = "connection_available"
    case external = "external"
}

final class UserSessionService{
    
    private let logger = Logger.plog(UserSessionService.self, category: "SuiteLogin.SessionManagerService")
    
    private static let logger = Logger.log(UserSessionService.self, category: "SuiteLogin.SessionManagerService")
    
    private let disposeBag = DisposeBag()
    
    private var isCheckingStub : Bool = false
    
    private var isDoingActionStub : Bool = false

    private var switchIdentityResp : V3.Step?

    private var navDisposable: Disposable?

    private var vcDisposable: Disposable?
    //监控用 context
    private var _monitorContext: UniContextProtocol?
    private var monitorContext: UniContextProtocol {
        get {
            if let obj = _monitorContext {
                return obj
            } else {
                let context = UniContextCreator.create(.invalidSession)
                _monitorContext = context
                return context
            }
        }

        set {
            _monitorContext = newValue
        }
    }
    
    @Provider var launchService: Launcher
    @Provider var loginService: V3LoginService

    public func start(reason: CheckSessionReason){

        logger.info("n_action_session_invalid_invoked", additionalData: ["reason": reason.rawValue])

        //监控
        self.monitorContext = UniContextCreator.create(.invalidSession) // 入口, 重置 monitorContext
        PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.process_invalid_start,
                              categoryValueMap: ["invoke_reason": reason.rawValue],
                              context: monitorContext)

        //线程安全
        SuiteLoginUtil.runOnMain {

            //是否是流程中
            guard !self.isCheckingStub,
                  !self.isDoingActionStub else {
                self.logger.info("n_action_session_invalid_skip", additionalData:["reason": "processing"], method: .local)
                return
            }

            //检查当前网络, 如果不可用, 等到可用后重试
            if let reach = Reachability(), reach.connection == .none {
                self.logger.info("n_action_session_invalid_skip", additionalData:["reason": "none_connect"])

                self.isCheckingStub = true
                NotificationCenter.default.rx
                    .notification(.reachabilityChanged)
                    .filter({ notification in
                        if let reach = notification.object as? Reachability {
                            return reach.connection != .none
                        } else {
                            return false
                        }
                    })
                    .take(1)
                    .subscribe { [weak self] _ in
                        guard let self = self else { return }
                        
                        self.logger.info("n_action_session_invalid_invoked", body: "connection_available")
                        self.beginProcess(reason: .networkResume)
                    } onError: { [weak self] _ in
                        self?.isCheckingStub = false
                        self?.logger.info("n_action_session_invalid_invoked", body: "connection_watch_fallback")
                    }
                    .disposed(by: self.disposeBag)
            } else {
                // 网络可用, 开始执行
                self.beginProcess(reason: reason)
            }

        }

    }
    // 直接 check, 用于登出等场景
    public func doCheckSession(completion:((Bool) -> Void)? = nil) {
        //线程安全
        SuiteLoginUtil.runOnMain {
            self.logger.info("n_action_session_invalid_invoked", additionalData: ["reason":  CheckSessionReason.autoSwitch.rawValue])
            self.monitorContext = UniContextCreator.create(.invalidSession) // 入口, 重置 monitorContext
            PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.process_invalid_start,
                                  categoryValueMap: ["invoke_reason": CheckSessionReason.autoSwitch.rawValue],
                                  context: self.monitorContext)

            self.beginProcess(reason: .autoSwitch, completion: completion)
        }
    }
    
    /// 检查飞书当前用户的登录状态
    /// - Parameter onSuccess: 接口调用成功，block 返回值：登录态是否有效和额外说明
    /// - Parameter onFail: 接口调用成功，block 返回值：失败原因
    public func checkForegroundUserSessionIsValid(onSuccess: @escaping (Bool, String?) -> Void, onFail: @escaping(String) -> Void) { // user:current
        
        UserCheckSessionAPI().checkSessions().observeOn(MainScheduler.instance).subscribe { resp in
            guard let foregroundUser = UserManager.shared.foregroundUser else { // user:current
                Self.logger.info("n_action_session_check_no_foreground_user", method: .local)
                onFail("foregroundUser is empty") // user:current
                return
            }

            if let foregroundUserStatus = resp.sessionList[foregroundUser.suiteSessionKey ?? ""] { // user:current
                onSuccess(foregroundUserStatus.isLogged, foregroundUserStatus.isLogged ? nil: foregroundUserStatus.logoutReasonDescription()) // user:current
            } else {
                Self.logger.info("n_action_session_check_server_data_invalid", method: .local)
                onFail("server data invalid")
            }
        } onError: { error in
            onFail((error as NSError).localizedFailureReason ?? "")
        }.disposed(by: self.disposeBag)
    }

    //请求后台 check 当前的 session 和 user 的最新状态
    private func beginProcess(reason: CheckSessionReason, completion:((Bool) -> Void)? = nil) {

        logger.info("n_action_session_invalid_start", method: .local)
        self.isCheckingStub = true

        PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.check_status_request_start, context: monitorContext)

        UserCheckSessionAPI().checkSessions().observeOn(MainScheduler.instance).subscribe { [weak self] resp in
            guard let self = self else { return }

            self.doUpdateUserWithResp(resp)

            self.isCheckingStub = false
            completion?(true)
        } onError: {[weak self] error in
            guard let self =  self else { return }
            self.logger.error("n_action_session_invalid_check_failed")
            self.isCheckingStub = false
            completion?(false)
            //监控
            PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.check_status_request_fail, context: self.monitorContext, error: error)
        }.disposed(by: self.disposeBag)
    }

    //解析 check session 的后台数据
    private func doUpdateUserWithResp(_ resp: UserCheckSessionResponse){

        var bgUserList = [V4UserInfo]()
        var bgRemoveUserIDList = [String]()

        //监控
        var invalidCount = 0
        var needLogoutCount = 0
        let localActiveCount = UserManager.shared.getActiveUserList().count
        var monitorKVMap: [String: Any] = [:]
        var logIDMap: [String: String] = [:]
        var logSessionMap: [String: String] = [:]

        UserManager.shared.getUserList().forEach { user in
            if let sessionKey = user.suiteSessionKey, let item = resp.sessionList[sessionKey] { //session check
                if !item.isLogged{
                    if isForegroundUser(user) {
                        self.logger.info("n_action_session_invalid_process_foreground_start", additionalData: ["userId": user.userID])
                        //处理前台用户 session 失效的情况
                        self.updateForegroundUser(user, status: item)
                        //监控
                        invalidCount += 1
                        if needSwitchUserAction(action: item.action) { needLogoutCount += 1 }
                        PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.process_invalid_front_user_start, context: monitorContext)
                    }else{
                        if needSwitchUserAction(action: item.action){
                            bgRemoveUserIDList.append(user.userID)

                            //监控
                            needLogoutCount += 1
                        }else{
                            bgUserList.append(user)
                        }
                        //监控
                        invalidCount += 1
                    }

                    //log
                    logIDMap[user.userID] = item.logoutReasonDescription()
                    logSessionMap[user.userID] = sessionKey.desensitized()
                    //监控
                    let reason = "logout_reason_" + String( item.logoutRawReason ?? 0 )
                    if let value = monitorKVMap[reason] as? Int {
                        monitorKVMap[reason] = value + 1
                    } else {
                        monitorKVMap[reason] = 1
                    }
                } else {
                    if isForegroundUser(user),
                       let actionStep = item.actionStep,
                       let stepName = actionStep.stepName {
                        Self.logger.info("n_action_session_invalid_reauth: action step enter")

                        let runStep = { () in
                            // 6.7 新增 session 风险场景
                            LoginPassportEventBus.shared.post(
                                event: stepName,
                                context: V3RawLoginContext(
                                    stepInfo: actionStep.stepInfo,
                                    backFirst: nil,
                                    context: UniContextCreator.create(.invalidSession)
                                ),
                                success: {

                                }, error: { error in
                                    Self.logger.error("n_action_session_invalid_reauth: \(error.localizedDescription)")
                                }
                            )
                        }

                        if self.checkActionAvailible() {
                            runStep()
                        } else {
                            observeViewStackChange(action: runStep)
                        }
                    }
                }
            }
        }

        //更新最新的 user status
        if let list = resp.userList {
            logger.info("n_action_session_invalid_check_session", body: "update user status")
            updateUserStatusByIDs(list: list)

            // 需要直接删除的用户, 一般是未激活的用户同时又被离职了. 注: 只删除后台的 user. 前台用户走前台的逻辑
            if let deleteList = resp.requestUserList?.filter({ !(list.keys.contains($0)) && ($0 != UserManager.shared.foregroundUser?.userID) }) { // user:current
                bgRemoveUserIDList += deleteList
            }
        }

        // 后台用户失效合集
        if !bgUserList.isEmpty {
            self.updateBackgroundUser(bgUserList)
            self.logger.info("n_action_session_invalid_process_background", body: "start",
                             additionalData: ["userIds": "\(bgUserList.compactMap({$0.userID}))"]) //TODO: 追加掩码后的 session
        }
        // 后台需要直接删除的用户, 比如离职等
        if !bgRemoveUserIDList.isEmpty {
            if !MultiUserActivitySwitch.enableMultipleUser {
                self.logger.info("n_action_session_invalid_process_background: Not enable MultipleUser")
                removeBackgroundUsersByIDs(list: bgRemoveUserIDList)
            } else {
                self.logger.info("n_action_session_invalid_process_background: Enable MultipleUser")
                let workflow = (removeUsersHasSideEffectTask(context: UniContext(.invalidSession), action: .logout))
                workflow.runnable(bgRemoveUserIDList).execute { _ in
                    self.removeBackgroundUsersByIDs(list: bgRemoveUserIDList)
                } failureCallback: { error in
                    self.removeBackgroundUsersByIDs(list: bgRemoveUserIDList)
                    self.logger.error("n_action_session_invalid: logoutUserHasSideEffectTask error: \(error)")
                }
            }

            self.logger.info("n_action_session_invalid_process_background", body: "silence", additionalData: ["remote_removed_users": "\(bgRemoveUserIDList)"])
        }

        // log
        logger.info("n_action_session_invalid_invalid_sessions",
                    additionalData: ["invalid_user_logout_reason_map": logIDMap,
                                     "invalid_user_logout_session_map": logSessionMap,
                                     "remote_removed_users": bgRemoveUserIDList])
        if invalidCount == 0 {
            logger.info("n_action_session_invalid_end", additionalData: ["reason": "none_invalid_user"])
        }

        //监控
        monitorKVMap["local_count"] = localActiveCount
        monitorKVMap["server_count"] = resp.sessionList.count
        monitorKVMap["invalid_count"] = invalidCount
        monitorKVMap["unregister_count"] = needLogoutCount

        PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.check_status_request_succ,
                              categoryValueMap: monitorKVMap,
                              context: monitorContext)

        PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.process_invalid_bkg_user_end,
                              context: monitorContext)
    }

    // 确认某个用户的 session 是在线状态
    public func validateUserSessionOnline(_ user: V4UserInfo, completion:((Bool) -> Void)? = nil) {
        SuiteLoginUtil.runOnMain {
            // 检查当前网络, 如果不可用, 等到可用后重试
            if let reach = Reachability(), reach.connection == .none {
                self.logger.info("n_action_session_validate_user_session_skip", additionalData:["reason": "none_connect"])
                NotificationCenter.default.rx
                    .notification(.reachabilityChanged)
                    .filter({ notification in
                        if let reach = notification.object as? Reachability {
                            return reach.connection != .none
                        } else {
                            return false
                        }
                    })
                    .take(1)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        self.logger.info("n_action_session_validate_user_session_invoked", body: "connection_available")
                        self.requestUserSessionCheck(user, completion: completion)
                    }, onError: { [weak self] _ in
                        self?.logger.info("n_action_session_validate_user_session_invoked", body: "connection_watch_fallback")
                    })
                    .disposed(by: self.disposeBag)
            } else {
                // 网络可用
                self.requestUserSessionCheck(user, completion: completion)
            }
        }
    }

    private func requestUserSessionCheck(_ user: V4UserInfo, completion:((Bool) -> Void)? = nil) {
        UserCheckSessionAPI().checkSessions()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                if let sessionKey = user.suiteSessionKey,
                   let item = response.sessionList[sessionKey] {
                    completion?(item.isLogged)
                } else {
                    completion?(false)
                }

            }, onError: { [weak self] error in
                guard let self = self else { return }
                self.logger.error("n_action_session_validate_user_session_failed")
                completion?(false)
            })
            .disposed(by: self.disposeBag)
    }

    private func isForegroundUser(_ user: V4UserInfo) -> Bool {
        return user.userID == UserManager.shared.foregroundUser?.userID // user:current
    }
    //标记后台用户为失效用户
    private func updateBackgroundUser(_ list: [V4UserInfo]) {
        UserManager.shared.makeUsersInvalid(list)
    }

    private func removeBackgroundUsersByIDs(list: [String]) {
        UserDataEraserHelper.shared.logoutUserList(by: list)
        UserManager.shared.removeUsers(by: list)
    }

    private func updateUserStatusByIDs(list: [String: UserExpressiveStatus]) {
        UserManager.shared.updateUserStatusByIDs(list)
    }

    private func updateForegroundUser(_ userInfo: V4UserInfo, status: UserCheckSessionItem){

        // 如果已经在流程中了...忽略
        guard false == isDoingActionStub else {
            self.logger.info("n_action_session_invalid_skip_update_foreground", additionalData:["reason":"processing"])
            return
        }
        //设置为处理中
        isDoingActionStub = true

        //如果是特殊的无弹窗情况, 直接切换用户
        if needSwitchUserAction(action: status.action) {
            logger.info("n_action_session_invalid_process_foreground_silence", additionalData: ["userId": userInfo.userID])
            handleSwitchUserAction(status: status)
            return
        }

        //标记前台用户为失效状态需要在 无弹窗之后, 因为 logout 那边会判断有效用户>1 才会走切换.
        //标记前台用户为失效
        UserManager.shared.makeForegroundUserInvalid()

        //发起 switch identity 请求, 获取弹窗数据
        let request = SwitchUserAPI().switchIdentity(to: userInfo.userID, credentialID: userInfo.user.credentialID, sessionKey: userInfo.suiteSessionKey, switchType: .passive).observeOn(MainScheduler.instance)
        request.subscribe {[weak self] resp in
            guard let self = self else { return }

            self.switchIdentityResp = resp

            //检查当前 app 是不是可以显示弹窗.(现在是passport 相关的页面上不显示)
            if self.checkActionAvailible() {
                self.logger.info("n_action_session_invalid_post_step", body: "direct")
                self.postStep()
            }else{
                //当前不能显示, 监听页面堆栈的变更
                self.logger.info("n_action_session_invalid_process_foreground_blocked", additionalData: ["userId": userInfo.userID])
                self.observeViewStackChange { [weak self] in
                    guard let self = self else { return }
                    self.postStep()
                }
            }

        } onError: {[weak self] error in
            self?.isDoingActionStub = false
            self?.logger.error("n_action_session_invalid_end", additionalData:["reason": "check_session_failed"], error: error)
        }.disposed(by: disposeBag)
    }

    private func observeViewStackChange(action: @escaping (() -> Void)) {

        //最上层页面有导航栏,监听导航栏的变更
        if let navVC = PassportNavigator.topMostVC?.navigationController {
            observeNavigationPop(navVC, action: action)
            observeViewControllerDismiss(navVC, action: action)
        } else if let topVC = PassportNavigator.topMostVC {
            observeViewControllerDismiss(topVC, action: action)
        } else {
            //兜底 直接显示
            self.logger.warn("n_action_session_invalid_post_step", body: "no_navVC_fallback")
            action()
        }
    }

    private func observeNavigationPop(_ navVC: UINavigationController, action: @escaping (() -> Void)) {
        navDisposable = Observable.of(navVC.rx.methodInvoked(#selector(UINavigationController.popViewController(animated:))))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in

                guard let self = self else { return }
                guard self.checkActionAvailible() else { return }

                //可以显示, 重走 check 逻辑. 避免 block 过程中有其他 session 失效,没有及时更新
                self.logger.info("n_action_session_invalid_start", body: "intercepted view nav pop")
                self.retryCheck()

            }, onError: {[weak self] error in
                guard let self = self else { return }
                self.logger.warn("n_action_session_invalid_post_step", body: "error fallback nav pop")
                action()
            })
    }

    private func observeViewControllerDismiss(_ vc: UIViewController, action: @escaping (() -> Void)) {
        vcDisposable = Observable.of(vc.rx.methodInvoked(#selector(UIViewController.dismiss(animated:completion:))))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in

                guard let self = self else { return }

                if self.checkActionAvailible() {
                    //可以显示, 重走 check 逻辑. 避免 block 过程中有其他 session 失效,没有及时更新
                    self.logger.info("n_action_session_invalid_start", body: "intercepted view view dismiss")
                    self.retryCheck()
                }else {
                    //重新监听 view 的变更
                    self.observeViewStackChange(action: action)
                }
            }, onError: {[weak self] error in
                guard let self = self else { return }
                self.logger.warn("n_action_session_invalid_post_step", body: "error fallback view dismiss")
                action()
            })
    }

    //显示失效弹窗
    private func postStep() {
        guard let resp = switchIdentityResp else {
            self.logger.warn("n_action_show_dialog", body: "no resp instance retry check")
            self.isDoingActionStub = false
            return
        }

        guard resp.stepData.nextStep == PassportStep.showDialog.rawValue || resp.stepData.nextStep == PassportStep.guideDialog.rawValue else {
            self.logger.warn("n_action_show_dialog", body: "not show dialog or guide dialog step \(resp.stepData.nextStep)")
            self.isDoingActionStub = false
            return
        }

        //关闭视频会议
        signalInterrupt()

        let context = UniContextCreator.create(.invalidSession)
        LoginPassportEventBus.shared.post(
            event: resp.stepData.nextStep,
            context: V3RawLoginContext(
                stepInfo: resp.stepData.stepInfo,
                vcHandler: { [weak self] viewController in
                    if let vc = viewController {
                        self?.pushVCWithDialogStep(vc)
                    }else {
                        self?.logger.warn("n_action_show_dialog", body: "no vc to push")
                    }
                }, context: context
            ),
            success: {}, error: {[weak self] error in
                //有错误暂不处理
                self?.isDoingActionStub = false
                self?.logger.error("n_action_session_invalid_end", additionalData:["reason": "step_handler"], error: error)
            })

        //监控
        PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.process_invalid_front_user_end_block,
                              context: monitorContext)

    }

    func pushVCWithDialogStep(_ vc: UIViewController, animated: Bool = true) {

        self.logger.warn("n_action_show_dialog", body: "push vc")

        let navigation = LoginNaviController(rootViewController: vc)
        navigation.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen

        if let mainSceneTopMost = PassportNavigator.topMostVC {
            Navigator.shared.present(navigation, from: mainSceneTopMost) // user:checked (navigator)
        } else {
            self.logger.errorWithAssertion("no main scene top most for showVC")
        }
    }

    //重新走 check 逻辑
    private func retryCheck() {
        self.isCheckingStub = false
        self.isDoingActionStub = false
        self.vcDisposable?.dispose()
        self.navDisposable?.dispose()
        self.start(reason: .retry)
    }

    // 无弹窗, 自动切换用户的场景
    private func handleSwitchUserAction(status: UserCheckSessionItem) {

        //如果是离职的情况,需要删除所有cache
        if status.action == SessionInvalidAction.clearCacheAndSwitchNextValidUser {
            logger.info("n_action_session_invalid_resign_clean_cache")
            if let view = PassportNavigator.keyWindow {
                UDToast.showLoading(
                    with: BundleI18n.LarkAccount.Lark_Legacy_BaseUiLoading,
                    on: view,
                    disableUserInteraction: true
                )
                CacheManager.shared.clean(config: CleanConfig(isUserTriggered: true)) {
                    SuiteLoginUtil.runOnMain { [weak self] in
                        guard let self = self else { return }

                        UDToast.removeToast(on: view)
                        self.logger.info("n_action_session_invalid_resign_clean_cache", body: "end")
                        self.logoutForegroundUser(reason: status.logoutReason)
                    }
                }
            }
        } else {
            logoutForegroundUser(reason: status.logoutReason)
        }
    }

    // 自动登出前台用户, 走自动切换流程
    private func logoutForegroundUser(reason: UserCheckSessionItem.LogoutReason) {

        logger.info("n_action_session_invalid_process_foreground_silence", body: "logout")

        //登出当前用户
        launchService.unregisterUser(trigger: .sessionExpired) { [weak self] flag in
            guard let self = self else { return }
            if(!flag){ //直接回到登录页
                if let toast = self.autoSwitchToastMessage(reason: reason), let panel = PassportNavigator.keyWindow {
                    UDToast.showTips(with: toast, on: panel)
                    //监控
                    PassportMonitor.flush(EPMClientPassportMonitorSessionInvalidCode.process_invalid_front_user_end_logout_all,
                                          context: self.monitorContext)
                }
            }
            self.isDoingActionStub = false
            self.logger.info("n_action_session_invalid_end", additionalData: ["reason": flag ? "resolved" : "switch_user_failed"])
        }
    }

    //判断是否是特殊的自动切换场景
    private func needSwitchUserAction(action: String) -> Bool {
        switch action {
        case SessionInvalidAction.switchNextValidUser: //失效动作为切换到下一个有效租户
            return true
            break
        case SessionInvalidAction.clearCacheAndSwitchNextValidUser: //失效动作为先清理缓存再切换到下一个有效租户
            return true
            break
        default:
            return false
        }
    }

    //自动切换场景,如果回退到登录页的 toast 文案
    private func autoSwitchToastMessage(reason: UserCheckSessionItem.LogoutReason) -> String?{
        switch reason {
        case .resign:
            return BundleI18n.suiteLogin.Lark_Passport_DeleteAccount_DeleteByTerminateToast
        case .quitTenant,.unregister:
            return BundleI18n.suiteLogin.Lark_Passport_DeleteAccount_AutoLogOutToast
        case .tenantDismiss:
            return BundleI18n.suiteLogin.Lark_Passport_DeleteAccount_TeamDisbandLogOutToast
        default:
            return nil
        }
    }
    //是否可以显示弹窗
    private func checkActionAvailible() ->Bool{
        if let topVC = PassportNavigator.topMostVC as? BaseViewController{
            return topVC.showSessionInvalidAlert
        }
        return true
    }

    private func signalInterrupt() {

        let interruptObservable = loginService.interruptOperations.map { (interrupt) -> Single<Bool> in
            return interrupt.getInterruptObservable(type: .sessionInvalid)
        }

        Single
            .zip(interruptObservable)
            .catchError({ [weak self] (error) -> Single<[Bool]> in
                self?.logger.error("n_action_session_invalid", body: "Interrupt fail", error: error)
                return Single.just([true])
            })
            .flatMap { (results) -> Single<Bool> in
                for result in results where result == false {
                    return Single.just(false)
                }
                return Single.just(true)
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] status in
                self?.logger.info("n_action_session_invalid", body: "Interrupt \(status)")
            })
            .disposed(by: disposeBag)
    }
}
