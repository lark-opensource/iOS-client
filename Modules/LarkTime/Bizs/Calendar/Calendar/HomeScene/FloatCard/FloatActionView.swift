//
//  FloatActionView.swift
//  Calendar
//
//  Created by zhuheng on 2021/5/26.
//

import UniverseDesignIcon
import Foundation
import SnapKit
import UniverseDesignColor
enum ActionItemType: Equatable {
    /// 切换视图
    case sceneMode(HomeSceneMode)
    /// 设置
    case setting

    static func == (lhs: Self, rhs: Self) -> Bool {
        if case .sceneMode(let lMode) = lhs, case .sceneMode(let rMode) = rhs {
            return lMode == rMode
        }
        if case .setting = lhs, case .setting = rhs {
            return true
        }
        return false
    }
}
