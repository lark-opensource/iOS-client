//
//  MailScheduleSendController.swift
//  MailSDK
//
//  Created by majx on 2020/12/5.
//

import Foundation
import SnapKit
import LarkAlertController
import EENavigator

protocol MailScheduleSendDelegate: AnyObject {
    func didSetScheduleSendTime(_ timestamp: Int64)
}

class MailScheduleSendController: MailBaseViewController {
    weak var delegate: MailScheduleSendDelegate?

    private var timeZoneService: TimeZoneService? = {
        if let dataService = MailDataServiceFactory.commonDataService {
            return TimeZoneServiceImpl(api: dataService)
        } else {
            mailAssertionFailure("timeZoneService not avaliable")
            return nil
        }
    }()
    private var navBar: MailScheduleSendNavBar = MailScheduleSendNavBar(frame: .zero)
    /// 初始化时默认选中的日期，
    private let defaultScheduleDate: Date
    private var selectedDate: Date // 存储正确的时分秒，时区使用了默认时区，所以时间戳不一定对
    private var selectedTimezone: TimeZoneModel?
    private lazy var datePicker: MailMinutesDatePickerView = {
        let picker = MailMinutesDatePickerView(frame: datePickerFrame(), selectedDate: defaultScheduleDate)
        picker.delegate = self
        return picker
    }()

    private lazy var timezoneView: MailScheduleTimezoneView = {
        let view = MailScheduleTimezoneView(frame: .zero)
        view.delegate = self
        return view
    }()

    private func datePickerFrame() -> CGRect {
        return CGRect(x: 0.0, y: 0.0, width: view.frame.width, height: 256.0)
    }

    // 这个才是正确的时间戳
    private var scheduleLocalDate: Date {
        return calculateLocalDateWithTimeZone(selectedDate, destTimeZone: selectedTimezone)
    }
    
    private let accountContext: MailAccountContext
    
    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
        // 保证大于 1 小时，往后 1:04:59 再向下取整
        let defaultDate = Date(timeIntervalSinceNow: 3899)
        let defaultMinute = MailMinutesDatePickerView.getMultipleOfMinutesInterval(defaultDate.minute)
        self.defaultScheduleDate = defaultDate.changed(minute: defaultMinute) ?? defaultDate
        self.selectedDate = defaultScheduleDate
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var serviceProvider: MailSharedServicesProvider? {
        accountContext
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        MailLogger.info("mail send schedule setting did load")
        setupViews()
        loadTimezone()
    }

    func setupViews() {
        view.addSubview(navBar)
        let navBarHeight = Display.realNavBarHeight() + Display.realStatusBarHeight()
        navBar.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(0)
            make.height.equalTo(navBarHeight)
        }
        navBar.closeButton.addTarget(self, action: #selector(onClickClose), for: .touchUpInside)
        navBar.confirmButton.addTarget(self, action: #selector(onClickConfirm), for: .touchUpInside)

        view.addSubview(datePicker)
        datePicker.snp.makeConstraints({make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
            make.height.equalTo(256)
        })

        view.addSubview(timezoneView)
        timezoneView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(datePicker.snp.bottom)
            make.height.equalTo(48)
        }
    }

    func loadTimezone() {
        guard let service = timeZoneService else { return }
        let previousTimeZone = service.preferredTimeZone.value
        timezoneView.updateTimezone(name: previousTimeZone.name)
    }

    func updateSelectedTimezone(_ timezone: TimeZoneModel) {
        selectedTimezone = timezone
        timezoneView.updateTimezone(name: timezone.name)
        updateSelectedDate(selectedDate)
        datePicker.resetScrollViews()
    }

    func updateScheduleDateTitle() {
        navBar.updateScheduleDate(scheduleLocalDate)
        navBar.showSubTitle(show: true)
    }

    func calculateLocalDateWithTimeZone(_ sourceDate: Date) -> Date {
        return calculateLocalDateWithTimeZone(sourceDate, destTimeZone: selectedTimezone)
    }

    /// 将 Date 在当前时区下的时分秒 和 目标时区 组合起来
    /// 时分秒不变，时区改变，时间戳改变⚠️
    /// 用于使用「正确的时分秒」和「正确的时区」获得「正确的时间戳」
    /// eg: 北京时间 12:00:00(UTC+9000)（当前时区）-> 东京时间 12:00:00(UTC+9000)
    func calculateLocalDateWithTimeZone(_ sourceDate: Date, destTimeZone: TimeZoneModel?) -> Date {
        if let timeZone = destTimeZone {
            let newDate = TimeZoneUtil.dateTransForm(
                srcDate: sourceDate,
                srcTzId: TimeZone.current.identifier,
                destTzId: timeZone.identifier
            )
            return newDate
        }
        return sourceDate
    }

    /// 将 Date 的时间戳 与 目标时区 结合起来，变成当前时区相同的时分秒
    /// 时区改变，时间戳改变，使得时分秒不变⚠️
    /// 用于使用「正确的时间戳」和「正确的时区」获得「正确的时分秒」
    /// eg：东京时间 12:00:00 (UTC+9000)) -> 北京时间 12:00:00(UTC+8000)（当前时区）
    func calculateLocalDate(_ sourceDate: Date, sourceTimezone: TimeZoneModel?) -> Date {
        if let timeZone = sourceTimezone {
            let newDate = TimeZoneUtil.dateTransForm(
                srcDate: sourceDate,
                srcTzId: timeZone.identifier,
                destTzId: TimeZone.current.identifier
            )
            return newDate
        }
        return sourceDate
    }

    func updateSelectedDate(_ newDate: Date) {
        selectedDate = newDate
        let isValid = MailScheduleSendController.scheduledDateIsValid(scheduleDate: scheduleLocalDate,
                                                                      nowDate: Date())
        if !isValid {
            // 保证大于 5 分钟，往后 9:59 再向下取整
            let validDate = Date(timeIntervalSinceNow: 599)
            let validMinute = MailMinutesDatePickerView.getMultipleOfMinutesInterval(validDate.minute)
            var validScheduleDate = validDate.changed(minute: validMinute) ?? validDate
            validScheduleDate = calculateLocalDate(validScheduleDate, sourceTimezone: selectedTimezone)
            datePicker.setDate(validScheduleDate)
            selectedDate = validScheduleDate
        }
        updateScheduleDateTitle()
    }

    static func scheduledDateIsValid(scheduleDate: Date, nowDate: Date) -> Bool {
        let nowTimestamp = nowDate.timeIntervalSince1970
        let selectTimestamp = scheduleDate.timeIntervalSince1970
        let offset = selectTimestamp - nowTimestamp
        MailLogger.debug("mail checkselectedDate offset:\(offset)")
        // late than 5 minutes(300 seconds)
        return offset >= 300
    }

    @objc
    func onClickClose() {
        self.dismiss(animated: true) {

        }
    }

    @objc
    func onClickConfirm() {
        /// before send, check date again
        let isValid = MailScheduleSendController.scheduledDateIsValid(scheduleDate: scheduleLocalDate,
                                                                      nowDate: Date())
        if isValid {
            let timestamp = scheduleLocalDate.timeIntervalSince1970 * 1000

            let currentTimestamp = Date().timeIntervalSince1970 * 1000
            let offset = floor(timestamp - currentTimestamp)
            MailTracker.log(event: "email_scheduledSend_time", params: ["current": currentTimestamp,
                                                                        "scheduled": timestamp,
                                                                        "offset": offset,
                                                                        "hour": scheduleLocalDate.hour,
                                                                        "week": scheduleLocalDate.weekday,
                                                                        "local": timeZoneService?.preferredTimeZone.value.identifier ?? "",
                                                                        "select": selectedTimezone?.identifier ?? ""])
            self.dismiss(animated: true) { [weak self] in
                self?.delegate?.didSetScheduleSendTime(Int64(timestamp))
            }
        } else {
            let alert = LarkAlertController()
            alert.setContent(text: BundleI18n.MailSDK.Mail_SendLater_TimeInvalid, alignment: .center)
            alert.addCancelButton()
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_Confirm)
            navigator?.present(alert, from: self)
            InteractiveErrorRecorder.recordError(event: .schedule_send_time_invalid, tipsType: .alert)
            // navBar.confirmButton.isEnabled = false
        }
    }
}

extension MailScheduleSendController: MailMinutesDatePickerViewDelegate {
    func minutesDatePicker(_ picker: MailMinutesDatePickerView, didSelectDate date: Date) {
        MailLogger.info("MailScheduleSendController didSelectDate \(date)")
        updateSelectedDate(date)
    }
}

extension MailScheduleSendController: MailScheduleTimezoneViewDelegate {
    func onClickTimezoneView() {
        showTimeZonePopup()
    }

    private func showTimeZonePopup() {
        guard let service = timeZoneService else { return }
        var previousTimeZone = service.preferredTimeZone.value
        let popupVC = getPopupTimeZoneSelectViewController(
            with: service,
            selectedTimeZone: service.preferredTimeZone,
            onTimeZoneSelect: { [weak self] timeZone in
                guard let `self` = self else { return }
                if previousTimeZone.identifier != timeZone.identifier {
                    MailRoundedHUD.showSuccess(with: "\(timeZone.name)(\(timeZone.gmtOffsetDescription))", on: self.view)
                }
                previousTimeZone = timeZone
                self.updateSelectedTimezone(previousTimeZone)
                // 用户青睐的时区
                // _ = self.timeZoneService.setPreferredTimeZone(timeZone).subscribe(onDisposed:  { })
            }
        )
        present(popupVC, animated: true)
    }
}
