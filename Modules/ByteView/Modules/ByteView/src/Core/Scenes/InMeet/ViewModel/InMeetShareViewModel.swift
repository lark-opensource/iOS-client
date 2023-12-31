//
//  InMeetShareViewModel.swift
//  ByteView
//
//  Created by eesh-macmini-automation on 2023/3/15.
//

import Foundation
import ByteViewTracker
import ByteViewNetwork
import ByteViewRtcBridge

/// 处理通用共享内容（屏幕、文档、白板）相关逻辑
final class InMeetShareViewModel: InMeetViewModelComponent {
    private let meeting: InMeetMeeting
    private let logger = Logger.meeting
    private let httpClient: HttpClient
    private lazy var uploadShareStatusConfig = meeting.setting.uploadShareStatusConfig

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        self.httpClient = HttpClient(userId: resolver.meeting.userId)
        meeting.rtc.engine.addListener(self)
        meeting.push.notice.addObserver(self)
        NoticeService.shared.addInterceptor(self)
    }
}

extension InMeetShareViewModel: RtcListener, VideoChatNoticePushObserver, MeetingNoticeInterceptorListener {

    func onFirstRemoteVideoFrameDecoded(streamKey: RtcRemoteStreamKey) {
        guard streamKey.streamIndex == .screen else { return }
        // webinar 观众无需上报
        guard !meeting.isWebinarAttendee else { return }
        // 共享人无需上报
        guard !meeting.shareData.isSelfSharingContent else { return }

        guard let shareID = meeting.shareData.shareID else { return }

        // 限流策略
        // 根据 deviceID 大小（字典序）筛选前 x 位参会人，判断自己是否在前 x 位内
        var lowPariticipantsCount: Int = 0
        let myDeviceID = meeting.myself.deviceId
        for participant in meeting.participant.currentRoom.all {
            if participant.deviceId < myDeviceID {
                lowPariticipantsCount += 1
            }
        }
        guard lowPariticipantsCount < uploadShareStatusConfig.uploadStatusParticipantCount else { return }

        let meetingMeta = MeetingMeta(meetingID: meeting.meetingId, breakoutRoomID: meeting.data.breakoutRoomId)
        let request = UploadShareStatusRequest(meetingMeta: meetingMeta, shareID: shareID, shareType: .shareScreen, shareScreenStatus: .init(status: .firstFrameReceived))
        httpClient.getResponse(request) { _ in }
    }

    func didReceiveToast(extra: [String: String]) -> MeetingNoticeInterceptorListener.Intercepted {
        if meeting.shareData.isSelfSharingContent,
           let shareID = meeting.shareData.shareID,
           extra["only_show_toast_in_sharing"] == shareID {
            return true
        } else {
            return false
        }
    }

    func didReceiveNotice(_ notice: VideoChatNotice) {
        guard notice.meetingID == meeting.meetingId,
              let shareID = meeting.shareData.shareID,
              notice.extra["only_show_toast_in_sharing"] == shareID else { return }
        VCTracker.post(name: .vc_toast_status,
                       params: ["toast_name": "share_published", "share_id": "\(shareID)"])
        let persistingTime = notice.toastDurationMs > 0 ? TimeInterval(notice.toastDurationMs) / 1000 : nil
        httpClient.i18n.get(by: notice.msgI18NKey, defaultContent: notice.message, meetingId: notice.meetingID) {
            Toast.showOnVCScene($0, duration: persistingTime)
        }
    }
}
