//
//  CardDataModelImp.swift
//  Calendar
//
//  Created by heng zhu on 2019/6/24.
//

import UIKit
import Foundation
import LarkModel
import RustPB
import LarkContainer
import CalendarFoundation
import LKCommonsLogging

fileprivate let logger = Logger.log(CardDataModelImp.self, category: "Calendar.CardDataModel")

struct CardDataModelImp: InviteEventCardModel {

    let content: CalendarBotContent
    let message: LarkModel.Message
    let chatId: String
    let tenantId: String

    init(content: CalendarBotContent,
         message: LarkModel.Message,
         chatId: String,
         tenantId: String) {
        self.content = content
        self.message = message
        self.chatId = chatId
        self.tenantId = tenantId

        if content.isAccepted {
            status = .accept
        } else if content.isDeclined {
            status = .decline
        } else if content.isTentatived {
            status = .tentative
        } else {
            status = .needsAction
        }
    }

    var showReplyInviterEntry: Bool {
        return content.showReplyInviterEntry
    }

    var rsvpCommentUserName: String? {
        if let generalContent = content as? GeneralCalendarBotCardContent {
            guard let responderUserID = generalContent.responderUserID else { return nil }
            return content.complementSenderName(with: content.chattersForUserNames, senderUserId: responderUserID)
        }

        let commentUserName = content.complementSenderName(with: content.chattersForUserNames,
                                                           senderUserId: content.userInviteOperatorId)
        return commentUserName.isEmpty ? nil : commentUserName
    }

    var userInviteOperatorId: String? {
        return content.userInviteOperatorId
    }

    var successorUserId: String? {
        return content.successorUserID
    }

    var organizerUserId: String? {
        return content.organizerUserID
    }

    var creatorUserId: String? {
        return content.creatorUserID
    }

    var inviteOperatorLocalizedName: String? {
        return content.inviteOperatorLocalizedName
    }

    public var descAttributedInfo: (string: NSAttributedString, range: [NSRange: URL])? {
        if let desc = content.desc, desc.isEmpty {
            return nil
        }
        guard let richTextObject: RustPB.Basic_V1_RichText = content.richText else {
            return nil
        }
        let checkIsMe: ((String) -> Bool) = { _ in
            return false
        }
        let customFont = UIFont.systemFont(ofSize: 14)
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.ud.textTitle,
            .font: customFont]

        return paseRichText(richText: richTextObject,
                            isShowReadStatus: false,
                            checkIsMe: checkIsMe,
                            maxLines: 0,
                            maxCharLine: 90,
                            customAttributes: attributes)
    }
    public var richText: NSAttributedString? {
        return nil
    }

    public var status: CalendarEventAttendee.Status

    public var conflictTime: Int64 {
        return content.conflictTime
    }

    public var hasReaction: Bool {
        return !message.reactions.isEmpty
    }

    public var messageId: String {
        return message.id
    }

    public var eventServerID: String {
        return content.eventId ?? ""
    }
    public var attendeeCount: Int {
        return content.attendeeCount
    }

    public var groupIds: [String]? {
        return Array(content.chatNames.keys)
    }

    public var groupNames: [String: String] {
        return content.chatNames
    }

    public var isCrossTenant: Bool {
        return content.isCrossTenant
    }

    public var senderUserName: String {
        content.complementSenderName(with: content.chattersForUserNames,
                                     senderUserId: content.senderUserId)
    }

    public var senderUserId: String? {
        return content.senderUserId
    }

    public var eventId: String? {
        return content.eventId
    }

    public var isAccepted: Bool {
        return content.isAccepted
    }

    public var isDeclined: Bool {
        return content.isDeclined
    }

    public var isTentatived: Bool {
        return content.isTentatived
    }

    public var isShowOptional: Bool {
        return content.isOptional
    }

    public var isShowConflict: Bool {
        return content.isConflict
    }

    public var isShowRecurrenceConflict: Bool {
        return content.isRecurrenceConflict
    }

    public var messageType: Int? {
        return content.messageType
    }

    public var startTime: Int64? {
        return content.startTime
    }

    public var endTime: Int64? {
        return content.endTime
    }

    public var isAllDay: Bool? {
        return content.isAllDay
    }

    public var meetingRoomsInfo: [(name: String, isDisabled: Bool)] {
        return content.meetingRoomsInfo
    }

    public var meetingRooms: String? {
        if let meetingRoom = content.meetingRoom, meetingRoom.isEmpty {
            return nil
        }
        return content.meetingRoom
    }

    public var summary: String {
        return content.summary
    }

    public var time: String {
        return content.time
    }

    public var rrule: String? {
        if let rrepeat = content.rrepeat, rrepeat.isEmpty {
            return nil
        }
        return content.rrepeat
    }

    public var attendeeIDs: [String]? {
        return content.attendeeIDs
    }

    public var attendeeNames: [String: String] {
        content.complementAttendeeNames(with: content.chattersForUserNames,
                                        attendeeIDs: content.attendeeIDs)
    }

    public var location: String? {
        if let location = content.location, location.isEmpty {
            return nil
        }
        return content.location
    }

    public var desc: String? {
        return content.desc
    }

    public var needAction: Bool {
        return content.needAction
    }

    public var calendarID: String? {
        return content.calendarId
    }

    public var key: String? {
        return content.key
    }

    public var originalTime: Int? {
        return content.originalTime
    }

    public var acceptButtonColor: String? {
        return content.acceptButtonColor
    }

    public var declineButtonColor: String? {
        return content.declineButtonColor
    }

    public var tentativeButtonColor: String? {
        return content.tentativeButtonColor
    }

    public var atMeForegroundColor: UIColor {
        return UIColor.ud.primaryOnPrimaryFill
    }

    public var atOtherForegroundColor: UIColor {
        return UIColor.ud.primaryContentDefault
    }

    public var atGroupForegroundColor: UIColor {
        return UIColor.ud.textPlaceholder
    }

    public var showTimeUpdatedFlag: Bool {
        guard let updatedDiff = content.updatedDiff,
            let startTime = startTime,
            let endTime = endTime,
            let isAllDay = isAllDay else {
            return false
        }
        return updatedDiff.startTime != startTime
            || updatedDiff.endTime != endTime
            || updatedDiff.isAllDay != isAllDay
    }

    public var showRruleUpdatedFlag: Bool {
        guard let updatedDiff = content.updatedDiff else {
            return false
        }
        return (rrule ?? "") != (updatedDiff.rruleText ?? "")
    }

    public var showLocationUpdatedFlag: Bool {
        guard let updatedDiff = content.updatedDiff else {
            return false
        }
        return (location ?? "") != (updatedDiff.loctionText ?? "")
    }

    public var showMeetingRoomUpdatedFlag: Bool {
        guard let updatedDiff = content.updatedDiff else {
            return false
        }
        let curMeetingRoomText = meetingRoomsInfo
            .map { $0.0 }
            .sorted()
            .joined(separator: "")
        return updatedDiff.meetingRoomTexts.sorted().joined(separator: "") != curMeetingRoomText
    }

    public var isInvalid: Bool {
        return content.isInvalid
    }

    // webinar
    public var isWebinar: Bool {
        return content.isWebinar
    }

    public var speakerChatterIDs: [String] {
        return content.speakerChatterIDs
    }

    public var speakerNames: [String: String] {
        return content.complementSpeakerNames(with: content.chattersForUserNames,
                                              speakerIDs: content.speakerChatterIDs)
    }

    public var speakerGroupIDs: [String] {
        return Array(content.speakerChatNames.keys)
    }

    public var speakerGroupNames: [String: String] {
        return content.speakerChatNames
    }

    public var relationTag: String? {
        if let calendarBotCardContent = content as? CalendarBotCardContent {
            return calendarBotCardContent.relationTag
        }

        let tenant = Tenant(currentTenantId: self.tenantId)
        if tenant.isExternalTenant(isCrossTenant: isCrossTenant) {
            return I18n.Calendar_Detail_External
        } else {
            return nil
        }
    }

}

extension CalendarBotContent {
    func complementAttendeeNames(
        with chatters: [String: RustPB.Basic_V1_Chatter],
        attendeeIDs: [String]?
    ) -> [String: String] {
        var names: [String: String] = [:]
        let fg = FG.useChatterAnotherName
        attendeeIDs?.forEach({ (attendeeID) in
            if let name = getNameOn(chatter: chatters[attendeeID], useChatterAnotherName: fg) {
                names.updateValue(name, forKey: attendeeID)
            }
        })
        return names
    }

    // webinar 嘉宾
    func complementSpeakerNames( with chatters: [String: RustPB.Basic_V1_Chatter],
                                 speakerIDs: [String]?) -> [String: String] {
        var names: [String: String] = [:]
        let fg = FG.useChatterAnotherName
        speakerIDs?.forEach({ (id) in
            if let name = getNameOn(chatter: chatters[id], useChatterAnotherName: fg) {
                names.updateValue(name, forKey: id)
            }
        })
        return names
    }

    func complementSenderName(with chatters: [String: RustPB.Basic_V1_Chatter], senderUserId: String?) -> String {
        var name: String = ""
        if let userId = senderUserId {
            name = getNameOn(chatter: chatters[userId], useChatterAnotherName: FG.useChatterAnotherName) ?? ""
        }
        return name
    }

    func getNameOn(chatter: Basic_V1_Chatter?,
                   useChatterAnotherName: Bool) -> String? {
        guard let chatter = chatter else { return nil }
        return useChatterAnotherName ? chatter.nameWithAnotherName : chatter.localizedName
    }
}


extension CardDataModelImp {
    func paseRichText(richText: RustPB.Basic_V1_RichText,
                      isShowReadStatus: Bool,
                      checkIsMe: ((_ userId: String) -> Bool)?,
                      maxLines: Int,
                      maxCharLine: Int,
                      customAttributes: [NSAttributedString.Key: Any]) -> (string: NSAttributedString, range: [NSRange: URL])? {
        logger.info("isShowReadStatus:\(isShowReadStatus), maxLines:\(maxLines), maxCharLine:\(maxCharLine)")
        #if MessengerMod
        let attributeElement = LarkCoreUtils.parseRichText(richText: richText,
                                                           isShowReadStatus: isShowReadStatus,
                                                           checkIsMe: checkIsMe,
                                                           maxLines: maxLines,
                                                           maxCharLine: maxCharLine,
                                                           customAttributes: customAttributes)
        return (attributeElement.attriubuteText, attributeElement.urlRangeMap)
        #else
        return nil
        #endif
    }
}
