//
//  PSTNInfo.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/11/18.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation

/// Videoconference_V1_PSTNInfo
public struct PSTNInfo: Equatable {
    public var participantType: ParticipantType
    public var mainAddress: String
    public var subAddress: String
    public var displayName: String
    public var bindId: String
    public var bindType: BindType
    public var pstnSubType: PSTNSubType

    public enum BindType: Int, Hashable {
        case unknown = 0 // = 0
        case lark // = 1
        case people // = 2
    }
    public enum PSTNSubType: Int, Hashable {
        case unknownSubtype // = 0
        case ipPhone // = 1
        case enterprisePhone // = 2
        case recruitmentPhone // = 3
    }

    public init(participantType: ParticipantType,
                mainAddress: String,
                subAddress: String,
                displayName: String,
                bindId: String,
                bindType: BindType,
                pstnSubType: PSTNSubType) {
        self.participantType = participantType
        self.displayName = displayName
        self.mainAddress = mainAddress
        self.subAddress = subAddress
        self.bindId = bindId
        self.bindType = bindType
        self.pstnSubType = pstnSubType
    }

    public init() {
        self.init(participantType: .unknown, mainAddress: "", subAddress: "", displayName: "", bindId: "", bindType: .unknown, pstnSubType: .unknownSubtype)
    }

    public init(sipAddress: String) {
        self.init(participantType: .sipUser, mainAddress: sipAddress, subAddress: "", displayName: "", bindId: "", bindType: .unknown, pstnSubType: .unknownSubtype)
    }

    public init(pstnAddress: String, displayName: String) {
        self.init(participantType: .pstnUser, mainAddress: pstnAddress, subAddress: "", displayName: displayName, bindId: "", bindType: .unknown, pstnSubType: .unknownSubtype)
    }

    public init(conveniencePstnId: String, displayName: String) {
        self.init(participantType: .pstnUser, mainAddress: "", subAddress: "", displayName: displayName, bindId: conveniencePstnId, bindType: .lark, pstnSubType: .unknownSubtype)
    }

    public init(participantType: ParticipantType, mainAddress: String, displayName: String = "") {
        self.init(participantType: participantType, mainAddress: mainAddress, subAddress: "", displayName: displayName, bindId: "", bindType: .unknown, pstnSubType: .unknownSubtype)
    }
}

extension PSTNInfo.BindType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "unknown"
        case .lark:
            return "lark"
        case .people:
            return "people"
        }
    }
}

extension PSTNInfo: CustomStringConvertible {
    public var description: String {
        String(
            indent: "PSTNInfo",
            "participantType: \(participantType)",
            "bind: (\(bindType), \(bindId))",
            "pstnSubType: \(pstnSubType)"
        )
    }
}
