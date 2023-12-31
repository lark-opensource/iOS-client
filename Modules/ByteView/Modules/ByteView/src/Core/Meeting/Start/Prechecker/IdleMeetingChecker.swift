//
//  IdleMeetingChecker.swift
//  ByteView
//
//  Created by lutingting on 2023/8/16.
//

import Foundation
import ByteViewMeeting
import ByteViewUI
import ByteViewNetwork

extension PrecheckBuilder {
    @discardableResult
    func checkIdleMeeting(identifier: String, isJoin: Bool, type: MeetingType, isRejoin: Bool) -> Self {
        checker(IdleMeetingChecker(identifier: identifier, isJoin: isJoin, type: type, isRejoin: isRejoin))
        return self
    }
}

final class IdleMeetingChecker: MeetingPrecheckable {
    let identifier: String
    let isJoin: Bool
    let type: MeetingType
    let isRejoin: Bool
    var nextChecker: MeetingPrecheckable?

    init(identifier: String, isJoin: Bool, type: MeetingType, isRejoin: Bool) {
        self.identifier = identifier
        self.isJoin = isJoin
        self.type = type
        self.isRejoin = isRejoin
    }

    private static weak var noOtherMeetingAlert: ByteViewDialog?

    /// 呼叫/响铃/通话中/会中 拦截入会
    func check(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        context.isNoOtherChecking = true
        guard let session = MeetingManager.shared.currentSession else {
            checkNext(context, completion: completion)
            return
        }
        // 当前有一个会议或者通话
        // 发起1v1则阻断逻辑后弹toast提示
        // 发起或者加入会议, 如果当前currentModule是voip则阻断逻辑弹toast提示
        if session.isActive, isRejoin || type == .call {
            let isRinging = session.state == .ringing
            let text = isRinging ? (isRejoin ? I18n.View_M_IncomingCallCannotJoin : I18n.View_G_IncomingCall) : I18n.View_G_CurrentlyInCall
            let vcerror: VCError = isRinging ? .hostIsInRinging : .hostBusy
            /// 可能会在vc的window上弹，不能用LarkToast
            Toast.show(text)
            completion(.failure(vcerror))
        } else if session.sessionId != context.sessionId, session.isLivedInLocal(identifier, currentSession: session) {
            Logger.precheck.info("[\(context.sessionId)] user already in session \(session), identifier = \(identifier)")
            session.service?.router.setWindowFloating(false)
            VCScene.activateIfNeeded()
            completion(.failure(VCError.hostIsInVC))
        } else if session.sessionType == .vc, !session.isEnd, session.sessionId != context.sessionId, !session.isCheckerEnterLeave {
            checkNoOtherMeeting(context, session: session, completion: completion)
        } else {
            checkNext(context, completion: completion)
        }
    }

    private func checkNoOtherMeeting(_ context: MeetingPrecheckContext, session: MeetingSession, completion: @escaping PrecheckHandler) {
        let sessionId = context.sessionId
        if session.state == .start || session.state == .preparing {
            session.isCheckerEnterLeave = true
            session.leave { [weak self] _ in
                guard let self = self else {
                    completion(.failure(VCError.unknown))
                    return
                }
                self.checkNext(context, completion: completion)
            }
            return
        }

        Logger.precheck.info("show noOtherMeeting alert: \(session)")
        // 弹窗结束当前会议进入preview页面发起/加入另一通会议
        let title: String
        let message: String
        let isShareScreenMeeting = session.setting?.meetingSubType == .screenShare
        if isShareScreenMeeting {
            title = I18n.View_G_SharingMirroringTitle
            message = isJoin ? I18n.View_G_SharingWillEndIfJoinMeeting : I18n.View_G_SharingWillEndIfStartMeeting
        } else if session.state == .ringing {
            title = I18n.View_G_IncomingCall
            message = isJoin ? I18n.View_G_IfJoinMeetingHangUpCall : I18n.View_G_IfStartMeetingHangUpCall
        } else {
            title = I18n.View_G_CurrentlyInCall
            message = isJoin ? I18n.View_G_IfJoinMeetingEndCall : I18n.View_G_IfStartMeetingEndCall
        }
        let previousMeetingId = session.meetingId
        let previousInteractiveId = session.myself?.interactiveId
        Self.noOtherMeetingAlert?.dismiss()
        ByteViewDialog.Builder()
            .colorTheme(.followSystem)
            .inVcScene(false)
            .title(title)
            .message(message)
            .leftTitle(I18n.View_G_CancelButton)
            .leftHandler({ _ in
                JoinTracks.trackJoinMeetingPopup(placeholderId: sessionId, action: .cancel,
                                                 previousMeetingId: previousMeetingId, previousInteractiveId: previousInteractiveId)
                completion(.failure(VCError.userCancelOperation))
            })
            .rightTitle(I18n.View_G_ConfirmButton)
            .rightHandler({ [weak self, weak session] (_) in
                guard let self = self, let session = session else {
                    completion(.failure(VCError.unknown))
                    return
                }
                JoinTracks.trackJoinMeetingPopup(placeholderId: sessionId, action: .confirm,
                                                 previousMeetingId: previousMeetingId, previousInteractiveId: previousInteractiveId)
                BusyRingingManager.shared.meeting?.declineRinging()
                session.leave(.startAnother(isJoined: self.isJoin)) { _ in
                    self.checkNext(context, completion: completion)
                }
            })
            .show { alert in
                Self.noOtherMeetingAlert = alert
            }
    }

    private func checkNext(_ context: MeetingPrecheckContext, completion: @escaping PrecheckHandler) {
        context.isNoOtherChecking = false
        checkNextIfNeeded(context, completion: completion)
    }

}

private extension MeetingSession {

    func isLivedInLocal(_ identifier: String, currentSession: MeetingSession) -> Bool {
        // 日历会议有可能会从群加入，所以日历判断放到最后
        guard !identifier.isEmpty, identifier != "0" else { return false }
        if state == .lobby {
            if case .meetingId = previewEntryParams?.idType, let meetingId = previewEntryParams?.id {
                return meetingId == currentSession.meetingId
            } else if let id = currentSession.previewEntryParams?.id, let currentIdType = currentSession.previewEntryParams?.idType, let idType = previewEntryParams?.idType {
                switch currentIdType {
                case .groupId, .uniqueId, .interviewUid, .reservationId:
                    return idType == currentIdType && identifier == id
                default:
                    return false
                }
            }
        } else if let info = videoChatInfo, state == .onTheCall {
            if info.id == identifier {
                return true
            } else if info.groupId == identifier || imChatId == identifier {
                return true
            } else if info.meetNumber == identifier {
                return true
            } else if info.uniqueId == identifier {
                return true
            } else if info.meetingSource == .vcFromCalendar {
                return previewEntryParams?.calendarId == identifier
            } else if case .interviewId(let interviewId) = joinMeetingParams?.joinType {
                return interviewId == identifier
            }
        }
        return false
    }
}

private extension PreviewEntryParams {
     var meetingId: String? {
         switch idType {
         case .meetingId:
             return id
         default:
             return nil
         }
     }

    var calendarId: String? {
        switch idType {
        case .uniqueId:
            return id
        default:
            return nil
        }
    }
}

private extension MeetingSession {
    var isCheckerEnterLeave: Bool {
        get { attr(.isCheckerEnterLeave, false) }
        set { setAttr(newValue, for: .isCheckerEnterLeave) }
    }
}

private extension MeetingAttributeKey {
    static let isCheckerEnterLeave: MeetingAttributeKey = "vc.isCheckerEnterLeave"
}
