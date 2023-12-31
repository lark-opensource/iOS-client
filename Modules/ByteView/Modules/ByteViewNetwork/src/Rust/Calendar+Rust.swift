//
//  Calendar+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ServerPB
import SwiftProtobuf

typealias PBCalendarInfo = Videoconference_V1_CalendarInfo
typealias ServerPBCalendarVCSettings = ServerPB_Videochat_calendar_CalendarVCSettings

typealias ServerPBCalendarIntelligentMeetingSetting = ServerPB_Videochat_calendar_CalendarIntelligentMeetingSetting
typealias ServerPBCalendarFeatureStatus = ServerPB_Videochat_calendar_CalendarIntelligentMeetingSetting.FeatureStatus

extension PBCalendarInfo {
    var vcType: CalendarInfo {
        .init(topic: topic, groupID: groupID, desc: description_p, total: total, canEnterOrCreateGroup: canEnterOrCreateGroup,
              theEventStartTime: theEventStartTime, theEventEndTime: theEventEndTime, wholeEventEndTime: wholeEventEndTime, isAllDay: isAllDay,
              rooms: rooms.mapValues({ $0.toCalendarRoom() }),
              roomStatus: roomStatus.mapValues({ CalendarInfo.CalendarAcceptStatus(rawValue: $0.rawValue) ?? .unknown }),
              viewRooms: viewRooms.mapValues({ $0.toCalendarRoom() }),
              calendarLocations: calendarLocations.map({ $0.vcType }))
    }
}

extension PBRoom {
    func toCalendarRoom() -> CalendarInfo.CalendarRoom {
        .init(roomID: roomID, name: name, capacity: capacity, controllerIDList: controllerIDList,
              location: location.vcType, meetingNumber: meetingNumber, avatarKey: avatarKey,
              tenantID: tenantID, fullNameParticipant: fullNameParticipant, fullNameSite: fullNameSite,
              primaryNameParticipant: primaryNameParticipant, primaryNameSite: primaryNameSite,
              secondaryName: secondaryName, isUnbind: isUnbind)
    }
}

extension PBRoom.Location {
    var vcType: RoomLocation {
        .init(floorName: floorName, buildingName: buildingName)
    }
}

extension PBCalendarInfo.CalendarLocation {
    var vcType: CalendarInfo.CalendarLocation {
        .init(name: name, address: address)
    }
}

extension CalendarSettings {
    public init(jsonString: String) throws {
        let pb = try ServerPBCalendarVCSettings(jsonString: jsonString, options: .ignoreUnknownFieldsOption)
        self.init(pb: pb)
    }

    public func toJSONString() throws -> String {
        return try toProtobuf().jsonString(options: Self.jsonEncodingOptions)
    }

    private static let jsonEncodingOptions: JSONEncodingOptions = {
        var options = JSONEncodingOptions()
        options.alwaysPrintEnumsAsInts = true
        options.preserveProtoFieldNames = true
        return options
    }()
}

extension ServerPBCalendarVCSettings {
    var vcType: CalendarSettings {
        .init(vcSecuritySetting: .init(rawValue: vcSecuritySetting.rawValue) ?? .public,
              canJoinMeetingBeforeOwnerJoined: canJoinMeetingBeforeOwnerJoined,
              muteMicrophoneWhenJoin: muteMicrophoneWhenJoin,
              putNoPermissionUserInLobby: putNoPermissionUserInLobby,
              autoRecord: autoRecord,
              isPartiUnmuteForbidden: isPartiUnmuteForbidden,
              backupHostUids: backupHostUids,
              onlyHostCanShare: onlyHostCanShare,
              onlyPresenterCanAnnotate: onlyPresenterCanAnnotate,
              isPartiChangeNameForbidden: isPartiChangeNameForbidden,
              isAudienceChangeNameForbidden: isAudienceChangeNameForbidden,
              isAudienceImForbidden: isAudienceImForbidden,
              isAudienceHandsUpForbidden: isAudienceHandsUpForbidden,
              isAudienceReactionForbidden: isAudienceReactionForbidden,
              interpretationSetting: interpretationSetting.vcType,
              panelistPermission: panelistPermission.vcType,
              rehearsalMode: rehearsalMode,
              intelligentMeetingSetting: intelligentMeetingSetting.vcType
        )
    }
}
