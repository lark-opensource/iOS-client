//
//  MeetingPushCenter.swift
//  ByteView
//
//  Created by kiri on 2023/5/19.
//

import Foundation
import ByteViewMeeting
import ByteViewNetwork

final class MeetingPushCenter {
    fileprivate let session: MeetingSession
    fileprivate var userId: String { session.userId }
    fileprivate var meetingId: String { session.meetingId }
    init(session: MeetingSession) {
        self.session = session

        // early loading for caching last value.
        _ = self.notice
        _ = self.fullLobby
        _ = self.vcManageNotify
    }

    private(set) lazy var notifyVideoChat = Push.notifyVideoChat.inSession(self, meetingId: \.id).ofType(NotifyVideoChatPushObserver.self) {
        $0.didNotifyVideoChat($1)
    }

    private(set) lazy var extraInfo = Push.videoChatExtra.inSession(self).ofType(VideoChatExtraInfoPushObserver.self) {
        $0.didReceiveExtraInfo($1)
    }

    private(set) lazy var combinedInfo = Push.videoChatCombinedInfo.inSession(self, meetingId: \.inMeetingInfo.id)
        .ofType(VideoChatCombinedInfoPushObserver.self) {
            $0.didReceiveCombinedInfo(inMeetingInfo: $1.inMeetingInfo, calendarInfo: $1.calendarInfo)
        }

    private(set) lazy var heartbeatStop = Push.heartbeatStop.inSession(self, meetingId: \.token)

    private(set) lazy var fullParticipants = Push.fullParticipants.inSession(self, meetingId: \.meetingID)
        .ofType(FullParticipantsPushObserver.self) {
            $0.didReceiveFullParticipants(meetingId: $1.meetingID, participants: $1.participants)
            $0.didReceiveFullWebinarAttendees(meetingId: $1.meetingID, attendees: $1.webinarAttendeeList, num: $1.webinarAttendeeNum)
            if let webinarViewList = $1.viewList {
                $0.didReceiveFullWebinarAttendeeView(meetingId: $1.meetingID, participants: webinarViewList.panels)
            }
        }

    private(set) lazy var participantChange = Push.participantChange.inSession(self, meetingId: \.meetingID)
        .ofType(ParticipantChangePushObserver.self) {
            $0.didReceiveParticipantChange($1)
        }

    private(set) lazy var attendeeChange =  Push.webinarAttendeeChange.inSession(self, meetingId: \.meetingID)
        .ofType(WebinarAttendeeChangePushObserver.self) {
            $0.didReceiveWebinarAttendeeChange($1)
        }

    private(set) lazy var attendeeViewChange = Push.webinarAttendeeViewChange.inSession(self, meetingId: \.meetingID)
        .ofType(WebinarAttendeeViewChangePushObserver.self) {
            $0.didReceiveWebinarAttendeeViewChange($1)
        }

    private(set) lazy var inMeetingChange = Push.inMeetingChangedInfo.inSession(self)
        .ofType(InMeetingChangedInfoPushObserver.self) { [weak self] ob, info in
            guard let self = self else { return }
            info.changes.forEach {
                if $0.meetingID == self.meetingId {
                    ob.didReceiveInMeetingChangedInfo($0)
                }
            }
        }

    private(set) lazy var fullLobby = Push.fullLobbyParticipants.inSession(self, meetingId: \.meetingID, cacheLast: true)
        .ofType(FullLobbyParticipantsPushObserver.self) {
            $0.didReceiveFullLobbyParticipants(meetingId: $1.meetingID, participants: $1.lobbyParticipants)
        }

    private(set) lazy var vcManageNotify = Push.vcManageNotify.inSession(self, meetingId: \.meetingID, cacheLast: true)
        .ofType(VCManageNotifyPushObserver.self) {
            $0.didReceiveManageNotify($1)
        }

    private(set) lazy var vcManageResult = Push.vcManageResult.inSession(self, meetingId: \.meetingID)
        .ofType(VCManageResultPushObserver.self) {
            $0.didReceiveManageResult($1)
        }

    private(set) lazy var notice = Push.videoChatNotice.inSession(self, meetingId: \.meetingID, cacheLast: true)
        .ofType(VideoChatNoticePushObserver.self) {
            $0.didReceiveNotice($1)
        }

    private(set) lazy var noticeUpdate = Push.videoChatNoticeUpdate.inSession(self, meetingId: \.meetingID)
        .ofType(VideoChatNoticeUpdatePushObserver.self) {
            $0.didReceiveNoticeUpdate($1)
        }

    private(set) lazy var chatMessage = Push.interactionMessages.inSession(self)
        .ofType(InteractionMessagePushObserver.self) { [weak self] ob, msg in
            guard let self = self else { return }
            msg.messages.forEach { message in
                ob.didReceiveInteractionMessage(message, expiredMsgPosition: msg.expiredMsgPosition)
            }
        }

    private(set) lazy var suggestedParticipants = Push.suggestedParticipants.inSession(self, meetingId: \.meetingID)
        .ofType(SuggestedParticipantsChangedPushObserver.self) {
            $0.didReceiveChanged($1)
        }

    private(set) lazy var chatters = Push.chatters.inSession(self)

    private(set) lazy var translateResults = Push.translateResults.inSession(self)
        .ofType(TranslateResultsPushObserver.self) {
            $0.didReceiveTranslateResults($1.translateInfos)
        }

    private(set) lazy var sendMessageToRtc = Push.sendMessageToRtc.inSession(self)
    private(set) lazy var messagePreviews = Push.messagePreviews.inSession(self)
    private(set) lazy var emojiPanel = Push.emojiPanel.inSession(self)
    private(set) lazy var userRecentEmojiEvent = ServerPush.userRecentEmoji.inSession(self, cacheLast: true)
    private(set) lazy var meetingKeyExchange = ServerPush.meetingKeyExchange.inSession(self)
}

protocol NotifyVideoChatPushObserver: AnyObject {
    func didNotifyVideoChat(_ info: VideoChatInfo)
}

protocol FullParticipantsPushObserver: AnyObject {
    func didReceiveFullParticipants(meetingId: String, participants: [Participant])
    func didReceiveFullWebinarAttendees(meetingId: String, attendees: [Participant], num: Int64?)
    func didReceiveFullWebinarAttendeeView(meetingId: String, participants: [Participant])
}

protocol ParticipantChangePushObserver: AnyObject {
    func didReceiveParticipantChange(_ message: MeetingParticipantChange)
}

protocol WebinarAttendeeChangePushObserver: AnyObject {
    func didReceiveWebinarAttendeeChange(_ message: MeetingParticipantChange)
}

protocol WebinarAttendeeViewChangePushObserver: AnyObject {
    func didReceiveWebinarAttendeeViewChange(_ message: MeetingParticipantChange)
}

protocol InMeetingChangedInfoPushObserver: AnyObject {
    func didReceiveInMeetingChangedInfo(_ data: InMeetingData)
}

protocol InteractionMessagePushObserver: AnyObject {
    func didReceiveInteractionMessage(_ message: VideoChatInteractionMessage, expiredMsgPosition: Int32?)
}

protocol TranslateResultsPushObserver: AnyObject {
    func didReceiveTranslateResults(_ infos: [TranslateInfo])
}

protocol SuggestedParticipantsChangedPushObserver: AnyObject {
    func didReceiveChanged(_ changed: InMeetingSuggestedParticipantsChanged)
}

protocol VCManageNotifyPushObserver: AnyObject {
    func didReceiveManageNotify(_ notify: VCManageNotify)
}

protocol VCManageResultPushObserver: AnyObject {
    func didReceiveManageResult(_ result: VCManageResult)
}

protocol VideoChatCombinedInfoPushObserver: AnyObject {
    func didReceiveCombinedInfo(inMeetingInfo: VideoChatInMeetingInfo, calendarInfo: CalendarInfo?)
}

protocol VideoChatExtraInfoPushObserver: AnyObject {
    func didReceiveExtraInfo(_ extraInfo: VideoChatExtraInfo)
}

protocol VideoChatNoticePushObserver: AnyObject {
    func didReceiveNotice(_ notice: VideoChatNotice)
}

protocol VideoChatNoticeUpdatePushObserver: AnyObject {
    func didReceiveNoticeUpdate(_ update: VideoChatNoticeUpdate)
}

private extension PushReceiver {
    func inSession(_ pushCenter: MeetingPushCenter, meetingId: KeyPath<T, String>, cacheLast: Bool = false) -> PushDispatcher<T> {
        inUser(pushCenter.userId, cacheLast: cacheLast).filter { [weak pushCenter] in
            if let pushCenter = pushCenter, !pushCenter.meetingId.isEmpty, !pushCenter.session.isEnd,
               pushCenter.meetingId == $0[keyPath: meetingId] {
                return true
            } else {
                return false
            }
        }
    }

    func inSession(_ pushCenter: MeetingPushCenter, cacheLast: Bool = false) -> PushDispatcher<T> {
        inUser(pushCenter.userId, cacheLast: cacheLast).filter { [weak pushCenter] _ in
            if let pushCenter = pushCenter, !pushCenter.session.isEnd {
                return true
            } else {
                return false
            }
        }
    }
}
