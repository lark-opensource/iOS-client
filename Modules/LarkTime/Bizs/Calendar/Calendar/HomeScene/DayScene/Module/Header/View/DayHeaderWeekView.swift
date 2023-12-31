//
//  DayHeaderWeekView.swift
//  Calendar
//
//  Created by 张威 on 2020/7/29.
//

import UIKit
import Foundation
import UniverseDesignFont

/// DayScene - Header - WeekItemView
/// 每一天对应一个 `DayHeaderWeekItemView`，每一周对应一个 `DayHeaderWeekView`

protocol DayHeaderWeekItemDataType {
    var weekText: String { get }
    var dayText: String { get }
    var alternateDayText: String? { get }
    var status: JulianDayStatus { get }
}

protocol DayHeaderWeekViewDataType {
    var items: [DayHeaderWeekItemDataType] { get }
    var pageIndex: PageIndex { get }
    var activeIndex: Int? { get }
}

final class DayHeaderWeekView: UIView, ViewDataConvertible {
    var onItemClick: ((_ pageIndex: Int, _ itemIndex: Int) -> Void)?

    var viewData: DayHeaderWeekViewDataType? {
        didSet {
            guard let viewData = viewData else {
                isHidden = true
                return
            }
            if let oldViewData = oldValue, isEqual(oldViewData, viewData) {
                return
            }
            isHidden = false
            for i in 0..<min(viewData.items.count, itemViews.count) {
                itemViews[i].viewData = viewData.items[i]
                itemViews[i].isActive = viewData.activeIndex == i
            }
        }
    }

    private let itemViews: [DayHeaderWeekItemView]

    override init(frame: CGRect) {
        itemViews = (0..<7).map { _ in DayHeaderWeekItemView() }
        super.init(frame: frame)
        for i in 0..<itemViews.count {
            addSubview(itemViews[i])
            itemViews[i].onClick = { [weak self] in
                guard let self = self,
                      let pageIndex = self.viewData?.pageIndex else { return }
                self.onItemClick?(pageIndex, i)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let itemWidth = floor(bounds.width / CGFloat(itemViews.count))
        for i in 0..<itemViews.count {
            itemViews[i].frame = CGRect(x: itemWidth * CGFloat(i), y: 0, width: itemWidth, height: bounds.height)
        }
    }

    private func isEqual(_ data1: DayHeaderWeekViewDataType, _ data2: DayHeaderWeekViewDataType) -> Bool {
        guard data1.activeIndex == data2.activeIndex,
              data1.items.count == data2.items.count else {
            return false
        }
        for i in 0..<data1.items.count {
            if !isEqual(data1.items[i], data2.items[i]) {
                return false
            }
        }
        return true
    }

    private func isEqual(_ item1: DayHeaderWeekItemDataType, _ item2: DayHeaderWeekItemDataType) -> Bool {
        return item1.weekText == item2.weekText
               && item1.dayText == item2.dayText
               && item1.alternateDayText == item2.alternateDayText
               && item1.status == item2.status
    }

}

// ref: OneDayHeaderCell
final class DayHeaderWeekItemView: UIView, ViewDataConvertible {

    var viewData: DayHeaderWeekItemDataType? {
        didSet {
            guard let viewData = viewData else { return }

            weekLabel.text = viewData.weekText
            dayLabel.text = viewData.dayText
            alternateDayLabel.text = viewData.alternateDayText

            updateColors()
            setNeedsLayout()
        }
    }

    var isActive: Bool = false {
        didSet {
            activeRoundView.isHidden = !isActive
            updateColors()
        }
    }

    var onClick: (() -> Void)?

    private let weekLabel = UILabel()
    private let dayLabel = UILabel()
    private let alternateDayLabel = UILabel()
    private let activeRoundView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handClick)))

        activeRoundView.layer.cornerRadius = 16
        activeRoundView.isHidden = true
        activeRoundView.layer.allowsEdgeAntialiasing = true
        addSubview(activeRoundView)

        weekLabel.textAlignment = .center
        weekLabel.font = UIFont.cd.font(ofSize: 12)
        addSubview(weekLabel)

        dayLabel.textAlignment = .center
        if UDFontAppearance.isCustomFont {
            dayLabel.font = UIFont.cd.mediumFont(ofSize: 16)
        } else {
            dayLabel.font = UDFont.dinBoldFont(ofSize: 18)
        }
        addSubview(dayLabel)

        alternateDayLabel.textAlignment = .center
        alternateDayLabel.font = UIFont.cd.font(ofSize: 11)
        addSubview(alternateDayLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        weekLabel.frame = CGRect(x: 8, y: 4, width: bounds.width - 16, height: 16)
        dayLabel.frame = CGRect(x: 8, y: weekLabel.frame.bottom + 8, width: bounds.width - 16, height: 21)

        var roundFrame = CGRect(origin: .zero, size: CGSize(width: 32, height: 32))
        roundFrame.center = dayLabel.frame.center
        activeRoundView.frame = roundFrame

        if !(alternateDayLabel.text?.isEmpty ?? true) {
            alternateDayLabel.frame = CGRect(x: 3, y: dayLabel.frame.bottom + 8, width: bounds.width - 6, height: 15)
        }
    }

    private func updateColors() {
        guard let status = viewData?.status else { return }
        let (weekColor, dayColor, alternateColor): (UIColor, UIColor, UIColor)
        var roundColor = UIColor.ud.N300
        switch status {
        case .past:
            (weekColor, alternateColor) = (UIColor.ud.textPlaceholder, UIColor.ud.textPlaceholder)
            dayColor = UIColor.ud.textPlaceholder
        case .today:
            (weekColor, alternateColor) = (UIColor.ud.primaryContentDefault, UIColor.ud.primaryContentDefault)
            dayColor = isActive ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.primaryContentDefault
            roundColor = UIColor.ud.primaryFillDefault
        case .future:
            (weekColor, alternateColor) = (UIColor.ud.textTitle, UIColor.ud.textCaption)
            dayColor = UIColor.ud.textTitle
        }
        weekLabel.textColor = weekColor
        dayLabel.textColor = dayColor
        alternateDayLabel.textColor = alternateColor
        activeRoundView.backgroundColor = roundColor
    }

    @objc
    private func handClick() {
        onClick?()
    }

}
