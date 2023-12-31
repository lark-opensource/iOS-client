//
//  PolicyEngineService.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/28.
//

import Foundation

public enum ResponseType: String, Codable {
    case fastPass = "fast_pass"
    case local = "local"
    case remote = "remote"
    case downgrade = "downgrade"
}

public class ValidateRequest {
    let pointKey: String
    let entityJSONObject: [String: Any]

    let uuid = UUID().uuidString

    public init(pointKey: String, entityJSONObject: [String: Any] = [:]) {
        self.pointKey = pointKey
        self.entityJSONObject = entityJSONObject
    }
}

public struct Action: Codable {
    public let name: String
    public let params: [String: Any]

    public init(name: String, params: [String: Any] = [:]) {
        self.name = name
        self.params = params
    }

    enum CodingKeys: CodingKey {
        case name
        case params
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        let jsonObject = try container.decode(Data.self, forKey: .params)
        self.params = (try JSONSerialization.jsonObject(with: jsonObject) as? [String: Any]) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        let jsonData = try JSONSerialization.data(withJSONObject: self.params)
        try container.encode(jsonData, forKey: .params)
    }
}

public struct ValidateResponse: Codable {
    public let effect: Effect
    public let actions: [Action]
    public let uuid: String
    public let errorMsg: String?
    public let type: ResponseType
    public let policySetKeys: [String]?

    public var allow: Bool {
        return effect != .deny
    }

    public init(effect: Effect, actions: [Action], uuid: String, type: ResponseType, errorMsg: String? = nil, policySetKeys: [String]? = []) {
        self.effect = effect
        self.actions = actions
        self.uuid = uuid
        self.type = type
        self.errorMsg = errorMsg
        self.policySetKeys = policySetKeys
    }
}

public final class CheckPointcutRequest: ValidateRequest {
    let factors: [String]

    public init(pointKey: String, entityJSONObject: [String: Any], factors: [String]) {
        self.factors = factors
        super.init(pointKey: pointKey, entityJSONObject: entityJSONObject)
    }
}

public protocol PolicyEngineService {

    /// 注册动态参数
    /// - Parameter parameter: 动态参数
    func register(parameter: Parameter)

    /// 移除动态参数
    /// - Parameter parameter: 动态参数
    func remove(parameter: Parameter)

    /// 注册策略引擎内部事件观察者
    /// 弱引用
    /// - Parameter observer: observer
    func register(observer: Observer)

    /// 移除观察者
    /// - Parameter observer: observer
    func remove(observer: Observer)

    /// 发送事件
    /// 策略引擎内部使用
    func postEvent(event: InnerEvent)

    func asyncValidate(requestMap: [String: ValidateRequest],
                       callback: (([String: ValidateResponse]) -> Void)?)

    func downgradeDecision(request: ValidateRequest) -> ValidateResponse

    func enableFastPass(request: ValidateRequest) -> Bool

    func checkPointcutIsControlledByFactors(requestMap: [String: CheckPointcutRequest],
                                            callback: ((_ retMap: [String: Bool]) -> Void)?)
    func enableFetchPolicy(tenantId: String?) -> Bool
    
    func reportRealLog(evaluateInfoList: [EvaluateInfo])
    
    func deleteDecisionLog(evaluateInfoList: [EvaluateInfo])
}
