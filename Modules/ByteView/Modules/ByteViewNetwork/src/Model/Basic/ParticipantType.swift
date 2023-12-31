//
//  ParticipantType.swift
//  ByteViewCommon
//
//  Created by kiri on 2021/9/24.
//

import Foundation

/// Videoconference_V1_ParticipantType
public struct ParticipantType: RawRepresentable, Hashable, Comparable, Codable {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static var reservedUserRange: Range<ParticipantType> {
        ParticipantType(rawValue: 8)..<ParticipantType(rawValue: 28)
    }

    public static func < (lhs: ParticipantType, rhs: ParticipantType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public extension ParticipantType {
    // disable-lint: magic number
    /// = 0
    static let unknown = ParticipantType(rawValue: 0)
    /// = 1
    static let larkUser = ParticipantType(rawValue: 1)
    /// = 2
    static let room = ParticipantType(rawValue: 2)
    /// = 3
    static let docUser = ParticipantType(rawValue: 3)
    /// = 4
    static let neoUser = ParticipantType(rawValue: 4)
    /// = 5
    static let neoGuestUser = ParticipantType(rawValue: 5)
    /// = 6
    static let pstnUser = ParticipantType(rawValue: 6)
    /// = 7
    static let sipUser = ParticipantType(rawValue: 7)
    /// = 8, reservedUser1
    static let shareboxUser = ParticipantType(rawValue: 8)
    /// = 10, reservedUser3
    static let xiaofeiBot = ParticipantType(rawValue: 10)
    /// = 11, reservedUser4
    static let standaloneVcUser = ParticipantType(rawValue: 11)
    /// = 12, reservedUser5
    static let h323User = ParticipantType(rawValue: 12)
    // enable-lint: magic number
    var isUserType: Bool {
        if ParticipantType.reservedUserRange.contains(self) {
            return true
        }
        switch self {
        case .larkUser, .neoUser, .neoGuestUser, .pstnUser, .docUser:
            return true
        default:
            return false
        }
    }
}

extension ParticipantType: CustomStringConvertible {

    public var description: String {
        switch self {
        case .larkUser:
            return "larkUser"
        case .room:
            return "room"
        case .docUser:
            return "docUser"
        case .neoUser:
            return "neoUser"
        case .neoGuestUser:
            return "neoGuestUser"
        case .pstnUser:
            return "pstnUser"
        case .sipUser:
            return "sipUser"
        case .xiaofeiBot:
            return "xiaofeiBot"
        case .standaloneVcUser:
            return "standaloneVcUser"
        case .h323User:
            return "h323User"
        default:
            return "unknown(\(rawValue))"
        }
    }
}
