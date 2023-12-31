//
//  ArrangementFreeBusyTextUtil.swift
//  Calendar
//
//  Created by Rico on 2022/4/19.
//

import Foundation
import UniverseDesignColor
import UIKit

// 忙闲页底部提示文案  for  未回复/待定需求 新抽象
struct ArrangementFreeBusyTextUtil {

    static let allFreeColor = UDColor.primaryContentDefault
    static let allBusyColor = UDColor.functionDangerContentDefault

    static func textColor(with attendeeFreeBusy: AttendeeFreeBusyInfo) -> UIColor {
        if attendeeFreeBusy.isAllFree { return allFreeColor }
        if attendeeFreeBusy.isAllBusy { return allBusyColor }
        return UDColor.textPlaceholder
    }

    // 有工作时间交集的文案
    static func textOnWorkingHour(with attendeeFreeBusy: AttendeeFreeBusyInfo) -> String {
        let info = attendeeFreeBusy
        let text = I18n.Calendar_MV_StatusThreeOptions(count: info.totalCount, countOne: info.freeAttendees.count, countTwo: info.maybeFreeAttendees.count)
        return text
    }

    // 无工作时间交集的文案
    static func textWithoutWorkingHour(with attendeeFreeBusy: AttendeeFreeBusyInfo) -> String {
        let info = attendeeFreeBusy
        if info.isAllFree {
            return I18n.Calendar_Edit_AllFree
        }
        if info.isAllBusy {
            return I18n.Calendar_Edit_AllBusy
        }

        if info.maybeFreeAttendees.isEmpty,
           info.busyAttendees.count <= 2,
           !info.busyAttendees.isEmpty,
           info.totalCount >= 5 {
            // 除了xxx都有空
            var names = info.busyAttendees[safeIndex: 0]?.name ?? ""
            if info.busyAttendees.count > 1,
               let second = info.busyAttendees[safeIndex: 1] {
                names += "\(I18n.Calendar_Common_Comma)\(second.name)"
            }
            return I18n.Calendar_Edit_MinorityBusy(content: names)
        }
        return I18n.Calendar_MV_EventDescription_GreyText(count: info.totalCount,
                                                          countOne: info.freeAttendees.count,
                                                          countTwo: info.maybeFreeAttendees.count)
    }

}
