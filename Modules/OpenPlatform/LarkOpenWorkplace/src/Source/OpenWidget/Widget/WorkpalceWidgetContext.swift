//
//  WorkpalceWidgetContext.swift
//  LarkOpenWorkplace
//
//  Created by ByteDance on 2023/6/2.
//

import Foundation
import LarkContainer
import ECOProbe

/// Widget
public struct WorkplaceWidgetContext {
    /// 用户维度 resolver
    public let resolver: UserResolver
    /// 宿主 trace
    public let trace: OPTrace
    /// 内存态强类型 KV 存储
    public let store: Store
    /// Widget 宿主容器
    public let host: any WorkplaceWidgetHost
    /// Widget 本次加载类型
    public let loadType: WorkplaceWidgetLoadType
    
    // write a function to draw a rectangle
    
    public init(
        resolver: UserResolver,
        trace: OPTrace,
        store: Store,
        host: any WorkplaceWidgetHost,
        loadType: WorkplaceWidgetLoadType
    ) {
        self.resolver = resolver
        self.trace = trace
        self.store = store
        self.host = host
        self.loadType = loadType
    }
    
}
