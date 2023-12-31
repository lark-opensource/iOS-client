//
//  Interceptor.swift
//  LarkSensitivityControl
//
//  Created by huanzhengjie on 2022/8/30.
//

import UIKit

/// 拦截器判断结果
public enum InterceptorResult {
    /// 继续执行
    case `continue`
    /// 被拦截并返回判断结果
    case `break`(ResultInfo)
}

/// 拦截器
public protocol Interceptor {
    /// 拦截规则
    func intercept(token: Token, context: Context) -> InterceptorResult
}

/// 忽略检测的拦截器，特殊场景下使用，如debug
struct IgnoreInterceptor: Interceptor {

    func intercept(token: Token, context: Context) -> InterceptorResult {
        let flag = token.identifier == kTokenAvoidInterceptIdentifier
        return flag ? .break(CheckResult(token: token, code: .success, context: context)) : .continue
    }
}

/// token不存在拦截器
struct NotExistInterceptor: Interceptor {

    func intercept(token: Token, context: Context) -> InterceptorResult {
        let result = CheckResult(token: token, code: .notExist, context: context)
        return TCM.contains(token: token) ? .continue : .break(result)
    }
}

/// AtomicInfo不匹配拦截器
struct AtomicInfoNotMatchInterceptor: Interceptor {

    func intercept(token: Token, context: Context) -> InterceptorResult {
        // 如果本地atomicinfo为默认的atomicinfo则不拦截
        if let localAtomicInfo = context.atomicInfoList.first, localAtomicInfo == AtomicInfo.Default.defaultAtomicInfo.rawValue {
            return .continue
        }
        guard let remoteAtomicInfoList = TCM.getAtomicInfo(of: token.identifier) else {
            LSC.logger?.info("atomicinfo not match, token: \(token.identifier), local info: \(context.atomicInfoList), remote info is empty")
            return .break(CheckResult(token: token, code: .atomicInfoNotMatch, context: context))
        }
        // 服务端下发的atomicinfo数组包含所有的本地atomicinfo则不拦截
        for localAtomicInfo in context.atomicInfoList where !remoteAtomicInfoList.contains(localAtomicInfo) {
            LSC.logger?.info("atomicinfo not match, token: \(token.identifier), local info: \(context.atomicInfoList), remote info: \(remoteAtomicInfoList)")
            return .break(CheckResult(token: token, code: .atomicInfoNotMatch, context: context))
        }
        return .continue
    }
}

/// token禁用拦截器
struct DisableInterceptor: Interceptor {

    func intercept(token: Token, context: Context) -> InterceptorResult {
        let result = CheckResult(token: token, code: .statusDisabled, context: context)
        return TCM.isForbidden(token: token) ? .break(result) : .continue
    }
}
