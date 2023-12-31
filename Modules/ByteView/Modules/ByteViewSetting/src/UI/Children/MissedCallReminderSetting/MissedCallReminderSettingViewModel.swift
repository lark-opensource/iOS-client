//
//  MissedCallReminderSettingViewModel.swift
//  ByteView
//
//  Created by fakegourmet on 2022/4/2.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewNetwork
import ByteViewCommon
import ByteViewTracker

final class MissedCallReminderSettingViewModel: UserSettingListener {

    @RwAtomic
    private(set) var missedCallReminder: ViewUserSetting.MeetingAdvanced.MissedCallReminder

    private var updateAction: (() -> Void)?

    let service: UserSettingManager
    init(service: UserSettingManager) {
        self.service = service
        self.missedCallReminder = service.viewUserSetting.meetingAdvanced.missedCallReminder
        service.addListener(self, for: .viewUserSetting)
    }

    func bindAction(_ action: (() -> Void)?) {
        updateAction = action
    }

    func updateSetting(_ reminder: ViewUserSetting.MeetingAdvanced.MissedCallReminder.Reminder) {
        missedCallReminder.reminder = reminder
        service.updateViewUserSetting { $0.reminder = reminder }
        VCTracker.post(name: .setting_meeting_missed_call_click, params: [
            .click: reminder == .bot ? "meeting_assistant_notify" : "navigation_bar_red_dot", "target": "none"
        ])
    }

    func didChangeUserSetting(_ setting: UserSettingManager, _ data: UserSettingChange) {
        if case let .viewUserSetting(change) = data {
            missedCallReminder = change.value.meetingAdvanced.missedCallReminder
            updateAction?()
        }
    }
}
