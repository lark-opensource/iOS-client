//
//  Const.swift
//  LarkPolicyEngine
//
//  Created by 汤泽川 on 2022/11/22.
//

import Foundation

public let LarkPolicyEngineVersion = "1.0.0"

// 支持的策略类型集合
let SUPPORT_POLICY_TYPES: [PolicyType] = [
    .fileProtect
]

// 策略引擎任务执行队列
let PolicyEngineQueue = DispatchSafeQueue(label: "com.dispatch_queue.policy_engine")

// 因子管控检查最大并发数
let FactorsControlMaxRequestCount = 100

let PolicyRemoteCheckMaxRequestCount = 20

// 客户端策略引擎能够解析的action 列表
enum KnownAction: ActionName {
    case fileBlockCommon = "FILE_BLOCK_COMMON"
    case dlpContentDetecting = "DLP_CONTENT_DETECTING"
    case dlpContentSensitive = "DLP_CONTENT_SENSITIVE"
    case ttBlock = "TT_BLOCK"
    case universalFallbackCommon = "UNIVERSAL_FALLBACK_COMMON"
    case fallbackCommon = "FALLBACK_COMMON"
}
