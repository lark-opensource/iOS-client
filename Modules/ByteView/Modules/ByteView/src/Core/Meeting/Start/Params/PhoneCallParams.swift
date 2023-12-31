//
//  PhoneCallParams.swift
//  ByteView
//
//  Created by kiri on 2023/6/19.
//

import Foundation

public struct PhoneCallParams: Equatable, CustomStringConvertible {
    let id: String
    let idType: IdType
    let calleeId: String?
    let calleeName: String?
    let calleeAvatarKey: String?

    public init(id: String, idType: IdType, calleeId: String? = nil, calleeName: String? = nil, calleeAvatarKey: String? = nil) {
        self.id = id
        self.idType = idType
        self.calleeId = calleeId
        self.calleeName = calleeName
        self.calleeAvatarKey = calleeAvatarKey
    }

    public enum IdType: String, Equatable, CustomStringConvertible {
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

    public var description: String {
        "PhoneCallParams(id: \(idType.isPhoneNumber ? "phoneNumber" : id), idType: \(idType), calleeId: \(calleeId), hasName: \(calleeName != nil), hasAvatar: \(calleeAvatarKey != nil))"
    }

    func displayName(candidateName: String? = nil) -> String {
        if let name = candidateName, !name.isEmpty {
            return name
        }
        if let name = self.calleeName, !name.isEmpty {
            return name
        }
        if self.idType.isPhoneNumber {
            return self.id
        }
        return ""
    }
}
