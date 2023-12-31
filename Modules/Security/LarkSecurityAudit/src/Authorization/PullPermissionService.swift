//
//  PullPermissionService.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/12/25.
//

import Foundation
import ServerPB
import LarkRustClient
import ThreadSafeDataStructure
import LKCommonsLogging
import LarkFeatureGating
import LarkSetting
import UniverseDesignToast
import EENavigator
import LarkSecurityComplianceInfra
import LarkAccountInterface
import LarkContainer
import LarkNavigator
import CryptoSwift

typealias PermissionMap = [PermissionType: [ServerPB_Authorization_CustomizedOperatePermission]]
final class PullPermissionService: UserResolverWrapper {

    static let serialQueue: DispatchQueue = DispatchQueue(label: "security.audit.pull.permission.enqueue", qos: .default)

    static func enablePermission(resolver: UserResolver) -> Bool {
        let service = try? resolver.resolve(assert: FeatureGatingService.self)
        return service?.staticFeatureGatingValue(with: "lark.security.audit.permission") ?? true
    }

    static func authByIPEnabled(resolver: UserResolver) -> Bool {
        let service = try? resolver.resolve(assert: FeatureGatingService.self)
        return service?.staticFeatureGatingValue(with: "lark.passport.security.auth_by_ip") ?? false
    }

    enum Trigger: String {
        case timer
        case push
        case networkChange = "network"
        case noneResponse = "noResponse"
    }

    static let logger = Logger.log(PullPermissionService.self, category: "SecurityAudit.PullPermissionService")

    let timer: BatchTimer
    private let scheduler: PullPermissionScheduler
    private let fetcher: PermissionFetcher

    var permissionResponse: ServerPB_Authorization_PullPermissionResponse? {
        get { _permissionResponse.value }
        set { _permissionResponse.value = newValue }
    }
    private var _permissionResponse: SafeAtomic<ServerPB_Authorization_PullPermissionResponse?> = nil + .readWriteLock
    var permissionMap: PermissionMap? {
        get { _permissionMap.value }
        set { _permissionMap.value = newValue }
    }
    private var _permissionMap: SafeAtomic<PermissionMap?> = nil + .readWriteLock

    let cacheManager: SecurityCacheManager

    private var networkMonitor: NetworkChangeMonitor

    private lazy var observerManager = PermissionChangeActionManager()
    private var enableFetchPermission: Bool?

    private let retryManager: PermissionRetryManager

    let userResolver: UserResolver
    @ScopedProvider private var userService: PassportUserService?

#if DEBUG || ALPHA
    var pullSuccess: Bool = false
#endif

    init(resolver: UserResolver) {
        self.userResolver = resolver
        networkMonitor = NetworkChangeMonitor(userResolver: resolver)
        timer = BatchTimer(timerInterval: Const.pullPermissionTimerInterval)
        retryManager = PermissionRetryManager(resolver: resolver)
        scheduler = PullPermissionScheduler()
        fetcher = PermissionFetcher(resolver: resolver)
        cacheManager = SecurityCacheManager(userResolver: userResolver)
        timer.handler = { [weak self] in
            guard let self = self else { return }
            self.fetchPermission(.timer)
        }

        Self.logger.info("n_action_permission_auth_by_ip_fg enabled: \(Self.authByIPEnabled(resolver: userResolver))")
        if Self.authByIPEnabled(resolver: userResolver) {
            networkMonitor.updateHandler = { [weak self] _ in
                Self.logger.info("n_action_auth_by_ip fetch permission")

                guard let self = self else { return }
                self.fetchPermission(.networkChange)
            }
            networkMonitor.start()
        }

        Self.serialQueue.async {
            /// 初始化数据
            if let resp = self.cacheManager.readCache() {
                self.mergeData(resp)
                Self.logger.info("init permission data with local cache")
            } else {
                Self.logger.info("init permission data no local cache")
            }
        }
    }

    func stop() {
        timer.stopTimer()
        if Self.authByIPEnabled(resolver: userResolver) {
            networkMonitor.stop()
        }
    }

    func fetchPermission(_ trigger: Trigger, complete: @escaping () -> Void = {}) {
        Self.serialQueue.async {
            Self.logger.info("n_action_permission_fetch_triggered type: \(trigger)")
            guard Self.enablePermission(resolver: self.userResolver) else {
                Self.logger.info("pull fg disable")
#if DEBUG || ALPHA
                self.pullSuccess = false
#endif
                complete()
                self.trackPullPermission(trigger: trigger.rawValue, triggerSuccess: false, triggerFailReason: "fg_disable")
                return
            }
            if trigger == .networkChange {
                if Self.authByIPEnabled(resolver: self.userResolver) {
                    Self.logger.info("n_action_permission_auth_by_ip_enabled")
                    self.clearIPPermissionData()
                } else {
                    Self.logger.info("n_action_permission_auth_by_ip_disabled")
                    self.trackPullPermission(trigger: trigger.rawValue, triggerSuccess: false, triggerFailReason: "fg_disable")
                    return
                }
            }

            let additionalData: [String: String] = ["trigger": String(describing: trigger)]
            guard SecurityAuditManager.shared.isNetworkEnable else {
                Self.logger.info("n_action_permission_fetch_unreachable", additionalData: additionalData)
                self.trackPullPermission(trigger: trigger.rawValue, triggerSuccess: false, triggerFailReason: "network_unreach")
#if DEBUG || ALPHA
                self.pullSuccess = false
#endif
                complete()
                return
            }
            guard !SecurityAuditManager.shared.conf.session.isEmpty else {
                Self.logger.info("pull empty session", additionalData: additionalData)
                self.trackPullPermission(trigger: trigger.rawValue, triggerSuccess: false, triggerFailReason: "no_session")
#if DEBUG || ALPHA
                self.pullSuccess = false
#endif
                complete()
                return
            }
            if case .timer = trigger {
                // timer触发限流
                guard self.scheduler.shouldUpload() else {
                    Self.logger.info("n_action_permission_fetch_throttled", additionalData: additionalData)
#if DEBUG || ALPHA
                    self.pullSuccess = false
#endif
                    complete()
                    self.trackPullPermission(trigger: trigger.rawValue, triggerSuccess: false, triggerFailReason: "frenquency_control")
                    return
                }
            }
            Self.logger.info("n_action_permission_fetch_req_start")
            self.trackPullPermission(trigger: trigger.rawValue, triggerSuccess: true)
            if self.enablePullPermission() {
                self.retryManager.clearRetryTask()
            }
            self.fetcher.fetchPermissions(permVersion: self.permissionResponse?.permVersion, complete: { [weak self] (result) in
                guard let `self` = self else { return }
                switch result {
                case .success(let resp):
                    Self.logger.info("n_action_permission_fetch_req_succ", additionalData: additionalData)
                    Self.serialQueue.async {
                        self.cacheResponse(resp: resp)
                        self.getStrictAuthMode(resp: resp)
                        SecurityAuditManager.shared.lastErrorType = nil
                        complete()
#if DEBUG || ALPHA
                        self.pullSuccess = true
#endif
                    }
                case .failure(let error):
                    let lastErrorType = self.getErrorCodeType(error)
                    SecurityAuditManager.shared.lastErrorType = lastErrorType
                    Self.logger.error("n_action_permission_fetch_req_fail", additionalData: [
                        "trigger": String(describing: trigger),
                        "authErrorType": String(describing: lastErrorType)], error: error)
                    complete()
                    self.retryFetchPermission()
#if DEBUG || ALPHA
                    self.pullSuccess = false
#endif
                }
            })
        }
    }

    func retryFetchPermission(complete: @escaping () -> Void = {}) {
        guard self.enablePullPermission() else {
            return
        }
        Self.serialQueue.async {
            Self.logger.info("n_action_permission_fetch_req_retry_start")
            self.retryManager.retryPullPermission(permVesion: self.permissionResponse?.permVersion) { [weak self] resp in
                guard let `self` = self else { return }
                Self.serialQueue.async {
                    self.cacheResponse(resp: resp)
                }
            }
        }
    }

    func cacheResponse(resp: ServerPB_Authorization_PullPermissionResponse) {
        self.mergeData(resp)
        self.cacheManager.writeCache(self.permissionResponse)
    }

    private func getErrorCodeType(_ error: Error) -> AuthResultErrorReason? {
        var defaultError = AuthResultErrorReason.requestFailed
        guard let rceError = error as? RCError else {
            return defaultError
        }
        switch rceError {
        case .businessFailure(let errorInfo):
            switch errorInfo.errorCode {
            case 100_052:
                defaultError = .networkError
            case 100_054:
                defaultError = .requestTimeout
            default:
                break
            }
        default:
            break
        }
        return defaultError
    }

    func clearIPPermissionData() {
        if let oldPermResp = permissionResponse,
           var oldPermMap = permissionMap {
            let clearList = oldPermResp.permissionExtra.permissionTypeInfos.filter { $0.forceClear }
            clearList.forEach {
                oldPermMap.removeValue(forKey: $0.permType)
                Self.logger.info("n_action_permission_clear_ip_permission, clear_permission_type_\($0.permType)")
            }
            permissionMap = oldPermMap
            permissionResponse?.permissionData.customizedOperatePermissionData = oldPermMap.values.flatMap({ $0 })
            permissionResponse?.permVersion = ""
            cacheManager.writeCache(self.permissionResponse)
        } else {
            Self.logger.info("n_action_permission_auth_no_ip_cache_to_clear")
        }
    }

    func mergeData(
        _ response: ServerPB_Authorization_PullPermissionResponse
    ) {
        Self.logger.info("n_action_permission_merge count: \(response.permissionData.operatePermissionData.count), extended: \(response.permissionData.extendedOperatePermissionData.count)")

        if response.clearOld_p {
            // 删除旧数据替换
            Self.logger.info("n_action_permission_merge_skip clear old data")
            let newPermissionMap = getPermissionMap(response)
            permissionResponse = response
            permissionMap = newPermissionMap
            clearSurplusPermissionData(permissionMap: newPermissionMap)
        } else {
            guard let oldResponse = permissionResponse else {
                // 没有旧数据，直接覆盖
                Self.logger.info("n_action_permission_merge_skip no local data")
                let newPermissionMap = getPermissionMap(response)
                permissionResponse = response
                permissionMap = newPermissionMap
                clearSurplusPermissionData(permissionMap: newPermissionMap)
                return
            }
            let oldPermissionMap = getPermissionMap(oldResponse)
            var newPermissionMap = getPermissionMap(response)

            Self.logger.info("n_action_permission_merge_start old: \(oldPermissionMap.count), new: \(newPermissionMap.count)")
            newPermissionMap.merge(oldPermissionMap) { (current, _) -> [ServerPB_Authorization_CustomizedOperatePermission] in
                return current  // 服务端会下发权限类型对应的所有数据，这里直接替换即可，三端统一逻辑
            }
            Self.logger.info("n_action_permission_merge_succ result: \(newPermissionMap.count)")

            permissionResponse = response
            permissionMap = newPermissionMap
            clearSurplusPermissionData(permissionMap: newPermissionMap)
        }
        self.observerManager.notify()
    }

    private func clearSurplusPermissionData(permissionMap: PermissionMap) {
        // 新老类型的数据都会合并到 customizedOperatePermissionData 字段中，因此将 operatePermissionData 和 extendedOperatePermissionData 置空以避免重复
        permissionResponse?.permissionData.customizedOperatePermissionData = permissionMap.values.flatMap({ $0 })
        permissionResponse?.permissionData.extendedOperatePermissionData = []
        permissionResponse?.permissionData.operatePermissionData = []
    }

    // 返回全量的权限信息，包含 operatePermissionData、extendedOperatePermissionData和customizedOperatePermissionData
    private func getPermissionMap(
        _ response: ServerPB_Authorization_PullPermissionResponse
    ) -> PermissionMap {
        /// 之前的 PermissionType 被设计成 required，会导致新增权限点时解析失败
        /// 为了解决这个问题，服务端新增了 ExtendedOperatePermission(PermissionType 可选)
        /// extendedOperatePermissionData 里面包含了**新类型的增量**权限数据，需要跟老数据合并使用
        /// https://bytedance.feishu.cn/wiki/wikcnKJ6kYJ0BfSInU2bJ3Ht3tc
        /// https://github.com/apple/swift-protobuf/blob/main/Sources/SwiftProtobuf/Enum.swift
        var allOperatePermissionData = response.permissionData.operatePermissionData.map { $0.customizedOperatePermission }
        allOperatePermissionData.append(contentsOf: response.permissionData.extendedOperatePermissionData.map { $0.customizedOperatePermission })
        allOperatePermissionData.append(contentsOf: response.permissionData.customizedOperatePermissionData)

        var opPermissionDataMap: PermissionMap = [:]
        for permission in allOperatePermissionData {
            if var permissions = opPermissionDataMap[permission.permType] {
                permissions.append(permission)
                opPermissionDataMap[permission.permType] = permissions
            } else {
                opPermissionDataMap[permission.permType] = [permission]
            }
        }
        return opPermissionDataMap
    }

    private func enablePullPermission() -> Bool {
        guard let enablePullPermission = enableFetchPermission else {
            let enablePullPermission = AuditPermissionSetting.optPullPermissionsettings(userResolver: userResolver).authzRetry
            self.enableFetchPermission = enablePullPermission
            return enablePullPermission
        }
        return enablePullPermission
    }

    func getStrictAuthMode(resp: ServerPB_Authorization_PullPermissionResponse) {
        if !resp.hasPermissionExtra {
            return
        }
        let fgInfos = resp.permissionExtra.featureGateInfos
        for info in fgInfos where info.isOpen {
            SecurityAuditManager.shared.strictAuthModeCache = true
            return
        }
        SecurityAuditManager.shared.strictAuthModeCache = false
    }

    private func trackPullPermission(trigger: String, triggerSuccess: Bool = true, triggerFailReason: String = "") {
        let tenantId: String = userService?.user.tenant.tenantID ?? ""
        Events.track("scs_authz_pull_permission", params: ["trigger": trigger, "trigger_success": triggerSuccess ? 1 : 0, "trigger_fail_reason": triggerFailReason, "tenant_id": tenantId])
    }

}

extension ServerPB_Authorization_OperatePermission {
    var customizedOperatePermission: ServerPB_Authorization_CustomizedOperatePermission {
        var permission = ServerPB_Authorization_CustomizedOperatePermission()
        permission.permType = permType
        permission.object = object.customizedEntity
        permission.result = result
        return permission
    }
}

extension ServerPB_Authorization_ExtendedOperatePermission {
    var customizedOperatePermission: ServerPB_Authorization_CustomizedOperatePermission {
        var permission = ServerPB_Authorization_CustomizedOperatePermission()
        permission.permType = permType
        permission.object = object.customizedEntity
        permission.result = result
        return permission
    }
}

extension PullPermissionService {
    func registe(_ observer: PermissionChangeAction) {
        observerManager.addObserver(observer)
    }

    func unRegiste(_ observer: PermissionChangeAction) {
        observerManager.removeObserver(observer)
    }
}

#if DEBUG || ALPHA
extension PullPermissionService {
   func clearPermissionData() {
       Self.logger.info("n_action_permission_clear_cache")
       self.cacheManager.clear()
       self.permissionResponse = nil
       self.permissionMap = nil
       DispatchQueue.main.async {
           if let mainWindow = self.userResolver.navigator.mainSceneWindow {
               UDToast.showTips(with: "清理缓存成功", on: mainWindow)
           }
       }
   }

    func fetchPermission() {
        self.fetchPermission(.timer) { [weak self] in
            guard let self else { return }
            DispatchQueue.main.async {
                if let mainWindow = self.userResolver.navigator.mainSceneWindow {
                    UDToast.showTips(with: self.pullSuccess ? "拉取成功" : "拉取失败", on: mainWindow)
                }
            }
        }
    }

    func retryPullPermission() {
        self.retryFetchPermission()
    }

    func mockAndStoreData(padding: CryptoSwift.Padding) {
        let key = padding == .zeroPadding ? Const.permissionCacheKey : Const.permissionCacheKeyWithPKCS7Padding
        let uid = userResolver.userID
        let cache = securityComplianceCache(uid, .securityAudit)
        fetcher.fetchPermissions(permVersion: nil) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let resp):
                do {
                    let mockResp = try self.mockData(resp: resp)
                    let data = try mockResp.serializedData()
                    let encryptedData = try Utils.aes(key: uid, op: .encrypt, data: data, padding: padding)
                    cache.set(object: encryptedData, forKey: key)
                    DispatchQueue.main.async {
                        if let mainWindow = self.userResolver.navigator.mainSceneWindow {
                            UDToast().showTips(with: "success mock with data \(data.count)", on: mainWindow)
                        }
                    }
                } catch {
                    DispatchQueue.main.async {
                        if let mainWindow = self.userResolver.navigator.mainSceneWindow {
                            UDToast().showTips(with: "\(error)", on: mainWindow)
                        }
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    if let mainWindow = self.userResolver.navigator.mainSceneWindow {
                        UDToast().showTips(with: "\(error)", on: mainWindow)
                    }
                }
            }
        }
    }

    private func mockData(resp: ServerPB_Authorization_PullPermissionResponse) throws -> ServerPB_Authorization_PullPermissionResponse {
        // 通过修改 permVersion 使 resp 序列化后 data 的长度刚好为 16 的整数倍
        var mockResp = resp
        mockResp.permVersion = ""
        let data = try mockResp.serializedData()
        var restCount = (16 - data.count % 16)
        var mockPermVersion = ""
        while restCount > 0 {
            restCount -= 1
            // 每加一个字符，data.count ++
            mockPermVersion += "1"
        }
        mockResp.permVersion = mockPermVersion
        return mockResp
    }
}
#endif
