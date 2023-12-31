//
//  JoinMeetingUtil.swift
//  ByteView
//
//  Created by kiri on 2022/7/21.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork
import ByteViewMeeting
import ByteViewUI
import ByteViewSetting

final class JoinMeetingUtil {
    static func handleJoinMeetingBizError(service: MeetingBasicService?, _ error: VCError) {
        let noHandleError: [VCError] = [.collaborationBlocked, .collaborationBeBlocked, .collaborationNoRights, .replaceJoinUnsupported]
        if noHandleError.contains(error) {
            // 部分错误由后端处理，不需要端上额外处理
            return
        }
        guard let service = service else { return }
        if error == .hostVersionLow && service.setting.shouldUpdateLark {
            let router = service.larkRouter
            ByteViewDialog.Builder()
                .id(.updateApp)
                .title(I18n.View_M_UpdateSoftwareTitle)
                .message(I18n.View_M_UpdateSoftwareInfo)
                .leftTitle(I18n.View_G_NoThanksButton)
                .rightTitle(I18n.View_M_GetUpdate)
                .rightHandler({ _ in
                    MeetingManager.shared.leaveAll(.forceExit)
                    router.gotoUpgrade()
                })
                .show()
            return
        }
        // 忽略已经被通用错误处理处理过的错误
        guard !error.isHandled else { return }
        let errorMsg = error.description
        if error == .unknown || errorMsg.isEmpty {
            Toast.show(I18n.View_M_FailedToJoinMeeting)
        } else {
            Toast.show(errorMsg)
        }
    }
}

extension MeetingSession {
    func handleJoinMeetingBizError(_ error: VCError) {
        JoinMeetingUtil.handleJoinMeetingBizError(service: service, error)
    }
}

extension VideoChatInfo {
    func checkMyself(_ account: ByteviewUser) -> Bool {
        if self.participants.contains(where: { $0.user == account }) {
            return true
        }

        // account 的 deviceId 为空表示会议已结束，此时无需上报异常埋点
        // 这个逻辑是为了解决用户预览页点击入会后立刻收到后端入会推送，前一个会议会走到 acceptOther，session 数据都被清理
        guard !account.deviceIdIsEmpty else { return false }
        let meetingId = self.id
        Logger.meeting.error("[\(meetingId)] checkMyself failed, account = \(account)")
        // myself == nil，后端推送的参会人列表中没有与自己 accountID 相匹配的项，如果发现此时会中有一个 uid 与自己相同的用户，上报 deviceID 不匹配埋点
        if let myself = self.participants.first(where: {
            $0.user.id == account.id && $0.status == .onTheCall && $0.deviceType == .mobile
        }) {
            Logger.meeting.error("[\(meetingId)] checkMyself failed because of inconsistent device ID: myselfInServer = \(myself.user)")
            DevTracker.post(.warning(.passport_inconsistent_did).category(.meeting)
                .params([.conference_id: meetingId, "account_id": account.identifier, "participant_account_id": myself.user.identifier]))
        }
        return false
    }
}
