//
//  CalendarFeedCardTitleVM.swift
//  LarkFeedPlugin
//
//  Created by xiaruzhen on 2023/8/18.
//

import Foundation
import LarkOpenFeed
import LarkModel
import RustPB
import LarkFeedBase
import Calendar

// MARK: - ViewModel
final class CalendarFeedCardTitleVM: FeedCardTitleVM {
    // 组件类别
    var type: FeedCardComponentType {
        return .title
    }

    // VM 数据
    let title: String

    // 在子线程生成view data
    required init(feedPreview: FeedPreview) {
        guard let calendarSubtitleData = try? Feed_V1_CalendarSubtitle(serializedData: feedPreview.extraMeta.bizPb.extraData) else {
            self.title = BundleI18n.CalendarMod.Lark_Feed_EventCenter_EventTitle
            return
        }
        let calendarCount = calendarSubtitleData.calendarCount
        if calendarCount == 0 {

            self.title = BundleI18n.CalendarMod.Lark_Feed_EventCenter_EventTitle
        } else {
            if feedPreview.uiMeta.name.isEmpty {
                self.title = BundleI18n.CalendarMod.Calendar_Common_NoTitle
            } else {
                self.title = feedPreview.uiMeta.name
            }
        }
    }
}
