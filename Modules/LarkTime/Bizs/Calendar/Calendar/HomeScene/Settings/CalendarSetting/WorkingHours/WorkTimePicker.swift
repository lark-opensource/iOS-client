//
//  WorkTimePicker.swift
//  Calendar
//
//  Created by zhuchao on 2019/5/22.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit
import LarkDatePickerView

final class WorkTimePicker {
    private let pickerView: WorkTimePickerView
    private let selection: (_ startTime: Int, _ endTime: Int) -> Void
    private let errorSelection: (UIViewController) -> Void
    init(weekDay: String,
         startTime: Int,
         endTime: Int,
         is12HourStyle: Bool,
         isMeridiemIndicatorAheadOfTime: Bool,
         displayWidth: CGFloat,
         selection: @escaping (_ startTime: Int, _ endTime: Int) -> Void,
         errorSelection: @escaping (UIViewController) -> Void) {
        self.selection = selection
        self.errorSelection = errorSelection
        pickerView = WorkTimePickerView(weekDay: weekDay,
                                        startTime: startTime,
                                        endTime: endTime,
                                        is12HourStyle: is12HourStyle,
                                        isMeridiemIndicatorAheadOfTime: isMeridiemIndicatorAheadOfTime,
                                        displayWidth: displayWidth)
    }

    func show(in parentController: UIViewController) {
        let risingController = RisingController(contentView: pickerView)
        if Display.pad {
            risingController.modalPresentationStyle = .formSheet
        }
        parentController.present(risingController, animated: true, completion: nil)
        let selection = self.selection
        pickerView.selection = { (startTime: Int, endTime: Int) in
            parentController.dismiss(animated: true, completion: nil)
            selection(startTime, endTime)
        }
        let errorSelection = self.errorSelection
        pickerView.errorSelection = { [weak risingController] in
            guard let risingController = risingController else {
                return
            }
            errorSelection(risingController)
        }
    }
}

private final class WorkTimePickerView: RisingView {

    private static let headerHeight: CGFloat = 50.0
    fileprivate static let pickerHeight: CGFloat = 156.0
    private static let bottomBarHeight: CGFloat = 49.0
    private let startTimeButton = UIButton.cd.button(type: .system)
    private let endTimeButton = UIButton.cd.button(type: .system)
    private var selectedButton: UIButton?

    private var startTimePicker: WorkTimePickerContent!
    private var endTimePicker: WorkTimePickerContent!

    var selection: ((_ startTime: Int, _ end: Int) -> Void)?
    var errorSelection: (() -> Void)?

    init(weekDay: String,
         startTime: Int,
         endTime: Int,
         is12HourStyle: Bool,
         isMeridiemIndicatorAheadOfTime: Bool,
         displayWidth: CGFloat) {
        let initHeight = WorkTimePickerView.headerHeight + WorkTimePickerView.pickerHeight + WorkTimePickerView.bottomBarHeight
        let initFrame = CGRect(x: 0, y: 0, width: displayWidth, height: initHeight)
        super.init(frame: initFrame)
        addHeaderView()
        addEndTimePicker(week: weekDay, hour: endTime / 60, minute: endTime % 60, is12HourStyle: is12HourStyle, isMeridiemIndicatorAheadOfTime: isMeridiemIndicatorAheadOfTime)
        addStartTimePicker(week: weekDay, hour: startTime / 60, minute: startTime % 60, is12HourStyle: is12HourStyle, isMeridiemIndicatorAheadOfTime: isMeridiemIndicatorAheadOfTime)
        addFooterView()
        backgroundColor = UIColor.ud.bgBody
        endTimePicker.isHidden = true
    }

    override func relayout(newWidth: CGFloat) {
        self.startTimePicker.relayout(newWidth: newWidth)
        var startTimeFrame = self.startTimePicker.frame
        startTimeFrame.origin.y = WorkTimePickerView.headerHeight
        self.startTimePicker.frame = startTimeFrame

        self.endTimePicker.relayout(newWidth: newWidth)
        var endTimeFrame = self.endTimePicker.frame
        endTimeFrame.origin.y = WorkTimePickerView.headerHeight
        self.endTimePicker.frame = endTimeFrame
    }

    required init?(coder aDecoder: NSCoder) {

        fatalError("init(coder:) has not been implemented")
    }

    private func addHeaderView() {
        let header = UIView()
        self.addSubview(header)
        header.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(WorkTimePickerView.headerHeight)
        }
        header.addBottomBorder()
        let confirmButton = UIButton.cd.button(type: .system)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        confirmButton.setTitle(BundleI18n.Calendar.Calendar_Common_Confirm, for: .normal)
        confirmButton.setTitleColor(.ud.primaryContentDefault, for: .normal)
        confirmButton.addTarget(self, action: #selector(confirm(sender:)), for: .touchUpInside)
        confirmButton.contentHorizontalAlignment = .right
        header.addSubview(confirmButton)
        confirmButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }

    @objc
    private func confirm(sender: UIButton) {
        if currentStartTime() > currentEndTime() {
            errorSelection?()
            return
        }
        selection?(currentStartTime(), currentEndTime())
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = WorkTimePickerView.headerHeight + WorkTimePickerView.pickerHeight + WorkTimePickerView.bottomBarHeight
        return size
    }

    private func addStartTimePicker(week: String,
                                    hour: Int,
                                    minute: Int,
                                    is12HourStyle: Bool,
                                    isMeridiemIndicatorAheadOfTime: Bool) {
        let picker: WorkTimePickerContent
        if is12HourStyle {
            picker = WorkTime12HourPickerContent(week: week,
                                                 hour: hour,
                                                 minute: minute,
                                                 isMeridiemIndicatorAheadOfTime: isMeridiemIndicatorAheadOfTime,
                                                 displayWidth: self.frame.width)
        } else {
            picker = WorkTimePickerContent(week: week,
                                           hour: hour,
                                           minute: minute,
                                           displayWidth: self.frame.width)
        }
        var frame = picker.frame
        frame.origin.y = WorkTimePickerView.headerHeight
        picker.frame = frame
        addSubview(picker)
        self.startTimePicker = picker
        picker.selectionCallBack = { [weak self] (hour: Int, minute: Int) -> Void in
            self?.didSelectStartTime(hour * 60 + minute)
        }
    }

    private func didSelectStartTime(_ time: Int) {
        if time > currentEndTime() {
            startTimePicker.isInvalid = true
            endTimePicker.isInvalid = true
        } else {
            startTimePicker.isInvalid = false
            endTimePicker.isInvalid = false
        }
    }

    private func addEndTimePicker(week: String, hour: Int, minute: Int, is12HourStyle: Bool, isMeridiemIndicatorAheadOfTime: Bool) {
        let picker: WorkTimePickerContent
        if is12HourStyle {
            picker = WorkTime12HourPickerContent(week: week,
                                                 hour: hour,
                                                 minute: minute,
                                                 isMeridiemIndicatorAheadOfTime: isMeridiemIndicatorAheadOfTime,
                                                 displayWidth: self.frame.width)
        } else {
            picker = WorkTimePickerContent(week: week,
                                           hour: hour,
                                           minute: minute,
                                           displayWidth: self.frame.width)
        }
        var frame = picker.frame
        frame.origin.y = WorkTimePickerView.headerHeight
        picker.frame = frame
        addSubview(picker)
        self.endTimePicker = picker
        picker.selectionCallBack = { [weak self] (hour: Int, minute: Int) -> Void in
            self?.didSelectEndTime(hour * 60 + minute)
        }
    }

    private func didSelectEndTime(_ time: Int) {
        if currentStartTime() > time {
            startTimePicker.isInvalid = true
            endTimePicker.isInvalid = true
        } else {
            startTimePicker.isInvalid = false
            endTimePicker.isInvalid = false
        }
    }

    private func currentStartTime() -> Int {
        let selected = startTimePicker.currentSelected()
        return selected.hour * 60 + selected.minute
    }

    private func currentEndTime() -> Int {
        let selected = endTimePicker.currentSelected()
        return selected.hour * 60 + selected.minute
    }

    private func addFooterView() {
        let footer = UIView()
        self.addSubview(footer)
        footer.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(WorkTimePickerView.bottomBarHeight)
        }
        startTimeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        startTimeButton.setTitle(BundleI18n.Calendar.Calendar_Edit_StartTime, for: .normal)
        startTimeButton.addTarget(self, action: #selector(beginEndButtonAction(sender:)), for: .touchUpInside)
        footer.addSubview(startTimeButton)
        startTimeButton.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        endTimeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        endTimeButton.setTitle(BundleI18n.Calendar.Calendar_Edit_EndTime, for: .normal)
        endTimeButton.addTarget(self, action: #selector(beginEndButtonAction(sender:)), for: .touchUpInside)
        footer.addSubview(endTimeButton)
        endTimeButton.snp.makeConstraints { (make) in
            make.top.right.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }
        footer.addTopBorder()
        self.updateButtonState(button: startTimeButton, isSelected: true)
        self.updateButtonState(button: endTimeButton, isSelected: false)
        self.selectedButton = self.startTimeButton
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(line)
        line.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(footer)
            make.width.equalTo(1.0 / UIScreen.main.scale)
        }
    }

    private func updateButtonState(button: UIButton, isSelected: Bool) {
        if isSelected {
            button.setTitleColor(NewEventViewUIStyle.Color.blueBackground, for: .normal)
        } else {
            button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        }
    }

    @objc
    private func beginEndButtonAction(sender: UIButton) {
        if let selectedButton = self.selectedButton {
            self.updateButtonState(button: selectedButton, isSelected: false)
        }
        self.updateButtonState(button: sender, isSelected: true)
        self.selectedButton = sender
        self.switchBetweenStartEnd(isStartDate: self.isSelectingBeginDate())
    }

    private func switchBetweenStartEnd(isStartDate: Bool) {
        if isStartDate {
            startTimePicker.isHidden = false
            endTimePicker.isHidden = true
        } else {
            startTimePicker.isHidden = true
            endTimePicker.isHidden = false
        }
    }

    func isSelectingBeginDate() -> Bool {
        return self.selectedButton === self.startTimeButton
    }
}

private class WorkTimePickerContent: UIView {

    private static let pickerHeight: CGFloat = 156.0
    private let weekLabel = UILabel()
    fileprivate var hourView: NumberColumnView!
    fileprivate var minuteView: NumberColumnView!
    private let colon = UILabel()
    private let middleColorView = UIView()
    var selectionCallBack: ((_ hour: Int, _ minutes: Int) -> Void)?
    private var topCover: UIImageView = .init(image: nil)
    private var bottomCover: UIImageView = .init(image: nil)

    private let widthMultiplier: CGFloat = 1 / 3.0

    init(week: String, hour: Int, minute: Int, displayWidth: CGFloat) {
        let initFrame = CGRect(x: 0, y: 0, width: displayWidth, height: WorkTimePickerView.pickerHeight)
        super.init(frame: initFrame)
        layoutWeekLabel(weekLabel, text: week, widthMultiplier: widthMultiplier)
        layoutHourColumn(hour: hour, x: initFrame.width * widthMultiplier, widthMultiplier: widthMultiplier)
        let interval: Int = 5
        layoutMinuteColumn(minute: WorkTimePickerContent.formattedTime(minute, interval: interval), interval: 5, x: initFrame.width * widthMultiplier * 2, widthMultiplier: widthMultiplier)
        addTopCover()
        addBottomCover()
        layoutIfNeeded()
    }

    func relayout(newWidth: CGFloat) {
        self.frame = CGRect(x: 0, y: 0, width: newWidth, height: WorkTimePickerView.pickerHeight)
        self.weekLabel.frame = CGRect(x: 0, y: 0, width: newWidth * widthMultiplier + 1, height: self.bounds.height)

        // 获得当前centerCell显示的元素
        guard let hour = self.hourView.getCenterCellText() else {
            return
        }
        guard let minute = self.minuteView.getCenterCellText() else {
            return
        }

        // 删除旧的hourView和minuteView
        self.hourView.removeFromSuperview()
        self.hourView = nil
        self.minuteView.removeFromSuperview()
        self.minuteView = nil

        // 用删除旧view前保存的hour和minute重新生成
        layoutHourColumn(hour: hour - 1, x: self.frame.width * widthMultiplier, widthMultiplier: widthMultiplier)
        let interval: Int = 5
        layoutMinuteColumn(minute: WorkTimePickerContent.formattedTime(minute - interval, interval: interval), interval: 5, x: self.frame.width * widthMultiplier * 2, widthMultiplier: widthMultiplier)

        // 恢复之前的isInvalid状态(是否红色)，这里延迟0.1秒是因为直接执行取不到hourView/minuteView的centerCell
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.changeColor(isInvalid: self.isInvalid)
        }

        bringSubviewToFront(topCover)
        bringSubviewToFront(bottomCover)
    }

    static func formattedTime(_ time: Int, interval: Int) -> Int {
        let modLeft = time % interval
        return modLeft == 0 ? time : time + (interval - modLeft)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func layoutWeekLabel(_ label: UILabel,
                                     text: String,
                                     widthMultiplier: CGFloat) {
        addSubview(label)
        label.text = text
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        label.textColor = UIColor.ud.textTitle
        label.frame = CGRect(x: 0, y: 0, width: self.bounds.width * widthMultiplier + 1, height: self.bounds.height)
    }

    fileprivate func layoutHourColumn(hour: Int, x: CGFloat, widthMultiplier: CGFloat, modNumber: Int = 24, is12HourStyle: Bool = false) {
        let columnFrame = CGRect(x: x, y: 0, width: self.bounds.width * widthMultiplier + 1, height: self.bounds.height)
        let column = NumberColumnView(frame: columnFrame,
                                      currentNumber: hour,
                                      modNumber: modNumber,
                                      interval: 1,
                                      isDoubleDigit: !is12HourStyle,
                                      is12HourStyle: is12HourStyle)
        hourView = column
        addSubview(column)
        column.selectedAction = { [unowned self] (_: Int) -> Void in
            self.selectionCallBack?(self.selectedHour(), self.minuteView.selectedNumber())
        }
        colon.font = UIFont.cd.font(ofSize: 20)
        colon.textAlignment = .center
        colon.textColor = UIColor.ud.textTitle
        colon.text = ":"
        colon.sizeToFit()
        column.addSubview(colon)
        colon.center = CGPoint(x: columnFrame.width - 2, y: columnFrame.height / 2.0 - 2)
    }

    var isInvalid: Bool = false {
        didSet {
            changeColor(isInvalid: isInvalid)
        }
    }

    func changeColor(isInvalid: Bool) {
        let textColor = isInvalid ? UIColor.ud.functionDangerContentDefault : UIColor.ud.textTitle

        weekLabel.textColor = textColor
        colon.textColor = textColor
        hourView.changeColor(isInvalid: isInvalid)
        minuteView.changeColor(isInvalid: isInvalid)
    }

    fileprivate func layoutMinuteColumn(minute: Int, interval: Int, x: CGFloat, widthMultiplier: CGFloat) {
        let columnFrame = CGRect(x: x, y: 0, width: self.bounds.width * widthMultiplier + 1, height: self.bounds.height)
        let column = NumberColumnView(frame: columnFrame,
                                      currentNumber: minute,
                                      modNumber: 60,
                                      interval: interval,
                                      isDoubleDigit: true)
        addSubview(column)
        minuteView = column
        column.selectedAction = { [unowned self] (minute: Int) -> Void in
            self.selectionCallBack?(self.selectedHour(), minute)
        }
    }

    func currentSelected() -> (hour: Int, minute: Int) {
        return (selectedHour(), minuteView.selectedNumber())
    }

    fileprivate func selectedHour() -> Int {
        return hourView.selectedNumber()
    }

    func addTopCover() {
        let gradientImage = UIImage.cd.verticalGradientImage(fromColor: DarkMode.pickerTopGradient.top,
                                                             toColor: DarkMode.pickerTopGradient.bottom,
                                                             size: CGSize(width: self.bounds.width, height: 50),
                                                             locations: [0.3, 1.0])
        let gradientView = UIImageView(image: gradientImage)
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        gradientView.isUserInteractionEnabled = false
        gradientView.sizeToFit()
        self.topCover = gradientView
        self.addSubview(gradientView)
    }

    func addBottomCover() {
        let gradientImage = UIImage.cd.verticalGradientImage(fromColor: DarkMode.pickerBottomGradient.top,
                                                             toColor: DarkMode.pickerBottomGradient.bottom,
                                                             size: CGSize(width: bounds.width, height: 50),
                                                             locations: [0.0, 0.7])
        let gradientView = UIImageView(image: gradientImage)
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        gradientView.isUserInteractionEnabled = false
        gradientView.sizeToFit()
        var frame = gradientView.frame
        frame.origin.y = self.bounds.height - frame.height
        gradientView.frame = frame
        self.bottomCover = gradientView
        self.addSubview(gradientView)
    }
}

private final class WorkTime12HourPickerContent: WorkTimePickerContent {
    private let isMeridiemIndicatorAheadOfTime: Bool
    private var symbolView: DateSymbolView!
    init(week: String, hour: Int, minute: Int, isMeridiemIndicatorAheadOfTime: Bool, displayWidth: CGFloat) {
        self.isMeridiemIndicatorAheadOfTime = isMeridiemIndicatorAheadOfTime
        super.init(week: week, hour: hour, minute: minute, displayWidth: displayWidth)
        layoutSymbolView(isAm: hour < 12, isMeridiemIndicatorAheadOfTime: isMeridiemIndicatorAheadOfTime)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func relayout(newWidth: CGFloat) {
        super.relayout(newWidth: newWidth)
        let isAm = self.symbolView.getIsAm()

        self.symbolView.removeFromSuperview()
        self.symbolView = nil

        layoutSymbolView(isAm: isAm, isMeridiemIndicatorAheadOfTime: isMeridiemIndicatorAheadOfTime)
    }

    override func changeColor(isInvalid: Bool) {
        super.changeColor(isInvalid: isInvalid)
        symbolView.changeColor(isInvalid: isInvalid)
    }

    fileprivate override func layoutHourColumn(hour: Int,
                                               x: CGFloat,
                                               widthMultiplier: CGFloat,
                                               modNumber: Int,
                                               is12HourStyle: Bool) {
        super.layoutHourColumn(
            hour: hour,
            x: self.bounds.width * (isMeridiemIndicatorAheadOfTime ? 0.5 : 0.25),
            widthMultiplier: 0.25,
            modNumber: 12,
            is12HourStyle: true
        )
    }

    fileprivate override func layoutWeekLabel(_ label: UILabel,
                                     text: String,
                                     widthMultiplier: CGFloat) {
        super.layoutWeekLabel(label, text: text, widthMultiplier: 1 / 4.0)
    }

    fileprivate override func layoutMinuteColumn(minute: Int, interval: Int, x: CGFloat, widthMultiplier: CGFloat) {
        super.layoutMinuteColumn(
            minute: minute,
            interval: interval,
            x: self.bounds.width * (isMeridiemIndicatorAheadOfTime ? 0.75 : 0.5),
            widthMultiplier: 0.25
        )
    }

    fileprivate override func selectedHour() -> Int {
        let hour = hourView.selectedNumber()
        let isAm = symbolView.getIsAm()
        if isAm {
            if hour == 12 { return 0 }
            return hour
        } else { // PM
            if hour == 12 { return 12 }
            return hour + 12
        }
    }

    private func layoutSymbolView(isAm: Bool, isMeridiemIndicatorAheadOfTime: Bool) {
        let frame = CGRect(
            x: self.bounds.width * (isMeridiemIndicatorAheadOfTime ? 0.25 : 0.75),
            y: 0,
            width: self.bounds.width * 0.25,
            height: self.bounds.height
        )
        let symbolView = DateSymbolView(isAm: isAm, frame: frame)
        symbolView.selectedAction = { [unowned self] (_: Bool) -> Void in
            self.selectionCallBack?(self.selectedHour(), self.minuteView.selectedNumber())
        }
        insertSubview(symbolView, belowSubview: hourView)
        self.symbolView = symbolView
    }
}
