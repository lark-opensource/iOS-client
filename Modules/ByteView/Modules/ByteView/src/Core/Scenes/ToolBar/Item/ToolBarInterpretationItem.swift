//
//  ToolBarInterpretationItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewNetwork
import ByteViewTracker
import ByteViewSetting
import ByteViewUI

final class ToolBarInterpretationItem: ToolBarItem {
    private let interpretationViewModel: InMeetInterpreterViewModel

    override var itemType: ToolBarItemType { .interpretation }

    override var title: String {
        I18n.View_G_InterpretationShort
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .languageFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .languageOutlined)
    }

    override var isEnabled: Bool {
        meeting.setting.isInterpretEnabled
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        guard meeting.setting.showsInterpret else { return .none }
        if meeting.isWebinarAttendee {
            return meeting.setting.isMeetingOpenInterpretation ? .more : .none
        } else {
            return .more
        }
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        guard meeting.setting.showsInterpret else { return .none }
        if meeting.isWebinarAttendee {
            return meeting.setting.isMeetingOpenInterpretation ? .more : .none
        } else {
            return .more
        }
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.interpretationViewModel = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.updateInterpretationInfo()
        self.addBadgeListener()
        meeting.setting.addListener(self, for: [.showsInterpret, .isInterpretEnabled, .isMeetingOpenInterpretation])
    }

    override func clickAction() {
        if !meeting.setting.hasCohostAuthority && !meeting.setting.isMeetingOpenInterpretation {
            Toast.show(I18n.View_MV_OnlyHostInterpretation_Toast)
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "no_auth_hover_interpretation",
                                                                       "is_more": true,
                                                                       "target": "vc_meeting_interpretation_view"])
            return
        }

        MeetingTracksV2.trackMeetingClickOperation(action: .clickInterpretation,
                                                   isSharingContent: meeting.shareData.isSharingContent,
                                                   isMinimized: meeting.router.isFloating,
                                                   isMore: true)
        if Display.phone, VCScene.isLandscape {
            MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
        }
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            if self.meeting.setting.isMeetingOpenInterpretation {
                let viewModel = SelectInterpreterChannelViewModel(meeting: self.meeting, interpretation: self.interpretationViewModel)
                let viewController = SelectInterpreterChannelViewController(viewModel: viewModel)
                self.meeting.router.presentDynamicModal(viewController,
                                                  regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                  compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
            } else {
                let viewModel = InterpreterManageViewModel(meeting: self.meeting)
                let viewController = InterpreterManageViewController(viewModel: viewModel)
                self.meeting.router.presentDynamicModal(viewController,
                                                  regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                  compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
            }
        }
        InterpreterTrack.clickToolBar()
    }

    private func updateInterpretationInfo() {
        let badgeType: ToolBarBadgeType = .text(I18n.View_Paid_Tag)
        if isEnabled && self.badgeType == badgeType {
            removeBadgeType(badgeType)
        } else if !isEnabled && self.badgeType != badgeType {
            updateBadgeType(badgeType)
        }
    }
}

extension ToolBarInterpretationItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        if key == .isInterpretEnabled {
            updateInterpretationInfo()
        }
        notifyListeners()
    }
}
