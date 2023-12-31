//
//  MeetTabUpcomingCellViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/6.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import ByteViewNetwork

class MeetTabUpcomingCellViewModel: MeetTabCellViewModel {

    override var sortKey: Int64 {
        return Int64(index)
    }

    override var cellIdentifier: String {
        return MeetTabHistoryDataSource.upcomingCellIdentifier
    }

    override var matchKey: String {
        return "\(eventID)_\(instance.startTime)"
    }

    var timing: String {
        DateUtil.formatDateTimeRange(startTime: TimeInterval(instance.startTime), endTime: TimeInterval(instance.endTime))
    }

    private var currentTime: Int64 {
        return Int64(Date().timeIntervalSince1970)
    }

    var reminderTiming: String {
        let startTime = self.instance.startTime
        let endTime = self.instance.endTime
        let currentTime = self.currentTime
        if currentTime < startTime {
            let minutes: Double = Double((startTime - currentTime)) / 60.0
            if minutes > 15.0 {
                return ""
            } else {
                return I18n.View_MV_HowManyMinutesLater(Int(ceil(minutes)))
            }
        } else if currentTime >= startTime && currentTime <= endTime {
            return I18n.View_MV_RightNowTime
        } else {
            return ""
        }
    }

    var reminderTimingDriver: Driver<String> {
        return Self.timer
            .filter { [weak self] _ in
                return self != nil
            }.map { [weak self] _ in
                guard let self = self else { return "" }
                return self.reminderTiming
            }
    }

    var eventID: String {
        instance.uniqueID
    }

    var topic: String {
        if instance.summary.isEmpty {
            return I18n.View_G_ServerNoTitle
        } else {
            return instance.summary
        }
    }

    var meetingNumber: String {
        return "\(I18n.View_MV_IdentificationNo): \(Util.formatMeetingNumber(instance.meetingNumber))"
    }

    var meetingTagType: MeetingTagType {
        Logger.tab.info("meetingTagType for upcoming: \(String(describing: instance.relationTag)), meetingNumber: \(instance.meetingNumber)")
        if let tagDataItems = instance.relationTag?.tagDataItems,
           let item = tagDataItems.first(where: { $0.tagItemType == .relationTag }),
           let tagText = item.textVal {
            return .partner(tagText)
        }

        if isExternal {
            return .external
        }

        return .none
    }

    var isExternal: Bool {
        guard account.tenantTag == .standard else {
            // 小B用户不显示外部标签
            return true
        }
        return instance.isCrossTenant
    }

    var isWebinar: Bool {
        instance.category == .webinar
    }

    let index: Int
    let instance: TabUpcomingInstance
    let viewModel: MeetTabViewModel
    var account: AccountInfo { viewModel.account }

    init(viewModel: MeetTabViewModel, index: Int, instance: TabUpcomingInstance) {
        self.viewModel = viewModel
        self.index = index
        self.instance = instance
        super.init()
    }
}
