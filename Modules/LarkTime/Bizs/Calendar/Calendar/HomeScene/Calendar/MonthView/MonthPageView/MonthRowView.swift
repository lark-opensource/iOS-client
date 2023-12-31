//
//  MonthRowView.swift
//  Calendar
//
//  Created by zhu chao on 2018/10/18.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import LarkUIKit
import UniverseDesignFont

protocol MonthRowViewDelgate: AnyObject {
    func rowView(_ view: MonthRowView, didSelectedAt date: Date, index: Int)
    func rowView(_ view: MonthRowView, setNeedsShrinkAt date: Date, index: Int)
    func rowViewIsPageExpand(_ view: MonthRowView) -> Bool
    func rowViewIsTodayInCurrentMonth(_ view: MonthRowView) -> Bool
}

final class MonthRowView: UIView {
    private var previousSize: CGSize
    lazy var dateLabels: [RowHeaderLabel] = {
        var array = [RowHeaderLabel]()
        for i in 0..<7 {
            let label = RowHeaderLabel(alternateCalendar: alternateCalendar)
            array.append(label)
            label.tag = i
            label.addTarget(self,
                            action: #selector(dateTaped(sender:)),
                            for: .touchUpInside)
        }
        return array
    }()
    private lazy var dateHeader: MonthViewRowContainer<RowHeaderLabel> = {
        let labels = dateLabels
        let header = MonthViewRowContainer(subViews: labels,
                                           edgeInsets: UIEdgeInsets.zero)
        return header
    }()

    private lazy var eventContainer = MonthEventContainer(calendarSelectTracer: self.calendarSelectTracer)
    weak var delegate: MonthRowViewDelgate?
    var events: [MonthItem] = []
    var isSelected: Bool = false {
        didSet {
            if !isSelected {
                self.eventContainer.unselected()
                self.dateLabels.forEach({ $0.setSelected(isSelected: false,
                                                         fourceShowTodayBg: self.forceShowTodayBackground()) })
            }
        }
    }

    private let alternateCalendar: AlternateCalendarEnum
    private let isAlternateCalOpen: Bool
    private let calendarSelectTracer: CalendarSelectTracer?

    // header 34
    init(alternateCalendar: AlternateCalendarEnum,
         calendarSelectTracer: CalendarSelectTracer?,
         width: CGFloat) {
        /// 91 外层性能优化，有比较高度，决定是否刷新
        previousSize = CGSize(width: width, height: 91)
        self.alternateCalendar = alternateCalendar
        self.calendarSelectTracer = calendarSelectTracer
        self.isAlternateCalOpen = alternateCalendar != .noneCalendar
        super.init(frame: CGRect(origin: .zero, size: previousSize))
        self.layoutHeader(dateHeader)
        self.addSubview(eventContainer)
        self.layoutEventContainer(eventContainer, dateHeader: dateHeader)
        self.backgroundColor = UIColor.ud.bgBody
    }

    func dateRanges() -> (startTime: Date, endTime: Date) {
        let start = dateLabels.first?.date ?? Date()
        let end = dateLabels.last?.date?.dayEnd() ?? Date()
        assertLog(start < end)
        return (start, end)
    }

    func clearEventLabels() {
        self.eventContainer.clear()
        self.dateLabels.forEach { (label) in
            label.setCountText(with: 0)
        }
    }

    func dates() -> [Date] {
        return self.dateLabels.map({ $0.date?.dayStart() ?? Date() })
    }

    func currentSelectedIndex() -> Int? {
        return self.dateLabels.firstIndex(where: { $0.isSelected })
    }

    func setSelectedIndex(_ index: Int) {
        self.eventContainer.setSelected(index: index)
        self.dateLabels.forEach { (label) in
            label.setSelected(isSelected: label.tag == index,
                              fourceShowTodayBg: self.forceShowTodayBackground())
        }
    }

    func selectedDate() -> Date? {
        guard let label = self.dateLabels.first(where: { $0.isSelected }) else {
            return nil
        }
        return label.date
    }

    func setBlocks(_ events: [MonthItem]) {
        self.events = events
        let dateRange = self.dateRanges()
        let startDay = getJulianDay(date: dateRange.startTime)
        let endDay = getJulianDay(date: dateRange.endTime)
        let models = events.compactMap { (entity) -> MonthBlockViewCellProtocol? in
            entity.process { type in
                switch type {
                case .event(let monthEvent):
                    return MonthInstanceViewCellModel(eventViewSetting: monthEvent.eventViewSetting,
                                                      instance: monthEvent.instance,
                                                      calendar: monthEvent.calendar,
                                                      fromJulianDay: startDay,
                                                      toJulianDay: endDay)
                case .timeBlock(let timeBlockModel):
                    return MonthTimeBlockViewCellModel(eventViewSetting: timeBlockModel.eventViewSetting,
                                                       timeBlock: timeBlockModel.timeBlock,
                                                       fromJulianDay: startDay,
                                                       toJulianDay: endDay)
                case .none:
                    return nil
                }
            }
        }

        let moreNumbers = eventContainer.updateContent(models: models, startDate: dateRange.startTime)
        for i in 0..<moreNumbers.count {
            self.dateLabels[i].setCountText(with: moreNumbers[i])
        }
    }

    private func layoutHeader(_ header: UIView) {
        self.addSubview(header)
        let height: CGFloat = isAlternateCalOpen ? 24 + 18.5 : 24
        header.frame = CGRect(x: 16, y: 0, width: self.frame.width - 16 * 2, height: height)
        header.autoresizingMask = [.flexibleWidth]
    }

    private func forceShowTodayBackground() -> Bool {
        let isExpand = self.delegate?.rowViewIsPageExpand(self) ?? false
        let isTodayInCurrentMonth = self.delegate?.rowViewIsTodayInCurrentMonth(self) ?? false
        return !isExpand && isTodayInCurrentMonth
    }

    @objc
    private func dateTaped(sender: RowHeaderLabel) {
        guard let selectedDate = sender.date else { return }
        let isSelected = !sender.isSelected
        self.updateSelectStatus(of: sender, isSelected: isSelected)
        if isSelected {
            self.eventContainer.setSelected(index: sender.tag)
            self.delegate?.rowView(self,
                                   didSelectedAt: selectedDate,
                                   index: sender.tag)
        } else {
            self.eventContainer.unselected()
            self.delegate?.rowView(self, setNeedsShrinkAt: selectedDate, index: sender.tag)
        }
    }

    private func updateSelectStatus(of label: RowHeaderLabel,
                                    isSelected: Bool) {
        self.dateLabels.forEach { (tmpLabel) in
            if tmpLabel !== label {
                tmpLabel.setSelected(isSelected: false,
                                     fourceShowTodayBg: self.forceShowTodayBackground())
            }
        }
        label.setSelected(isSelected: isSelected,
                          fourceShowTodayBg: self.forceShowTodayBackground())
    }

    private func layoutEventContainer(_ container: MonthEventContainer, dateHeader: UIView) {
        self.addSubview(container)
        container.frame = CGRect(x: 16, y: dateHeader.frame.height, width: self.frame.width - 16 * 2, height: frame.height - dateHeader.frame.height)
        container.autoresizingMask = [.flexibleWidth]
        container.delegate = self
        container.layoutRectangleControls()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        TimerMonitorHelper.shared.launchTimeTracer?.showGrid.end()
        guard self.frame.size != previousSize else { return }
        self.previousSize = self.frame.size
        self.layoutEventContainer(eventContainer, dateHeader: dateHeader)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension MonthRowView: MonthEventContainerDelegate {
    func dateSelected(container: MonthEventContainer, index: Int, date: Date, isRepeat: Bool) {
        if !isRepeat {
            self.delegate?.rowView(self, didSelectedAt: date, index: index)
        } else {
            self.delegate?.rowView(self, setNeedsShrinkAt: date, index: index)
        }
        self.updateSelectStatus(of: self.dateLabels[index], isSelected: !isRepeat)
    }
}

private final class TodayBG: UIView {
    private lazy var circleShape: CAShapeLayer = {
        guard self.frame.width == self.frame.height else {
            assertionFailure()
            return CAShapeLayer()
        }
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: self.frame.width / 2,
                                                         y: self.frame.width / 2),
                                      radius: self.frame.width / 2,
                                      startAngle: CGFloat(0),
                                      endAngle: CGFloat(Double.pi * 2), clockwise: true)

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.ud.setFillColor(UIColor.ud.primaryContentDefault, bindTo: self)
        shapeLayer.ud.setStrokeColor(UIColor.ud.primaryContentDefault, bindTo: self)
        shapeLayer.lineWidth = 0.001
        return shapeLayer
    }()

    func setCircleShape(color: UIColor) {
        circleShape.ud.setFillColor(color, bindTo: self)
        circleShape.ud.setStrokeColor(color, bindTo: self)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.addSublayer(circleShape)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 月份对应label
final class RowHeaderLabel: UIControl {
    private let label = UILabel()
    private let alternateCalendarLabel = UILabel()
    private let counterLabel = UILabel()
    private lazy var todayBg: TodayBG = {
        let bg = TodayBG(frame: CGRect(x: 0, y: 0, width: 22, height: 22))
        bg.isUserInteractionEnabled = false
        self.insertSubview(bg, at: 0)
        return bg
    }()

    private let alternateCalendar: AlternateCalendarEnum
    private let isAlternateCalOpen: Bool

    init(alternateCalendar: AlternateCalendarEnum) {
        self.alternateCalendar = alternateCalendar
        self.isAlternateCalOpen = alternateCalendar != .noneCalendar
        super.init(frame: CGRect(x: 0, y: 0, width: 44, height: 34))
        self.layoutLabel(label)
        if isAlternateCalOpen {
            self.layoutAlternateCalendarLabel(alternateCalendarLabel)
        }
        self.layoutCounterLabel(counterLabel)
    }

    var date: Date?
    var isGray: Bool = false {
        didSet {
            if isAlternateCalOpen {
                alternateCalendarLabel.textColor = isGray ? UIColor.ud.textDisable : UIColor.ud.textPlaceholder
            }
        }
    }
    var isToday: Bool = false

    func setCountText(with number: Int) {
        guard number > 0 else {
            counterLabel.isHidden = true
            return
        }
        counterLabel.isHidden = false
        counterLabel.text = (number > 9) ? "+N" : "+\(number)"
    }

    private let grayTextColor = UIColor.ud.textPlaceholder

    func setDate(_ date: Date,
                 isGray: Bool,
                 isToday: Bool,
                 isSelected: Bool,
                 fourceShowTodayBg: Bool,
                 alternateCalendarText: String) {
        label.text = "\(date.day)"
        self.date = date
        self.alternateCalendarLabel.text = alternateCalendarText
        self.isGray = isGray
        self.isToday = isToday
        self.setSelected(isSelected: isSelected, fourceShowTodayBg: fourceShowTodayBg)
    }

    func setSelected(isSelected: Bool, fourceShowTodayBg: Bool) {
        self.isSelected = isSelected
        if isSelected {
            self.todayBg.isHidden = false
            if isToday {
                label.textColor = UIColor.white
                self.todayBg.setCircleShape(color: UIColor.ud.primaryContentDefault)
            } else {
                label.textColor = isGray ? grayTextColor : UIColor.ud.N800
                self.todayBg.setCircleShape(color: UIColor.ud.textDisable)
            }
        } else {
            self.todayBg.isHidden = true
            if isToday {
                if fourceShowTodayBg {
                    self.todayBg.isHidden = false
                    label.textColor = UIColor.white
                    self.todayBg.setCircleShape(color: UIColor.ud.primaryContentDefault)
                } else {
                    label.textColor = UIColor.ud.primaryContentDefault
                }
            } else {
                label.textColor = isGray ? grayTextColor : UIColor.ud.N800
            }
        }
    }

    private func layoutCounterLabel(_ label: UILabel) {
        label.frame = CGRect(x: self.bounds.width - 19 - 4.5, y: 6, width: 19, height: 12.0)
        label.isUserInteractionEnabled = false
        self.insertSubview(label, at: 0)
        label.font = UIFont.cd.mediumFont(ofSize: 10)
        label.textColor = UIColor.ud.textPlaceholder
        label.textAlignment = .center
        label.autoresizingMask = [.flexibleLeftMargin]
        label.backgroundColor = UIColor.ud.N200
        label.layer.cornerRadius = 2.5
        label.clipsToBounds = true
        label.isHidden = true
    }

    private func layoutLabel(_ label: UILabel) {
        let height = isAlternateCalOpen ? 24 : self.bounds.height
        label.frame = CGRect(x: 0, y: 0, width: 18, height: height)
        label.isUserInteractionEnabled = false
        self.addSubview(label)
        if UDFontAppearance.isCustomFont {
            label.font = UIFont.cd.mediumFont(ofSize: 12)
        } else {
            label.font = UDFont.dinBoldFont(ofSize: 14.0)
        }
        label.textColor = UIColor.ud.N800
        label.textAlignment = .center
        if !isAlternateCalOpen {
            label.autoresizingMask = [.flexibleHeight]
        }
    }

    private func layoutAlternateCalendarLabel(_ label: UILabel) {
        label.frame = CGRect(x: 0, y: 24, width: 40, height: 18.5)
        label.isUserInteractionEnabled = false
        self.addSubview(label)
        label.font = UIFont.cd.regularFont(ofSize: 12.0)
        label.textColor = UIColor.ud.N600
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.todayBg.center = label.center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
