//
//  ParticipantAbbrInfo.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/13.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// 参会人简化信息
/// - Videoconference_V1_VCParticipantAbbrInfo
public struct ParticipantAbbrInfo: Equatable {

    public var user: ByteviewUser

    public var status: Participant.Status

    public var deviceType: Participant.DeviceType

    public var joinTimeMs: Int64

    /// 参会人所属租户ID
    public var tenantID: Int64

    /// 是否游客入会
    public var isLarkGuest: Bool

    public var bindID: String

    public var bindType: PSTNInfo.BindType

    public var usedCallMe: Bool
}
