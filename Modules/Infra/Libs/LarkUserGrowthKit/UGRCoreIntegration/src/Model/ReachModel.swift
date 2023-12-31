//
//  ReachModel.swift
//  UGRCoreIntegration
//
//  Created by shizhengyu on 2021/3/10.
//

import Foundation

struct ReachPointGlobalInfo {
    let meta: ReachPointEntity
    let localRuleId: Int64?

    init(meta: ReachPointEntity, localRuleId: Int64?) {
        self.meta = meta
        self.localRuleId = localRuleId
    }
}
