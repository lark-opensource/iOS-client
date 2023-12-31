//
//  AppCollectionCellPosition.swift
//  LarkWorkplace
//
//  Created by houjihu on 2021/1/7.
//

import Foundation

/// 标识应用相关单元格位置
enum AppCollectionCellPosition {
    /// section中间，此section有超过一个cell，默认值
    case middle
    /// section最上面，此section有超过一个cell
    case top
    /// section最下面，此section有超过一个cell
    case bottom
    /// section下只有一个cell
    case topAndBottom
}
