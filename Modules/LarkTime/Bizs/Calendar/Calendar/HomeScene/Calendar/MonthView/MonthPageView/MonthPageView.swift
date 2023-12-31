//
//  MonthPageView.swift
//  Calendar
//
//  Created by zhu chao on 2018/10/17.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkUIKit

protocol MonthPageViewDelegate: AnyObject {
    func pageViewDidExpand(_ pageView: MonthPageView)
    func pageViewDidShrink(_ pageView: MonthPageView)
    func pageView(_ view: MonthPageView, didDidSelectAt item: MonthEventItem)
    func pageView(_ view: MonthPageView, isDateSelected date: Date) -> Bool
    func pageView(_ view: MonthPageView, didSelect date: Date)
    func pageViewCreateActionTaped(_ view: MonthPageView)
}

final class MonthPageView: UIView {
    private let daysPerWeek: Int = 7
    private let is12HourStyle: Bool

    private lazy var weekHeader: MonthWeekHeader = {
        let headerFrame = CGRect(x: 0,
                                 y: 0,
                                 width: frame.width,
                                 height: 23)
        return MonthWeekHeader(frame: headerFrame, firstWeekday: firstWeekday, isAlternateCalOpen: isAlternateCalOpen)
    }()

    private let rows: [MonthRowView]
    private let firstWeekday: DaysOfWeek
    weak var delegate: MonthPageViewDelegate?

    private var monthStart: Date = Date()

    private let alternateCalendar: AlternateCalendarEnum
    private let isAlternateCalOpen: Bool
    let localRefreshService: LocalRefreshService?

    init(frame: CGRect,
         firstWeekday: DaysOfWeek,
         is12HourStyle: Bool,
         localRefreshService: LocalRefreshService?,
         calendarSelectTracer: CalendarSelectTracer?,
         alternateCalendar: AlternateCalendarEnum) {
        self.firstWeekday = firstWeekday
        self.is12HourStyle = is12HourStyle
        self.localRefreshService = localRefreshService
        self.alternateCalendar = alternateCalendar
        self.isAlternateCalOpen = alternateCalendar != .noneCalendar
        self.rows = {
            var arr = [MonthRowView]()
            (0..<6).forEach({ (i) in
                let row = MonthRowView(alternateCalendar: alternateCalendar,
                                       calendarSelectTracer: calendarSelectTracer,
                                       width: frame.width)
                row.tag = i
                arr.append(row)
            })
            return arr
        }()
        super.init(frame: frame)
        self.layoutWeekHeader(weekHeader)
        rows.forEach({ $0.delegate = self })
    }

    func onSizeChange(size: CGSize) {
        guard Display.pad else { return }
        self.frame.size = size
        self.weekHeader.onWidthChange(width: size.width)
        if let date = self.updatedDate {
            let monthStart = date.startOfMonth()
            let monthEnd = date.endOfMonth()
            let rowNumber = self.rowNumber(startWeekDay: monthStart.weekday, monthEnd: monthEnd)
            self.layoutRows(rowNumber: rowNumber)
            self.updateRows(with: events, is12HourStyle: is12HourStyle)
        }
    }

    var events: [MonthItem] = [] {
        didSet {
            self.updateRows(with: events, is12HourStyle: is12HourStyle)
        }
    }

    private lazy var listView: MonthInnerListView = {
        let view = MonthInnerListView(frame: self.bounds)
        view.localRefreshService = self.localRefreshService
        self.insertSubview(view, at: 0)
        view.delegate = self
        view.isHidden = true
        return view
    }()

    private func updateRows(with events: [MonthItem], is12HourStyle: Bool) {
        let rowNum = self.currentRowNumber()
        for i in 0..<rowNum {
            let row = self.rows[i]
            let dateRange = row.dateRanges()
            let rowEvents = events.filter({ $0.isBelongsTo(startTime: dateRange.startTime, endTime: dateRange.endTime) })
            row.tag = i
            row.setBlocks(rowEvents)
        }
        // 如果展开状态
        if !self.isExpand() { return }
        guard let currentRow = self.selectedRow(), let index = currentRow.currentSelectedIndex() else { return }
        self.listView.updateBlocks(currentRow.events, index: index, dates: currentRow.dates(), is12HourStyle: is12HourStyle)
    }

    private func layoutWeekHeader(_ header: MonthWeekHeader) {
        header.autoresizingMask = [.flexibleWidth]
        self.addSubview(header)
        header.addBottomBorder()
    }

    func contains(date: Date) -> Bool {
        return self.currentRows().contains(where: { (row) -> Bool in
            return row.dates().contains(where: { $0.isInSameDay(date) })
        })
    }

    func expand(at date: Date) {
        let rows = self.currentRows()
        if let row = rows.first(where: { (row) -> Bool in
            let dates = row.dates()
            return dates.contains(where: { $0.isInSameDay(date) })
        }) {
            let dates = row.dates()
            if let index = row.dates().firstIndex(where: { $0.isInSameDay(date) }) {
                row.setSelectedIndex(index)
                self.rowView(row, didSelectedAt: dates[index], index: index)
            }
        }
    }

    func expandedDate() -> Date? {
        guard self.isExpand() else { return nil }
        guard let row = self.rows.first(where: { $0.isSelected }) else { return nil }
        return row.selectedDate()
    }

    var updatedDate: Date?

    func update(date: Date) -> (pageStartDate: Date, pageEndDate: Date) {
        let pageMaker = MonthPageMaker(firstWeekday: firstWeekday.rawValue)
        let pageData = pageMaker.getPageData(date: date)
        if updatedDate == date {
            return (pageData.start, pageData.end)
        }
        self.updatedDate = date

        let current = Date()
        let containsToday = current >= pageData.monthStart && current <= pageData.monthEnd
        self.weekHeader.update(isShowToday: containsToday)
        if self.rowHeight(with: pageData.rowNumber) != self.rows[0].bounds.height {
            self.layoutRows(rowNumber: pageData.rowNumber)
        }

        let displayElementList: [LunarComponents]
        displayElementList = AlternateCalendarUtil.getDisplayElementList(date: pageData.start,
                                                                         appendCount: pageData.rowNumber * daysPerWeek,
                                                                         type: alternateCalendar)

        for i in 0..<pageData.rowNumber * daysPerWeek {
            let date = (pageData.start + i.days)!

            var alternateCalText: String = ""

            if displayElementList.count > i {
                var displayElement = displayElementList[safeIndex: i]
                displayElement?.solarTerm = AlternateCalendarUtil.getSolarTerm(date: date)
                alternateCalText = displayElement?.get() ?? ""
            }

            let isGray = date < pageData.monthStart || date > pageData.monthEnd
            let isToday = date.isInSameDay(current)
            var isSelected = false
            let label = self.dateLabel(at: i)
            if self.isExpand() {
                isSelected = label.isSelected
            }
            let fourceShowTodayBg = !self.isExpand() && (date >= pageData.monthStart && date <= pageData.monthEnd)
            label.setDate(date,
                          isGray: isGray,
                          isToday: isToday,
                          isSelected: isSelected,
                          fourceShowTodayBg: fourceShowTodayBg,
                          alternateCalendarText: alternateCalText)
        }
        self.monthStart = pageData.monthStart
        return (pageData.start, pageData.end)
    }

    func clearEventLabels() {
        self.rows.forEach({ $0.clearEventLabels() })
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let rowNumber = self.currentRowNumber()
        if self.rowHeight(with: rowNumber) != self.rows[0].bounds.height {
            self.layoutRows(rowNumber: rowNumber)
        }
    }

    private func rowHeight(with rowNumber: Int) -> CGFloat {
        return (self.frame.height - weekHeader.bounds.height) / CGFloat(rowNumber)
    }

    private func selectedRow() -> MonthRowView? {
        return self.rows.first(where: { $0.isSelected })
    }

    private func rowNumber(startWeekDay: Int, monthEnd: Date) -> Int {
        let totalDays = startWeekDay - 1 + monthEnd.day
        return totalDays / daysPerWeek + 1
    }

    private func dateLabel(at index: Int) -> RowHeaderLabel {
        let labels = self.rows[index / daysPerWeek].dateLabels
        return labels[index % daysPerWeek]
    }

    private func currentRowNumber() -> Int {
        let number = currentRows().count
        return number
    }

    func isExpand() -> Bool {
        return !self.rows[1].transform.isIdentity
    }

    private func currentRows() -> [MonthRowView] {
        return self.rows.filter({ $0.superview != nil })
    }

    private func layoutRows(rowNumber: Int) {
        self.shrink(animated: false)
        let rowFrame = CGRect(x: 0,
                              y: 0,
                              width: self.frame.width,
                              height: (self.frame.height - weekHeader.bounds.height) / CGFloat(rowNumber))
        for i in 0..<self.rows.count {
            let row = self.rows[i]
            if i < rowNumber {
                var frame = rowFrame
                frame.origin.y = CGFloat(i) * rowFrame.height + weekHeader.bounds.height
                row.frame = frame
                if row.superview !== self {
                    self.addSubview(row)
                }
            } else {
                row.removeFromSuperview()
            }
        }
        self.bringSubviewToFront(weekHeader)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func expand(by view: MonthRowView) -> CGRect {
        guard !self.isExpand() else {
            assertionFailureLog()
            return .zero
        }
        self.delegate?.pageViewDidExpand(self)
        view.isSelected = true
        let currentRows = self.currentRows()
        let selectedIndex = view.tag
        let upperViews = Array(currentRows.prefix(selectedIndex + 1))
        var lowerViews: [MonthRowView] = []
        if selectedIndex + 1 < self.currentRowNumber() {
            lowerViews = Array(currentRows.suffix(from: selectedIndex + 1))
        }
        UIView.animate(withDuration: 0.3) {
            let upperY = -(view.frame.minY - self.weekHeader.frame.height)
            upperViews.forEach({ (rowView) in
                rowView.transform = CGAffineTransform(translationX: 0, y: upperY)
            })
            guard let firstLowerView = lowerViews.first else { return }
            let lowerY = self.frame.height - firstLowerView.frame.origin.y - firstLowerView.frame.height
            lowerViews.forEach({ (rowView) in
                rowView.transform = CGAffineTransform(translationX: 0, y: lowerY)
            })
        }

        let resultY = self.weekHeader.bounds.height + view.bounds.height
        var resultBottomMargin: CGFloat = 0.0
        if let firestLowerRow = lowerViews.first {
            resultBottomMargin = firestLowerRow.bounds.height
        }
        return CGRect(x: 0,
                      y: resultY,
                      width: self.bounds.width,
                      height: self.bounds.height - resultY - resultBottomMargin)
    }

    func shrink(selectedRow: MonthRowView? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        self.delegate?.pageViewDidShrink(self)
        let action = {
            // 单独置成 .identity 是因为判断展开非展开根据transform来判断
            self.rows.forEach({ $0.transform = .identity })
            self.rows.forEach({ (row) in
                if row !== selectedRow {
                    row.isSelected = false
                }
            })
        }
        if animated {
            UIView.animate(withDuration: 0.3, animations: action) { (_) in
                completion?()
            }
            return
        }
        action()
        completion?()
    }

    func shrinkWithUpdateSelectedDate(selectedRow: MonthRowView? = nil,
                                      animated: Bool = true,
                                      completion: (() -> Void)? = nil) {
        self.shrink(selectedRow: selectedRow, animated: animated) { [weak self] in
            guard let `self` = self else { return }
            if self.contains(date: Date()) {
                self.delegate?.pageView(self, didSelect: Date())
            }
            completion?()
        }
    }
}

extension MonthPageView: MonthRowViewDelgate, MonthInnerListViewDelegate {
    func rowViewIsTodayInCurrentMonth(_ view: MonthRowView) -> Bool {
        let today = Date()
        return today >= self.monthStart && today <= self.monthStart.endOfMonth()
    }

    func rowViewIsPageExpand(_ view: MonthRowView) -> Bool {
        return self.isExpand()
    }

    func innerListViewCreateActionTaped(_ view: MonthInnerListView) {
        self.delegate?.pageViewCreateActionTaped(self)
    }

    func innerListView(_ view: MonthInnerListView, didDidSelectAt item: MonthEventItem) {
        self.delegate?.pageView(self, didDidSelectAt: item)
    }

    func rowView(_ view: MonthRowView, didSelectedAt date: Date, index: Int) {
        self.delegate?.pageView(self, didSelect: date)
        if !self.isExpand() {
            let expandSpace = self.expand(by: view)
            self.listView.isHidden = false
            self.listView.frame = expandSpace
            let events = view.events
            self.listView.updateBlocks(events, index: index, dates: view.dates(), is12HourStyle: is12HourStyle)
            return
        }

        // 页面已经展开的情况
        if view.isSelected {
            self.listView.scroll(to: index, animated: true)
        } else {
            self.shrinkWithUpdateSelectedDate(selectedRow: view, animated: true) { [weak self] in
                self?.rowView(view, didSelectedAt: date, index: index)
            }
        }
    }

    func rowView(_ view: MonthRowView, setNeedsShrinkAt date: Date, index: Int) {
        self.shrinkWithUpdateSelectedDate(animated: true) { [weak self] in
            self?.listView.isHidden = true
        }
    }

    func innerListView(_ view: MonthInnerListView, didScrollTo index: Int) {
        guard let selectedRow = self.rows.first(where: { $0.isSelected }) else { return }
        selectedRow.setSelectedIndex(index)
        self.delegate?.pageView(self, didSelect: selectedRow.dates()[index])
    }
}
