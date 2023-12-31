//
//  DayInstanceEditViewController.swift
//  Calendar
//
//  Created by 张威 on 2020/8/12.
//

import UIKit
import RxSwift
import RxCocoa
import LarkExtensions
import QuartzCore
import LarkFoundation
import UniverseDesignToast

/// DayScene - InstanceEdit - ViewController

protocol DayInstanceEditViewControllerDelegate: AnyObject {
    // 根据 rect 获取 TimeScaleRange
    func timeScaleRange(forRect rectInContainerView: CGRect) -> TimeScaleRange
    // 根据 rect 获取 JulianDy
    func julianDay(forRect rectInContainerView: CGRect) -> JulianDay
    // 根据 TimeScaleRange 和 JulianDay 获取 rect
    func rectInContainerView(for timeScaleRange: TimeScaleRange, in julianDay: JulianDay) -> CGRect
    // TimeScaleRange 发生变化
    func timeScaleRangeDidChange(_ timeScaleRange: TimeScaleRange)
    func createEvent(withStartDate startDate: Date, endDate: Date, from viewController: DayInstanceEditViewController)
    func didCancelEdit(from viewController: DayInstanceEditViewController)
    func didFinishEdit(from viewController: DayInstanceEditViewController)
    func showVC(_ vc: UIViewController)
}

final class DayInstanceEditViewController: UIViewController {

    let viewModel: DayInstanceEditViewModel
    weak var delegate: DayInstanceEditViewControllerDelegate?
    let disposeBag = DisposeBag()

    /// 当前 view 的可见区域
    lazy var visibleRectInView: CGRect = { view.bounds }()
    /// 日程块最小高度
    var minDurationHeight: CGFloat = 20
    /// ContainerView Padding
    var containerViewPadding: UIEdgeInsets = .zero

    var editingContext: EditingContext?

    private lazy var passthroughView = DayInstanceEditPassthroughView()
    private let containerView: UIScrollView
    private let pageView: PageView
    private lazy var animators = (
        containerViewScrolling: ContainerViewScrollAnimator(targetView: containerView),
        pageViewPaging: PageViewPagingAnimator(targetView: pageView)
    )

    private let instanceView = DayInstanceEditView()
    private let positionView = UIView()
    private let panGestures = (
        // 开始刻度
        fromTimeScale: UIPanGestureRecognizer(),
        // 结束刻度
        toTimeScale: UIPanGestureRecognizer(),
        // 位置
        position: UIPanGestureRecognizer()
    )

    // 描述手势上下文最后一次的位置
    private var gestureRefLocations = (
        fromTimeScale: CGPoint?.none,
        toTimeScale: CGPoint?.none,
        position: CGPoint?.none
    )

    // 翻页
    private var pagingContext = (
        timer: Timer?.none,
        task: (() -> Void)?.none
    )

    // 跟踪长按手势的 context
    private var longPressContext = (
        gesture: UILongPressGestureRecognizer?.none,
        beganLocation: CGPoint?.none,
        isTrackingPositionActive: false
    )

    init(viewModel: DayInstanceEditViewModel, containerView: UIScrollView, pageView: PageView) {
        self.viewModel = viewModel
        self.containerView = containerView
        self.pageView = pageView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupPassthroughView()
        setupInstanceView()
        setupPositionView()
    }

    override func loadView() {
        super.loadView()
        view = passthroughView
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil && instanceView.superview == containerView {
            instanceView.removeFromSuperview()
        }
        pagingContext.timer?.invalidate()
        pagingContext.timer = nil
        animators.containerViewScrolling.pause()
    }

    deinit {
        kvoObservations.instanceViewFrame?.invalidate()
        kvoObservations.positionViewFrame?.invalidate()
        kvoObservations.containerContentOffset?.invalidate()
        kvoObservations.containerContentInset?.invalidate()
        pagingContext.timer?.invalidate()
    }

    private var kvoObservations = (
        instanceViewFrame: NSKeyValueObservation?.none,
        positionViewFrame: NSKeyValueObservation?.none,
        containerContentOffset: NSKeyValueObservation?.none,
        containerContentInset: NSKeyValueObservation?.none
    )

    private func doPrepare(for initialRectInContainer: CGRect) {
        containerView.addSubview(instanceView)
        let inset = instanceView.padding
        let extendInset = UIEdgeInsets(top: -inset.top, left: -inset.left, bottom: -inset.bottom, right: -inset.right)
        instanceView.frame = initialRectInContainer.inset(by: extendInset)

        // report time scale range for first time
        reportTimeScaleRange()

        let obv1 = instanceView.observe(\.frame, options: [.initial, .new]) { [weak self] (_, _) in
            self?.adjustPositionViewFrame()
            self?.reportTimeScaleRange()
        }
        kvoObservations.instanceViewFrame?.invalidate()
        kvoObservations.instanceViewFrame = obv1

        let obv2 = containerView.observe(\.contentOffset, options: [.initial, .new]) { [weak self] (_, _) in
            self?.adjustPositionViewFrame()
            self?.reportTimeScaleRange()
        }
        kvoObservations.containerContentOffset?.invalidate()
        kvoObservations.containerContentOffset = obv2

        let obv3 = positionView.observe(\.frame, options: [.initial, .new]) { [weak self] (_, _) in
            self?.reportTimeScaleRange()
        }
        kvoObservations.positionViewFrame?.invalidate()
        kvoObservations.positionViewFrame = obv3
    }

    private func adjustPositionViewFrame() {
        let instanceViewFrameInView = view.convert(instanceView.frame, from: instanceView.superview)
        let positionViewMargin = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        self.positionView.frame = instanceViewFrameInView.inset(by: positionViewMargin)
    }

    private func instanceRectInContainer() -> CGRect {
        var rectInContainer = containerView.convert(instanceView.frame, from: instanceView.superview)
        rectInContainer = rectInContainer.inset(by: instanceView.padding)
        return rectInContainer
    }

    private func reportTimeScaleRange() {
        guard let delegate = delegate else { return }

        let timeScaleRange = delegate.timeScaleRange(forRect: instanceRectInContainer())
        delegate.timeScaleRangeDidChange(timeScaleRange)
    }

    private func setupPassthroughView() {
        passthroughView.clipsToBounds = true
        passthroughView.eventFilter = { [weak self] (point, _) -> Bool in
            guard let self = self else { return false }

            let positionViewRect = self.passthroughView.convert(
                self.positionView.frame,
                from: self.positionView.superview
            )

            return positionViewRect.contains(point)
        }
    }

    private func setupInstanceView() {
        instanceView.padding = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        instanceView.placeholder = BundleI18n.Calendar.Calendar_Edit_addEventNamedTitle
        instanceView.borderColor = UIColor.ud.primaryContentDefault

        panGestures.fromTimeScale.maximumNumberOfTouches = 1
        panGestures.fromTimeScale.addTarget(self, action: #selector(trackFromTimeScaleGesture(_:)))
        instanceView.knobViews.top.addGestureRecognizer(panGestures.fromTimeScale)

        panGestures.toTimeScale.maximumNumberOfTouches = 1
        panGestures.toTimeScale.addTarget(self, action: #selector(trackToTimeScaleGesture(_:)))
        instanceView.knobViews.bottom.addGestureRecognizer(panGestures.toTimeScale)
    }

    private func setupPositionView() {
        positionView.clipsToBounds = false
        view.addSubview(positionView)

        panGestures.position.maximumNumberOfTouches = 1
        panGestures.position.addTarget(self, action: #selector(trackPositionGesture(_:)))
        positionView.addGestureRecognizer(panGestures.position)
        panGestures.position.require(toFail: panGestures.fromTimeScale)
        panGestures.position.require(toFail: panGestures.toTimeScale)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapInPositionView))
        positionView.addGestureRecognizer(tapGesture)
        tapGesture.require(toFail: panGestures.position)
    }

    @objc
    private func handleTapInPositionView() {
        guard instanceView.contentView == nil else { return }
        guard let delegate = delegate else { return }

        let rectInContainer = instanceRectInContainer()
        var timeScaleRange = delegate.timeScaleRange(forRect: rectInContainer)
        timeScaleRange = timeScaleRange.lowerBound.round(toGranularity: .hour_4)..<timeScaleRange.upperBound.round(toGranularity: .hour_4)
        let julianDay = delegate.julianDay(forRect: rectInContainer)
        let dates = viewModel.dates(from: timeScaleRange, julianDay: julianDay)
        delegate.createEvent(withStartDate: dates.startDate, endDate: dates.endDate, from: self)
    }

}

// MARK: Internel APIs

extension DayInstanceEditViewController {

    typealias EditingContext = (julianDay: JulianDay, instanceUniqueId: String)

    func prepareForCreating(from rectInContainer: CGRect) {
        instanceView.showKnobs()
        doPrepare(for: rectInContainer)
    }

    func prepareForEditing(from sender: UIView, snapshotView: UIView, editingContext: EditingContext? = nil) {
        let initialRectInContainer = containerView.convert(sender.frame, from: sender.superview)

        // attach instanceView to containerView
        snapshotView.isUserInteractionEnabled = false
        instanceView.contentView = snapshotView

        self.editingContext = editingContext

        doPrepare(for: initialRectInContainer)
    }

    func tryToFinishEdit() {
        guard let delegate = delegate else { return }
        let rectInContainer = instanceRectInContainer()
        var timeScaleRange = delegate.timeScaleRange(forRect: rectInContainer)
        timeScaleRange = timeScaleRange.lowerBound.round(toGranularity: .hour_4)..<timeScaleRange.upperBound.round(toGranularity: .hour_4)
        let julianDay = delegate.julianDay(forRect: rectInContainer)
        doSaveEvent(withTimeScaleRange: timeScaleRange, julianDay: julianDay, actionType: .drag)
    }

    @objc
    func handleLongPress(_ gesture: UILongPressGestureRecognizer) {

        longPressContext.gesture = gesture

        let point = gesture.location(in: gesture.view)
        switch gesture.state {
        case .began:
            longPressContext.beganLocation = point
            longPressContext.isTrackingPositionActive = false
        case .changed:
            if let beganLocation = longPressContext.beganLocation,
                abs(point.x - beganLocation.x) > 10 || abs(point.y - beganLocation.y) > 10 {
                longPressContext.isTrackingPositionActive = true
            }
        default:
            break
        }
        adjustInstanceViewPosition(by: gesture)
    }

}

// MARK: - Track TimeScaleRange

extension DayInstanceEditViewController {

    // MARK: Drap Top Knob

    // top 拖拽手势结束后，修改 timeScaleRange.lowerBound
    private func fixInstanceViewTop() {
        guard let delegate = delegate else { return }

        let rectInContainer = instanceRectInContainer()
        let timeScaleRange = delegate.timeScaleRange(forRect: rectInContainer)
        let julianDay = delegate.julianDay(forRect: rectInContainer)
        var fixedFrom = timeScaleRange.lowerBound.round(toGranularity: .hour_4)
        if fixedFrom >= timeScaleRange.upperBound {
            fixedFrom = fixedFrom.adding(-TimeScale.Granularity.hour_4.rawValue)
        }
        let fixedRectInContainer = delegate.rectInContainerView(for: fixedFrom..<timeScaleRange.upperBound, in: julianDay)
        let padding = instanceView.padding
        let extendInsets = UIEdgeInsets(top: -padding.top, left: -padding.left, bottom: -padding.bottom, right: -padding.right)
        instanceView.frame = fixedRectInContainer.inset(by: extendInsets)
    }

    // 修改 InstanceView.frame.top，bottom 不变
    private func updateInstanceViewTop(_ changed: CGFloat) {
        let minTop = containerViewPadding.top - instanceView.padding.top
        let maxTop = instanceView.frame.bottom - instanceView.padding.top - instanceView.padding.bottom - minDurationHeight
        var targetTop = instanceView.frame.top + changed
        targetTop = max(min(maxTop, instanceView.frame.top + changed), minTop)
        var targetFrame = instanceView.frame
        targetFrame.size.height = targetFrame.bottom - targetTop
        targetFrame.top = targetTop
        instanceView.frame = targetFrame
    }

    @objc
    private func trackFromTimeScaleGesture(_ pan: UIPanGestureRecognizer) {
        let location = pan.location(in: view)
        switch pan.state {
        case .began:
            gestureRefLocations.fromTimeScale = location
        case .changed:
            guard let refLocation = gestureRefLocations.fromTimeScale else { return }
            defer { gestureRefLocations.fromTimeScale = location }

            updateInstanceViewTop(location.y - refLocation.y)

            // 在滚动 containerView 的过程中，调整 instanceView 的 top
            let alongsideAnimation = { [weak self] (scrollContext: ContainerViewWillScrollContext) in
                guard let self = self else { return }
                self.updateInstanceViewTop(scrollContext.toOffsetY - scrollContext.fromOffsetY)
            }

            if positionView.frame.top < visibleRectInView.top + 20 {
                // 手势抵达上边缘，快速滚动 containerView 到顶部
                animators.containerViewScrolling.scrollToTop(alongside: alongsideAnimation)
            } else if positionView.frame.top < visibleRectInView.top + 120 {
                // 手势接近上边缘，缓慢滚动 containerView 到顶部
                if location.y < refLocation.y {
                    animators.containerViewScrolling.scrollToTop(duration: 1.0, alongside: alongsideAnimation)
                } else {
                    animators.containerViewScrolling.pause()
                }
            } else if positionView.frame.top > visibleRectInView.bottom - 120 {
                // 手势接近下边缘，当 instanceView 底部在可见视图外时，缓慢滚动 containerView 直到可以显示 instanceView 底部
                let instanceViewFrameInView = view.convert(instanceView.frame, from: instanceView.superview)
                if instanceViewFrameInView.bottom > visibleRectInView.bottom {
                    animators.containerViewScrolling.scrollToBottom(duration: 1.0, alongside: alongsideAnimation)
                } else {
                    animators.containerViewScrolling.pause()
                }
            } else {
                animators.containerViewScrolling.pause()
            }
        case .ended, .cancelled, .failed:
            gestureRefLocations.fromTimeScale = nil
            animators.containerViewScrolling.pause()
            fixInstanceViewTop()
        default:
            break
        }
    }

    // MARK: Drap Bottom Knob

    // top 拖拽手势结束后，修改 timeScaleRange.upperBound
    private func fixInstanceViewBottom() {
        guard let delegate = delegate else { return }

        let rectInContainer = instanceRectInContainer()
        let timeScaleRange = delegate.timeScaleRange(forRect: rectInContainer)
        let julianDay = delegate.julianDay(forRect: rectInContainer)
        var fixedTo = timeScaleRange.upperBound.round(toGranularity: .hour_4)
        if fixedTo <= timeScaleRange.lowerBound {
            fixedTo = fixedTo.adding(TimeScale.Granularity.hour_4.rawValue)
        }
        let fixedRectInContainer = delegate.rectInContainerView(for: timeScaleRange.lowerBound..<fixedTo, in: julianDay)
        let padding = instanceView.padding
        let extendInsets = UIEdgeInsets(top: -padding.top, left: -padding.left, bottom: -padding.bottom, right: -padding.right)
        instanceView.frame = fixedRectInContainer.inset(by: extendInsets)
    }

    // 修改 InstanceView.frame.bottom，top 不变
    private func updateInstanceViewBottom(_ changed: CGFloat) {
        var targetFrame = instanceView.frame
        let minHeight = instanceView.padding.top + instanceView.padding.bottom + minDurationHeight
        let maxHeight = containerView.contentSize.height - containerViewPadding.bottom
            + instanceView.padding.bottom - targetFrame.top
        targetFrame.size.height = max(min(instanceView.frame.height + changed, maxHeight), minHeight)
        instanceView.frame = targetFrame
    }

    @objc
    private func trackToTimeScaleGesture(_ pan: UIPanGestureRecognizer) {
        let location = pan.location(in: view)
        switch pan.state {
        case .began:
            gestureRefLocations.toTimeScale = location
        case .changed:
            guard let refLocation = gestureRefLocations.toTimeScale else { return }
            defer { gestureRefLocations.toTimeScale = location }

            updateInstanceViewBottom(location.y - refLocation.y)

            // 在滚动 containerView 的过程中，调整 instanceView 的 bottom
            let alongsideAnimation = { [weak self] (scrollContext: ContainerViewWillScrollContext) in
                guard let self = self else { return }
                self.updateInstanceViewBottom(scrollContext.toOffsetY - scrollContext.fromOffsetY)
            }

            if positionView.frame.bottom > visibleRectInView.bottom - 20 {
                // 手势抵达下边缘，快速滚动 containerView 到底部
                animators.containerViewScrolling.scrollToBottom(alongside: alongsideAnimation)
            } else if positionView.frame.bottom > visibleRectInView.bottom - 120 {
                // 手势接近上边缘，缓慢滚动 containerView 到底部
                if location.y > refLocation.y {
                    animators.containerViewScrolling.scrollToBottom(duration: 1.0, alongside: alongsideAnimation)
                } else {
                    animators.containerViewScrolling.pause()
                }
            } else if positionView.frame.bottom < visibleRectInView.top + 120 {
                // 手势接近上边缘，当 instanceView 顶部在可见视图外时，缓慢滚动 containerView 直到可以显示 instanceView 顶部
                let instanceViewFrameInView = view.convert(instanceView.frame, from: instanceView.superview)
                if instanceViewFrameInView.top < visibleRectInView.top {
                    animators.containerViewScrolling.scrollToTop(duration: 1.0, alongside: alongsideAnimation)
                } else {
                    animators.containerViewScrolling.pause()
                }
            } else {
                animators.containerViewScrolling.pause()
            }
        case .ended, .cancelled, .failed:
            gestureRefLocations.toTimeScale = nil
            animators.containerViewScrolling.pause()
            fixInstanceViewBottom()
        default:
            break
        }
    }

}

// MARK: - Track Position

extension DayInstanceEditViewController {

    @objc
    private func trackPositionGesture(_ gesture: UIPanGestureRecognizer) {
        adjustInstanceViewPosition(by: gesture)
    }

    private func setupPagableTimer(block: @escaping () -> Void) {
        if pagingContext.timer == nil {
            let timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { [weak self]_ in
                self?.pagingContext.task?()
            })
            pagingContext.timer = timer
            pagingContext.task = block
            RunLoop.main.add(timer, forMode: .common)
            timer.fireDate = Date()
        } else {
            pagingContext.task = block
        }
    }

    private func invalidatePagingTimer() {
        pagingContext.timer?.invalidate()
        pagingContext.timer = nil
        pagingContext.task = nil
    }

    private func fixInstanceViewCenter() {
        guard let delegate = delegate else { return }

        let rectInContainer = instanceRectInContainer()
        let timeScaleRange = delegate.timeScaleRange(forRect: rectInContainer)
        var (fixedFrom, fixedTo) = (timeScaleRange.lowerBound, timeScaleRange.upperBound)
        fixedFrom = fixedFrom.round(toGranularity: .hour_4)
        fixedTo = fixedTo.round(toGranularity: .hour_4)
        if fixedTo == .maxinum {
            fixedFrom = fixedTo.adding(-timeScaleRange.points)
        } else {
            fixedTo = fixedFrom.adding(timeScaleRange.points)
        }
        let julianDay = delegate.julianDay(forRect: rectInContainer)
        let fixedRectInContainer = delegate.rectInContainerView(for: fixedFrom..<fixedTo, in: julianDay)
        let padding = instanceView.padding
        let extendInsets = UIEdgeInsets(top: -padding.top, left: -padding.left, bottom: -padding.bottom, right: -padding.right)
        instanceView.frame = fixedRectInContainer.inset(by: extendInsets)
    }

    private func scrollToNextPage() {
        guard !animators.pageViewPaging.isAnimating else { return }
        animators.pageViewPaging.pageToNext()
    }

    private func scrollToPrevPage() {
        guard !animators.pageViewPaging.isAnimating else { return }
        animators.pageViewPaging.pageToPrev()
    }

    private func endEditing(isFromLongPress: Bool) {
        guard let delegate = delegate else { return }

        let fromFrame = instanceView.frame
        fixInstanceViewCenter()

        // 结束编辑
        let rectInContainer = instanceRectInContainer()
        var timeScaleRange = delegate.timeScaleRange(forRect: rectInContainer)
        timeScaleRange = timeScaleRange.lowerBound.round(toGranularity: .hour_4)..<timeScaleRange.upperBound.round(toGranularity: .hour_4)
        let julianDay = delegate.julianDay(forRect: rectInContainer)

        let doSave = {
            let toFrame = self.instanceView.frame
            // 在拖拽日程块的情况下，保持原日程日程时间间隔不变，不会受到日程块 timeScale 的影响
            // 例如 5分钟间隔的日程，在拖动日程块更改时间之后依旧是5分钟间隔
            if let blockData = self.viewModel.blockData {
                let timeScaleOffset = Int(blockData.endTime - blockData.startTime) * TimeScale.pointsPerSecond
                let endTimeScale = timeScaleRange.lowerBound.adding(timeScaleOffset)
                timeScaleRange = timeScaleRange.lowerBound..<endTimeScale
            }
            if abs(fromFrame.center.x - toFrame.center.x) > 10
                || abs(fromFrame.center.y - toFrame.center.y) > 10 {
                // 位移较大，加一个动画
                self.instanceView.frame = fromFrame
                UIView.animate(withDuration: 0.2, animations: {
                    self.instanceView.frame = toFrame
                }, completion: { _ in
                    guard self.viewModel.blockData != nil else { return }
                    self.doSaveEvent(withTimeScaleRange: timeScaleRange, julianDay: julianDay, actionType: .move)
                })
            } else {
                guard self.viewModel.blockData != nil else { return }
                self.doSaveEvent(withTimeScaleRange: timeScaleRange, julianDay: julianDay, actionType: .move)
            }
        }

        if isFromLongPress {
            // 对于长按触发的 track position，如果移动距离较小，则 isTrackingPositionActive 为 false；
            // 则被是识别为进入编辑状态
            if longPressContext.isTrackingPositionActive {
                doSave()
            } else {
                // 显示 knob
                instanceView.showKnobs()
            }
        } else {
            // 拖拽
            doSave()
        }
    }

    // swiftlint:disable cyclomatic_complexity
    private func adjustInstanceViewPosition(by gesture: UIGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        let location = view.convert(point, from: gesture.view)
        switch gesture.state {
        case .began:
            if instanceView.superview != positionView {
                // 将 instanceView 移动到 positionView 上
                instanceView.removeFromSuperview()
                instanceView.center = positionView.bounds.center
                positionView.addSubview(instanceView)
            }

            gestureRefLocations.position = location
        case .changed:
            guard let refLocation = gestureRefLocations.position else { return }
            defer { gestureRefLocations.position = location }

            // calculate targetFrame
            var targetCenter = positionView.frame.center
            targetCenter.x += location.x - refLocation.x
            targetCenter.y += location.y - refLocation.y
            var targetFrame = positionView.frame
            targetFrame.center = targetCenter

            let isUp = location.y < refLocation.y // 手势向上拖动
            let isDown = location.y > refLocation.y // 手势向下拖动
            let beyondVisibleView = targetFrame.height > visibleRectInView.height // 日程块显示高度超出可见区域高度

            var fixedFrame = targetFrame
            if !beyondVisibleView {
                fixedFrame.top = max(visibleRectInView.top, fixedFrame.top)
                fixedFrame.bottom = min(visibleRectInView.bottom, fixedFrame.bottom)
            } else {
                if isUp {
                    fixedFrame.top = max(visibleRectInView.top, fixedFrame.top)
                } else if isDown {
                    fixedFrame.bottom = min(visibleRectInView.bottom, fixedFrame.bottom)
                }
            }
            fixedFrame.left = max(-fixedFrame.width / 2, targetFrame.left)
            fixedFrame.right = min(visibleRectInView.right + fixedFrame.width / 2, fixedFrame.right)
            positionView.frame = fixedFrame

            // 描述是否可以 scrolling containerView；
            // 当 scrolling containerView 和 paging PageView 同时存在时，优先 scrolling containerView
            var isScrollingContainerViewSucceed = false

            if isUp && positionView.frame.top < visibleRectInView.top {
                positionView.frame.top = visibleRectInView.top
                isScrollingContainerViewSucceed = animators.containerViewScrolling.scrollToTop(duration: 1.0)
            }
            if isUp && positionView.frame.top < visibleRectInView.top + 20 && !beyondVisibleView {
                // 到达上边缘
                isScrollingContainerViewSucceed = animators.containerViewScrolling.scrollToTop()
            } else if isUp && positionView.frame.top < visibleRectInView.top + 120 {
                // 到达安全区
                if location.y < refLocation.y {
                    isScrollingContainerViewSucceed = animators.containerViewScrolling.scrollToTop(duration: 1.0)
                } else {
                    animators.containerViewScrolling.pause()
                }
            } else if isDown && positionView.frame.bottom > visibleRectInView.bottom - 20 && !beyondVisibleView {
                // 到达下边缘
                isScrollingContainerViewSucceed = animators.containerViewScrolling.scrollToBottom()
            } else if isDown && positionView.frame.bottom > visibleRectInView.bottom - 120 {
                // 到达安全区
                if location.y > refLocation.y {
                    isScrollingContainerViewSucceed = animators.containerViewScrolling.scrollToBottom(duration: 1.0)
                } else {
                    animators.containerViewScrolling.pause()
                }
            } else {
                animators.containerViewScrolling.pause()
            }

            guard !isScrollingContainerViewSucceed else {
                invalidatePagingTimer()
                return
            }

            let padingThreshold: CGFloat = pageView.pageCountPerScene == 1 ? 30 : 10
            if positionView.frame.left < visibleRectInView.left - padingThreshold {
                // 触发左边缘
                if location.x <= refLocation.x {
                    setupPagableTimer { [weak self] in
                        DayScene.logger.info("invoke delegate: scrollToPrev")
                        self?.scrollToPrevPage()
                    }
                } else {
                    invalidatePagingTimer()
                }
            } else if positionView.frame.right > visibleRectInView.right + padingThreshold {
                // 触发右边缘
                if location.x >= refLocation.x {
                    setupPagableTimer { [weak self] in
                        DayScene.logger.info("invoke delegate: scrollToNext")
                        self?.scrollToNextPage()
                    }
                } else {
                    DayScene.logger.info("invalidate scrollToNext")
                    invalidatePagingTimer()
                }
            } else {
                invalidatePagingTimer()
            }
        case .ended, .cancelled, .failed:
            DayScene.logger.info("end track position gesture. state: \(gesture.state)")
            gestureRefLocations.position = nil
            animators.containerViewScrolling.pause()
            invalidatePagingTimer()

            let isCancelled = gesture.state != .ended
            let isFromLongPress = gesture == self.longPressContext.gesture
            let doCompletion = { [weak self] in
                guard let self = self else { return }
                if self.instanceView.superview != self.containerView {
                    // 将 instanceView 移动回到 containerView 上
                    let rect = self.containerView.convert(self.instanceView.frame, from: self.instanceView.superview)
                    self.containerView.addSubview(self.instanceView)
                    self.instanceView.frame = rect
                }

                if isCancelled {
                    // 取消编辑
                    DayScene.logger.info("cancel edit")
                    self.delegate?.didCancelEdit(from: self)
                } else {
                    // 结束编辑
                    DayScene.logger.info("end edit")
                    self.endEditing(isFromLongPress: isFromLongPress)
                }
            }

            if let leftDuration = animators.pageViewPaging.currentAnimationLeftDuration() {
                // 如果正在动画中，则等动画结束后再处理
                DispatchQueue.main.asyncAfter(deadline: .now() + leftDuration + 0.01) {
                    doCompletion()
                }
            } else {
                doCompletion()
            }
        default:
            break
        }
    }
    // swiftlint:enable cyclomatic_complexity

}

extension DayInstanceEditViewController {

    private func doSaveEvent(withTimeScaleRange timeScaleRange: TimeScaleRange, 
                             julianDay: JulianDay,
                             actionType: UpdateTimeBlockActionType) {
        viewModel.saveEvent(with: timeScaleRange, julianDay: julianDay, actionType: actionType)
            .subscribe(
                onState: { [weak self] in
                    guard let self = self else { return }
                    self.instanceView.isUserInteractionEnabled = false
                    // 延时 0.1s 再结束编辑，是为了基于残影（instanceView）让被编辑的日程块过渡更流畅自然
                    // 如果没有延时，日程块所占区域（称为 rect）可能会闪烁，造成日程块闪烁的基本逻辑：
                    //   - rect 被 instanceView 占据
                    //   - instanceView 消失，rect 为空
                    //   - 接到 push 通知，nonAllDay 更新数据，rect 被填充
                    //   - instanceView 原来位置的地方被填上
                    // 如上 rect 的逻辑：被占据 - 为空 - 被占据，当 view 没变的情况下，会形成视觉上的闪烁
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.delegate?.didFinishEdit(from: self)
                    }
                },
                onMessage: { [weak self] viewMessage in
                    self?.handleSaveViewMessage(viewMessage)
                },
                onTerminate: { [weak self] error in
                    guard let self = self else { return }
                    let window = self.view.window
                    self.delegate?.didCancelEdit(from: self)
                    if let saveTerminalError = error as? DayInstanceEditViewModel.SaveTerminal, case .cancelledByUser = saveTerminalError {
                        DayScene.logger.error("user cancel")
                        return
                    }
                    if let window = window {
                        let tip = error.getTitle(errorScene: .eventSave) ?? I18n.Calendar_Toast_Retry
                        UDToast.showTips(with: tip, on: window)
                    }
                    DayScene.logger.error("save failed: \(error)")
                },
                scheduler: MainScheduler.asyncInstance
            )
            .disposed(by: disposeBag)
    }
}
