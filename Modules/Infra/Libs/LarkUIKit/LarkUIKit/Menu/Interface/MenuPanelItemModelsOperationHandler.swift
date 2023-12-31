//
//  MenuPanelItemModelsOperationHandler.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/30.
//

import Foundation

@objc
/// 菜单面板的数据模型更新句柄
public protocol MenuPanelItemModelsOperationHandler {
    /// 更新选项视图，如果更新的选项ID不存在，那么会追加更新，如果存在，则会覆盖更新
    /// - Parameter models: 需要更新的选项数据模型
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担。
    ///         如果插件提供了数据模型，但是插件之后又被销毁了，它所产生的数据模型会依然保留，直至菜单触发dealloc事件，
    ///         数据模型才会被清除
    func updateItemModels(for models: [MenuItemModelProtocol])

    /// 更新选项视图，此操作会全部覆盖现在所有的数据模型，包括插件已经返回的数据模型，这相当于给外界一个重新自定义数据模型的机会
    /// - Parameter models: 需要更新的选项数据模型
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担。
    ///         如果插件提供了数据模型，但是插件之后又被销毁了，它所产生的数据模型会依然保留，直至菜单触发dealloc事件，
    ///         数据模型才会被清除
    func resetItemModels(with models: [MenuItemModelProtocol])

    /// 更新选项视图,此操作会将数据模型从视图中移除
    /// - Parameter modelIDs: 需要移除的数据模型ID
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担。
    func removeItemModels(for modelIDs: [String])

    /// 禁用或者启用现在的所有的选项
    /// - Parameter with: `true` 禁用 `fasle` 启用
    /// - Note: 注意必须在主线程执行。如果你一不小心在其他线程执行，则不会被执行，会触发assert，
    ///         因此会发生一些其他奇怪的问题，责任需要自己承担。
    func disableCurrentAllItemModels(with: Bool)
}
