//
//  Participant.swift
//  ByteView
//
//  Created by LUNNER on 2019/1/13.
//

import Foundation
import RxDataSources
import ByteViewCommon
import ByteViewNetwork

enum ParticipantState {
    case joined
    case busy
    case idle
    case inviting
    case waiting
}

enum ParticipantSearchType {
    case user, room
}

class ParticipantSearchBox {
    var type: ParticipantSearchType
    var id: String
    var state: ParticipantState

    /// .joined, .inviting, .waiting, .idle, .busy
    var userInfo: ParticipantUserInfo?

    var disable: Bool {
        return false
    }

    var disabledMessage: String? {
        return nil
    }

    var isJoining: Bool {
        return state == .inviting || state == .waiting
    }

    init(_ type: ParticipantSearchType, id: String, state: ParticipantState) {
        self.type = type
        self.id = id
        self.state = state
    }
}

extension ParticipantSearchBox {
    var userItem: SearchedUser? {
        if let userBox = self as? ParticipantSearchUserBox {
            return userBox.user
        }
        return nil
    }

    var roomItem: SearchedRoom? {
        if let roomBox = self as? ParticipantSearchRoomBox {
            return roomBox.room
        }
        return nil
    }

    var participant: Participant? {
        if let userItem = userItem {
            return userItem.participant
        } else if let roomItem = roomItem {
            return roomItem.participant
        }
        return nil
    }

    var lobbyParticipant: LobbyParticipant? {
        if let userItem = userItem {
            return userItem.lobbyParticipant
        } else if let roomItem = roomItem {
            return roomItem.lobbyParticipant
        }
        return nil
    }

    var name: String? {
        if let userItem = userItem {
            return userItem.name
        } else if let roomItem = roomItem {
            return roomItem.name
        }
        return nil
    }
}

class ParticipantSearchRoomBox: ParticipantSearchBox {
    let room: SearchedRoom
    let highlightPattern: String?

    init(_ room: SearchedRoom, highlightPattern: String?) {
        self.room = room
        self.highlightPattern = highlightPattern
        super.init(.room, id: room.id, state: room.status.toParticipantState())
    }

    override var disable: Bool {
        if state == .busy {
            return true
        }
        return false
    }

    override var disabledMessage: String? {
        if state == .busy {
            return I18n.View_M_MeetingRoomBusy
        }
        return nil
    }
}

class ParticipantSearchUserBox: ParticipantSearchBox {
    let user: SearchedUser
    let highlightPattern: String?

    init(_ user: SearchedUser, highlightPattern: String?) {
        self.user = user
        self.highlightPattern = highlightPattern
        super.init(.user, id: user.id, state: user.status?.toParticipantState() ?? .idle)
    }

    override var disable: Bool {
        if user.executiveMode {
            return true
        } else if user.unsupportedRtcVersion {
            return true
        } else if state == .busy {
            return true
        } else {
            return false
        }
    }

    override var disabledMessage: String? {
        if user.executiveMode {
            return I18n.View_M_AdminRestrictionsInfo
        } else if user.unsupportedRtcVersion {
            return I18n.View_VM_UnsupportedVersion
        } else if state == .busy {
            return I18n.View_M_UserBusy
        } else {
            return nil
        }
    }
}

extension SearchedUserStatus {

    func toParticipantState() -> ParticipantState {
        switch self {
        case .idle: return .idle
        case .busy: return .busy
        case .inMeeting: return .joined
        case .ringing: return .inviting
        case .inviting: return .inviting
        case .waiting: return .waiting
        }
    }
}

extension MatchPaginatedList.MatchResult where T: ParticipantSearchBox {
    func convert() -> SearchContainerView.Status {
        switch self {
        case .loading: return SearchContainerView.Status.loading
        case .noMatch: return SearchContainerView.Status.noResult
        case let .results(_, hasMore): return SearchContainerView.Status.result(hasMore)
        }
    }
}

class ParticipantsSectionModel {

    enum ItemType: Hashable {
        case lobby
        case invite
        case inMeet
        case suggest

        var state: ParticipantState {
            switch self {
            case .lobby: return .waiting
            case .invite: return .inviting
            case .inMeet: return .joined
            case .suggest: return .idle
            }
        }
    }

    var header: String
    var headerIcon: ParticipantImgKey = .empty
    var actionName: String
    var actionEnabled: Bool
    let itemType: ItemType
    /// 折叠状态下为空数组
    var items: [BaseParticipantCellModel]
    /// 真实持有的数据
    var realItems: [BaseParticipantCellModel] {
        if let last = lastItems {
            return last
        }
        return items
    }

    init(header: String,
         headerIcon: ParticipantImgKey = .empty,
         actionName: String = "",
         actionEnabled: Bool = true,
         state: ParticipantState? = nil,
         itemType: ItemType,
         items: [BaseParticipantCellModel]) {
        self.header = header
        self.headerIcon = headerIcon
        self.actionName = actionName
        self.actionEnabled = actionEnabled
        self.itemType = itemType
        self.items = items
    }

    private var lastActionName: String?
    func clearActionName() {
        if "" != actionName {
            lastActionName = actionName
            actionName = ""
        }
    }
    func recoverActionName() {
        if let lastActionName = lastActionName, actionName != lastActionName {
            actionName = lastActionName
            self.lastActionName = nil
        }
    }

    /// 保存折叠状态下的原数据
    private var lastItems: [BaseParticipantCellModel]?
    func clearItems() {
        if [] != items {
            lastItems = items
            items = []
        }
    }
    func recoverItems() {
        if let lastItems = lastItems, items != lastItems {
            items = lastItems
            self.lastItems = nil
        }
    }
}

extension ParticipantsSectionModel: Equatable {
    static func == (lhs: ParticipantsSectionModel, rhs: ParticipantsSectionModel) -> Bool {
        return lhs.header == rhs.header
        && lhs.headerIcon == rhs.headerIcon
        && lhs.actionName == rhs.actionName
        && lhs.actionEnabled == rhs.actionEnabled
        && lhs.itemType == rhs.itemType
        && lhs.items == rhs.items
    }
}

struct ParticipantSearchSectionModel {
    var items: [BaseParticipantCellModel]
}

extension ParticipantSearchSectionModel: SectionModelType {
    init(original: ParticipantSearchSectionModel, items: [BaseParticipantCellModel]) {
        self = original
        self.items = items
    }
}

extension ParticipantSearchSectionModel: Equatable {
    static func == (lhs: ParticipantSearchSectionModel, rhs: ParticipantSearchSectionModel) -> Bool {
        return lhs.items == rhs.items
    }
}

struct InterpretParticipantSectionModel {
    var items: [BaseParticipantCellModel]
}

extension InterpretParticipantSectionModel: SectionModelType {
    init(original: InterpretParticipantSectionModel, items: [BaseParticipantCellModel]) {
        self = original
        self.items = items
    }
}

extension InterpretParticipantSectionModel: Equatable {
    static func == (lhs: InterpretParticipantSectionModel, rhs: InterpretParticipantSectionModel) -> Bool {
        return lhs.items == rhs.items
    }
}
