//
//  RunnerCost.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2023/9/27.
//

import Foundation

public struct RunnerCost {
    var exprCount = 0
    var parseCost = 0
    var execCost = 0
    var paramCost = 0
    var excutorType: ExprEngineType = .native
}

extension RunnerCost {
    static func + (left: RunnerCost, right: RunnerCost) -> RunnerCost {
        return RunnerCost(
            exprCount: left.exprCount + right.exprCount,
            parseCost: left.parseCost + right.parseCost,
            execCost: left.execCost + right.execCost,
            paramCost: left.paramCost + right.paramCost,
            excutorType: right.excutorType
        )
    }

    static func += (left: inout RunnerCost, right: RunnerCost) {
        left.exprCount += right.exprCount
        left.parseCost += right.parseCost
        left.execCost += right.execCost
        left.paramCost += right.paramCost
        left.excutorType = right.excutorType
    }
}
