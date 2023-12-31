//
//  WorkplaceWidgetHost.swift
//  LarkOpenWorkplace
//
//  Created by ByteDance on 2023/6/2.
//

import Foundation

/// Widget 宿主操作协议
/// 主要通过 context 提供给组件调用
public protocol WorkplaceWidgetHost {
    associatedtype RenderType: WorkplaceWidgetHostRender
    /// 当前 widget 状态
    var state: WorkplaceWidgetState { get set }

    /// 当前渲染容器
    var render: RenderType { get }
    
    /// 宿主所在的 VC，主要是跳转场景使用，用于获取 from
    /// 实现时需要指定为 weak
    var hostVC: UIViewController? { get }

    /// 触发当前 Widget 实体重新加载，全部实体会被销毁重新创建
    func reload()

    /// 通知宿主渲染完成，仅做事件通知，宿主核心指标依赖。
    func reportLoadFinish()
}

/// Widget 宿主渲染操作协议。
/// 主要通过 context.render 提供给组件调用。
public protocol WorkplaceWidgetHostRender: AnyObject {
    /// 是否在宿主 VC 可视区域
    var isInViewPort: Bool { get }

    /// 触发当前 Widget 实体重新渲染，会重新进行布局计算。
    func refresh()
    
    /// 更新组件 header
    /// icon 类型待定
    func updateHeader(icon: String, title: String)

    /// 添加一个 header menu，key 作为 menu 的唯一标识，相同 key 的 menu 会被替换
    /// icon 类型待定
    /// 讨论：Block 自带的设置页等内容，也应该完全由业务感知后添加进来。
    func addHeaderMenu(key: String, title: String, icon: String)

    /// 删除一个 header menu
    func removeHeaderMenu(_ key: String)
}
