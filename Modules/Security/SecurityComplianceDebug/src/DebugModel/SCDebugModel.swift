//
//  SCDebugModel.swift
//  LarkSecurityComplianceInfra
//
//  Created by qingchun on 2022/9/6.
//

import Foundation
import LarkSecurityComplianceInfra

// 单元格标题、子标题、类型、不同类型的handler
public struct SCDebugModel {
    public let cellTitle: String
    public let cellSubtitle: String
    public let cellType: DebugCellType
    public let normalHandler: (() -> Void)?
    public let switchHandler: ((Bool) -> Void)?
    public let isSwitchButtonOn: Bool

    // 构造器，title为必选参数，其余参数有默认实现，根据不同类型使用相关参数
    public init(cellTitle: String,
                cellSubtitle: String = "",
                cellType: DebugCellType = .normal,
                isSwitchButtonOn: Bool = false,
                normalHandler: (() -> Void)? = nil,
                switchHandler: ((Bool) -> Void)? = nil) {
        self.cellTitle = cellTitle
        self.cellSubtitle = cellSubtitle
        self.cellType = cellType
        self.normalHandler = normalHandler
        self.switchHandler = switchHandler
        self.isSwitchButtonOn = isSwitchButtonOn
    }

    // 调用对应的handler方法
    public func handleClick() {
        switch cellType {
        case .normal:
            normalHandler?()
        default:
            break
        }
    }

    // 单元格类型枚举
    public enum DebugCellType {
        case normal
        case switchButton
        case subtitle
    }
}

