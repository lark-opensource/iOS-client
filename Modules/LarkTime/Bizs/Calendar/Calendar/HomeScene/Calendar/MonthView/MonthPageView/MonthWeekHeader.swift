//
//  MonthWeekHeader.swift
//  Calendar
//
//  Created by zhu chao on 2018/10/17.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import LarkTimeFormatUtils

final class MonthWeekHeader: UIView {
    private let containerView: MonthViewRowContainer<MonthWeekHeaderItem>
    init(frame: CGRect, firstWeekday: DaysOfWeek, isAlternateCalOpen: Bool) {
        var items = [MonthWeekHeaderItem]()
        (0..<7).forEach { (index) in
            let (weekString, weekday) = MonthWeekHeader.weekInfo(index: index,
                                                             firstWeekday: firstWeekday)
            items.append(MonthWeekHeaderItem(text: weekString, weekday: weekday, isAlternateCalOpen: isAlternateCalOpen))
        }
        containerView = MonthViewRowContainer<MonthWeekHeaderItem>(
            subViews: items,
            edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
        )
        super.init(frame: frame)
        self.addSubview(containerView)
        containerView.frame = self.bounds.insetBy(dx: 16, dy: 0)
        self.backgroundColor = UIColor.ud.bgBody
    }

    func onWidthChange(width: CGFloat) {
        self.frame.size.width = width
        self.containerView.onWidthChange(width: width - 16 * 2)
    }

    static private func weekInfo(index: Int, firstWeekday: DaysOfWeek) -> (String, Int) {
        let weekday = (index + firstWeekday.rawValue - 1) % 7 + 1
        let string = TimeFormatUtils.weekdayAbbrString(weekday: weekday)
        return (string, weekday)
    }

    func update(isShowToday: Bool) {
        let weekday = Date().weekday
        for i in 0..<7 {
            let item = containerView.view(at: i)
            if isShowToday {
                item.isSelected = item.weekday == weekday
            } else {
                item.isSelected = false
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class MonthWeekHeaderItem: UIView {
    private let label = UILabel()
    let weekday: Int
    init(text: String, weekday: Int, isAlternateCalOpen: Bool) {
        self.weekday = weekday
        super.init(frame: .zero)
        label.text = text
        label.font = UIFont.cd.regularFont(ofSize: 12)
        label.textColor = UIColor.ud.N800
        label.frame = CGRect(x: -4, y: 3.5, width: 26, height: 18)
        label.textAlignment = .center
        self.addSubview(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isSelected: Bool = false {
        didSet {
            self.label.textColor = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.N800
        }
    }
}
