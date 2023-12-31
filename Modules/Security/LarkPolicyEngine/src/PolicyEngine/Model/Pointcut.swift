//
//  Pointcut.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/2/14.
//

import Foundation

public struct PointCutModel: Codable {
    public let tags: [String: String]
    public let contextDerivation: [String: String]
    public let fallbackStrategy: Int
    public let identifier: String
    public let appliedPolicyTypes: [PolicyType]
    public let fallbackActions: [ActionName]?
}

struct PointcutQueryDataModel: Codable {
    let pointcuts: [PointCutModel]?
}
