//
//  SearchDateFilterViewController.swift
//  Calendar
//
//  Created by sunxiaolei on 2019/8/13.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignDatePicker

final class SearchDateFilterViewController: BaseUIViewController, UIGestureRecognizerDelegate {

    /// 回调参数: vc本身，开始时间，结束时间
    var finishChooseBlock: ((SearchDateFilterViewController, Date?, Date?) -> Void)?

    private var startDate: Date?
    private var endDate: Date?

    private let contentView = UIView()
    private let naviBar = DateFilterNaviBar(style: .left)
    private let leftItemView = DateFilerItemView(style: .left)
    private let rightItemView = DateFilerItemView(style: .right)
    private let dateFilterOtherView: DateFilterOtherView
    private let datePickerView: UDDateCalendarPickerView

    init(startDate: Date?, endDate: Date?) {
        self.startDate = startDate
        self.endDate = endDate
        dateFilterOtherView = DateFilterOtherView(date: Date(), noLimitSelected: startDate == nil)

        let datePickerConfig = UDCalendarStyleConfig(rowNumFixed: true, autoSelectedDate: false)
        datePickerView = .init(date: startDate ?? Date(), calendarConfig: datePickerConfig)
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overCurrentContext
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgMask

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapDidInvoke))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        view.addSubview(contentView)
        contentView.clipsToBounds = true
        contentView.backgroundColor = UDDatePickerTheme.wheelPickerBackgroundColor
        contentView.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
        }

        layoutNaviZone()
        layoutLeftTimeItem()
        layoutRightTimeItem()
        layoutOtherView()
        layoutDatePickerView()

    }

    @objc
    private func backgroundTapDidInvoke() {
        dismiss(animated: false, completion: nil)
    }

    private func layoutNaviZone() {
        naviBar.delegate = self
        contentView.addSubview(naviBar)
        naviBar.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(64)
        }
    }

    private func layoutLeftTimeItem() {
        updateItemTime(item: leftItemView, date: startDate)
        leftItemView.set(selected: true)
        leftItemView.delegate = self
        contentView.addSubview(leftItemView)
        leftItemView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.height.equalTo(68)
            make.top.equalTo(naviBar.snp.bottom)
            make.width.equalToSuperview().multipliedBy(0.5).offset(20)
        }
    }

    private func layoutRightTimeItem() {
        updateItemTime(item: rightItemView, date: endDate)
        rightItemView.set(selected: false)
        rightItemView.delegate = self
        contentView.addSubview(rightItemView)
        rightItemView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.height.equalTo(68)
            make.top.equalTo(naviBar.snp.bottom)
            make.width.equalToSuperview().multipliedBy(0.5).offset(20)
        }
    }

    private func layoutOtherView() {
        contentView.addSubview(dateFilterOtherView)
        dateFilterOtherView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(60)
            make.top.equalTo(rightItemView.snp.bottom)
        }
        dateFilterOtherView.backClickCallback = { self.datePickerView.scrollToPrev(withAnimate: true) }
        dateFilterOtherView.forwardClickCallback = { self.datePickerView.scrollToNext(withAnimate: true) }
        dateFilterOtherView.noLimitClickCallback = { [weak self] isNolimit in
            guard let self = self else { return }
            if isNolimit { self.updateTime(item: self.leftItemView.selected ? .left : .right, with: nil) }
        }
    }

    private func layoutDatePickerView() {
        datePickerView.delegate = self
        contentView.addSubview(datePickerView)
        datePickerView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(dateFilterOtherView.snp.bottom)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
    }

    private func updateTime(item: DateFilerItemViewSyle, with date: Date?) {
        switch item {
        case .left:
            startDate = date
            updateItemTime(item: self.leftItemView, date: date)
        case .right:
            endDate = date
            updateItemTime(item: self.rightItemView, date: date)
        }
    }

    private func updateItemTime(item: DateFilerItemView, date: Date?) {
        if let date = date {
            item.set(title: "\(date.year)-\(date.month)-\(date.day)")
        } else {
            item.set(title: BundleI18n.Calendar.Lark_Search_AnyTime)
        }
    }

    private func switchNaviBar(to: DateFilerItemViewSyle) {
        switch to {
        case .left:
            naviBar.set(style: .left)
            leftItemView.set(selected: true)
            rightItemView.set(selected: false)
        case .right:
            naviBar.set(style: .right)
            leftItemView.set(selected: false)
            rightItemView.set(selected: true)
        }
    }

    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: view)
        if contentView.frame.contains(location) {
            return false
        } else {
            return true
        }
    }
}

extension SearchDateFilterViewController: DateFilterNaviBarDelegate {
    func naviBarDidClickCloseButton(_ naviBar: DateFilterNaviBar) {
        dismiss(animated: false, completion: nil)
    }

    func naviBarDidClickFinishButton(_ naviBar: DateFilterNaviBar) {
        startDate = startDate?.dayStart()
        endDate = endDate?.dayEnd()
        finishChooseBlock?(self, startDate, endDate)
        dismiss(animated: false, completion: nil)
    }
}

extension SearchDateFilterViewController: DateFilerItemViewDelegate {
    func itemViewDidClick(_ itemView: DateFilerItemView) {
        if !itemView.selected {
            if itemView === leftItemView {
                switchNaviBar(to: .left)
                if let startDate = startDate {
                    datePickerView.select(date: startDate)
                }
            } else if itemView === rightItemView {
                switchNaviBar(to: .right)
                if let endDate = endDate {
                    datePickerView.select(date: endDate)
                }
            }
        }
    }
}

extension SearchDateFilterViewController: UDDatePickerViewDelegate {
    func dateChanged(_ date: Date, _ sender: UDDateCalendarPickerView) {
        if leftItemView.selected {
            if let endDate = endDate, date > endDate {
                updateTime(item: .right, with: nil)
            }
        } else {
            if let startDate = startDate, date < startDate {
                updateTime(item: .left, with: nil)
            }
        }
        updateTime(item: leftItemView.selected ? .left : .right, with: date)
        dateFilterOtherView.updateDate(date: date)
        dateFilterOtherView.updateNolimit(noLimitSelected: false)
    }

    // 按钮-翻页
    func calendarScrolledTo(_ date: Date, _ sender: UDDateCalendarPickerView) {
        dateFilterOtherView.updateDate(date: date)
    }
}
