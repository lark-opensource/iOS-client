//
//  SecurityPolicyService.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2022/11/15.
//

import Foundation

public protocol SecurityPolicyService {
    // 本地缓存校验接口，内部只根据本地缓存结果进行校验
    func cacheValidate(policyModel: PolicyModel,
                       authEntity: AuthEntity?,
                       config: ValidateConfig?) -> ValidateResult
    // 异步校验接口，内部会依次经过本地缓存校验->本地策略校验->服务端接口校验，其中任何一环节返回Deny即返回
    func asyncValidate(policyModel: PolicyModel,
                       authEntity: AuthEntity?,
                       config: ValidateConfig?,
                       complete: @escaping(ValidateResult) -> Void)
    // 异步批量校验接口，内部会依次经过本地缓存校验->本地策略校验->服务端接口校验，其中任何一环节返回Deny即返回
    func asyncValidate(policyModels: [PolicyModel],
                       config: ValidateConfig?,
                       complete: @escaping([String: ValidateResult]) -> Void)
    // 直接弹出安全模型校验的弹窗，内部不会再经过校验，直接弹出对应弹窗
    func showInterceptDialog(policyModel: PolicyModel)
    // 是否可以快速通过，即该点位不需要经过校验
    func isEnableFastPass(policyModel: PolicyModel) -> Bool

    func config()

    func handleSecurityAction(securityAction: SecurityActionProtocol)
    
    func dlpMaxDetectingTime() -> Int // 单位：秒
}

public protocol SecurityActionProtocol: Codable {
    var rawActions: String { get }
}

public struct DefaultSecurityAction: SecurityActionProtocol {
    public var rawActions: String

    public init(rawActions: String) {
        self.rawActions = rawActions
    }
}
