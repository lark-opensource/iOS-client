//
//  TokenChecker.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/8.
//

import UIKit
import LarkSnCService

/// 默认Token，用于Debug环境
public let kTokenAvoidInterceptIdentifier = "psda_token_avoid_intercept"
/// 禁用token的开关key值
public let kTokenDisabledCacheKey = "disable_all_token_key"
/// 全链路监控告警上报key值
let kMonitorErrorKey = "error_monitor"

/// token检测失败的错误类型
enum ErrorInfo: String {
    /// 不存在
    case NONE = "notExist"
    /// atomicInfo不匹配
    case MATCH = "atomicInfoNotMatch"
    /// 被禁用
    case STATUS = "statusDisabled"
    /// 策略引擎拦截
    case STRATEGY = "strategyIntercepted"
    /// debug环境下被禁用
    case DISABLEDFORDEBUG = "statusDisabledForDebug"
}

/// 有效性验证异常
///
/// 目前只有一种情况：token被禁用时才抛该异常
public struct CheckError: Error, CustomStringConvertible {

    /// 错误信息描述
    let errorInfo: String

    public var description: String {
        return "Token check errorInfo: \(errorInfo)."
    }

}

extension CheckError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}

/// token有效性检测
extension Token {
    /// for debug
    static var isDisabled: Bool = {
        return (try? LSC.storage?.get(key: kTokenDisabledCacheKey).or(false)).or(false)
    }()

    static func updateDisabledState(_ disabled: Bool) {
        isDisabled = disabled
    }

    /// token有效性检测，并根据不同的状态码抛出相应的异常
    func check(context: Context) throws {
        let result = TCM.checkResult(ofToken: self, context: context)
        switch result.code {
        case .notExist where !TCM.getConfigDict().isEmpty:
            // token不存在 且 本地token缓存不为空时上报
            LSC.logger?.warn("token: \(identifier), alarm info: \(result.build()), error code: \(result.code.description).")
            LSC.monitor?.sendInfo(service: kMonitorErrorKey, category: result.build(), metric: nil)
        case .atomicInfoNotMatch:
            // API不匹配时上报
            LSC.logger?.warn("token: \(identifier), error info: \(result.buildAtomicInfo()), error code: \(result.code.description).")
            LSC.monitor?.sendInfo(service: kMonitorErrorKey, category: result.buildAtomicInfo(), metric: nil)
        case .statusDisabled where !Self.isDisabled:
            // token禁用 且 Mock开关关闭时上报
            LSC.logger?.warn("token: \(identifier), error info: \(result.build()), error code: \(result.code.description).")
            LSC.monitor?.sendInfo(service: kMonitorErrorKey, category: result.build(), metric: nil)
        default:
            break
        }

        if Self.isDisabled {
            throw CheckError(errorInfo: ErrorInfo.DISABLEDFORDEBUG.rawValue)
        }
        switch result.code {
        case .success: break
        case .notExist: break
//            throw CheckError(errorInfo: ErrorInfo.NONE.rawValue)
        case .atomicInfoNotMatch: break
//            throw CheckError(errorInfo: ErrorInfo.MATCH.rawValue)
        case .statusDisabled:
            throw CheckError(errorInfo: ErrorInfo.STATUS.rawValue)
        case .strategyIntercepted: break
//            throw CheckError(errorInfo: ErrorInfo.STRATEGY.rawValue)
        case .statusDisabledForDebug:
            throw CheckError(errorInfo: ErrorInfo.DISABLEDFORDEBUG.rawValue)
        }
    }

}
