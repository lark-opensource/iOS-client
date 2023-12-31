//
//  MenuPanelDataUpdaterProtocol.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/19.
//

import Foundation

/// 遵循此协议的菜单面板可以支持视图更新
protocol MenuPanelDataUpdaterProtocol {
    /// 更新菜单的头部
    /// - Parameter view: 菜单的头部视图
    func updatePanelHeader(for view: MenuAdditionView?)

    /// 更新菜单的底部
    /// - Parameter view: 菜单的底部视图
    func updatePanelFooter(for view: MenuAdditionView?)

    /// 更新菜单的选项
    /// - Parameter models: 菜单的选项数据模型
    func updateItemModels(for models: [MenuItemModelProtocol])
}
