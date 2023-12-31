//
//  EventEditViewController+Save.swift
//  Calendar
//
//  Created by 张威 on 2020/4/25.
//

import UIKit
import LarkAlertController
import LarkActionSheet
import LarkUIKit
import RoundedHUD
import EENavigator
import UniverseDesignActionPanel
import UniverseDesignToast

// 处理日程保存相关交互

extension EventEditViewController {

    func handleSavingMessage(_ savingMessage: EventEditViewModel.SavingMessage) {
        let view: UIView = userResolver.navigator.mainSceneTopMost?.view ?? self.view
        switch savingMessage {
        case .actionSheet(let actionSheet):
            guard let buttonItem = navigationItem.rightBarButtonItem as? LKBarButtonItem else { return }
            let popSource = UDActionSheetSource(sourceView: buttonItem.button,
                                                sourceRect: buttonItem.button.bounds,
                                                arrowDirection: .up)
            let config = UDActionSheetUIConfig(popSource: popSource,
                                               dismissedByTapOutside: {
                actionSheet.cancelAction?.handler()
            })
            let actionSheetVC = UDActionSheet(config: config)

            actionSheet.actions.forEach { item in
                actionSheetVC.addItem(UDActionSheetItem(title: item.title,
                                                        titleColor: item.titleColor,
                                                        action: {
                    item.handler()
                }))
            }

            if let item = actionSheet.cancelAction {
                actionSheetVC.setCancelItem(text: item.title) {
                    item.handler()
                }
            }
            present(actionSheetVC, animated: true)
        case .alert(let alert):
            handleAlert(alert)
        case .meetingRoomApprovalAlert(let alert):
            LarkAlertController.showAddApproveInfoAlert(
                from: self,
                title: alert.title,
                itemTitles: alert.itemTitles,
                disposeBag: disposeBag,
                cancelText: BundleI18n.Calendar.Calendar_Detail_BackToEdit,
                cancelAction: alert.cancelHandler,
                confirmAction: alert.confirmHandler
            )
        case .notiOptionAlert(let alert):
            let confirmVC = NotificationOptionViewController()
            confirmVC.setTitles(
                titleText: alert.title,
                subTitleText: alert.checkBoxTitle ?? alert.subtitle,
                showSubtitleCheckButton: alert.checkBoxTitle != nil,
                subTitleMailText: nil,
                checkBoxTitleList: alert.checkBoxTitleList,
                checkBoxType: alert.checkBoxType
            )
            let actionButtons = alert.actions.map { item in
                ActionButton(title: item.title, titleColor: item.titleColor) { (isChecked, disappear) in
                    disappear {
                        item.handler(isChecked)
                    }
                }
            }
            actionButtons.forEach {
                confirmVC.addAction(actionButton: $0)
            }

            confirmVC.checkBoxListValsCallBack = {[weak self] (checkedVals, type) in
                self?.viewModel.notiCheckBoxTuple = (checkedVals, type)
            }

            confirmVC.trackInvitedGroupCheckStatus = {[weak self] isSelected in
                self?.viewModel.trackInvitedGroupCheckStatus(isSelected: isSelected)
            }

            confirmVC.trackMinutesCheckStatus = {[weak self] isSelected in
                self?.viewModel.trackMinutesCheckStatus(isSelected: isSelected)
            }

            confirmVC.show(controller: self.navigationController ?? self)
        case .alertWithShareCheck(let alert):
            LarkAlertController.showAlertWithCheckBox(
                from: self,
                title: alert.title,
                allConfirmTypes: alert.allConfirmTypes,
                event: event,
                disposeBag: disposeBag,
                subTitle: alert.subTitle,
                content: alert.content,
                checkBoxTitle: alert.checkBoxTitle,
                defaultSelectType: alert.defaultSelectType,
                cancelAction: alert.cancelHandler,
                confirmAction: alert.confirmHandler
            )
        case .present(let vc):
            self.present(vc, animated: true)
        case .showLoadingToast(let text):
            RoundedHUD.showLoading(with: text, on: view, disableUserInteraction: true)
        case .dismissLoadingToast:
            RoundedHUD.removeHUD(on: view)
        case .syncEventChanged(let event, let span):
            delegate?.didFinishSaveEvent(event, span: span, from: self)
        case .showErrorTip(let tip):
            handleErrorToast(tip)
        }
    }

    func handleAlert(_ alert: EventEdit.Alert) {
        let alertVC = LarkAlertController()
        if let title = alert.title {
            alertVC.setTitle(text: title, alignment: alert.checkBoxType == .all ? .left : alert.titleAlignment)
        }

        let view = EventEditNotiCheckBoxListView(checkBoxTitleList: alert.checkBoxTitleList, checkBoxType: alert.checkBoxType)

        if !alert.checkBoxTitleList.isEmpty {
            view.trackInvitedGroupCheckStatus = {[weak self] isSelected in
                self?.viewModel.trackInvitedGroupCheckStatus(isSelected: isSelected)
            }

            view.trackMinutesCheckStatus = {[weak self] isSelected in
                self?.viewModel.trackMinutesCheckStatus(isSelected: isSelected)
            }

            alertVC.setContent(view: view)
        } else
        if let message = alert.content {
            alertVC.setContent(text: message, alignment: alert.contentAlignment)
        }

        alert.actions.forEach { item in
            alertVC.addButton(text: item.title, color: item.titleColor, dismissCompletion: {
                if !alert.checkBoxTitleList.isEmpty, item.actionType == .confirm {
                    self.viewModel.notiCheckBoxTuple = view.getCheckBoxListVals()
                }
                item.handler()
            })
        }
        present(alertVC, animated: true)
    }

    func handleAttendeeLimitReason(limitReason: AttendeesLimitReason, controller: UIViewController) {
        var alert: UIViewController?
        switch limitReason {
        case .notTenantCertificated(let limit):
            /// 未认证企业提示弹窗
            alert = EventAlert.showAlert(title: I18n.Calendar_G_UnableAddGuests,
                                         message: I18n.Calendar_G_ToAddNeedVerify_Note(number: limit),
                                         confirmText: I18n.Calendar_Common_GotIt,
                                         cancelText: nil)
        case .reachFinalLimit(let limit):
            alert = EventAlert.showAlert(title: I18n.Calendar_G_UnableAddGuests,
                                        message: I18n.Calendar_G_MaxRemoveThenTry_Note(number: limit),
                                        confirmText: I18n.Calendar_Common_GotIt,
                                        cancelText: nil)
        case .reachRecurEventLimit(let limit):
            alert = EventAlert.showAlert(title: I18n.Calendar_G_GuestLimitReached(number: limit),
                                         message: I18n.Calendar_G_GuestRecurNoExceedLimit(number: limit),
                                         confirmText: I18n.Calendar_Common_GotIt,
                                         cancelText: nil)
            let isFromCreating = viewModel.input.isFromCreating
            let event = viewModel.eventModel?.rxModel?.value.getPBModel()
            CalendarTracerV2.RepeatedEventReachLimit.traceView {
                $0.mergeEventCommonParams(commonParam: .init(event: event))
                $0.is_new_create = isFromCreating.description
                $0.limit_number = limit
            }
        case .reachControlLimit(let limit):
            switch self.viewModel.input {
            case .createWebinar, .createWithContext, .copyWithEvent:
                // 新建场景触发管控上限
                CalendarTracerV2.EventAttendeeReachLimit.traceView {
                    $0.content = "create_event_add"
                    $0.role = "organizer"
                    $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
                }
                alert = EventAlert.showAlert(title: I18n.Calendar_G_GuestLimitReached(number: limit),
                                             message: I18n.Calendar_G_StepToAddMoreGuest,
                                             confirmText: I18n.Calendar_Common_GotIt,
                                             cancelText: nil,
                                             confirmHandler: {
                    CalendarTracerV2.EventAttendeeReachLimit.traceClick {
                        $0.click("know").target("none")
                        $0.content = "create_event_add"
                        $0.role = "organizer"
                        $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
                    }
                })
            case .editFrom, .editWebinar:
                // 编辑场景区分日程创建者角色
                let isCreator = self.viewModel.calendarManager?.primaryCalendar.serverId == (self.viewModel.eventModel?.rxModel?.value.creatorCalendarId ?? "")
                if isCreator {
                    // 创建者可以发起审批
                    CalendarTracerV2.EventAttendeeReachLimit.traceView {
                        $0.content = "edit_event_add"
                        $0.role = "organizer"
                        $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
                    }
                    let requestPermissionAction = { [weak self] in
                        guard let self = self else { return }
                        CalendarTracerV2.EventAttendeeReachLimit.traceClick {
                            $0.click("apply_access").target("none")
                            $0.content = "edit_event_add"
                            $0.role = "organizer"
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
                        }
                        guard !self.hasApprovedAttendeeCount else {
                            UDToast.showWarning(with: I18n.Calendar_G_SubmitNumberApply, on: controller.view)
                            return
                        }
                        guard let event = self.viewModel.eventModel?.rxModel?.value.getPBModel() else {
                            assertionFailure("cannot to approve page, because event is nil")
                            return
                        }
                        let approveVM = EventAttendeeLimitApproveViewModel(userResolver: self.userResolver,
                                                                           calendarId: event.calendarID,
                                                                           key: event.key,
                                                                           originalTime: event.originalTime)
                        approveVM.approveCommitSucceedHandler = {
                            self.hasApprovedAttendeeCount = true
                            UDToast.showSuccess(with: I18n.Calendar_G_IncreaseNumberRequestSubmitted, on: controller.view)
                        }
                        let approveVC = EventAttendeeLimitApproveViewController(viewModel: approveVM)
                        let naviController = LkNavigationController(rootViewController: approveVC)
                        controller.present(naviController, animated: true, completion: nil)
                    }
                    alert = EventAlert.showAlert(title: I18n.Calendar_G_UnableAddGuests,
                                                 message: I18n.Calendar_G_MaxGuestRequestRetry(number: limit),
                                                 confirmText: I18n.Calendar_G_RequestPermission_Button,
                                                 cancelText: I18n.Calendar_Detail_BackToEdit,
                                                 confirmHandler: requestPermissionAction,
                                                 cancelHandler: {
                        CalendarTracerV2.EventAttendeeReachLimit.traceClick {
                            $0.click("continue_edit").target("none")
                            $0.content = "edit_event_add"
                            $0.role = "organizer"
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
                        }
                    })
                } else {
                    CalendarTracerV2.EventAttendeeReachLimit.traceView {
                        $0.content = "edit_event_add"
                        $0.role = "guest"
                        $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
                    }
                    alert = EventAlert.showAlert(title: I18n.Calendar_G_UnableAddGuests,
                                                 message: I18n.Calendar_G_CantJoinEvent_Explain(number: limit),
                                                 confirmText: I18n.Calendar_Common_GotIt,
                                                 cancelText: nil,
                                                 confirmHandler: {
                        CalendarTracerV2.EventAttendeeReachLimit.traceClick {
                            $0.click("know").target("none")
                            $0.content = "edit_event_add"
                            $0.role = "guest"
                            $0.mergeEventCommonParams(commonParam: CommonParamData(event: self.event))
                        }
                    })
                }
            default:
                break
            }
        }
        if let alert = alert {
            controller.present(alert, animated: true)
        } else {
            assertionFailure("approve alert build failed")
        }
    }

    func handleErrorToast(_ errMsg: String) {
        RoundedHUD.showFailure(with: errMsg, on: view)
    }

    func handleWarningToast(_ msg: String) {
        UDToast.showWarning(with: msg, on: view)
    }

    func handleTipsToast(_ msg: String) {
        UDToast.showTips(with: msg, on: view)
    }

}
