// swiftlint:disable line_length
//
//  SearchRequestor.swift
//  ByteView
//
//  Created by kiri on 2020/9/20.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import ByteViewCommon
import ByteViewNetwork

enum SearchMeta {
    case chatter(SearchedUser)
    case chat(SearchedGroup)
    case room(SearchedRoom)
}

struct VideoSearchResult {
    let searchMeta: SearchMeta
}

struct SearchCallBack {
    var hasMore: Bool
    var searchResults: [VideoSearchResult]

    init(hasMore: Bool, searchResults: [VideoSearchResult]) {
        self.hasMore = hasMore
        self.searchResults = searchResults
    }
}

extension SearchParticipantResponse.SearchResult {
    func toUser(canShowExternal: Bool) -> SearchedUser? {
        guard user.type.isUserType else { return nil }
        let convertedStatus = searchedUserStatus
        let id = (convertedStatus == .inMeeting || convertedStatus == .waiting) ? user.deviceId : user.id
        let isExternal = larkUserInfo?.crossTenant == true && canShowExternal
        return SearchedUser(id: id,
                            isExternal: isExternal,
                            name: name,
                            avatarInfo: .remote(key: avatarKey, entityId: id),
                            workStatus: larkUserInfo?.workStatus ?? .default,
                            byteviewUser: user,
                            description: larkUserInfo?.department,
                            status: convertedStatus,
                            unsupportedRtcVersion: larkUserInfo?.versionSupport == false,
                            executiveMode: larkUserInfo?.executiveMode ?? false,
                            participant: participant,
                            lobbyParticipant: lobby,
                            collaborationType: larkUserInfo?.collaborationType,
                            crossTenant: larkUserInfo?.crossTenant,
                            customStatuses: larkUserInfo?.customStatuses ?? [])
    }

    func toRoom() -> SearchedRoom? {
        switch user.type {
        case .room:
            return toPlainRoom()
        case .sipUser:
            return toSipRoom()
        default:
            return nil
        }
    }

    private func toPlainRoom() -> SearchedRoom {
        let convertedStatus = searchedUserStatus
        let id = (convertedStatus == .inMeeting || convertedStatus == .waiting) ? user.deviceId : user.id
        return SearchedRoom(id: id,
                            name: name,
                            avatarInfo: .remote(key: avatarKey, entityId: id),
                            byteviewUser: user,
                            title: roomInfo?.primaryNameParticipant ?? "",
                            subtitle: roomInfo?.secondaryName ?? "",
                            status: convertedStatus,
                            participant: participant,
                            lobbyParticipant: lobby,
                            relationTagWhenRing: nil)
    }

    private func toSipRoom() -> SearchedRoom {
        let convertedStatus = searchedUserStatus
        let id = (convertedStatus == .inMeeting || convertedStatus == .waiting) ? user.deviceId : user.id
        return SearchedRoom(id: id,
                            name: name,
                            avatarInfo: .remote(key: avatarKey, entityId: id),
                            byteviewUser: user,
                            title: sipInfo?.primaryName ?? "",
                            subtitle: sipInfo?.secondaryName ?? "",
                            status: convertedStatus,
                            participant: participant,
                            lobbyParticipant: lobby,
                            sipAddress: sipInfo?.address,
                            relationTagWhenRing: nil)
    }

    func toVideoSearchResult(canShowExternal: Bool) -> VideoSearchResult? {
        if let user = toUser(canShowExternal: canShowExternal) {
            return VideoSearchResult(searchMeta: .chatter(user))
        } else if let room = toRoom() {
            return VideoSearchResult(searchMeta: .room(room))
        }
        return nil
    }

    private var searchedUserStatus: SearchedUserStatus {
        switch (status, self.participant?.status) {
        case (.inMeeting, .ringing):
            return .inviting
        case (.inMeeting, .onTheCall):
            return .inMeeting
        case (.inMeeting, .idle), (.notInMeeting, _):
            return .idle
        case (.inLobby, _):
            return .waiting
        default:
            return .busy
        }
    }
}
