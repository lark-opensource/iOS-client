//
//  Const.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/11/24.
//

import Foundation

struct Const {
    static let xRequestId: String = "X-Request-ID"
    static let contentType: String = "Content-Type"
    static let suiteSessionKey: String = "Suite-Session-Key"
    static let applicationPB: String = "application/x-protobuf"
    static let eventSizeLimit50k: Int = 50 * 1024
    static let requestTimeout: TimeInterval = 15

    static let prefixHTTPS: String = "https://"

    static let apiEvent: String = "suite/admin/security/events/"

    static let dbFileName: String = "security_audit.db"

    static let dbFilePathComponent: String = "SecurityAudit"

    static let dbDeleteSliceLimit: Int = 300

    /// 一次batch上传数量
    static let dbReadLimit: Int = 51

    static let maxReqCntInTimeInterval: Int = 10

    /// 拉取权限 请求次数限制
    static let maxPullPermissionReqCntInTimeInterval: Int = 2

    /// 恢复阀值
    static let recoveryThreshold: Int = 3

#if DEBUG || ALPHA
    static let batchTimerInterval: Int = 10
#else
    static let batchTimerInterval: Int = 60
#endif

    static let pullPermissionTimerInterval: Int = 60 * 15

    static let maxBatchTimerInterval: Int = 16 * batchTimerInterval

    static let bizStatusOK: Int = 0

    static let httpStatusOK: Int = 200

    static let sidecarKey: String = "security_audit_sidecar"

    static let slant: String = "/"

    static let empty: String = "empty"

    static let apiVersion: String = "1-0"

    static let permissionCacheKey: String = "permission"

    static let permissionCacheKeyWithPKCS7Padding: String = "permission_pkcs7"
}
