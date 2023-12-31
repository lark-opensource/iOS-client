//
//  SceneEventManager.swift
//  LarkSecurityComplianceInterface
//
//  Created by ByteDance on 2023/7/24.
//

import Foundation

public enum Trigger: String {
    case start // 启动场景事件：创建一个场景事件handler，并启动handler操作，与end成对使用
    case end // 结束场景事件：停止事件操作，移除场景事件handler，与start成对使用
    case immediately // 立即执行当前场景事件操作
}

public protocol SceneEventService {
    /// 处理场景事件
    /// - Parameters:
    ///   - trigger: 触发的场景操作，有start end 和immediately 4种
    ///   - context: 场景上下文
    func handleEvent(_ trigger: Trigger, context: SecurityPolicy.SceneContext)
}
