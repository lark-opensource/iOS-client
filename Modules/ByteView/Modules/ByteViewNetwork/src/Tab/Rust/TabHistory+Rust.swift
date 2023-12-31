//
//  TabHistory+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias PBHistoryAbbrInfo = Videoconference_V1_HistoryAbbrInfo
typealias PBTabListItem = Videoconference_V1_VCTabListItem
typealias PBTabUpcomingInstance = Videoconference_V1_VCUpcomingVcInstance
typealias PBHistoryInfo = Videoconference_V1_HistoryInfo
typealias PBFollowAbbrInfo = Videoconference_V1_FollowAbbrInfo
typealias PBTabDetailRecordInfo = Videoconference_V1_VCTabDetailRecordInfo
typealias PBTabDetailItemChangeEvent = Videoconference_V1_VCTabDetailItemChangeEvent
typealias PBTabStatisticsInfo = Videoconference_V1_VCTabStatisticsInfo
typealias PBRustTabMissedCallInfo = Videoconference_V1_VCTabTotalMissedCallInfo
typealias PBTabMeetingChangeInfo = Videoconference_V1_VCTabMeetingChangeInfo
typealias PBParticipantAbbrInfo = Videoconference_V1_VCParticipantAbbrInfo
typealias PBTabHistoryCommonInfo = Videoconference_V1_VCTabHistoryCommonInfo
typealias PBTabMeetingAbbrInfo = Videoconference_V1_VCTabMeetingAbbrInfo
typealias PBTabMeetingBaseInfo = Videoconference_V1_VCTabMeetingBaseInfo
typealias PBMeetingSourceAppLinkInfo = Videoconference_V1_MeetingSourceAppLinkInfo
typealias PBTabAccessInfos = Videoconference_V1_AccessInfos
typealias PBTabMeetingUserSpecInfo = Videoconference_V1_VCTabMeetingUserSpecInfo
typealias PBTabPstnIncomingSetting = Videoconference_V1_VideoChatPstnIncomingSetting
typealias PBMeetingJoinInfo = Videoconference_V1_MeetingJoinInfo
typealias PBTabDetailChatHistoryV2 = Videoconference_V1_ImRecordInfoV2
typealias PBCollectionInfo = Videoconference_V1_CollectionInfo
typealias PBTabDetailCheckinInfo = Videoconference_V1_VCTabCheckInInfo
typealias PBBitableInfo = Videoconference_V1_BitableInfo
typealias PBAudienceInfo = Videoconference_V1_AudienceInfo
typealias PBCalendarEvent = Calendar_V1_CalendarEvent
typealias PBWebinarAttendeeType = Calendar_V1_WebinarAttendeeType
typealias PBVoteStatisticsInfo = Videoconference_V1_VCVoteStatisticsInfo
typealias PBTabNotesInfo = Videoconference_V1_VCTabNotesInfo

extension PBMeetingJoinInfo {
    var vcType: MeetingJoinInfo {
        .init(meetingID: meetingID, joinStatus: .init(rawValue: joinStatus.rawValue) ?? .unknown)
    }
}

extension PBHistoryAbbrInfo {
    var vcType: HistoryAbbrInfo {
        .init(historyType: .init(rawValue: historyType.rawValue) ?? .unknown,
              callStatus: .init(rawValue: callStatus.rawValue) ?? .unknown, callCount: callCount,
              interacterUserID: interacterUserID,
              interacterUserType: interacterUserType.vcType)
    }
}

extension PBTabListItem {
    var vcType: TabListItem {
        .init(historyID: historyID, meetingID: meetingID, meetingType: meetingType.vcType, meetingTopic: meetingTopic,
              meetingSource: .init(rawValue: meetingSource.rawValue) ?? .unknown,
              meetingStatus: .init(rawValue: meetingStatus.rawValue) ?? .unknown,
              meetingNumber: meetingNumber, meetingStartTime: meetingStartTime, isLocked: isLocked,
              historyAbbrInfo: historyAbbrInfo.vcType, sortTime: sortTime,
              containsMultipleTenant: containsMultipleTenant, sameTenantID: sameTenantID,
              subscribeDetailChange: subscribeDetailChange, contentLogos: contentLogos.map({ .init(rawValue: $0.rawValue) ?? .unknown }),
              uniqueID: uniqueID, phoneNumber: phoneNumber, phoneType: .init(rawValue: phoneType.rawValue) ?? .vc,
              recordInfo: recordInfo.vcType,
              followInfo: followInfo.map { $0.vcType },
              collectionInfo: collectionInfo.map { $0.vcType },
              ipPhoneNumber: ipPhoneNumber, isCrossWithKa: isCrossWithKa,
              showVersion: showVersion,
              enterpriseType: .init(rawValue: enterpriseType.rawValue) ?? .enterprise,
              meetingSubType: meetingSubType.vcType,
              allParticipantTenant: allParticipantTenant,
              rehearsalStatus: rehearsalStatus.vcType)
    }
}

extension PBTabUpcomingInstance {
    var vcType: TabUpcomingInstance {
        .init(key: key, meetingNumber: meetingNumber, uniqueID: uniqueID, summary: summary, startTime: startTime, endTime: endTime,
              isCrossTenant: isCrossTenant, originalTime: originalTime,
              category: category.vcType,
              selfWebinarAttendeeType: selfWebinarAttendeeType.vcType,
              relationTag: hasRelationTag ? relationTag.vcType : nil)
    }
}

extension PBCalendarEvent.Category {
    var vcType: TabUpcomingInstance.Category {
        switch self {
        case .defaultCategory: return .defaultCategory
        case .resourceRequisition: return .resourceRequisition
        case .resourceStrategy: return .resourceStrategy
        case .samePageMeeting: return .samePageMeeting
        case .webinar: return .webinar
        @unknown default: return .defaultCategory
        }
    }
}

extension PBWebinarAttendeeType {
    var vcType: TabUpcomingInstance.WebinarAttendeeType {
        switch self {
        case .audience: return .audience
        case .speaker: return .speaker
        @unknown default: return .unknown
        }
    }
}

extension PBHistoryInfo {
    var vcType: HistoryInfo {
        .init(historyType: .init(rawValue: historyType.rawValue) ?? .unknown, historyInfoType: .init(rawValue: historyInfoType.rawValue) ?? .unknown,
              callStatus: .init(rawValue: callStatus.rawValue) ?? .unknown,
              interacterUserID: interacterUserID, interacterUserType: interacterUserType.vcType,
              callStartTime: callStartTime, joinTime: joinTime, leaveTime: leaveTime, cancelReason: .init(rawValue: cancelReason.rawValue) ?? .cancel, offlineReason: .init(rawValue: offlineReason.rawValue) ?? .unknown)
    }
}

extension PBFollowAbbrInfo {
    var vcType: FollowAbbrInfo {
        .init(rawURL: rawURL, fileTitle: fileTitle, fileToken: fileToken, shareSubtype: .init(rawValue: shareSubtype.rawValue) ?? .unknown,
              fileLabelURL: fileLabelURL, presenters: presenters.map({ $0.vcType }))
    }
}

extension PBCollectionInfo {
    var vcType: CollectionInfo {
        .init(collectionID: collectionID, collectionTitle: collectionTitle, totalCount: Int(totalCount),
              collectionType: CollectionInfo.CollectionType(rawValue: collectionType.rawValue) ?? .unknown,
              items: items.map { $0.vcType }, calendarEventRrule: calendarEventRrule)
    }
}

extension PBTabDetailRecordInfo {
    var vcType: TabDetailRecordInfo {
        .init(type: .init(rawValue: type.rawValue) ?? .larkMinutes, url: url, minutesInfo: minutesInfo.map({ $0.vcType }), minutesInfoV2: minutesInfoV2.map({ $0.vcType }), recordInfo: recordInfo.map({ $0.vcType }), minutesBreakoutInfo: minutesBreakoutInfo.map({ $0.vcType }))
    }
}

extension PBTabDetailRecordInfo.MinutesInfo {
    var vcType: TabDetailRecordInfo.MinutesInfo {
        .init(url: url, topic: topic, owner: owner.vcType, hasViewPermission: hasViewPermission_p, duration: duration, status: .init(rawValue: status.rawValue) ?? .pending, coverUrl: coverURL, breakoutRoomID: breakoutRoomID, objectID: objectID)
    }
}

extension PBTabDetailRecordInfo.RecordInfo {
    var vcType: TabDetailRecordInfo.RecordInfo {
        .init(url: url, topic: topic, owner: owner.vcType, duration: duration, status: .init(rawValue: status.rawValue) ?? .pending, breakoutRoomID: breakoutRoomID)
    }
}

extension PBTabDetailCheckinInfo {
    var vcType: TabDetailCheckinInfo {
        .init(meetingId: "", url: checkInURL, title: checkInTitle, ownerUserId: "\(ownerID)")
    }
}
extension PBTabDetailChatHistoryV2 {
    var vcType: TabDetailChatHistoryV2 {
        .init(meetingID: meetingID,
              version: version,
              owner: imOwner.vcType,
              status: .init(rawValue: imGenerateStatus.rawValue) ?? .unavailable,
              title: imTitle,
              url: rawURL,
              type: .init(rawValue: imRecordType.rawValue) ?? .unknown)
    }
}

extension PBTabDetailItemChangeEvent {
    var vcType: TabDetailItemChangeEvent {
        .init(meetingID: meetingID,
              recordInfo: hasRecordInfo ? recordInfo.vcType : nil,
              historyInfo: hasHistoryInfo ? historyInfo.vcType : nil,
              replaceAllHistory: replaceAllHistory.map({ $0.vcType }),
              followInfo: followInfo.map({ $0.vcType }),
              version: version)
    }
}

extension PBTabStatisticsInfo {
    var vcType: TabStatisticsInfo {
        .init(meetingID: meetingID, status: .init(rawValue: status.rawValue) ?? .unavailable,
              statisticsURL: statisticsURL, statisticsFileTitle: statisticsFileTitle,
              version: version, isBitable: isBiTable)
    }
}

extension PBRustTabMissedCallInfo {
    var vcType: TabMissedCallInfo {
        .init(totalMissedCalls: totalMissedCalls, confirmedMissedCalls: confirmedMissedCalls)
    }
}

extension PBTabMeetingChangeInfo {
    var vcType: TabMeetingChangeInfo {
        .init(changeType: .init(rawValue: changeType.rawValue) ?? .participant,
              participantChanges: participantChanges.map({ $0.vcType }),
              meetingInfo: hasMeetingInfo ? meetingInfo.vcType : nil,
              audienceInfo: hasAudienceInfo ? audienceInfo.vcType : nil)
    }
}

extension PBParticipantAbbrInfo {
    var vcType: ParticipantAbbrInfo {
        .init(user: user.vcType, status: .init(rawValue: status.rawValue) ?? .unknown,
              deviceType: .init(rawValue: deviceType.rawValue) ?? .unknown,
              joinTimeMs: joinTimeMs, tenantID: tenantID, isLarkGuest: isLarkGuest,
              bindID: bindID, bindType: .init(rawValue: bindType.rawValue) ?? .unknown, usedCallMe: usedCallMe)
    }
}

extension PBTabHistoryCommonInfo {
    var vcType: TabHistoryCommonInfo {
        .init(meetingTopic: meetingTopic, meetingType: meetingType.vcType, meetingSource: .init(rawValue: meetingSource.rawValue) ?? .unknown,
              meetingStatus: .init(rawValue: meetingStatus.rawValue) ?? .unknown,
              isLocked: isLocked, containsMultipleTenant: containsMultipleTenant, sameTenantID: sameTenantID,
              startTime: startTime, endTime: endTime, hostUser: hostUser.vcType, isRecorded: isRecorded, canCopyMeetingInfo: canCopyMeetingInfo, isCrossWithKa: isCrossWithKa, meetingSubType: meetingSubType.vcType, allParticipantTenant: allParticipantTenant, rehearsalStatus: rehearsalStatus.vcType)
    }
}

extension PBTabMeetingAbbrInfo {
    var vcType: TabMeetingAbbrInfo {
        .init(meetingID: meetingID, meetingBaseInfo: meetingBaseInfo.vcType, userSpecInfo: userSpecInfo.vcType)
    }
}

extension PBTabMeetingBaseInfo {
    var vcType: TabMeetingBaseInfo {
        .init(meetingInfo: meetingInfo.vcType, sponsorUser: sponsorUser.vcType, participants: participants.map({ $0.vcType }),
              downVersion: downVersion, audienceNum: audienceNum)
    }
}

extension PBVoteStatisticsInfo {
    var vcType: TabVoteStatisticsInfo {
        .init(status: .init(rawValue: status.rawValue) ?? .unavailable,
              statisticsURL: statisticsURL,
              statisticsFileTitle: statisticsFileTitle,
              meetingID: meetingID,
              owner: owner.vcType,
              version: version)
    }
}

extension PBTabNotesInfo {
    var vcType: TabNotesInfo {
        .init(owner: owner.vcType,
              notesURL: notesURL,
              fileTitle: fileTitle)
    }
}

extension PBTabMeetingUserSpecInfo {
    var vcType: TabMeetingUserSpecInfo {
        .init(historyInfo: historyInfo.map({ $0.vcType }),
              recordInfo: hasRecordInfo ? recordInfo.vcType : nil,
              followInfo: followInfo.map({ $0.vcType }),
              statisticsInfo: hasStatisticsInfo ? statisticsInfo.vcType : nil,
              sourceApplink: hasSourceApplink ? sourceApplink.vcType : nil,
              manageURLParam: manageURLParam,
              version: version,
              collection: collection.map { $0.vcType },
              checkinInfo: hasCheckInInfo ? checkInInfo.vcType : nil,
              chatHistoryV2: hasImInfoV2 ? imInfoV2.vcType : nil,
              bitable: hasBitable ? bitable.vcType : nil,
              isWebinarAudience: isWebinarAudience,
              voteStatisticsInfo: hasVoteStatisticsInfo ? voteStatisticsInfo.vcType : nil,
              notesInfo: notesInfo.first?.vcType) // 目前只支持一篇纪要，服务端留了多纪要的接口，这里我们取第一个
    }
}

extension PBMeetingSourceAppLinkInfo {
    var vcType: MeetingSourceAppLinkInfo {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown,
              paramCalendar: hasParamCalendar ? paramCalendar.vcType : nil,
              paramGroup: hasParamGroup ? paramGroup.vcType : nil)
    }
}

extension PBMeetingSourceAppLinkInfo.ParamFromCalendar {
    var vcType: MeetingSourceAppLinkInfo.ParamFromCalendar {
        .init(calendarID: calendarID, key: key, originalTime: originalTime, startTime: startTime)
    }
}

extension PBMeetingSourceAppLinkInfo.ParamFromGroup {
    var vcType: MeetingSourceAppLinkInfo.ParamFromGroup {
        .init(chatID: chatID)
    }
}

extension PBTabAccessInfos {
    var vcType: TabAccessInfos {
        .init(pstnIncomingSetting: pstnIncomingSetting.vcType, sipSetting: sipSetting.vcType, h323Setting: h323Setting.vcType)
    }
}

extension PBTabPstnIncomingSetting {
    var vcType: TabAccessInfos.PstnIncomingSetting {
        .init(pstnEnableIncomingCall: pstnEnableIncomingCall, pstnIncomingCallCountryDefault: pstnIncomingCallCountryDefault,
              pstnIncomingCallPhoneList: pstnIncomingCallPhoneList.map({ .init(pb: $0) }))
    }
}

extension PBBitableInfo {
    var vcType: BitableInfo {
        .init(url: url, title: title, owner: owner.vcType)
    }
}

extension PBAudienceInfo {
    var vcType: AudienceInfo {
        .init(audienceNum: audienceNum)
    }
}
