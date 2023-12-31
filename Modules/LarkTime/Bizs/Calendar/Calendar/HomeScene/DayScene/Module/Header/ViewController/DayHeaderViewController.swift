//
//  DayHeaderViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/7/9.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import LarkExtensions
import CalendarFoundation
import CTFoundation
import LarkUIKit
import LarkReleaseConfig

/// DayScene - Header - ViewController

final class DayHeaderViewController: UIViewController, DayScenePagableChild {

    let viewModel: DayHeaderViewModel
    var onPageOffsetChange: PageOffsetSyncer?

    private var timeZoneView: DayTimeZoneView?
    private var additionalTimeZoneView: DayTimeZoneView?
    private var dayPageView: PageView?
    private var weekPageView: PageView?
    private let disposeBag = DisposeBag()
    private let rxIs12HourStyle: BehaviorRelay<Bool>

    private lazy var dayItemViewPool = initDayItemViewPool()
    private lazy var weekItemViewPool = initWeekItemViewPool()

    private lazy var additionalTimeZoneOption = FeatureGating.additionalTimeZoneOption(userID: viewModel.userResolver.userID)

    init(viewModel: DayHeaderViewModel, rxIs12HourStyle: BehaviorRelay<Bool>) {
        self.viewModel = viewModel
        self.rxIs12HourStyle = rxIs12HourStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody

        if CalConfig.isMultiTimeZone {
            setupTimeZoneView()
        }
        setupPageView()
        bindViewData()
        coldLaunchIfNeeded()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        let timeZoneMarginBottom: CGFloat
        let pageMarginLeft: CGFloat
        var additionalTimeZoneWidth: CGFloat = 0
        if let timeZoneWidth = viewModel.dayStore.state.additionalTimeZone?.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value),
            viewModel.rxAdditionalTimeZoneText.value != nil {
            additionalTimeZoneWidth = timeZoneWidth
        }
        let extraWidth = additionalTimeZoneWidth == 0 ? DayScene.UIStyle.Layout.hiddenAdditionalTimeZoneSpacingWidth
        : additionalTimeZoneWidth + DayScene.UIStyle.Layout.showAdditionalTimeZoneSpacingWidth

        switch viewModel.rxViewMode.value {
        case .week(_, let isAlternateCalendarActive):
            timeZoneMarginBottom = isAlternateCalendarActive ? 11 : 15
            if additionalTimeZoneOption {
                pageMarginLeft = timeZoneView == nil ? 0 : viewModel.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value)
                + extraWidth
            } else {
                pageMarginLeft = timeZoneView == nil ? 0 : DayScene.UIStyle.Layout.leftPartWidth
            }
        case .day:
            timeZoneMarginBottom = 8
            if additionalTimeZoneOption {
                pageMarginLeft = viewModel.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value)
                + extraWidth
            } else {
                pageMarginLeft = DayScene.UIStyle.Layout.leftPartWidth
            }
        }
        var additionalTimeZoneFrame = CGRect(origin: CGPoint(x: DayScene.UIStyle.Layout.timeZonePadding, y: 0),
                                             size: CGSize(width: additionalTimeZoneWidth, height: 30))
        additionalTimeZoneFrame.bottom = view.bounds.height - timeZoneMarginBottom
        additionalTimeZoneView?.frame = additionalTimeZoneFrame
        additionalTimeZoneView?.isHidden = viewModel.rxAdditionalTimeZoneText.value == nil

        let timeZoneFrameleft = additionalTimeZoneWidth + (additionalTimeZoneWidth == 0 ? DayScene.UIStyle.Layout.timeZonePadding :
                                                            DayScene.UIStyle.Layout.timeZonePadding + DayScene.UIStyle.Layout.timeZonesSpacing)
        var timeZoneFrame: CGRect
        if additionalTimeZoneOption {
            timeZoneFrame = CGRect(origin: CGPoint(x: timeZoneFrameleft, y: 0),
                                   size: CGSize(width: viewModel.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value)
                                                + DayScene.UIStyle.Layout.timeZoneRightWidth,
                                                height: 30))
        } else {
            timeZoneFrame = CGRect(origin: CGPoint(x: 0, y: 0),
                                   size: CGSize(width: DayScene.UIStyle.Layout.leftPartWidth,
                                                height: 30))
        }
        timeZoneFrame.bottom = view.bounds.height - timeZoneMarginBottom
        timeZoneView?.frame = timeZoneFrame

        var pageFrame = view.bounds
        pageFrame.left = pageMarginLeft
        pageFrame.size.width -= pageMarginLeft
        let updatePageViewFrame = { (pageView: PageView) in
            let widthChanged = abs(pageFrame.width - pageView.frame.width) > 0.0001
            if widthChanged {
                pageView.freezeStateIfNeeded()
                pageView.frame = pageFrame
                pageView.layoutIfNeeded()
                pageView.unfreezeStateIfNeeded()
            } else {
                pageView.frame = pageFrame
            }
        }
        if let pageView = dayPageView {
            updatePageViewFrame(pageView)
        }
        if let pageView = weekPageView {
            updatePageViewFrame(pageView)
        }
    }

    func scroll(to pageOffset: PageOffset, animated: Bool) {
        if let dayPageView = dayPageView {
            dayPageView.scroll(to: pageOffset, animated: animated)
        }
    }

    private func bindViewData() {
        viewModel.rxDayViewDataUpdate.allPages.bind { [weak self] _ in
            self?.dayPageView?.reloadData(loggerModel: .init())
        }.disposed(by: disposeBag)

        viewModel.rxDayViewDataUpdate.pageAt.bind { [weak self] pageIndex in
            self?.dayPageView?.reloadData(at: pageIndex, loggerModel: .init())
        }.disposed(by: disposeBag)

        viewModel.rxWeekViewDataUpdate.allPages.bind { [weak self] _ in
            self?.weekPageView?.reloadData(loggerModel: .init())
        }.disposed(by: disposeBag)

        viewModel.rxWeekViewDataUpdate.pageAt.bind { [weak self] pageIndex in
            self?.weekPageView?.reloadData(at: pageIndex, loggerModel: .init())
        }.disposed(by: disposeBag)

        if weekPageView != nil {
            viewModel.dayStore.rxValue(forKeyPath: \.activeDay)
                .distinctUntilChanged()
                .skip(1)
                .observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: { [weak self] day in
                    guard let self = self else { return }
                    let pageIndex = self.viewModel.pageIndexForWeekMode(from: day)
                    self.weekPageView?.scroll(to: pageIndex, animated: true)
                })
                .disposed(by: disposeBag)
        }
    }

    private func coldLaunchIfNeeded() {
        guard viewModel.dayStore.state.coldLaunchContext != nil else {
            // 不需要走冷启动流程，直接 setup ViewModel
            viewModel.setup()
            return
        }

        // 监听 `didFinishColdLaunch` action，由 nonAllDay 模块 dispatch
        // 冷启动完成：切换 dataSource；setup viewModel
        viewModel.dayStore.responds { [weak self] (action, _)  in
            guard case .didFinishColdLaunch = action else { return }
            self?.viewModel.setup()
        }.disposed(by: disposeBag)
    }

}

// MARK: - Lazy Init

extension DayHeaderViewController {

    private func initDayItemViewPool() -> KeyedPool<PageIndex, DayHeaderDayView> {
        let capacity = viewModel.dayStore.state.daysPerScene + 2
        return KeyedPool<PageIndex, DayHeaderDayView>(capacity: capacity) { _ in
            return DayHeaderDayView()
        }
    }

    private func initWeekItemViewPool() -> KeyedPool<PageIndex, DayHeaderWeekView> {
        return KeyedPool<PageIndex, DayHeaderWeekView>(capacity: 3) { _ in
            let view = DayHeaderWeekView()
            view.onItemClick = { [weak self] (pageIndex, itemIndex) in
                guard let self = self else { return }
                let julianDay = self.viewModel.julianDayForWeekMode(from: pageIndex, at: itemIndex)
                self.viewModel.dayStore.dispatch(.scrollToDay(julianDay), on: MainScheduler.asyncInstance)
                self.viewModel.dayStore.dispatch(.clearEditingContext, on: MainScheduler.asyncInstance)
            }
            return view
        }
    }

}

// MARK: - Setup Views

extension DayHeaderViewController {

    // MARK: TimeZoneView

    private func makeTimeZoneView() -> DayTimeZoneView {
        let timeZoneView = CalendarPreloadTask.dayTimeZoneView ?? DayTimeZoneView()
        CalendarPreloadTask.dayTimeZoneView = nil
        timeZoneView.onClick = { [weak self] in
            guard let self = self else { return }
            self.viewModel.dayStore.dispatch(.showTimeZonePopup)
            if self.additionalTimeZoneOption {
                CalendarTracer.shared.calMainClick(type: .timezone_setting)
            }
        }
        return timeZoneView
    }

    private func makeAdditionalTimeZoneView() -> DayTimeZoneView {
        let additionalTimeZoneView = CalendarPreloadTask.dayAdditionalTimeZoneView ?? DayTimeZoneView(isShowIcon: false)
        CalendarPreloadTask.dayAdditionalTimeZoneView = nil
        additionalTimeZoneView.onClick = { [weak self] in
            guard let self = self else { return }
            self.viewModel.dayStore.dispatch(.showTimeZonePopup)
            if additionalTimeZoneOption {
                CalendarTracer.shared.calMainClick(type: .timezone_setting)
            }
        }
        return additionalTimeZoneView
    }

    private func setupTimeZoneView() {
        timeZoneView = makeTimeZoneView()
        additionalTimeZoneView = makeAdditionalTimeZoneView()
        view.addSubview(timeZoneView!)
        if let additionalTimeZoneView = additionalTimeZoneView {
            view.addSubview(additionalTimeZoneView)
        }

        let rxTimeZoneText = viewModel.rxTimeZoneText
            .observeOn(MainScheduler.instance)
            .map { [weak self] text in
                guard let self = self else { return }
                self.timeZoneView?.text = text
            }
        let rxAdditionalTimeZoneText = viewModel.rxAdditionalTimeZoneText
            .observeOn(MainScheduler.instance)
            .map { [weak self] text in
                guard let self = self else { return }
                self.additionalTimeZoneView?.text = text
            }
        Observable.merge(rxTimeZoneText, rxAdditionalTimeZoneText, rxIs12HourStyle.map {_ in })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }).disposed(by: disposeBag)
    }

    // MARK: PageView

    private func makeDayPageView(_ pagesPerScene: Int) -> PageView {
        let pageView = PageView(frame: view.bounds, totalPageCount: DayScene.UIStyle.Const.dayPageCount)
        pageView.name = "DayScene.Header.DayMode"
        pageView.isDeceleratingEnabled = false
        pageView.pageCountPerScene = pagesPerScene
        pageView.clipsToBounds = true
        pageView.dataSource = self
        pageView.delegate = self
        return pageView
    }

    private func makeWeekPageView() -> PageView {
        let totalPageCount = (DayScene.UIStyle.Const.dayPageCount + 6) / 7
        let pageView = PageView(frame: view.bounds, totalPageCount: totalPageCount)
        pageView.name = "DayScene.Header.WeekMode"
        pageView.isDeceleratingEnabled = false
        pageView.pageCountPerScene = 1
        pageView.clipsToBounds = true
        pageView.dataSource = self
        pageView.delegate = self
        return pageView
    }

    private func setupPageView() {
        let unloadPageView = { (pageView: PageView?) in
            pageView?.removeFromSuperview()
            pageView?.delegate = nil
            pageView?.dataSource = nil
        }
        let updatePageViewByMode = { [weak self] (viewMode: ViewMode) in
            guard let self = self else { return }

            // remove old pageView
            unloadPageView(self.weekPageView)
            self.weekPageView = nil
            unloadPageView(self.dayPageView)
            self.dayPageView = nil

            // add new pageView
            let (newPageView, pageIndex): (PageView, PageIndex)
            switch viewMode {
            case .day(let daysPerScene, _):
                newPageView = self.makeDayPageView(daysPerScene)
                pageIndex = self.viewModel.pageIndexForDayMode(from: self.viewModel.activeJulianDay())
                self.dayPageView = newPageView
            case .week:
                newPageView = self.makeWeekPageView()
                pageIndex = self.viewModel.pageIndexForWeekMode(from: self.viewModel.activeJulianDay())
                self.weekPageView = newPageView
            }
            self.view.addSubview(newPageView)
            newPageView.scroll(to: pageIndex)
            self.view.setNeedsLayout()
        }

        updatePageViewByMode(viewModel.rxViewMode.value)
        viewModel.rxViewMode.skip(1).bind {
            updatePageViewByMode($0)
        }.disposed(by: disposeBag)
    }

}

// MARK: - View Delegate

extension DayHeaderViewController: PageViewDataSource, PageViewDelegate {

    // MARK: PageViewDataSource

    func itemView(at index: PageIndex, in pageView: PageView, loggerModel: CaVCLoggerModel) -> UIView {
        if pageView == dayPageView {
            let dayItemView = dayItemViewPool.pop(byKey: index)
            dayItemView.viewData = viewModel.dayViewData(forDayPage: index)
            return dayItemView
        } else if pageView == weekPageView {
            let weekItemView = weekItemViewPool.pop(byKey: index)
            weekItemView.viewData = viewModel.weekViewData(forWeekPage: index)
            return weekItemView
        } else {
            DayScene.assertionFailure()
            return UIView()
        }
    }

    // MARK: PageViewDelegate

    func pageView(_ pageView: PageView, didUnload itemView: UIView, at index: PageIndex) {
        if let weekItemView = itemView as? DayHeaderWeekView {
            weekItemViewPool.push(weekItemView, forKey: index)
            DayScene.logger.info("recycle unloaded DayHeaderWeekView at: \(index)")
        } else if let dayItemView = itemView as? DayHeaderDayView {
            dayItemViewPool.push(dayItemView, forKey: index)
            DayScene.logger.info("recycle unloaded DayHeaderDayView at: \(index)")
        } else {
            DayScene.assertionFailure()
        }
    }

    func pageView(_ pageView: PageView, didChangePageOffset pageOffset: PageOffset) {
        if pageView == dayPageView {
            onPageOffsetChange?(pageOffset, self)
        }
    }

    func pageViewWillBeginFixingIndex(_ pageView: BasePageView, targetIndex: PageIndex, animated: Bool) {
        guard pageView == weekPageView else { return }

        // 周模式下，当 weekPageView 的 index 要变化时，同步到 dayStore
        let activeDay = viewModel.dayStore.state.activeDay
        let pageIndex = viewModel.pageIndexForWeekMode(from: activeDay)
        let offset = activeDay - viewModel.julianDayForWeekMode(from: pageIndex, at: 0)
        let targetJulianDay = viewModel.julianDayForWeekMode(from: targetIndex, at: offset)
        viewModel.dayStore.dispatch(.scrollToDay(targetJulianDay))
    }

}

// MARK: - ViewMode Type

extension DayHeaderViewController {
    enum ViewMode {
        /// 星期模式
        /// - parameter firstWeekDay: 星期的第一天
        /// - parameter isAlternateCalendarActive: alternate calendar 是否激活
        case week(firstWeekDay: DaysOfWeek, isAlternateCalendarActive: Bool)

        /// 日模式
        /// - parameter daysPerScene: 每个 scene 显示的天数
        /// - parameter isAlternateCalendarActive: alternate calendar 是否激活
        case day(daysPerScene: Int, isAlternateCalendarActive: Bool)
    }
}
