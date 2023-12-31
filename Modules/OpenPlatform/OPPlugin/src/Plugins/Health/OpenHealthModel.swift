//
//  OpenHealthModel.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/9/16.
//

import Foundation
import LarkOpenAPIModel

final class StepCountResult: OpenAPIBaseResult {
    let stepCount: Int

    init(stepCount: Int) {
        self.stepCount = stepCount
        super.init()
    }

    override func toJSONDict() -> [AnyHashable : Any] {
        return ["stepCount" : stepCount]
    }
}
