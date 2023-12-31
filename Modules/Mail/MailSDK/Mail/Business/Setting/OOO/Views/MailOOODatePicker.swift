//
//  MailOOODatePicker.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/23.
//

import UIKit
import RxSwift
import RxCocoa
import LarkUIKit

protocol MailOOODatePickerDelegate: AnyObject {
    func oooDatePicker(_ picker: MailOOODatePicker, startTimeDidSelected date: Date)
    func oooDatePicker(_ picker: MailOOODatePicker, endTimeDidSelected date: Date)
    func oooPickerDidSwitchToStartDate(_ picker: MailOOODatePicker)
    func oooPickerDidSwitchToEndDate(_ picker: MailOOODatePicker)
}

class MailOOODatePicker: UIView, MailDatePickerViewDelegate {

    private let startTimeButton = UIButton(type: .system)
    private let endTimeButton = UIButton(type: .system)
    private var selectedButton: UIButton!
    private var frameWidth: CGFloat
    private let disposeBag = DisposeBag()
    var startTime: Date
    var endTime: Date
    weak var delegate: MailOOODatePickerDelegate?

    func updateStartTime(_ date: Date) {
        self.startTime = date
        self.startTimePicker.setDate(date)
    }

    func updateEndTime(_ date: Date) {
        self.endTime = date
        self.endTimePicker.setDate(date)
    }

    private lazy var startTimePicker: MailDatePickerView = {
        let picker = MailDatePickerView(frame: self.datePickerFrame(), selectedDate: self.startTime)
        picker.delegate = self
        self.pickerWrapper.insertSubview(picker, at: 0)
        picker.snp.makeConstraints({make in
            make.edges.equalToSuperview()
        })
        return picker
    }()

    private lazy var endTimePicker: MailDatePickerView = {
        let picker = MailDatePickerView(frame: self.datePickerFrame(), selectedDate: self.endTime)
        picker.delegate = self
        self.pickerWrapper.insertSubview(picker, at: 0)
        picker.snp.makeConstraints({make in
            make.edges.equalToSuperview()
        })
        return picker
    }()

    private func datePickerFrame() -> CGRect {
        return CGRect(x: 0.0,
                      y: 0.0,
                      width: self.frameWidth,
                      height: 256)
    }

    private let pickerWrapper: UIView = UIView()
    /// initialize
    func commonInit() {
//        self.backgroundColor = UIColor.white
        self.addSubview(self.pickerWrapper)
        pickerWrapper.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        // _ = self.addFooterView(pickerView: pickerWrapper)
        self.updateButtonState(button: startTimeButton, isSelected: true)
        self.updateButtonState(button: endTimeButton, isSelected: false)
        self.selectedButton = self.startTimeButton
    }

    init(startTime: Date,
         endTime: Date,
         frameWidth: CGFloat) {
        self.startTime = startTime
        self.endTime = endTime
        self.frameWidth = frameWidth
        super.init(frame: .zero)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: date picker delegate

    func datePicker(_ picker: MailDatePickerView, didSelectDate date: Date) {
        if picker === self.startTimePicker {
            self.startTimeSelected(date: date)
        } else {
            self.endTimeSelected(date: date)
        }
    }

    func updateButtonState(button: UIButton, isSelected: Bool) {
        if isSelected {
            button.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        } else {
            button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        }
    }

    @objc
    private func beginEndButtonAction(sender: UIButton) {
        self.updateButtonState(button: self.selectedButton, isSelected: false)
        self.updateButtonState(button: sender, isSelected: true)
        self.selectedButton = sender
        self.switchBetweenStartEnd(isStartDate: false)
    }

    @objc
    private func beginStartButtonAction(sender: UIButton) {
        self.updateButtonState(button: self.selectedButton, isSelected: false)
        self.updateButtonState(button: sender, isSelected: true)
        self.selectedButton = sender
        self.switchBetweenStartEnd(isStartDate: true)
    }

    func switchToStartDate() {
        self.beginStartButtonAction(sender: self.startTimeButton)
    }

    func switchToEndDate() {
        self.beginEndButtonAction(sender: self.endTimeButton)
    }

    private func switchBetweenStartEnd(isStartDate: Bool) {
        self.switchViews(isSelectStartDate: isStartDate)
        let originalPicker = self.pickerToDisplay(isSelectStartDate: isStartDate)
        originalPicker.killScroll()
        if isStartDate {
            self.delegate?.oooPickerDidSwitchToStartDate(self)
        } else {
            self.delegate?.oooPickerDidSwitchToEndDate(self)
        }
    }

    func switchViews(isSelectStartDate: Bool) {
        self.pickerWrapper.bringSubviewToFront(self.pickerToDisplay(isSelectStartDate: isSelectStartDate))
    }

    func pickerToDisplay(isSelectStartDate: Bool) -> MailPickerView {
        if isSelectStartDate {
            return self.startTimePicker
        } else {
            return self.endTimePicker
        }
    }

    func startTimeSelected(date: Date) {
        let date = Calendar.current.startOfDay(for: date)
        if date.compare(Date()) == .orderedDescending {
            self.delegate?.oooDatePicker(self, startTimeDidSelected: date)
        } else {
            updateStartTime(Date())
            self.delegate?.oooDatePicker(self, startTimeDidSelected: Date())
        }
    }

    func endTimeSelected(date: Date) {
        let date = Calendar.current.startOfDay(for: date).changed(hour: 23) ?? date
        if date.compare(Date()) == .orderedDescending {
            self.delegate?.oooDatePicker(self, endTimeDidSelected: date)
        } else {
            updateEndTime(Date())
            self.delegate?.oooDatePicker(self, endTimeDidSelected: Date())
        }
    }
}
