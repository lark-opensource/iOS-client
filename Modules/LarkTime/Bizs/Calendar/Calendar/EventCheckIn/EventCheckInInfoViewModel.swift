//
//  EventCheckInInfoViewModel.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/19.
//

import UIKit
import Foundation
import LarkContainer
import RxSwift
import ServerPB
import UniverseDesignFont
import UniverseDesignColor

class EventCheckInInfoViewModel: UserResolverWrapper {

    let userResolver: UserResolver

    @ScopedInjectedLazy var rustApi: CalendarRustAPI?

    enum Tab: Int {
        case link = 0
        case qrcode
        case stats

        var description: String {
            switch self {
            case .link: return I18n.Calendar_Bot_CheckInLink
            case .qrcode: return I18n.Calendar_Event_CheckInQRCode
            case .stats: return I18n.Calendar_Event_CheckInStatistics
            }
        }
    }

    private let calendarID: Int64
    let key: String
    let originalTime: Int64
    let startTime: Int64
    let defaultSelectedTab: Tab

    let tabs: [Tab] = [.link, .qrcode, .stats]

    init(userResolver: UserResolver,
         calendarID: Int64,
         key: String,
         originalTime: Int64,
         startTime: Int64,
         defaultTab: Tab = .link) {
        self.userResolver = userResolver
        self.calendarID = calendarID
        self.key = key
        self.originalTime = originalTime
        self.startTime = startTime
        self.defaultSelectedTab = defaultTab
    }

    func getEventCheckInInfo(condition: [CalendarRustAPI.CheckInInfoCondition]) -> Observable<ServerPB_Calendarevents_GetEventCheckInInfoResponse> {
        return rustApi?.getEventCheckInInfo(calendarID: calendarID,
                                           key: key,
                                           originalTime: originalTime,
                                           startTime: startTime,
                                            condition: condition) ?? .empty()
    }
}

extension ServerPB_Calendarevents_GetEventCheckInInfoResponse {
    private func makeAttributedString(title: String, content: String, axis: NSLayoutConstraint.Axis = .horizontal) -> NSMutableAttributedString {
        let titleAttributedString = NSMutableAttributedString(string: title, attributes: [.font: UDFont.body2, .foregroundColor: UDColor.textCaption])

        let contentAttributedString = NSMutableAttributedString(string: content, attributes: [.font: UDFont.body2, .foregroundColor: UDColor.textTitle])

        switch axis {
        case .vertical:
            titleAttributedString.append(NSAttributedString(string: "\n"))
            titleAttributedString.append(contentAttributedString)
        case .horizontal:
            titleAttributedString.append(contentAttributedString)
        }

        return titleAttributedString
    }

    func generateAttributeString() -> NSAttributedString {
        let attributedText: NSMutableAttributedString = self.makeAttributedString(title: I18n.Calendar_Bot_TimeToCheckIn, content: self.checkInURL, axis: .vertical)
        attributedText.append(NSAttributedString(string: "\n\n"))
        attributedText.append(self.makeAttributedString(title: I18n.Calendar_Detail_EventInfo, content: ""))
        attributedText.append(NSAttributedString(string: "\n"))
        attributedText.append(self.makeAttributedString(title: "\(I18n.Calendar_Bot_SubjectColon) ", content: self.eventSummary))
        attributedText.append(NSAttributedString(string: "\n"))
        attributedText.append(self.makeAttributedString(title: I18n.Calendar_Bot_EventTime, content: self.eventTime))
        attributedText.append(NSAttributedString(string: "\n"))
        if !self.rrule.isEmpty {
            attributedText.append(self.makeAttributedString(title: I18n.Calendar_Bot_RecurringRule, content: self.rrule))
            attributedText.append(NSAttributedString(string: "\n"))
        }
        attributedText.append(self.makeAttributedString(title: I18n.Calendar_Bot_Organizer, content: self.organizerName))

        let pargraphStyle = NSMutableParagraphStyle()
        pargraphStyle.lineSpacing = 4

        attributedText.addAttribute(.paragraphStyle, value: pargraphStyle, range: NSRange(location: 0, length: attributedText.length))

        return attributedText
    }
}
