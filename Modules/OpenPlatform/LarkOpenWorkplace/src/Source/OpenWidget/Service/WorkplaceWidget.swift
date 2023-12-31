//
//  WorkplaceWidget.swift
//  LarkOpenWorkplace
//
//  Created by ByteDance on 2023/6/2.
//

import Foundation
import LarkContainer

/// 工作台组件注册入口
public final class WorkplaceWidget {
    public private(set) static var widgetTypeFactories: [WorkplaceWidgetType: (UserResolver) -> WorkplaceWidgetTypeService] = [:]
    
    /// 注册一个具体的 Widget 类型
    public static func register(_ widgetType: WorkplaceWidgetType, for typeServiceFactory: @escaping (UserResolver) -> WorkplaceWidgetTypeService) {
        #if DEBUG
        if widgetTypeFactories.keys.contains(widgetType) {
            assertionFailure("Workplace widget \(widgetType) has already been registered")
        }
        #endif
        widgetTypeFactories[widgetType] = typeServiceFactory
    }
}
