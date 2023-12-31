//
//  ToolBarCountdownItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/6/6.
//

import Foundation
import ByteViewUI
import ByteViewTracker
import ByteViewSetting

final class ToolBarCountdownItem: ToolBarItem {
    static let logger = Logger.ui
    private weak var preEndAlert: ByteViewDialog?
    private weak var closeAlert: ByteViewDialog?
    private let manager: CountDownManager

    override var itemType: ToolBarItemType { .countDown }

    override var title: String {
        I18n.View_G_Countdown_Button
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .burnlifeNotimeFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .burnlifeNotimeOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        meeting.setting.showsCountdown ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        meeting.setting.showsCountdown ? .more : .none
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.manager = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        self.addBadgeListener()
        meeting.setting.addListener(self, for: .showsCountdown)
    }

    deinit {
        preEndAlert?.dismiss()
        closeAlert?.dismiss()
    }

    override func clickAction() {
        VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "countdown", "is_more": true])

        if !manager.enabled {
            Toast.showOnVCScene(I18n.View_G_BreakRoomNoCount)
            return
        }

        var noAuthToast: Bool = false
        if !manager.canOperate.0 {
            if Display.phone || VCScene.rootTraitCollection?.horizontalSizeClass == .compact {
                noAuthToast = true
            } else if manager.state == .close {
                noAuthToast = true
            }
        }
        if noAuthToast, let message = manager.canOperate.1?.message {
            VCTracker.post(name: .vc_meeting_onthecall_click, params: [.click: "no_auth_hover_countdown"])
            Toast.showOnVCScene(message)
            return
        }

        shrinkToolBar { [weak self] in
            guard let self = self else { return }
            switch self.manager.state {
            case .close:
                // 可开启
                self.showViewController(style: .start, source: .more)
            case .start:
                // 可延长、结束
                if Display.phone || VCScene.rootTraitCollection?.horizontalSizeClass == .compact {
                    self.showActionSheet([self.prolongSheetAction(), self.preEndSheetAction()])
                } else if self.manager.boardFolded {
                    self.manager.foldBoard(false)
                } else {
                    // no reaction (by UX)
                }
            case .end:
                // 可重设、关闭
                if Display.phone || VCScene.rootTraitCollection?.horizontalSizeClass == .compact {
                    self.showActionSheet([self.resetSheetAction(), self.closeSheetAction()])
                } else if self.manager.boardFolded {
                    self.manager.foldBoard(false)
                } else {
                    // no reaction (by UX)
                }
            }
        }
    }

    private func showViewController(style: CountDownPickerViewController.Style, source: CountDownPickerViewModel.PageSource) {
        let vm = CountDownPickerViewModel(meeting: meeting, manager: manager)
        vm.pageSource = source
        vm.style = style
        let viewController = CountDownPickerViewController(viewModel: vm)
        meeting.router.presentDynamicModal(viewController,
                                          regularConfig: .init(presentationStyle: .formSheet, needNavigation: true),
                                          compactConfig: .init(presentationStyle: .pan, needNavigation: true))
    }

    private func prolongSheetAction() -> SheetAction {
        return SheetAction.init(title: I18n.View_G_Extend_Button) { [weak self] _ in
            self?.showViewController(style: .prolong, source: .prolong)
        }
    }

    private func preEndSheetAction() -> SheetAction {
        return SheetAction.init(title: I18n.View_G_EndButton) { [weak manager] _ in
            ByteViewDialog.Builder()
                .id(.preEndCountDown)
                .needAutoDismiss(true)
                .title(I18n.View_G_ConfirmEndCountdown_Pop)
                .message(nil)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    VCTracker.post(name: .vc_countdown_click, params: [.click: "close_ahead_of_time", "sub_click_type": "cancel"])
                })                .rightTitle(I18n.View_G_EndButton)
                .rightHandler({ [weak manager] _ in
                    VCTracker.post(name: .vc_countdown_click, params: [.click: "close_ahead_of_time", "sub_click_type": "confirm"])
                    manager?.requestPreEnd()
                })
                .show { [weak self] alert in
                    if let self = self {
                        self.preEndAlert = alert
                    } else {
                        alert.dismiss()
                    }
                }
        }
    }

    private func resetSheetAction() -> SheetAction {
        return SheetAction.init(title: I18n.View_G_Reset_Icon) { [weak self] _ in
            VCTracker.post(name: .vc_countdown_click, params: [.click: "reset"])
            self?.showViewController(style: .start, source: .reset)
        }
    }

    private func closeSheetAction() -> SheetAction {
        return SheetAction.init(title: I18n.View_G_CloseButton) { [weak manager] _ in
            VCTracker.post(name: .vc_countdown_click, params: [.click: "close"])
            ByteViewDialog.Builder()
                .id(.closeCountDown)
                .needAutoDismiss(true)
                .title(I18n.View_G_OffCountdownForAllPop)
                .message(nil)
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler({ _ in
                    VCTracker.post(name: .vc_countdown_click, params: [.click: "close_double_check", "is_check": false])
                })
                .rightTitle(I18n.View_G_StopCountdown_Button)
                .rightHandler({ [weak manager] _ in
                    VCTracker.post(name: .vc_countdown_click, params: [.click: "close_double_check", "is_check": true])
                    manager?.requestClose()
                })
                .show { [weak self] alert in
                    if let self = self {
                        self.closeAlert = alert
                    } else {
                        alert.dismiss()
                    }
                }
        }
    }

    private func showActionSheet(_ actions: [SheetAction]) {
        let appearance = ActionSheetAppearance(backgroundColor: Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody,
                                               titleColor: UIColor.ud.textPlaceholder)
        let actionSheet = ActionSheetController(title: I18n.View_G_Countdown_Button, appearance: appearance)
        actionSheet.modalPresentation = .popover
        for action in actions {
            actionSheet.addAction(action)
        }
        let cancelAction = SheetAction.init(title: I18n.View_G_CancelButton,
                                            sheetStyle: .cancel,
                                            handler: { _ in })
        actionSheet.addAction(cancelAction)
        meeting.router.presentDynamicModal(actionSheet, config: .init(presentationStyle: .pan))
    }
}

extension ToolBarCountdownItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        notifyListeners()
    }
}
