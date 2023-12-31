//
//  SearchEntity.swift
//  Calendar
//
//  Created by zoujiayi on 2019/8/18.
//
import RustPB
import Foundation
import CalendarFoundation
import LarkTimeFormatUtils

protocol CalendarSearchContent {
    var calendarID: String { get }
    var key: String { get }
    var originalTime: Int64 { get }

    var summary: String { get }
    var attendee: String { get }
    var location: String { get }
    var desc: String { get }
    var eventHighLight: HighlightTexts { get }
    var selfAttendeeStatus: CalendarEventAttendee.Status { get }
    var eventColorIndex: ColorIndex { get }
    var calendarColorIndex: ColorIndex { get }
    var isAllday: Bool { get }
    var calendarType: RustPB.Calendar_V1_Calendar.TypeEnum { get }
    var isCrossTenant: Bool { get }
}

extension CalendarSearchContent {
    func haveExtraInfo() -> Bool {
        return !desc.isEmpty || !attendee.isEmpty
    }
}

struct CalendarSearchInstance {
    var startTimeForInstance: Int64
    var endTimeForInstance: Int64
    var startTime: Int64
    var endTime: Int64
    var currentDayCount: Int
    var totalDayCount: Int
}

struct SerachEntity: CalendarSearchContent {

    var calendarType: RustPB.Calendar_V1_Calendar.TypeEnum {
        return content.calendarType
    }

    var isCrossTenant: Bool {
        return content.isAllDay
    }

    var calendarID: String {
        return content.calendarID
    }

    var key: String {
        return content.key
    }

    var originalTime: Int64 {
        return content.originalTime
    }

    var summary: String {
        return content.summary
    }

    var attendee: String {
        if !content.organizer.isEmpty {
            return BundleI18n.Calendar.Calendar_Detail_Organizer + ": " + content.organizer
        }
        if !content.creator.isEmpty {
            return BundleI18n.Calendar.Calendar_Detail_Creator + ":" + content.creator
        }
        if !content.attendee.isEmpty {
            return BundleI18n.Calendar.Calendar_Common_Includes(itemName: content.attendee)
        }
        return ""
    }

    var organizer: String {
        return content.organizer
    }

    var resource: String {
        return content.resource
    }

    var location: String {
        if !content.resource.isEmpty {
            return content.resource
        }
        return content.location
    }

    var desc: String {
        return content.description_p
    }

    var eventHighLight: HighlightTexts {
        var texts = HighlightTexts()
        for highlight in content.eventHighlights {
            switch highlight.tag {
            case .unknownEventHighlightTag:
                assertionFailureLog()
            case .attendee:
                texts[.attendee] = highlight.highlights
            case .chat:
                texts[.chat] = highlight.highlights
            case .description_:
                texts[.desc] = highlight.highlights
            case .location:
                texts[.location] = highlight.highlights
            case .meetingRoom:
                texts[.meetingRoom] = highlight.highlights
            case .summary:
                texts[.title] = highlight.highlights
            @unknown default: break
            }
        }
        return texts
    }

    var selfAttendeeStatus: CalendarEventAttendee.Status {
        return content.selfAttendeeStatus
    }

    var eventColorIndex: ColorIndex {
        return content.colorIndex.isNoneColor ? content.calColorIndex : content.colorIndex
    }

    var calendarColorIndex: ColorIndex {
        return content.calColorIndex
    }

    var isAllday: Bool {
        return content.isAllDay
    }

    private var content: SearchCalendarEventContent

    init(content: SearchCalendarEventContent) {
        self.content = content
    }
}

public protocol CalendarGeneralSearchContent {
    var calendarId: String { get }
    var eventKey: String { get }
    var originalTime: Int64 { get }
    var title: String { get }
    var subtitle: String { get }
    var isLarkEvent: Bool { get }
    var startTime: Int64 { get }
    var endTime: Int64 { get }
    var titleHitTerms: [String] { get }
    var subtitleHitTerms: [String] { get }
    var timeDisplay: String { get }
}

struct CalendarGeneralSearchEntity: CalendarGeneralSearchContent {
    var searchContent: SearchCalendarEventContent
    var is12Hour: Bool
    var startTime: Int64
    var endTime: Int64

    var calendarId: String {
        return searchContent.calendarID
    }
    var eventKey: String {
        return searchContent.key
    }
    var originalTime: Int64 {
        return searchContent.originalTime
    }
    var title: String {
        return searchContent.summary.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : searchContent.summary
    }
    var subtitle: String {
        if !searchContent.organizer.isEmpty {
            return BundleI18n.Calendar.Calendar_Detail_Organizer + ": " + searchContent.organizer
        } else {
            return BundleI18n.Calendar.Calendar_Detail_Creator + ": " + searchContent.creator
        }
    }
    var isLarkEvent: Bool {
        return !(searchContent.calendarType == RustPB.Calendar_V1_Calendar.TypeEnum.google)
    }
    var titleHitTerms: [String] {
        let hitTerms = searchContent.eventHighlights.filter { $0.tag == RustPB.Calendar_V1_EventHighLight.Tag.summary }
        if !hitTerms.isEmpty {
            return hitTerms[0].highlights
        } else {
            return [String]()
        }
    }
    var subtitleHitTerms: [String] {
        let hitTerms = searchContent.eventHighlights.filter { $0.tag == RustPB.Calendar_V1_EventHighLight.Tag.attendee }
        if !hitTerms.isEmpty {
            return hitTerms[0].highlights
        } else {
            return [String]()
        }
    }
    var timeDisplay: String {
        let customOptions = Options(
            is12HourStyle: is12Hour,
            timeFormatType: .short,
            timePrecisionType: .minute,
            datePrecisionType: .day
        )

        return CalendarTimeFormatter.formatDate(
            from: getDateFromInt64(startTime),
            accordingTo: searchContent.isAllDay,
            with: customOptions
        )
    }

    init(startTime: Int64,
         endTime: Int64,
         searchContent: SearchCalendarEventContent,
         is12Hour: Bool) {
        self.startTime = startTime
        self.endTime = endTime
        self.searchContent = searchContent
        self.is12Hour = is12Hour
    }
}
