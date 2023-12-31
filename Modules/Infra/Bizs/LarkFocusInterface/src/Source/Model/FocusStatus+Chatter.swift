//
//  ChatterFocusStatus.swift
//  EEAtomic
//
//  Created by Hayden Wang on 2021/9/8.
//

import Foundation
import RustPB
import UIKit
import LarkFoundation
import LarkFocusInterface

/// Chatter 的个人状态
///
/// ```
/// struct ChatterFocusStatus {
///     var title: String
///     var iconKey: String
///     var isNotDisturbMode: Bool
///     var effectiveInterval: FocusEffectiveTime
///     var statusID: Int
/// }
/// ```
public typealias ChatterFocusStatus = RustPB.Basic_V1_Chatter.ChatterCustomStatus

public extension ChatterFocusStatus {

    var isActive: Bool {
        // 判断生效时间段的格式是否合法
        guard effectiveInterval.isValid else { return false }
        // 判断当前时间是否属于生效时间段
        let curTime = FocusUtils.shared.currentServerTime
        return curTime >= effectiveInterval.startTime
            && curTime <= effectiveInterval.endTime
    }
}

public extension Array where Element == ChatterFocusStatus {

    var topActive: ChatterFocusStatus? {
        self.filter({ $0.isActive }).first
    }

    var simplifiedDescription: String {
        return "[\(self.map({ $0.title.desensitized() + ($0.isActive ? "(Active)" : "") }).joined(separator: ","))]"
    }
}

// 遵循 FocusStatus 协议，实现 Chatter / User 通用
extension ChatterFocusStatus: FocusStatus {}

// MARK: - Debug Description

extension ChatterFocusStatus: CustomStringConvertible {

    public var description: String {
        return "<\(title.desensitized()), isActive: \(isActive), time: \(effectiveInterval), silent: \(isNotDisturbMode)>"
    }
}
