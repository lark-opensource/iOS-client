//
//  MailOOOTimeView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/2/23.
//

import UIKit
import LarkUIKit
import UniverseDesignFont

class MailOOOTimeView: UIView {
    var startTimeAction: (() -> Void)?
    var endTimeAction: (() -> Void)?

    private var startTime: Date
    private var endTime: Date

    private let beginTimeControl: MailOOOTimeItemView
    private let endTimeControl: MailOOOTimeItemView
    private let slashView = MailSlashView()

    var leftMargin: CGFloat = 0.0

    private var calendarProvider: CalendarProxy?

    init(startTime: Date, endTime: Date, calendarProvider: CalendarProxy?) {
        self.startTime = startTime
        self.endTime = endTime
        self.beginTimeControl = MailOOOTimeItemView()
        self.endTimeControl = MailOOOTimeItemView()
        self.calendarProvider = calendarProvider
        super.init(frame: .zero)
        self.commonInit()
        self.beginTimeControl.setDate(startTime, calendarProvider: calendarProvider)
        self.endTimeControl.setDate(endTime, calendarProvider: calendarProvider)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// initialize
    func commonInit() {
        let slash = self.addSlashView()
        self.addBeginTimeItem(slash: slash, date: self.startTime)
        self.addEndTimeItem(slash: slash, date: self.endTime)
        self.backgroundColor = UIColor.ud.bgBody
    }

    func setStartTime(_ date: Date) {
        self.startTime = date
        self.beginTimeControl.setDate(date, calendarProvider: calendarProvider)
    }

    func setEndTime(_ date: Date) {
        self.endTime = date
        self.endTimeControl.setDate(date, calendarProvider: calendarProvider)
    }
    
    private func addEndTimeItem(slash: UIView, date: Date) {
        self.addSubview(self.endTimeControl)
        self.endTimeControl.addTarget(self, action: #selector(endTimeControlTaped), for: .touchUpInside)
        self.endTimeControl.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalTo(slash.snp.right)
            make.height.equalTo(slash).priority(.high)
            make.centerY.equalTo(slash)
        }
    }

    private func addBeginTimeItem(slash: UIView, date: Date) {
        self.addSubview(self.beginTimeControl)
        self.beginTimeControl.addTarget(self, action: #selector(beginTimeControlTaped), for: .touchUpInside)
        self.beginTimeControl.snp.makeConstraints { (make) in
            make.left.equalTo(leftMargin)
            make.right.equalTo(slash.snp.left)
            make.height.equalTo(slash).priority(.high)
            make.centerY.equalTo(slash)
        }
    }

    @objc
    private func beginTimeControlTaped() {
        self.startTimeAction?()
    }

    @objc
    private func endTimeControlTaped() {
        self.endTimeAction?()
    }

    private func addSlashView() -> MailSlashView {
        self.addSubview(slashView)
        slashView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(8)
        }
        return slashView
    }

    func isStartTimeSelected() -> Bool {
        return self.beginTimeControl.isSelected
    }

    func isEndTimeSelected() -> Bool {
        return self.endTimeControl.isSelected
    }

    private func deselectBeignDate() {
        self.beginTimeControl.deselect(isAvailable: true)
        self.slashView.hideLeftTriangleViews()
    }

    private func deselectEndDate(isAvailable: Bool) {
       self.endTimeControl.deselect(isAvailable: isAvailable)
       self.slashView.hideRightTriangleViews()
    }

    private func selectBeignDateView(with color: UIColor) {
        self.beginTimeControl.select(with: color)
        self.slashView.showLeftTriangle(color: color)
    }

    private func selectEndDateView(with color: UIColor) {
        self.endTimeControl.select(with: color)
        self.slashView.showRightTriangle(color: color)
    }

    func setStardRegionState(isOK: Bool?) {
        guard let isOK = isOK else {
            self.deselectBeignDate()
            return
        }
        self.selectBeignDateView(with: isOK ? UIColor.ud.primaryContentDefault : UIColor.ud.functionDangerContentPressed)
    }

    func setEndRegionState(isOK: Bool?, isAvailable: Bool) {
        guard let isOK = isOK else {
            self.deselectEndDate(isAvailable: isAvailable)
            return
        }
        self.selectEndDateView(with: isOK ? UIColor.ud.primaryContentDefault : UIColor.ud.functionDangerContentPressed)
    }
}

class MailOOOTimeItemView: UIControl {
    let weekLabel = UILabel()
    let dateLabel = UILabel()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init() {
        super.init(frame: .zero)
        self.commonInit()
    }

    func setDate(_ date: Date, calendarProvider: CalendarProxy?) {
        let dateInfo = self.parse(date: date, calendarProvider: calendarProvider)
        dateLabel.text = dateInfo.date
        weekLabel.text = dateInfo.weekDay
    }

    func commonInit() {
        dateLabel.textColor = UIColor.ud.textTitle
        dateLabel.font = UDFontAppearance.isCustomFont ? UDFont.monospacedDigitSystemFont(ofSize: 17, weight: .medium) : UDFont.dinBoldFont(ofSize: 17)
        dateLabel.numberOfLines = 0
        self.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.trailing.lessThanOrEqualToSuperview().offset(-16)
            make.top.equalToSuperview().offset(14)
        }
        weekLabel.font = UIFont.systemFont(ofSize: 14)
        weekLabel.textColor = UIColor.ud.textPlaceholder
        self.addSubview(weekLabel)
        weekLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(dateLabel)
            make.top.greaterThanOrEqualTo(dateLabel.snp.bottom).offset(3)
            make.bottom.equalToSuperview().offset(-14)
        }
    }

    func parse(date: Date, calendarProvider: CalendarProxy?) -> (date: String, time: String, weekDay: String) {
        let dateFormat: String
        dateFormat = "YYYY/MM/dd*HH:mm*\(BundleI18n.MailSDK.Mail_Calendar_Edit_DatePickerWeekday)"
        let result = date.string(with: dateFormat, isFor12Hour: false)
        let weekdayStr = calendarProvider?.formattCalenderWeekday(date: date) ?? ""

        let comp = result.components(separatedBy: "*")
        guard comp.count == 3 else {
            return ("", "", "")
        }
        return (comp[0], comp[1], weekdayStr)
    }
    
    func select(with color: UIColor) {
        self.isSelected = true
        self.backgroundColor = color
        self.dateLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        self.weekLabel.textColor = UIColor.ud.primaryOnPrimaryFill
    }

    func deselect(isAvailable: Bool) {
        self.isSelected = false
        self.backgroundColor = UIColor.ud.bgBody

        if isAvailable {
            weekLabel.textColor = UIColor.ud.textPlaceholder
            dateLabel.textColor = UIColor.ud.textTitle
        } else {
            weekLabel.textColor = UIColor.ud.functionDangerContentDefault
            dateLabel.textColor = UIColor.ud.functionDangerContentDefault
        }
    }
}

class MailSlashView: UIView {
    /// TriangleView
    private class TriangleView: UIView {
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        init() {
            super.init(frame: .zero)
            self.backgroundColor = UIColor.clear
            self.isOpaque = false
        }

        var color: UIColor = UIColor.clear {
            didSet {
                self.setNeedsDisplay()
            }
        }
    }

    /// LeftTriangleView
    private class LeftTriangleView: TriangleView {
        override func draw(_ rect: CGRect) {
            let aPath = UIBezierPath()
            aPath.lineWidth = 1.0 / UIScreen.main.scale
            aPath.move(to: .zero)
            aPath.addLine(to: CGPoint(x: 0, y: 0))
            aPath.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height / 2.0))
            aPath.addLine(to: CGPoint(x: 0, y: rect.size.height))
            aPath.close()
            self.color.setFill()
            aPath.fill()
        }
    }

    /// RightTriangleView
    private class RightTriangleView: TriangleView {
        override func draw(_ rect: CGRect) {
            let aPath = UIBezierPath()
            aPath.lineWidth = 1.0 / UIScreen.main.scale
            aPath.move(to: CGPoint(x: rect.size.width, y: 0))
            aPath.addLine(to: CGPoint(x: 0, y: 0))
            aPath.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height / 2.0))
            aPath.addLine(to: CGPoint(x: 0, y: rect.size.height))
            aPath.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height))
            aPath.close()
            self.color.setFill()
            aPath.fill()
        }
    }

    private let leftRriangleView: LeftTriangleView = LeftTriangleView()
    private let rightRriangleView: RightTriangleView = RightTriangleView()

    init() {
        super.init(frame: .zero)
        self.isOpaque = false
        self.addSubview(self.leftRriangleView)
        self.leftRriangleView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.leftRriangleView.isHidden = true
        self.addSubview(self.rightRriangleView)
        self.rightRriangleView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.rightRriangleView.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let aPath = UIBezierPath()
        aPath.lineWidth = 1.0
        aPath.move(to: CGPoint(x: 0, y: 0))
        aPath.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height / 2.0))
        aPath.addLine(to: CGPoint(x: 0, y: rect.size.height))
        UIColor.ud.lineBorderCard.setStroke()
        aPath.stroke()
    }

    func showLeftTriangle(color: UIColor) {
        self.leftRriangleView.isHidden = false
        self.leftRriangleView.color = color
    }

    func hideLeftTriangleViews() {
        self.leftRriangleView.isHidden = true
    }

    func showRightTriangle(color: UIColor) {
        self.rightRriangleView.isHidden = false
        self.rightRriangleView.color = color
    }

    func hideRightTriangleViews() {
        self.rightRriangleView.isHidden = true
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width = 16.0
        return size
    }
}
