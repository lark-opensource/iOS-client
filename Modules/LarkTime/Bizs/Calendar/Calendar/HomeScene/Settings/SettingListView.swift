//
//  SettingListView.swift
//  Calendar
//
//  Created by zc on 2018/5/17.
//  Copyright © 2018年 EE. All rights reserved.
//
import CalendarFoundation
import UIKit
import LarkUIKit
import LarkFoundation
import UniverseDesignIcon
import UniverseDesignColor

protocol SettingListViewDelegate: AnyObject {
    func settingListViewDidSelectAccountManage(_ listView: SettingListView)
    func settingListViewDidSelectMeetingAccountManage(_ listView: SettingListView)
    func settingListViewDidSelectReminder(_ listView: SettingListView)
    func settingListViewDidSelectAllDayReminder(_ listView: SettingListView)
    func settingListViewDidSelectEventDuration(_ listView: SettingListView)
    func settingListViewDidSelectSkinSetting(_ listView: SettingListView)
    func settingListView(_ listView: SettingListView, showCoverPassEventWith isShow: Bool)
    func settingListView(_ listView: SettingListView, showRejectedEventWith isShow: Bool)
    func settingListView(_ listView: SettingListView, notifyWhenGuestsDecline isShow: Bool)
    func settingListView(_ listView: SettingListView, remindNoDecline isShow: Bool)
    func settingListView(_ listView: SettingListView, feedTopEvent isShow: Bool)
    func settingListViewDidSelectFirstWeekdayPicker(_ listView: SettingListView)
    func settingListViewDidSelectAlternateCalendarPicker(_ listView: SettingListView)
    func settingListViewDidSelectWorkingHoursCell(_ listView: SettingListView)
    func settingListViewDidSelectGuestPermission(_ listView: SettingListView)
    func updateSettingListView(_ listView: SettingListView, feedTopEvent isShow: Bool)
    func settingListViewAdditionalTimeZoneList(_ listView: SettingListView)
}

final class SettingListView: UIView {

    private let stackView = UIStackView()
    private let fromWhere: CalendarSettingBody.FromWhere
    private lazy var scrollView = UIScrollView()
    private let userID: String

    private(set) lazy var accountManageCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showAccountManage),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_CalendarThirdPartyAccount,
                               badgeID: .cal_import)
        return view
    }()

    private(set) lazy var meetingAccountManageCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showMeetingAccountManage),
                               target: self,
                               title: I18n.Calendar_Settings_ThirdPartyManage)
        view.isHidden = !FG.shouldEnableZoom
        return view
    }()

    private(set) lazy var guestPermissionCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showGuestPermissionManager),
                               target: self,
                               title: I18n.Calendar_G_EventGuestPermit_Subtitle)
        return view
    }()

    private(set) lazy var timezoneCell: SettingView = {
        let view = SettingView(title: BundleI18n.Calendar.Calendar_Setting_CurrentDeviceZone,
                               tailingTitle: "")
        return view
    }()

    private(set) lazy var reminderCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showReminderPicker),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_EventReminderNotAllDayMobile,
                               tailingTitle: "")
        return view
    }()

    private(set) lazy var allDayReminderCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showAllDayReminderPicker),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_EventReminderAllDayMobile,
                               tailingTitle: "")
        return view
    }()

    private(set) lazy var eventDurationPickerCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showEventDurationPicker),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_DefaultEventDuration,
                               tailingTitle: "")
        return view
    }()

    private(set) lazy var firstWeekdayPickerCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showFirstWeekdayPicker),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_FirstDayOfWeek,
                               tailingTitle: "")
        return view
    }()

    private(set) lazy var alternateCalendarPickerCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showAlternateCalendarPicker),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_UseAlternateCalendar,
                               tailingTitle: "")
        return view
    }()

    private(set) lazy var workingHoursCell: SettingView = {
        let view = SettingView(cellSelector: #selector(workingHoursSetting),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_WorkingHoursMobile,
                               tailingTitle: "")
        return view
    }()

    private(set) lazy var skinSettingCell: SettingView = {
        let view = SettingView(cellSelector: #selector(showSkinSetting),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_EventColor,
                               tailingTitle: "",
                               badgeID: .cal_dark_mode)
        return view
    }()

    private(set) lazy var coverPassEventCell: SettingView = {
        let view = SettingView(switchSelector: #selector(coverPassEventAction(sender:)),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_LowerBrightnessOfPastEvents)
        return view
    }()

    private(set) lazy var rejectEventCell: SettingView = {
        let view = SettingView(switchSelector: #selector(showRejectedEventAction(sender:)),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_ShowRejectedEvents)
        return view
    }()

    private(set) lazy var remindNoDeclineCell: SettingView = {
        let view = SettingView(switchSelector: #selector(remindNoDeclineAction(sender:)),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_NewSettings_DontNotifyDeclined_Desc)
        return view
    }()

    private(set) lazy var notifyWhenGuestsDeclineCell: SettingView = {
        let view = SettingView(switchSelector: #selector(notifyWhenGuestsDeclineAction(sender:)),
                               target: notifyWhenGuestsDeclineAction,
                               title: BundleI18n.Calendar.Calendar_NewSettings_NotifyWhenOthersRejectMyEvent)
        return view
    }()

    private(set) lazy var switchFeedTopEventCell: SettingView = {
        let view = SettingView(switchSelector: #selector(feedTopEventAction(sender:)),
                               target: self,
                               title: BundleI18n.Calendar.Lark_FeedEvent_ShowFeedTop_Toggle)
        return view
    }()

    private(set) lazy var additionalTimeZoneCell: SettingView = {
        let view = SettingView(cellSelector: #selector(additionalTimeZoneAction),
                               target: self,
                               title: BundleI18n.Calendar.Calendar_G_SecondaryTimeZone_Tab,
                               tailingTitle: "")
        return view
    }()

    weak var delegate: SettingListViewDelegate?

    init(userID: String, fromWhere: CalendarSettingBody.FromWhere) {
        self.userID = userID
        self.fromWhere = fromWhere
        super.init(frame: UIScreen.main.bounds)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        self.fromWhere = .none
        self.userID = ""
        super.init(coder: aDecoder)
        commonInit()
    }

    private lazy var accountManagerSettingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var reminderTimeSettingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var viewSettingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var reminderSettingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private lazy var feedTopEventSettingStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    private func commonInit() {
        backgroundColor = UIColor.ud.bgFloatBase
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        stackView.axis = .vertical
        scrollView.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.width.equalToSuperview().offset(-32)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        addSeparator(with: 16)
        let accountManagerStackBG = UIView()
        accountManagerStackBG.addSubview(accountManagerSettingStack)
        accountManagerStackBG.layer.cornerRadius = 10
        accountManagerStackBG.clipsToBounds = true
        accountManagerSettingStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.addArrangedSubview(accountManagerStackBG)
        accountManagerSettingStack.addArrangedSubview(accountManageCell)
        accountManagerSettingStack.addArrangedSubview(meetingAccountManageCell)
        meetingAccountManageCell.addTopBorder(inset: UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0), lineHeight: 0.5)

        addReminderTitle()
        let reminderTimeSettingStackBG = UIView()
        reminderTimeSettingStackBG.addSubview(reminderTimeSettingStack)
        reminderTimeSettingStackBG.layer.cornerRadius = 10
        reminderTimeSettingStackBG.clipsToBounds = true
        reminderTimeSettingStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.addArrangedSubview(reminderTimeSettingStackBG)
        reminderTimeSettingStack.addArrangedSubview(reminderCell)
        reminderCell.addCellBottomBorder()
        reminderTimeSettingStack.addArrangedSubview(allDayReminderCell)
        addSeparator(with: 16)

        let viewSettingStackBG = UIView()
        viewSettingStackBG.addSubview(viewSettingStack)
        viewSettingStackBG.layer.cornerRadius = 10
        viewSettingStackBG.clipsToBounds = true
        viewSettingStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.addArrangedSubview(viewSettingStackBG)
        viewSettingStack.addArrangedSubview(eventDurationPickerCell)
        eventDurationPickerCell.addCellBottomBorder()
        viewSettingStack.addArrangedSubview(firstWeekdayPickerCell)
        firstWeekdayPickerCell.addCellBottomBorder()
        viewSettingStack.addArrangedSubview(workingHoursCell)
        workingHoursCell.addCellBottomBorder()
        viewSettingStack.addArrangedSubview(skinSettingCell)
        skinSettingCell.addCellBottomBorder()
        viewSettingStack.addArrangedSubview(alternateCalendarPickerCell)
        alternateCalendarPickerCell.addCellBottomBorder()
        viewSettingStack.addArrangedSubview(coverPassEventCell)
        coverPassEventCell.addCellBottomBorder()
        viewSettingStack.addArrangedSubview(rejectEventCell)
        addSeparator(with: 12)

        let reminderSettingStackBG = UIView()
        reminderSettingStackBG.addSubview(reminderSettingStack)
        reminderSettingStackBG.layer.cornerRadius = 10
        reminderSettingStackBG.clipsToBounds = true
        reminderSettingStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.addArrangedSubview(reminderSettingStackBG)
        reminderSettingStack.addArrangedSubview(remindNoDeclineCell)
        remindNoDeclineCell.addCellBottomBorder()
        reminderSettingStack.addArrangedSubview(notifyWhenGuestsDeclineCell)
        if FeatureGating.feedTopEvent(userID: userID) {
            addSeparator(with: 16)
            let feedTopEventSettingStackBG = UIView()
            feedTopEventSettingStackBG.addSubview(feedTopEventSettingStack)
            feedTopEventSettingStackBG.layer.cornerRadius = 10
            feedTopEventSettingStackBG.clipsToBounds = true
            feedTopEventSettingStack.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            stackView.addArrangedSubview(feedTopEventSettingStackBG)
            stackView.bringSubviewToFront(feedTopEventSettingStackBG)
            if fromWhere == .todayEvent {
                let backView = UIView()
                backView.backgroundColor = UDColor.calendarSettingLightBgColor
                stackView.addSubview(backView)
                stackView.bringSubviewToFront(feedTopEventSettingStackBG)
                backView.snp.makeConstraints { make in
                    make.leading.equalTo(feedTopEventSettingStackBG).offset(-16)
                    make.trailing.equalTo(feedTopEventSettingStackBG).offset(16)
                    make.top.equalTo(feedTopEventSettingStackBG).offset(-8)
                    make.bottom.equalTo(feedTopEventSettingStackBG).offset(8)
                }
                UIView.animate(withDuration: 0.2, delay: 0, options: [.curveLinear]) {
                    backView.backgroundColor = UDColor.calendarSettingLightBgColor
                }
                UIView.animate(withDuration: 2, delay: 2, options: [.curveLinear]) {
                    backView.backgroundColor = .clear
                }
            }
            feedTopEventSettingStack.addArrangedSubview(switchFeedTopEventCell)
        }

        if FG.guestPermission {
            addSeparator(with: 16)
            stackView.addArrangedSubview(guestPermissionCell)
            guestPermissionCell.layer.cornerRadius = 10
            guestPermissionCell.clipsToBounds = true
        }

        addSeparator(with: 16)
        stackView.addArrangedSubview(timezoneCell)
        updateTimezone()
        if !Utils.isiOSAppOnMacSystem {
            addTimeZoneSettingView()
        }
        timezoneCell.layer.cornerRadius = 10

        if FeatureGating.additionalTimeZoneOption(userID: userID) {
            addSeparator(with: 16)
            stackView.addArrangedSubview(additionalTimeZoneCell)
            additionalTimeZoneCell.layer.cornerRadius = 10
            additionalTimeZoneCell.clipsToBounds = true
            addSeparator(with: 60)
        }
    }

    func updateTimezone() {
        timezoneCell.update(tailingTitle: TimeZone.current.abbreviation() ?? "")
    }

    @objc
    private func showAccountManage() {
        LarkBadgeManager.hidden(.cal_import)
        delegate?.settingListViewDidSelectAccountManage(self)
    }

    @objc
    private func showMeetingAccountManage() {
        delegate?.settingListViewDidSelectMeetingAccountManage(self)
    }

    @objc
    private func showGuestPermissionManager() {
        delegate?.settingListViewDidSelectGuestPermission(self)
    }

    @objc
    private func showReminderPicker() {
        delegate?.settingListViewDidSelectReminder(self)
    }

    @objc
    private func showAllDayReminderPicker() {
        delegate?.settingListViewDidSelectAllDayReminder(self)
    }

    @objc
    private func showEventDurationPicker() {
        delegate?.settingListViewDidSelectEventDuration(self)
    }

    @objc
    private func showFirstWeekdayPicker() {
        delegate?.settingListViewDidSelectFirstWeekdayPicker(self)
    }

    @objc
    private func showAlternateCalendarPicker() {
        delegate?.settingListViewDidSelectAlternateCalendarPicker(self)
    }

    @objc
    private func workingHoursSetting() {
        delegate?.settingListViewDidSelectWorkingHoursCell(self)
    }

    @objc
    private func showSkinSetting() {
        LarkBadgeManager.hidden(.cal_dark_mode)
        delegate?.settingListViewDidSelectSkinSetting(self)
    }

    @objc
    private func coverPassEventAction(sender: UISwitch) {
        delegate?.settingListView(self, showCoverPassEventWith: sender.isOn)
        CalendarTracer.shareInstance.calSettingReduceBrightness(actionTargetStatus: .init(isOn: sender.isOn))
    }

    @objc
    private func showRejectedEventAction(sender: UISwitch) {
        delegate?.settingListView(self, showRejectedEventWith: sender.isOn)
        CalendarTracer.shareInstance.calSettingShowRejected(actionTargetStatus: .init(isOn: sender.isOn))
    }

    @objc
    private func notifyWhenGuestsDeclineAction(sender: UISwitch) {
        delegate?.settingListView(self, notifyWhenGuestsDecline: sender.isOn)
        CalendarTracer.shareInstance.calSettingsDecliningEventNotification(actionTargetStatus: .init(isOn: sender.isOn))
    }

    @objc
    private func remindNoDeclineAction(sender: UISwitch) {
        delegate?.settingListView(self, remindNoDecline: sender.isOn)
        CalendarTracer.shareInstance.calSettingsNotifyAcceptedOnly(actionTargetStatus: .init(isOn: sender.isOn))
    }

    @objc
    private func feedTopEventAction(sender: UISwitch) {
        delegate?.settingListView(self, feedTopEvent: sender.isOn)
    }

    @objc
    private func additionalTimeZoneAction() {
        delegate?.settingListViewAdditionalTimeZoneList(self)
    }

    private func addSeparator(with height: CGFloat) {
        let seprator = UIView()
        seprator.snp.makeConstraints { (make) in
            make.height.equalTo(height)
        }
        stackView.addArrangedSubview(seprator)
    }

    var reminderTitleLabel = UILabel()
    private func addReminderTitle() {
        let wrapper = UIView()
        reminderTitleLabel = UILabel.cd.subTitleLabel()
        wrapper.addSubview(reminderTitleLabel)
        reminderTitleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(4)
            make.top.equalToSuperview().offset(14)
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-2)
            make.right.lessThanOrEqualToSuperview()
        }
        reminderTitleLabel.numberOfLines = 0
        stackView.addArrangedSubview(wrapper)
    }

    private func addTimeZoneSettingView() {
        let wrapper = UIView()
        let label = UILabel.cd.subTitleLabel(fontSize: 14)
        label.text = BundleI18n.Calendar.Calendar_NewSettingsMV_ChangeTimezoneDescription
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        wrapper.addSubview(label)

        label.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(8)
            $0.right.equalToSuperview().offset(-16)
            $0.bottom.equalToSuperview().offset(-8)
        }

        stackView.addArrangedSubview(wrapper)
    }

    func scrollToFeedToTopSetting() {
        let point = self.convert(feedTopEventSettingStack.frame, from: feedTopEventSettingStack.superview)
        let offsetY = min(point.center.y - self.frame.center.y, scrollView.contentSize.height - self.frame.height)
        if offsetY > 0 {
            self.scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
        }
    }
}
