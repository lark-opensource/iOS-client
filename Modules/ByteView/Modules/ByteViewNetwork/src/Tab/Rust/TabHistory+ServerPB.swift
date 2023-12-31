//
//  TabHistory+ServerPB.swift
//  ByteViewNetwork
//
//  Created by fakegourmet on 2022/6/7.
//

import Foundation
import ServerPB

typealias S_PBHistoryAbbrInfo = ServerPB_Videochat_tab_v2_HistoryAbbrInfo
typealias S_PBTabListItem = ServerPB_Videochat_tab_v2_VCTabListItem
typealias S_PBHistoryInfo = ServerPB_Videochat_tab_v2_HistoryInfo
typealias S_PBFollowAbbrInfo = ServerPB_Videochat_tab_v2_FollowAbbrInfo
typealias S_PBTabDetailRecordInfo = ServerPB_Videochat_tab_v2_VCTabDetailRecordInfo
typealias S_PBTabDetailItemChangeEvent = ServerPB_Videochat_tab_v2_VCTabDetailItemChangeEvent
typealias S_PBTabStatisticsInfo = ServerPB_Videochat_tab_v2_VCTabStatisticsInfo
typealias S_PBRustTabMissedCallInfo = ServerPB_Videochat_tab_v2_VCTabTotalMissedCallInfo
typealias S_PBTabMeetingChangeInfo = ServerPB_Videochat_tab_v2_VCTabMeetingChangeInfo
typealias S_PBParticipantAbbrInfo = ServerPB_Videochat_VCParticipantAbbrInfo
typealias S_PBTabHistoryCommonInfo = ServerPB_Videochat_tab_v2_VCTabHistoryCommonInfo
typealias S_PBTabMeetingAbbrInfo = ServerPB_Videochat_tab_v2_VCTabMeetingAbbrInfo
typealias S_PBTabMeetingBaseInfo = ServerPB_Videochat_tab_v2_VCTabMeetingBaseInfo
typealias S_PBMeetingSourceAppLinkInfo = ServerPB_Videochat_tab_v2_MeetingSourceAppLinkInfo
typealias S_PBTabAccessInfos = ServerPB_Videochat_tab_v2_AccessInfos
typealias S_PBTabMeetingUserSpecInfo = ServerPB_Videochat_tab_v2_VCTabMeetingUserSpecInfo
typealias S_PBTabPstnIncomingSetting = ServerPB_Videochat_VideoChatPstnIncomingSetting
typealias S_PBTabDetailChatHistoryV2 = ServerPB_Videochat_tab_v2_ImRecordInfoV2
typealias S_PBCollectionInfo = ServerPB_Videochat_tab_v2_CollectionInfo
typealias S_PBBitableInfo = ServerPB_Videochat_tab_v2_BitableInfo
typealias S_PBAudienceInfo = ServerPB_Videochat_tab_v2_AudienceInfo
typealias S_PBVoteStatisticsInfo = ServerPB_Videochat_tab_v2_VCVoteStatisticsInfo
typealias S_PBTabNotesInfo = ServerPB_Videochat_tab_v2_NotesInfo

extension S_PBHistoryAbbrInfo {
    var vcType: HistoryAbbrInfo {
        .init(historyType: .init(rawValue: historyType.rawValue) ?? .unknown,
              callStatus: .init(rawValue: callStatus.rawValue) ?? .unknown, callCount: callCount,
              interacterUserID: interacterUserID,
              interacterUserType: interacterUserType.vcType)
    }
}

extension S_PBTabListItem {
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

extension S_PBHistoryInfo {
    var vcType: HistoryInfo {
        .init(historyType: .init(rawValue: historyType.rawValue) ?? .unknown, historyInfoType: .init(rawValue: historyInfoType.rawValue) ?? .unknown,
              callStatus: .init(rawValue: callStatus.rawValue) ?? .unknown,
              interacterUserID: interacterUserID, interacterUserType: interacterUserType.vcType,
              callStartTime: callStartTime, joinTime: joinTime, leaveTime: leaveTime,
              cancelReason: .init(rawValue: cancelReason.rawValue) ?? .cancel,
              offlineReason: .init(rawValue: offlineReason.rawValue) ?? .unknown)
    }
}

extension S_PBFollowAbbrInfo {
    var vcType: FollowAbbrInfo {
        .init(rawURL: rawURL, fileTitle: fileTitle, fileToken: fileToken, shareSubtype: .init(rawValue: shareSubtype.rawValue) ?? .unknown,
              fileLabelURL: fileLabelURL, presenters: presenters.map({ $0.vcType }))
    }
}

extension S_PBCollectionInfo {
    var vcType: CollectionInfo {
        .init(collectionID: collectionID, collectionTitle: collectionTitle, totalCount: Int(totalCount),
              collectionType: CollectionInfo.CollectionType(rawValue: collectionType.rawValue) ?? .unknown,
              items: items.map { $0.vcType }, calendarEventRrule: calendarEventRrule)
    }
}

extension S_PBTabDetailRecordInfo {
    var vcType: TabDetailRecordInfo {
        .init(type: .init(rawValue: type.rawValue) ?? .larkMinutes, url: url, minutesInfo: minutesInfo.map({ $0.vcType }), minutesInfoV2: minutesInfoV2.map({ $0.vcType }), recordInfo: recordInfo.map({ $0.vcType }), minutesBreakoutInfo: minutesBreakoutInfo.map({ $0.vcType }))
    }
}

extension S_PBTabDetailRecordInfo.MinutesInfo {
    var vcType: TabDetailRecordInfo.MinutesInfo {
        .init(url: url, topic: topic, owner: owner.vcType, hasViewPermission: hasViewPermission_p, duration: duration, status: .init(rawValue: status.rawValue) ?? .pending, coverUrl: coverURL, breakoutRoomID: breakoutRoomID, objectID: objectID)
    }
}

extension S_PBTabDetailRecordInfo.RecordInfo {
    var vcType: TabDetailRecordInfo.RecordInfo {
        .init(url: url, topic: topic, owner: owner.vcType, duration: duration, status: .init(rawValue: status.rawValue) ?? .pending, breakoutRoomID: breakoutRoomID)
    }
}

extension S_PBTabDetailChatHistoryV2 {
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

extension S_PBTabDetailItemChangeEvent {
    var vcType: TabDetailItemChangeEvent {
        .init(meetingID: meetingID,
              recordInfo: hasRecordInfo ? recordInfo.vcType : nil,
              historyInfo: hasHistoryInfo ? historyInfo.vcType : nil,
              replaceAllHistory: replaceAllHistory.map({ $0.vcType }),
              followInfo: followInfo.map({ $0.vcType }),
              version: version)
    }
}

extension S_PBTabStatisticsInfo {
    var vcType: TabStatisticsInfo {
        .init(meetingID: meetingID, status: .init(rawValue: status.rawValue) ?? .unavailable,
              statisticsURL: statisticsURL, statisticsFileTitle: statisticsFileTitle,
              version: version, isBitable: isBiTable)
    }
}

extension S_PBRustTabMissedCallInfo {
    var vcType: TabMissedCallInfo {
        .init(totalMissedCalls: totalMissedCalls, confirmedMissedCalls: confirmedMissedCalls)
    }
}

extension S_PBTabMeetingChangeInfo {
    var vcType: TabMeetingChangeInfo {
        .init(changeType: .init(rawValue: changeType.rawValue) ?? .participant,
              participantChanges: participantChanges.map({ $0.vcType }),
              meetingInfo: hasMeetingInfo ? meetingInfo.vcType : nil,
              audienceInfo: hasAudienceInfo ? audienceInfo.vcType : nil)
    }
}

extension S_PBParticipantAbbrInfo {
    var vcType: ParticipantAbbrInfo {
        .init(user: user.vcType, status: .init(rawValue: status.rawValue) ?? .unknown,
              deviceType: .init(rawValue: deviceType.rawValue) ?? .unknown,
              joinTimeMs: joinTimeMs, tenantID: Int64(tenantIDStr) ?? 0, isLarkGuest: isLarkGuest,
              bindID: bindID, bindType: .init(rawValue: bindType.rawValue) ?? .unknown,
              usedCallMe: usedCallMe)
    }
}

extension S_PBTabHistoryCommonInfo {
    var vcType: TabHistoryCommonInfo {
        .init(meetingTopic: meetingTopic, meetingType: meetingType.vcType, meetingSource: .init(rawValue: meetingSource.rawValue) ?? .unknown,
              meetingStatus: .init(rawValue: meetingStatus.rawValue) ?? .unknown,
              isLocked: isLocked, containsMultipleTenant: containsMultipleTenant, sameTenantID: sameTenantID,
              startTime: startTime, endTime: endTime, hostUser: hostUser.vcType, isRecorded: isRecorded, canCopyMeetingInfo: canCopyMeetingInfo, isCrossWithKa: isCrossWithKa,
              meetingSubType: meetingSubType.vcType, allParticipantTenant: allParticipantTenant, rehearsalStatus: rehearsalStatus.vcType)
    }
}

extension S_PBTabMeetingAbbrInfo {
    var vcType: TabMeetingAbbrInfo {
        .init(meetingID: meetingID, meetingBaseInfo: meetingBaseInfo.vcType, userSpecInfo: userSpecInfo.vcType)
    }
}

extension S_PBTabMeetingBaseInfo {
    var vcType: TabMeetingBaseInfo {
        .init(meetingInfo: meetingInfo.vcType, sponsorUser: sponsorUser.vcType, participants: participants.map({ $0.vcType }),
              downVersion: downVersion,
              audienceNum: audienceNum)
    }
}

extension S_PBVoteStatisticsInfo {
    var vcType: TabVoteStatisticsInfo {
        .init(status: .init(rawValue: status.rawValue) ?? .unavailable,
              statisticsURL: statisticsURL,
              statisticsFileTitle: statisticsFileTitle,
              meetingID: meetingID,
              owner: owner.vcType,
              version: version)
    }
}

extension S_PBTabNotesInfo {
    var vcType: TabNotesInfo {
        .init(owner: owner.vcType,
              notesURL: notesURL,
              fileTitle: fileTitle)
    }
}

extension S_PBTabMeetingUserSpecInfo {
    var vcType: TabMeetingUserSpecInfo {
        .init(historyInfo: historyInfo.map({ $0.vcType }),
              recordInfo: hasRecordInfo ? recordInfo.vcType : nil,
              followInfo: followInfo.map({ $0.vcType }),
              statisticsInfo: hasStatisticsInfo ? statisticsInfo.vcType : nil,
              sourceApplink: hasSourceApplink ? sourceApplink.vcType : nil,
              manageURLParam: manageURLParam,
              version: version,
              collection: collection.map { $0.vcType },
              checkinInfo: nil,
              chatHistoryV2: hasImInfoV2 ? imInfoV2.vcType : nil, // TODO : @maozhixiang.lip
              bitable: hasBitable ? bitable.vcType : nil,
              isWebinarAudience: isWebinarAudience,
              voteStatisticsInfo: voteStatisticsInfo.vcType,
              notesInfo: notesInfo.first?.vcType) // 目前只支持一篇纪要，服务端留了多纪要的接口，这里我们取第一个
    }
}

extension S_PBMeetingSourceAppLinkInfo {
    var vcType: MeetingSourceAppLinkInfo {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown,
              paramCalendar: hasParamCalendar ? paramCalendar.vcType : nil,
              paramGroup: hasParamGroup ? paramGroup.vcType : nil)
    }
}

extension S_PBMeetingSourceAppLinkInfo.ParamFromCalendar {
    var vcType: MeetingSourceAppLinkInfo.ParamFromCalendar {
        .init(calendarID: calendarID, key: key, originalTime: originalTime, startTime: startTime)
    }
}

extension S_PBMeetingSourceAppLinkInfo.ParamFromGroup {
    var vcType: MeetingSourceAppLinkInfo.ParamFromGroup {
        .init(chatID: chatID)
    }
}

extension S_PBTabAccessInfos {
    var vcType: TabAccessInfos {
        .init(pstnIncomingSetting: pstnIncomingSetting.vcType, sipSetting: sipSetting.vcType, h323Setting: h323Setting.vcType)
    }
}

extension S_PBTabPstnIncomingSetting {
    var vcType: TabAccessInfos.PstnIncomingSetting {
        .init(pstnEnableIncomingCall: pstnEnableIncomingCall, pstnIncomingCallCountryDefault: pstnIncomingCallCountryDefault,
              pstnIncomingCallPhoneList: pstnIncomingCallPhoneList.map({ $0.vcType }))
    }
}

extension S_PBBitableInfo {
    var vcType: BitableInfo {
        .init(url: url, title: title, owner: owner.vcType)
    }
}

extension S_PBAudienceInfo {
    var vcType: AudienceInfo {
        .init(audienceNum: audienceNum)
    }
}
