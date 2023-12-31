//
//  PermissionSDK+Log.swift
//  SKPermission
//
//  Created by Weston Wu on 2023/5/15.
//

import Foundation
import SKFoundation
import SpaceInterface
import UniverseDesignToast

// 日志方法入参多，豁免下长参数检查
// nolint: long parameters
struct PermissionSDKLogger {
    // 比 debug 高一级，会打在日志里，在 logifer 上是 debug 级别
    static func verbose(_ message: String,
                        extraInfo: [String: Any]? = nil,
                        error: Error? = nil,
                        component: String? = LogComponents.permissionSDK,
                        traceID: String? = nil,
                        fileName: String = #fileID,
                        funcName: String = #function,
                        funcLine: Int = #line) {
        // verbose 实际上会被过滤，这里还是按照 info 级别打，但是加上 verbose 关键词方便过滤
        DocsLogger.info(message, extraInfo: extraInfo, error: error, component: "\(component ?? "") [verbose] ", traceId: traceID, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }

    static func info(_ message: String,
                     extraInfo: [String: Any]? = nil,
                     error: Error? = nil,
                     component: String? = LogComponents.permissionSDK,
                     traceID: String? = nil,
                     fileName: String = #fileID,
                     funcName: String = #function,
                     funcLine: Int = #line) {
        DocsLogger.info(message, extraInfo: extraInfo, error: error, component: component, traceId: traceID, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }

    static func warning(_ message: String,
                        extraInfo: [String: Any]? = nil,
                        error: Error? = nil,
                        component: String? = LogComponents.permissionSDK,
                        traceID: String? = nil,
                        fileName: String = #fileID,
                        funcName: String = #function,
                        funcLine: Int = #line) {
        DocsLogger.warning(message, extraInfo: extraInfo, error: error, component: component, traceId: traceID, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }

    static func error(_ message: String,
                     extraInfo: [String: Any]? = nil,
                     error: Error? = nil,
                     component: String? = LogComponents.permissionSDK,
                     traceID: String? = nil,
                     fileName: String = #fileID,
                     funcName: String = #function,
                     funcLine: Int = #line) {
        DocsLogger.error(message, extraInfo: extraInfo, error: error, component: component, traceId: traceID, fileName: fileName, funcName: funcName, funcLine: funcLine)
    }

    static func undefinedValidation(operation: PermissionRequest.Operation,
                                    validator: String,
                                    traceID: String? = nil,
                                    fileName: String = #fileID,
                                    funcName: String = #function,
                                    funcLine: Int = #line) {
        #if DEBUG || ALPHA
        DocsLogger.error("undefined validation found",
                         extraInfo: [
                            "operation": operation,
                            "validator": validator
                         ],
                         component: LogComponents.permissionSDK,
                         traceId: traceID,
                         fileName: fileName,
                         funcName: funcName,
                         funcLine: funcLine)
        spaceAssertionFailure("undefined validation found for operation: \(operation), validator: \(validator)")
        #else
        DocsLogger.verbose("undefined validation found",
                           extraInfo: [
                            "operation": operation,
                            "validator": validator
                           ],
                           component: LogComponents.permissionSDK,
                           traceId: traceID,
                           fileName: fileName,
                           funcName: funcName,
                           funcLine: funcLine)
        #endif
    }
}
// enable-lint: long parameters

extension PermissionSDK {
    typealias Logger = PermissionSDKLogger
}

extension PermissionSDKValidator {
    typealias Logger = PermissionSDKLogger
}

extension PermissionRequest.Entity {
    var desensitizeDescription: String {
        switch self {
        case let .ccm(token, type, parentMeta):
            let parentMessage: String
            if let parentMeta {
                parentMessage = "\(DocsTracker.encrypt(id: parentMeta.objToken)):\(parentMeta.objType)"
            } else {
                parentMessage = "nil"
            }
            return "CCM:\(DocsTracker.encrypt(id: token)):\(type), parent:\(parentMessage)"
        case let .driveSDK(domain, fileID):
            return "DriveSDK:\(domain):\(DocsTracker.encrypt(id: fileID))"
        }
    }
}

extension PermissionRequest.BizDomain {
    var desensitizeDescription: String {
        switch self {
        case let .customCCM(fileBizDomain):
            return "CCMEntity:\(fileBizDomain)"
        case let .customIM(fileBizDomain, _, _, _, _, _, _):
            return "IMEntity:\(fileBizDomain)"
        }
    }
}

extension PermissionDefaultUIBehaviorType {
    var desensitizeDescription: String {
        switch self {
        case let .toast(config, allowOverrideMessage, _, _):
            return "TOAST:\(config.toastType):\(config.text):ALLOW_OVERRIDE:\(allowOverrideMessage)"
        case .present:
            return "PRESENT_CONTROLLER"
        case .custom:
            return "CUSTOM_ACTION"
        }
    }
}

extension PermissionValidatorResponse {
    var desensitizeDescription: String {
        switch self {
        case .allow:
            return "ALLOW"
        case let .forbidden(denyType, preferUIStyle, defaultUIBehaviorType):
            return "FORBIDDEN, denyType: \(denyType), preferUIStyle: \(preferUIStyle), defaultBehaviorType: \(defaultUIBehaviorType.desensitizeDescription)"
        }
    }
}

extension UserPermissionService {
    typealias Logger = PermissionSDKLogger
}

extension UserPermissionEntity {
    var desensitizeDescription: String {
        switch self {
        case let .document(token, type, parentMeta):
            let parentMessage: String
            if let parentMeta {
                parentMessage = "\(DocsTracker.encrypt(id: parentMeta.objToken)):\(parentMeta.objType)"
            } else {
                parentMessage = "nil"
            }
            return "document:\(DocsTracker.encrypt(id: token)):\(type), parent:\(parentMessage)"
        case let .folder(token):
            return "folder:\(DocsTracker.encrypt(id: token))"
        case let .legacyFolder(info):
            return "legacyFolder:\(DocsTracker.encrypt(id: info.token)):\(info.folderType)"
        }
    }
}

extension UserPermissionResponse {
    var desensitizeDescription: String {
        switch self {
        case .success:
            return "success"
        case let .noPermission(statusCode, applyUserInfo):
            let userIDInLog: String
            if let applyUserInfo {
                userIDInLog = DocsTracker.encrypt(id: applyUserInfo.userID)
            } else {
                userIDInLog = "nil"
            }
            return "noPermission, code: \(statusCode), applyUserID: \(userIDInLog)"
        }
    }
}

extension PermissionResponse {
    var desensitizeDescription: String {
        switch result {
        case .allow:
            return "ALLOW"
        case let .forbidden(denyType, preferUIStyle):
            return "FORBIDDEN, denyType: \(denyType), preferUIStyle: \(preferUIStyle)"
        }
    }
}

extension UserPermissionAPIResult {
    var desensitizeDescription: String {
        switch self {
        case .success:
            return "success"
        case let .noPermission(_, statusCode, applyUserInfo):
            let userIDInLog: String
            if let applyUserInfo {
                userIDInLog = DocsTracker.encrypt(id: applyUserInfo.userID)
            } else {
                userIDInLog = "nil"
            }
            return "noPermission, code: \(statusCode), applyUserID: \(userIDInLog)"
        }
    }
}

extension PermissionCommonErrorContext {
    var desensitizeDescription: String {
        "token: \(DocsTracker.encrypt(id: objToken)), type: \(objType), operation: \(operation)"
    }
}

extension DLP {
    typealias Logger = PermissionSDKLogger
}
