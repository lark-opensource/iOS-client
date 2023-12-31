//
//  RunnerContext.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/29.
//

import Foundation
import LarkExpressionEngine
import LarkSnCService

public struct RunnerContext {
    public let uuid: String
    public let contextParams: [String: Any]
    public let policies: [String: Policy]
    public let combineAlgorithm: CombineAlgorithm
    public let service: SnCService

    public init(uuid: String,
                contextParams: [String: Any],
                policies: [String: Policy],
                combineAlgorithm: CombineAlgorithm,
                service: SnCService) {
        self.uuid = uuid
        self.contextParams = contextParams
        self.policies = policies
        self.combineAlgorithm = combineAlgorithm
        self.service = service
    }
}
