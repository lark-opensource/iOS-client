//
//  FloatActionItem.swift
//  Calendar
//
//

import UIKit
import UniverseDesignIcon
import Foundation
import LarkUIKit

enum FloatActionType {
    case schedule
    case day
    case threeDay
    case month
    case setting
}

struct FloatActionItem {

    let icon: UIImage

    let title: String

    let type: FloatActionType

    var showBottomBorder: Bool
}

extension FloatActionType {

    var item: FloatActionItem {
        switch self {
        case .schedule:

            return FloatActionItem(icon: UDIcon.getIconByKeyNoLimitSize(.viewTaskOutlined).renderColor(with: .n2),
                                   title: BundleI18n.Calendar.Calendar_ListView_Schedule,
                                   type: .schedule,
                                   showBottomBorder: false)
        case .day:
            return FloatActionItem(icon: UDIcon.getIconByKeyNoLimitSize(.viewDayOutlined).renderColor(with: .n2).withRenderingMode(.alwaysOriginal),
                                   title: BundleI18n.Calendar.Calendar_DailyView_DailyView,
                                   type: .day,
                                   showBottomBorder: false)
        case .threeDay:
            return FloatActionItem(icon: UDIcon.getIconByKeyNoLimitSize(.view3dayOutlined).renderColor(with: .n2),
                                   title: Display.pad ? BundleI18n.Calendar.Calendar_WeekView_WeekView : BundleI18n.Calendar.Calendar_threeDaysView_3DayView,
                                   type: .threeDay,
                                   showBottomBorder: false)
        case .month:
            return FloatActionItem(icon: UDIcon.getIconByKeyNoLimitSize(.viewMonthOutlined).renderColor(with: .n2),
                                   title: BundleI18n.Calendar.Calendar_MonView_MonthlyView,
                                   type: .month,
                                   showBottomBorder: true)
        case .setting:
            return FloatActionItem(icon: UDIcon.getIconByKeyNoLimitSize(.settingOutlined).renderColor(with: .n2),
                                   title: BundleI18n.Calendar.Calendar_Setting_Settings,
                                   type: .setting,
                                   showBottomBorder: false)
        }
    }

}
