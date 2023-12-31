//
//  FocusEffectiveTime.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/11.
//

import Foundation
import RustPB
import LarkFocusInterface

/// 个人状态的生效时间段（具体开启时间）
///
/// ```
/// struct FocusEffectiveTime {
///     var startTime: Int64    // 开始时间（s）
///     var endTime: Int64      // 结束时间（s）
///     var isShowEndTime: Bool // 如果为false 状态上不展示开始至xxx时间
/// }
/// ```

public typealias FocusEffectiveTime = Basic_V1_StatusEffectiveInterval

public extension FocusEffectiveTime {

    /// 状态的开启时间是否有效
    var isValid: Bool {
        guard startTime != 0, endTime != 0, startTime < endTime else {
            return false
        }
        return true
    }

    /// 是否在生效期间
    var isActive: Bool {
        // 判断生效时间段的格式是否合法
        guard isValid else { return false }
        // 判断当前时间是否属于生效时间段
        let curTime = FocusUtils.shared.currentServerTime
        return curTime >= startTime && curTime <= endTime
    }

    static func fromNow(totalSeconds: TimeInterval) -> FocusEffectiveTime {
        let currentServerTime: Int64 = 0
        var effectiveTime = FocusEffectiveTime()
        effectiveTime.startTime = currentServerTime
        effectiveTime.endTime = currentServerTime + Int64(totalSeconds)
        return effectiveTime
    }

    static var close: FocusEffectiveTime {
        return FocusEffectiveTime()
    }
}
