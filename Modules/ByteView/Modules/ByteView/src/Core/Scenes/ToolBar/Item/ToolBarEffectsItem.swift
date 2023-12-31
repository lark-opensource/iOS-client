//
//  ToolBarEffectsItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewSetting
import ByteViewUI

final class ToolBarEffectsItem: ToolBarItem {
    override var itemType: ToolBarItemType { .effects }

    override var title: String {
        I18n.View_G_Effects
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .effectsFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .effectsOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsEffects ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsEffects ? .more : .none
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        //如果是面试官，之前没有设置为面试会议，则处理面试会议
        if meeting.isInterviewMeeting, meeting.myself.role == .interviewer, let service = meeting.effectManger?.virtualBgService, service.meetingVirtualBgType != .people {
            service.addJob(type: .people)
        }
        meeting.setting.addListener(self, for: .showsEffects)
    }

    override func clickAction() {
        MeetingTracksV2.trackMeetingClickOperation(action: .clickEffect,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: true)
        if Display.phone, VCScene.isLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
        }
        shrinkToolBar { [weak self] in
            guard let self = self, let effectManger = self.meeting.effectManger else { return }
            MeetSettingTracks.trackTapLab()

            let isInterviewer: Bool = self.meeting.isInterviewMeeting && self.meeting.myself.role == .interviewer
            let labViewModel = InMeetingLabViewModel(service: self.meeting.service, effectManger: effectManger, fromSource: .inMeet, isInterviewer: isInterviewer, isCameraOnBeforeLab: !self.meeting.camera.isMuted)
            Logger.lab.info("lab bg: labViewModel from meeting isInterview: \(isInterviewer)")

            let viewController = InMeetingLabViewController(viewModel: labViewModel)
            viewController.location = .settings
            self.meeting.router.presentDynamicModal(viewController,
                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                              compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
        }
    }
}

extension ToolBarEffectsItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}
