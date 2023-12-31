//
//  EventCustomRruleMonthDayPicker.swift
//  Calendar
//
//  Created by 张威 on 2020/4/16.
//

import UIKit
import Foundation

final class EventCustomRruleMonthDayPicker: UIControl {

    /// 是否允许多选
    var allowsMultiSelection = true {
        didSet {
            gridView.reloadData()
        }
    }

    /// 当内部触发 monthDays 改变，触发 valueChanged 事件
    var monthDays: Set<Int> {
        get {
            return innerMonthDays.union(requiredDays)
        }
        set {
            innerMonthDays = newValue
            gridView.reloadData()
        }
    }

    /// 必须勾选的
    var requiredDays = Set<Int>() {
        didSet {
            gridView.reloadData()
        }
    }

    /// 不可取消的 item 被点击
    var onRequiredDayClick: ((Int) -> Void)?
    /// 不可勾选的 item 被点击
    var onUnavailableDayClick: ((Int) -> Void)?

    private var innerMonthDays = Set<Int>()
    private let allMonthDays = Array(1...31)
    private let gridView = EventCustomRruleBaseGridView(numberOfRows: 5, numberOfColomn: 7)
    private let itemLabels: [UILabel]

    override init(frame: CGRect) {

        itemLabels = allMonthDays.map { day in
            let label = UILabel()
            label.text = String(day)
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
        guard index >= 0 && index < itemLabels.count else { return nil }

        let label = itemLabels[index]
        let isSelected = monthDays.contains(allMonthDays[index])
        label.textColor = isSelected ? UIColor.ud.primaryContentDefault : UIColor.ud.textCaption
        return label
    }

    private func handleItemSelect(at index: Int) {
        guard index >= 0 && index < itemLabels.count else {
            assertionFailure()
            return
        }

        var valueChanged = false
        let day = allMonthDays[index]
        if monthDays.contains(day) {
            if requiredDays.contains(day) {
                onRequiredDayClick?(day)
            } else {
                valueChanged = true
                monthDays.remove(day)
            }
        } else {
            if !requiredDays.isEmpty && !allowsMultiSelection {
                onUnavailableDayClick?(day)
            } else {
                valueChanged = true
                monthDays.insert(day)
            }
        }

        gridView.reloadData()
        if valueChanged {
            sendActions(for: .valueChanged)
        }
    }

}
