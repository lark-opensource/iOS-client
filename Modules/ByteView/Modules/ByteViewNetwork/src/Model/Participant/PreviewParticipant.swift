//
//  PreviewParticipant.swift
//  ByteViewNetwork
//
//  Created by kiri on 2023/6/29.
//

import Foundation
import ByteViewCommon

public struct PreviewParticipant: Equatable {
    public let userId: String
    public let userName: String
    public let avatarInfo: AvatarInfo
    public let participantType: ParticipantType
    public let isLarkGuest: Bool
    public let isSponsor: Bool
    public let deviceType: Participant.DeviceType
    public let showDevice: Bool
    public let tenantId: String?
    public let tenantTag: TenantTag?
    public let bindId: String
    public let bindType: PSTNInfo.BindType
    public let showCallme: Bool

    public init(userId: String,
                userName: String,
                avatarInfo: AvatarInfo,
                participantType: ParticipantType,
                isLarkGuest: Bool,
                isSponsor: Bool,
                deviceType: Participant.DeviceType,
                showDevice: Bool,
                tenantId: String?,
                tenantTag: TenantTag?,
                bindId: String,
                bindType: PSTNInfo.BindType,
                showCallme: Bool) {
        self.userId = userId
        self.userName = userName
        self.avatarInfo = avatarInfo
        self.participantType = participantType
        self.isLarkGuest = isLarkGuest
        self.isSponsor = isSponsor
        self.deviceType = deviceType
        self.showDevice = showDevice
        self.tenantId = tenantId
        self.tenantTag = tenantTag
        self.bindId = bindId
        self.bindType = bindType
        self.showCallme = showCallme
    }

    public var isConveniencePSTN: Bool {
        return participantType == .pstnUser && bindType == .lark && !bindId.isEmpty
    }
}
