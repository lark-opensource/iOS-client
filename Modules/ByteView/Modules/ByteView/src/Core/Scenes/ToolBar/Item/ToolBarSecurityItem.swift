//
//  ToolBarSecurityItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewTracker
import ByteViewSetting
import ByteViewUI

final class ToolBarSecurityItem: ToolBarItem {
    override var itemType: ToolBarItemType { .security }

    override var title: String {
        I18n.View_MV_Security_IconButton
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .safeVcFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .safeVcOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsHostControl ? .custom : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsHostControl ? .right : .none
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.setting.addListener(self, for: .showsHostControl)
    }

    override func clickAction() {
        openHostControlPage()
    }

    func muteAll() {
        meeting.microphone.muteAll(true)
        UserActionTracks.trackRequestAllMicAction(isOn: false)
    }

    func unmuteAll() {
        if meeting.participant.currentRoom.count > meeting.setting.maxSoftRtcNormalMode {
            Toast.showOnVCScene(I18n.View_M_CanNotUnmuteAll)
        } else {
            meeting.microphone.muteAll(false)
        }
        UserActionTracks.trackRequestAllMicAction(isOn: true)
    }

    func openHostControlPage() {
        MeetingTracksV2.trackMeetingClickOperation(action: .clickHostPanel,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: true)
        if Display.phone, VCScene.isLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
        }
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            let context = InMeetSecurityContextImpl(meeting: self.meeting, fromSource: .toolbar)
            let vc = self.meeting.setting.ui.createInMeetSecurityViewController(context: context)
            self.meeting.router.presentDynamicModal(vc,
                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                              compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
        }
    }
}

extension ToolBarSecurityItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}
