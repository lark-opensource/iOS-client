//
//  VoipPushEntry.swift
//  ByteView
//
//  Created by kiri on 2022/7/28.
//

import Foundation
import ByteViewTracker
import ByteViewMeeting
import ByteViewNetwork
import ByteViewCommon


extension MeetingPrechecker {
    func handleVoipPushEntry(_ session: MeetingSession, pushInfo: VoIPPushInfo, completion: @escaping PrecheckOutput) {
        guard let service = session.service else { return }
        let context = MeetingPrecheckContext(service: service)
        let entrance = VoIPPushEntrance(params: pushInfo, context: context)
        session.precheckEntrance = entrance
        entrance.precheck(context: context) {
            switch $0 {
            case .success:
                completion(.success(.voipPush))
            case .failure(let e):
                completion(.failure(e))
            }
        }
    }
}

extension MeetingSession {
    func joinMeetingWithVoipPushInfo(_ info: VoIPPushInfo) {
        self.dualChannelPollVideoChatInfo(info)
    }

    func dualChannelPollVideoChatInfo(_ pushInfo: VoIPPushInfo, completion: ((Result<VideoChatInfo, Error>) -> Void)? = nil) {
        let startTime = CACurrentMediaTime()
        let meetingId = self.meetingId
        let account = self.account
        let request = RegisterClientInfoRequest(sourceType: .dualChannelPoll, status: .ringing, meetingIds: [meetingId])
        httpClient.getResponse(request) { [weak self] result in
            guard let self = self else { return }
            let cost = CACurrentMediaTime() - startTime
            self.log("poll videoChatInfo takes \(cost)s")
            /**
             * 存在 callkit 拉活 app 后， rust 启动后立即收到 idle push，但是 LarkRustClient 并没有启动完成，
             * 如果采用 status == .ringing 来获取 info 会导致匹配不到 videoChatInfo，
             * 从而使用 mock 的 ringing 状态数据去向 callkit reportNewIncomingCall，
             * rust 端在 LarkRustClient 注册成功后，不会再推送 idle 的状态，
             * 就会导致其他端已经接听或挂断，callkit 响铃直到超时才挂断。
             * 现先改动成，不匹配状态，reportNewIncomingCall 后 `idle` 状态的直接 end。
             */
            if case let .success(resp) = result, let info = resp.infos.first(where: {
                $0.id == meetingId && $0.participants.first(where: { p in p.user == account }) != nil
            }) {
                self.log("dualChannelPoll get info success: \(info)")
                JoinMeetingQueue.shared.send(JoinMeetingMessage(info: info, type: .dualChannelPoll, sessionId: self.sessionId))
                completion?(.success(info))
            } else {
                self.loge("failed get VideoChatInfo from dualChannelPoll")
                self.leave(.voipDualPullFailed(uuid: pushInfo.uuid))
                completion?(.failure(VCError.unknown))
            }
        }
    }
}
