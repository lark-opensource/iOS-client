//
//  EventRSVPModelImpl.swift
//  Calendar
//
//  Created by pluto on 2023/1/18.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkContainer
import LarkModel
import RustPB

struct EventRSVPModelImpl: RSVPCardModel {    
        
    var content: GeneralCalendarEventRSVPContent
    let message: LarkModel.Message
    let primaryCalendarID: String?

    init(content: GeneralCalendarEventRSVPContent,
         message: LarkModel.Message,
         primaryCalendarID: String?) {
        self.content = content
        self.message = message
        self.primaryCalendarID = primaryCalendarID
    }

    var messageId: String { return "\(message.id)" }
        
    var chatID: String { return "\(content.chatID)" }
    
    var hasReaction: Bool { return !message.reactions.isEmpty }

    var calendarID: String { return primaryCalendarID ?? "" }
    
    var organizerCalendarId: Int64 { return content.organizerCalendarId }

    var key: String { return content.key }

    var originalTime: Int { return content.originalTime }
    
    var headerTitle: String {
        let title: String = content.title.isEmpty ? BundleI18n.Calendar.Calendar_Common_NoTitle : content.title
        if content.cardStatus == .updated { return title }
        if isInValid { return I18n.Calendar_G_CanceledEvent(event: title) }
        if !isJoined { return title }
        
        switch selfAttendeeRsvpStatus {
        case .accept, .decline, .tentative, .removed:
            return title
        case .needsAction:
            return I18n.Calendar_G_PleaseReplyEvent(event: title)
        @unknown default:
            return title
        }
    }

    var summary: String { return content.title }
    
    var startTime: Int64? { return content.startTime }

    var endTime: Int64? { return content.endTime }

    var isAllDay: Bool? { return content.isAllDay }
    
    var rrule: String? {
        if content.rrepeat.isEmpty {
            return nil
        }
        return content.rrepeat
    }
    
    var isRruleUpdated: Bool {
        return content.isRruleUpdated
    }
    
    var isTimeUpdated: Bool {
        return content.isTimeUpdated
    }
    
    var isLocationUpdated: Bool {
        return content.isLocationUpdated
    }
    
    var isResourceUpdated: Bool {
        return content.isResourceUpdated
    }

    var isShowConflict: Bool { return content.isShowConflict }

    var isShowRecurrenceConflict: Bool { return content.isRecurrenceConflict }

    var conflictTime: Int64 { return content.conflictTime }

    var location: String? {
        if content.location.isEmpty {
            return nil
        }
        return content.location
    }
    
    var meetingRoom: String? {
        if content.meetingRoom.isEmpty {
            return nil
        }
        return content.meetingRoom
    }
    
    var desc: String { return content.description }

    var attendeeRsvpInfo: [Basic_V1_AttendeeRSVPInfo] {
        // 个人rsvpInfo置于首位
        var info: [Basic_V1_AttendeeRSVPInfo] = content.attendeeRsvpInfo
        for i in 0..<content.attendeeRsvpInfo.count {
            if "\(content.attendeeRsvpInfo[i].calendarID)" == calendarID {
                info.remove(at: i)
                info.insert(content.attendeeRsvpInfo[i], at: 0)
                break
            }
        }

        return info
    }
    
    var needActionAttendeeIDs: [String] {
        return attendeeRsvpInfo
            .filter { $0.status == .needsAction }
            .map { "\($0.chatterID)" }
    }
    
    var needActionAttendeeNames: [String: String] {
        var names: [String: String] = [:]
        attendeeRsvpInfo
            .filter { $0.status == .needsAction }
            .map {
                names["\($0.chatterID)"] = $0.displayName
            }
        return names
    }
    
    var userOwnChatterId: String {
        var chatterID: Int64 = 0
        attendeeRsvpInfo.map {
            if "\($0.calendarID)" == calendarID {
                chatterID = $0.chatterID
            }
        }
        return "\(chatterID)"
    }
    
    var atMeForegroundColor: UIColor {
        return UIColor.ud.primaryOnPrimaryFill
    }

    var atOtherForegroundColor: UIColor {
        return UIColor.ud.primaryContentDefault
    }

    var atGroupForegroundColor: UIColor {
        return UIColor.ud.textPlaceholder
    }
    
    var isAllUserInGroupReplyed: Bool {
        return content.isAllUserInGroupReplyed
    }
    
    var rsvpAllReplyedCountString: String {
        var str: [String] = []
        if content.acceptCount != 0 {
            str.append(I18n.Calendar_Detail_NumberOfGuestAcccepted(acceptNum: content.acceptCount))
        }
        
        if content.declineCount != 0 {
            str.append(I18n.Calendar_Detail_NumberOfGuestRejected(rejectNum: content.declineCount))
        }
        
        if content.tentativeCount != 0 {
            str.append(I18n.Calendar_Detail_NumberOfGuestTentative(tentativeNum: content.tentativeCount))
        }
        
        if content.needActionCount != 0 {
            str.append(I18n.Calendar_Detail_NumberOfGuestNoAction(needActionNum: content.needActionCount) )
        }
        
        return str.joined(separator: I18n.Calendar_Common_DivideSymbol)
    }
    
    var eventTotalAttendeeCount: Int64 {
        return content.eventAttendeeCount
    }
    
    var needActionCount: Int64 {
        return content.needActionCount
    }
    
    var cardStatus: EventRSVPCardInfo.EventRSVPCardStatus { return content.cardStatus }
    
    var selfAttendeeRsvpStatus: CalendarEventAttendee.Status {
        get {
            return content.selfAttendeeStatus
        }
        set {
            content.selfAttendeeStatus = newValue
        }
    }

    var isJoined: Bool {
        get { return content.isJoined }
    }

    var isInValid: Bool {
        get { return content.isInValid }
        set { content.isInValid = newValue }
    }
    
    var isUpdated: Bool {
        return content.isUpdated
    }
    
    var isOrganizer: Bool {
        return calendarID == "\(organizerCalendarId)"
    }
    
    var isCrossTenant: Bool { return content.isCrossTenant }

    var isAttendeeOverflow: Bool { return content.isAttendeeOverflow }
    
    var isWebinar: Bool { return content.isWebinar }

    var isOptional: Bool { return content.isOptional }
    
    //此字段本次暂时不用，后续优化会使用
    var relationTag: String? {
        if let generalCalendarEventRSVPContent = content as? GeneralCalendarEventRSVPContent {
            return generalCalendarEventRSVPContent.relationTag
        }

        if isCrossTenant {
            return I18n.Calendar_Detail_External
        } else {
            return nil
        }
    }

    var meetingNotes: RustPB.Basic_V1_MeetingNotesInfo? {
        return content.meetingNotes
    }
}
