//
//  MenuIPhonePanelCellViewModelProtocol.swift
//  LarkUIKitDemo
//
//  Created by 刘洋 on 2021/1/28.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkBadge

/// iPhone菜单中选项的视图模型
protocol MenuIPhonePanelCellViewModelProtocol: MenuPanelCellCommonViewModelProtocol {
    /// 根据文字区域大小获取文字的字号
    /// - Parameters:
    ///   - size: 文字区域的大小
    ///   - lineHeight: 文字的行高
    func font(for size: CGSize, lineHeight: CGFloat) -> UIFont
}
