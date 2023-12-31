//
//  MenuPanelStyle.swift
//  LarkUIKitDemo
//
//  Created by 刘洋 on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// LarkMenu菜单的风格
@objc
public enum MenuPanelStyle: Int {

    /// 经典菜单风格
    ///
    /// 在iPhone上是从下往上弹出的面板
    ///
    /// 在iPad上是Popover弹出的面板
    case traditionalPanel

    /// Lark风格
    ///
    /// - Note: 仅会在iPhone设备的主导航模式下才会使用
    case larkPanel
}
