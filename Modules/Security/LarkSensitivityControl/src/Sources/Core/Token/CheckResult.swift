//
//  CheckResult.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/5.
//

import UIKit

/// 检测结果对应的状态码
public enum Code: Int, CustomStringConvertible {
    /// 通过
    case success = 0
    /// token不存在
    case notExist = 1
    /// atomicInfo不匹配
    case atomicInfoNotMatch = 2
    /// 禁用
    case statusDisabled = 3
    /// 策略拦截
    case strategyIntercepted = 4
    /// debug禁用
    case statusDisabledForDebug = 5

    public var description: String {
        switch self {
        case .success:
            return "success"
        case .notExist:
            return "notExist"
        case .atomicInfoNotMatch:
            return "atomicInfoNotMatch"
        case .statusDisabled:
            return "statusDisabled"
        case .strategyIntercepted:
            return "strategyIntercepted"
        case .statusDisabledForDebug:
            return "statusDisabledForDebug"
        }
    }
}

/// 数据读写和解析 & 证书校验结果场景
enum Scene: String {
    case `default` = "default"
    case readLocal = "read_local_data"
    case readBuiltIn = "read_builtin_data"
    case parse = "parse_data"
    case update = "update_local"

    case success = "success"
    case notExist = "token_not_exist"
    case tokenDisabled = "token_disable"
    case atomicInfoNotMatch = "token_atomicInfo_not_match"
}

/// tokenConfigDict的数据来源枚举
enum TokenSource: String {
    case empty = "empty"
    case local = "local"
    case builtIn = "builtin"
    case remote = "remote"
}

/// 拦截结果
public protocol ResultInfo {
    /// 拦截 Code
    var code: Code { get }
    /// Token 信息
    var token: Token { get }
    /// Context 上下文信息
    var context: Context { get }
    /// 构造结果为字典
    /// - Returns: 字典
    func build() -> [String: Any]
}

public extension ResultInfo {
    /// 构造atomicInfo不匹配参数
    func buildAtomicInfo() -> [String: Any] {
        var dict = [String: Any]()
        dict["token"] = token.identifier
        dict["scene"] = getScence(code).rawValue
        dict["token_source"] = TCM.tokenSource.rawValue
        dict["local_info"] = context.atomicInfoList
        dict["remote_info"] = TCM.getAtomicInfo(of: token.identifier)
        return dict
    }

    /// 构造一般参数
    func build() -> [String: Any] {
        var dict = [String: Any]()
        dict["token"] = token.identifier
        dict["scene"] = getScence(code).rawValue
        dict["token_source"] = TCM.tokenSource.rawValue
        return dict
    }

    private func getScence(_ code: Code) -> Scene {
        switch code {
        case .success:
            return Scene.success
        case .notExist:
            return Scene.notExist
        case .atomicInfoNotMatch:
            return Scene.atomicInfoNotMatch
        case .statusDisabled:
            return Scene.tokenDisabled
        case .strategyIntercepted:
            return Scene.default
        case .statusDisabledForDebug:
            return Scene.default
        }
    }
}

struct CheckResult: ResultInfo {
    let token: Token
    let code: Code
    let context: Context
}
