//
//  TrackContext.swift
//  ByteView
//
//  Created by kiri on 2022/1/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork
import QuartzCore

final class TrackContext {
    static let shared = TrackContext()

    private init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
    }

    @RwAtomic
    private var userId: String?

    @RwAtomic
    private(set) var currentEnvId: String?
    @RwAtomic
    private var storages: [String: Storage] = [:]

    func removeContext(for envId: String) {
        TrackCommonParams.removeValue(for: envId)
        self.storages.removeValue(forKey: envId)
        if self.currentEnvId == envId {
            self.currentEnvId = nil
        }
    }

    func updateCurrent(envId: String) {
        if envId.isEmpty || self.currentEnvId == envId { return }
        self.currentEnvId = envId
        TrackCommonParams.updateCurrentEnvId(envId)
    }

    func updateContext(for envId: String, block: (inout Storage) -> Void) {
        if envId.isEmpty { return }
        var storage = storages[envId] ?? Storage.create(envId: envId)
        let oldValue = storage
        block(&storage)
        if oldValue != storage {
            storages[envId] = storage
            TrackCommonParams.setValue(storage.toCommonParams(), for: envId)
            if self.currentEnvId == nil {
                self.currentEnvId = envId
            }
        }
    }

    @objc func willEnterForeground() {
        // 进入前台后，重新刷新一下 ntp 时间偏移量
        syncNtpTime()
    }
}

extension TrackContext {

    struct Storage: Equatable, Codable {
        fileprivate static let persistQueue = DispatchQueue(label: "ByteView.TrackContext.Storage")

        fileprivate static func create(envId: String) -> Storage {
            var obj = Storage()
            obj.envId = envId
            return obj
        }

        /// Codable不能let。。
        var account: ByteviewUser?
        var isIdle: Bool = true
        var didOnTheCall: Bool = false

        // --- common params ---
        private(set) var envId = ""
        var conferenceId: String?
        var interactiveId: String?
        var host: ByteviewUser?
        var meetingType: MeetingType?
        var meetingSubType: MeetingSubType?
        var interviewRole: Participant.Role?
        var meetingRole: Participant.MeetingRole?
        var isInterview: Bool?
        var isCallKit: Bool?
        /// MagicShare的共享ID
        var shareId: String = "none"
        /// 标识当前远端MagicShare的唯一ID，相当于（转移共享人也会改变的）shareID
        var actionUniqueID: String = "none"
        var participantNum: Int?
        /// 是否是加密会议
        var isE2EeMeeting: Bool?
        // --- common params end ---

        func toCommonParams() -> [String: Any] {
            var params: [String: Any] = [:]
            if let conferenceId = conferenceId {
                params["conference_id"] = conferenceId
            }
            if let interactiveId = interactiveId, !interactiveId.isEmpty {
                params["interactive_id"] = interactiveId
            }
            params["sdk_name"] = "bytertc"
            if let meetingType = meetingType {
                switch meetingType {
                case .call:
                    params["call_type"] = "call"
                case .meet:
                    params["call_type"] = "meeting"
                default:
                    break
                }
                if let meetingRole = meetingRole {
                    switch (meetingType, meetingRole) {
                    case (.call, .host):
                        params["user_type"] = "caller"
                    case (.call, .participant):
                        params["user_type"] = "callee"
                    case (.meet, .host):
                        params["user_type"] = "host"
                    case (.meet, .coHost):
                        params["user_type"] = "cohost"
                    case (.meet, .participant):
                        params["user_type"] = "attendee"
                    default:
                        break
                    }
                } else if account == host {
                    params["user_type"] = meetingType == .call ? "caller" : "host"
                }
            }

            // 面试场景增加通参，其中interview_participant_type的interviewer_shadow类型无法判断因此忽略
            if let isInterview = isInterview {
                params["meeting_type"] = isInterview ? "interview" : "general"
            }
            if let interviewRole = interviewRole {
                switch interviewRole {
                case .interviewer:
                    params["interview_participant_type"] = "interviewer"
                case .interviewee:
                    params["interview_participant_type"] = "candidate"
                default:
                    params["interview_participant_type"] = "none"
                }
            }
            params["share_id"] = shareId.isEmpty ? "none" : shareId
            params["action_unique_id"] = actionUniqueID.isEmpty ? "none" : actionUniqueID
            params["env_id"] = envId
            if let num = participantNum {
                params["participant_num"] = num
            }
            if let isCallKit = isCallKit {
                params["is_callkit"] = isCallKit
            }
            if let isE2EeMeeting = isE2EeMeeting {
                params["is_j2m"] = isE2EeMeeting
            }
            if meetingSubType == .webinar {
                params["is_webinar"] = "true"
                if self.meetingRole == .webinarAttendee {
                    params["user_type"] = "webinar_attendee"
                } else if self.meetingRole == .participant {
                    params["user_type"] = "webinar_panelist"
                }
            } else {
                params["is_webinar"] = "false"
            }
            return params
        }

        mutating func update(info: VideoChatInfo) {
            self.conferenceId = info.id
            self.host = info.host
            self.meetingType = info.type
            self.meetingSubType = info.settings.subType
            self.isInterview = info.meetingSource == .vcFromInterview
            self.isE2EeMeeting = info.settings.isE2EeMeeting
        }

        mutating func update(myself: Participant?) {
            self.interactiveId = myself?.interactiveId
            self.interviewRole = myself?.role
            self.meetingRole = myself?.meetingRole
        }

        mutating func update(interactiveId: String?) {
            self.interactiveId = interactiveId
        }

        mutating func update(isCallKit: Bool) {
            self.isCallKit = isCallKit
        }

        mutating func reset() {
            isIdle = true
            didOnTheCall = false
            conferenceId = nil
            interactiveId = nil
            host = nil
            meetingType = nil
            meetingSubType = nil
            interviewRole = nil
            isInterview = nil
            isCallKit = nil
            meetingRole = nil
            shareId = "none"
            actionUniqueID = "none"
            isE2EeMeeting = nil
        }
    }
}

extension TrackContext {
    func reset(userId: String) {
        self.userId = userId
        self.syncNtpTime()
        self.currentEnvId = nil
        self.storages = [:]
        TrackCommonParams.removeAll()
    }

    func syncNtpTime() {
        guard let userId = userId, !userId.isEmpty else { return }
        _syncNtpTime(userId: userId)
    }

    private func _syncNtpTime(userId: String) {
        // 同步NTP时间
        var request = GetNtpTimeRequest()
        request.blockUntilUpdate = true
        HttpClient(userId: userId).getResponse(request) { r in
            switch r {
            case .success(let rsp):
                TrackCommonParams.ntpOffset = rsp.ntpOffset
            case .failure(let error):
                Logger.tracker.info("getNtpTime request failed, error: \(error)")
            }
        }
    }
}
