//
//  BasePageView.swift
//  PageView
//
//  Created by 张威 on 2020/6/18.
//  Copyright © 2020 ByteDance. All rights reserved.
//
import Foundation
import UIKit
///
/// PageIndex:
///     +--------------------------+
///     +                          +
///     +  0  1  2  3  4  5  6  7  +
///     +                          +
///     +--------------------------+
///

// MARK: - BasePageView

// swiftlint:disable file_length
typealias PageOffset = CGFloat
typealias PageIndex = Int
typealias PageRange = Range<PageIndex>

typealias PageDirection = BasePageView.Direction

protocol BasePageViewDelegate: AnyObject {
    func pageViewWillBeginDragging(_ pageView: BasePageView)
    func pageViewWillEndDragging(_ pageView: BasePageView)
    func pageViewDidEndDragging(_ pageView: BasePageView, willDecelerate decelerate: Bool)
    func pageViewWillBeginDecelerating(_ pageView: BasePageView)
    func pageViewDidEndDecelerating(_ pageView: BasePageView)
    func pageViewDidEndScrollingAnimation(_ pageView: BasePageView)
    func pageViewWillBeginFixingIndex(_ pageView: BasePageView, targetIndex: PageIndex, animated: Bool)
}

extension BasePageViewDelegate {
    func pageViewWillBeginDragging(_ pageView: BasePageView) {}
    func pageViewWillEndDragging(_ pageView: BasePageView) {}
    func pageViewDidEndDragging(_ pageView: BasePageView, willDecelerate decelerate: Bool) {}
    func pageViewWillBeginDecelerating(_ pageView: BasePageView) {}
    func pageViewDidEndDecelerating(_ pageView: BasePageView) {}
    func pageViewDidEndScrollingAnimation(_ pageView: BasePageView) {}
    func pageViewWillBeginFixingIndex(_ pageView: BasePageView, targetIndex: PageIndex, animated: Bool) {}
}

class BasePageView: UIView {

    enum Direction {
        case horizontal
        case vertical
    }

    // MARK: Properties

    let direction: Direction

    let scrollView = UIScrollView()

    /// total page count
    let totalPageCount: Int

    /// `pageCountPerScene = 3` means there are always 3 pageItemViews in PageView
    var pageCountPerScene: Int = 1 {
        didSet {
            guard oldValue != pageCountPerScene else { return }
            scrollView.isPagingEnabled = pageCountPerScene <= 1
            setNeedsLayout()
        }
    }

    /// for logging
    var name: String?

    var pageSize: CGSize {
        var size = scrollView.bounds.size
        if direction == .horizontal {
            size.width /= CGFloat(max(1, pageCountPerScene))
        } else {
            size.height /= CGFloat(max(1, pageCountPerScene))
        }
        return size
    }

    /// enable decelerating or not
    var isDeceleratingEnabled: Bool = true {
        didSet { scrollView.decelerationRate = isDeceleratingEnabled ? .normal : .fast }
    }

    weak var baseDelegate: BasePageViewDelegate?

    /// The following two properties, are considered to be state properties.
    /// `0.0` <= `pageOffset` <= `totalPageCount` - `pageCountPerScene`
    private(set) var pageOffset: PageOffset = 0.0
    private(set) var visiblePageRange: PageRange = 0..<1

    private var isStateFrozen: Bool = false {
        didSet { scrollView.isScrollEnabled = !isStateFrozen }
    }

    private var observation: NSKeyValueObservation?

    init(frame: CGRect = .zero, totalPageCount: Int, direction: Direction = .horizontal) {
        self.direction = direction
        self.totalPageCount = totalPageCount
        super.init(frame: frame)
        setupScrollView()
        startObserving()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        stopObserving()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // resize scrollView if needed
        let minScrollViewSize = CGSize(width: 24, height: 24)
        var scrollViewFrame = bounds
        scrollViewFrame.size.width = max(minScrollViewSize.width, scrollViewFrame.width)
        scrollViewFrame.size.height = max(minScrollViewSize.height, scrollViewFrame.height)
        if !scrollViewFrame.equalTo(scrollView.frame) {
            scrollView.frame = scrollViewFrame
        }

        var contentSize = pageSize
        if direction == .horizontal {
            contentSize.width *= CGFloat(totalPageCount)
        } else {
            contentSize.height *= CGFloat(totalPageCount)
        }
        if !contentSize.equalTo(scrollView.contentSize) {
            scrollView.contentSize = contentSize
        }

        if isStateFrozen {
            let fixedOffset = fixedPageOffset(ref: round(pageOffset))
            setContentOffset(by: fixedOffset, animated: false)
        } else {
            // force update pageState (pageOffset/visiblePageRange)
            updatePageState()
        }
    }

    private func setupScrollView() {
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.bounces = false
        scrollView.isPagingEnabled = pageCountPerScene <= 1
        scrollView.scrollsToTop = false
        scrollView.decelerationRate = .normal
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.isScrollEnabled = true
        scrollView.clipsToBounds = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.delegate = self

        addSubview(scrollView)
    }

    private func startObserving() {
        observation = scrollView.observe(\.contentOffset, options: [.new, .old]) { [unowned self] (_, change) in
            if let newValue = change.newValue, let oldValue = change.oldValue, newValue == oldValue {
                return
            }
            if !self.isStateFrozen {
                self.updatePageState()
            }
        }
    }

    private func stopObserving() {
        observation?.invalidate()
    }

    // MARK: Scrolling

    private func setContentOffset(by pageOffset: PageOffset, animated: Bool) {
        var targetOffset = CGPoint.zero
        if direction == .horizontal {
            targetOffset.x = pageOffset * pageSize.width
        } else {
            targetOffset.y = pageOffset * pageSize.height
        }
        scrollView.setContentOffset(targetOffset, animated: animated)
    }

    func scroll(to pageIndex: PageIndex, animated: Bool = false) {
        scroll(to: PageOffset(pageIndex), animated: animated)
    }

    func scroll(to pageOffset: PageOffset, animated: Bool = false) {
        assert(pageOffset >= 0.0 && pageOffset <= fixedPageOffset(ref: pageOffset))
        guard !isStateFrozen else { return }
        let pageOffset = fixedPageOffset(ref: pageOffset)
        layoutIfNeeded()
        setContentOffset(by: pageOffset, animated: animated)
    }

    func scrollToPrev(animated: Bool = false) {
        scroll(to: round(pageOffset - 1), animated: animated)
    }

    func scrollToNext(animated: Bool = false) {
        scroll(to: round(pageOffset + 1), animated: animated)
    }

    // MARK: Page Item Management

    @inline(__always)
    private func fixedPageOffset(ref: PageOffset) -> PageOffset {
        return max(0, min(PageOffset(totalPageCount - pageCountPerScene), ref))
    }

    @inline(__always)
    private func calculatePageOffset(from contentOffset: CGPoint) -> PageOffset {
        if direction == .horizontal {
            return contentOffset.x / max(1, pageSize.width)
        } else {
            return contentOffset.y / max(1, pageSize.height)
        }
    }

    @inline(__always)
    private func calculatePageOffset() -> PageOffset {
        return calculatePageOffset(from: scrollView.contentOffset)
    }

    // MARK: - Orientation Management

    func freezeStateIfNeeded() {
        guard !isStateFrozen else { return }
        isStateFrozen = true
    }

    func unfreezeStateIfNeeded() {
        guard isStateFrozen else { return }
        isStateFrozen = false
        setNeedsLayout()
    }

    // MARK: - Page State

    private func updatePageState() {
        var pageOffset = calculatePageOffset()
        pageOffset = fixedPageOffset(ref: pageOffset)

        // visible index range
        let fromIndex = max(0, PageIndex(floor(pageOffset + 0.01)))
        let toIndex = min(PageIndex(ceil(pageOffset - 0.01)) + pageCountPerScene, totalPageCount)
        let visiblePageRange = fromIndex..<max(toIndex, fromIndex + 1)

        let (oldPageOffset, oldVislbePageRange) = (self.pageOffset, self.visiblePageRange)
        let pageOffsetChanged = pageOffset != oldPageOffset
        let visiblePageRangeChanged = visiblePageRange != oldVislbePageRange

        // update state properties
        self.pageOffset = pageOffset
        self.visiblePageRange = visiblePageRange

        if pageOffsetChanged {
            pageOffsetDidChange()
        }
        if visiblePageRangeChanged {
            visiblePageRangeDidChange()
        }
    }

    func pageOffsetDidChange() { }

    func visiblePageRangeDidChange() { }

}

extension BasePageView: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        baseDelegate?.pageViewWillBeginDragging(self)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        baseDelegate?.pageViewWillEndDragging(self)
        guard !isDeceleratingEnabled else { return }
        guard !scrollView.isPagingEnabled else { return }

        var targetOffset = calculatePageOffset(from: targetContentOffset.pointee)
        let fixedOffset: PageOffset
        if direction == .horizontal {
            if velocity.x < 0 {
                targetOffset = floor(targetOffset)
            } else if velocity.x > 0 {
                targetOffset = ceil(targetOffset)
            } else {
                targetOffset = round(targetOffset)
            }
            fixedOffset = fixedPageOffset(ref: targetOffset)
            targetContentOffset.pointee.x = fixedOffset * pageSize.width
        } else {
            if velocity.y < 0 {
                targetOffset = floor(targetOffset)
            } else if velocity.y > 0 {
                targetOffset = ceil(targetOffset)
            } else {
                targetOffset = round(targetOffset)
            }
            fixedOffset = fixedPageOffset(ref: targetOffset)
            targetContentOffset.pointee.y = fixedOffset * pageSize.height
        }
        baseDelegate?.pageViewWillBeginFixingIndex(self, targetIndex: PageIndex(round(fixedOffset)), animated: true)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        baseDelegate?.pageViewDidEndDragging(self, willDecelerate: decelerate)
        if !decelerate {
            let pageOffset = fixedPageOffset(ref: round(calculatePageOffset()))
            setContentOffset(by: pageOffset, animated: true)
            baseDelegate?.pageViewWillBeginFixingIndex(self, targetIndex: PageIndex(round(pageOffset)), animated: true)
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        baseDelegate?.pageViewWillBeginDecelerating(self)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        baseDelegate?.pageViewDidEndDecelerating(self)
        let pageOffset = fixedPageOffset(ref: round(calculatePageOffset()))
        setContentOffset(by: pageOffset, animated: true)
        baseDelegate?.pageViewWillBeginFixingIndex(self, targetIndex: PageIndex(round(pageOffset)), animated: true)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        baseDelegate?.pageViewDidEndScrollingAnimation(self)
    }
}

protocol PageViewDataSource: AnyObject {
    func itemView(at index: PageIndex, in pageView: PageView) -> UIView
}

// MARK: - PageViewDelegate

protocol PageViewDelegate: BasePageViewDelegate {
    func pageView(_ pageView: PageView, willLoad itemView: UIView, at index: PageIndex)
    func pageView(_ pageView: PageView, didLoad itemView: UIView, at index: PageIndex)
    func pageView(_ pageView: PageView, willUnload itemView: UIView, at index: PageIndex)
    func pageView(_ pageView: PageView, didUnload itemView: UIView, at index: PageIndex)

    func pageView(_ pageView: PageView, didChangePageOffset pageOffset: PageOffset)
    func pageView(_ pageView: PageView, didChangeVisiblePageRange visiblePageRange: PageRange)
}

extension PageViewDelegate {
    func pageView(_ pageView: PageView, willLoad itemView: UIView, at index: PageIndex) {}
    func pageView(_ pageView: PageView, didLoad itemView: UIView, at index: PageIndex) {}
    func pageView(_ pageView: PageView, willUnload itemView: UIView, at index: PageIndex) {}
    func pageView(_ pageView: PageView, didUnload itemView: UIView, at index: PageIndex) {}

    func pageView(_ pageView: PageView, didChangePageOffset pageOffset: PageOffset) {}
    func pageView(_ pageView: PageView, didChangeVisiblePageRange visiblePageRange: PageRange) {}
}

// MARK: - PageView

class PageView: BasePageView {

    // MARK: Properties

    weak var delegate: PageViewDelegate? {
        didSet { baseDelegate = delegate }
    }

    weak var dataSource: PageViewDataSource? {
        didSet {
            if dataSource != nil {
                reloadData(in: 0..<totalPageCount)
            }
        }
    }

    private var loadedItemViews = [PageIndex: UIView]()

    override func layoutSubviews() {
        super.layoutSubviews()
        // layout item views if needed
        loadedItemViews.forEach { setFrame(for: $1, at: $0) }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard window != nil else { return }
        updateItemViewsIfNeeded()
    }

    // MARK: Index <-> ItemView

    /// return `nil` if item view at index has not been loaded.
    func itemView(at index: PageIndex) -> UIView? {
        return loadedItemViews[index]
    }

    func index(of itemView: UIView) -> PageIndex? {
        return loadedItemViews.first { $0.value == itemView }?.key
    }

    // MARK: Reload Data

    func reloadData() {
        reloadData(in: visiblePageRange)
    }

    func reloadData(at index: PageIndex) {
        reloadData(in: index..<index + 1)
    }

    func reloadData(in range: PageRange) {
        let lowerBoundMax = max(range.lowerBound, visiblePageRange.lowerBound)
        let upperBoundMin = min(range.upperBound, visiblePageRange.upperBound)
        guard upperBoundMin > lowerBoundMax else { return }
        let reloadRange = lowerBoundMax..<upperBoundMin
        reloadRange.forEach(unloadItemView(at:))
        updateItemViewsIfNeeded()
    }

    // MARK: Page Item Management

    private func setFrame(for itemView: UIView, at index: PageIndex) {
        assert(index >= 0 && index < totalPageCount)
        var origin = CGPoint.zero
        if direction == .horizontal {
            origin.x = CGFloat(index) * pageSize.width
        } else {
            origin.y = CGFloat(index) * pageSize.height
        }
        itemView.frame = CGRect(origin: origin, size: pageSize)
    }

    private func loadItemView(at index: Int) {
        guard index >= 0 && index < totalPageCount else { return }

        guard let dataSource = dataSource else { return }
        let oldView = itemView(at: index)

        // fetch itemView
        let newItemView = dataSource.itemView(at: index, in: self)

        // before load itemView
        delegate?.pageView(self, willLoad: newItemView, at: index)
        // unload old itemView if needed
        if let oldView = oldView, oldView != newItemView {
            delegate?.pageView(self, willUnload: oldView, at: index)
            oldView.removeFromSuperview()
            delegate?.pageView(self, didUnload: oldView, at: index)
        }

        setFrame(for: newItemView, at: index)

        if newItemView.superview != scrollView {
            scrollView.addSubview(newItemView)
        }

        loadedItemViews[index] = newItemView
        #if DEBUG
        newItemView.pageIndex = index
        #endif

        // after load itemView
        delegate?.pageView(self, didLoad: newItemView, at: index)
    }

    private func unloadItemView(at index: Int) {
        guard let view = loadedItemViews[index] else { return }

        loadedItemViews.removeValue(forKey: index)

        guard view.superview == scrollView else { return }

        delegate?.pageView(self, willUnload: view, at: index)
        view.removeFromSuperview()
        delegate?.pageView(self, didUnload: view, at: index)
    }

    // MARK: - Page State

    private func updateItemViewsIfNeeded() {
        // remove invisible item views if needed
        loadedItemViews.keys
            .filter { !visiblePageRange.contains($0) }
            .forEach(unloadItemView(at:))

        // load missing item views if needed
        if window != nil {
            for index in visiblePageRange {
                let view = loadedItemViews[index]
                if view == nil || view!.superview != scrollView {
                    loadItemView(at: index)
                }
            }
        }
    }

    override func visiblePageRangeDidChange() {
        super.visiblePageRangeDidChange()
        updateItemViewsIfNeeded()
        delegate?.pageView(self, didChangeVisiblePageRange: visiblePageRange)

        #if DEBUG
        guard window != nil else { return }
        // 自检：
        //  - 没有出现空页
        //  - itemView 出现在正确的位置
        //  - itemView 的编号正确
        visiblePageRange.forEach { index in
            // 不出现空页
            guard let view = itemView(at: index),
                let superview = view.superview,
                superview == scrollView else {
                assertionFailure()
                return
            }
            // 页码正确
            guard let pageIndex = view.pageIndex, pageIndex == index else {
                assertionFailure()
                return
            }
            // frame 正确
            var origin = CGPoint.zero
            if direction == .horizontal {
                origin.x = CGFloat(index) * pageSize.width
            } else {
                origin.y = CGFloat(index) * pageSize.height
            }
            guard abs(origin.x - view.frame.minX) < 0.0001,
                  abs(origin.y - view.frame.minY) < 0.0001,
                  abs(pageSize.width - view.frame.width) < 0.0001,
                  abs(pageSize.height - view.frame.height) < 0.0001 else {
                // assertionFailure()
                return
            }
        }
        #endif
    }

    override func pageOffsetDidChange() {
        super.pageOffsetDidChange()
        delegate?.pageView(self, didChangePageOffset: pageOffset)
    }

}

extension UIView {
    private struct AssociatedKeys {
        static var pageIndex = "pageIndex"
    }

    var pageIndex: PageIndex? {
        set {
            var num: NSNumber?
            if let value = newValue {
                num = NSNumber(value: value)
            }
            objc_setAssociatedObject(self, &AssociatedKeys.pageIndex, num, .OBJC_ASSOCIATION_RETAIN)
        }
        get {
            guard let num = objc_getAssociatedObject(self, &AssociatedKeys.pageIndex) as? NSNumber else {
                return nil
            }
            return num.intValue
        }
    }
}
// swiftlint: enable file_length
