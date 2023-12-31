//
//  MeetingFrontier.swift
//  ByteView
//
//  Created by kiri on 2023/6/17.
//

import Foundation
import ByteViewCommon
import ByteViewUI
import ByteViewMeeting
import ByteViewNetwork
import ByteViewTracker

public final class MeetingFrontier {
    @discardableResult
    public static func startCall(_ params: StartCallParams, dependency: MeetingDependency, from: UIViewController?,
                                 file: String = #fileID, function: String = #function, line: Int = #line) -> MeetingSession? {
        if params.shouldShowSecretAlert, dependency.setting.isSecretChatRemindEnabled {
            Logger.meeting.info("startCall guard by secureChatAlert, params = \(params), from = \(from)", file: file, function: function, line: line)
            self.showSecretChatAlert(isGroupMeeting: false, isVoiceCall: params.isVoiceCall) { [weak from] in
                Logger.meeting.info("startCall continued by secureChatAlert, params = \(params), from = \(from)", file: file, function: function, line: line)
                _ = self.startMeeting(entry: .call(params), dependency: dependency, from: from,
                                      file: file, function: function, line: line)
            }
            return nil
        }
        return startMeeting(entry: .call(params), dependency: dependency, from: from, file: file, function: function, line: line)
    }

    @discardableResult
    public static func startMeeting(_ params: StartMeetingParams, dependency: MeetingDependency, from: UIViewController?,
                                    file: String = #fileID, function: String = #function, line: Int = #line) -> MeetingSession? {
        if params.shouldShowSecretAlert, dependency.setting.isSecretChatRemindEnabled {
            Logger.meeting.info("startCall guard by secureChatAlert, params = \(params), from = \(from)", file: file, function: function, line: line)
            self.showSecretChatAlert(isGroupMeeting: true, isVoiceCall: false) { [weak from] in
                Logger.meeting.info("startCall continued by secureChatAlert, params = \(params), from = \(from)", file: file, function: function, line: line)
                _ = startMeeting(entry: params.entry, dependency: dependency, from: from, file: file, function: function, line: line)
            }
            return nil
        }
        return startMeeting(entry: params.entry, dependency: dependency, from: from, file: file, function: function, line: line)
    }

    @discardableResult
    public static func startPhoneCall(_ params: PhoneCallParams, dependency: MeetingDependency, from: UIViewController?,
                                      file: String = #fileID, function: String = #function, line: Int = #line,
                                      completion: ((Result<Void, Error>) -> Void)? = nil) -> MeetingSession? {
        PhoneCallUtil.startPhoneCall(params, dependency: dependency, from: from, file: file, function: function, line: line, completion: completion)
    }

    @discardableResult
    public static func startShareToRoom(source: MeetingEntrySource, dependency: MeetingDependency, from: UIViewController?,
                                        file: String = #fileID, function: String = #function, line: Int = #line) -> MeetingSession? {
        return startMeeting(entry: .shareToRoom(ShareToRoomEntryParams(source: source, fromVC: from)), dependency: dependency, from: from, file: file, function: function, line: line)
    }

    public static func showPhoneCallPicker(_ params: PhoneCallParams, dependency: MeetingDependency, from: UIViewController) {
        PhoneCallUtil.showPhoneCallPicker(params, dependency: dependency, from: from)
    }

    public static func createPreviewParticipantsViewController(_ params: PreviewParticipantParams, dependency: MeetingDependency) throws -> UIViewController {
        try ByteViewApp.shared.preload(account: dependency.account, reason: "showPreviewParticipants")
        let vm = PreviewParticipantsViewModel(params: params, dependency: dependency)
        return PreviewParticipantsViewController(viewModel: vm)
    }

    public static func createPstnPhonesViewController(_ params: PstnPhonesParams, dependency: SecurityStateDependency) -> UIViewController {
        let vm = PhoneListViewModel(meetingNumber: params.meetingNumber, pstnIncomingCallPhoneList: params.phones, security: MeetingSecurityControl(security: dependency))
        return PhoneListViewController(viewModel: vm)
    }

    /// 待废弃
    public static func preload(for reason: String, account: AccountInfo, file: String = #fileID, function: String = #function, line: Int = #line) {
        do {
            Logger.context.info("preload for \(reason)", file: file, function: function, line: line)
            try ByteViewApp.shared.preload(account: account, reason: reason)
        } catch {
            Logger.context.error("preload for \(reason) failed, \(error)", file: file, function: function, line: line)
        }
    }

    private static func startMeeting(entry: MeetingEntry, dependency: MeetingDependency, from: UIViewController?,
                                     file: String, function: String, line: Int) -> MeetingSession? {
        try? MeetingManager.shared.startMeeting(entry, dependency: dependency, from: from.map(RouteFrom.init(_:)),
                                                file: file, function: function, line: line).get()
    }
}

public struct StartMeetingParams {
    let entry: MeetingEntry
    var shouldShowSecretAlert = false
    init(params: PreviewEntryParams) {
        self.entry = .preview(params)
    }

    public init(source: MeetingEntrySource) {
        self.init(params: .createMeeting(source: source))
    }

    public init(meetingNumber number: String, source: MeetingEntrySource, isWebinar: Bool) {
        self.init(params: .meetingNumber(number, source: source, isWebinar: isWebinar))
    }

    public init(meetingId: String, source: MeetingEntrySource, topic: String, isE2EeMeeting: Bool,
                chatID: String?, messageID: String?, isWebinar: Bool, isInterview: Bool = false) {
        self.init(params: .meetingId(meetingId, source: source, topic: topic, isE2EeMeeting: isE2EeMeeting, chatID: chatID, messageID: messageID, isWebinar: isWebinar, isInterview: isInterview))
    }

    public init(group id: String, source: MeetingEntrySource, isE2EeMeeting: Bool, isFromSecretChat: Bool, isJoinMeeting: Bool, isWebinar: Bool) {
        self.init(params: .group(id: id, source: source, isE2EeMeeting: isE2EeMeeting, isJoinMeeting: isJoinMeeting, isWebinar: isWebinar))
        self.shouldShowSecretAlert = !isE2EeMeeting && isFromSecretChat
    }

    public init(calendar uniqueId: String, source: MeetingEntrySource, topic: String?, fromLink: Bool, instance: CalendarInstanceIdentifier, isJoinMeeting: Bool = true, isWebinar: Bool) {
        self.init(params: .calendar(uniqueId: uniqueId, source: source, topic: topic, fromLink: fromLink, instance: instance, isJoinMeeting: isJoinMeeting, isWebinar: isWebinar))
    }

    public init(interview uid: String, role: Participant.Role?, isWebinar: Bool) {
        self.init(params: .interview(uid: uid, role: role, isWebinar: isWebinar))
    }

    public init(openPlatform id: String, preview: Bool, isWebinar: Bool, mic: Bool?, speaker: Bool?, camera: Bool?) {
        if preview {
            self.entry = .preview(.openPlatform(uniqueId: id, isWebinar: isWebinar))
        } else {
            self.entry = .noPreview(.openPlatform(id: id, mic: mic, camera: camera, speaker: speaker))
        }
    }
}

public extension StartCallParams {
    init(id: String, source: MeetingEntrySource, isVoiceCall: Bool, secureChatId: String = "", isE2EeMeeting: Bool,
         onError: ((StartCallError) -> Void)? = nil) {
        self = .call(id: id, source: .init(rawValue: source.rawValue), isVoiceCall: isVoiceCall, secureChatId: secureChatId, isE2EeMeeting: isE2EeMeeting, onError: onError)
    }

    init(openPlatform id: String, isVoiceCall: Bool) {
        self = .openPlatform(id: id, isVoiceCall: isVoiceCall)
    }
}

extension StartMeetingParams: CustomStringConvertible {
    public var description: String {
        switch entry {
        case .preview(let params):
            return params.description
        case .noPreview(let params):
            return params.description
        default:
            return "\(entry)"
        }
    }
}

private extension MeetingFrontier {
    // PRD: https://bytedance.feishu.cn/docx/NYOrddGejoKbTkx2hLOcjnBJnRf, 后面会跟随旧版密聊下掉
    static func showSecretChatAlert(isGroupMeeting: Bool, isVoiceCall: Bool, _ confirmAction: @escaping () -> Void) {
        Logger.meeting.info("showSecretChatAlert(isGroupMeeting: \(isGroupMeeting))")
        VCTracker.post(name: .vc_secretchat_video_call_confirm_popup_view)
        var title = isVoiceCall ? I18n.View_G_VoiceCallNoEEE_Title : I18n.View_G_VideoNoETEEncryption
        var message = isVoiceCall ? I18n.View_G_VoiceCallNoEEE_Desc : I18n.View_G_ConfirmStartRegularCall
        var rightTitle = I18n.View_G_StartCallButton
        if isGroupMeeting {
            title = I18n.View_G_VideoMeetNoETEEncryption
            message = I18n.View_G_ConfirmJoinRegularMeet
            rightTitle = I18n.View_G_Window_Confirm_Button
        }
        ByteViewDialog.Builder()
            .id(.requestLivingFromHost)
            .title(title)
            .message(message)
            .adaptsLandscapeLayout(true)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                Logger.meeting.info("showSecretChatAlert(isGroupMeeting: \(isGroupMeeting)) cancelled")
                VCTracker.post(name: .vc_secretchat_video_call_confirm_popup_click, params: ["click": "cancel"])
            })
            .rightTitle(rightTitle)
            .rightHandler({ _ in
                Logger.meeting.info("showSecretChatAlert(isGroupMeeting: \(isGroupMeeting)) confirmed")
                VCTracker.post(name: .vc_secretchat_video_call_confirm_popup_click, params: ["click": "video_call"])
                confirmAction()
            })
            .show()
    }
}

private extension StartCallParams {
    var shouldShowSecretAlert: Bool {
        !isE2EeMeeting && !secureChatId.isEmpty
    }
}

public struct PstnPhonesParams {
    public let meetingNumber: String
    public let phones: [PSTNPhone]

    public init(meetingNumber: String, phones: [PSTNPhone]) {
        self.meetingNumber = meetingNumber
        self.phones = phones
    }
}
