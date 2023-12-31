//
//  IntervalPicker.swift
//  Calendar
//
//  Created by zhuchao on 2018/3/23.
//  Copyright © 2018年 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import EventKit
import LarkDatePickerView

protocol IntervalPickerDelegate: AnyObject {
    func intervaPicker(_ picker: IntervalPicker, didSelectAt interval: Int, type: IntervalPicker.Frequency)
}

final class IntervalPicker: PickerView {
    enum Frequency: Int {
        case daily = 1
        case weekly
        case monthly
        case yearly

        static func totalNumber() -> Int {
            return 4
        }

        static func string(withRawValue value: Int, interval: Int) -> String {
            switch value {
            case 1:
                return BundleI18n.RRule.Calendar_Plural_RRuleDay(number: interval)
            case 2:
                return BundleI18n.RRule.Calendar_Plural_RRuleWeek(number: interval)
            case 3:
                return BundleI18n.RRule.Calendar_Plural_RRuleMonth(number: interval)
            case 4:
                return BundleI18n.RRule.Calendar_Plural_RRuleYear(number: interval)
            default:
                assertionFailureLog()
                return ""
            }
        }

        func toEventKitFrequency() -> EKRecurrenceFrequency {
            switch self {
            case .monthly:
                return .monthly
            case .daily:
                return .daily
            case .weekly:
                return .weekly
            case .yearly:
                return .yearly
            }
        }
    }

    var defaultInterval: Int = 1
    var defaultFrequency: Frequency = .daily

    private var intervalLimit: Int = 99
    private var frequencyLimit: Int = Frequency.totalNumber()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupEveryTipLabel()
        backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupEveryTipLabel() {
        let label = UILabel.cd.textLabel(fontSize: 20)
        label.text = BundleI18n.RRule.Calendar_RRule_Every
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview().multipliedBy(0.25)
        }
    }

    weak var delegate: IntervalPickerDelegate?

    override func scrollViewFrame(index: Int) -> CGRect {
        assertLog(self.bounds.width > 0 && self.bounds.height > 0)
        let minutesLeftWheelWidth: CGFloat = 86.0 / 375.0 * self.bounds.width
        let minutesMiddleWheelWidth: CGFloat = 72.0 / 375.0 * self.bounds.width
        let minutesRightWheelWidth: CGFloat = self.bounds.width - minutesLeftWheelWidth - minutesMiddleWheelWidth

        switch index {
        case 1:
            return CGRect(x: 0, y: 0, width: minutesLeftWheelWidth, height: self.bounds.height)
        case 2:
            return CGRect(x: minutesLeftWheelWidth, y: 0, width: minutesMiddleWheelWidth, height: self.bounds.height)
        case 3:
            return CGRect(x: minutesLeftWheelWidth + minutesMiddleWheelWidth, y: 0, width: minutesRightWheelWidth, height: self.bounds.height)
        default:
            assertionFailureLog()
            return .zero
        }
    }

    // MARK: scroll view delegate
    override func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        guard let cell = view as? DatePickerCell else {
            return
        }
        let offSet = index
        switch scrollView {
        case firstScrollView:
            break
        case secondScrollView:
            let number = self.recycledNumber(withBenchmark: self.defaultInterval, offSet: offSet, modNumber: intervalLimit)
            cell.label.text = "\(number)"
        case thirdScrollView:
            let number = self.recycledNumber(withBenchmark: self.defaultFrequency.rawValue, offSet: offSet, modNumber: frequencyLimit)
            cell.label.text = Frequency.string(withRawValue: number, interval: selectedInterval())
        default:
            assertionFailureLog()
        }
    }

    override func scrollEndScroll(scrollView: InfiniteScrollView) {
        super.scrollEndScroll(scrollView: scrollView)
        if scrollView === secondScrollView {
            thirdScrollView.reloadData()
        }
        self.delegate?.intervaPicker(self,
                                       didSelectAt: self.selectedInterval(),
                                       type: self.selectedFrequency())
    }

    // MARK: methods
    func selectedInterval() -> Int {
        guard let centerCell = self.centerCell(of: secondScrollView) else {
            return self.defaultInterval
        }
        return self.recycledNumber(withBenchmark: self.defaultInterval, offSet: centerCell.tag, modNumber: self.intervalLimit)
    }

    func selectedFrequency() -> Frequency {
        guard let centerCell = self.centerCell(of: thirdScrollView) else {
            return self.defaultFrequency
        }
        let number = self.recycledNumber(withBenchmark: self.defaultFrequency.rawValue,
                                         offSet: centerCell.tag,
                                         modNumber: self.frequencyLimit)
        if let type = Frequency(rawValue: number) {
            return type
        }
        assertionFailureLog()
        return self.defaultFrequency
    }
}
