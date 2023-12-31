//
//  Interface.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/22.
//

import Foundation
import ThreadSafeDataStructure
import LKCommonsLogging

// swiftlint:disable missing_docs
public final class Config {

    public static let emptyConfig: Config = Config(hostProvider: nil, deviceId: "", session: "")

    public static let larkAppId: Int = 1

    public var hostProvider: (() -> String)?
    public var deviceId: String {
        get { _deviceId.value }
        set { _deviceId.value = newValue }
    }
    private var _deviceId: SafeAtomic<String>
    public var session: String {
        get { _session.value }
        set { _session.value = newValue }
    }
    private var _session: SafeAtomic<String>
    public var appId: Int {
        get { _appId.value }
        set { _appId.value = newValue }
    }
    private var _appId: SafeAtomic<Int>

    public init(
        hostProvider: (() -> String)?,
        deviceId: String,
        session: String,
        appId: Int = Config.larkAppId
    ) {
        self.hostProvider = hostProvider
        self._deviceId = deviceId + .readWriteLock
        self._session = session + .readWriteLock
        self._appId = appId + .readWriteLock

    }
}

public typealias Event = SecurityEvent_Event
public typealias OperatorEntity = SecurityEvent_OperatorEntity
public typealias Env = SecurityEvent_Env
public typealias ModuleType = SecurityEvent_ModuleType
public typealias Extend = SecurityEvent_Extend
public typealias FlagType = SecurityEvent_FlagType
public typealias ClientType = SecurityEvent_ClientType
public typealias EntityType = SecurityEvent_EntityType
public typealias CommentType = SecurityEvent_CommentType
public typealias ObjectEntity = SecurityEvent_ObjectEntity
public typealias ObjectDetail = SecurityEvent_ObjectDetail
public typealias OperationType = SecurityEvent_OperationType
public typealias RecipientEntity = SecurityEvent_RecipientEntity
public typealias PermissionActionType = SecurityEvent_PermissionActionType
public typealias PermissionSettingType = SecurityEvent_PermissionSettingType
public typealias RecipientDetail = SecurityEvent_RecipientDetail

protocol SecurityAuditProtocol {
    func auditEvent(_ event: Event)
}

public final class SecurityAudit: SecurityAuditProtocol {
    ///
    /// 共享参数
    /// 优先级：
    ///    - event: Event > sharedParams: Event > Config
    public var sharedParams: Event?

    public init() {}

    public func auditEvent(_ event: Event) {
        SecurityAuditManager.shared.auditEvent(event, sharedParams)
    }
}
// swiftlint:enable missing_docs
