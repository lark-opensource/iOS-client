//
//  FocusEffectiveTime.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/11.
//

import Foundation
import RustPB
import LarkFocusInterface

// MARK: - i18n Display

extension FocusEffectiveTime {

    /// 显示时间：“至 XX:XX”，与 `validUntilTime` 只有文案不同
    func untilTime(is24Hour: Bool) -> String {
        if isOpenWithoutEndTime {
            // "无结束时间"
            return BundleI18n.LarkFocus.Lark_Core_SelectAStatusDuringFocus_NoEndingTime_Text
        }
        if !isShowEndTime {
            // ”至会议结束“
            return BundleI18n.LarkFocus.Lark_Profile_StatusEndTimeTillMeetingEnds_Option
        }
        let endDate = FocusUtils.shared.getRelatedLocalTime(asServer: endTime)
        let timeString = endDate.readableString(is24Hour: is24Hour)
        return BundleI18n.LarkFocus.Lark_Profile_UntilTime(timeString)
    }

    /// 显示时间：“持续至 XX:XX”，与 `untilTime` 只有文案不同
    /// NOTE: 之前的需求里文案不同，后来改为相同文案
    func validUntilTime(is24Hour: Bool) -> String {
        return untilTime(is24Hour: is24Hour)
    }

    /// 生效的状态，展示 “持续至 XX:XX”；未生效的状态，展示 “至 XX:XX”。
    func systemStatusTime(isActive: Bool, is24Hour: Bool) -> String {
        let endDate = FocusUtils.shared.getRelatedLocalTime(asServer: endTime)
        let timeString = endDate.readableString(is24Hour: is24Hour)
        if isActive {
            return BundleI18n.LarkFocus.Lark_Profile_LastUntilTime(timeString)
        } else {
            return BundleI18n.LarkFocus.Lark_Profile_UntilTime(timeString)
        }
    }
}

extension FocusEffectiveTime: CustomStringConvertible {

    public var description: String {
        return "[\(startTime) - \(isShowEndTime ? "\(endTime)" : "inf")]"
    }
}
