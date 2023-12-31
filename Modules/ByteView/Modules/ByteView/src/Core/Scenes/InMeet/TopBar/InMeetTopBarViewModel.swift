//
//  InMeetTopBarViewModel.swift
//  ByteView
//
//  Created by kiri on 2021/4/22.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import ByteViewCommon
import ByteViewSetting
import ByteViewNetwork

protocol InMeetTopBarViewModelObserver: AnyObject {
    func didChangeExternal(_ meetingTagType: MeetingTagType)
    func didChangeWebinarRehearsingTagHidden(_ isHidden: Bool)
    func didChangeJoinRoomHidden(_ isHidden: Bool)
    func didChangeRoomConnected(_ isConnected: Bool)
}

enum MeetingTagType: Equatable {
    case none
    /// 外部
    case external
    /// 互通
    case cross
    /// 关联租户
    case partner(String)
}

extension MeetingTagType: CustomStringConvertible {
    var text: String? {
        switch self {
        case .external:
            return I18n.View_G_ExternalLabel
        case .cross:
            return I18n.View_G_ConnectLabel
        case .partner(let relationTag):
            return relationTag
        case .none:
            return nil
        }
    }

    var description: String {
        switch self {
        case .partner:
            return "partner"
        default:
            return text ?? ""
        }
    }
}

final class InMeetTopBarViewModel: InMeetMeetingProvider {
    var subject: String?
    let meeting: InMeetMeeting
    let context: InMeetViewContext
    let resolver: InMeetViewModelResolver
    let myAIViewModel: MyAIViewModel


    // 参数: isExpanded: Bool, completion: @escaping () -> Void
    var toggleToolbarClosure: ((Bool, @escaping () -> Void) -> Void)?

    @RwAtomic private(set) var meetingTagType: MeetingTagType = .none
    /// 会议维度关联标签缓存
    @RwAtomic private var tenantInfoCache: [String: TargetTenantInfo] = [:]

    private let toolbarViewModel: ToolBarViewModel
    var toolBarFactory: ToolBarFactory {
        toolbarViewModel.factory
    }
    var badgeManager: ToolBarBadgeManager {
        toolbarViewModel.badgeManager
    }
    var toolbarItems: [ToolBarItemType] {
        toolbarViewModel.phoneMainItems
    }
    weak var observer: InMeetTopBarViewModelObserver?
    let isCalendarMeeting: Bool

    var isWebinarRehearsingTagHidden: Bool {
        !isWebinarRehearsing
    }
    private var isWebinarRehearsing: Bool = false {
        didSet {
            guard isWebinarRehearsing != oldValue else {
                return
            }
            self.observer?.didChangeWebinarRehearsingTagHidden(!isWebinarRehearsing)
        }
    }

    var isRoomConnected = false
    var isJoinRoomHidden = true
    var isJoinRoomEnabled: Bool { Display.pad && meeting.setting.showsJoinRoom }
    var isMyAIEnabled: Bool { myAIViewModel.isEnabled }

    init(meeting: InMeetMeeting, context: InMeetViewContext, resolver: InMeetViewModelResolver) {
        self.meeting = meeting
        self.context = context
        self.resolver = resolver
        self.isCalendarMeeting = meeting.isCalendarMeeting
        self.toolbarViewModel = resolver.resolve()!
        self.myAIViewModel = resolver.resolve()!
        self.isRoomConnected = meeting.myself.settings.targetToJoinTogether != nil
        meeting.participant.addListener(self)
        meeting.addMyselfListener(self)
        meeting.setting.addListener(self, for: [.showsJoinRoom, .isUltrawaveEnabled])
        updateJoinRoomStatus()

        if meeting.subType == .webinar {
            meeting.webinarManager?.addListener(self)
        }
    }

    func addToolbarListener(_ listener: ToolBarViewModelDelegate) {
        toolbarViewModel.addListener(listener)
    }

    func setToolbarBridge(_ bridge: ToolBarViewModelBridge) {
        toolbarViewModel.setBridge(bridge, for: .navbar)
    }

    private func updateJoinRoomStatus() {
        let isRoomConnected = isJoinRoomEnabled && meeting.myself.settings.targetToJoinTogether != nil
        let isJoinRoomHidden: Bool
        if isJoinRoomEnabled {
            isJoinRoomHidden = !meeting.setting.isUltrawaveEnabled && !isRoomConnected
        } else {
            isJoinRoomHidden = true
        }
        Util.runInMainThread { [weak self] in
            guard let self = self else { return }
            let isHiddenChanged = self.isJoinRoomHidden != isJoinRoomHidden
            let isConnectedChanged = self.isRoomConnected != isRoomConnected
            self.isJoinRoomHidden = isJoinRoomHidden
            self.isRoomConnected = isRoomConnected
            if isHiddenChanged {
                self.observer?.didChangeJoinRoomHidden(isJoinRoomHidden)
            }
            if isConnectedChanged {
                self.observer?.didChangeRoomConnected(isRoomConnected)
            }
        }
    }
}

extension InMeetTopBarViewModel: InMeetParticipantListener {

    func didChangeGlobalParticipants(_ output: InMeetParticipantOutput) {
        updateMeetingTagType()
    }

    func didChangeWebinarAttendees(_ output: InMeetParticipantOutput) {
        updateMeetingTagType()
    }

    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput) {
        updateMeetingTagType()
    }

    private func updateMeetingTagType() {
        var tenantIdSet = Set<String>()
        defer {
            meeting.setting.updateSettings {
                $0.isExternalMeeting = tenantIdSet.count >= 1
            }
        }

        let isCrossWithKa = meeting.setting.isCrossWithKa
        var ps: [ByteviewUser: Participant] = [:]
        if meeting.participant.subType == .webinar {
            if meeting.myself.meetingRole == .webinarAttendee {
                ps = meeting.participant.attendeePanel.nonRingingDict
            } else {
                ps = (meeting.participant.global + meeting.participant.attendee).nonRingingDict
            }
        } else {
            ps = meeting.participant.global.nonRingingDict
        }

        for (_, p) in ps {
            if p.isExternal(localParticipant: meeting.myself) {
                tenantIdSet.insert(p.tenantId)
                if tenantIdSet.count >= 2 {
                    // 如果除自己 tenantId >= 2, 直接走外部租户逻辑
                    updateMeetingTagTypeIfNeeded(isCrossWithKa ? .cross : .external)
                    return
                }
            }
        }

        if self.setting.isRelationTagEnabled, tenantIdSet.count == 1, let tenantId = tenantIdSet.first, let id = Int64(tenantId) {
            // 除自己 tenantId == 1, 查看是否为关联租户
            getTargetTenantInfo(tenantId: id) { [weak self] info in
                guard let self = self else { return }
                guard let info = info, let tag = info.relationTag?.meetingTagText else {
                    self.updateMeetingTagTypeIfNeeded(isCrossWithKa ? .cross : .external)
                    return
                }
                self.updateMeetingTagTypeIfNeeded(.partner(tag))
            }
        } else {
            // 外部租户逻辑
            let tagType: MeetingTagType = tenantIdSet.count >= 1 ? (isCrossWithKa ? .cross : .external) : .none
            updateMeetingTagTypeIfNeeded(tagType)
        }
    }

    private func getTargetTenantInfo(tenantId: Int64, completion: @escaping (TargetTenantInfo?) -> Void) {
        if let info = tenantInfoCache[String(tenantId)] {
            Logger.base.info("get TenantInfo for \(tenantId) from cache")
            completion(info)
            return
        }

        let request = GetTargetTenantInfoRequest(targetTenantIds: [tenantId])
            meeting.httpClient.getResponse(request) { [weak self] (result) in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let resp):
                if let info = resp.targetTenantInfos.first(where: { $0.key == tenantId }) {
                    Logger.base.info("fetch TenantInfo for tenant \(tenantId) success")
                    self.tenantInfoCache.updateValue(info.value, forKey: String(info.key))
                    completion(info.value)
                    return
                } else {
                    Logger.base.info("fetch TenantInfo for tenant \(tenantId) error: no info in response")
                }
            case .failure(let error):
                Logger.base.info("fetch TenantInfo for tenant \(tenantId) error: \(error)")
            }
            completion(nil)
        }
    }

    private func updateMeetingTagTypeIfNeeded(_ type: MeetingTagType) {
        guard type != meetingTagType else { return }
        Logger.meeting.info("updte meetTagType: \(type)")
        meetingTagType = type
        Util.runInMainThread {
            self.observer?.didChangeExternal(type)
        }
    }
}

extension InMeetTopBarViewModel: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        updateJoinRoomStatus()
    }
}

extension InMeetTopBarViewModel: WebinarRoleListener {
    func webinarDidChangeRehearsal(isRehearsing: Bool, oldValue: Bool?) {
        DispatchQueue.main.async {
            self.isWebinarRehearsing = isRehearsing
        }
    }
}

extension InMeetTopBarViewModel: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .showsJoinRoom || key == .isUltrawaveEnabled {
            updateJoinRoomStatus()
        }
    }
}
