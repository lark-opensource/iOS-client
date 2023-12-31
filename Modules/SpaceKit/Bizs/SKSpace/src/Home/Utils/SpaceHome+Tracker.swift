//
//  SpaceHome+Tracker.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/24.
//

import Foundation
import SKCommon

protocol SpaceTracker {
    var bizParameter: SpaceBizParameter { get }
}

extension SpaceTracker {
    // 用于快速定义 params 的类型
    typealias P = [String: Any]
}
