//
//  MenuIPadPanelCellViewModelProtocol.swift
//  LarkUIKit
//
//  Created by 刘洋 on 2021/2/2.
//

import Foundation
import UIKit
import LarkBadge

/// iPad菜单选项的视图模型
protocol MenuIPadPanelCellViewModelProtocol: MenuPanelCellCommonViewModelProtocol {

    /// 标题的字号
    var font: UIFont {get}

    /// 选项下是否应该存在一条分割线
    var isShowBorderLine: Bool {get set}

    /// 是否应该显示Badge
    var isShowBadge: Bool {get}
}
