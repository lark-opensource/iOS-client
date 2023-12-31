//
//  WorkplaceWidgetTypeService.swift
//  LarkOpenWorkplace
//
//  Created by ByteDance on 2023/6/2.
//

import Foundation
import LarkContainer

/// Widget 类型服务协议，Widget 类型相关的配置和初始化在此协议实现，工作台持有。
/// 主要包含 Widget 实体无关的业务逻辑。
///
/// 调用顺序及时机
///            (internal)Workplace init 工作台初始化
///                   ↓
///      (internal)WorkplaceWidgetLoad 工作台 Widget 类型初始化
///                   ↓
///                 enable   → (false) →  end
///                   ↓
///                 (true)
///.                  ↓
///                setup() 业务初始设置
///                   ↓
///     （internal）Workplace preload 工作台数据预加载
///                   ↓
///            preload(widgets:) 业务预加载 Widgets
///                   ↓
///     （internal）Workplace portal load 工作台门户加载
///                   ↓
///          forEach canLoad(_:) →  (false) → end
///                   ↓
///                 (true)
///                   ↓
///          createViewModel(_:context:) 创建 Widget 实体
///                   ↓
///            ViewModel lifecycle
///
public protocol WorkplaceWidgetTypeService: AnyObject {
    /// 组件类型，一般业务根据类型写死即可
    static var type: WorkplaceWidgetType { get }
    
    /// 组件类型总开关，返回 false 不会运行/加载任何此类型组件的逻辑，包括预加载，默认返回 true
    /// 业务整体 FG/Settings 配置可以收敛至此
    var enable: Bool { get }
    
    /// 业务初始化
    init(resolver: UserResolver)
    
    /// 组件类型实体初始化入口，一般用于初始化组件实体无关的业务内容，提供默认空实现。
    func setup()

    /// 批量预加载接口, 默认提供空实现。
    /// 由于工作台场景是多门户，工作台会根据业务需要可能调用多次。
    /// widgets 顺序目前不做保证。
    func preload(widgets: [WorkplaceWidgetModel])
    
    /// 组件实体开关，返回 false 不会加载此实体，UI 容器上也不会有此实体组件，默认返回 true
    /// 批量预加载 preload(widgets:) 不受此影响。
    ///
    /// 比如一共 10 个此类型的 Widget 组件，2 个返回了 false，工作他最终 UI 上只会有 8 个。
    func canLoad(_ widget: WorkplaceWidgetModel) -> Bool
    
    /// 创建组件实体 ViewModel
    func createViewModel(_ widget: WorkplaceWidgetModel, context: WorkplaceWidgetContext) -> WorkplaceWidgetViewModel
}

/// 默认实现，业务暂时不用关心。
extension WorkplaceWidgetTypeService {
    var enable: Bool { return true }

    static func setup() {}
    func setup() {}
    
    func canLoad(_ widget: [WorkplaceWidgetModel]) -> Bool {
        return true
    }
    
    func preload(widgets: [WorkplaceWidgetModel]) {}
}
