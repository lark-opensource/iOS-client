//
//  EventEditCoordinator+Rrule.swift
//  Calendar
//
//  Created by 张威 on 2020/4/13.
//

import UIKit
import Foundation
import LarkUIKit
import CTFoundation
import EventKit
import UniverseDesignToast
import CalendarFoundation

/// 编辑日程重复性规则

extension EventEditCoordinator: EventEditRruleDelegate,
    EventBuiltinRruleViewControllerDelegate,
    EventCustomRruleViewControllerDelegate,
    EventRruleEndDateViewControllerDelegate {

    // MARK: EventEditRruleDelegate

    func selectRrule(from fromVC: EventEditViewController) {
        guard let event = fromVC.viewModel.eventModel?.rxModel?.value else { return }
        var showNoRrule = (fromVC.viewModel.originalEvent?.rrule == nil)
        let toVC = EventBuiltinRruleViewController(rrule: event.rrule, showNoRepeat: showNoRrule)
        toVC.eventTimezoneId = fromVC.viewModel.rxPickDateViewData.value.timeZone.identifier
        toVC.delegate = self
        enter(from: fromVC, to: toVC, present: false)
        toVC.delegate = self
    }

    func selectRruleEndDate(from fromVC: EventEditViewController) {
        guard let rrule = fromVC.viewModel.eventModel?.rxModel?.value.rrule,
              let startDate = fromVC.viewModel.eventModel?.rxModel?.value.startDate else {
            assertionFailure()
            return
        }
        
        let toVC = EventRruleEndDateViewController(
            rrule: rrule,
            startDate: startDate,
            meetingRoomMaxEndDateInfo: fromVC.viewModel.meetingRoomMaxEndDateInfo(),
            meetingRoomAmount: fromVC.viewModel.selectedMeetingRooms.count,
            eventTimezoneId: fromVC.viewModel.rxPickDateViewData.value.timeZone.identifier
        )
        toVC.eventParam = CommonParamData(
            event: fromVC.viewModel.originalEvent?.getPBModel()
        )
        enter(from: fromVC, to: toVC, present: true)
        toVC.delegate = self
    }

    // MARK: EventBuiltinRruleViewControllerDelegate

    public func didCancelEdit(from viewController: EventBuiltinRruleViewController) {
        exit(from: viewController, fromPresent: true)
    }

    public func didFinishEdit(from viewController: EventBuiltinRruleViewController) {
        let event = eventViewController?.viewModel.originalEvent
        let rule = viewController.selectedRrule
        eventViewController?.viewModel.updateRrule(rule)
        CalendarTracerV2.EventFullCreate.traceClick {
            $0.click("edit_rrule")
                .mergeEventCommonParams(commonParam: CommonParamData(event: eventViewController?.viewModel.eventModel?.rxModel?.value.getPBModel(), startTime: Int64(event?.startDate.timeIntervalSince1970 ?? 0)))
            $0.rrule_type = rule?.getFrequencyDesciption()
        }
        exit(from: viewController, fromPresent: false)
    }

    public func selectCustomRrule(from viewController: EventBuiltinRruleViewController) {
        guard let viewModel = eventViewController?.viewModel,
              let eventModel = viewModel.eventModel?.rxModel?.value else {
            assertionFailure()
            return
        }

        let firstWeekday: RRule.FirstWeekday
        switch dependency.setting.firstWeekday {
        case .saturday: firstWeekday = .saturday
        case .sunday: firstWeekday = .sunday
        case .monday: firstWeekday = .monday
        default:
            assertionFailure("firstWeekday should be one of [.saturday, .sunday, .monday]")
            firstWeekday = .monday
        }

        var config = EventCustomRruleViewController.Config()
        config.isWeekDayUnselectStartDateEnable = false
        config.weekDayUnselectStartDateDisableCallback = { (selectItem: String, from: UIViewController) in
            let tip = BundleI18n.Calendar.Calendar_RRule_Unselect(Type: selectItem)
            UDToast.showTips(with: tip, on: from.view)
        }

        config.isMonthWeekScrollEnable = false
        config.monthWeekScrollDisableCallback = { (selectItem: String, from: UIViewController) in
            let tip = BundleI18n.Calendar.Calendar_RRule_NoSlide(WeekType: selectItem)
            UDToast.showTips(with: tip, on: from.view)
        }

        config.isMonthDayUnselectStartDateEnable = false
        config.monthDayUnselectStartDateDisableCallback = { (selectItem: String, from: UIViewController) in
            let tip = BundleI18n.Calendar.Calendar_RRule_Unselect(Type: selectItem)
            UDToast.showTips(with: tip, on: from.view)
        }

        config.isMonthDayMultiSelectEnable = false
        config.eventTimeZoneId = viewModel.rxPickDateViewData.value.timeZone.identifier
        config.monthDayMultiSelectDisableCallback = { (selectItem: String, from: UIViewController) in
            let tip = BundleI18n.Calendar.Calendar_RRule_NoSlide(WeekType: selectItem)
            UDToast.showTips(with: tip, on: from.view)
        }

        let toVC = EventCustomRruleViewController(
            startDate: eventModel.startDate,
            rrule: eventModel.rrule,
            firstWeekday: firstWeekday,
            config: config
        )
        toVC.delegate = self
        viewController.navigationController?.pushViewController(toVC, animated: true)
    }

    public func parseRruleToTitle(rrule: EKRecurrenceRule) -> String? {
        parseRruleToTitle(rrule: rrule, timezone: "")
    }

    public func parseRruleToTitle(rrule: EKRecurrenceRule, timezone: String) -> String? {
        return rrule.getReadableRecurrenceRepeatString(timezone: timezone)
    }

    // MARK: EventCustomRruleViewControllerDelegate

    public func didCancelEdit(from viewController: EventCustomRruleViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }

    public func didFinishEdit(from viewController: EventCustomRruleViewController) {
        let firstDayOfTheWeek: Int = SettingService.shared().getSetting().firstWeekday.convertEKRruleFirstDayOfTheWeek()
        // 系统库 EKRecurrenceRule 的 firstDayOfTheWeek 无法设置，导致其 description 的 WKST 总是 SU
        viewController.selectedRrule?.setFirstWeekDay(firstDayOfTheWeek)
        eventViewController?.viewModel.updateRrule(viewController.selectedRrule)
        // pop前更新数据
        if let builtinRruleViewController = navigationController?.viewControllers.first(where: { $0 is EventBuiltinRruleViewController }) as? EventBuiltinRruleViewController {
            builtinRruleViewController.updateRRuleAndReload(viewController.selectedRrule)
        }
        if let vc = eventViewController {
            viewController.navigationController?.popToViewController(vc, animated: true)

        }
    }
    
    public func parseRruleToHeaderTitle(rrule: EKRecurrenceRule) -> String? {
        parseRruleToHeaderTitle(rrule: rrule, timezone: "")
    }

    public func parseRruleToHeaderTitle(rrule: EKRecurrenceRule, timezone: String) -> String? {
        return rrule.getReadableString(timezone: timezone)
    }

    // MARK: EventRruleEndDateViewControllerDelegate

    func didCancelEdit(from viewController: EventRruleEndDateViewController) {
        exit(from: viewController, fromPresent: true)
    }

    func didFinishEdit(from viewController: EventRruleEndDateViewController, needRenewalReminder: Bool) {
        eventViewController?.viewModel.updateRrule(viewController.rrule)
        // needRenewalReminder只能从false => true
        if eventViewController?.viewModel.needRenewalReminder == false {
            eventViewController?.viewModel.needRenewalReminder = needRenewalReminder
        }
        exit(from: viewController, fromPresent: true)
    }
}
