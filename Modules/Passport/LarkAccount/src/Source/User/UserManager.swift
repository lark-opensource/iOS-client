//
//  UserManager.swift
//  LarkAccount
//
//  Created by au on 2021/7/6.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import RxCocoa
import RxSwift
import Reachability
import ECOProbeMeta

/// https://bytedance.feishu.cn/wiki/wikcnGHDOa1l28jpvgkPkMDoYVg#
final class UserManager {

    private static let logger = Logger.plog(UserManager.self, category: "User.UserManager")

    static let shared = UserManager()

    // MARK: - Exposed Properties

    var foregroundUser: V4UserInfo? {
        return store.foregroundUser // user:current
    }

    var foregroundUserObservable: Observable<V4UserInfo?> { store.foregroundUserUpdateObservable.map { [weak self] _ in self?.store.foregroundUser } } // user:current

    var userListObservable: Observable<[V4UserInfo]> { userListRelay.asObservable() }

    let userListRelay = BehaviorRelay<[V4UserInfo]>(value: [])

    // MARK: - Private Properties

    private let disposeBag = DisposeBag()

    private lazy var userCenterAPI = UserCenterAPI()
    
    // 网络可用性信号
    private let reachabilityChanged = {
        NotificationCenter.default.rx.notification(.reachabilityChanged).map({ _ in
            return (Reachability()?.connection ?? .none) != .none
        })
    }()

    @InjectedLazy private var launcher: Launcher
    @Provider private var store: PassportStore

    private init () {
        prefetchStoredUserList()
    }

    // MARK: - UserList 相关操作

    /// 登出全部时，清空所有 hidden user 和 session 失效 user
    func resetStoredUser() {
        updateForegroundUser(nil)
        clearHiddenUserList()
        clearAllUserList()
    }

    /// 移除 user，同时也会将 user 添加到 hiddenUser 列表中
    func removeUsers(by userIDs: [String]) {
        userIDs.forEach { id in
            if let user = store.getUser(userID: id) {
                store.addHiddenUser(user)
                Self.logger.info("n_action_user_manager", body: "add hidden user.", additionalData: ["userID": id])
            }
            store.removeUser(userID: id)
            Self.logger.info("n_action_user_manager", body: "remove user in removeUsers() method.", additionalData: ["userID": id])
        }
        // 推送变更
        updateUserListRelay()
    }

    /// 移除 user，
    func removeUsersWithoutAddHiddenUser(by userIDs: [String]) {
        userIDs.forEach { id in
            store.removeUser(userID: id)
            Self.logger.info("n_action_user_manager", body: "remove user in removeUsersWithoutAddHiddenUser() method.", additionalData: ["userID": id])
        }
        // 推送变更
        updateUserListRelay()
    }

    /// 侧边栏用户列表内容；这里的顺序需要自行维护，使用以下规则：
    /// 1. 默认排序使用登录时后端返回的顺序
    /// 2. 后续登录的用户, 分成 session 有效和无效两组, 分别追加到原先对应的数据尾部
    /// 3. 通过 user/list 获取的数据都是没有 session 的, 追加到 session 无效的尾部
    /// 4. 主动切换租户时, 目标用户移动到 session 有效的数据头部, 其他依次下移
    /// 5. session 失效时, 失效用户移动到 session 无效的数据头部
    func getUserList() -> [V4UserInfo] {
        return store.getUserList()
    }

    func getActiveUserList() -> [V4UserInfo] {
        return getUserList().filter { $0.userStatus == .normal }
    }

    func getHiddenUserList() -> [V4UserInfo] {
        return store.getHiddenUserList()
    }

    /// 在 enter/app step 后调用
    /// 入参的 userList 是来自 enter_app step 返回的用户数据，默认带着 Session 信息，直接存入 store
    func setEnterAppUserList(_ userList: [V4UserInfo]) {
        Self.logger.info("n_action_user_manager", body: "set enter app user list.", additionalData: ["list": userList.map { $0.userID }], method: .local)
        // 先把有 session 的用户先添加进 store
        userList.forEach { user in
            store.addActiveUser(user)
        }

        // 某些 KA 不允许多账号同时登录，此时不需要更新 user 列表 https://bytedance.feishu.cn/docs/doccnfLmKuFekUh9p7kbH3XvPMb
        let exclusiveLogin = userList.contains(where: { $0.user.excludeLogin ?? false })
        if exclusiveLogin {
            Self.logger.info("n_action_user_manager",
                             body: "skip updating user list for exclusive login.",
                             additionalData: ["user": userList.filter { $0.user.excludeLogin ?? false }.map { $0.userID }])
            updateUserListRelay()
        } else {
            Self.logger.info("n_action_user_manager", body: "update user list for non-exclusive login.")
            updateUserList(userList)
        }
    }

    /// 调用 user/list 接口并更新本地 user 列表
    /// 当传入 userListWithSession（一般从 enter_app 返回）时，本地添加时会`过滤掉`这些 user
    /// completion 中返回的 array 是`过滤后`的 user 列表，使用时请注意
    func updateUserList(_ userListWithSession: [V4UserInfo]? = nil, completion: (([V4UserInfo]) -> Void)? = nil) {
        Self.logger.info("n_action_user_manager", body: "update user list start.", method: .local)
        fetchUserList()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] dataInfo in
                guard let self = self else { return }
                let withoutSessionUsers = dataInfo.filter { !(userListWithSession?.contains($0) ?? false) }
                var callbackNewUserList: [V4UserInfo] = []
                withoutSessionUsers.forEach { user in
                    let newUser = self.getUserByResponseUser(responseUser: user.user)
                    callbackNewUserList.append(newUser)
                    if case .normal = newUser.userStatus {
                        self.store.addActiveUser(newUser)
                        Self.logger.info("n_action_user_manager", body: "add active user.", additionalData: ["userID": newUser.userID], method: .local)
                    } else {
                        self.store.addInactiveUser(newUser)
                        Self.logger.info("n_action_user_manager", body: "add inactive user.", additionalData: ["userID": newUser.userID], method: .local)
                    }
                }
                completion?(callbackNewUserList)
                self.updateUserListRelay()
            }, onError: { [weak self] error in
                Self.logger.error("n_action_user_manager", body: "update user list error.", error: error, method: .local)
                completion?([])
                self?.updateUserListRelay()
            })
            .disposed(by: disposeBag)
    }

    /// 单纯调用 userlist 接口
    func fetchUserList() -> Observable<[V4UserInfo]> {
        Self.logger.info("n_action_user_manager", body: "fetch user list start.", method: .local)
        return userCenterAPI
            .fetchUserList()
            .flatMap { (response) -> Observable<[V4UserInfo]> in
                let list = response.dataInfo ?? []
                Self.logger.info("n_action_user_manager", body: "fetch user list succ.", additionalData: ["list": list.map { $0.userID }], method: .local)
                return .just(list)
            }
    }

    func updateUserStatusByIDs(_ list: [String: UserExpressiveStatus]) {
        var changed = false
        list.forEach { (userID, status) in
            if let userInfo = store.getUser(userID: userID), status != userInfo.user.status {
                var newUser = userInfo.user
                newUser.status = status
                let newUserInfo = getUserByResponseUser(responseUser: newUser)
                store.updateUser(newUserInfo)
                Self.logger.info("n_action_user_manager", body: "update user status.", additionalData: ["userID": newUserInfo.userID, "status": "\(status)"])
                changed = true
            }
        }
        if changed {
            self.updateUserListRelay()
        }
    }

    func removeHiddenUserByIDs(_ list: [String]) {
        list.forEach { hidden in
            store.removeHiddenUser(userID: hidden)
            Self.logger.info("n_action_user_manager", body: "remove hidden user.", additionalData: ["userID": hidden], method: .local)
        }
    }

    // MARK: - User 相关操作

    /// 更新前台 user，传入新 user 或 nil
    func updateForegroundUser(_ user: V4UserInfo?) {
        Self.logger.info("n_action_user_manager",
                         body: "update foreground user start.",
                         additionalData: ["oldUserID": foregroundUser?.userID ?? "nil",
                                          "oldUserSession": (foregroundUser?.suiteSessionKey ?? "nil").desensitized()],
                         method: .local)
        if let account = user?.makeAccount() {
            Self.logger.info("n_action_user_manager", body: "Execute .beforeSetAccount")
            launcher.execute(.beforeSetAccount, block: { $0.beforeSetAccount(account) })
        }

        if let user = user {
            let updatedUser = updateUserLatestActiveTime(user)
            store.foregroundUserID = updatedUser.userID // user:current
            // 为了保证更新前台用户的时候本地一定有，这里用 addActiveUser 而不是 updateUser
            store.addActiveUser(updatedUser)
            store.bringActiveUserToFront(updatedUser)
            updateUserListRelay()
            updateCachedLogoutTokenList()

            PassportProbeHelper.shared.userID = user.userID
            PassportProbeHelper.shared.tenantID = user.user.tenant.id
        } else {
            store.foregroundUserID = nil // user:current
            PassportProbeHelper.shared.userID = ""
            PassportProbeHelper.shared.tenantID = ""
        }
        Self.logger.info("n_action_user_manager",
                         body: "ForegroundUser did set.",
                         additionalData: ["newUserID": foregroundUser?.userID ?? "nil",
                                          "newUserSession": (foregroundUser?.suiteSessionKey ?? "nil").desensitized()])
        
        var domainsWithSessions = ""
        if let accessTokens = foregroundUser?.suiteSessionKeyWithDomains {
            for (domain, session) in accessTokens {
                domainsWithSessions.append(contentsOf: "\(domain) : \(session["value"]?.desensitized() ?? "null"), ")
            }
        }
        Self.logger.info("n_action_user_manager", body: "domains with session: \(domainsWithSessions)")

        UploadLogManager.shared.userId = user?.userID
        executeLaunchDelegateUpdateAccount(user: foregroundUser)

        if let account = user?.makeAccount() {
            Self.logger.info("Execute .afterSetAccount")
            launcher.execute(.afterSetAccount, block: { $0.afterSetAccount(account) })
        }
    }

    func makeForegroundUserInvalid() {
        if let user = self.foregroundUser { // user:current
            var newUser = user
            newUser._invalidSessionFlag = true
            store.updateUser(newUser)
            Self.logger.info("n_action_user_manager", body: "make foreground user invalid.")
        }
    }

    func makeUsersInvalid(_ userList: [V4UserInfo]) {
        userList.forEach { user in
            var newUser = user
            newUser._invalidSessionFlag = true
            store.updateUser(newUser)
            store.bringInactiveUserToFront(newUser)
            Self.logger.info("n_action_user_manager", body: "make user invalid.", additionalData: ["userID": newUser.userID])
        }
        //推送变更
        updateUserListRelay()
    }

    func getUserByResponseUser(responseUser: V4ResponseUser) -> V4UserInfo {
        let oldUser = getUser(userID: responseUser.id)
        var newResponseUser = responseUser
        newResponseUser.leanModeInfo = oldUser?.user.leanModeInfo
        return V4UserInfo(user: newResponseUser,
                          currentEnv: oldUser?.currentEnv ?? "",
                          logoutToken: oldUser?.logoutToken ?? nil,
                          suiteSessionKey: oldUser?.suiteSessionKey ?? nil,
                          suiteSessionKeyWithDomains: oldUser?.suiteSessionKeyWithDomains ?? nil,
                          deviceLoginID: oldUser?.deviceLoginID ?? nil,
                          isAnonymous: oldUser?.isAnonymous ?? false,
                          latestActiveTime: oldUser?.latestActiveTime ?? 0,
                          isSessionFirstActive: oldUser?.isSessionFirstActive)
    }

    func getUser(userID: String) -> V4UserInfo? {
        return store.getUser(userID: userID)
    }
    
    /// 使用这个方法向 PassportStore 中的 userList 添加 user
    /// 不要操作 hidden user
    func addUserToStore(_ user: V4UserInfo) {
        if user.isActive {
            store.addActiveUser(user)
        } else {
            store.addInactiveUser(user)
        }
    }

    // MARK: - Private Methods

    private func executeLaunchDelegateUpdateAccount(user: V4UserInfo?) {
        var observables: [Observable<Void>] = []
        launcher.execute(.updateAccount) {
            let account = user?.makeAccount() ?? UserManager.placeholderUser.makeAccount()
            let observable = $0.updateAccount(account).catchErrorJustReturn(())
            observables.append(observable)
        }
        Self.logger.info("n_action_user_manager_update_account", additionalData: [
            "userID": user?.userID ?? "PlaceholderUser"
        ], method: .local)
        Observable<Void>
            .combineLatest(observables)
            .timeout(
                .seconds(15),
                scheduler: MainScheduler.instance
            )
            .catchError({ (error) -> Observable<[Void]> in
                Self.logger.error("n_action_user_manager_update_account_catch_error", additionalData: [
                    "userID": user?.userID ?? "PlaceholderUser"
                ], error: error)
                return .just([])
            })
            .map({ _ in })
            .subscribe(onNext: { _ in
                Self.logger.info("n_action_user_manager_update_account_succ", additionalData: [
                    "userID": user?.userID ?? "PlaceholderUser"
                ], method: .local)
            }, onError: { error in
                Self.logger.error("n_action_user_manager_update_account_on_error", additionalData: [
                    "userID": user?.userID ?? "PlaceholderUser"
                ], error: error)
            })
            .disposed(by: disposeBag)
    }

    /// 更新侧边栏用户列表数据
    /// 侧边栏用户数据逻辑详见 getUserList() 方法注释
    private func updateUserListRelay() {
        let userList = getUserList()
        let hiddenUserList = getHiddenUserList()

        let result = hiddenUserList.isEmpty ? userList : userList.filter { !hiddenUserList.contains($0) }
        Self.logger.info("n_action_user_manager", body: "update user list relay.", additionalData: ["list": result.map { $0.userID }], method: .local)

        userListRelay.accept(result)
    }

    public func updateCachedLogoutTokenList() {
        guard foregroundUser != nil else { return }
        // 前台用户不为空的时候更新，避免重装 app 后还没来得及处理，就重置了数据

        let userList = getUserList()
        let hiddenUserList = getHiddenUserList()
        let result = hiddenUserList.isEmpty ? userList : userList.filter { !hiddenUserList.contains($0) }
        let activeUserLogoutTokens = result.filter { $0.userStatus == .normal }.compactMap { $0.logoutToken }
        Self.logger.info("n_action_user_manager",
                         body: "logout tokens update.",
                         additionalData: ["list": "\(activeUserLogoutTokens.map { $0.desensitized() }.joined(separator: ","))"])
        ReinstallAppCleanHelper.updateLogoutTokenList(activeUserLogoutTokens)
    }

    private func updateUserLatestActiveTime(_ user: V4UserInfo) -> V4UserInfo {
        var newUser = user
        newUser.latestActiveTime = Date().timeIntervalSince1970
        return newUser
    }

    /// 清空所有的 hidden user
    private func clearHiddenUserList() {
        for hidden in store.getHiddenUserList() {
            store.removeHiddenUser(userID: hidden.userID)
            Self.logger.info("n_action_user_manager", body: "clear hidden user list.", additionalData: ["userID": hidden.userID])
        }
    }

    /// 清空所有的 user
    private func clearAllUserList() {
        for user in getUserList() {
            store.removeUser(userID: user.userID)
            Self.logger.info("n_action_user_manager", body: "clear all user list.", additionalData: ["userID": user.userID])
        }
    }

    /// 只用于初始化
    private func prefetchStoredUserList() {
        updateUserListRelay()
    }

    var upgradeSessionRetryCount: Int = 0
}

extension UserManager {
    /// 在旧版本中，前台 User 是一个不允许为空的设计，如果存在没有前台 User 的情况，会使用一个 placeholder 占位
    /// 新帐号模型下，前台 User 是可以为空（nil）的
    /// 这里只兼容原有 currentAccountInfo 使用，之后将被移除，请不要在其它地方使用
    static let placeholderUser: V4UserInfo = {
        let responseTenant = V4ResponseTenant(id: "placeholder.tenant.id", name: "placeholder.tenant.name",i18nNames: nil, iconURL: "", iconKey: "", tag: nil, brand: .feishu, geo: nil, domain: "", fullDomain: nil)
        let responseUser = V4ResponseUser(id: "placeholder.user.id", name: "placeholder.user.name", displayName: "placeholder.user.name", i18nNames: nil, i18nDisplayNames: nil, status: .unknown, avatarURL: "placeholder.user.avatarURL", avatarKey: "placeholder.user.avatarKey", tenant: responseTenant, createTime: 0, credentialID: "placeholder.user.credentialID", unit: nil, geo: "", excludeLogin: nil, userCustomAttr: [], isTenantCreator: false)
        return V4UserInfo(user: responseUser, currentEnv: "", logoutToken: "", suiteSessionKey: "", suiteSessionKeyWithDomains: nil, deviceLoginID: nil, isAnonymous: true, isSessionFirstActive: false)
    }()
}

extension UserManager: PassportStoreMigratable {
    func startMigration() -> Bool {
        
        // 更新对外暴露的 BehaviorRelay
        prefetchStoredUserList()

        return true
    }
    
    /// 本地数据迁移后，升级新模型 session
    func upgradeUserSession(completion: @escaping (_ success: Bool) -> Void) {
        Self.logger.info("n_action_upgrade_session started", method: .local)
        
        self.userCenterAPI.upgradeLogin()
            .do(onError: { error in
                // 因为日志时机过早，使用 local 方式
                Self.logger.error("n_action_upgrade_session_fail", body: "error: \(error)", error: error, method: .local)
            })
            .retry(2)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                Self.logger.info("n_action_upgrade_session returned: \(response.code)", method: .local)
                
                guard let self = self else { return }
                guard let updatedUsers = response.data else {
                    Self.logger.error("n_action_upgrade_session_fail", body: "no data", method: .local)
                    completion(false)
                    return
                }
                
                Self.logger.info("n_action_upgrade_session_succ", body: "userids: \(updatedUsers.map{ $0.userID }), sessions: \(updatedUsers.map{ $0.suiteSessionKey?.desensitized() ?? "-" })", method: .local)
                
                updatedUsers.forEach { self.addUserToStore($0) }
                self.updateUserListRelay()
                
                completion(true)
            }, onError: { error in
                Self.logger.error("n_action_upgrade_session_fail_after_retry", body: "error: \(error)", error: error, method: .local)
                                
                completion(false)
            })
            .disposed(by: disposeBag)
    }
}
