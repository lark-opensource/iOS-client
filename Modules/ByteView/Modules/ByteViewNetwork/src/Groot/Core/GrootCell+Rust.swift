//
//  GrootPushCommand+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/15.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB

typealias PBGrootChannelMeta = Videoconference_V1_ChannelMeta
typealias PBGrootCell = Videoconference_V1_GrootCell
typealias PBPushGrootChannelStatus = Videoconference_V1_PushGrootChannelStatus
typealias PBGrootChannelType = Videoconference_V1_GrootChannel
typealias PBChannelMetaAssociateType = Videoconference_V1_ChannelMeta.AssociateType
typealias PBMeetingMeta = Videoconference_V1_MeetingMeta
typealias PBIMNoticeInfo = Videoconference_V1_IMNoticeInfo

// MARK: - groot conversion

extension GrootChannel: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_ChannelMeta
    init(pb: Videoconference_V1_ChannelMeta) throws {
        guard let type = GrootChannelType(rawValue: pb.channel.rawValue) else {
            throw ProtobufCodableError(.notSupported, "channel: \(pb.channel)")
        }
        if let idType = GrootChannel.AssociateType(rawValue: pb.idType.rawValue) {
            self.init(id: pb.channelID, type: type, associateID: pb.associateID, idType: idType)
        } else {
            self.init(id: pb.channelID, type: type)
        }
    }
}

extension GrootChannel {
    var pbType: PBGrootChannelMeta {
        var meta = PBGrootChannelMeta()
        if let channel = PBGrootChannelType(rawValue: type.rawValue) {
            meta.channel = channel
        }
        meta.channelID = id
        if let associateID = associateID {
            meta.associateID = associateID
        }
        if let type = idType, let idType = PBChannelMetaAssociateType(rawValue: type.rawValue) {
            meta.idType = idType
        }
        if let meetingMeta = meetingMeta {
            meta.meetingMeta = meetingMeta.pbType
        }
        return meta
    }
}

extension MeetingMeta {
    var pbType: PBMeetingMeta {
        var meta = PBMeetingMeta()
        meta.meetingID = meetingID
        if let breakoutRoomID = breakoutRoomID,
           !breakoutRoomID.isEmpty {
            meta.breakoutRoomID = breakoutRoomID
            meta.metaType = .breakoutRoom
        } else {
            meta.metaType = .meeting
        }
        return meta
    }
}

extension PBGrootCell {
    var vcType: GrootCell {
        .init(action: .init(rawValue: action.rawValue) ?? .unknown, payload: payload, sender: sender.vcType, upVersion: upVersionI64, downVersion: downVersionI64, pageID: pageID, dataType: .init(rawValue: dataType.rawValue) ?? .unknown)
    }
}

extension PBIMNoticeInfo {
    var vcType: IMNoticeInfo {
        .init(meetingId: meetingID, topic: topic, i18NDefaultTopic: .init(i18NKey: i18NDefaultTopic.i18NKey), meetingNumber: meetingNumber, startTime: startTime, attendeeStatus: .init(rawValue: attendeeStatus.rawValue) ?? .unknown, containsMultipleTenant: containsMultipleTenant, sameTenantId: sameTenantID, isCrossWithKa: isCrossWithKa, version: version, meetingSubType: meetingSubType.vcType, allParticipantTenant: allParticipantTenant, meetingSource: meetingSource, rehearsalStatus: rehearsalStatus.vcType, sortTime: sortTime, bindChatID: bindChatID, calendarGroupID: calendarGroupID, videoBotID: videoBotID)
    }
}

// MARK: - cells conversion

extension SketchGrootCell: _NetworkDecodable, NetworkDecodable, _NetworkEncodable, NetworkEncodable {
    typealias ProtobufType = Videoconference_V1_SketchGrootCellPayload
    init(pb: Videoconference_V1_SketchGrootCellPayload) {
        self.init(meetingID: pb.meetingID, units: pb.units)
    }

    func toProtobuf() -> Videoconference_V1_SketchGrootCellPayload {
        var pb = Videoconference_V1_SketchGrootCellPayload()
        pb.meetingID = self.meetingID
        pb.units = self.units
        return pb
    }
}

struct RawGrootCell: NetworkDecodable, NetworkEncodable {
    static var protoName: String = "Data"
    let data: Data

    init(serializedData data: Data) throws {
        self.data = data
    }

    func serializedData() throws -> Data {
        return data
    }
}

extension FollowGrootCell: _NetworkDecodable, _NetworkEncodable, NetworkDecodable, NetworkEncodable {
    typealias ProtobufType = Videoconference_V1_FollowGrootCellPayload
    init(pb: Videoconference_V1_FollowGrootCellPayload) {
        self.init(type: .init(rawValue: pb.type.rawValue) ?? .unknown,
                  patches: pb.patches.map({ $0.vcType }), states: pb.states.map({ $0.vcType }))
    }

    func toProtobuf() -> Videoconference_V1_FollowGrootCellPayload {
        var payload = Videoconference_V1_FollowGrootCellPayload()
        switch type {
        case .patches:
            payload.type = .patches
            payload.patches = patches.map({ $0.pbType })
        case .states:
            payload.type = .states
            payload.states = states.map({ $0.pbType })
        default:
            payload.type = .unknown
        }
        return payload
    }
}

extension TabListGrootCell: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VCTabListGrootCellPayload
    init(pb: Videoconference_V1_VCTabListGrootCellPayload) {
        self.init(insertTopItems: pb.insertTopItems.map({ $0.vcType }),
                  updateItems: pb.updateItems.map({ $0.vcType }),
                  deletedHistoryIds: pb.deletedHistoryIds,
                  calInsertTopItems: pb.calInsertTopItems.map({ $0.vcType }),
                  calUpdateItems: pb.calUpdateItems.map({ $0.vcType }),
                  calDeletedHistoryIds: pb.calDeletedHistoryIds,
                  enterpriseInsertTopItems: pb.enterpriseInsertTopItems.map({ $0.vcType }),
                  enterpriseUpdateItems: pb.enterpriseUpdateItems.map({ $0.vcType }),
                  enterpriseDeletedHistoryIds: pb.enterpriseDeletedHistoryIds)
    }
}

extension TabUserGrootCell: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VCTabUserGrootCellPayload
    init(pb: Videoconference_V1_VCTabUserGrootCellPayload) {
        self.init(changeType: .init(rawValue: pb.changeType.rawValue) ?? .missedCall,
                  missedCallInfo: pb.hasMissedCallInfo ? pb.missedCallInfo.vcType : nil,
                  detailPageEvents: pb.detailPageEvents.map({ $0.vcType }),
                  statisticsInfo: pb.hasStatisticsInfo ? pb.statisticsInfo.vcType : nil,
                  checkinInfo: pb.hasCheckInInfo ? pb.checkInInfo.vcType : nil,
                  chatHistoryV2: pb.hasImInfoV2 ? pb.imInfoV2.vcType : nil,
                  voteStatisticsInfo: pb.hasVoteStatisticsInfo ? pb.voteStatisticsInfo.vcType : nil)
    }
}

extension TabMeetingGrootCell: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VCTabMeetingGrootCellPayload
    init(pb: Videoconference_V1_VCTabMeetingGrootCellPayload) {
        self.init(changes: pb.changes.map({ $0.vcType }))
    }
}

extension VCNoticeGrootCell: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = Videoconference_V1_VCNoticeGrootCellPayload
    init(pb: Videoconference_V1_VCNoticeGrootCellPayload) {
        self.init(upsertImNoticeInfo: pb.upsertImNoticeInfo.vcType, dismissNoticeMeetingId: pb.dismissNoticeMeetingID, version: pb.version)
    }
}
