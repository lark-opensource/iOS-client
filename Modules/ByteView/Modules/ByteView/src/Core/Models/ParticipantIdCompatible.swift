//
//  ParticipantIdCompatible.swift
//  ByteView
//
//  Created by kiri on 2021/9/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

extension ParticipantIdConvertible {
    var identifier: String {
        participantId.identifier
    }
}

extension FollowInfo: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        user.participantId
    }
}

extension LobbyParticipant: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        ParticipantId(id: user.participantId.id, type: user.participantId.type,
                      deviceId: user.participantId.deviceId, bindInfo: BindInfo(id: bindId, type: bindType))
    }
}

extension PreLobbyParticipant: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        user.participantId
    }
}

extension VideoChatInfo {

    var inviterPid: ParticipantId {
        switch type {
        case .meet:
            return ParticipantId(id: inviterId, type: inviterType)
        default:
            return host.participantId
        }
    }
}

extension MeetingSubtitleData: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        if let pstnInfo = source.pstnInfo, pstnInfo.bindType == .lark, pstnInfo.bindId.isEmpty == false {
            let bindInfo = BindInfo(id: pstnInfo.bindId, type: pstnInfo.bindType)
            return ParticipantId(id: user.id, type: user.type, deviceId: user.deviceId, bindInfo: bindInfo)
        }
        return ParticipantId(id: user.id, type: user.type, deviceId: user.deviceId)
    }

    var user: ByteviewUser {
        if let event = event {
            return event.user
        } else {
            return source.speaker
        }
    }
}

extension ScreenSharedData: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        participant.participantId
    }
}

extension PullCardInfoResponse.MeetingParticipant: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        return ParticipantId(id: userID, type: userType, bindInfo: BindInfo(id: bindID, type: bindType))
    }
}

extension MagicShareDocument: ParticipantIdConvertible {
    var participantId: ParticipantId {
        user.participantId
    }
}

extension InMeetingData.HostTransferredData: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        host.participantId
    }
}

extension VideoChatParticipant: ParticipantIdConvertible {
    public var participantId: ParticipantId {
        ParticipantId(id: userID, type: type, deviceId: deviceID)
    }

    var pid: ByteviewUser {
        ByteviewUser(id: userID, type: type, deviceId: deviceID)
    }
}

extension Dictionary where Key == String, Value == I18nKeyInfo.I18nParam {
    var pid: ParticipantId? {
        guard let uid = values.filter({ $0.type == .userID }).map({ $0.val }).first else { return nil }
        let did = values.filter { $0.type == .deviceID }.map { $0.val }.first
        var type: ParticipantType?
        if let typeVal = values.filter({ $0.type == .userType }).map({ $0.val }).first, let rawValue = Int(typeVal) {
            type = ParticipantType(rawValue: rawValue)
        }
        return ParticipantId(id: uid, type: type ?? .larkUser, deviceId: did ?? "0", bindInfo: nil)
    }
}

extension Dictionary where Key == String, Value == String {
    var pid: ParticipantId? {
        guard let uid = self["user_id"] else { return nil }
        let did = self["device_id"]
        var type: ParticipantType?
        if let typeVal = self["user_type"], let rawValue = Int(typeVal) {
            type = ParticipantType(rawValue: rawValue)
        }
        return ParticipantId(id: uid, type: type ?? .larkUser, deviceId: did ?? "0", bindInfo: nil)
    }
}
