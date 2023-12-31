//
//  MultiUserActivityCoordinator.swift
//  LarkAccount
//
//  Created by au on 2023/10/26.
//

import EEAtomic
import LarkAccountInterface
import LarkContainer
import LarkEnv
import LarkSetting
import LarkStorage
import LKCommonsLogging

/// 处理多租户同时在线，承载来自`设置页`和`Passport 事件变化`带来的 online 用户列表变化逻辑
final class MultiUserActivityCoordinator {

    static let shared = MultiUserActivityCoordinator()

    private static let logger = Logger.log(MultiUserActivityCoordinator.self, category: "MultiUserActivityCoordinator")

    final class MultiUserDelegateWrapper: LarkContainerManagerFlowProgressDelegate {

        private static let logger = Logger.log(MultiUserDelegateWrapper.self, category: "MultiUserDelegateWrapper")

        private weak var coordinator: MultiUserActivityCoordinator?
        private let activityUserIDList: [String]
        private var completion: ((Result<Void, Error>) -> Void)?

        init(coordinator: MultiUserActivityCoordinator?, activityUserIDList: [String], completion: ((Result<Void, Error>) -> Void)?) {
            self.coordinator = coordinator
            self.activityUserIDList = activityUserIDList
            self.completion = completion
        }

        func didCompleteWithError(_ error: LarkContainerManagerFlowError?) {
            Self.logger.info("[Coordinator] wrapper: receive didComplete")
            complete(error: error)
        }

        func afterForegroundChange() {
            Self.logger.info("[Coordinator] wrapper: receive afterForegroundChange")
            complete(error: nil)
        }

        /// 有 afterForegroundChange()，直接回调成功
        /// 先收到 didCompleteWithError(_)，基于结果，无 error，返回成功；有 error，透传给业务
        private func complete(error: LarkContainerManagerFlowError?) {
            guard let completion = self.completion else { return }
            defer { self.completion = nil }

            if let error = error {
                Self.logger.error("[Coordinator] wrapper: completion failure \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } else {
                Self.logger.info("[Coordinator] wrapper: completion success")
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
        }
    }

    private init() {
        let store = KVStores.udkv(space: .global, domain: Domain.biz.infra)
        do {
            try store.excludeFromBackup()
        } catch {
            assertionFailure("coordinator store init with error \(error)")
        }
        self.kvStore = store
    }

    /// `预期`的跨租户消息用户列表
    /// `预期`是指，它基于产品规则和当前完整用户列表的计算结果，但不一定和容器/ sdk 实际 online 列表一致
    /// 它会在容器处理之前就完成更新，无本地持久化，每次启动根据 fast login 和设置开关值做最新的计算
    @AtomicObject
    private(set) var activityUserIDList = [String]()

    /// coordinator 内部功能开关
    private var enableMultiUser: Bool {
        return MultiUserActivitySwitch.enableMultipleUserRealtime && settingsEnableMultiUserActivity
    }

    /// 设置页用户开关
    var settingsEnableMultiUserActivity: Bool {
        get {
            // TODO: MultiUser - 确认 key
            let key = KVKey<Bool>(self.settingsEnableKey, default: false)
            return kvStore.value(forKey: key)
        }
        set {
            Self.logger.info("[Coordinator] settings enable set to \(newValue)")
            let key = KVKey<Bool>(self.settingsEnableKey, default: false)
            kvStore.set(newValue, forKey: key)
        }
    }

    @Provider var dependency: PassportDependency
    @Provider var passportService: PassportService

    /// 接收其它账号消息通知的用户数量上限，这个限额是`不包含`前台用户的
    private var activityLimit: Int {
        if let limit = try? SettingManager.shared.setting(with: Int.self, 
                                                          key: UserSettingKey.make(userKeyLiteral: "multi_user_max_background_user_num")) {
            return limit
        }
        Self.logger.warn("[Coordinator] cannot fetch setting limit")
        return 10
    }

    private let kvStore: KVStore

    private var settingsEnableKey: String {
        let key = "settingsEnableMultiUserActivity"
        #if DEBUG || BETA || ALPHA
            let debugKey: String
            switch EnvManager.env.type {
            case .release:
                debugKey = key
            case .preRelease:
                debugKey = key + "_pre"
            case .staging:
                debugKey = key + "_staging"
            @unknown default:
                debugKey = key
            }
            return debugKey
        #else
            return key
        #endif
    }

}

// 计算 Activity User List
extension MultiUserActivityCoordinator {
    /// 计算生成`终态`的 activity user list，用于传递给 container manager 进行上下线
    /// 方法返回`包含`前台身份
    /// 方法使用在`功能启用`场景，内部不包含功能开关状态判断
    private func createActivityUserList(state: MultiUserActivityState) -> [User] {
        // fastLogin, login, switch, settingsUpdating(开关打开)
        // 这几个场景本质都是：
        //     1. 先将前台用户放入结果列表
        //     2. 活跃用户剔除前台用户，获取限额数量
        //     3. 合并为结果列表
        func _defaultLoginUserList() -> [User] {
            var activityList = [User]()
            let foregroundUserID = state.toForegroundUserID
            let foregroundUser = passportService.activeUserList.first(where: { $0.userID == foregroundUserID })
            if let user = foregroundUser {
                activityList.append(user)
            }
            let rest = Array(passportService.activeUserList.filter { $0.userID != foregroundUserID }.prefix(activityLimit))
            activityList.append(contentsOf: rest)
            return activityList
        }

        switch state.action {
        case .initialized:
            // do nothing
            return []
        case .fastLogin, .login, .switch, .settingsMultiUserUpdating:
            // 登录：用户列表已经更新，前台用户已包含在用户列表中
            // 切换租户：用户列表已包含将要切换的前台租户，但顺序可能不在范围内
            return _defaultLoginUserList()
        case .logout:
            // 登出：使用 state 中的除外用户列表
            var activityList = [User]()
            let foregroundUserID = state.toForegroundUserID
            if let foregroundUser = passportService.activeUserList.first(where: { $0.userID == foregroundUserID }) {
                activityList.append(foregroundUser)
            }
            var rest = passportService.activeUserList.filter { $0.userID != foregroundUserID }
            if let droppedUserIDs = state.droppedUserIDs {
                rest = rest.filter { user in
                    !droppedUserIDs.contains { userID in
                        user.userID == userID
                    }
                }
            }
            rest = Array(rest.prefix(activityLimit))
            activityList.append(contentsOf: rest)
            return activityList
        @unknown default:
            Self.logger.error("[Coordinator] create user list unknown case!")
            assertionFailure("[Coordinator] create user list unknown case!")
            return []
        }
    }

    func updateActivityUserIDList(_ idList: [String]) {
        activityUserIDList = idList
        Self.logger.info("[Coordinator] update activity user id list \(idList)")
        // TODO: MultiUser
        // 根据 action 场景判断是即时生效，还是等待 container 的回调再更新
        // fast login、Settings 变更即时生效
    }
}

extension MultiUserActivityCoordinator: MultiUserActivityCoordinatable {
    func settingsWillUpdate(_ enable: Bool, completion: @escaping (Bool) -> Void) {
        guard let foregoundUser = passportService.foregroundUser else {
            DispatchQueue.main.async {
                Self.logger.error("[Coordinator] settings update no foreground user")
                completion(false)
            }
            return
        }
        let activityUserList: [User]
        if enable {
            let state = MultiUserActivityState(action: .settingsMultiUserUpdating, toForegroundUserID: foregoundUser.userID)
            activityUserList = createActivityUserList(state: state)
        } else {
            activityUserList = [foregoundUser]
        }
        // 计算完成，先行回调
        settingsEnableMultiUserActivity = enable
        let ids = activityUserList.map { $0.userID }
        updateActivityUserIDList(ids)
        Self.logger.info("[Coordinator] settingsWillUpdate ids: \(ids)")
        DispatchQueue.main.async {
            completion(true)
        }

        // 不再传递回调
        let wrapper = MultiUserDelegateWrapper(coordinator: self, activityUserIDList: ids, completion: nil)
        dependency.userListChange(userList: activityUserList, foregroundUser: foregoundUser, action: .settingsMultiUserUpdating, delegate: wrapper)
    }

    func stateWillUpdate(_ state: MultiUserActivityState, completion: @escaping (Result<Void, Error>) -> Void) {
        var activityUserList = [User]()
        let foregroundUser: User?
        if let toForegroundUserID = state.toForegroundUserID {
            foregroundUser = passportService.getUser(toForegroundUserID)
        } else {
            foregroundUser = nil
        }

        if enableMultiUser {
            // 功能启用，计算完整列表
            activityUserList = createActivityUserList(state: state)
        } else {
            // 功能关闭，只计算前台用户
            if let user = foregroundUser {
                activityUserList = [user]
            }
        }

        let ids = activityUserList.map { $0.userID }
        updateActivityUserIDList(ids)
        Self.logger.info("[Coordinator] stateWillUpdate ids: \(ids), action: \(state.action.rawValue)")

        let wrapper = MultiUserDelegateWrapper(coordinator: self, activityUserIDList: ids, completion: completion)
        dependency.userListChange(userList: activityUserList, foregroundUser: foregroundUser, action: state.action, delegate: wrapper)
    }

}
