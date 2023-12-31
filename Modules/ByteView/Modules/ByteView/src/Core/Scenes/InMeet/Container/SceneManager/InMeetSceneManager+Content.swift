//
// Created by liujianlong on 2022/8/18.
//

import Foundation
import ByteViewNetwork
import ByteViewSetting

extension InMeetSceneManager: InMeetDataListener, MeetingSettingListener {

    func setupData(meeting: InMeetMeeting) {
        self.is1V1 = (meeting.data.inMeetingInfo?.vcType ?? meeting.info.type) == .call
        self.hasHostCohostAuthority = meeting.setting.hasCohostAuthority
        meeting.data.addListener(self, fireImmediately: true)
        meeting.participant.addListener(self)
        meeting.webinarManager?.addListener(self, fireImmediately: true)
        meeting.setting.addListener(self, for: .hasCohostAuthority)
        meeting.shareData.addListener(self, fireImmediately: true)
    }

    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        Util.runInMainThread {
            self.hasHostCohostAuthority = isOn
        }
    }

    /// meetType改变，由inMeetingInfo变化触发，目前只有1v1升meet这一种case
    func didUpgradeMeeting(_ type: MeetingType, oldValue: MeetingType) {
        Util.runInMainThread {
           self.is1V1 = type == .call
        }
    }

    func didChangeInMeetingInfo(_ inMeetingInfo: VideoChatInMeetingInfo, oldValue: VideoChatInMeetingInfo?) {
        Util.runInMainThread {
            self.updateIsFocusing()
        }
    }

    func updateIsFocusing() {
        Util.runInMainThread {
            if self.meeting.participant.focusing != nil {
                // 主持人、主共享人，视图不受焦点视频管控
                let isHost = self.meeting.myself.isHost
                let isSelfSharingContent = self.meeting.shareData.shareContentScene.isSelfSharingContent(with: self.meeting.account)
                self.isFocusing = !isHost && !isSelfSharingContent
            } else {
                self.isFocusing = false
            }
        }
    }
}

extension InMeetSceneManager: WebinarRoleListener {
    func webinarDidChangeStageInfo(stageInfo: WebinarStageInfo?, oldValue: WebinarStageInfo?) {
        Util.runInMainThread {
            self.webinarStageInfo = stageInfo
        }
    }
}

extension InMeetSceneManager: InMeetShareDataListener {
    func didChangeShareContent(to newScene: InMeetShareScene, from oldScene: InMeetShareScene) {
        Util.runInMainThread {
            self.updateIsFocusing()
        }
    }
}


extension InMeetSceneManager: InMeetParticipantListener {

    func didChangeCurrentRoomParticipants(_ output: InMeetParticipantOutput) {
        Util.runInMainThread {
            self.updateHideSelf()
            self.updateHideNonVideo()
            self.updateIsFocusing()
        }
    }

    func didChangeFocusingParticipant(_ participant: Participant?, oldValue: Participant?) {
        updateIsFocusing()
    }
}
