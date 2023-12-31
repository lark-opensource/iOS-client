//
//  GadgetNavigationStyle.swift
//  OPGadget
//
//  Created by 刘洋 on 2021/4/29.
//

import Foundation

/// 路由打开新页面的样式
public enum GadgetNavigationStyle {
    /// 在目标页面内部打开，现在包含showDetail和push方式
    case innerOpen
    /// 使用present模态打开
    case present
    /// 什么都不做，中断路由
    case none
}
