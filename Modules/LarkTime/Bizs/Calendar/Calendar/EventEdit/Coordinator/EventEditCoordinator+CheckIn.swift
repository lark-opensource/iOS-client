//
//  EventEditCoordinator+CheckIn.swift
//  Calendar
//
//  Created by ByteDance on 2022/9/8.
//

import Foundation
import LarkTimeFormatUtils
import CalendarFoundation
import UniverseDesignColor
import UniverseDesignActionPanel

/// 编辑日程签到

extension EventEditCoordinator: EventCheckInSettingViewControllerDelegate {

    func selectCheckIn(from fromVC: EventEditViewController) {
        guard let eventModel = fromVC.viewModel.eventModel?.rxModel?.value else { return }

        let checkInConfig = eventModel.checkInConfig
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("check_in_setting").target("cal_check_in_setting_view")
                .mergeEventCommonParams(commonParam: CommonParamData(event: eventModel.getPBModel(), startTime: Int64(eventModel.startDate.timeIntervalSince1970) ))
        }

        let vm = EventCheckInSettingViewModel(checkInConfig: checkInConfig,
                                              eventModel: eventModel) { [weak self] startDate, endDate in
            guard let self = self else { return "" }
            let options = Options(timeZone: TimeZone.current,
                                  is12HourStyle: self.calendarDependency?.is12HourStyle.value ?? true,
                                  shouldShowGMT: true,
                                  timeFormatType: .long,
                                  timePrecisionType: .minute,
                                  datePrecisionType: .day,
                                  dateStatusType: .absolute,
                                  shouldRemoveTrailingZeros: false)
            return CalendarTimeFormatter.formatFullDateTimeRange(startFrom: startDate, endAt: endDate, isAllDayEvent: eventModel.isAllDay, shouldTextInOneLine: true, shouldShowTailingGMT: false, with: options)
        }
        let toVC = EventCheckInSettingViewController(viewModel: vm)
        toVC.delegate = self
        enter(from: fromVC, to: toVC, present: true)
    }

    func didFinishEdit(from viewController: EventCheckInSettingViewController) {
        guard let viewModel = eventViewController?.viewModel else { return }
        let currentConfig = viewController.viewModel.checkInConfig
        // 判断是签到开启状态
        if currentConfig.checkInEnable {
            eventViewController?.viewModel.updateCheckIn(currentConfig)
            exit(from: viewController, fromPresent: true)
            return
        }
        // 取消签到操作
        if let originalConfig = viewModel.originalEvent?.checkInConfig,
           originalConfig.checkInEnable {
            // 原日程开启签到配置时，关闭签到需要弹窗提示
            let config = UDActionSheetUIConfig(style: .autoAlert, isShowTitle: true)
            let actionSheet = UDActionSheet(config: config)
            actionSheet.setTitle(I18n.Calendar_Event_OnceSaveNoCheckIn)
            actionSheet.setCancelItem(text: I18n.Calendar_Common_Cancel) {
                CalendarTracerV2.CancelCheckInEvent.traceClick {
                    $0.click("cancel")
                    $0.mergeEventCommonParams(commonParam: CommonParamData(event: viewModel.originalEvent?.getPBModel(),
                                                                          startTime: Int64(viewModel.originalEvent?.startDate.timeIntervalSince1970 ?? 0)))
                }
            }
            actionSheet.addItem(UDActionSheetItem(title: I18n.Calendar_Edit_Confirm, titleColor: UDColor.primaryPri500, action: { [weak self] in
                CalendarTracerV2.CancelCheckInEvent.traceClick {
                    $0.click("confirm")
                    $0.mergeEventCommonParams(commonParam:  CommonParamData(event: viewModel.originalEvent?.getPBModel(),
                                                                          startTime: Int64(viewModel.originalEvent?.startDate.timeIntervalSince1970 ?? 0)))
                }
                viewModel.closeCheckIn()
                self?.exit(from: viewController, fromPresent: true)
            }))

            CalendarTracerV2.CancelCheckInEvent.traceView {
                $0.mergeEventCommonParams(commonParam: CommonParamData(event: viewModel.originalEvent?.getPBModel(),
                                                                      startTime: Int64(viewModel.originalEvent?.startDate.timeIntervalSince1970 ?? 0)))
            }
            viewController.present(actionSheet, animated: true)
        } else {
            viewModel.closeCheckIn()
            exit(from: viewController, fromPresent: true)
        }
    }

    func didCancelEdit(from viewController: EventCheckInSettingViewController) {
        exit(from: viewController, fromPresent: true)
    }

}
