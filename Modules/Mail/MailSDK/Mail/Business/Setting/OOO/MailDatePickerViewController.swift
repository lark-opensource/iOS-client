//
//  MailDatePickerViewController.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/24.
//

import Foundation
import LarkUIKit
import EENavigator
import LarkAlertController

protocol MailDatePickerViewControllerDelegate: AnyObject {
    var calendarProvider: CalendarProxy? { get }
    func didSaveDate(startTime: Date, endTime: Date)
}

class MailDatePickerViewController: MailBaseViewController {

    private var startTime: Date = Date()
    private var endTime: Date = Date()

    lazy var rangeView: MailOOOTimeView = {
        let timeView = MailOOOTimeView(startTime: Date(), endTime: Date(), calendarProvider: delegate?.calendarProvider)
        return timeView
    }()

    var pickerView: MailOOODatePicker = {
        let pickerView = MailOOODatePicker(startTime: Date(), endTime: Date(), frameWidth: Display.width)
        return pickerView
    }()

    weak var delegate: MailDatePickerViewControllerDelegate?
    var isSelectAtStarTime = true

    private lazy var rightItem: UIBarButtonItem = {
        let saveBtn = LKBarButtonItem(title: BundleI18n.MailSDK.Mail_CustomLabels_Save)
        saveBtn.button.tintColor = UIColor.ud.primaryContentPressed
        saveBtn.addTarget(self, action: #selector(saveDate), for: .touchUpInside)
        return saveBtn
    }()
    
    private let accountContext: MailAccountContext
    
    init(accountContext: MailAccountContext) {
        self.accountContext = accountContext
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

        setupViews()

        rangeView.startTimeAction = { [unowned self] in
            self.switchToStatrTime()
            self.pickerView.updateStartTime(self.startTime)
            self.pickerView.switchToStartDate()
            self.updateEndTimeState(startTime: self.startTime, endDate: self.endTime, preStartDate: nil, rangeView: self.rangeView)
        }
        rangeView.endTimeAction = { [unowned self] in
            self.switchToEndTime()
            self.pickerView.updateEndTime(self.endTime)
            self.pickerView.switchToEndDate()
        }

         // 选前/后
        if isSelectAtStarTime {
            self.switchToStatrTime()
            self.pickerView.switchToStartDate()
        } else {
            self.switchToEndTime()
            self.pickerView.switchToEndDate()
        }
    }

    func setupViews() {
        // isToolBarHidden = false
        isNavigationBarHidden = false
        addCloseItem()
        closeCallback = { [weak self] in
            guard let `self` = self else { return }
            // self.attachmentViewModel.cancelAll()
        }
        navigationItem.rightBarButtonItem = self.rightItem

        view.addSubview(rangeView)
        pickerView.delegate = self
        view.addSubview(pickerView)

        rangeView.snp.makeConstraints { (make) in
            make.top.left.width.equalToSuperview()
        }
        pickerView.snp.makeConstraints { (make) in
            make.top.equalTo(rangeView.snp.bottom)
            make.width.left.equalToSuperview()
            make.height.equalTo(256)
        }
        rangeView.addTopBorder()
        pickerView.addTopBorder()
    }

    @objc
    func saveDate() {
        if isLegalEndDate(endTime, startTime: startTime) {
            delegate?.didSaveDate(startTime: startTime, endTime: endTime)
            dismiss(animated: true, completion: nil)
        } else {
            let alert = LarkAlertController()
            alert.setContent(text: BundleI18n.MailSDK.Mail_Calendar_Edit_InvalidEndTime, alignment: .center)
            alert.addPrimaryButton(text: BundleI18n.MailSDK.Mail_Alert_Confirm)
            navigator?.present(alert, from: self)
            InteractiveErrorRecorder.recordError(event: .ooo_save_date_time_invalid, tipsType: .alert)
        }
    }

    func updateStartTimeRangeAndPicker(_ date: Date) {
        startTime = date
        pickerView.updateStartTime(startTime)
        rangeView.setStartTime(startTime)
    }

    func updateEndTimeRangeAndPicker(_ date: Date) {
        endTime = date
        pickerView.updateEndTime(endTime)
        rangeView.setEndTime(endTime)
    }
}

// MARK: picker delegate
extension MailDatePickerViewController: MailOOODatePickerDelegate {
    func oooDatePicker(_ picker: MailOOODatePicker, startTimeDidSelected date: Date) {
        guard self.rangeView.isStartTimeSelected() else { return }
        let preStartDate = startTime
        startTime = date
        rangeView.setStartTime(date)
        self.rangeView.setStardRegionState(isOK: true)
        updateEndTimeState(startTime: startTime, endDate: endTime, preStartDate: preStartDate, rangeView: rangeView)
    }

    func updateEndTimeState(startTime: Date, endDate: Date, preStartDate: Date?, rangeView: MailOOOTimeView) {
        // 如果结束时间处于不合法状态(飘红)需要更新一下状态
        // 需要更新endDate为
        let isCurrentEndtimeLegal = isLegalEndDate(endTime, startTime: startTime)
        if !isCurrentEndtimeLegal {
            let newEndDate: Date
            if let preStartDate = preStartDate {
                let interval = endTime.timeIntervalSince(preStartDate)
                newEndDate = Date(timeInterval: abs(interval), since: startTime)
            } else {
                newEndDate = endDate
            }
            endTime = newEndDate
            rangeView.setEndTime(newEndDate)
            pickerView.updateEndTime(newEndDate)
        }
        /// 更新后最终确定是否需要显示红色
        rangeView.setEndRegionState(isOK: nil,
                                    isAvailable: isLegalEndDate(endTime, startTime: startTime))
    }

    func oooDatePicker(_ picker: MailOOODatePicker, endTimeDidSelected date: Date) {
        guard self.rangeView.isEndTimeSelected() else { return }
        endTime = date
        rangeView.setEndTime(date)
        let endtimeLegal = isLegalEndDate(date, startTime: self.startTime)
        self.rangeView.setEndRegionState(isOK: endtimeLegal, isAvailable: endtimeLegal)
    }

    func oooPickerDidSwitchToStartDate(_ picker: MailOOODatePicker) {
        self.switchToStatrTime()
    }

    func oooPickerDidSwitchToEndDate(_ picker: MailOOODatePicker) {
        self.switchToEndTime()
    }

    private func switchToStatrTime() {
        self.rangeView.setEndRegionState(isOK: nil,
                                         isAvailable: true)
        self.rangeView.setStardRegionState(isOK: true)
    }

    private func switchToEndTime() {
        self.rangeView.setStardRegionState(isOK: nil)
        let isLegal = isLegalEndDate(self.endTime, startTime: self.startTime)
        self.rangeView.setEndRegionState(isOK: isLegal, isAvailable: isLegal)
    }

    func isLegalEndDate(_ date: Date, startTime: Date) -> Bool {
        let isSameDay = Calendar.current.isDate(date, inSameDayAs: startTime)
        let isGreater = date >= startTime
        return isSameDay || isGreater
    }
}
