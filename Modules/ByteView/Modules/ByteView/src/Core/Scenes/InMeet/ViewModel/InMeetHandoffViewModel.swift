//
//  InMeetHandoffViewModel.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/9/23.
//

import Foundation

final class InMeetHandoffViewModel: InMeetViewModelComponent {

    struct Key {
        static let HANDOFF_ACTIVITY_TYPE = "com.lark.handoff.meeting_transfer"
        static let MEETING_ID = "meetingId"
        static let USER_ID = "userId"
        static let TOPIC = "topic"
        static let IS_WEBINAR = "isWebinar"
        static let IS_SECRET = "isSecret"
        static let IS_INTERVIEW = "isInterview"
    }

    let meeting: InMeetMeeting

    private var activity: NSUserActivity?

    init(resolver: InMeetViewModelResolver) {
        self.meeting = resolver.meeting
        startHandOff()
        meeting.router.addListener(self)
        // 处于后台、小窗时，需要取消handoff广播
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    func startHandOff() {
        let activity = NSUserActivity(activityType: Key.HANDOFF_ACTIVITY_TYPE)
        activity.userInfo = handoffUserInfo
        self.activity = activity
        activity.becomeCurrent()
    }

    func stopHandoff() {
        self.activity?.resignCurrent()
    }

    private var handoffUserInfo: [AnyHashable: Any] {
        let meetingId = self.meeting.meetingId
        let userId = self.meeting.userId
        let topic = self.meeting.topic
        let isWebinar = self.meeting.subType == .webinar
        let isSecret = self.meeting.isE2EeMeeing
        let isInterview = self.meeting.isInterviewMeeting
        return [Key.MEETING_ID: meetingId, Key.USER_ID: userId, Key.TOPIC: topic,
                Key.IS_WEBINAR: isWebinar, Key.IS_SECRET: isSecret, Key.IS_INTERVIEW: isInterview]
    }
}

extension InMeetHandoffViewModel {
    @objc private func didBecomeActive() {
        startHandOff()
    }

    @objc private func didEnterBackground() {
        stopHandoff()
    }
}

extension InMeetHandoffViewModel: RouterListener {
    func didChangeWindowFloatingBeforeAnimation(_ isFloating: Bool, window: FloatingWindow?) {
        if isFloating {
            stopHandoff()
        } else {
            startHandOff()
        }
    }
}
