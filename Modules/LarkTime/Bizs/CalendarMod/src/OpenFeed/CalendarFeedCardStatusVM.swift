//
//  CalendarFeedCardStatusVM.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/8/18.
//

import Foundation
import LarkOpenFeed
import LarkModel
import UniverseDesignColor
import RustPB
import LarkFeedBase

// MARK: - ViewModel
class CalendarFeedCardStatusVM: FeedCardStatusVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .status
    }

    // VM 数据
    let statusData: FeedCardStatusData
    var isVisible: Bool = false
    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        guard let calendarSubtitleData = try? Feed_V1_CalendarSubtitle(serializedData: feedPreview.extraMeta.bizPb.extraData) else {
            // text = 空字符串，+ 不需要执行倒计时
            self.statusData = .default()
            return
        }
        switch calendarSubtitleData.calendarType {
        case .vcMeeting:
            // text = 进行中，+ 不需要倒计时
            let conf = FeedCardStatusConf(text: BundleI18n.CalendarMod.Lark_Event_EventInProgress_Status, color: .green)
            self.statusData = .desc(conf)
        case .calendar:
            if calendarSubtitleData.isAllDay {
                self.statusData = .default()
            } else if (calendarSubtitleData.startTime / 1000) != 0 && (calendarSubtitleData.endTime / 1000 != 0) {
                let minutes = 60
                let seconds = 60
                let timeInterval = minutes * seconds
                if var statusData = FeedCardStatusCountDownData(
                    startTime: Int(calendarSubtitleData.startTime / 1000),
                    endTime: Int(calendarSubtitleData.endTime / 1000),
                    advancedTime: timeInterval) {
                    statusData.isFlag = feedPreview.basicMeta.isFlaged
                    self.statusData = .countDownData(statusData)
                } else {
                    self.statusData = .default()
                }
            } else {
                self.statusData = .default()
            }
        case .unknownCalendar:
            self.statusData = .default()
        @unknown default:
            self.statusData = .default()
        }
    }

    func showOrHiddenView(isVisible: Bool) {
        self.isVisible = isVisible
    }
}
