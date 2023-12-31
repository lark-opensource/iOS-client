//
//  PhoneCallBody.swift
//  ByteViewInterface
//
//  Created by kiri on 2023/6/29.
//

import Foundation

/// 发起办公电话, /client/byteview/phonecall
public struct PhoneCallBody: CodablePathBody {
    public static let path: String = "/client/byteview/phonecall"

    public var id: String
    public var idType: IdType
    public var calleeId: String?
    public var calleeName: String?
    public var calleeAvatarKey: String?

    public init(id: String, idType: IdType, calleeId: String? = nil, calleeName: String? = nil, calleeAvatarKey: String? = nil) {
        self.id = id
        self.idType = idType
        self.calleeId = calleeId
        self.calleeName = calleeName
        self.calleeAvatarKey = calleeAvatarKey
    }

    public enum IdType: String, Equatable, Codable, CustomStringConvertible {
        case candidateId
        case chatId
        case enterprisePhone
        case ipPhone
        case recruitmentPhone
        case telephone

        public var description: String { rawValue }

        var isPhoneNumber: Bool {
            switch self {
            case .ipPhone, .enterprisePhone, .recruitmentPhone, .telephone:
                return true
            default:
                return false
            }
        }
    }
}

extension PhoneCallBody: CustomStringConvertible {
    public var description: String {
        "PhoneCallBody(id: \(idType.isPhoneNumber ? "phoneNumber" : id), idType: \(idType), calleeId: \(calleeId ?? "<nil>"), hasName: \(calleeName != nil), hasAvatar: \(calleeAvatarKey != nil))"
    }
}
