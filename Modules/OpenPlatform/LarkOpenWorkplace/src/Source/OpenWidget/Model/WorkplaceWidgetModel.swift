//
//  WorkplaceWidgetModel.swift
//  LarkOpenWorkplace
//
//  Created by ByteDance on 2023/6/2.
//

import Foundation

/// widget 初始化数据结构
public struct WorkplaceWidgetModel {
    /// 工作台组件 id
    public let itemId: String
    
    /// 其他透传数据
    /// 可能需要 config（包含管理员配置的标题跳转链接等），后端数据链路 Schema 确认后填充。
    
    /// Block 依赖待抽象讨论
    
    public init(itemId: String) {
        self.itemId = itemId
    }
}
