//
//  MenuItemImageModelProtocol.swift
//  LarkUIKitDemo
//
//  Created by 刘洋 on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

/// 为LarkMenu的Item提供图片
@objc
public protocol MenuItemImageModelProtocol {

    /// 根据Item处于的状态以及显示在哪种类型的面板中为Item返回合适的照片
    /// - Parameters:
    ///   - location: Item所处菜单面板的类型
    ///   - status: Item的状态
    func image(for location: MenuPanelType, status: UIControl.State) -> UIImage
}
