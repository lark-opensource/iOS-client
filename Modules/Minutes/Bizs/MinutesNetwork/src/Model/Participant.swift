//
//  Participant.swift
//  LarkMinutesAPI
//
//  Created by lvdaqian on 2021/1/11.
//

import Foundation

public enum UserType: Int, Codable, ModelEnum {
    public static var fallbackValue: UserType = .unknown

    case unknow = 0
    case lark = 1
    case room = 2
    case doc = 3
    case neo = 4
    case neoGuest = 5
    case pstn = 6
    case sip = 7
    case reserve1
    case reserve2
    case reserve3
    case reserve4
    case reserve5
    case says = 59
    case guest = 99
    case autoDetect = 100
    case roomDetect = 101
    case sidDetect = 102
    case unknown = -999
}

public struct DisplayTag: Codable, Hashable {
    public let tagType: Int
    public let tagValue: TagValue?
    public struct TagValue: Codable, Hashable {
        public let value: String?
        public let i18nValue: I18NValue?
        
        public struct I18NValue: Codable, Hashable {
            public let zh: String?
            public let en: String?
            public let ja: String?
            
            private enum CodingKeys: String, CodingKey {
                case zh = "zh_cn"
                case en = "en_us"
                case ja = "ja_jp"
            }
            
            public func hash(into hasher: inout Hasher) {
                hasher.combine("\(zh)" + "\(en)" + "\(ja)")
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case value = "value"
            case i18nValue = "i18n_value"
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(value)
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case tagType = "tag_type"
        case tagValue = "tag_value"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(tagType)
    }
}


public struct Participant: Codable, Hashable {

    public struct Room: Codable, Hashable {
        public let avatarUrl: String

        enum CodingKeys: String, CodingKey {
            case avatarUrl = "avatar_url"
        }
    }

    public init(userID: String, deviceID: String?, userType: UserType?, userName: String, avatarURL: URL?, avatarKey: String? = nil, isExternal: Bool? = nil, isHostUser: Bool? = nil, actionId: String? = nil, tenantId: Int? = nil, tenantName: String? = nil, departmentName: String? = nil, isInParticipants: Bool? = nil, origVersion: Int? = nil, newVersion: Int? = nil, paragraphIds: [String]? = nil, isParagraphSpeaker: Bool? = nil, originUserId: Int? = nil, iconType: Int? = nil, marker: SpeakerMarker? = nil, isBind: Bool? = nil, bindID: String? = nil, displayTag: DisplayTag? = nil, roomInfo: Room? = nil) {
        self.userID = userID
        self.deviceID = deviceID
        self.userType = userType ?? .unknow
        self.userName = userName
        self.avatarKey = avatarKey
        self.avatarURL = avatarURL ?? URL(fileURLWithPath: "")
        self.isExternal = isExternal
        self.isHostUser = isHostUser
        self.actionId = actionId
        self.tenantId = tenantId
        self.tenantName = tenantName
        self.departmentName = departmentName
        self.isInParticipants = isInParticipants
        self.origVersion = origVersion
        self.newVersion = newVersion
        self.paragraphIds = paragraphIds
        self.isParagraphSpeaker = isParagraphSpeaker
        self.originUserId = originUserId
        self.iconType = iconType
        self.marker = marker
        self.isBind = isBind
        self.bindID = bindID
        self.displayTag = displayTag
        self.roomInfo = roomInfo
    }

    public let userID: String
    public let deviceID: String?
    public let userType: UserType
    public let userName: String
    public let avatarKey: String?
    public let avatarURL: URL
    public let isExternal: Bool?
    public let isHostUser: Bool?
    public let actionId: String?
    public let tenantId: Int?
    public let tenantName: String?
    public let departmentName: String?
    public let isInParticipants: Bool?
    public var origVersion: Int?
    public var newVersion: Int?
    public var paragraphIds: [String]?
    public var isParagraphSpeaker: Bool?
    public var originUserId: Int?
    public var iconType: Int?
    public var marker: SpeakerMarker?
    public var isBind: Bool?
    public var bindID: String?
    public let displayTag: DisplayTag?
    public let roomInfo: Room?

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case deviceID = "device_id"
        case userType = "user_type"
        case userName = "user_name"
        case avatarKey = "avatar_key"
        case avatarURL = "avatar_url"
        case isExternal = "is_external"
        case isHostUser = "is_host_user"
        case actionId = "action_id"
        case tenantId = "tenant_id"
        case tenantName = "tenant_name"
        case departmentName = "department_name"
        case isInParticipants = "is_in_participants"
        case paragraphIds = "paragraph_ids"
        case origVersion = "orig_version"
        case newVersion = "new_version"
        case isParagraphSpeaker = "is_paragraph_speaker"
        case originUserId = "origin_user_id"
        case iconType = "icon_type"
        case marker = "marker"
        case isBind = "is_bind"
        case bindID = "bind_id"
        case displayTag = "display_tag"
        case roomInfo = "room_info"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
    }

    public func isSame(to participant: Participant?) -> Bool {
        if let sid = participant?.userID, let sname = participant?.userName {
            return (sid == userID && sname == userName)
        }
        return false
    }
}
