//
//  ToolBarSettingsItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewSetting
import ByteViewTracker
import ByteViewUI

final class ToolBarSettingsItem: ToolBarItem {
    override var itemType: ToolBarItemType { .settings }

    override var title: String {
        I18n.View_G_Settings
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .settingFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .settingOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        .more
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        .more
    }

    override func clickAction() {
        MeetingTracksV2.trackMeetingClickOperation(action: .clickSetting,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: true)
        if Display.phone, VCScene.isLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
        }
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: "click_settings"])
            let meeting = self.meeting
            let settingContext = InMeetSettingContext(meeting: meeting, context: self.resolver.viewContext)
            let handler = InMeetSettingHandlerImpl(meeting: meeting, context: self.resolver.viewContext)
            let vc = meeting.setting.ui.createInMeetSettingViewController(context: settingContext, handler: handler)
            meeting.router.presentDynamicModal(vc,
                                              regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                              compactConfig: .init(presentationStyle: .fullScreen, needNavigation: true))
        }
    }
}
