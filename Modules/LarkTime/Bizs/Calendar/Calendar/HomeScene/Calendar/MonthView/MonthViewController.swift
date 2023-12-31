//
//  MonthViewController.swift
//  Calendar
//
//  Created by zhu chao on 2018/10/17.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import RxCocoa

enum MonthDataType: String {
    case event
    case timeBlock
}

protocol MonthItem {
    var type: MonthDataType { get }
    var title: String { get }
    var sortKey: String { get }
    var startDate: Date { get }
    var endDate: Date { get }
    var startDay: Int32 { get }
    var endDay: Int32 { get }
    var startTime: Int64 { get }
    var endTime: Int64 { get }
    var isAllDay: Bool { get }

    func isBelongsTo(startTime: Date, endTime: Date) -> Bool
}

enum MonthBlockDataEntityType {
    case event(MonthEvent)
    case timeBlock(MonthTimeBlock)
    case none
}

extension MonthItem {
    @discardableResult
    func process<R>(_ task: (MonthBlockDataEntityType) -> R) -> R {
        if let monthEvent = self as? MonthEvent {
            task(.event(monthEvent))
        } else if let monthTimeBlock = self as? MonthTimeBlock {
            task(.timeBlock(monthTimeBlock))
        } else {
            task(.none)
        }
    }
}

struct MonthTimeBlock: MonthItem {
    var title: String { timeBlock.title }
    var sortKey: String { timeBlock.id }
    var type: MonthDataType { .timeBlock }

    let timeBlock: TimeBlockModel
    let eventViewSetting: EventViewSetting
    var startDate: Date
    var endDate: Date
    var startDay: Int32 { timeBlock.startDay }
    var endDay: Int32 { timeBlock.endDay }
    var startTime: Int64 { timeBlock.startTime }
    var endTime: Int64 { timeBlock.endTime }
    var isAllDay: Bool { timeBlock.isAllDay }

    init(timeBlock: TimeBlockModel,
         eventViewSetting: EventViewSetting) {
        self.timeBlock = timeBlock
        self.eventViewSetting = eventViewSetting
        self.startDate = Date(timeIntervalSince1970: TimeInterval(timeBlock.startTime))
        self.endDate = Date(timeIntervalSince1970: TimeInterval(timeBlock.endTime))
    }

    func isBelongsTo(startTime: Date, endTime: Date) -> Bool {
        let startDate = timeBlock.startDate
        let endDate = timeBlock.endDate
        if startDate >= startTime, startDate < endTime {
            return true
        }

        if endDate > startTime, endDate <= endTime {
            return true
        }
        return (startDate < startTime) && (endDate > endTime)
    }
}

struct MonthEvent: MonthItem {
    var title: String { instance.title }
    var sortKey: String
    var type: MonthDataType { .event }

    var startDate: Date
    var endDate: Date
    var startDay: Int32 { instance.startDay }
    var endDay: Int32 { instance.endDay }
    var startTime: Int64 { instance.startTime }
    var endTime: Int64 { instance.endTime }
    let instance: CalendarEventInstanceEntity
    let calendar: CalendarModel?
    let eventViewSetting: EventViewSetting
    var isAllDay: Bool { instance.isAllDay }

    init(instance: CalendarEventInstanceEntity,
         calendar: CalendarModel?,
         eventViewSetting: EventViewSetting) {
        self.instance = instance
        self.sortKey = instance.uniqueId
        self.eventViewSetting = eventViewSetting
        self.calendar = calendar
        self.startDate = Date(timeIntervalSince1970: TimeInterval(instance.startTime))
        self.endDate = Date(timeIntervalSince1970: TimeInterval(instance.endTime))
    }

    func isBelongsTo(startTime: Date, endTime: Date) -> Bool {
        instance.isBelongsTo(startTime: startTime, endTime: endTime)
    }
}

public final class MonthViewController: UIViewController, EventViewController {
    func reloadData(with date: Date) {
        self.monthView.reloadData()
    }

    func currentPageDate() -> Date {
        return self.date
    }

    func getCurrentSelectDate() -> Date {
        return self.date
    }

    func scrollToRedLine(animated: Bool) {
        if animated {
            self.scrollToToday()
        }
    }

    func dayViewContentOffset() -> CGPoint? {
        return nil
    }

    var controller: UIViewController {
        return self
    }
    var tabBarDirection: EventViewController.ScrollDriction {
        return .horizontal
    }
    private var localRefreshService: LocalRefreshService?
    private let disposeBag = DisposeBag()
    private let monthView: MonthContainerView
    private let dataLoader: MonthLoader
    private let workQueue: DispatchQueue
    weak var delegate: EventViewControllerDelegate?

    private var date: Date {
        didSet {
            let days = daysBetween(date1: Date.today(), date2: date)
            self.delegate?.eventViewController(self, pagingProgress: CGFloat(days), isJump: true)
        }
    }

    deinit {
        print("xxx deinit MonthViewController")
    }

    init(date: Date,
         dataLoader: MonthLoader,
         workQueue: DispatchQueue,
         firstWeekday: DaysOfWeek,
         is12HourStyle: Bool,
         localRefreshService: LocalRefreshService?,
         calendarSelectTracer: CalendarSelectTracer?,
         alternateCalendar: AlternateCalendarEnum) {
        self.date = date
        self.dataLoader = dataLoader
        self.workQueue = workQueue
        let monthView = MonthContainerView(frame: UIScreen.main.bounds,
                                           firstWeekday: firstWeekday,
                                           dataQueue: workQueue,
                                           date: date,
                                           is12HourStyle: is12HourStyle,
                                           localRefreshService: localRefreshService,
                                           calendarSelectTracer: calendarSelectTracer,
                                           alternateCalendar: alternateCalendar)
        self.monthView = monthView
        super.init(nibName: nil, bundle: nil)
        addPushListener(subject: self.dataLoader.loaderUpdateSucess)
    }

    public func scrollToToday() {
        self.monthView.scrollToToday()
    }
    
    /// 滚动到 Date，并展开 Date
    public func scrollToDate(_ date: Date) {
        self.monthView.scrollTo(date: date) { page in
            page?.expand(at: date)
        }
    }

    private func addPushListener(subject: PublishSubject<Void>) {
        subject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] () in
                self?.monthView.reloadData()
        }).disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
    }

    public override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        view.addSubview(monthView)
        monthView.backgroundColor = UIColor.ud.bgBody
        monthView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        monthView.delegate = self
    }

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        let monthViewHeight = view.bounds.height - (parent?.view.safeAreaInsets.bottom ?? 0)
        monthView.frame = CGRect(origin: view.bounds.origin,
                                 size: CGSize(width: view.bounds.width, height: monthViewHeight))
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.dataLoader.active()
        displayRangeDidChanged()
    }

    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.dataLoader.inactive()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    func displayRangeDidChanged() {
        let pageMaker = MonthPageMaker(firstWeekday: monthView.firstWeekday.rawValue)
        let pageData = pageMaker.getPageData(date: self.currentPageDate())

        self.delegate?.displayRangeDidChanged(self, startDate: pageData.start, endDate: pageData.end)
    }
}

extension MonthViewController: MonthContainerViewDelegate {
    func containerViewCreateActionTaped(_ view: MonthContainerView) {
        self.delegate?.eventCreateActionTaped(self)
    }

    /// 月份更新
    func containerView(_ view: MonthContainerView,
                       mothDateChangedTo date: Date) {
        self.date = date
        self.delegate?.dateDidChanged(self, date: date)
        self.displayRangeDidChanged()
        self.dataLoader.eliminationCacheData(with: date)
    }

    /// 选中时间更新
    func containerView(_ view: MonthContainerView,
                       selectedDateChangedTo date: Date) {
        self.date = date
    }

    func containerView(_ view: MonthContainerView, didDidSelectAt item: MonthEventItem) {
        self.delegate?.eventViewController(self, didSelected: item.originalModel)
    }

    func containerView(view: MonthContainerView,
                       instancesFrom start: Date,
                       to end: Date) -> [MonthItem] {
        let events = self.dataLoader.getInstance(start: start, end: end)
        let timeBlocks = self.dataLoader.getTimeBlock(start: start, end: end)
        TimeDataServiceImpl.logger.info("monthPage reload: events = \(events.count), timeBlocks = \(timeBlocks.count)")
        var result = [MonthItem]()
        result.append(contentsOf: events)
        result.append(contentsOf: timeBlocks)
        return result
    }
}
