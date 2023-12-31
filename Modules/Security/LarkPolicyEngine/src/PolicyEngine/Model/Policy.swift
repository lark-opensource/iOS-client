//
//  Policy.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/28.
//  Define from server:
//  https://code.byted.org/gerrit/ee/idl/-/blob/idl/lark/scs/compliance/lark.scs.compliance.policy_engine.thrift

import Foundation

typealias PolicyID = String
typealias PolicyFilterCondition = String
typealias PolicyVersion = String
/// policy id -> policy filter
typealias PolicyMap = [PolicyID: PolicyInfo]

struct PolicyInfo: Equatable, Codable {
    let version: PolicyVersion
    let filterCondition: PolicyFilterCondition
}

public enum PolicyAdvice: String, Codable {
    case unknown = "unknown"
    case before = "BEFORE"
    case after = "AFTER"
    case middle = "MIDDLE"
    public init(from decoder: Decoder) throws {
        self = try PolicyAdvice(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

public enum PolicyType: String, Codable, CaseIterable {
    case unknown = "unknown"
    case conditionalAccessPolicy = "COND_ACCESS" // 条件访问控制策略
    case retentionScopePolicy = "RETENTION_SCOPE" // 数据删除-人群范围策略
    case retentionDeletePolicy = "RETENTION_DELETE" // 数据删除-删除标签策略
    case DLPPolicy = "DLP" // DLP
    case DLPAsyncPolicy = "DLP_ASYNC" // DLP离线
    case alarmBehaviorAudit = "ALARM_BEHAVIOR_AUDIT"
    case DLPNative = "DLP_NATIVE"
    case fileProtect = "FILE_PROTECT"               // 文件操作权限保护

    public init(from decoder: Decoder) throws {
        self = try PolicyType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

public struct Condition: Codable {
    let rawExpression: String
}

public enum Effect: String, Codable {
    case permit = "PERMIT"
    case deny = "DENY"
    case indeterminate = "INDETERMINATE"
    case notApplicable = "NOT_APPLICABLE"
}

public typealias ActionName = String
public struct ConditionalAction: Codable {
    let condition: Condition
    let actions: [ActionName]
}

public struct Decision: Codable {
    let effect: Effect
    var actions: [ConditionalAction]
}

/// 组合算法 参考：https://bytedance.feishu.cn/wiki/wikcn1v7XNHY6E1Z8VZk7Rj2hbj#doxcnQ2YEEwSg8KikWMhRgx6pqd
public enum CombineAlgorithm: String, Codable, CaseIterable {
    case firstApplicable = "FirstApplicable"
    case denyOverride = "DenyOverride"
    case firstDenyApplicable = "FirstDenyApplicable"
    case firstPermitApplicable = "FirstPermitApplicable"
    case onlyOneApplicable = "OnlyOneApplicable"
    case permitOverride = "PermitOverride"
}

public enum PolicyBasedOnEntity: String, Codable {
    case policyBasedOnEntitySubject = "SUBJECT"
    case policyBasedOnEntityObject = "OBJECT"
    case unknown
    public init(from decoder: Decoder) throws {
        self = try PolicyBasedOnEntity(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

public struct Rule: Codable {
    let condition: Condition
    var decision: Decision
}

public struct Policy: Codable {
    public let id: String
    public let name: String
    public let tenantID: String
    public let type: PolicyType
    public let filterCondition: Condition
    public var rules: [Rule]
    public let combineAlgorithm: CombineAlgorithm
    public let version: String
    public let basedOn: PolicyBasedOnEntity
}

public struct PolicyRuntimeConfigModel: Codable {
    let policies: [Policy]?
    let policyType2combineAlgorithm: [String: String]?
}

public struct PolicyEntityModel: Codable {
    var policies: [String: Policy]?
    var policyType2combineAlgorithm: [String: String]?
}

public struct PolicyPairsModel: Codable {
    let policyPairs: [PolicyPair]?
    let policyType2CombineAlgorithmMap: [String: String]?
}

public struct PolicyEntityResponse: Codable {
    let policies: [Policy]?
}

public struct PolicyPair: Codable {
    let id: String
    let version: String
}

struct PolicyUpdateResult {
    let reserve: [String: String]
    let new: [String: String]
}
