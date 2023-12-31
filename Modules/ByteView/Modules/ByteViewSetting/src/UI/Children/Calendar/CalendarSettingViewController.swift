//
//  CalendarSettingViewController.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/3/5.
//

import Foundation
import ByteViewCommon
import ByteViewTracker
import UniverseDesignColor
import UniverseDesignToast
import UniverseDesignIcon
import ByteViewNetwork

final class CalendarSettingViewController: CalendarBaseSettingVC {
    lazy var saveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_M_Save, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16.0, weight: .medium)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        button.addTarget(self, action: #selector(saveAction), for: .touchUpInside)
        button.isEnabled = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: saveButton)
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 14))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0))
    }

    override func reloadData() {
        super.reloadData()
        Util.runInMainThread { [weak self] in
            if let self = self, let vm = self.viewModel as? CalendarSettingViewModel {
                self.saveButton.isEnabled = vm.isSettingLoaded && vm.isSaveButtonEnabled
            }
        }
    }

    private var calendarViewModel: CalendarSettingViewModel? { viewModel as? CalendarSettingViewModel }
    @objc func saveAction() {
        self.trackback(isSave: true)
        guard let vm = calendarViewModel else { return }
        let hud = UDToast.showLoading(with: I18n.View_VM_Loading, on: self.view, disableUserInteraction: true)
        vm.submit { [weak self] result in
            hud.remove()
            guard let self = self else { return }
            switch result {
            case .success:
                self.doBack()
            case .failure:
                UDToast.showTips(with: I18n.View_G_SomethingWentWrong, on: self.view)
            }
        }
    }

    @objc func cancelAtion() {
        self.trackback(isSave: false)
        doBack()
    }

    private func trackback(isSave: Bool) {
        guard let vm = viewModel as? CalendarSettingViewModel else { return }
        let settings = vm.settings
        VCTracker.post(name: .vc_meeting_pre_setting_click, params: [
            .click: isSave ? "save" : "cancel",
            "is_change_permission": settings.vcSecuritySetting.trackText,
            "is_enable_pre_waitingroom": settings.putNoPermissionUserInLobby,
            "is_permit_join_before_owner": settings.canJoinMeetingBeforeOwnerJoined,
            "is_auto_mute": settings.muteMicrophoneWhenJoin,
            "is_auto_record": settings.autoRecord,
            "is_permit_self_opening_mic": !settings.isPartiUnmuteForbidden,
            "is_only_host_can_share": settings.onlyHostCanShare,
            "is_only_presenter_can_mark": settings.onlyPresenterCanAnnotate,
            "is_permit_rename": !settings.isPartiChangeNameForbidden,
            .location: vm.context.type == .start ? "create_cal" : "cal_detail"
        ])
    }
}

private extension CalendarSettings.SecuritySetting {
    var trackText: String {
        switch self {
        case .public:
            return "anyone"
        case .sameTenant:
            return "organizer_company"
        case .onlyCalendarGuest:
            return"event_guest"
        }
    }
}
