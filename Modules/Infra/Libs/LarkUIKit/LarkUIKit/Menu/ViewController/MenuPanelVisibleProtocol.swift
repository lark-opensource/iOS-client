//
//  MenuPanelVisibleProtocol.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/3/18.
//

import Foundation

/// 遵循此协议的视图可以进行显示与隐藏的操作
protocol MenuPanelVisibleProtocol {
    /// 菜单面板隐藏，调用此方法后，菜单面板隐藏
    func hide(animation: Bool, duration: Double, complete: ((Bool) -> Void)?)

    /// 菜单面板显示，调用此方法后，菜单面板显示
    func show(animation: Bool, duration: Double, complete: ((Bool) -> Void)?)
}
