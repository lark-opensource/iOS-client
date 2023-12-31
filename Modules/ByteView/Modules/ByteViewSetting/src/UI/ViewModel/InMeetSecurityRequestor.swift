//
//  MeetingSecurityRequestor.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/5/8.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

protocol InMeetSecurityRequestorDelegate: AnyObject {
    func didUpdateSecurityUsers(for setting: VideoChatSettings.SecuritySetting)
}

final class InMeetSecurityRequestor {
    private let setting: MeetingSettingManager
    var meetingId: String { setting.meetingId }
    var requestCache: MeetingSettingRequestCache { setting.requestCache }
    var httpClient: HttpClient { setting.service.httpClient }
    weak var delegate: InMeetSecurityRequestorDelegate?
    init(setting: MeetingSettingManager) {
        self.setting = setting
    }

    @RwAtomic private var securitySetting: VideoChatSettings.SecuritySetting?
    @RwAtomic private(set) var value = UserValue(key: .init(groupIds: [], userIds: [], roomIds: []))

    var isRequesting: Bool { value.isRequesting }
    var names: [String] {
        value.groups.map({ $0.name }) + value.users.map({ $0.name }) + value.rooms.compactMap({ $0.room?.primaryName })
    }

    func updateSecuritySetting(_ setting: VideoChatSettings.SecuritySetting, completion: ((UserValue) -> Void)? = nil) {
        self.securitySetting = setting
        let key = UserKey(groupIds: setting.groupIds, userIds: setting.userIds, roomIds: setting.roomIds)
        if self.value.key == key {
            completion?(self.value)
            return
        }

        self.value = UserValue(key: key)
        if key.isEmpty {
            completion?(self.value)
            return
        }

        self._fetchUserInfos(key) { [weak self] isAsyncCallback, value in
            if let self = self, self.value.key == key {
                self.value = value
                if isAsyncCallback { // 非异步回调不代理出去，避免UI重复刷新
                    self.delegate?.didUpdateSecurityUsers(for: setting)
                }
            }
            completion?(value)
        }
    }

    func fetchUserInfos(_ key: UserKey, completion: @escaping (UserValue) -> Void) {
        self._fetchUserInfos(key) { _, value in
            completion(value)
        }
    }

    private func _fetchUserInfos(_ key: UserKey, completion: @escaping (Bool, UserValue) -> Void) {
        var value = UserValue(key: key)
        if key.isEmpty {
            completion(false, value)
            return
        }

        let participantService = httpClient.participantService
        let batch = DispatchGroup()
        if !key.groupIds.isEmpty {
            batch.enter()
            self.requestCache.fetchGroups(key.groupIds) {
                value.setGroups($0, for: key.groupIds)
                batch.leave()
            }
        }
        if !key.userIds.isEmpty {
            batch.enter()
            participantService.participantInfo(pids: key.userIds.map({ ByteviewUser(id: $0, type: .larkUser) }), meetingId: self.meetingId) {
                value.setUsers($0, for: key.userIds)
                batch.leave()
            }
        }
        if !key.roomIds.isEmpty {
            batch.enter()
            participantService.participantInfo(pids: key.roomIds.map({ ByteviewUser(id: $0, type: .room) }), meetingId: self.meetingId) {
                value.setRooms($0, for: key.roomIds)
                batch.leave()
            }
        }
        if value.isRequesting {
            batch.notify(queue: .main) {
                completion(true, value)
            }
        } else {
            completion(false, value)
        }
    }

    struct UserKey: Equatable {
        let groupIds: [String]
        let userIds: [String]
        let roomIds: [String]

        var isEmpty: Bool {
            groupIds.isEmpty && userIds.isEmpty && roomIds.isEmpty
        }
    }

    struct UserValue {
        let key: UserKey
        private(set) var groups: [Chat] = []
        private(set) var users: [ParticipantUserInfo] = []
        private(set) var rooms: [ParticipantUserInfo] = []

        private var isRequestingGroups: Bool
        private var isRequestingUsers: Bool
        private var isRequestingRooms: Bool

        init(key: UserKey) {
            self.key = key
            self.isRequestingGroups = !key.groupIds.isEmpty
            self.isRequestingUsers = !key.userIds.isEmpty
            self.isRequestingRooms = !key.roomIds.isEmpty
        }

        var isRequesting: Bool {
            isRequestingGroups || isRequestingUsers || isRequestingRooms
        }

        mutating func setGroups(_ groups: [Chat], for ids: [String]) {
            if Set(key.groupIds) == Set(ids) {
                self.groups = groups
                self.isRequestingGroups = false
            }
        }

        mutating func setUsers(_ users: [ParticipantUserInfo], for ids: [String]) {
            if Set(key.userIds) == Set(ids) {
                self.users = users
                self.isRequestingUsers = false
            }
        }

        mutating func setRooms(_ rooms: [ParticipantUserInfo], for ids: [String]) {
            if Set(key.roomIds) == Set(ids) {
                self.rooms = rooms
                self.isRequestingRooms = false
            }
        }
    }
}
