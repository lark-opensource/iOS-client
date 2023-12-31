//
//  UDMenuConfig.swift
//  UniverseDesignMenu
//
//  Created by qsc on 2020/11/20.
//

import UIKit
import Foundation

/// Menu 展示的相对位置
public enum MenuPosition {
    ///自动，按以下规则决定 menu 显示位置
    /// * 显示空间足够的情况下，Menu 会显示在触发区域的底部，并保持居对齐。
    /// * 若底部空间不够且触发区域顶部空间大于底部空间，则会显示在触发区域顶部。
    /// * 若居中对齐时两侧空间不够，则会自动切换至左/右对齐。
    case auto
    /// Menu 处于起始 view 的上方，默认居中，边界空间不足是自动切换左右对齐
    case topAuto
    /// Menu 处于起始 view 的上方，并保持右侧对齐
    case topLeft
    /// Menu 处于起始 view 的上方，并保持右侧对齐
    case topRight
    /// Menu 处于起始 view 的下方，默认居中，边界空间不足是自动切换左右对齐
    case bottomAuto
    /// Menu 处于起始 view 的下方，并保持左侧对齐
    case bottomLeft
    /// Menu 处于起始 view 的下方，并保持右侧对齐
    case bottomRight
}

/// Menu 的参数配置，当前为显示位置的配置
public struct UDMenuConfig {

    /// Menu 的显示位置参数，默认为显示在起始 View 底部
    public let position: MenuPosition

    /// UDMenuConfig, 目前为手动配置 menu view 的大小
    /// - Parameter position: Menu 的显示位置配置项
    public init(position: MenuPosition = .auto) {
        self.position = position
    }

    public func getArrowDirection() -> UIPopoverArrowDirection {
        var arrowDirection: UIPopoverArrowDirection = .unknown
        switch position {
        case .auto:
            arrowDirection = .any
        case .bottomAuto, .bottomLeft, .bottomRight:
            arrowDirection = .up
        case .topAuto, .topLeft, .topRight:
            arrowDirection = .down
        default:
            break
        }
        return arrowDirection
    }
}
