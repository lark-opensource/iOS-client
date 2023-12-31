//
//  MeetingTerminationCache.swift
//  ByteView
//
//  Created by kiri on 2021/8/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork
import ByteViewCommon

/// 用来存储已经被结束的会议
final class MeetingTerminationCache {
    static let shared = MeetingTerminationCache()

    @RwAtomic
    private var terminatedIdentifiers: [VideoChatIdentifier] = []

    private init() {
        // 切换账号后清空缓存
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeAccount),
                                               name: VCNotification.didChangeAccountNotification, object: nil)
    }

    @objc private func didChangeAccount() {
        terminatedIdentifiers = []
    }

    /// 仅用于拨号状态
    func isTerminated(placeholderId: String) -> Bool {
        terminatedIdentifiers.contains(VideoChatIdentifier(id: placeholderId))
    }

    /// 用于判断MeetingSession以外的会议信息（ongoing或push）
    /// - note: interactiveId为空直接返回false
    func isTerminated(meetingId: String, interactiveId: String) -> Bool {
        if interactiveId.isEmpty {
            return false
        }
        return terminatedIdentifiers.contains(VideoChatIdentifier(id: meetingId, interactiveId: interactiveId))
    }

    /// 添加termination记录
    func terminate(meetingId: String, interactiveId: String) {
        let identifier = VideoChatIdentifier(id: meetingId, interactiveId: interactiveId)
        if !terminatedIdentifiers.contains(identifier) {
            terminatedIdentifiers.append(identifier)
            Logger.meeting.debug("Terminated video chat identifiers are \(terminatedIdentifiers).")
        }
    }

    /// 添加termination记录，如果accountId和当前Account不匹配则忽略
    func terminate(info: VideoChatInfo, account: ByteviewUser) {
        let identifier = self.identifier(info: info, account: account)
        if !terminatedIdentifiers.contains(identifier) {
            terminatedIdentifiers.append(identifier)
            Logger.meeting.debug("Terminated video chat identifiers are \(terminatedIdentifiers).")
        }
    }

    /// 添加termination记录，如果accountId和当前Account不匹配则忽略
    func terminate(lobbyInfo: LobbyInfo, account: ByteviewUser) {
        let identifier = self.identifier(lobbyInfo: lobbyInfo, account: account)
        if !terminatedIdentifiers.contains(identifier) {
            terminatedIdentifiers.append(identifier)
            Logger.meeting.debug("Terminated video chat identifiers are \(terminatedIdentifiers).")
        }
    }

    /// 添加termination记录，如果accountId和当前Account不匹配则忽略
    func terminate(session: MeetingSession) {
        let account = session.account
        let sessionId = session.sessionId
        terminatedIdentifiers.removeAll { $0.id == sessionId && $0.interactiveId == nil }
        let identifier: VideoChatIdentifier
        if let lobbyInfo = session.lobbyInfo {
            terminatedIdentifiers.removeAll { $0.id == sessionId && $0.interactiveId == nil }
            identifier = self.identifier(lobbyInfo: lobbyInfo, account: account)
        } else if let info = session.videoChatInfo {
            terminatedIdentifiers.removeAll { $0.id == sessionId && $0.interactiveId == nil }
            identifier = self.identifier(info: info, account: account)
        } else {
            identifier = VideoChatIdentifier(id: sessionId)
        }
        if !terminatedIdentifiers.contains(identifier) {
            terminatedIdentifiers.append(identifier)
            Logger.meeting.info("Terminated video chat identifiers are \(terminatedIdentifiers).")
        }
    }

    /// 仅用于拨号状态结束
    func updatePlaceholder(_ placeholderId: String, info: VideoChatInfo, account: ByteviewUser) {
        terminatedIdentifiers.removeAll { $0.id == placeholderId && $0.interactiveId == nil }
        terminatedIdentifiers.append(identifier(info: info, account: account))
    }

    /// 清除某个会议的terminations，用于joinMeeting修复
    func removeTerminations(by meetingId: String) {
        terminatedIdentifiers.removeAll { $0.id == meetingId }
    }

    func isTerminated(info: VideoChatInfo, account: ByteviewUser) -> Bool {
        if let interactiveId = info.participants.first(where: { $0.user == account })?.interactiveId {
            return terminatedIdentifiers.contains(VideoChatIdentifier(id: info.id, interactiveId: interactiveId))
        }
        return false
    }

    func isTerminated(lobbyInfo: LobbyInfo, account: ByteviewUser) -> Bool {
        if let p = lobbyInfo.lobbyParticipant, p.user == account, !p.interactiveId.isEmpty {
            return terminatedIdentifiers.contains(VideoChatIdentifier(id: lobbyInfo.meetingId, interactiveId: p.interactiveId))
        }
        return false
    }

    private func identifier(info: VideoChatInfo, account: ByteviewUser) -> VideoChatIdentifier {
        let interactiveId = info.participants.first(where: { $0.user == account })?.interactiveId
        return VideoChatIdentifier(id: info.id, interactiveId: interactiveId)
    }

    private func identifier(lobbyInfo: LobbyInfo, account: ByteviewUser) -> VideoChatIdentifier {
        let interactiveId = lobbyInfo.lobbyParticipant?.user == account ? lobbyInfo.lobbyParticipant?.interactiveId : nil
        return VideoChatIdentifier(id: lobbyInfo.meetingId, interactiveId: interactiveId)
    }
}
