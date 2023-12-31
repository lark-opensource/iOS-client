//
//  FocusDurationType.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/11.
//

import Foundation
import RustPB

/// 个人状态时间配置（30分钟、1小时、2小时……）
///
/// ```
/// enum FocusDurationType: Int {
///     case minutes30      // 开启 30 分钟
///     case hour1          // 开启 1 小时
///     case hour2          // 开启 2 小时
///     case hour4          // 开启 4 小时
///     case untilTonight   // 开启至当晚
/// }
/// ```
public typealias FocusDurationType = RustPB.Contact_V1_UserCustomStatusDuration

public extension FocusDurationType {

    var displayName: String {
        switch self {
        case .minutes30:    return BundleI18n.LarkFocus.Lark_Profile_ThirtyMins
        case .hour1:        return BundleI18n.LarkFocus.Lark_Profile_AnHour
        case .hour2:        return BundleI18n.LarkFocus.Lark_Profile_TwoHours
        case .hour4:        return BundleI18n.LarkFocus.Lark_Profile_FourHours
        case .untilTonight: return BundleI18n.LarkFocus.Lark_Profile_UntilTonight
        @unknown default:   return BundleI18n.LarkFocus.Lark_Profile_UntilTonight
        }
    }
}
