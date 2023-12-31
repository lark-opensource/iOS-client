//
//  MenuPanelDelegate.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/1.
//

import Foundation

@objc
/// 菜单面板弹出和消失的代理方法
public protocol MenuPanelDelegate {
    /// 菜单面板出现前的执行的代理方法
    @objc optional func menuPanelWillShow()

    /// 菜单面板出现后的执行的代理方法
    @objc optional func menuPanelDidShow()

    /// 菜单面板消失前的执行的代理方法
    @objc optional func menuPanelWillHide()

    /// 菜单面板消失后的执行的代理方法
    @objc optional func menuPanelDidHide()

    /// 菜单面板中item点击事件
    @objc optional func menuPanelItemDidClick(identifier: String?, model: MenuItemModelProtocol?)

    /// 菜单面板收到了新的数据模型后通知代理的方法
    /// - Parameter new: 新的数据模型
    @objc optional func menuPanelItemModelsDidChanged(models: [MenuItemModelProtocol])

    /// 菜单头 header 更新
    @objc optional func menuPanelHeaderDidChanged(view: MenuAdditionView?)

    /// 菜单头 footer 更新
    @objc optional func menuPanelFooterDidChanged(view: MenuAdditionView?)
}
