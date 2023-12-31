//
//  BasePageView.swift
//  PageView
//
//  Created by 张威 on 2020/6/18.
//  Copyright © 2020 ByteDance. All rights reserved.
//

import UIKit
import LKCommonsLogging

///
/// PageIndex:
///     +--------------------------+
///     +                          +
///     +  0  1  2  3  4  5  6  7  +
///     +                          +
///     +--------------------------+
///

// MARK: - BasePageView

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

    static let logger = Logger.log(BasePageView.self)

    /// The following two properties, are considered to be state properties.
    /// `0.0` <= `pageOffset` <= `totalPageCount` - `pageCountPerScene`
    private(set) var pageOffset: PageOffset = 0.0
    private(set) var visiblePageRange: PageRange = 0..<1

    private var isStateFrozen: Bool = false {
        didSet { scrollView.isScrollEnabled = !isStateFrozen }
    }

    private var observation: NSKeyValueObservation?
    let isShowEffLog: Bool
    
    init(frame: CGRect = .zero,
         totalPageCount: Int,
         direction: Direction = .horizontal,
         isShowEffLog: Bool = false) {
        self.direction = direction
        self.isShowEffLog = isShowEffLog
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

        // update scrollView contentSize if needed
        // `fixedPageCount` is a multiple of `pageCountPerScene`
        let fixedPageCount = (totalPageCount + pageCountPerScene - 1) / pageCountPerScene * pageCountPerScene
        var contentSize = pageSize
        if direction == .horizontal {
            contentSize.width *= CGFloat(fixedPageCount)
        } else {
            contentSize.height *= CGFloat(fixedPageCount)
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
            Self.logger.info("BasePageView(\(name ?? "") pageOffset changed: \(oldPageOffset) -> \(pageOffset). offset: \(scrollView.contentOffset), size: \(scrollView.contentSize)")
        }
        if visiblePageRangeChanged {
            visiblePageRangeDidChange()
            Self.logger.info("BasePageView(\(name ?? "") visiblePageRange changed: \(oldVislbePageRange) -> \(visiblePageRange). offset: \(scrollView.contentOffset), size: \(scrollView.contentSize)")
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
        } else {
            // do nothing
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
