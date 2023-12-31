//
//  MonthView.swift
//  Calendar
//
//  Created by zhu chao on 2018/10/18.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkDatePickerView
import RxSwift
import RxCocoa
import LarkUIKit
import LKCommonsLogging

protocol MonthContainerViewDelegate: AnyObject {
    func containerView(view: MonthContainerView,
                       instancesFrom start: Date,
                       to end: Date) -> [MonthItem]

    func containerView(_ view: MonthContainerView,
                       didDidSelectAt item: MonthEventItem)

    /// 月份更新
    func containerView(_ view: MonthContainerView,
                       mothDateChangedTo date: Date)

    /// 选中时间更新
    func containerView(_ view: MonthContainerView,
                       selectedDateChangedTo date: Date)

    func containerViewCreateActionTaped(_ view: MonthContainerView)
}

final class MonthContainerView: UIView {
    static let logger = Logger.log(MonthContainerView.self, category: "MonthContainerView")
    private let scrollView: DaysViewInfiniteScrollView
    private let dataQueue: DispatchQueue
    private let disposeBag = DisposeBag()
    private let initDate: Date
    let firstWeekday: DaysOfWeek
    private let is12HourStyle: Bool
    private var onSizeChanging: Bool = false
    private var retryCount = 0
    weak var delegate: MonthContainerViewDelegate?
    override var frame: CGRect {
        didSet {
            if frame != oldValue && Display.pad && frame.size != .zero {
                self.onSizeChange(size: frame.size)
            }
        }
    }

    var currentDate: Date
    private let workItemQueue: WorkItemQueue
    private let alternateCalendar: AlternateCalendarEnum
    private let cachePageCount = 1
    private let localRefreshService: LocalRefreshService?
    private let calendarSelectTracer: CalendarSelectTracer?

    init(frame: CGRect,
         firstWeekday: DaysOfWeek,
         dataQueue: DispatchQueue,
         date: Date,
         is12HourStyle: Bool,
         localRefreshService: LocalRefreshService?,
         calendarSelectTracer: CalendarSelectTracer?,
         alternateCalendar: AlternateCalendarEnum) {
        self.initDate = date
        self.currentDate = date
        self.firstWeekday = firstWeekday
        self.is12HourStyle = is12HourStyle
        self.localRefreshService = localRefreshService
        self.calendarSelectTracer = calendarSelectTracer

        scrollView = DaysViewInfiniteScrollView(pageWidth: frame.width,
                                                cachePageCount: 0)
        workItemQueue = WorkItemQueue(maxCount: cachePageCount * 2 + 1)
        self.dataQueue = dataQueue
        self.alternateCalendar = alternateCalendar
        super.init(frame: frame)
        self.layoutScrollView(scrollView)
    }

    func onSizeChange(size: CGSize) {
        self.onSizeChanging = true
        let currentPage = self.scrollView.currentPage()
        self.scrollView.pageWidth = size.width
        self.scrollView.frame.size = size
        self.scrollView.contentSize = self.scrollView.defaultContentSize()

        self.scrollView.bounds.origin.x = self.scrollView.startOffset.x + CGFloat(currentPage) * self.scrollView.pageWidth
        self.scrollView.containerView.frame.size = CGSize(width: self.scrollView.contentSize.width, height: self.scrollView.bounds.height)

        self.scrollView.visibleViews.forEach { (view) in
            view.frame.origin.x = self.scrollView.startOffset.x + CGFloat(view.tag) * self.scrollView.pageWidth
            view.frame.size = size
            if let view = view as? MonthPageView {
                view.onSizeChange(size: size)
            }
        }
        self.scrollView.resetBuffers()
        self.onSizeChanging = false
    }

    private func layoutScrollView(_ view: DaysViewInfiniteScrollView) {
        view.frame = self.bounds
        self.addSubview(view)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.layoutIfNeeded()
        view.dataSource = self
        view.rx.didScroll
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .asObservable()
            .subscribe(onNext: { [weak self] () in
                guard let self = self, !self.onSizeChanging else { return }
                if self.scrollView.cachePageCount != self.cachePageCount {
                    self.scrollView.cachePageCount = self.cachePageCount
                }
                self.updateCurrentDateByScroll()
            })
            .disposed(by: disposeBag)
    }

    func reloadData() {
        self.scrollView.reloadData()
    }

    func scrollToToday() {
        self.scrollTo(date: Date())
    }
    
    /// 滚动到某天
    /// - Parameters:
    ///   - date: 当日期在 pageView 上，会进行expand状态切换
    ///   - scrollCompleted: 当日期不在 pageView 上，会自动关闭当前expand状态，并滚动到日期所在页，触发 scrollCompleted 回调
    func scrollTo(date: Date, _ scrollCompleted: ((MonthPageView?) -> Void)? = nil) {
        let currentPageIndex = self.scrollView.currentPage()
        guard let page = self.scrollView.visibleViews.first(where: { $0.tag == currentPageIndex }) as? MonthPageView else { return }
        if page.contains(date: date) {
            if let expandDate = page.expandedDate(), expandDate.isInSameDay(date) {
                page.shrinkWithUpdateSelectedDate()
                return
            }
            page.expand(at: date)
            return
        }

        let goExpand = { [unowned self] in
            let components = Calendar.gregorianCalendar.dateComponents([.weekOfYear, .month],
                                                             from: self.currentDate.startOfMonth(),
                                                             to: date.startOfMonth())
            let difference = components.month ?? 0
            var offset = self.scrollView.contentOffset
            offset.x += self.scrollView.bounds.width * CGFloat(difference)
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView.contentOffset = offset
            })
            
            let currentPageIndex = self.scrollView.currentPage()
            let page = self.scrollView.visibleViews.first(where: { $0.tag == currentPageIndex }) as? MonthPageView
            scrollCompleted?(page)
            
        }
        if page.isExpand() {
            page.shrinkWithUpdateSelectedDate(selectedRow: nil, animated: true) {
                goExpand()
            }
        } else {
            goExpand()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateCurrentDateByScroll() {
        var current = (initDate + self.scrollView.currentPage().month)!.startOfMonth()
        if current.isInSameMonth(self.currentDate) { return }
        if current > self.currentDate {
            CalendarTracer.shareInstance.calNavigation(actionSource: .defaultView,
                                                       navigationType: .next,
                                                       viewType: .month)
        } else {
            CalendarTracer.shareInstance.calNavigation(actionSource: .defaultView,
                                                       navigationType: .prev,
                                                       viewType: .month)
        }
        CalendarTracer.shared.calMainClick(type: .day_change)
        if current.isInSameMonth(Date()) {
            current = Date()
        }
        self.currentDate = current
        self.delegate?.containerView(self, mothDateChangedTo: current)
    }
}

extension MonthContainerView: MonthPageViewDelegate {
    func pageViewCreateActionTaped(_ view: MonthPageView) {
        self.delegate?.containerViewCreateActionTaped(self)
    }

    func pageView(_ view: MonthPageView, didSelect date: Date) {
        self.currentDate = date

        self.delegate?.containerView(self, selectedDateChangedTo: date)
        operationLog(message: "dateString: \(date.dateString(in: .short))",
                     optType: CalendarOperationType.monthClickTime.rawValue)
    }

    func pageView(_ view: MonthPageView, isDateSelected date: Date) -> Bool {
        return date.isInSameDay(self.currentDate)
    }

    func pageViewDidExpand(_ pageView: MonthPageView) {
        self.scrollView.isScrollEnabled = false
    }

    func pageViewDidShrink(_ pageView: MonthPageView) {
        self.scrollView.isScrollEnabled = true
    }

    func pageView(_ view: MonthPageView, didDidSelectAt item: MonthEventItem) {
        self.delegate?.containerView(self, didDidSelectAt: item)
    }
}

extension MonthContainerView: InfiniteScrollViewDelegate {
    func infiniteScrollView(scrollView: InfiniteScrollView, viewForIndex index: Int) -> UIView {
        let pageView = MonthPageView(frame: self.bounds,
                                     firstWeekday: firstWeekday,
                                     is12HourStyle: is12HourStyle,
                                     localRefreshService: localRefreshService,
                                     calendarSelectTracer: calendarSelectTracer,
                                     alternateCalendar: alternateCalendar)
        pageView.delegate = self
        return pageView
    }

    func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int) {
        guard let pageView = view as? MonthPageView else {
            assertionFailureLog()
            return
        }
        let pageDate = (self.initDate + index.months)!
        if let pageViewCurrentDate = pageView.updatedDate, !pageViewCurrentDate.isInSameMonth(pageDate) {
            pageView.clearEventLabels()
        }
        let range = pageView.update(date: pageDate)
        let pageTag = pageView.tag
        operationLog(message: "new downLoadTask index: \(pageTag)")
        let workItem = DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            operationLog(message: "execute downLoadTask index: \(pageTag)")
            let events = self.delegate?.containerView(view: self,
                                                      instancesFrom: range.pageStartDate,
                                                      to: range.pageEndDate)
            DispatchQueue.main.async {
                if TimerMonitorHelper.shared.getFirstScreenInstancesLength() != -1 {
                    TimerMonitorHelper.shared.launchTimeTracer?.renderInstance.start()
                    TimerMonitorHelper.shared.launchTimeTracer?.instanceRenderGap.end()
                }
                // 依靠 tag 作为唯一标识，绑定view & data，tag 不匹配时未刷新数据导致异常，暂时没找到根源问题
                // 只能 reload 兜底 + 日志
                if view.tag != pageTag {
                    MonthContainerView.logger.error("monthPageTag not match \(view.tag) != \(pageTag)")
                    // 为了防止死循环，最多只重试5次
                    if self.retryCount <= 5 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                            self.reloadData()
                            self.retryCount += 1
                        }
                    }
                    return
                }
                operationLog(message: "execute refresh index: \(pageTag)")
                pageView.events = events ?? []
                if TimerMonitorHelper.shared.getFirstScreenInstancesLength() == 0 {
                    CalendarMonitorUtil.endTrackHomePageLoad()
                }
            }
        }

        if !CalendarMonitorUtil.hadTrackPerfCalLaunch {
            DispatchQueue.main.async(execute: workItem)
        } else {
            self.workItemQueue.add((workItem, index))
            dataQueue.async(execute: workItem)

            let removeworkItem = DispatchWorkItem { [weak self] in
                self?.workItemQueue.remove(workItem)
            }
            dataQueue.async(execute: removeworkItem)
        }
    }
}
