//
//  ToolBarBreakoutControlItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewSetting

final class ToolBarBreakoutControlItem: ToolBarItem {
    private let breakoutRoomManager: BreakoutRoomManager

    override var itemType: ToolBarItemType { .breakoutRoomHostControl }

    override var title: String {
        I18n.View_G_BreakoutRooms
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .breakoutroomsFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .breakoutroomsOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsBreakoutRoomHostControl ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsBreakoutRoomHostControl ? .right : .none
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.breakoutRoomManager = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.breakoutRoomManager.hostControl.addListener(self)
        meeting.setting.addListener(self, for: .showsBreakoutRoomHostControl)
        self.addBadgeListener()
    }

    override func clickAction() {
        shrinkToolBar {
            self.breakoutRoomManager.hostControl.didTapToolbarItem()
            let viewController = BreakoutRoomHostControlViewController(viewModel: self.breakoutRoomManager)
            self.meeting.router.presentDynamicModal(viewController,
                                                    regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                                    compactConfig: .init(presentationStyle: .pageSheet, needNavigation: true))
        }
    }
}

extension ToolBarBreakoutControlItem: BreakoutRoomHostControlListener {
    func updateToolbarItem(badge: ToolBarBadgeType) {
        updateBadgeType(badge)
    }
}

extension ToolBarBreakoutControlItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}
