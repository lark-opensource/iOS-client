//
//  SecurityAuditManager.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import Foundation
import LKCommonsLogging
import ThreadSafeDataStructure
import Reachability
import LarkContainer
import LarkAccountInterface
import ByteDanceKit
import LarkSecurityComplianceInfra

/// 用于初始化全局配置
public final class SecurityAuditManager {

    /// singleton instance
    public static let shared = SecurityAuditManager()

    /// sidecar id
    public var sidecar: String {
        get {
            return udkv?.string(forKey: Const.sidecarKey) ?? ""
        }
        set {
            udkv?.set(newValue, forKey: Const.sidecarKey)
        }
    }

    private(set) var userResolver: UserResolver?

    private(set) var udkv: SCKeyValueStorage?

    /// init sdk
    public func initSDK(_ conf: Config) {
        self.conf = conf
    }

    /// start sdk
    /// 如果已启动SDK，会先销毁SDK，再重新启动SDK
    public func start(resolver: UserResolver) {
        if started.value {
            stop()
        }
        self.userResolver = resolver
        self.udkv = SCKeyValue.userDefaultEncrypted(userId: resolver.userID)
        started.value = true
        self.batchService = BatchService()
        self.batchService?.timer.startTimer()
        if PullPermissionService.enablePermission(resolver: resolver) {
            Self.logger.info("init pull permission")
            self.pullPermissionService = PullPermissionService(resolver: resolver)
            self.pullPermissionService?.timer.startTimer()
        } else {
            Self.logger.info("fg disable not init pull permission")
        }
    }

    /// stop batch upload
    public func stop() {
        started.value = false
        self.batchService?.timer.stopTimer()
        self.batchService = nil
        self.pullPermissionService?.timer.stopTimer()
        self.pullPermissionService = nil
        self.strictAuthMode = nil
        self.userResolver = nil
        self.udkv = nil
    }

    init() {
        reachability = Reachability()
        try? reachability?.startNotifier()
    }

    internal func auditEvent(_ event: Event, _ commonEvent: Event?) {
        assert(hasInitialize(), "must initSDK before use")
        enqueueEvent(event, commonEvent)
    }

    private func enqueueEvent(_ event: Event, _ commonEvent: Event?) {

        Self.serialQueue.async {
            do {
                let event = event.fillCommonFields()
                #if DEBUG || ALPHA
                _ = try Utils.verify(event, commonEvent)
                #endif
                let mergedEvent = try Utils.merge(event, commonEvent)
#if DEBUG || ALPHA || BETA
                self.checkRequiredParams(mergedEvent)
#endif
                assert(
                    !mergedEvent.objects.isEmpty,
                    "event require objects.count > 0"
                )
                assert(
                    mergedEvent.isInitialized,
                    "event not initialized all required fileds event module: \(mergedEvent.module)"
                )
                Database.shared.aduitLogTable.insert(event: mergedEvent)
            } catch {
                Self.logger.error("enqueue event failed", error: error)
            }
        }
    }

    static let logger = Logger.log(SecurityAuditManager.self, category: "SecurityAudit.SecurityAuditManager")

    static let serialQueue = DispatchQueue(label: "security.audit.event.enqueue", qos: .background)

    internal var conf: Config {
        get { _conf.value }
        set { _conf.value = newValue }
    }
    private var _conf: SafeAtomic<Config> = Config(
        hostProvider: nil,
        deviceId: "",
        session: ""
    ) + .readWriteLock

    internal var host: String? { conf.hostProvider?() }

    private func hasInitialize() -> Bool {
        return conf.hostProvider != nil
    }

    private var batchService: BatchService?
    private(set) var started: SafeAtomic<Bool> = false + .readWriteLock
    private let reachability: Reachability?
    var enableFetchPermission: Bool?

    internal var isNetworkEnable: Bool {
        if let reach = reachability {
            switch reach.connection {
            case .cellular, .wifi:
                return true
            case .none:
                return false
            @unknown default:
                return true
            }
        } else {
            return true
        }
    }

    // MARK: Permission
    var pullPermissionService: PullPermissionService? {
        get { _pullPermissionService.value }
        set { _pullPermissionService.value = newValue }
    }
    // swiftlint:disable identifier_name
    private var _pullPermissionService: SafeAtomic<PullPermissionService?> = nil + .readWriteLock
    // swiftlint:enable identifier_name

    var lastErrorType: AuthResultErrorReason?

    var strictAuthMode: Bool?

#if DEBUG || ALPHA || BETA
    private func checkRequiredParams(_ event: Event) {
        if event.module.rawValue == ModuleType.moduleUnknown.rawValue
            || event.operation.rawValue == OperationType.unknown.rawValue
            || event.timeStamp.isEmpty
            || event.operator.type.rawValue == EntityType.unknown.rawValue
            || event.operator.value.isEmpty
            || (event.operator.type.rawValue == EntityType.entityBotID.rawValue && event.tenantID.isEmpty) {
            SCMonitor.info(business: .security_audit, eventName: "parameter_missing", category: ["event": "\(event)"])
        }
    }
#endif
}

extension SecurityEvent_Event {
    func fillCommonFields() -> SecurityEvent_Event {
        var event = self
        if !event.hasTimeStamp {
            event.timeStamp = String(Int64(Date().timeIntervalSince1970 * 1000))
        }
        if !event.env.hasDid {
            event.env.did = SecurityAuditManager.shared.conf.deviceId
        }
        return event
    }
}
