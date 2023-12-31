//
//  InMeetParticipantStrategy.swift
//  ByteView
//
//  Created by Prontera on 2021/11/1.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

func meetingRoleStrategyWith(meetingSource: VideoChatInfo.MeetingSource, selfRole: ParticipantRole) -> MeetingRoleStrategy {
    switch (meetingSource, selfRole) {
    case (.vcFromInterview, .interviewee):
        return CandidateMeetingRoleStrategy()
    case (.vcFromInterview, .interviewer), (.vcFromInterview, .unknown):
        return InterviewerMeetingRoleStrategy()
    default:
        return DefaultMeetingRoleStrategy()
    }
}

final class InMeetParticipantStrategy: ParticipantStrategy {

    let roleStrategy: MeetingRoleStrategy
    let lock = NSLock()
    var participantRoleMap: [ByteviewUser: ParticipantRole] = [:]
    var participantNicknameMap: [ByteviewUser: String] = [:]
    /// 设备维度
    var participantInMeetingNameMap: [ByteviewUser: String] = [:]
    var enableAnotherName: Bool
    let startParams: ParticipantStrategyKey
    var meetingId: String { startParams.meetingId }
    var chattersInfoDidClear: ((Set<String>) -> Void)?

    init(params: ParticipantStrategyKey, participants: [Participant], roleStrategy: MeetingRoleStrategy, isShowAnotherNameEnabled: Bool) {
        self.startParams = params
        self.roleStrategy = roleStrategy
        self.enableAnotherName = isShowAnotherNameEnabled
        for p in participants {
            self.participantRoleMap[p.user] = p.role
            self.participantNicknameMap[p.user] = p.settings.nickname
            self.participantInMeetingNameMap[p.user] = p.settings.inMeetingName
        }
        Push.chatters.inUser(params.userId).addObserver(self) { [weak self] in
            self?.didReceiveChatters($0.users)
        }
    }

    func updateParticipant(_ ap: ParticipantUserInfo) -> ParticipantUserInfo {
        lock.lock()
        var role: ParticipantRole = .unknown
        var nickname: String?
        var inMeetingName: String?
        if let id = ap.pid?.pid {
            if let name = participantInMeetingNameMap[id], !name.isEmpty {
                inMeetingName = name
            }
            if let name = participantNicknameMap[id], !name.isEmpty {
                nickname = name
            }
            if let r = participantRoleMap[id] {
                role = r
            }
        }
        lock.unlock()

        if var user = ap.user {
            if let inMeetingName = inMeetingName {
                user.inMeetingName = roleStrategy.displayNameFor(role: role, name: inMeetingName)
            }
            user.name = roleStrategy.displayNameFor(role: role, name: user.name)
            user.alias = roleStrategy.displayNameFor(role: role, name: user.alias)
            user.avatarInfo = roleStrategy.displayAvatarFor(role: role, avatar: user.avatarInfo)
            user.displayName = roleStrategy.displayNameByFG(role: role, user: user, enableAnotherName: enableAnotherName)
            var newUser: ParticipantUserInfo = .user(user)
            newUser.pid = ap.pid
            return newUser
        } else if var room = ap.room {
            if let inMeetingName = inMeetingName {
                room.inMeetingName = roleStrategy.displayNameFor(role: role, name: inMeetingName)
            }
            room.fullName = roleStrategy.displayNameFor(role: role, name: room.fullName)
            room.primaryName = roleStrategy.displayNameFor(role: role, name: room.primaryName)
            room.secondaryName = roleStrategy.displayRoomSecondaryNameFor(role: role, name: room.secondaryName)
            room.avatarInfo = roleStrategy.displayAvatarFor(role: role, avatar: room.avatarInfo)
            var newRoom: ParticipantUserInfo = .room(room)
            newRoom.pid = ap.pid
            return newRoom
        } else if var guest = ap.guest {
            if let inMeetingName = inMeetingName {
                guest.inMeetingName = roleStrategy.displayNameFor(role: role, name: inMeetingName)
            }
            guest.name = roleStrategy.displayNameFor(role: role, name: inMeetingName ?? guest.name)
            if let nickname = nickname {
                guest.nickname = roleStrategy.displayNameFor(role: role, name: nickname)
            }
            guest.fullName = roleStrategy.displayNameFor(role: role, name: guest.fullName)
            guest.avatarInfo = roleStrategy.displayAvatarFor(role: role, avatar: guest.avatarInfo)
            var newGuest: ParticipantUserInfo = .guest(guest)
            newGuest.pid = ap.pid
            return newGuest
        }
        return ap
    }
}

extension VideoChatInfo {
    func makeStrategy(account: ByteviewUser, isShowAnotherNameEnabled: Bool) -> InMeetParticipantStrategy {
        let source = meetingSource
        let role = participants.first(withUser: account)?.role ?? .unknown
        var roleStrategy: MeetingRoleStrategy?
        if source == .vcFromInterview && role == .interviewee {
            roleStrategy = meetingRoleStrategyWith(meetingSource: source, selfRole: role)
        }
        let params = ParticipantStrategyKey(userId: account.id, meetingId: self.id)
        let strategy = InMeetParticipantStrategy(params: params, participants: participants, roleStrategy: roleStrategy ?? DefaultMeetingRoleStrategy(), isShowAnotherNameEnabled: isShowAnotherNameEnabled)
        return strategy
    }
}

extension InMeetParticipantStrategy {

    private func updateName(_ p: Participant) {
        self.participantRoleMap[p.user] = p.role
        self.participantNicknameMap[p.user] = p.settings.nickname
        self.participantInMeetingNameMap[p.user] = p.settings.inMeetingName
    }

    func updateParticipantsName(modify: InMeetParticipantOutput.Modify) {
        lock.lock(); defer { lock.unlock() }
        modify.ringing.inserts.values.forEach(updateName(_:))
        modify.nonRinging.inserts.values.forEach(updateName(_:))
        modify.ringing.updates.values.forEach(updateName(_:))
        modify.nonRinging.updates.values.forEach(updateName(_:))
    }

    func updateParticipantsName(participants: [Participant]) {
        lock.lock(); defer { lock.unlock() }
        participants.forEach(updateName(_:))
    }
}

extension InMeetParticipantStrategy: InMeetLobbyViewModelObserver {
    func didChangeLobbyParticipants(_ lobbyParticipants: [LobbyParticipant]) {
        lock.lock(); defer { lock.unlock() }
        for lobby in lobbyParticipants {
            participantInMeetingNameMap[lobby.user] = lobby.inMeetingName
        }
    }
}

extension InMeetParticipantStrategy {
    func didReceiveChatters(_ chatters: [String: User]) {
        lock.lock()
        chatters.keys.forEach {
            ParticipantService.clearUserCache($0)
        }
        lock.unlock()
        let ids = Set(chatters.keys)
        chattersInfoDidClear?(ids)
        Logger.meeting.info("didReceiveChattersChange: \(ids)")
    }
}
