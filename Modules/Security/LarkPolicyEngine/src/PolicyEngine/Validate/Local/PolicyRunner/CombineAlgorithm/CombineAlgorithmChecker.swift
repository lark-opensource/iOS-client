//
//  CombineAlgorithmChecker.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/9/27.
//

import Foundation

final class CombineAlgorithmChecker<T>: CombineAlgorithmType<T> {

    let realChecker: CombineAlgorithmType<T>

    init(algorithm: CombineAlgorithm) {
        switch algorithm {
        case .firstApplicable:
            realChecker = FirstApplicableAlgorithm<T>()
        case .denyOverride:
            realChecker = DenyOverrideAlgorithm<T>()
        case .firstDenyApplicable:
            realChecker = FirstDenyApplicableAlgorithm<T>()
        case .firstPermitApplicable:
            realChecker = FirstPermitApplicableAlgorithm<T>()
        case .onlyOneApplicable:
            realChecker = OnlyOneApplicableAlgorithm<T>()
        case .permitOverride:
            realChecker = PermitOverrideAlgorithm<T>()
        }
    }

    override func push(node: T, effect: Effect) {
        realChecker.push(node: node, effect: effect)
    }

    override func interrupt() -> Bool {
        return realChecker.interrupt()
    }

    override func genResult() -> (Effect, [T]) {
        return realChecker.genResult()
    }
}
