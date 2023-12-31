//
//  ChatMessageCellModel.swift
//  ByteView
//
//  Created by wulv on 2020/12/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay
import UniverseDesignIcon
import UIKit
import ByteViewNetwork
import ByteViewSetting

final class ChatMessageCellModel: InMeetParticipantListener, MeetingSettingListener {
    private(set) var avatar: ChatAvatarView.Content?
    private(set) var canTapAvatar: Bool = false
    private(set) var name: NSAttributedString?
    let nameRelay: BehaviorRelay<NSAttributedString?> = BehaviorRelay(value: nil)
    private(set) var me: NSAttributedString?
    private(set) var external: NSAttributedString?
    private(set) var time: NSAttributedString?
    /// 原文 or 仅译文时的译文 or 原文+译文时的原文
    private(set) var content: NSAttributedString?
    /// 原文+译文时的译文
    private(set) var translationContent: NSAttributedString?
    private var meetingRole: ParticipantMeetingRole = .participant
    private var isLarkGuest: Bool = false
    private var interviewRole: Participant.Role = .unknown
    private var participant: Participant?
    let roleRelay: BehaviorRelay<ParticipantRoleConfig?> = BehaviorRelay(value: nil)

    let model: ChatMessageModel
    let meeting: InMeetMeeting
    private let profileConfigEnabled: Bool
    private var currentUser: Participant?
    private var isInterInterviewMeeting: Bool
    var meetingURL: String { meeting.data.inMeetingInfo?.meetingURL ?? "" }
    private(set) var translation: IMTranslationResult?
    private(set) var relationTag: VCRelationTag?
    private(set) var hasRequestRelationTag: Bool = false
    var httpClient: HttpClient { meeting.httpClient }

    init(model: ChatMessageModel,
         meeting: InMeetMeeting,
         profileConfigEnabled: Bool) {
        self.model = model
        self.meeting = meeting
        self.currentUser = meeting.myself
        self.isInterInterviewMeeting = meeting.isInterviewMeeting
        self.profileConfigEnabled = profileConfigEnabled

        constructAvatar()
        constructName()
        constructMe()
        constructHost()
        constructExternal()
        constructTime()
        constructContent()
    }

    func updateTranslation(_ translation: IMTranslationResult?) {
        self.translation = translation
        if let translation = translation {
            switch translation.rule {
            case .noTranslation, .unknown:
                constructContent()
                translationContent = nil
            case .onlyTranslation:
                content = nil
                constructTranslationContent(translation.content)
            case .withOriginal:
                constructContent()
                constructTranslationContent(translation.content)
            }
        } else {
            constructContent()
            translationContent = nil
        }
    }

    private func updatePaticipantInfo(with output: InMeetParticipantOutput) {
        let upserts: (Participant) -> Void = { [weak self] p in
            guard let self = self else { return }
            self.participant = p
            self.meetingRole = p.meetingRole
            self.updateRoleConfig()
            self.httpClient.participantService.participantInfo(pid: p, meetingId: self.meeting.meetingId) { [weak self] ap in
                let name = ChatMessageCell.createNameAttributedString(with: ap.name)
                self?.name = name
                self?.nameRelay.accept(name)
            }
        }
        if let p = output.modify.nonRinging.inserts[model.pid] ?? output.modify.nonRinging.updates[model.pid] {
            upserts(p)
        } else if output.modify.nonRinging.removes[model.pid] != nil {
            meetingRole = .participant
            updateRoleConfig()
        }
    }

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        updatePaticipantInfo(with: output)
    }

    func didChangeWebinarParticipantForAttendee(_ output: InMeetParticipantOutput) {
        updatePaticipantInfo(with: output)
    }

    private func updateRoleConfig() {
        var roleConfig = participant?.roleConfig(hostEnabled: meeting.setting.isHostEnabled,
                                                 isInterview: meeting.isInterviewMeeting)
        let role = roleConfig?.role
        roleConfig?.roleAttributeString = ChatMessageCell.createRoleAttributedString(with: role)
        roleRelay.accept(roleConfig)
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        updateRoleConfig()
    }

    private func constructAvatar() {
        if isInterInterviewMeeting {
            // 面试会议，面试官可以点击他人profile，面试者不可以查看面试官头像
            if currentUser != nil {
                canTapAvatar = currentIsInterviewer && profileConfigEnabled
                avatar = (currentIsInterviewer || !cellIsInterviewer) ? .key(model.userAvatarKey, userId: model.userId, backup: guestAvatar) : .image(interviewerAvatar)
            } else {
                canTapAvatar = false
                avatar = (currentUser?.user.id == model.userId) ? .key(model.userAvatarKey, userId: model.userId, backup: guestAvatar) : .image(interviewerAvatar)
            }
        } else {
            switch model.userType {
            case .larkUser, .neoUser:
                    // 套件场景: Lark 和单品都可以查看，游客可以查看他人的真实头像
                canTapAvatar = !currentIsGuest && profileConfigEnabled
                avatar = .key(model.userAvatarKey, userId: model.userId, backup: guestAvatar)
            default:
                    // 目前其他场景均不支持点击 Profile
                canTapAvatar = false
                avatar = .key(model.userAvatarKey, userId: model.userId, backup: guestAvatar)
            }
        }
    }

    private func constructName() {
        name = ChatMessageCell.createNameAttributedString(with: displayName)
    }

    private func constructMe() {
        me = ChatMessageCell.createMeAttributedString(with: meString)
    }

    private func constructHost() {
        meeting.participant.addListener(self)
        meeting.setting.addListener(self, for: .isHostEnabled)
        updateRoleConfig()
    }

    private func constructExternal() {
        external = ChatMessageCell.createExternalAttributedString(with: externalString)
    }

    private func constructTime() {
        let createTimeInterval = (Double(model.createTime) ?? 0) / 1000
        let createDate = Date(timeIntervalSince1970: createTimeInterval)
        let dateformatter = DateFormatter()
        let gregorianCalendar = Calendar.gregorianCalendarWithCurrentTimeZone()
        if gregorianCalendar.isDate(Date(), inSameDayAs: createDate) {
            dateformatter.dateFormat = "HH:mm"
        } else {
            dateformatter.dateFormat = "MM-dd HH:mm"
        }
        let timeString = dateformatter.string(from: createDate)
        time = ChatMessageCell.createTimeAttributedString(with: timeString)
    }

    private func constructContent() {
        if model.type == .text {
            let attributedString = meeting.service.messenger.richTextToString(model.content)
            let attrStr = meeting.service.emotion.parseEmotion(attributedString)
            content = ChatMessageCell.createContentAttributedString(with: attrStr)
        }
        if content?.string.isEmpty != false {
            let string = I18n.View_M_UnknownMessageType
            content = ChatMessageCell.createContentAttributedString(with: NSMutableAttributedString(string: string))
        }
    }

    private func constructTranslationContent(_ content: MessageRichText) {
        let attributedString = meeting.service.messenger.richTextToString(content)
        let attrStr = meeting.service.emotion.parseEmotion(attributedString)
        translationContent = ChatMessageCell.createContentAttributedString(with: attrStr)
    }
}

extension ChatMessageCellModel {

    private var currentIsInterviewer: Bool {
        currentUser?.role == .interviewer || currentUser?.role == .unknown
    }

    private var cellIsInterviewer: Bool {
        model.userRole == .interviewer || model.userRole == .unknown
    }

    private var interviewerAvatar: UIImage {
        AvatarResources.interviewer
    }

    private var interviewerName: String {
        I18n.View_M_Interviewer
    }

    private var currentIsGuest: Bool {
        meeting.accountInfo.isGuest
    }

    private var selfIsGuest: Bool {
        return model.tags.contains(where: { $0 == .guest })
    }

    private var isExternal: Bool {
        let localPartipant = meeting.myself
        if localPartipant.tenantTag != .standard {
            // 自己是小 B 用户，则不关注 external
            return false
        }
        if model.isBot || currentIsGuest || selfIsGuest {
            // 自己或对方是游客、或者对方是机器人，不展示外部标签
            return false
        }
        return Int64(meeting.accountInfo.tenantId) != model.tenantID
    }

    private var guestAvatar: UIImage? {
        AvatarResources.guest
    }

    private var cellIsMe: Bool {
        model.pid == meeting.account
    }

    var position: Int {
        model.position
    }

    var id: String {
        model.id
    }

    var userId: String {
        model.userId
    }

    var meetingID: String {
        model.meetingID
    }

    private var meString: String? {
        if cellIsMe {
            return " (\(I18n.View_M_Me))"
        } else if selfIsGuest {
            if meeting.info.meetingSource == .vcFromInterview {
                return I18n.View_G_CandidateBracket
            }
            return I18n.View_M_GuestParentheses
        } else {
            return nil
        }
    }

    private var externalString: String? {
        if isExternal {
            return I18n.View_G_ExternalLabel
        } else {
            return nil
        }
    }

    private var roleString: String? {
        switch meetingRole {
        case .host:
            return I18n.View_M_Host
        case .coHost:
            return I18n.View_M_CoHost
        default:
            return nil
        }
    }

    var displayName: String {
        var displayName: String
        if isInterInterviewMeeting {
            if currentUser != nil {
                displayName = (currentIsInterviewer || !cellIsInterviewer) ? model.userName : interviewerName
            } else {
                displayName = (currentUser?.user.id == model.userId) ? model.userName : interviewerName
            }
        } else {
            displayName = model.userName
        }
        return displayName
    }
}

extension ChatMessageCellModel: Hashable {

    static func == (lhs: ChatMessageCellModel, rhs: ChatMessageCellModel) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension ChatMessageCellModel {
    func getRelationTag(_ completion: @escaping ((NSAttributedString?) -> Void)) {
        guard meeting.setting.isRelationTagEnabled, isExternal else {
            completion(nil)
            return
        }

        if let externalString = relationTag?.relationText {
            external = ChatMessageCell.createExternalAttributedString(with: externalString)
            completion(external)
            return
        }

        var relationUserType: VCRelationTag.User.TypeEnum
        switch model.userType {
        case .larkUser:
            relationUserType = .larkUser
        case .room:
            relationUserType = .room
        default:
            relationUserType = .unknown
        }
        let user = VCRelationTag.User(type: relationUserType, id: model.userId)
        httpClient.participantRelationTagService.relationTagsByUsers([user]) { [weak self] tags in
            self?.hasRequestRelationTag = true
            let relationTag = tags.first
            guard relationTag?.userID == self?.model.userId else {
                completion(nil)
                return
            }
            self?.relationTag = relationTag
            if let externalString = relationTag?.relationText {
                let externalAttrStr = ChatMessageCell.createExternalAttributedString(with: externalString)
                completion(externalAttrStr)
            } else {
                completion(nil)
            }
        }
    }
}
