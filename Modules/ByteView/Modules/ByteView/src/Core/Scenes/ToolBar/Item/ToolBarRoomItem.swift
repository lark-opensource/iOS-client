//
//  ToolBarRoomItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import ByteViewTracker
import ByteViewNetwork
import UIKit
import LarkLocalizations
import ByteViewSetting
import ByteViewUI

/// 扫描会议室/会议室已连接
/// - PRD：https://bytedance.feishu.cn/docx/WXITdBzSjo4m4JxmWIkc5B0hnZf
/// - PRD: https://bytedance.feishu.cn/docx/doxcnye6Kau7za3vHrc5IUfaWLc
final class ToolBarRoomItem: ToolBarItem {
    override var itemType: ToolBarItemType { .room }

    override var title: String {
        hasJoinedRoom ? I18n.View_G_RoomConnected_Tab : I18n.View_G_ConnectToRoom_Button
    }

    override var filledIcon: ToolBarIconType {
        hasJoinedRoom ? .customColoredIcon(key: .videoSystemFilled, color: UIColor.ud.colorfulGreen) :
            .icon(key: .videoSystemFilled)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        isJoinRoomEnabled ? .more : .none
    }

    private var hasJoinedRoom: Bool {
        meeting.myself.settings.targetToJoinTogether?.type == .room
    }

    private var isJoinRoomEnabled: Bool {
        meeting.setting.showsJoinRoom
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        if Display.phone {
            meeting.setting.addListener(self, for: .showsJoinRoom)
            meeting.addMyselfListener(self, fireImmediately: false)
        }
        Logger.ui.info("init ToolBarRoomItem, isJoinRoomEnabled = \(self.isJoinRoomEnabled)")
    }

    override func clickAction() {
        let room = meeting.myself.settings.targetToJoinTogether
        if room == nil {
            /// 扫描会议室埋点
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "more_ultrasonic_room_scan"])
            if !self.meeting.setting.isUltrawaveEnabled {
                Toast.show(I18n.View_UltraOnToUseThis_Note)
                return
            }
        }
        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            if Display.phone, VCScene.isLandscape {
                MeetingTracksV2.trackChangeOrientation(toLandscape: false, reason: .click_function)
            }
            if (room?.id) != nil {
                self.showConnectedPage()
            } else {
                self.scanAction()
            }
        }
    }

    private func scanAction() {
        let vm = JoinRoomTogetherViewModel(service: meeting.service, provider: InMeetJoinRoomProvider(meeting: meeting), source: .toolbarMore)
        let vc = JoinRoomTogetherViewController(viewModel: vm)
        let config = DynamicModalConfig(presentationStyle: .pan)
        meeting.router.presentDynamicModal(vc, regularConfig: config, compactConfig: config)
    }

    private func showConnectedPage() {
        let vm = JoinRoomTogetherViewModel(service: meeting.service, provider: InMeetJoinRoomProvider(meeting: meeting), source: .toolbarMore)
        let vc = JoinRoomTogetherViewController(viewModel: vm)
        let config = DynamicModalConfig(presentationStyle: .pan)
        meeting.router.presentDynamicModal(vc, regularConfig: config, compactConfig: config)
    }
}

extension ToolBarRoomItem: MyselfListener {
    func didChangeMyself(_ myself: Participant, oldValue: Participant?) {
        let room = myself.settings.targetToJoinTogether
        if room == oldValue?.settings.targetToJoinTogether && myself.isInMainBreakoutRoom == oldValue?.isInMainBreakoutRoom {
            return
        }
        notifyListeners()
    }
}

extension ToolBarRoomItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}
