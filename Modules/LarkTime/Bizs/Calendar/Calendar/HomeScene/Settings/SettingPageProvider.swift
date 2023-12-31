//
//  SettingPageProvider.swift
//  Calendar
//
//  Created by zc on 2018/5/17.
//  Copyright © 2018年 EE. All rights reserved.
//
import UIKit
import RxSwift
import RxCocoa
import Foundation
import RoundedHUD
import LarkTimeFormatUtils

protocol SettingPageProviderDelegate: AnyObject {
    func settingPageProvider(_ provider: SettingPageProvider, didSelectDefaultReminderWith model: Setting)

    func settingPageProvider(_ provider: SettingPageProvider, didSelectAlldayReminderWith model: Setting)

    func settingPageProvider(_ provider: SettingPageProvider, didSelectEventDurationWith model: Setting)

    func settingPageProvider(_ provider: SettingPageProvider, didSelectGuestPermission model: Setting)

    func didSelectedFirstWeekday(_ provider: SettingPageProvider)

    func didSelectedAlternateCalendarday(_ provider: SettingPageProvider)

    func didSelectLocalCal(_ provider: SettingPageProvider)

    func didSelectSkinSetting(_ provider: SettingPageProvider)

    func didSelectAccountManage(_ provider: SettingPageProvider)

    func didSelectMeetingAccountManage(_ provider: SettingPageProvider)

    func didSelectedWorkingHours(_ provider: SettingPageProvider)

    func settingPageProvider(_ provider: SettingPageProvider, didSelectAdditionalTimeZone model: Setting)
}

// 日历设置页provider
public final class SettingPageProvider {
    let view: SettingListView
    private let disposeBag = DisposeBag()
    private let timeZoneService: TimeZoneService?
    private let userID: String

    weak var delegate: SettingPageProviderDelegate?

    private var setting: Setting {
        return self.settingProvider.getSetting()
    }

    var skinType: CalendarSkinType {
        return self.settingProvider.getSetting().skinTypeIos
    }

    var firstWeekday: DaysOfWeek {
        return self.settingProvider.getSetting().firstWeekday
    }

    var alternateCalendar: AlternateCalendarEnum {
        if let value = self.settingProvider.getSetting().alternateCalendar {
            return value
        }
        return self.settingProvider.getSetting().defaultAlternateCalendar
    }

    var workHourSettting: SettingModel.WorkHourSetting {
        return self.settingProvider.getSetting().workHourSetting
    }

    private let settingProvider: SettingProvider

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private let is12HourStyle: BehaviorRelay<Bool>
    init(settingProvider: SettingProvider,
         is12HourStyle: BehaviorRelay<Bool>,
         timeZoneService: TimeZoneService?,
         userID: String,
         fromWhere: CalendarSettingBody.FromWhere) {
        self.settingProvider = settingProvider
        self.is12HourStyle = is12HourStyle
        self.timeZoneService = timeZoneService
        self.userID = userID
        self.view = SettingListView(userID: userID, fromWhere: fromWhere)
        self.view.delegate = self
        self.updateCurrent()
        NotificationCenter.default.addObserver(self, selector: #selector(timeChange),
                                               name: UIApplication.significantTimeChangeNotification,
                                               object: nil)
        self.is12HourStyle.asDriver().skip(1)
            .drive(onNext: { [weak self] (_) in
                self?.updateCurrent()
        }).disposed(by: disposeBag)
        self.forceUpdateSettingView()
        self.updateFeedTempTopSetting()
    }

    @objc
    private func timeChange() {
        self.view.updateTimezone()
    }

    private func updateCurrent() {
        self.updateView(self.view, with: self.setting)
    }

    private func updateView(_ view: SettingListView,
                            with model: Setting) {
        view.reminderCell.update(tailingTitle: model.noneAllDayReminder?.reminderString(is12HourStyle: self.is12HourStyle.value) ?? BundleI18n.Calendar.Calendar_Common_NoAlerts)
        view.allDayReminderCell.update(tailingTitle: model.allDayReminder?.reminderString(is12HourStyle: self.is12HourStyle.value) ?? BundleI18n.Calendar.Calendar_Common_NoAlerts)
        let durationText = BundleI18n.Calendar.Calendar_Plural_CommonMins(number: Int(model.defaultEventDuration))
        view.eventDurationPickerCell.update(tailingTitle: durationText)
        view.firstWeekdayPickerCell.update(tailingTitle: TimeFormatUtils.weekdayFullString(weekday: model.firstWeekday.rawValue))
        let alternateCalendar = model.alternateCalendar ?? model.defaultAlternateCalendar
        view.alternateCalendarPickerCell.update(tailingTitle: alternateCalendar.toString())
        view.coverPassEventCell.update(switchIsOn: model.showCoverPassEvent)
        view.rejectEventCell.update(switchIsOn: model.showRejectSchedule)
        view.notifyWhenGuestsDeclineCell.update(switchIsOn: model.notifyWhenGuestsDecline)
        view.remindNoDeclineCell.update(switchIsOn: model.remindNoDecline)
        view.skinSettingCell.update(tailingTitle: model.skinTypeIos.rawValue)
        let enableString = model.workHourSetting.enableWorkHour ? BundleI18n.Calendar.Calendar_Workinghours_Enabled : BundleI18n.Calendar.Calendar_Workinghours_Notenabled
        view.workingHoursCell.update(tailingTitle: enableString)
        view.reminderTitleLabel.text = BundleI18n.Calendar.Calendar_NewSettings_EventReminderTimeMobile
        view.switchFeedTopEventCell.update(switchIsOn: model.feedTopEvent)
    }

    func setAlldayReminder(_ reminder: Reminder?) {
        var setting = self.setting
        setting.defaultAllDayReminder = reminder?.minutes ?? -1
        self.updateSaveSetting(setting)
    }

    func setReminder(_ reminder: Reminder?) {
        var setting = self.setting
        setting.defaultNoneAllDayReminder = reminder?.minutes ?? -1
        self.updateSaveSetting(setting)
    }

    func setEventDuration(_ duration: Int) {
        var setting = self.setting
        setting.defaultEventDuration = Int32(duration)
        self.updateSaveSetting(setting)
    }

    func setGuestPermission(_ permission: GuestPermission) {
        var setting = self.setting
        setting.guestPermission = permission
        self.updateSaveSetting(setting)
    }

    func setWorkHourSetting(_ workHourSetting: SettingModel.WorkHourSetting,
                            onError: @escaping ((SettingModel.WorkHourSetting) -> Void)) {
        var setting = self.setting
        setting.workHourSetting = workHourSetting
        self.updateSaveSetting(setting) { oldSetting in
            onError(oldSetting.workHourSetting)
        }
    }

    func setSkinType(skinType: CalendarSkinType) {
        var setting = self.setting
        setting.skinTypeIos = skinType
        self.updateSaveSetting(setting, shouldPublishUpdateView: true, shouldPublishUpdateCalendarLoader: true)
    }

    func setFirstWeekday(firstWeekday: DaysOfWeek) {
        CalendarTracer.shareInstance.calSettingFirstWeekday(targetValue: .init(daysOfWeek: firstWeekday))
        var setting = self.setting
        setting.firstWeekday = firstWeekday
        self.updateSaveSetting(setting, shouldPublishUpdateView: true)
    }

    func setAlternateCalendary(alternateCalendary: AlternateCalendarEnum) {
        CalendarTracer.shareInstance.calSettingsSecondaryCalendar(calendarType: .init(alternateCalendar: alternateCalendary))
        var setting = self.setting
        setting.alternateCalendar = alternateCalendary
        self.updateSaveSetting(setting, shouldPublishUpdateView: true)
    }

    func setAdditionalTimeZoneList(additionalTimeZones: [String], onError: ((Setting) -> Void)? = nil) {
        var setting = self.setting
        setting.additionalTimeZones = additionalTimeZones
        self.updateSaveSetting(setting, shouldPublishUpdateView: true, editOtherTimezones: true, onError: onError)
    }

    func updateSaveSetting(_ setting: Setting,
                           shouldPublishUpdateView: Bool = false,
                           shouldPublishUpdateCalendarLoader: Bool = false,
                           editOtherTimezones: Bool = false,
                           onError: ((Setting) -> Void)? = nil) {
        self.updateView(self.view, with: setting)
        self.settingProvider.updateSaveSetting(setting,
                                               shouldPublishUpdateView: shouldPublishUpdateView,
                                               shouldPublishUpdateCalendarLoader: shouldPublishUpdateCalendarLoader,
                                               editOtherTimezones: editOtherTimezones)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { _ in
            }, onError: { [weak self] error in
                guard let `self` = self else { return }
                self.updateCurrent()
                onError?(self.setting)
                RoundedHUD.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Edit_SaveFailedTip, on: self.view)
            }).disposed(by: disposeBag)
    }

    /// force update the setting into the newest server setting,  MAY TAKE A WHILE
    func forceUpdateSettingView() {
        self.settingProvider.getServerSetting()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (setting) in
                guard let `self` = self else { return }
                self.updateView(self.view, with: setting)
                if FeatureGating.additionalTimeZoneOption(userID: self.userID),
                let timeZoneService = timeZoneService {
                    SettingService.additionalTimeZoneUpgrade(setting: setting,
                                                             timeZoneService: timeZoneService,
                                                             settingProvider: settingProvider,
                                                             disposeBag: disposeBag)
                }
            }).disposed(by: disposeBag)
    }

    // feed置顶设置push更新
    func updateFeedTempTopSetting() {
        SettingService.shared().feedTempTopObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isTop in
                guard let self = self else { return }
                TodayEvent.logInfo("updateFeedTopSetting isTop: \(isTop)")
                self.updateSettingListView(self.view, feedTopEvent: isTop)
            }).disposed(by: disposeBag)
    }
}

extension SettingPageProvider: SettingListViewDelegate {

    func settingListViewDidSelectWorkingHoursCell(_ listView: SettingListView) {
        self.delegate?.didSelectedWorkingHours(self)
    }

    func settingListViewDidSelectAccountManage(_ listView: SettingListView) {
        self.delegate?.didSelectAccountManage(self)
    }

    func settingListViewDidSelectMeetingAccountManage(_ listView: SettingListView) {
        self.delegate?.didSelectMeetingAccountManage(self)
    }

    func settingListViewDidSelectFirstWeekdayPicker(_ listView: SettingListView) {
        self.delegate?.didSelectedFirstWeekday(self)
    }

    func settingListViewDidSelectAlternateCalendarPicker(_ listView: SettingListView) {
        self.delegate?.didSelectedAlternateCalendarday(self)
    }

    func settingListViewDidSelectSkinSetting(_ listView: SettingListView) {
        self.delegate?.didSelectSkinSetting(self)
    }

    func settingListViewDidSelectReminder(_ listView: SettingListView) {
        self.delegate?.settingPageProvider(self, didSelectDefaultReminderWith: self.setting)
    }

    func settingListViewDidSelectAllDayReminder(_ listView: SettingListView) {
        self.delegate?.settingPageProvider(self, didSelectAlldayReminderWith: self.setting)
    }

    func settingListViewDidSelectEventDuration(_ listView: SettingListView) {
        self.delegate?.settingPageProvider(self, didSelectEventDurationWith: self.setting)
    }

    func settingListViewDidSelectGuestPermission(_ listView: SettingListView) {
        self.delegate?.settingPageProvider(self, didSelectGuestPermission: self.setting)
    }

    func settingListView(_ listView: SettingListView, showRejectedEventWith isShow: Bool) {
        var setting = self.setting
        setting.showRejectSchedule = isShow
        self.updateSaveSetting(setting)
        CalendarTracerV2.SettingCalendar.traceClick {
            $0.click("show_rejected_event").target("none")
        }
    }

    func settingListView(_ listView: SettingListView, showCoverPassEventWith isShow: Bool) {
        var setting = self.setting
        setting.showCoverPassEvent = isShow
        self.updateSaveSetting(setting, shouldPublishUpdateView: true)
        CalendarTracerV2.SettingCalendar.traceClick {
            $0.click("lower_ended_event_brightness").target("none")
        }
    }

    func settingListView(_ listView: SettingListView, remindNoDecline isShow: Bool) {
        var setting = self.setting
        setting.remindNoDecline = isShow
        self.updateSaveSetting(setting)
        CalendarTracerV2.SettingCalendar.traceClick {
            $0.click("only_notify_accepted_event").target("none")
        }
    }

    func settingListView(_ listView: SettingListView, notifyWhenGuestsDecline isShow: Bool) {
        var setting = self.setting
        setting.notifyWhenGuestsDecline = isShow
        self.updateSaveSetting(setting)
        CalendarTracerV2.SettingCalendar.traceClick {
            $0.click("remind_me_of_event_rejection").target("none")
        }
    }

    func settingListView(_ listView: SettingListView, feedTopEvent isShow: Bool) {
        var setting = self.setting
        setting.feedTopEvent = isShow
        SettingService.shared().updateSaveFeedToTopSetting(setting)
    }

    func updateSettingListView(_ listView: SettingListView, feedTopEvent isShow: Bool) {
        var setting = self.setting
        setting.feedTopEvent = isShow
        listView.switchFeedTopEventCell.update(switchIsOn: isShow)
    }

    func settingListViewAdditionalTimeZoneList(_ listView: SettingListView) {
        self.delegate?.settingPageProvider(self, didSelectAdditionalTimeZone: self.setting)
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value) })
}
