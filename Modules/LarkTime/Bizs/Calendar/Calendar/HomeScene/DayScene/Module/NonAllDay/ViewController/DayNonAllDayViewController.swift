//
//  DayNonAllDayViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/7/9.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import LarkExtensions
import AudioToolbox
import CalendarFoundation
import CTFoundation
import UniverseDesignToast
import ThreadSafeDataStructure

/// DayScene - NonAllDay - ViewController

final class DayNonAllDayViewController: UIViewController, DayScenePagableChild {

    // MARK: Public Properties

    let viewModel: DayNonAllDayViewModel
    var onPageOffsetChange: PageOffsetSyncer?

    // MARK: Private Properties

    private lazy var containerView = initContainerView()
    private lazy var timeScaleView = initTimeScaleView()
    private lazy var additionalTimeScaleView = initTimeScaleView()
    private lazy var timeScaleBackgroundView = initTimeScaleBackgroundView()
    private lazy var dayPageView = initDayPageView()
    private lazy var redLineView = RedLineView()
    private lazy var editingMaskView = initEditingMaskView()
    private var lastPageDrawRect = CGRect.zero
    private lazy var additionalTimeZoneOption = FeatureGating.additionalTimeZoneOption(userID: viewModel.userResolver.userID)
    private let disposeBag = DisposeBag()

    private lazy var viewPool = (instanceItem: initInstanceViewPool(), dayItem: initDayItemViewPool())

    // 处理日程块长按
    private lazy var longPress = (
        // 捕捉 longPress 的 view
        captureView: LongPressCaptureView(),
        // longPress 手势
        gesture: UILongPressGestureRecognizer(),
        // longPress recognized 后，进入 forwardChild
        forwardChild: DayInstanceEditViewController?.none
    )

    private var rxIs12HourStyle: BehaviorRelay<Bool> {
        viewModel.rxIs12HourStyle
    }
    private let calendarApi: CalendarRustAPI?
    private let settingService: SettingProvider

    private lazy var pageViewDataSourceProxy: PageViewDataSourceProxy = {
        PageViewDataSourceProxy(target: self)
    }()

    private var coldLaunchDataSource: ColdLaunchDataSource?
    private var launchLoggerModel: CaVCLoggerModel

    init(
        viewModel: DayNonAllDayViewModel,
        calendarApi: CalendarRustAPI?,
        settingService: SettingProvider,
        launchLoggerModel: CaVCLoggerModel
    ) {
        HomeScene.coldLaunchTracker?.insertPoint(.initDayScene)

        self.viewModel = viewModel
        self.calendarApi = calendarApi
        self.settingService = settingService
        self.launchLoggerModel = launchLoggerModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Override

    override func viewDidLoad() {
        HomeScene.coldLaunchTracker?.insertPoint(.daySceneDidLoad)

        super.viewDidLoad()
        setupView()
        initPageDrawRect()
        respondsRxFromViewModel()
        bindStoreAction()
        attachLongPressGesture()
        coldLaunchIfNeeded()
    }

    override func loadView() {
        self.view = longPress.captureView
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewModel.rxViewAppeared.accept(.init(isAppeared: false, didAppeared: isViewAppeared, launchModel: nil))

        clearEditingContext()
    }

    private var isViewAppeared: Bool = false
    override func viewDidAppear(_ animated: Bool) {
        if !isViewAppeared {
            let new = self.launchLoggerModel.createNewModelByAddAsyncTask(.change)
            viewModel.rxViewAppeared.accept(.init(isAppeared: true, didAppeared: isViewAppeared, launchModel: new))
            HomeScene.coldLaunchTracker?.insertPoint(.daySceneDidAppear)
        } else {
            viewModel.rxViewAppeared.accept(.init(isAppeared: true, didAppeared: isViewAppeared, launchModel: nil))
        }
        super.viewDidAppear(animated)
        defer { isViewAppeared = true }
        if !isViewAppeared {
            scrollContainerView(to: viewModel.currentTimeScale(), animated: false)
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        containerView.contentSize = CGSize(
            width: view.bounds.width,
            height: DayScene.UIStyle.Layout.timeScaleCanvasHeight
        )
        let additionalTimeZoneWidth = viewModel.dayStore.state.additionalTimeZone?.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value) ?? 0
        let timeScaleViewX: CGFloat
        let timeZoneWidth: CGFloat
        let timeScaleLeftPartWidth: CGFloat
        if additionalTimeZoneOption {
            timeZoneWidth = viewModel.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value)
            + DayScene.UIStyle.Layout.timeZoneRightWidth

            timeScaleViewX = additionalTimeZoneWidth == 0 ? DayScene.UIStyle.Layout.timeZonePadding :
            additionalTimeZoneWidth + DayScene.UIStyle.Layout.timeZonePadding + DayScene.UIStyle.Layout.timeZonesSpacing

            timeScaleLeftPartWidth = additionalTimeZoneWidth == 0 ? DayScene.UIStyle.Layout.timeZonePadding * 2 + timeZoneWidth :
            timeScaleViewX + timeZoneWidth + DayScene.UIStyle.Layout.timeZonePadding

            timeScaleBackgroundView.frame = CGRect(
                x: 0,
                y: 0,
                width: timeScaleLeftPartWidth,
                height: containerView.contentSize.height
            )

            additionalTimeScaleView.frame = CGRect(
                x: DayScene.UIStyle.Layout.timeZonePadding,
                y: 0,
                width: additionalTimeZoneWidth,
                height: containerView.contentSize.height
            )
        } else {
            timeZoneWidth = DayScene.UIStyle.Layout.leftPartWidth
            timeScaleViewX = 0
            timeScaleLeftPartWidth = DayScene.UIStyle.Layout.leftPartWidth
        }
        timeScaleView.frame = CGRect(
            x: timeScaleViewX,
            y: 0,
            width: timeZoneWidth,
            height: containerView.contentSize.height
        )
        let pageViewTargetFrame = CGRect(
            x: timeScaleLeftPartWidth,
            y: 0,
            width: containerView.contentSize.width - timeScaleLeftPartWidth,
            height: DayScene.UIStyle.Layout.timeScaleCanvasHeight
        )
        let widthChanged = abs(pageViewTargetFrame.width - dayPageView.frame.width) > 0.0001
        if widthChanged {
            dayPageView.freezeStateIfNeeded()
            dayPageView.frame = pageViewTargetFrame
            dayPageView.layoutIfNeeded()
            dayPageView.unfreezeStateIfNeeded()
        } else {
            dayPageView.frame = pageViewTargetFrame
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            // dispatch async 处理，是为了确保 pageSize 已经稳定下来了
            let rect = CGRect(origin: .zero, size: self.dayPageView.pageSize).inset(by: DayNonAllDayView.padding)
            guard self.lastPageDrawRect != rect else { return }
            DayScene.logger.info("page draw rect changed. \(rect)")
            self.lastPageDrawRect = rect
            let rectFunc = { rect }
            self.viewModel.rxPageDrawRectFunc.accept(rectFunc)
        }
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        var scorllViewInset = containerView.contentInset
        scorllViewInset.bottom = view.safeAreaInsets.bottom
        containerView.contentInset = scorllViewInset
    }

    func scroll(to pageOffset: PageOffset, animated: Bool) {
        dayPageView.scroll(to: pageOffset, animated: animated)
    }

    // MARK: Cold Launch

    private func coldLaunchIfNeeded() {
        self.launchLoggerModel.updateTask(.process)
        guard let coldLaunchContext = viewModel.dayStore.state.coldLaunchContext else {
            // 不需要走冷启动流程，直接 setup ViewModel
            viewModel.setup(loggerModel: self.launchLoggerModel)
            return
        }

        // 结束冷启动
        var finishColdLaunchFlag = false
        let doFinishColdLaunch: (CaVCLoggerModel) -> Void = { [weak self] loggerModel in
            guard !finishColdLaunchFlag, let self = self else { return }
            defer { finishColdLaunchFlag = true }

            self.pageViewDataSourceProxy.target = self
            self.viewModel.setup(loggerModel: loggerModel)
            print("self.viewModel.setup(loggerModel")
            self.viewModel.didFinishColdLaunch(loggerModel: loggerModel)
            self.viewModel.dayStore.dispatch(.didFinishColdLaunch)
        }

        // 准备冷启动数据
        HomeScene.coldLaunchTracker?.insertPoint(.dayScenePrepareViewData)
        let coldLaunchDataSource = ColdLaunchDataSource(target: self, context: coldLaunchContext)
        pageViewDataSourceProxy.target = coldLaunchDataSource
        coldLaunchDataSource.prepareViewData { [weak self] (succeed, loggerModel) in
            guard let self = self else { return }
            if succeed {
                HomeScene.coldLaunchTracker?.insertPoint(.daySceneViewDataReady)
            }
            guard !finishColdLaunchFlag else { return }
            if succeed {
                DayScene.logger.info("will reload pageView with coldLaunch viewData")
                EffLogger.log(model: loggerModel, toast: "will reload pageView with coldLaunch viewData")
                DispatchQueue.main.async {
                    self.dayPageView.reloadData(loggerModel: loggerModel)
                    let asyncModel = loggerModel.createNewModelByAddAsyncTask(.process)
                    EffLogger.log(model: asyncModel, toast: "cold launch track")
                    self.dayEndTrack()
                    doFinishColdLaunch(asyncModel)
                }
            } else {
                HomeScene.coldLaunchTracker?.finish(.failedForError)
            }
        }
        self.coldLaunchDataSource = coldLaunchDataSource

        // Watch Dog. 800ms 还没完成冷启动，则强行结束
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(800)) {
            guard !finishColdLaunchFlag else { return }
            HomeScene.coldLaunchTracker?.finish(.failedForTimeout)
            doFinishColdLaunch(self.launchLoggerModel)
        }
    }

    private func dayEndTrack() {
        HomeScene.coldLaunchTracker?.finish(.succeed)
    }
}

// MARK: - InstanceView & DayView

extension DayNonAllDayViewController {

    private func initPageDrawRect() {
        let additionalTimeZoneWidth = viewModel.dayStore.state.additionalTimeZone?.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value) ?? 0
        let timeZoneWidth: CGFloat = viewModel.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value)
        let pageMarginLeft: CGFloat = additionalTimeZoneWidth == 0 ? timeZoneWidth + DayScene.UIStyle.Layout.hiddenAdditionalTimeZoneSpacingWidth
        : timeZoneWidth + additionalTimeZoneWidth + DayScene.UIStyle.Layout.showAdditionalTimeZoneSpacingWidth
        let pageViewWidth = UIScreen.main.bounds.width - pageMarginLeft
        let pageWidth = pageViewWidth / CGFloat(dayPageView.pageCountPerScene)

        let rect = CGRect(
            origin: .zero,
            size: CGSize(width: pageWidth, height: DayScene.UIStyle.Layout.timeScaleCanvasHeight)
        ).inset(by: DayNonAllDayView.padding)
        if rect != lastPageDrawRect {
            viewModel.rxPageDrawRectFunc.accept({ rect })
            lastPageDrawRect = rect
        }
    }

    private func initInstanceViewPool() -> KeyedPool<String, DayNonAllDayInstanceView> {
        #if DEBUG
        var count = 0
        #endif
        let capacity = viewModel.dayStore.state.daysPerScene * 10
        return KeyedPool<String, DayNonAllDayInstanceView>(capacity: capacity) { [weak self] _ in
            let view = DayNonAllDayInstanceView()
            view.calendarSelectTracer = self?.viewModel.calendarSelectTracer
            if let self = self {
                view.tapGesture.require(toFail: self.longPress.gesture)
            }
            #if DEBUG
            count += 1
            debugPrint("No.\(count) DayNonAllDayInstanceView is created")
            #endif
            return view
        }
    }

    private func initDayItemViewPool() -> KeyedPool<JulianDay, DayNonAllDayView> {
        #if DEBUG
        var count = 0
        #endif
        let capacity = viewModel.dayStore.state.daysPerScene + 2
        return KeyedPool<JulianDay, DayNonAllDayView>(capacity: capacity) { [weak self] _ in
            let view = DayNonAllDayView()
            view.delegate = self
            #if DEBUG
            count += 1
            debugPrint("No.\(count) DayNonAllDayView is created")
            #endif
            return view
        }
    }
}

// MARK: Views

extension DayNonAllDayViewController {

    // 红线（当前时间）
    final class RedLineView: UIView {
        static let desiredHeight: CGFloat = 7
        private let dotLayer = CALayer()
        private let lineLayer = CALayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            lineLayer.ud.setBackgroundColor(UIColor.ud.functionDangerContentDefault, bindTo: self)
            layer.addSublayer(lineLayer)

            dotLayer.ud.setBackgroundColor(UIColor.ud.functionDangerContentDefault, bindTo: self)
            dotLayer.cornerRadius = RedLineView.desiredHeight / 2
            dotLayer.masksToBounds = true
            layer.addSublayer(dotLayer)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            lineLayer.frame = CGRect(x: 8, y: bounds.centerY - 0.5, width: bounds.width - 8, height: 1)
            dotLayer.frame = CGRect(
                x: 0,
                y: bounds.centerY - Self.desiredHeight / 2,
                width: Self.desiredHeight,
                height: Self.desiredHeight
            )
            CATransaction.commit()
        }
    }

    // 捕获 longPress
    private final class LongPressCaptureView: UIView {
        var lastHitTestView: UIView?
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let view = super.hitTest(point, with: event)
            lastHitTestView = view
            return view
        }

    }

    private func setupView() {

        /// --- View Heriency ---
        ///
        /// |---self.view
        ///     |---containerView
        ///         |---dayTimeView
        ///         |---dayPageView
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapInContainerView(_:)))
        containerView.addGestureRecognizer(tapGesture)
        view.addSubview(containerView)
        containerView.frame = view.bounds
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        containerView.addSubview(dayPageView)
        if additionalTimeZoneOption {
            containerView.addSubview(timeScaleBackgroundView)
            timeScaleBackgroundView.addSubview(timeScaleView)
            timeScaleBackgroundView.addSubview(additionalTimeScaleView)
        } else {
            containerView.addSubview(timeScaleView)
        }

        let activePageIndex = DayScene.pageIndex(from: viewModel.dayStore.state.activeDay)
        dayPageView.scroll(to: activePageIndex)

        rxIs12HourStyle.distinctUntilChanged()
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak self] is12HourStyle in
                self?.timeScaleView.formatter = { [weak self] timeScale in
                    guard let self = self else { return "" }
                    return DayNonAllDayViewModel.formattedText(for: timeScale, is12HourStyle: is12HourStyle, activateDay: viewModel.dayStore.state.activeDay)
                }
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }
            .disposed(by: disposeBag)
    }

    private func initContainerView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = UIColor.ud.bgBody
        return scrollView
    }

    private func initTimeScaleView() -> DayTimeScaleView {
        let timeScaleView = DayTimeScaleView()
        timeScaleView.vPadding = (
            top: DayScene.UIStyle.Layout.timeScaleCanvas.vPadding.top,
            bottom: DayScene.UIStyle.Layout.timeScaleCanvas.vPadding.bottom
        )
        return timeScaleView
    }

    private func initTimeScaleBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.calEventViewBg
        return view
    }

    private func initDayPageView() -> PageView {
        let pageView = PageView(frame: view.bounds, totalPageCount: DayScene.UIStyle.Const.dayPageCount, isShowEffLog: true)
        pageView.name = "DayScene.NonAllDay"
        pageView.isDeceleratingEnabled = false
        pageView.pageCountPerScene = viewModel.dayStore.state.daysPerScene
        pageView.clipsToBounds = false
        pageView.dataSource = pageViewDataSourceProxy
        pageView.delegate = self
        return pageView
    }

    private func initEditingMaskView() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgBody
        view.isUserInteractionEnabled = false
        view.alpha = 0.5
        return view
    }

}

// MARK: - Responds Rx from ViewModel

extension DayNonAllDayViewController {

    private func respondsRxFromViewModel() {
        respondsToUpdatePages()
        respondsToUpdateRedLine()

        guard additionalTimeZoneOption else { return }
        Observable.combineLatest(viewModel.dayStore.rxValue(forKeyPath: \.additionalTimeZone),
                                 rxIs12HourStyle,
                                 viewModel.dayStore.rxValue(forKeyPath: \.timeZoneModel),
                                 viewModel.dayStore.rxValue(forKeyPath: \.activeDay))
            .observeOn(MainScheduler.instance)
            .distinctUntilChanged { (pre, next) -> Bool in
                return pre.0?.timeZone.identifier == next.0?.timeZone.identifier
                && pre.1 == next.1
                && pre.2.timeZone.identifier == next.2.timeZone.identifier
                && pre.3 == next.3
            }
            .subscribe(onNext: { [weak self] additionalTimeZoneModel, is12HourStyle, _, activeDay in
                self?.additionalTimeScaleView.isHidden = additionalTimeZoneModel == nil
                self?.additionalTimeScaleView.formatter = { timeScale in
                    return DayNonAllDayViewModel.formattedText(for: timeScale,
                                                               is12HourStyle: is12HourStyle,
                                                               activateDay: activeDay,
                                                               timeZone: additionalTimeZoneModel?.timeZone ?? .current)
                }
                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }).disposed(by: disposeBag)
    }

    // 响应 update pages
    private func respondsToUpdatePages() {
        viewModel.rxUpdate.pageAt.subscribe(onNext: { [weak self] v in
            self?.dayPageView.reloadData(at: v.value, loggerModel: v.loggerModel)
        }).disposed(by: disposeBag)

        viewModel.rxUpdate.allPages.subscribe(onNext: { [weak self] v in
            self?.dayPageView.reloadData(loggerModel: v)
        }).disposed(by: disposeBag)
    }

    // 响应处理红线
    private func respondsToUpdateRedLine() {
        viewModel.rxJulianDayTimeScale
            .observeOn(MainScheduler.asyncInstance)
            .bind { [weak self] tuple in
                guard let self = self else { return }
                let (julianDay, timeScale) = tuple
                let itemView = self.dayPageView.itemView(at: DayScene.pageIndex(from: julianDay))
                guard let pageItemView = itemView as? DayNonAllDayView else {
                    self.redLineView.removeFromSuperview()
                    return
                }
                self.attachRedLine(to: pageItemView, with: timeScale)
            }
            .disposed(by: disposeBag)
    }

    // 附着红线到 pageItemView 上
    private func attachRedLine(to pageItemView: DayNonAllDayView, with timeScale: TimeScale) {
        let baseline = pageItemView.baseline(at: timeScale)
        redLineView.frame = CGRect(
            origin: CGPoint(
                x: baseline.start.x,
                y: baseline.start.y - 2
            ),
            size: CGSize(
                width: baseline.end.x - baseline.start.x,
                height: 4
            )
        )
        pageItemView.addSubview(redLineView)
    }

}

// MARK: - Store Action

extension DayNonAllDayViewController {

    private func scrollContainerView(to timeScale: TimeScale, animated: Bool) {
        let offsetY = timeScaleView.baseline(at: timeScale).start.y
        var contentOffset = containerView.contentOffset
        contentOffset.y = offsetY - containerView.bounds.height / 2
        contentOffset.y = max(contentOffset.y, -containerView.contentInset.top)
        contentOffset.y = min(contentOffset.y, containerView.contentSize.height
            + containerView.contentInset.bottom - containerView.bounds.height)
        containerView.setContentOffset(contentOffset, animated: animated)
    }

    // 动画跳转到目标 julianDay；如果翻页跨度较大，则模拟翻页
    private func scrollPageViewAnimated(to julianDay: JulianDay) {
        let pageIndex = DayScene.pageIndex(from: julianDay)
        let curPageRange = dayPageView.visiblePageRange

        let adjacentLowerBound = curPageRange.lowerBound - dayPageView.pageCountPerScene
        let adjacentUpperBound = curPageRange.lowerBound + dayPageView.pageCountPerScene
        let adjacentPageRange = adjacentLowerBound..<adjacentUpperBound

        guard !adjacentPageRange.contains(pageIndex) else {
            // 翻页距离较短，直接翻页
            dayPageView.scroll(to: pageIndex, animated: true)
            return
        }

        guard let snapshotView = dayPageView.snapshotView(afterScreenUpdates: false) else {
            dayPageView.scroll(to: pageIndex)
            return
        }

        snapshotView.isUserInteractionEnabled = false
        snapshotView.frame = dayPageView.frame
        if additionalTimeZoneOption {
            containerView.insertSubview(snapshotView, belowSubview: timeScaleBackgroundView)
        } else {
            containerView.insertSubview(snapshotView, belowSubview: timeScaleView)
        }
        dayPageView.scroll(to: pageIndex, animated: false)
        let dayPageViewFromTransform: CGAffineTransform
        let snapshowToTransform: CGAffineTransform
        if pageIndex >= adjacentUpperBound {
            // 模拟向右翻页
            dayPageViewFromTransform = .init(translationX: dayPageView.frame.width, y: 0)
            snapshowToTransform = .init(translationX: -dayPageView.frame.width, y: 0)
        } else {
            // 模拟向左翻页
            dayPageViewFromTransform = .init(translationX: -dayPageView.frame.width, y: 0)
            snapshowToTransform = .init(translationX: dayPageView.frame.width, y: 0)
        }
        dayPageView.transform = dayPageViewFromTransform
        UIView.animate(withDuration: 0.25, animations: {
            self.dayPageView.transform = .identity
            snapshotView.transform = snapshowToTransform
        }, completion: { _ in
            snapshotView.removeFromSuperview()
            self.dayPageView.transform = .identity
        })
        CalendarTracer.shared.calMainClick(type: .day_change)
    }

    private func bindStoreAction() {
        viewModel.dayStore.responds { [weak self] (action, _) in
            guard let self = self else { return }
            switch action {
            case .adjustAllDayVisibleHeight(let height):
                var inset = self.containerView.contentInset
                inset.top = max(0, height)
                UIView.animate(withDuration: DayScene.UIStyle.Const.allDayAnimationDuration) {
                    self.containerView.contentInset = inset
                }
                if let longPressForwardVC = self.longPress.forwardChild {
                    longPressForwardVC.visibleRectInView = longPressForwardVC.view.bounds.inset(by: inset)
                }
            case .scrollToNow:
                let currentTimeScale = self.viewModel.currentTimeScale()
                let currentDay = self.viewModel.dayStore.state.currentDay
                let activeDay = self.viewModel.dayStore.state.activeDay
                if currentDay != activeDay {
                    self.scrollContainerView(to: currentTimeScale, animated: false)
                    self.scrollPageViewAnimated(to: currentDay)
                } else {
                    self.scrollContainerView(to: currentTimeScale, animated: true)
                }
            case .scrollToDay(let julianDay):
                DispatchQueue.main.async {
                    self.scrollPageViewAnimated(to: julianDay)
                }
            case .scrollToDate(let date):
                DispatchQueue.main.async {
                    let dateComps = Calendar.gregorianCalendar.dateComponents(in: self.viewModel.dayStore.state.timeZoneModel.timeZone, from: date)
                    let julianDay = JulianDayUtil.julianDay(from: date, in: self.viewModel.dayStore.state.timeZoneModel.timeZone)
                    self.scrollPageViewAnimated(to: julianDay)
                    if let timeScale = TimeScale(components: (dateComps.hour ?? 0, dateComps.minute ?? 0, dateComps.second ?? 0)) {
                        self.scrollContainerView(to: timeScale, animated: true)
                    }
                }
            case .clearEditingContext:
                self.clearEditingContext()
            default:
                break
            }
        }.disposed(by: disposeBag)
    }

}

// MARK: - PageView: DataSource

extension DayNonAllDayViewController: PageViewDataSource {

    func itemView(at index: PageIndex, in pageView: PageView, loggerModel: CaVCLoggerModel) -> UIView {
        let viewData: DayNonAllDayViewDataType
        var viewDataDisposable: Disposable?
        switch viewModel.pageViewData(for: index, loggerModel: loggerModel) {
        case .value(let vd):
            viewData = vd
        case .requesting(let disposable, let placeholder):
            viewData = placeholder
            viewDataDisposable = disposable
        }
        let dayView = viewPool.dayItem.pop(byKey: viewData.julianDay)
        dayView.viewData = viewData
        dayView.viewDataDisposable?.dispose()
        dayView.viewDataDisposable = viewDataDisposable
        let julianDayTimeScale = viewModel.rxJulianDayTimeScale.value
        if viewData.julianDay == julianDayTimeScale.julianDay {
            attachRedLine(to: dayView, with: julianDayTimeScale.timeScale)
        }
        return dayView
    }

    final class PageViewDataSourceProxy: PageViewDataSource {
        fileprivate weak var target: PageViewDataSource?
        init(target: PageViewDataSource) {
            self.target = target
        }

        func itemView(at index: PageIndex, in pageView: PageView, loggerModel: CaVCLoggerModel) -> UIView {
            return target?.itemView(at: index, in: pageView, loggerModel: loggerModel) ?? DayNonAllDayView(frame: .zero)
        }
    }

}

// MARK: - PageView: Delegate

extension DayNonAllDayViewController: PageViewDelegate {

    func pageViewWillBeginDragging(_ pageView: BasePageView) {
        clearEditingContext()
    }

    func pageView(_ pageView: PageView, didChangePageOffset pageOffset: PageOffset) {
        onPageOffsetChange?(pageOffset, self)
    }

    func pageView(_ pageView: PageView, didChangeVisiblePageRange visiblePageRange: CAValue<PageRange>) {
        viewModel.rxVisiblePageRange.accept(visiblePageRange)
    }

    func pageView(_ pageView: PageView, didUnload itemView: UIView, at index: PageIndex) {
        guard let pageItemView = itemView as? DayNonAllDayView,
            let julianDay = pageItemView.viewData?.julianDay else {
            DayScene.assertionFailure()
            return
        }
        if redLineView.superview == pageItemView {
            redLineView.removeFromSuperview()
        }
        pageItemView.viewDataDisposable?.dispose()
        pageItemView.viewDataDisposable = nil
        viewPool.dayItem.push(pageItemView, forKey: julianDay)
    }

    func pageViewWillBeginFixingIndex(_ pageView: BasePageView, targetIndex: PageIndex, animated: Bool) {
        CalendarTracer.shared.calMainClick(type: .day_change)
    }
}

// MARK: - DayNonAllDayView: Delegate

extension DayNonAllDayViewController: DayNonAllDayViewDelegate {

    func dayView(_ dayView: DayNonAllDayView, didTap instanceView: DayNonAllDayInstanceView, with uniqueId: String) {
        guard let julianDay = dayView.viewData?.julianDay else {
            DayScene.assert(false, "dayView.viewData should not be nil", type: .showDetailFailed)
            return
        }
        guard let model = viewModel.model(forUniqueId: uniqueId, in: julianDay) else {
            DayScene.assert(false, "model should not be nil", type: .showDetailFailed)
            return
        }
        viewModel.dayStore.dispatch(.showDetail(instance: model))
    }
    
    func dayView(_ dayView: DayNonAllDayView, tapIconDidTap instanceView: DayNonAllDayInstanceView, with uniqueId: String, isSelected: Bool) {
        guard let julianDay = dayView.viewData?.julianDay else {
            DayScene.assert(false, "dayView.viewData should not be nil", type: .tapIconTappedFailed)
            return
        }
        guard let model = viewModel.model(forUniqueId: uniqueId, in: julianDay) else {
            DayScene.assert(false, "model should not be nil", type: .tapIconTappedFailed)
            return
        }
        viewModel.dayStore.dispatch(.tapIconTapped(instance: model, isSelected: isSelected))
    }

    func dayView(_ dayView: DayNonAllDayView, instanceViewFor uniqueId: String) -> DayNonAllDayInstanceView {
        guard let julianDay = dayView.viewData?.julianDay else {
            DayScene.assertionFailure("dayView.viewData should not be nil")
            return viewPool.instanceItem.pop(byKey: uniqueId)
        }
        let instanceView = viewPool.instanceItem.pop(byKey: uniqueId)
        // 根据 editingContext 判断该日程块是否处于编辑中
        if let editingContext = editingContextFromForwardChild(),
            editingContext.julianDay == julianDay,
            editingContext.instanceUniqueId == uniqueId {
            attachEditingMask(to: instanceView)
        }
        return instanceView
    }

    func dayView(_ dayView: DayNonAllDayView, didUnload instanceView: DayNonAllDayInstanceView) {
        DayScene.assert(instanceView.superview == nil)
        if instanceView.superview != nil {
            instanceView.removeFromSuperview()
        }
        removeEditingMask(from: instanceView)
        guard let uniqueId = instanceView.viewData?.uniqueId else {
            assertionFailure()
            return
        }
        viewPool.instanceItem.push(instanceView, forKey: uniqueId)
    }

}

// MARK: - Editing: TapGesture

extension  DayNonAllDayViewController {

    // 处理 containerView 空白处的点击（结束编辑、或者快速新建）
    @objc
    private func handleTapInContainerView(_ tap: UITapGestureRecognizer) {
        if let longPressForwardVC = longPress.forwardChild, longPressForwardVC.parent == self {
            // 正处于编辑状态，结束编辑
            longPressForwardVC.tryToFinishEdit()
        } else {
            // 快速新建日程
            let durationMinute = Int(settingService.getSetting().defaultEventDuration)
            let pointInContainer = tap.location(in: containerView)
            var fromTimeScale = timeScale(forPoint: pointInContainer).floor(toGranularity: .hour_2)
            var toTimeScaleOffset = fromTimeScale.offset + TimeScale.pointsPerMinute * durationMinute
            if toTimeScaleOffset > TimeScale.maxOffset {
                toTimeScaleOffset = TimeScale.maxOffset
                fromTimeScale = TimeScale(refOffset: toTimeScaleOffset - TimeScale.pointsPerMinute * durationMinute)
            }
            let toTimeScale = TimeScale(refOffset: toTimeScaleOffset)
            let page = pageIndex(forPoint: pointInContainer)
            let rect = rectInContainerView(from: fromTimeScale..<toTimeScale, in: page)

            let vc = initEditingChild(for: nil)
            vc.prepareForCreating(from: rect)

            vc.visibleRectInView = vc.view.bounds.inset(by: containerView.contentInset)
            longPress.forwardChild = vc
        }
    }

}

// MARK: - Editing: LongPressGesture

extension DayNonAllDayViewController: UIGestureRecognizerDelegate {

    private func attachLongPressGesture() {
        longPress.gesture.addTarget(self, action: #selector(handleLongPress(_:)))
        longPress.gesture.cancelsTouchesInView = false
        longPress.gesture.delegate = self
        longPress.captureView.addGestureRecognizer(longPress.gesture)
    }

    @objc
    private func handleLongPress(_ longPressGesture: UILongPressGestureRecognizer) {
        guard longPress.gesture == longPressGesture else { return }
        if case .began = longPressGesture.state {
            guard let instanceView = longPress.captureView.lastHitTestView as? DayNonAllDayInstanceView else { return }

            guard let julianDay = (instanceView.superview as? DayNonAllDayView)?.viewData?.julianDay,
                let uniqueId = instanceView.viewData?.uniqueId else {
                DayScene.assertionFailure()
                DayScene.assert((instanceView.superview as? DayNonAllDayView) != nil)
                DayScene.assert((instanceView.superview as? DayNonAllDayView)?.viewData != nil)
                DayScene.assert(instanceView.viewData != nil)
                return
            }

            // remove instance edit child if needed
            clearEditingContext()

            AudioServicesPlaySystemSound(1520)
            if let alertTip = viewModel.blockTipForEditingInstance(withUniqueId: uniqueId, in: julianDay) {
                // https://stackoverflow.com/questions/26455880/how-to-make-iphone-vibrate-using-swift/39957091#39957091
                UDToast.showTips(with: alertTip, on: view)

                // cancel gesture
                longPressGesture.isEnabled = false
                longPressGesture.isEnabled = true
                return
            }

            guard let model = viewModel.model(forUniqueId: uniqueId, in: julianDay) else {
                DayScene.assertionFailure()
                return
            }

            // webinar 日程禁用拖拽
             if (model as? Instance)?.isWebinar == true {
                return
            }

            attachEditingMask(to: instanceView)

            let vc = initEditingChild(for: model)

            let snapshotView = DayNonAllDayInstanceView()
            snapshotView.calendarSelectTracer = viewModel.calendarSelectTracer
            var viewData = instanceView.viewData
            // 这里需要重新生成UI，以免和之前的UI复用同一个attament
            viewData?.updateUI()
            snapshotView.viewData = viewData
            snapshotView.frame = instanceView.frame

            vc.prepareForEditing(from: instanceView, snapshotView: snapshotView, editingContext: (julianDay, uniqueId))
            vc.visibleRectInView = vc.view.bounds.inset(by: containerView.contentInset)
            longPress.forwardChild = vc

            longPress.forwardChild?.handleLongPress(longPressGesture)
        } else {
            longPress.forwardChild?.handleLongPress(longPressGesture)
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard longPress.gesture == gestureRecognizer else { return true }
        guard let instanceView = longPress.captureView.lastHitTestView as? DayNonAllDayInstanceView else {
            return false
        }
        let instanceViewRectInCaptureView = longPress.captureView.convert(instanceView.frame, from: instanceView.superview)
        let gestureLocationInCaptureView = gestureRecognizer.location(in: longPress.captureView)
        guard instanceViewRectInCaptureView.contains(gestureLocationInCaptureView) else {
            // DayScene.assertionFailure()
            return false
        }

        return true
    }

}

// MARK: - Editing: InstanceEditChild Adding/Removeing

extension DayNonAllDayViewController {

    private func removeEditingMask(from instanceView: UIView) {
        if editingMaskView.superview == instanceView {
            editingMaskView.removeFromSuperview()
        }
    }

    private func attachEditingMask(to instanceView: UIView) {
        instanceView.addSubview(editingMaskView)
        editingMaskView.frame = instanceView.bounds
    }

    private func editingContextFromForwardChild() -> (julianDay: JulianDay, instanceUniqueId: String)? {
        guard let forwardChild = longPress.forwardChild, forwardChild.parent == self else { return nil }
        return forwardChild.editingContext
    }

    private func initEditingChild(for instance: BlockDataProtocol?) -> DayInstanceEditViewController {
        let vc = DayInstanceEditViewController(
            viewModel: DayInstanceEditViewModel(
                calendarApi: calendarApi,
                userResolver: viewModel.userResolver,
                timeZone: viewModel.dayStore.state.timeZoneModel.timeZone,
                is12HourStyle: self.rxIs12HourStyle.value,
                instance: instance
            ),
            containerView: containerView,
            pageView: dayPageView
        )

        vc.delegate = self
        vc.containerViewPadding = UIEdgeInsets(
            top: DayScene.UIStyle.Layout.timeScaleCanvas.vPadding.top,
            left: 0,
            bottom: DayScene.UIStyle.Layout.timeScaleCanvas.vPadding.bottom,
            right: 0
        )
        vc.minDurationHeight = self.settingService.getSetting().defaultEventDuration < 30 ?
            timeScaleView.heightPerHour / 4 : timeScaleView.heightPerHour / 2
        addChild(vc)
        view.addSubview(vc.view)
        vc.view.frame = view.bounds
        vc.didMove(toParent: self)
        return vc
    }

    // 清除 editing 相关内容
    private func clearEditingContext() {
        timeScaleView.setSelectedTimeScaleRange(nil)
        if additionalTimeZoneOption {
            additionalTimeScaleView.setSelectedTimeScaleRange(nil)
        }
        editingMaskView.removeFromSuperview()

        guard let vc = longPress.forwardChild else { return }
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
        longPress.forwardChild = nil
    }

}

// MARK: - Editing: InstanceEditChild Delegate

extension DayNonAllDayViewController: DayInstanceEditViewControllerDelegate {

    func timeScaleRange(forRect rectInContainerView: CGRect) -> TimeScaleRange {
        var fromTimeScale = timeScale(forPoint: rectInContainerView.topLeft)
        var toTimeScale = timeScale(forPoint: rectInContainerView.bottomLeft)
        let points = timeScalePoints(fromHeight: rectInContainerView.height)
        if fromTimeScale == .mininum {
            toTimeScale = fromTimeScale.adding(points)
        }
        if toTimeScale == .maxinum {
            fromTimeScale = toTimeScale.adding(-points)
        }
        return fromTimeScale..<toTimeScale
    }

    func showVC(_ vc: UIViewController) {
        viewModel.userResolver.navigator.present(vc, from: self)
    }
    
    func julianDay(forRect rectInContainerView: CGRect) -> JulianDay {
        return DayScene.julianDay(from: pageIndex(forPoint: rectInContainerView.center))
    }

    func rectInContainerView(for timeScaleRange: TimeScaleRange, in julianDay: JulianDay) -> CGRect {
        let pageIndex = DayScene.pageIndex(from: julianDay)
        return rectInContainerView(from: timeScaleRange, in: pageIndex)
    }

    func timeScaleRangeDidChange(_ timeScaleRange: TimeScaleRange) {
        let fixedFrom = timeScaleRange.lowerBound.round(toGranularity: .hour_4)
        var fixedTo = timeScaleRange.upperBound.round(toGranularity: .hour_4)
        if fixedTo == fixedFrom {
            fixedTo = fixedFrom.adding(TimeScale.Granularity.hour_4.rawValue)
        }
        timeScaleView.setSelectedTimeScaleRange(fixedFrom..<fixedTo)
        if additionalTimeZoneOption {
            additionalTimeScaleView.setSelectedTimeScaleRange(fixedFrom..<fixedTo)
        }
    }

    func didCancelEdit(from viewController: DayInstanceEditViewController) {
        clearEditingContext()
    }

    func didFinishEdit(from viewController: DayInstanceEditViewController) {
        clearEditingContext()
    }

    func createEvent(withStartDate startDate: Date, endDate: Date, from viewController: DayInstanceEditViewController) {
        viewModel.dayStore.dispatch(.createEvent(startDate: startDate, endDate: endDate))
        clearEditingContext()
    }

}

// MARK: - Editing: Utils

extension DayNonAllDayViewController {

    // 关于 TimeScale 的计算是基于 timeScaleView 进行的

    // 根据 height 计算所对应的 TimeScale.Point
    private func timeScalePoints(fromHeight height: CGFloat) -> TimeScale.Point {
        guard height >= 0 else { return 0 }
        let hour = height / timeScaleView.heightPerHour
        let points = TimeScale.Point(hour * CGFloat(TimeScale.pointsPerHour))
        return min(points, (TimeScale.maxOffset - TimeScale.minOffset))
    }

    // 根据 point 计算 TimeScale
    private func timeScale(forPoint pointInsideContainerView: CGPoint) -> TimeScale {
        let pointInTimeScaleView = timeScaleView.convert(pointInsideContainerView, from: containerView)
        let timeScaleOffset = (pointInTimeScaleView.y - timeScaleView.vPadding.top)
            / timeScaleView.heightPerHour * CGFloat(TimeScale.pointsPerHour)
        return TimeScale(refOffset: Int(timeScaleOffset))
    }

    // 根据 point 计算 PageIndex
    private func pageIndex(forPoint pointInsideContainerView: CGPoint) -> PageIndex {
        for pageIndex in dayPageView.visiblePageRange {
            guard let pageItemView = dayPageView.itemView(at: pageIndex) else {
                continue
            }
            let pageRectInContainerView = containerView.convert(pageItemView.frame, from: pageItemView.superview)
            if pageRectInContainerView.contains(pointInsideContainerView) {
                return pageIndex
            }
        }
        return dayPageView.visiblePageRange.lowerBound
    }

    // 根据 TimeScale 和 PageIndex 计算 rect
    private func rectInContainerView(from timeScaleRange: TimeScaleRange, in page: PageIndex) -> CGRect {
        let minYInTimeScaleView = timeScaleView.vPadding.top
            + timeScaleView.heightPerHour * CGFloat(timeScaleRange.lowerBound.offset) / CGFloat(TimeScale.pointsPerHour)
        let minY = containerView.convert(CGPoint(x: 0, y: minYInTimeScaleView), from: timeScaleView).y
        let height = CGFloat(timeScaleRange.points) / CGFloat(TimeScale.pointsPerHour) * timeScaleView.heightPerHour

        let minX: CGFloat
        let width: CGFloat

        if let pageItemView = dayPageView.itemView(at: page) {
            let pageRectInContainerView = containerView.convert(pageItemView.frame, from: pageItemView.superview)
            minX = pageRectInContainerView.left + DayNonAllDayView.padding.left
            width = pageRectInContainerView.width - DayNonAllDayView.padding.left - DayNonAllDayView.padding.right
        } else {
            DayScene.assertionFailure("pageItemView should not be nil")
            minX = 0
            width = containerView.frame.width
        }
        // TimeScale最小单位是秒，一天有86400秒，对应画布高度1200
        // 所以高度的精度误差会被放大，导致经常少了几秒进而分钟数也-1，这里取个整
        return CGRect(x: minX, y: round(minY), width: width, height: round(height))
    }

}

// MARK: - Extension viewDataDisposable

extension DayNonAllDayView {

    static var disposableKey = "disposableKey"

    // 为 DayNonAllDayView 扩展 disposable。使用场景：当 DayNonAllDayView 被 unload 时，将其相关异步任务给取消掉
    var viewDataDisposable: Disposable? {
        get {
            objc_getAssociatedObject(self, &Self.disposableKey) as? Disposable
        }
        set {
            objc_setAssociatedObject(self, &Self.disposableKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

}

// MARK: - Cold Launch

extension DayNonAllDayViewController {

    final class ColdLaunchDataSource: PageViewDataSource {
        // 目标 viewController
        private unowned var target: DayNonAllDayViewController
        // 冷启动上下文信息
        private var context: HomeScene.ColdLaunchContext
        // 首屏 viewDataMap
        private var viewDataMap: SafeDictionary<JulianDay, DayNonAllDayViewDataType> = [:] + .readWriteLock
        private let disposeBag = DisposeBag()

        init( target: DayNonAllDayViewController, context: HomeScene.ColdLaunchContext) {
            self.target = target
            self.context = context
        }

        fileprivate func prepareViewData(with completion: @escaping (Bool, CaVCLoggerModel) -> Void) {
            let originLoggerModel = context.loggerModel
            target.viewModel.rxColdLaunchViewData(with: context)
                .subscribe(
                    onSuccess: { [weak self] res in
                        self?.viewDataMap.safeWrite(all: { dataMap in
                            dataMap.removeAll()
                            res.value.forEach { item in
                                dataMap[item.key] = item.value
                            }
                        })
                        completion(true, res.loggerModel)
                        EffLogger.log(model: res.loggerModel, toast: "Succeed in preparing cold launch viewData for nonAllDay Module")
                        DayScene.logger.info("Succeed in preparing cold launch viewData for nonAllDay Module")
                    },
                    onError: { err in
                        completion(false, originLoggerModel)
                        DayScene.logger.error("Failed to prepare cold launch viewData for nonAllDay Module. err: \(err)")
                    }
                )
                .disposed(by: disposeBag)
        }

        func itemView(at index: PageIndex, in pageView: PageView, loggerModel: CaVCLoggerModel) -> UIView {
            let julianDay = DayScene.julianDay(from: index)
            let dayView = target.viewPool.dayItem.pop(byKey: julianDay)
            if let viewData = viewDataMap[julianDay] {
                dayView.viewData = viewData
            } else {
                dayView.viewData = target.viewModel.emptyPageViewData(for: julianDay)
            }

            let julianDayTimeScale = target.viewModel.rxJulianDayTimeScale.value
            if julianDay == julianDayTimeScale.julianDay {
                target.attachRedLine(to: dayView, with: julianDayTimeScale.timeScale)
            }
            return dayView
        }

    }

}
