//
//  UDCalendarPickerView.swift
//  UniverseDesignDatePicker
//
//  Created by LiangHongbin on 2021/3/17.
//

import Foundation
import UIKit
import EventKit

protocol UDCalendarPickerViewDataSource: AnyObject {
    /// CalendarCell 配置
    /// - Parameters:
    ///   - calendar: 当前展示 UDCalendarPickerView
    ///   - index: calendar 对应下标，有实际语义，参照 UDCalendarPickerView 中映射关系表
    ///   - indexPath: cell 对应坐标
    ///   - cell: CalendarCell
    func calendar(_ calendar: UDCalendarPickerView, cellForItemAt index: CalendarIndex,
                  indexPath: IndexPath, cell: UICollectionViewCell) -> UDCalendarPickerCell

    /// 配置本页 cell 行数
    func calendar(_ calendar: UDCalendarPickerView, numberOfRowsInItem index: CalendarIndex) -> Int

    /// 配置本页是否为单行显示
    func configureIsSingleLine(_ calendar: UDCalendarPickerView) -> Bool
}

extension UDCalendarPickerViewDataSource {
    func configureIsSingleLine(_ calendar: UDCalendarPickerView) -> Bool {
        return false
    }
}

protocol UDCalendarPickerViewDelegate: AnyObject {
    func calendar(_ calendar: UDCalendarPickerView, willLoad calendarItem: UIView, at index: CalendarIndex)
    func calendar(_ calendar: UDCalendarPickerView, didLoad calendarItem: UIView, at index: CalendarIndex)
    func calendar(_ calendar: UDCalendarPickerView, willUnload calendarItem: UIView, at index: CalendarIndex)
    func calendar(_ calendar: UDCalendarPickerView, didUnload calendarItem: UIView, at index: CalendarIndex)
    func calendar(_ calendar: UDCalendarPickerView, beginFixingIndex index: CalendarIndex)

    func calendar(_ calendar: UDCalendarPickerView, didSelect cell: UDCalendarPickerCell,
                  index: CalendarIndex, indexPath: IndexPath)
}

extension UDCalendarPickerViewDelegate {
    func calendar(_ calendar: UDCalendarPickerView, willLoad calendarItem: UIView, at index: CalendarIndex) {}
    func calendar(_ calendar: UDCalendarPickerView, didLoad calendarItem: UIView, at index: CalendarIndex) {}
    func calendar(_ calendar: UDCalendarPickerView, willUnload calendarItem: UIView, at index: CalendarIndex) {}
    func calendar(_ calendar: UDCalendarPickerView, didUnload calendarItem: UIView, at index: CalendarIndex) {}
    func calendar(_ calendar: UDCalendarPickerView, beginFixingIndex index: CalendarIndex) {}

    func calendar(_ calendar: UDCalendarPickerView, didSelect cell: UDCalendarPickerCell,
                  index: CalendarIndex, indexPath: IndexPath) {}
}

typealias CalendarIndex = Int

class UDCalendarPickerView: UIView {
    // 月历基数：就是 pageIndex == 0 时所对应的月，这里取 1900/01（ 1582年 julian to Gregorian 存在 bug ）
    // pageIndex     | 0           | 1           |2           |
    // calendarIndex | 1900*12+1-1 | 1900*12+2-1 |1900*12+3-1 |
    // YYYY/MM       | 1900/01     | 1900/02     |1900/03     |
    static let baseMonthIndex = 1900 * 12
    // 星期基数：就是 pageIndex == 0 时所对应的星期，这里取 1900/01/01 日所在星期
    // base = JulianDayUtil.julianDay(fromYear: 1900, month: 1, day: 1) / 7
    // pageIndex     | 0           | 1           |2           |
    // calendarIndex | base        | base + 1    |base + 2    | julianDay / 7
    // YYYY/MM       | 7 days      | 7 days      |7 days      |
    static let baseWeekIndex = JulianDayUtil.julianDayFrom1900_01_01 / 7

    let weekdayTitle: CalendarWeekTitleView
    let container: PageView

    weak var delegate: UDCalendarPickerViewDelegate?
    weak var dataSource: UDCalendarPickerViewDataSource?
    let cellClass: AnyClass
    let cellHeight: CGFloat
    var calendarIndex: CalendarIndex?

    init(firstWeekday: EKWeekday,
         dayCellClass: AnyClass,
         dayCellHeight: CGFloat) {
        weekdayTitle = CalendarWeekTitleView(firstWeekday: firstWeekday)
        container = PageView(frame: .zero, totalPageCount: UDCalendarPickerView.baseMonthIndex * 2)
        cellClass = dayCellClass
        cellHeight = dayCellHeight
        super.init(frame: .zero)
        addSubview(weekdayTitle)
        weekdayTitle.snp.makeConstraints {
            $0.top.right.left.equalToSuperview()
            $0.height.equalTo(32)
        }
        container.delegate = self
        container.dataSource = self
        addSubview(container)
        container.snp.makeConstraints {
            $0.top.equalTo(weekdayTitle.snp.bottom)
            $0.height.equalTo(6 * (dayCellHeight + 8))
            $0.left.right.bottom.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        container.freezeStateIfNeeded()
        container.layoutIfNeeded()
        container.unfreezeStateIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func scroll(to calendarIndex: CalendarIndex, animate: Bool = true) {
        if self.calendarIndex == calendarIndex {
            container.reloadData()
            return
        }
        self.calendarIndex = calendarIndex
        guard let isSingleLine = dataSource?.configureIsSingleLine(self) else {
            assertionFailure("dataSource 为空")
            return
        }
        let pageIndex: PageIndex
        if isSingleLine {
            pageIndex = calendarIndex - UDCalendarPickerView.baseWeekIndex
        } else {
            pageIndex = calendarIndex - UDCalendarPickerView.baseMonthIndex
        }
        guard pageIndex >= 0, pageIndex < container.totalPageCount else {
            assertionFailure("calenderIndex invalid")
            return
        }
        container.scroll(to: pageIndex, animated: animate)
    }

    func scrollToPre(withAnimate: Bool = false) {
        guard let index = self.calendarIndex else {
            assertionFailure("calenderIndex nil")
            return
        }
        self.calendarIndex = index - 1
        container.scrollToPrev(animated: withAnimate)
    }

    func scrollToNext(withAnimate: Bool = false) {
        guard let index = self.calendarIndex else {
            assertionFailure("calenderIndex nil")
            return
        }
        self.calendarIndex = index + 1
        container.scrollToNext(animated: withAnimate)
    }

    func reload() {
        // 重新加载,用于 mode 变化
        container.reloadData()
    }

    // 很多地方用到，故单独拿出来
    private func convert(fromPageIndex index: PageIndex) -> CalendarIndex {
        guard let isSingleLine = dataSource?.configureIsSingleLine(self) else {
            assertionFailure("dataSource 为空")
            return -1
        }
        if isSingleLine {
            return UDCalendarPickerView.baseWeekIndex + index
        } else {
            return UDCalendarPickerView.baseMonthIndex + index
        }
    }
}
// MARK: dataSource & delegate PageView
extension UDCalendarPickerView: PageViewDataSource, PageViewDelegate {
    func itemView(at index: PageIndex, in pageView: PageView) -> UIView {
        let monthView = CalendarPickerItemView(dayCellHeight: cellHeight)
        monthView.delegate = self
        monthView.dataSource = self
        monthView.register(cellClass, forCellWithReuseIdentifier: cellClass.description())
        return monthView
    }

    func pageView(_ pageView: PageView, willLoad itemView: UIView, at index: PageIndex) {
        delegate?.calendar(self, willLoad: itemView, at: convert(fromPageIndex: index))
    }

    func pageView(_ pageView: PageView, didLoad itemView: UIView, at index: PageIndex) {
        delegate?.calendar(self, didLoad: itemView, at: convert(fromPageIndex: index))
    }

    func pageView(_ pageView: PageView, willUnload itemView: UIView, at index: PageIndex) {
        delegate?.calendar(self, willUnload: itemView, at: convert(fromPageIndex: index))
    }

    func pageView(_ pageView: PageView, didUnload itemView: UIView, at index: PageIndex) {
        delegate?.calendar(self, didUnload: itemView, at: index + convert(fromPageIndex: index))
    }

    func pageViewWillBeginFixingIndex(_ pageView: BasePageView, targetIndex: PageIndex, animated: Bool) {
        guard let item = container.itemView(at: targetIndex) as? CalendarPickerItemView else {
            assertionFailure("未取到 pageItem")
            return
        }
        let calendarIndex = convert(fromPageIndex: targetIndex)
        self.calendarIndex = calendarIndex
        delegate?.calendar(self, beginFixingIndex: calendarIndex)
        // 翻页停止后有概率需要重新刷新UI
        item.reloadData()
    }
}

// MARK: dataSource & delegate CollectionView
extension UDCalendarPickerView: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let index = container.index(of: collectionView),
              let sectionNum = dataSource?.calendar(self, numberOfRowsInItem: convert(fromPageIndex: index)) else {
            return 6
        }
        return sectionNum
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellClass.description(), for: indexPath)
        guard let pageIndex = container.index(of: collectionView),
              let configuredCell = dataSource?.calendar(self, cellForItemAt: convert(fromPageIndex: pageIndex),
                                                        indexPath: indexPath, cell: cell) else {
            assertionFailure("error: cell 未取到")
            return UDCalendarPickerCell()
        }
        return configuredCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let pageIndex = container.index(of: collectionView),
              let cell = collectionView.cellForItem(at: indexPath) as? UDCalendarPickerCell else {
            return
        }

        // 数据刷新
        delegate?.calendar(self, didSelect: cell, index: convert(fromPageIndex: pageIndex), indexPath: indexPath)
        // UI 刷新，全量刷新；如必要，可以精细化刷新
        collectionView.reloadData()
    }
}
