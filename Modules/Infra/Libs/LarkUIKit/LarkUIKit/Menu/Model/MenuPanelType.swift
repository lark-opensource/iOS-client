//
//  MenuPanelType.swift
//  LarkUIKitDemo
//
//  Created by 刘洋 on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// LarkMenu菜单的类型
@objc
public enum MenuPanelType: Int {

    /**
     iPhone从下往上滑出的面板类型
     */
    case iPhonePanel

    /**
     iPad上Popover方式弹出的面板类型
     */
    case iPadPopover

    /**
     iPhone上主导航菜单栏的面板类型
     */
    case iPhoneLark
}
