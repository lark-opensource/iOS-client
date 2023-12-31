//
//  FreeBusyView.swift
//  Calendar
//
//  Created by zhouyuan on 2019/4/7.
//

import UIKit
import Foundation
import CalendarFoundation
import LarkDatePickerView
import RxSwift
import SnapKit
import LarkUIKit
import ThreadSafeDataStructure
import RoundedHUD
import LarkTimeFormatUtils
import LKCommonsLogging
import UniverseDesignToast

protocol FreeBusyViewDelegate: AnyObject {
    func freeBusyView(_ freeBusyView: FreeBusyView, date: Date) throws -> (InstanceMap, [String: [WorkingHoursTimeRange]], [String: Bool])?

    func getCalendarIds(_ freeBusyView: FreeBusyView) -> [String]

    func freeBusyViewClosed(_ freeBusyView: FreeBusyView)
    /// 滚动翻页的回调
    func dateChanged(_ freeBusyView: FreeBusyView, pageChanged date: Date)
    /// 点击小月历切换日期
    func dateChanged(_ freeBusyView: FreeBusyView, monthViewChanged date: Date)
    /// 一天内 点选、拖拽 时间
    func timeChanged(_ freeBusyView: FreeBusyView, startTime: Date, endTime: Date)
    /// 添加日程 块 的显隐状态回调 控制冲突信息的显示
    func intervalStateChanged(_ freeBusyView: FreeBusyView,
                              isHidden: Bool,
                              instanceMap: InstanceMap)
    func removeHUD()
    func showHUDLoading(with text: String)
    func showHUDFailure(with text: String)
    func timeZoneClicked()
    func getUiCurrentDate() -> Date
    func jumpToEventDetail(_ detailVC: UIViewController)
}

final class FreeBusyView: UIView {
    let logger = Logger.log(FreeBusyView.self, category: "lark.calendar.freebusy")
    typealias Style = ArrangementPanel.Style
    private let disposeBag = DisposeBag()
    weak var delegate: FreeBusyViewDelegate?
    
    var arrangementCellClickCallBack: ((_ instance: RoomViewInstance) -> Void)?
    
    private var page = 0
    let verticalScrollView = UIScrollView()
    var addNewEvent: ((_ startTime: Date, _ endTime: Date) -> Void)?
    // 仅在显示会议室信息时适用
    var meetingRoomMaxDuration: TimeInterval?
    var arrangePanelTitle = BundleI18n.Calendar.Calendar_Edit_addEventNamedTitle

    private let monthBgView: UIView = UIView()
    private let headerView: FreeBusyHeader
    private var heightConstraint: NSLayoutConstraint?
    private let footerView = FooterView()
    private var infiniteScrollView: DaysViewInfiniteScrollView
    private let navigationBar: ArrangementNavigationBar
    private var startDate: Date
    private let getNewEventMinute: () -> Int
    private let isHiddenPushlish = PublishSubject<Bool>()
    private let workItemQueue: WorkItemQueue
    private let is12HourStyle: Bool
    private var timeZone: TimeZone = .current
    private let dataQueue = DispatchQueue(label: "Calendar.FreeBusyView")
    private let loaddingWrapper: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        return view
    }()
    private lazy var loaddingView: LoadingView = {
        let loadding = LoadingView(displayedView: loaddingWrapper)
        return loadding
    }()

    private lazy var timeZoneWrapper: TimeZoneWrapper = {
        var tz = TimeZoneWrapper()
        tz.timeZoneClicked = { [weak self] in
            self?.delegate?.timeZoneClicked()
        }
        return tz
    }()

    init(startDate: Date,
         firstWeekday: DaysOfWeek,
         getNewEventMinute: @escaping () -> Int,
         is12HourStyle: Bool,
         showHeaderView: Bool = true) {
        self.startDate = startDate.dayStart()
        self.getNewEventMinute = getNewEventMinute
        self.is12HourStyle = is12HourStyle
        let timeWidth = TimeIndicator.indicatorWidth(is12HourStyle: is12HourStyle)
        self.headerView = FreeBusyHeader(leftMargin: timeWidth)
        self.navigationBar = ArrangementNavigationBar(date: startDate,
                                                      firstWeekday: firstWeekday)
        // WARNING: 不进行缓存；代码设计有些缺陷；被缓存的 page 触发的 willDisplay 会影响当前 page，导致 UI 数据异常
        let cachePageCount: Int = 0

        let uselessScreenWidthPlaceHolder: CGFloat = 666
        infiniteScrollView = DaysViewInfiniteScrollView(pageWidth: uselessScreenWidthPlaceHolder,
                                                        cachePageCount: cachePageCount,
                                                        hasLeftEdge: false)
        workItemQueue = WorkItemQueue(maxCount: cachePageCount * 2 + 1)
        super.init(frame: CGRect(x: 0, y: 0,
                                 width: uselessScreenWidthPlaceHolder,
                                 height: UIScreen.main.bounds.height))
        setupNavigationBar(navigationBar, superView: self)
        layoutHeaderView(headerView, superView: self, leftMargin: timeWidth, showHeaderView: showHeaderView)
        if CalConfig.isMultiTimeZone {
            layoutTimeZone(width: timeWidth)
        }
        layoutVerticalScrollView(scrollView: verticalScrollView, upView: headerView)
        layoutFooterView(footerView, upView: verticalScrollView)
        setupInfiniteScrollView(infiniteScrollView, in: verticalScrollView)
        /// 阴影不能遮挡
        bringSubviewToFront(headerView)

        self.addSubview(loaddingWrapper)
        loaddingWrapper.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerView)
        }
        observerScroll(verticalScrollView: verticalScrollView,
                       horizontalScrollView: infiniteScrollView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(maskViewOnClick))
        monthBgView.addGestureRecognizer(tap)
        addSubview(monthBgView)
        monthBgView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        monthBgView.isHidden = true

        /// 小月历可下拉 不能遮挡
        bringSubviewToFront(navigationBar)
    }

    func relayoutForiPad(newWidth: CGFloat) {
        verticalScrollView.contentSize = CGSize(width: newWidth, height: Style.wholeDayHeight)
        headerView.relayoutForiPad(newWidth: newWidth)
        if infiniteScrollView.frame.size.width != newWidth {

            infiniteScrollView.pageWidth = newWidth
            infiniteScrollView.frame.size.width = newWidth
        }
        infiniteScrollView.relayoutForiPad(newWidth: newWidth)
        infiniteScrollView.pageWidth = newWidth
    }

    @objc private func maskViewOnClick() {
        self.navigationBar.closeDatePicker()
    }

    private func observerScroll(verticalScrollView: UIScrollView,
                                horizontalScrollView: UIScrollView) {
        verticalScrollView.rx.didScroll
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .asObservable()
            .subscribe(onNext: { [weak self] () in
//                self?.isHiddenPushlish.onNext(true)
            })
            .disposed(by: disposeBag)

        horizontalScrollView.rx.didScroll
            .throttle(.milliseconds(500), scheduler: MainScheduler.asyncInstance)
            .asObservable()
            .subscribe(onNext: { [weak self] () in
                self?.isHiddenPushlish.onNext(true)
                self?.logger.info("[freeBusyView] horizontalScrollView didScroll")
                self?.pageDetect()
            })
            .disposed(by: disposeBag)
    }

    /// 翻页回调
    private func pageDetect() {
        let page = self.currentPage()
        if page == self.page { return }
        self.page = page
        self.navigationBar.changeDate(date: self.currentDate())
        self.logger.info("[freeBusyView] currentPage: \(page), currentDate: \(self.currentDate())")
        if let panel = getPageView(page: page) {
            if panel.loadingState.value == .loading || panel.loadingState.value != .success {
                self.delegate?.showHUDLoading(with: BundleI18n.Calendar.Calendar_Edit_FindTimeLoading)
            }
            if panel.loadingState.value != .success, panel.loadingState.value != .loading {
                self.logger.info("[freeBusyView] self call infiniteScrollView(:scrollView,:willDisplay,:at)")
                infiniteScrollView(scrollView: infiniteScrollView, willDisplay: panel, at: page)
            }
        }
        self.delegate?.dateChanged(self, pageChanged: self.currentDate())
    }

    private func setupNavigationBar(_ navigationBar: ArrangementNavigationBar,
                                    superView: UIView) {
        superView.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        navigationBar.closeHandle = { [unowned self] in
            self.delegate?.freeBusyViewClosed(self)
        }

        navigationBar.didSelectDate = { [weak self] date in
            guard let self = self else { return }
            self.scrollToDate(date)
            self.delegate?.dateChanged(self, monthViewChanged: date)
        }

        navigationBar.stateChangeHandle = { [weak self] (isExpand) in
            self?.monthBgView.isHidden = !isExpand
        }
    }

    private func layoutHeaderView(_ headerView: FreeBusyHeader,
                                  superView: UIView,
                                  leftMargin: CGFloat,
                                  showHeaderView: Bool) {
        superView.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.left.equalToSuperview().offset(leftMargin)
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top).offset(44)
            make.height.equalTo(showHeaderView ? FreeBusyHeader.height : 0)
        }
    }

    private func layoutTimeZone(width: CGFloat) {
        self.addSubview(timeZoneWrapper)
        timeZoneWrapper.snp.makeConstraints({make in
            make.left.equalToSuperview()
            make.width.equalTo(width)
            make.bottom.equalTo(headerView.snp.bottom).offset(-16)
        })
    }

    func setTimeZoneStr(timeZoneStr: String) {
        timeZoneWrapper.setTimeZoneStr(timeZoneStr: timeZoneStr)
    }

    func updateCurrentUiDate(uiDate: Date, with timeZone: TimeZone = .current) {
        // 忙闲页面可以左右滑动，需要调整 startDate 到对应时区，避免和 picker 循环调用
        startDate = TimeZoneUtil.dateTransForm(srcDate: startDate, srcTzId: self.timeZone.identifier, destTzId: timeZone.identifier)
        navigationBar.updateCurrentUiDate(uiDate: uiDate, timeZone: timeZone)
        self.timeZone = timeZone
    }

    private func layoutVerticalScrollView(scrollView: UIScrollView, upView: UIView) {
        scrollView.contentSize = CGSize(width: upView.bounds.width,
                                        height: Style.wholeDayHeight)
        addSubview(scrollView)
        scrollView.canCancelContentTouches = false
        scrollView.delaysContentTouches = false
        scrollView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(upView.snp.bottom)
        }
    }

    private func layoutFooterView(_ footerView: UIView, upView: UIView) {
        addSubview(footerView)
        footerView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(upView.snp.bottom)
        }
        self.heightConstraint = footerView.heightAnchor.constraint(equalToConstant: 52)
        self.heightConstraint?.isActive = true
    }

    private func setupInfiniteScrollView(_ infiniteScrollView: DaysViewInfiniteScrollView,
                                         in superView: UIScrollView) {
        infiniteScrollView.canCancelContentTouches = false
        infiniteScrollView.delaysContentTouches = false
        infiniteScrollView.frame = CGRect(x: 0,
                                          y: 0,
                                          width: superView.bounds.width,
                                          height: Style.wholeDayHeight)
        superView.addSubview(infiniteScrollView)
        infiniteScrollView.dataSource = self
    }

    func showLoading() {
        loaddingWrapper.isHidden = false
        loaddingView.showLoading()
    }

    func showFailed(retry: (() -> Void)? = nil) {
        loaddingView.showFailed {
            retry?()
        }
    }

    func hideLoading() {
        loaddingView.remove()
        loaddingWrapper.isHidden = true
    }

    func hideInterval() {
        isHiddenPushlish.onNext(true)
    }

    func reloadData() {
        infiniteScrollView.reloadData()
    }

    func scrollToDate(_ date: Date, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        let pageIndex = indexByDate(date)
        scrollToPage(pageIndex, animated: animated, completion: completion)
    }

    private func scrollToPage(_ page: Int, animated: Bool, completion: ((Bool) -> Void)? = nil) {
        self.logger.info("[freeBusyView] infiniteScrollView scrollToPage \(page)")
        infiniteScrollView.scrollToPage(page, animated: animated, completion: completion)
    }

    func setHeaderFoorterViewInfo(model: ArrangementHeaderViewModel,
                                  footerAttributedString: NSAttributedString?) {
        headerView.updateModel(model: model)
        if let text = footerAttributedString {
            footerView.isHidden = false
            footerView.setAttrText(text)
            self.heightConstraint?.constant = 52
        } else {
            footerView.isHidden = true
            self.heightConstraint?.constant = 0
        }
        self.setNeedsDisplay()
    }

    private func currentDate() -> Date {
        return dateByIndex(currentPage())
    }

    /// page 转换成日期
    private func dateByIndex(_ index: Int) -> Date {
        return (startDate + index.day)!
    }

    /// 日期转换成对应的page
    private func indexByDate(_ date: Date) -> Int {
        let components = Calendar.gregorianCalendar.dateComponents([.day],
                                                         from: startDate.dayStart(),
                                                         to: date.dayStart())
        guard let day = components.day else {
            return 0
        }
        return day
    }

    func scrollToTime(time: Date, animated: Bool) {
        let offset = yOffsetWithDate(time,
                                    inTheDay: time,
                                    totalHeight: Style.hourGridHeight * 24,
                                    topIgnoreHeight: 0,
                                    bottomIgnoreHeight: 0)
        let rect = CGRect(x: 0, y: offset,
                          width: verticalScrollView.frame.width,
                          height: 20)
        scrollRectToVisibleCenter(verticalScrollView, visibleRect: rect, animated: animated)
    }

    private func currentPage() -> Int {
        return infiniteScrollView.currentPage()
    }

    private func getPageView(page: Int) -> ArrangementPanel? {
        let view = infiniteScrollView.visibleViews.first(where: { $0.tag == page })
        let panel = view as? ArrangementPanel
        return panel
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension FreeBusyView: InfiniteScrollViewDelegate {
    func infiniteScrollView(scrollView: InfiniteScrollView, viewForIndex index: Int) -> UIView {
        let intervalCoodinator = FreebusyIntervalCoodinator(startTime: Date(),
                                                            title: arrangePanelTitle,
                                                            isHiddenPushlish: isHiddenPushlish,
                                                            getNewEventMinute: getNewEventMinute,
                                                            is12HourStyle: is12HourStyle)
        intervalCoodinator.addNewEvent = { [weak self, weak intervalCoodinator] (startTime, endTime) in
            guard let self = self else { return }
            if let intervalCoodinator = intervalCoodinator,
               let duration = self.meetingRoomMaxDuration,
                endTime.timeIntervalSince(startTime) > duration {
                let newEndTime = startTime + duration
                let newFrame = intervalCoodinator.getTimeRangFrame(startTime: startTime, endTime: newEndTime, containerWidth: intervalCoodinator.containerWidth)
                intervalCoodinator.intervalIndicator.frame = newFrame
                intervalCoodinator.changeTime(startTime: startTime, endTime: newEndTime)

                UDToast.showFailure(with: CalendarMeetingRoom.maxDurationText(fromSeconds: Int32(duration)), on: self)
            } else {
                self.addNewEvent?(startTime, endTime)
            }
        }
        let view = ArrangementPanel(intervalCoodinator: intervalCoodinator)
        if Display.pad, #available(iOS 14, *) {
            view.setCollectinPanGesturePriorityLower(than: verticalScrollView.panGestureRecognizer)
        }
        view.delegate = self
        view.frame = CGRect(x: 0, y: 0, width: scrollView.bounds.width, height: 1200)
        view.arrangementCellClickCallBack = { [weak self] instance in
            guard let self = self else { return }
            self.arrangementCellClickCallBack?(instance)
        }
        return view
    }

    func infiniteScrollView(scrollView: InfiniteScrollView,
                            willDisplay view: UIView,
                            at index: Int) {
        guard let arrangementPanel = view as? ArrangementPanel else {
//            hud?.remove()
            self.delegate?.removeHUD()
            assertionFailureLog()
            return
        }
        let now = Date()
        let date = dateByIndex(index).changed(hour: now.hour, minute: now.minute)!
        let calendarIds = self.delegate?.getCalendarIds(self) ?? []
        arrangementPanel.updateCurrentUiDate(uiDate: self.delegate?.getUiCurrentDate() ?? Date())
        arrangementPanel.cleanInstance(calendarIds: calendarIds, startTime: date, endTime: date)
        arrangementPanel.loadingState.value = .loading
        operationLog(message: "should load panel index: \(index)")
        self.logger.info("[freeBusyView] should load panel index: \(index)")
        let workItem = DispatchWorkItem { [weak self] in
            guard let `self` = self else { return }
            do {
                operationLog(message: "did load panel index: \(index)")
                self.logger.info("[freeBusyView] did load panel index: \(index)")
                DispatchQueue.main.async {
                    if self.currentPage() == index {
                        self.delegate?.showHUDLoading(with: BundleI18n.Calendar.Calendar_Edit_FindTimeLoading)
                    }
                }
                guard let (instanceMap, workingHoursTimeRangeMap, privateCalMap)
                    = try self.delegate?.freeBusyView(self, date: date),
                    !instanceMap.isEmpty else {
                        arrangementPanel.loadingState.value = .failed
                        self.logger.info("[freeBusyView] arrangement panel loadingState is failed")
                        return
                }
                DispatchQueue.main.async {
                    let calendarIds = self.delegate?.getCalendarIds(self) ?? []
                    arrangementPanel.reloadView(
                        calendarIds: calendarIds,
                        calendarInstanceMap: instanceMap,
                        workingHoursTimeRangeMap: workingHoursTimeRangeMap,
                        privateCalMap: privateCalMap
                    )
                    arrangementPanel.loadingState.value = .success
                    self.logger.info("[freeBusyView] arrangement panel loadingState is success")
                    if self.currentPage() == index {
//                        self.hud?.remove()
                        self.delegate?.removeHUD()
                    }
                }
            } catch {
                arrangementPanel.loadingState.value = .failed
                self.logger.info("[freeBusyView] arrangement panel syncLoadInstanceDate failed")
                DispatchQueue.main.async {
                    if self.currentPage() == index {
                        self.delegate?.showHUDFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad)
                    }
                }
            }
        }
        self.workItemQueue.add((workItem, index))
        dataQueue.async(execute: workItem)

        let removeworkItem = DispatchWorkItem { [weak self] in
            self?.workItemQueue.remove(workItem)
        }
        dataQueue.async(execute: removeworkItem)
    }
}

extension FreeBusyView: ArrangementPanelDelegate {
    func intervalStateChanged(_ arrangementPanel: ArrangementPanel,
                              isHidden: Bool,
                              instanceMap: InstanceMap) {
        self.delegate?.intervalStateChanged(self,
                                            isHidden: isHidden,
                                            instanceMap: instanceMap)
    }

    func timeChanged(_ arrangementPanel: ArrangementPanel,
                     startTime: Date, endTime: Date) {
        self.delegate?.timeChanged(self, startTime: startTime, endTime: endTime)
    }

    func intervalFrameChangedByClick(newFrame: CGRect, superView: UIView) {

    }

    private func scrollRectToVisibleCenter(_ scrollView: UIScrollView,
                                           visibleRect: CGRect,
                                           animated: Bool) {
        let centeredRect = CGRect(
            x: visibleRect.minX,
            y: visibleRect.minY - scrollView.frame.height / 2.0 + ArrangementPanel.Style.topGridMargin * 2.0,
            width: scrollView.frame.width,
            height: scrollView.frame.height)
        scrollView.scrollRectToVisible(centeredRect, animated: animated)
    }

    func jumpToEventDetailVC(_ detailVC: UIViewController) {
        self.delegate?.jumpToEventDetail(detailVC)
    }
}

private final class FooterView: UIView, Shadowable {
    private let footerLabel = UILabel.cd.textLabel(fontSize: 14)
    init() {
        super.init(frame: .zero)
        addSubview(footerLabel)
        footerLabel.numberOfLines = 0
        footerLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
        }
    }

    func setAttrText(_ attrText: NSAttributedString?) {
        footerLabel.attributedText = attrText
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTopShadows()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
