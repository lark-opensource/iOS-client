//
//  InMeetSecurityPickerRow.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/9.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

struct InMeetSecurityPickerRow {
    let identifier: InMeetSecurityPickerCellIdentifier
    let item: InMeetSecurityPickerItem
    var isSelected: Bool = false
    var showsSeparator: Bool = true

    init(item: InMeetSecurityPickerItem, selectedData: InMeetSecurityPickerSelectedData, showsSeparator: Bool = true) {
        self.identifier = item.cellIdentifier
        self.item = item
        self.isSelected = selectedData.isSelected(item)
        self.showsSeparator = showsSeparator
    }
}

struct InMeetSecurityPickerCellIdentifier {
    let identifier: String
    let cellType: UITableViewCell.Type

    static let user = InMeetSecurityPickerCellIdentifier(identifier: "user", cellType: InMeetSecurityPickerUserCell.self)
    static let group = InMeetSecurityPickerCellIdentifier(identifier: "group", cellType: InMeetSecurityPickerUserCell.self)
    static let room = InMeetSecurityPickerCellIdentifier(identifier: "room", cellType: InMeetSecurityPickerUserCell.self)
    static let calendar = InMeetSecurityPickerCellIdentifier(identifier: "calendar", cellType: InMeetSecurityPickerCalendarGuestCell.self)
    static let calendarHeader = InMeetSecurityPickerCellIdentifier(identifier: "calendarHeader", cellType: InMeetSecurityPickerCalendarCell.self)
}

enum InMeetSecurityPickerItem {
    case user(RecommandUser)
    case group(Chat)
    case room(ParticipantUserInfo)
    case search(SearchUsersAndChatsResponse.UserAndCardItem)
    case calendarGuest(GetCalendarGuestListResponse.Result)
    case calendarHeader(CalendarHeaderInfo)

    enum TypeEnum: Equatable {
        case user
        case group
        case room
        case calendarGuest
        case calendarHeader
    }

    struct CalendarHeaderInfo {
        var isExpanded: Bool
        var status: GetCalendarGuestListResponse.Status
    }

    struct RecommandUser {
        let user: ParticipantUserInfo
        let isCrossTenant: Bool
        var collaborationType: LarkUserCollaborationType
        var tenantName: String?

        var id: String { user.id }
    }

    var cellIdentifier: InMeetSecurityPickerCellIdentifier {
        switch self {
        case .user, .group, .room, .search:
            return .user
        case .calendarGuest:
            return .calendar
        case .calendarHeader:
            return .calendarHeader
        }
    }

    var id: String {
        switch self {
        case .user(let info):
            return info.id
        case .group(let info):
            return info.id
        case .room(let info):
            return info.id
        case .search(let info):
            return info.id
        case .calendarGuest(let info):
            return info.user.id
        case .calendarHeader:
            return ""
        }
    }

    var type: TypeEnum {
        switch self {
        case .user:
            return .user
        case .room:
            return .room
        case .group:
            return .group
        case .search(let item):
            switch item.idType {
            case .chat:
                return .group
            case .room:
                return .room
            default:
                return .user
            }
        case .calendarGuest:
            return .calendarGuest
        case .calendarHeader:
            return .calendarHeader
        }
    }

    var avatarInfo: AvatarInfo {
        switch self {
        case .user(let user):
            return user.user.avatarInfo
        case .group(let chat):
            return .remote(key: chat.avatarKey, entityId: chat.id)
        case .room(let room):
            return room.avatarInfo
        case .search(let item):
            return item.avatarInfo
        case .calendarGuest(let item):
            if let user = item.larkUserInfo {
                return .remote(key: user.avatarKey, entityId: item.user.id)
            } else if let room = item.roomUserInfo {
                return .remote(key: room.avatarKey, entityId: item.user.id)
            } else if let group = item.chatInfo {
                return .remote(key: group.avatarKey, entityId: String(group.chatID))
            }
            return .unknown
        case .calendarHeader:
            return .asset(BundleResources.ByteViewSetting.Settings.iconAvatarCalendarColorful)
        }
    }

    var title: NSAttributedString {
        switch self {
        case .user(let user):
            return .securityTitle(user.user.name)
        case .group(let chat):
            return .securityTitle(chat.name)
        case .room(let room):
            return .securityTitle(room.room?.primaryName ?? room.name)
        case .search(let item):
            return item.attributedTitle
        case .calendarGuest(let item):
            if let user = item.larkUserInfo {
                return .securityTitle(user.userName)
            } else if let room = item.roomUserInfo {
                return .securityTitle(room.fullName)
            } else if let group = item.chatInfo {
                return .securityTitle("\(group.chatName)")
            }
            return .securityTitle("")
        case .calendarHeader:
            return .securityTitle(I18n.View_G_EventGuests)
        }
    }

    var subtitle: NSAttributedString? {
        switch self {
        case .user, .room, .calendarHeader:
            return nil
        case .group(let chat):
            return .securitySubtitle(chat.desc)
        case .search(let item):
            return item.attributedSubtitle
        case .calendarGuest(let item):
            if let user = item.larkUserInfo {
                return .securitySubtitle(user.department)
            } else if let room = item.roomUserInfo {
                return .securitySubtitle(room.location.buildingName)
            }
            return nil
        }
    }
}

struct InMeetSecurityPickerSelectedData {
    var hasCalendarGuests: Bool = true
    var userIds: [String] = []
    var groupIds: [String] = []
    var roomIds: [String] = []
    var items: [InMeetSecurityPickerItem] = []

    var count: Int {
        (hasCalendarGuests ? 1 : 0) + userIds.count + groupIds.count + roomIds.count
    }

    func isSelected(_ item: InMeetSecurityPickerItem) -> Bool {
        let itemId = item.id
        let itemType = item.type
        switch itemType {
        case .user:
            return userIds.contains(itemId)
        case .group:
            return groupIds.contains(itemId)
        case .room:
            return roomIds.contains(itemId)
        case .calendarGuest:
            return false
        case .calendarHeader:
            return hasCalendarGuests
        }
    }

    mutating func toggleSelection(_ item: InMeetSecurityPickerItem) {
        let itemId = item.id
        let itemType = item.type
        switch itemType {
        case .user:
            if userIds.contains(itemId) {
                userIds.removeAll(where: { $0 == itemId })
                items.removeAll(where: { $0.id == itemId && $0.type == itemType })
            } else {
                userIds.append(itemId)
                items.append(item)
            }
        case .group:
            if groupIds.contains(itemId) {
                groupIds.removeAll(where: { $0 == itemId })
                items.removeAll(where: { $0.id == itemId && $0.type == itemType })
            } else {
                groupIds.append(itemId)
                items.append(item)
            }
        case .room:
            if roomIds.contains(itemId) {
                roomIds.removeAll(where: { $0 == itemId })
                items.removeAll(where: { $0.id == itemId && $0.type == itemType })
            } else {
                roomIds.append(itemId)
                items.append(item)
            }
        case .calendarHeader:
            if hasCalendarGuests {
                hasCalendarGuests = false
                items.removeAll(where: {
                    if case .calendarHeader = $0 {
                        return true
                    } else {
                        return false
                    }
                })
            } else {
                hasCalendarGuests = true
                items.insert(item, at: 0)
            }
        default:
            break
        }
    }

    mutating func unselectItems(_ items: [InMeetSecurityPickerItem]) {
        items.forEach { item in
            let itemId = item.id
            let itemType = item.type
            self.items.removeAll(where: { $0.id == itemId && $0.type == itemType })
            switch item {
            case .user:
                userIds.removeAll(where: { $0 == itemId })
            case .group:
                groupIds.removeAll(where: { $0 == itemId })
            case .room:
                roomIds.removeAll(where: { $0 == itemId })
            case .calendarHeader:
                hasCalendarGuests = false
                if let first = self.items.first, case .calendarHeader = first {
                    self.items.removeFirst()
                }
            default:
                break
            }

        }
    }
}

private extension SearchUsersAndChatsResponse.UserAndCardItem {
    var avatarInfo: AvatarInfo {
        .remote(key: self.imageKey, entityId: self.id)
    }

    var attributedTitle: NSAttributedString {
        switch self.idType {
        case .chat, .user:
            return Self.attributedText(text: self.name, config: .h4, withHitTerms: self.hitTerms)
        default:
            return .securityTitle(self.name)
        }
    }

    var attributedSubtitle: NSAttributedString? {
        switch self.idType {
        case .chat, .user:
            return Self.attributedText(text: self.desc, config: .bodyAssist, withHitTerms: self.subtitleHitTerms)
        default:
            return NSAttributedString(string: self.desc, config: .bodyAssist)
        }
    }

    static func attributedText(text: String, config: VCFontConfig, withHitTerms terms: [String]) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text, config: config, lineBreakMode: .byTruncatingTail)
        terms.forEach { (term) in
            var searchRange = NSRange(location: 0, length: text.count)
            let maxSearchTime = 2  // 和产品同学沟通，为了提高匹配效率，一个hitTerm最多匹配2次
            var searchTime = 0
            while searchRange.location < text.count, searchTime < maxSearchTime {
                searchTime += 1
                let foundRange = (text as NSString).range(of: term, options: [.caseInsensitive], range: searchRange)
                if foundRange.location != NSNotFound {
                    attributedString.addAttribute(.foregroundColor, value: UIColor.ud.primaryPri500, range: foundRange)
                    searchRange.location = foundRange.location + foundRange.length
                    searchRange.length = text.count - searchRange.location
                } else {
                    break
                }
            }
        }
        return attributedString
    }
}

private extension NSAttributedString {
    static func securityTitle(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, config: .h4, lineBreakMode: .byTruncatingTail)
    }

    static func securitySubtitle(_ string: String) -> NSAttributedString {
        NSAttributedString(string: string, config: .bodyAssist, lineBreakMode: .byTruncatingTail)
    }
}
