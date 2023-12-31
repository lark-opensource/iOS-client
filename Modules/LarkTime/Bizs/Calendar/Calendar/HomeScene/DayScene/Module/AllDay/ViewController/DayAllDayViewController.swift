//
//  DayAllDayViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/7/9.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import UniverseDesignIcon
import UIKit
import RxSwift
import RxCocoa
import CTFoundation

/// DayScene - AllDay - ViewController

final class DayAllDayViewController: UIViewController, DayScenePagableChild {

    typealias ViewModel = DayAllDayViewModel

    let viewModel: ViewModel
    var onPageOffsetChange: PageOffsetSyncer?

    private(set) var visibleHeight = CGFloat(0)
    private let layout = (
        rowHeight: CGFloat(22),
        rowSpacing: CGFloat(3),
        pageViewMargin: (top: CGFloat(3), bottom: CGFloat(3))
    )

    private let containerView = UIView()
    private lazy var leftPartViews = initLeftPartViews()
    private lazy var verticalScrollView = initVerticalScrollView()
    private lazy var bottomShadowView = initBottomShadowView()
    private lazy var dayPageView = initDayPageView()
    private let disposeBag = DisposeBag()
    private var requestingDisposables = [PageRange: Disposable]()
    private let rxIs12HourStyle: BehaviorRelay<Bool>

    private lazy var viewPool = (
        instanceItem: initInstanceItemViewPool(),
        expandTipItem: initExpandTipItemViewPool()
    )

    private lazy var pageViewDataSourceProxy = PageViewDataSourceProxy(target: self)
    private var coldLaunchDataSource: ColdLaunchDataSource?
    private var leftViewWidth: CGFloat = 0
    private lazy var additionalTimeZoneOption = FeatureGating.additionalTimeZoneOption(userID: viewModel.userResolver.userID)

    init(viewModel: DayAllDayViewModel, rxIs12HourStyle: BehaviorRelay<Bool>) {
        self.viewModel = viewModel
        self.rxIs12HourStyle = rxIs12HourStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        initItemDrawRect()
        bindViewData()
        coldLaunchIfNeeded()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        leftViewWidth = calculateleftViewWidth()
        setLeftPartViewsFrame()
        updateVerticalScrollViewFrame()
        updateDayPageViewFrame()
    }

    // 描述计算 itemDrawRect 所依赖的数据
    private var lastItemDrawRectInputs = (pageWidth: CGFloat, rowHeight: CGFloat)?.none
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bottomShadowView.layer.shadowPath = UIBezierPath(rect: bottomShadowView.bounds).cgPath

        // async 处理，确保 dayPageView.pageSize 是稳定准确的
        DispatchQueue.main.async {
            let pageWidth = self.dayPageView.pageSize.width
            let rowHeight = self.dayPageView.rowHeight
            guard self.lastItemDrawRectInputs?.pageWidth != pageWidth
                || self.lastItemDrawRectInputs?.rowHeight != rowHeight else {
                return
            }
            DayScene.logger.info("item draw rect changed. (\(pageWidth)-\(rowHeight))-\(self.view.bounds.size)")
            self.lastItemDrawRectInputs = (pageWidth, rowHeight)
            let getter = { (pageCount: Int) -> CGRect in
                let size = CGSize(width: pageWidth * CGFloat(pageCount), height: rowHeight)
                return CGRect(origin: .zero, size: size)
            }
            self.viewModel.rxItemDrawRectFunc.accept(getter)
        }
    }

    func scroll(to pageOffset: PageOffset, animated: Bool) {
        dayPageView.scroll(to: pageOffset, animated: animated)
    }

    func calculateleftViewWidth() -> CGFloat {
        if additionalTimeZoneOption {
            if let additionaltimeZoneWidth = viewModel.dayStore.state.additionalTimeZone?.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value) {
                return viewModel.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value)
                + additionaltimeZoneWidth
                + DayScene.UIStyle.Layout.showAdditionalTimeZoneSpacingWidth
            } else {
                return viewModel.dayStore.state.timeZoneModel.getTimeZoneWidth(is12HourStyle: rxIs12HourStyle.value)
                + DayScene.UIStyle.Layout.hiddenAdditionalTimeZoneSpacingWidth
            }
        } else {
            return DayScene.UIStyle.Layout.leftPartWidth
        }
    }

    private func coldLaunchIfNeeded() {
        guard let coldLaunchContext = viewModel.dayStore.state.coldLaunchContext else {
            // 不需要走冷启动流程，直接 setup ViewModel
            viewModel.setup()
            return
        }

        // 准备冷启动数据
        let coldLaunchDataSource = ColdLaunchDataSource(target: self, context: coldLaunchContext)
        pageViewDataSourceProxy.target = coldLaunchDataSource
        coldLaunchDataSource.prepareViewData { [weak self] succeed in
            guard let self = self else { return }
            if succeed && self.pageViewDataSourceProxy.target === self.coldLaunchDataSource {
                DayScene.logger.info("will reload pageView with coldLaunch viewData")
                self.dayPageView.reloadData()
            }
        }
        self.coldLaunchDataSource = coldLaunchDataSource

        // 监听 `didFinishColdLaunch` action，由 nonAllDay 模块 dispatch
        // 冷启动完成：切换 dataSource；setup viewModel
        viewModel.dayStore.responds { [weak self] (action, _)  in
            guard case .didFinishColdLaunch = action else { return }
            self?.pageViewDataSourceProxy.target = self
            self?.viewModel.setup()
            self?.viewModel.didFinishColdLaunch()
        }.disposed(by: disposeBag)
    }

    private func setupView() {
        // 确保阴影不被切掉
        view.clipsToBounds = false

        view.addSubview(bottomShadowView)
        bottomShadowView.frame = CGRect(x: 0, y: view.bounds.height - 20, width: view.bounds.width, height: 20)
        bottomShadowView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]

        containerView.backgroundColor = UIColor.ud.bgBody
        containerView.clipsToBounds = true
        containerView.frame = view.bounds
        view.addSubview(containerView)
        containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        updateVerticalScrollViewFrame()
        containerView.addSubview(verticalScrollView)

        containerView.addSubview(leftPartViews.tipLabel)
        containerView.addSubview(leftPartViews.expandButton)

        leftPartViews.expandButton.autoresizingMask = [.flexibleRightMargin, .flexibleTopMargin]
        leftPartViews.expandButton.addTarget(self, action: #selector(toggleExpand), for: .touchUpInside)

        updateDayPageViewFrame()
        verticalScrollView.addSubview(dayPageView)
        let activePageIndex = DayScene.pageIndex(from: viewModel.dayStore.state.activeDay)
        dayPageView.scroll(to: activePageIndex)
    }

    private func setLeftPartViewsFrame() {
        leftPartViews.tipLabel.frame = CGRect(
            x: 0,
            y: layout.pageViewMargin.top,
            width: leftViewWidth,
            height: dayPageView.rowHeight
        )

        leftPartViews.expandButton.frame = CGRect(
            x: 0,
            y: view.frame.height - layout.rowHeight - layout.pageViewMargin.bottom,
            width: leftViewWidth,
            height: layout.rowHeight
        )
    }

    private func initItemDrawRect() {
        let pageViewWidth = UIScreen.main.bounds.width - leftViewWidth
        let pageWidth = pageViewWidth / CGFloat(dayPageView.pageCountPerScene)
        let rowHeight = dayPageView.rowHeight
        lastItemDrawRectInputs = (pageWidth, rowHeight)
        let getter = { (pageCount: Int) -> CGRect in
            let size = CGSize(width: pageWidth * CGFloat(pageCount), height: rowHeight)
            return CGRect(origin: .zero, size: size)
        }
        self.viewModel.rxItemDrawRectFunc.accept(getter)
    }

    private func updateVerticalScrollViewFrame() {
        var vScrollViewFrame = containerView.bounds
        vScrollViewFrame.left = leftViewWidth
        vScrollViewFrame.size.width = containerView.bounds.width - vScrollViewFrame.left
        vScrollViewFrame.size.height = visibleHeight
        verticalScrollView.frame = vScrollViewFrame
    }

    private func updateDayPageViewFrame() {
        let dayPageViewMargin: UIEdgeInsets
        if verticalScrollView.bounds.height > layout.pageViewMargin.top + layout.pageViewMargin.bottom {
            dayPageViewMargin = UIEdgeInsets(
                top: layout.pageViewMargin.top,
                left: 0,
                bottom: layout.pageViewMargin.bottom,
                right: 0
            )
        } else {
            dayPageViewMargin = .zero
        }
        let targetFrame = verticalScrollView.bounds.inset(by: dayPageViewMargin)
        let widthChanged = abs(targetFrame.width - dayPageView.frame.width) > 0.0001
        if widthChanged {
            dayPageView.freezeStateIfNeeded()
            dayPageView.frame = targetFrame
            updatePageItemViewContentOffsets()
            dayPageView.layoutIfNeeded()
            dayPageView.unfreezeStateIfNeeded()
        } else {
            dayPageView.frame = targetFrame
        }
    }

    private func adjustVisibleHeight() {
        updateVerticalScrollViewFrame()
        updateDayPageViewFrame()
    }

    private func bindViewData() {
        // leftPartViews.expandButton 的 isHidden 和 transform
        viewModel.rxExpandViewData.bind { [weak self] tuple in
            guard let self = self else { return }
            let (shouldShow, isExpand) = tuple
            if shouldShow {
                self.leftPartViews.expandButton.isHidden = false
                UIView.animate(withDuration: DayScene.UIStyle.Const.allDayAnimationDuration) { [weak self] in
                    let transform = isExpand ? CGAffineTransform(rotationAngle: CGFloat.pi) : .identity
                    self?.leftPartViews.expandButton.transform = transform
                }
            } else {
                self.leftPartViews.expandButton.isHidden = true
            }
        }.disposed(by: disposeBag)

        viewModel.rxUpdate.sectionAt.bind { [weak self] _ in
            self?.dayPageView.reloadData()
        }.disposed(by: disposeBag)

        viewModel.rxUpdate.allSections
            .bind { [weak self] in
            guard let self = self else { return }
            self.requestingDisposables.forEach { kv in
                kv.value.dispose()
            }
            self.requestingDisposables.removeAll()
            self.dayPageView.configuration = self.viewModel.pageConfiguration
            self.dayPageView.reloadData()
        }.disposed(by: disposeBag)

        if additionalTimeZoneOption {
            viewModel.rxAdditionalTimeZoneRelay
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    self.view.setNeedsLayout()
                    self.view.layoutIfNeeded()
                }).disposed(by: disposeBag)
        }

        Observable.combineLatest(rxIs12HourStyle, viewModel.dayStore.rxValue(forKeyPath: \.timeZoneModel))
            .distinctUntilChanged { (pre, next) -> Bool in
                return pre.0 == next.0 && pre.1 == next.1
            }
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _, _ in
                guard let self = self else { return }
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
            }).disposed(by: disposeBag)
    }
}

// MARK: - Lazy Init

extension DayAllDayViewController {

    private func initLeftPartViews() -> (tipLabel: UILabel, expandButton: UIButton) {
        let tipLabel = UILabel()
        tipLabel.text = BundleI18n.Calendar.Calendar_Edit_Allday
        tipLabel.font = UIFont.cd.semiboldFont(ofSize: 11)
        tipLabel.textAlignment = .center
        tipLabel.textColor = UIColor.ud.textPlaceholder

        let expandButton = UIButton()
        expandButton.setImage(UDIcon.getIconByKeyNoLimitSize(.expandDownFilled)
                                .scaleInfoSize()
                                .renderColor(with: .n3), for: .normal)

        return (tipLabel, expandButton)
    }

    private func initVerticalScrollView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = false
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }

    private func initBottomShadowView() -> UIView {
        let shadowView = UIView()
        shadowView.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        shadowView.layer.shadowOpacity = 0.1
        shadowView.layer.shadowRadius = 5
        shadowView.layer.shadowPath = UIBezierPath(rect: shadowView.bounds).cgPath
        return shadowView
    }

    private func initDayPageView() -> DayAllDayPageView {
        let pageView = DayAllDayPageView(
            totalPageCount: DayScene.UIStyle.Const.dayPageCount,
            configuration: viewModel.pageConfiguration
        )
        pageView.name = "DayScene.AllDay"
        pageView.isDeceleratingEnabled = false
        pageView.pageCountPerScene = viewModel.dayStore.state.daysPerScene
        pageView.rowHeight = layout.rowHeight
        pageView.rowSpacing = layout.rowSpacing
        pageView.dataSource = self
        pageView.delegate = self
        pageView.clipsToBounds = true
        return pageView
    }

     private func initInstanceItemViewPool() -> KeyedPool<InstanceCacheKey, DayAllDayInstanceView> {
         #if DEBUG
         var count = 0
         #endif
         return KeyedPool<InstanceCacheKey, DayAllDayInstanceView>(capacity: 3 * 7) { [weak self] _ in
             let view = DayAllDayInstanceView()
             view.calendarSelectTracer = self?.viewModel.calendarSelectTracer
             view.onClick = { uniqueId, location in
                 self?.handleItemClick(uniqueId, location: location)
             }
             #if DEBUG
             count += 1
             debugPrint("No.\(count) DayAllDayInstanceView is created")
             #endif
             return view
         }
     }

     private func initExpandTipItemViewPool() -> KeyedPool<JulianDay, DayAllDayExpandTipView> {
         #if DEBUG
         var count = 0
         #endif
        return KeyedPool<JulianDay, DayAllDayExpandTipView>(capacity: 7) { [weak self] _ in
            let view = DayAllDayExpandTipView()
            view.onClick = { () in
                self?.handleExpandTipClick()
            }
             #if DEBUG
             count += 1
             debugPrint("No.\(count) DayAllDayExpandTipView is created")
             #endif
            return view
        }
    }

}

// MARK: - PageView: DataSource

extension DayAllDayViewController: DayAllDayPageViewDataSource {

    private struct PageViewItem: DayAllDayPageViewItemType {
        var view: UIView
        var layout: DayAllDayPageItemLayout
    }

    func pageView(_ pageView: DayAllDayPageView, itemsIn section: Int) -> [DayAllDayPageViewItemType] {
        let pageItems: [DayAllDayViewModel.SectionItem]
        switch viewModel.pageItems(in: section) {
        case .value(let items):
            pageItems = items
        case .requesting(let disposable, let placeholder):
            let pageRange = pageView.configuration.getPageRangeFromSection(section)
            requestingDisposables[pageRange]?.dispose()
            requestingDisposables[pageRange] = disposable
            pageItems = placeholder
        }
        return pageItems.map { pageItem -> PageViewItem in
            let layout = pageItem.layout
            switch pageItem {
            case .instanceViewData(let instanceItem):
                // 日程块
                let key = InstanceCacheKey(uniqueId: instanceItem.uniqueId, pageRange: pageItem.layout.pageRange)
                let view = viewPool.instanceItem.pop(byKey: key)
                view.viewData = instanceItem
                if let instanceViewData = instanceItem as? DayAllDayViewModel.InstanceViewData {
                    setContentOffset(for: view, with: instanceViewData.layout.pageRange)
                } else if let timeBlockViewData = instanceItem as? DayAllDayViewModel.TimeBlockViewData {
                    setContentOffset(for: view, with: timeBlockViewData.layout.pageRange)
                }
                return PageViewItem(view: view, layout: layout)
            case .collapsedTip(let tipItem):
                // 展开 tip
                let view = viewPool.expandTipItem.pop(byKey: pageItem.layout.pageRange.lowerBound)
                view.title = tipItem.title
                return PageViewItem(view: view, layout: layout)
            }
        }
    }

    final class PageViewDataSourceProxy: DayAllDayPageViewDataSource {
        fileprivate weak var target: DayAllDayPageViewDataSource?
        init(target: DayAllDayPageViewDataSource) {
            self.target = target
        }

        func pageView(_ pageView: DayAllDayPageView, itemsIn section: Int) -> [DayAllDayPageViewItemType] {
            return target?.pageView(pageView, itemsIn: section) ?? []
        }
    }

}

// MARK: - PageView: Delegate

extension DayAllDayViewController: DayAllDayPageViewDelegate {

    func pageView(_ pageView: DayAllDayPageView, didChangeVisibleRowCount visibleRowCount: Int) {
        var visibleHeight = pageView.rowHeight * CGFloat(visibleRowCount)
            + CGFloat(max(0, visibleRowCount - 1)) * pageView.rowSpacing
        if visibleRowCount > 0 {
            visibleHeight += (layout.pageViewMargin.top + layout.pageViewMargin.bottom)
        }
        self.visibleHeight = visibleHeight
        adjustVisibleHeight()
        self.viewModel.dayStore.dispatch(.adjustAllDayVisibleHeight(height: visibleHeight), on: MainScheduler.asyncInstance)
    }

    func pageView(_ pageView: DayAllDayPageView, didChangePageOffset pageOffset: PageOffset) {
        onPageOffsetChange?(pageOffset, self)
        updatePageItemViewContentOffsets()
    }

    func pageView(_ pageView: DayAllDayPageView, didChangeVisiblePageRange visiblePageRange: PageRange) {
        for key in requestingDisposables.keys where !key.overlaps(visiblePageRange) {
            requestingDisposables[key]?.dispose()
            requestingDisposables[key] = nil
        }
        viewModel.rxVisiblePageRange.accept(visiblePageRange)
        viewModel.updateExpandHidden()
    }

    func pageView(_ pageView: DayAllDayPageView, didLoad itemView: UIView, for layout: DayAllDayPageItemLayout) {
        viewModel.updateExpandHidden()
    }

    func pageView(_ pageView: DayAllDayPageView, didUnload itemView: UIView, for layout: DayAllDayPageItemLayout) {
        recycleItemView(itemView, with: layout)
    }

}

// MARK: - Manage Item Views

extension DayAllDayViewController {

    private struct InstanceCacheKey: Hashable {
        let uniqueId: String
        let pageRange: PageRange

        func hash(into hasher: inout Hasher) {
            hasher.combine(uniqueId)
            hasher.combine(pageRange.lowerBound)
            hasher.combine(pageRange.upperBound)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.uniqueId == rhs.uniqueId && lhs.pageRange == rhs.pageRange
        }
    }

    private func recycleItemView(_ itemView: UIView, with layout: DayAllDayPageItemLayout) {
        if let instanceView = itemView as? DayAllDayInstanceView {
            guard let uniqueId = instanceView.viewData?.uniqueId else {
                assertionFailure()
                return
            }
            let key = InstanceCacheKey(uniqueId: uniqueId, pageRange: layout.pageRange)
            viewPool.instanceItem.push(instanceView, forKey: key)
            DayScene.logger.info("recycle unloaded DayAllDayInstanceView at: \(layout)")
        } else if let expandTipView = itemView as? DayAllDayExpandTipView {
            viewPool.expandTipItem.push(expandTipView, forKey: layout.pageRange.lowerBound)
            DayScene.logger.info("recycle unloaded DayAllDayInstanceView at: \(layout)")
        } else {
            assertionFailure("do nothing")
        }
    }

}

// MARK: - Misc

extension DayAllDayViewController {

    // MARK: ContentOffset for InstanceView

    private func setContentOffset(for instanceView: DayAllDayInstanceView, with pageRange: PageRange) {
        let deltaOffset = dayPageView.pageOffset - CGFloat(pageRange.lowerBound)
        let fixedDeltaOffset = max(0, min(deltaOffset, CGFloat(pageRange.count - 1)))
        instanceView.contentOffsetX = dayPageView.pageSize.width * fixedDeltaOffset
    }

    private func updatePageItemViewContentOffsets() {
        for item in dayPageView.loadedItemViews() {
            guard let instanceView = item.view as? DayAllDayInstanceView else {
                continue
            }
            setContentOffset(for: instanceView, with: item.layout.pageRange)
        }
    }

    @objc
    private func toggleExpand() {
        DayScene.logger.info("expand button clicked")
        viewModel.toggleExpand()
    }

    private func handleExpandTipClick() {
        DayScene.logger.info("expand tip button clicked")
        viewModel.toggleExpand()
    }

    private func handleItemClick(_ uniqueId: String, location: DayAllDayInstanceView.TapLocation) {
        guard let instance = viewModel.model(forUniqueId: uniqueId) else {
            let assertMsg = "get instance failed. uniqueId \(uniqueId), visiblePageRange: \(dayPageView.visiblePageRange)"
            DayScene.assert(false, assertMsg, type: .showDetailFailed)
            return
        }
        switch location {
        case .icon(let isSelected):
            viewModel.dayStore.dispatch(.tapIconTapped(instance: instance, isSelected: isSelected))
        case .view:
            viewModel.dayStore.dispatch(.showDetail(instance: instance))
        }
    }

}

// MARK: - Cold Launch

extension DayAllDayViewController {

    final class ColdLaunchDataSource: DayAllDayPageViewDataSource {
        // 目标 viewController
        private unowned var target: DayAllDayViewController
        // 冷启动上下文信息
        private var context: HomeScene.ColdLaunchContext
        // 首屏 viewDataMap
        private var viewDataMap = [ViewModel.Section: ViewModel.SectionViewData]()
        private let disposeBag = DisposeBag()

        init( target: DayAllDayViewController, context: HomeScene.ColdLaunchContext) {
            self.target = target
            self.context = context
        }

        fileprivate func prepareViewData(with completion: @escaping (Bool) -> Void) {
            target.viewModel.rxColdLaunchViewData(with: context)
                .subscribe(
                    onSuccess: { [weak self] viewDataMap in
                        self?.viewDataMap = viewDataMap
                        completion(true)
                        DayScene.logger.info("Succeed in preparing cold launch viewData for allDay Module")
                    },
                    onError: { err in
                        completion(false)
                        DayScene.logger.error("Failed to prepare cold launch viewData for allDay Module. err: \(err)")
                    }
                )
                .disposed(by: disposeBag)
        }

        func pageView(_ pageView: DayAllDayPageView, itemsIn section: Int) -> [DayAllDayPageViewItemType] {
            guard let sectionViewData = viewDataMap[section] else {
                return []
            }
            return sectionViewData.collapsedItems.map { pageItem -> PageViewItem in
                let layout = pageItem.layout
                switch pageItem {
                case .instanceViewData(let instanceItem):
                    // 日程块
                    let key = InstanceCacheKey(uniqueId: instanceItem.uniqueId, pageRange: pageItem.layout.pageRange)
                    let view = target.viewPool.instanceItem.pop(byKey: key)
                    view.viewData = instanceItem
                    if let instanceViewData = instanceItem as? DayAllDayViewModel.InstanceViewData {
                        target.setContentOffset(for: view, with: instanceViewData.layout.pageRange)
                    } else if let timeBlockViewData = instanceItem as? DayAllDayViewModel.TimeBlockViewData {
                        target.setContentOffset(for: view, with: timeBlockViewData.layout.pageRange)
                    }
                    return PageViewItem(view: view, layout: layout)
                case .collapsedTip(let tipItem):
                    // 展开 tip
                    let view = target.viewPool.expandTipItem.pop(byKey: pageItem.layout.pageRange.lowerBound)
                    view.title = tipItem.title
                    return PageViewItem(view: view, layout: layout)
                }
            }
        }

    }

}
