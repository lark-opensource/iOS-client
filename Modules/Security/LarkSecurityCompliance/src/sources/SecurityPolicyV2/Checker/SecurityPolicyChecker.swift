//
//  SecurityPolicyChecker.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/9.
//

import Foundation
import LarkSecurityComplianceInterface
import RxSwift

protocol SecurityPolicyChecker {
    var identifier: String { get }
    /// 缓存校验：结果只从缓存中获取，缓存中无结果时，直接返回降级结果,
    /// - Parameter policyModel: 校验模型
    /// - Returns: 校验结果，结果类型为SecurityPolicyValidateResultCache
    func checkCacheAuth(policyModel: PolicyModel, config: ValidateConfig) -> ValidateResultProtocol?
    /// 异步校验：先从缓存中获取结果，有缓存结果直接返回，无缓存结果异步请求获取结果，请求失败，返回降级结果
    /// - Parameters:
    ///   - policyModel: 校验模型
    ///   - completed: 异步校验回调，回调中的结果类型为ValidateReult
    func checkAsyncAuth(policyModel: PolicyModel, config: ValidateConfig, complete: @escaping (ValidateResultProtocol?) -> Void)
}
