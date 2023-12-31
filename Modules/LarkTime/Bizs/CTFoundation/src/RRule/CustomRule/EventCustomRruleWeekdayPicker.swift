//
//  EventCustomRruleWeekdayPicker.swift
//  Calendar
//
//  Created by 张威 on 2020/4/16.
//

import UIKit
import EventKit
import LarkTimeFormatUtils

final class EventCustomRruleWeekdayPicker: UIControl {

    /// 每周的第一天
    var firstWeekDay: RRule.FirstWeekday = .monday {
        didSet {
            allWeekdays = Self.weekdays(for: firstWeekDay)
            gridView.reloadData()
        }
    }

    /// 必须勾选的
    var requiredWeekdays = Set<EKWeekday>() {
        didSet {
            gridView.reloadData()
            // check constraint
            guard requiredWeekdays.isDisjoint(with: unavailableWeekdays) else {
                assertionFailure("""
                    weekdays constraint.
                    requiredWeekdays: \(requiredWeekdays),
                    unavailableWeekdays: \(unavailableWeekdays)
                """)
                return
            }
        }
    }

    /// 不可取消的 item 被点击
    var onRequiredWeekdayClick: ((_ weekday: EKWeekday, _ weekdayString: String) -> Void)?

    /// 不可勾选的
    var unavailableWeekdays = Set<EKWeekday>() {
        didSet {
            gridView.reloadData()
            // check constraint
            guard innerWeekdays.isDisjoint(with: unavailableWeekdays),
                requiredWeekdays.isDisjoint(with: unavailableWeekdays) else {
                assertionFailure("""
                    weekdays constraint.
                    weekdays: \(innerWeekdays),
                    requiredWeekdays: \(requiredWeekdays),
                    unavailableWeekdays: \(unavailableWeekdays)
                """)
                return
            }
        }
    }

    /// 不可勾选的 item 被点击
    var onUnavailableWeekdayClick: ((_ weekday: EKWeekday, _ weekdayString: String) -> Void)?

    /// 当内部触发 weekdays 改变，触发 valueChanged 事件
    var weekdays: Set<EKWeekday> {
        get { innerWeekdays.union(requiredWeekdays).subtracting(unavailableWeekdays) }
        set {
            innerWeekdays = newValue
            gridView.reloadData()

            // check constraint
            guard newValue.isDisjoint(with: unavailableWeekdays) else {
                assertionFailure("""
                    weekdays constraint.
                    weekdays: \(newValue),
                    unavailableWeekdays: \(unavailableWeekdays)
                """)
                return
            }
        }
    }

    private var innerWeekdays = Set<EKWeekday>()
    private var allWeekdays: [EKWeekday]
    private let gridView = EventCustomRruleBaseGridView(numberOfRows: 3, numberOfColomn: 3)
    private let itemLabels: [UILabel]

    override init(frame: CGRect) {
        allWeekdays = Self.weekdays(for: firstWeekDay)

        let itemCount = allWeekdays.count + 2
        itemLabels = (0..<itemCount).map { _ in
            let label = UILabel()
            label.isUserInteractionEnabled = false
            label.font = UIFont.systemFont(ofSize: 16)
            label.textAlignment = .center
            return label
        }

        super.init(frame: frame)

        addSubview(gridView)
        gridView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        gridView.itemTitleLabelGetter = { [weak self] index in
            return self?.itemLabel(at: index)
        }
        gridView.itemSelectHandler = { [weak self] index in
            self?.handleItemSelect(at: index)
        }

        let border = UIView(frame: .zero)
        border.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(border)
        border.snp.makeConstraints { (make) in
            make.height.equalTo(1.5).priority(.low)
            make.left.equalToSuperview().priority(.low)
            make.right.equalToSuperview().priority(.low)
            make.top.equalToSuperview().priority(.low)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func itemLabel(at index: Int) -> UILabel? {
        guard index >= 0 && index < itemLabels.count else {
            assertionFailure()
            return nil
        }

        let label = itemLabels[index]
        let (text, isSelected): (String, Bool)
        if index < allWeekdays.count {
            // 周一 ... 周五、周六、周日
            let day = allWeekdays[index]
            text = Self.dayTitles[day] ?? ""
            isSelected = weekdays.contains(day)
        } else if index == allWeekdays.count {
            // 工作日
            text = Self.workdayTitle
            isSelected = Self.workdaySet.isSubset(of: weekdays)
        } else {
            // 周末
            text = Self.weekendTitle
            isSelected = Self.weekendSet.isSubset(of: weekdays)
        }
        label.text = text
        label.textColor = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textCaption

        return label
    }

    private func handleItemSelect(at index: Int) {
        guard index >= 0 && index < itemLabels.count else {
            assertionFailure()
            return
        }
        var valueChanged = false
        if index < allWeekdays.count {
            // 周一 ... 周五、周六、周日
            let day = allWeekdays[index]
            if weekdays.contains(day) {
                if requiredWeekdays.contains(day) {
                    onRequiredWeekdayClick?(day, Self.dayTitles[day] ?? "")
                } else {
                    valueChanged = true
                    innerWeekdays.remove(day)
                }
            } else {
                if unavailableWeekdays.contains(day) {
                    onUnavailableWeekdayClick?(day, Self.dayTitles[day] ?? "")
                } else {
                    valueChanged = true
                    innerWeekdays.insert(day)
                }
            }
        } else if index == allWeekdays.count {
            // 工作日
            if Self.workdaySet.isSubset(of: weekdays) {
                innerWeekdays.subtract(Self.workdaySet)
            } else {
                innerWeekdays = weekdays.union(Self.workdaySet)
            }
            valueChanged = true
        } else {
            // 周末
            if Self.weekendSet.isSubset(of: weekdays) {
                innerWeekdays.subtract(Self.weekendSet)
            } else {
                innerWeekdays = weekdays.union(Self.weekendSet)
            }
            valueChanged = true
        }
        gridView.reloadData()
        if valueChanged {
            sendActions(for: .valueChanged)
        }
    }

}

extension EventCustomRruleWeekdayPicker {

    fileprivate static func weekdays(for firstWeekday: RRule.FirstWeekday) -> [EKWeekday] {
        switch firstWeekday {
        case .saturday:
            return [
                .saturday, .sunday, .monday,
                .tuesday, .wednesday, .thursday,
                .friday
            ]
        case .sunday:
            return [
                .sunday, .monday, .tuesday,
                .wednesday, .thursday, .friday,
                .saturday
            ]
        case .monday:
            return [
                .monday, .tuesday, .wednesday,
                .thursday, .friday, .saturday,
                .sunday
            ]
        }
    }

    fileprivate static let dayTitles: [EKWeekday: String] = [
        .monday: TimeFormatUtils.weekdayFullString(weekday: 2),
        .tuesday: TimeFormatUtils.weekdayFullString(weekday: 3),
        .wednesday: TimeFormatUtils.weekdayFullString(weekday: 4),
        .thursday: TimeFormatUtils.weekdayFullString(weekday: 5),
        .friday: TimeFormatUtils.weekdayFullString(weekday: 6),
        .saturday: TimeFormatUtils.weekdayFullString(weekday: 7),
        .sunday: TimeFormatUtils.weekdayFullString(weekday: 1)
    ]

    fileprivate static var workdayTitle: String { BundleI18n.RRule.Calendar_RRule_Weekday }
    fileprivate static var weekendTitle: String { BundleI18n.RRule.Calendar_Edit_Weekend }
    fileprivate static let workdaySet = Set<EKWeekday>(
        [.monday, .tuesday, .wednesday, .thursday, .friday]
    )
    fileprivate static let weekendSet = Set<EKWeekday>(
        [.saturday, .sunday]
    )

}
