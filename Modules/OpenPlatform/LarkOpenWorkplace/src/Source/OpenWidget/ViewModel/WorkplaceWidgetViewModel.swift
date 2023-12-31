//
//  WorkplaceWidgetViewModel.swift
//  LarkOpenWorkplace
//
//  Created by ByteDance on 2023/6/5.
//

import Foundation
import UIKit

/// Widget 业务实体的核心实现协议，工作台持有。
///
/// WidgetViewModel 的调用过程及时机：
///   WorkplaceWidgetTypeService createViewModel(_:context:) 创建 Widget 实体
///                    ↓
///            (internal) Widget 容器初始化
///                    ↓
///         createView(_:) 创建 Widget 业务 View
///                    ↓
///            bindView(_:) 绑定 View 事件
///                    ↓
///             sizeToFit(_:) 布局
///                    ↓
///               willDisplay()
///                    ↓
///               Widget 业务逻辑     → update context.host.state (状态刷新）
///                    ↓
///              didEndDisplay()
///                    ↓
///       (internal) Widget 组件 UI 重用
///                    ↓
///                onReuse() 重用上下文处理
///                    ↓
///             bindView(_:) 绑定 View 事件
///                    ↓
///               sizeToFit(_:) 布局
///                    ↓
///              willDisplay()
///                    ↓
///                   ...
///
public typealias WorkplaceWidgetViewModel = WorkplaceWidgetBaseViewModel & WorkplaceWidgetRenderAble

/// Widget 基类 ViewModel，逻辑部分收敛在此类型。
/// UI 渲染部分收敛在子类
open class WorkplaceWidgetBaseViewModel {
    // Widget 初始化信息（宿主提供）
    public private(set) var model: WorkplaceWidgetModel
    
    // Widget 上下文（宿主提供）
    public private(set) var context: WorkplaceWidgetContext
    
    // 重用标识
    // TODO: 待讨论，应该由宿主直接提供？
    open var reuseIdentifier: String {
        assertionFailure("must override")
        return String(UInt(bitPattern: ObjectIdentifier(self)))
    }
    
    /// 初始化方法
    public init(model: WorkplaceWidgetModel, context: WorkplaceWidgetContext) {
        self.model = model
        self.context = context
    }
    
    /// Widget 在门户复用，Widget 业务侧实体不需要关心，实现 onReuse 即可。
    public func reload(model: WorkplaceWidgetModel, context: WorkplaceWidgetContext) {
        self.model = model
        self.context = context
        self.onReuse()
    }
    
    /// 生命周期 - 发生 UI 重用时，组件做上下文处理
    open func onReuse() {}
    /// 生命周期 - 组件 UI 由不可见变为可见。
    ///    - 滚动情况：从不可见滚动到可视区域。
    ///    - 页面切换情况: 工作台门户页面切入时，门户可视区域内的组件触发。
    open func willDisplay() {}
    /// 生命周期 - 组件 UI 由可见变为不可见。
    ///    - 滚动情况：从可见区域滚动到不可见区域。
    ///    - 页面切换情况：工作台门户页面切出时，门户可视区域内的组件触发。
    open func didEndDisplay() {}
    
    /// 标题部分被点击
    open func onHeaderClick() {}
    /// 菜单项被点击
    open func onMenuClick(_ key: String) {}
}

/// 业务方需要继承实现的 ViewModel。
/// 继承自 BaseViewModel，此 ViewModel 包含了渲染能力。
open class WorkplaceWidgetContentViewModel<U: UIView>: WorkplaceWidgetBaseViewModel {
    /// 业务组件创建 view 入口，创建后宿主会在合适时机添加到容器上。
    /// 注意：
    ///  * 工作台内部逻辑弱引用 View， View 被宿主 View 强持有。
    ///  * 如果 UI 本身时轻量的，Widget 业务默认也不需要强持有此 View，依赖 subView 天然的持有关系即可，在重用时销毁重新创建。
    ///  * 如果业务需要复用 View，避免重复创建，则需要自行管理此 View 的强持有和重用，此时业务需要处理好 UI 事件的解绑。
    open func create(_ size: CGSize) -> U {
        return U(frame: CGRect(origin: .zero, size: size))
    }
    
    /// 绑定 UI 事件，创建 View 后，宿主会在渲染前调用此接口，业务可以在此接口内绑定 UI 相关事件。
    /// 注意
    /// * 如果发生 View reuse，此方法也会在重用后调用，业务需要重新绑定 UI 事件。
    /// * 业务如果有自定义 header 和 menu 的部分，也应当在此方法内添加绑定。
    open func bindView(_ view: U) {}

    /// 业务通过此接口与宿主协商布局尺寸。
    /// 注意：
    ///   * 初始状态，工作台宿主会根据解析的工作台模版配置初始化（高度+容器宽度）。
    ///   * 业务如果不需要自己布局，只依赖宿主，直接使用默认实现即可。
    ///   * 业务如果需要协商布局，则在宿主调用时，根据提供的容器宽度计算自己当前的高度，并返回新的 size。
    open func sizeToFit(_ size: CGSize) -> CGSize { return size }
}

/// 组件渲染抽象，解偶 View 范型和 ViewModel 协议。
/// 工作台实现层关心，组件接入基本不需要关心。
public protocol WorkplaceWidgetRenderAble: AnyObject {
    func createView(_ size: CGSize) -> UIView
    func updateView(_ view: UIView)
    func sizeToFit(_ size: CGSize) -> CGSize
}

extension WorkplaceWidgetContentViewModel: WorkplaceWidgetRenderAble {
    public func createView(_ size: CGSize) -> UIView {
        return self.create(size)
    }
    
    public func updateView(_ view: UIView) {
        guard let view = view as? U else { return }
        self.bindView(view)
    }
}
