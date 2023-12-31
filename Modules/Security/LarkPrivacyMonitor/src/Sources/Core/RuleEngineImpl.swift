//
//  RuleEngineImpl.swift
//  LarkPrivacyMonitor-LarkPrivacyMonitor
//
//  Created by huanzhengjie on 2022/11/1.
//

import PNSServiceKit
import BDRuleEngine

typealias Execute = (NSMutableArray) -> Any

final class REFunc: BDREFunc {
    var block: Execute?
    override func execute(_ params: NSMutableArray) -> Any {
        if let block = self.block {
            return block(params)
        } else {
            return false
        }
    }
}

final class RuleSingleResult: NSObject, PNSSingleRuleResultProtocol {
    var conf: [AnyHashable: Any] = [:]

    var title: String?

    var key: String?
}

final class RuleResult: NSObject, PNSRuleResultProtocol {
    var signature: String?

    var scene: String?

    var ruleSetNames: [String]?

    var values: [PNSSingleRuleResultProtocol]?

    var usedParameters: [AnyHashable: Any]?
}

final class RuleEngineImpl: NSObject, PNSRuleEngineProtocol {
    func validateParams(_ params: [AnyHashable: Any]?) -> PNSRuleResultProtocol? {
        guard let params = params else {
            return nil
        }
        let model = BDStrategyCenter.validateParams(params)
        let result = RuleResult()
        result.ruleSetNames = model.ruleSetNames
        result.usedParameters = model.usedParameters
        var values: [PNSSingleRuleResultProtocol] = []
        for singleRuleResult in (model.values ?? []) {
            let itemResult = RuleSingleResult()
            itemResult.conf = singleRuleResult.conf
            itemResult.title = singleRuleResult.title
            itemResult.key = singleRuleResult.key
            values.append(itemResult)
        }
        result.values = values
        return result
    }

    func contextInfo() -> [AnyHashable: Any]? {
        return [:]
    }

    func register(_ funcc: PNSREFunc) {
        let adaptFunc = REFunc()
        adaptFunc.symbol = funcc.symbol()
        adaptFunc.block = { (param) in
            return funcc.execute(param) ?? false
        }
        BDREExprRunner.shared().register(adaptFunc)
    }
}
