//
//  InfiniteScrollView.swift
//  Calendar
//
//  Created by zhuchao on 2017/12/7.
//  Copyright © 2017年 linlin. All rights reserved.
//  Inspired by https://developer.apple.com/library/content/samplecode/StreetScroller/Introduction/Intro.html
import Foundation
import CalendarFoundation
import UIKit

public protocol InfiniteScrollViewDelegate: AnyObject {
    func infiniteScrollView(scrollView: InfiniteScrollView, viewForIndex index: Int) -> UIView
    func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int)
}

open class InfiniteScrollView: UIScrollView {

    public weak var dataSource: InfiniteScrollViewDelegate?

    public let containerView: UIView = UIView()

    public var visibleViews: [UIView] = []

    public var onSizeChanging: Bool = false

    private var buffers: [UIView] = []

    public init() {
        super.init(frame: CGRect.zero)
        self.commonInit()
    }

    public func resetBuffers() {
        self.buffers.removeAll()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    open func defaultContentSize() -> CGSize {
        return CGSize(width: 5000, height: self.bounds.height)
    }

    // initialize
    fileprivate func commonInit() {
        self.contentSize = self.defaultContentSize()
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.scrollsToTop = false

        self.containerView.frame = CGRect(x: 0, y: 0, width: self.contentSize.width, height: self.bounds.height)
        self.containerView.autoresizingMask = .flexibleHeight
        self.addSubview(self.containerView)
    }

    public func reloadData() {
        self.visibleViews.forEach { (cell) in
            self.dataSource?.infiniteScrollView(scrollView: self, willDisplay: cell, at: cell.tag)
        }
    }

    func reset() {
        self.setContentOffset(CGPoint.zero, animated: false)
        self.visibleViews.forEach { (view) in
            view.removeFromSuperview()
        }
        self.visibleViews.removeAll()
        self.recenterIfNeed()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.recenterIfNeed()
        let visibleBounds = self.convert(self.bounds, to: self.containerView)

        self.tileFirstView(startX: visibleBounds.minX)
        self.tileViewsFromMinX(minimumVisibleX: visibleBounds.minX, maximumVisibleX: visibleBounds.maxX)
    }

    open func recenterIfNeed() {
        let currentOffset = self.contentOffset
        let contentWidth = self.contentSize.width
        let offsetWhenCentrally = (contentWidth - self.bounds.width) / 2.0
        let distanceFromCenter = abs(currentOffset.x - offsetWhenCentrally)
        if distanceFromCenter > (contentWidth / 4.0) {
            self.contentOffset = CGPoint(x: offsetWhenCentrally, y: currentOffset.y)
            for view in self.visibleViews {
                var center = self.containerView.convert(view.center, to: self)
                center.x += (offsetWhenCentrally - currentOffset.x)
                view.center = self.convert(center, to: self.containerView)
            }
        }
    }

    open func tileFirstView(startX: CGFloat) {
        guard self.dataSource != nil, self.visibleViews.isEmpty else {
            return
        }
        self.placeNewViewOnRight(rightEdge: startX)
    }

    func tileViewsFromMinX(minimumVisibleX: CGFloat, maximumVisibleX: CGFloat) {
        guard self.dataSource != nil, !self.visibleViews.isEmpty else {
            return
        }

        let lastView = self.visibleViews.last!
        var rightEdge = lastView.frame.maxX
        while shouldPlaceNewViewOnRight(rightEdge: rightEdge, maximumVisibleX: maximumVisibleX) {
            rightEdge = self.placeNewViewOnRight(rightEdge: rightEdge)
        }

        let firstView = self.visibleViews.first!
        var leftEdge = firstView.frame.minX
        while shouldPlaceNewViewOnLeft(leftEdge: leftEdge, minimumVisibleX: minimumVisibleX) {
            leftEdge = self.placeNewViewOnLeft(leftEdge: leftEdge)
        }

        var currentLastView: UIView? = self.visibleViews.last
        while currentLastView != nil
            && shouldRemoveLastView(originX: currentLastView!.frame.origin.x,
                                    maximumVisibleX: maximumVisibleX) {
            currentLastView!.isHidden = true
            self.buffers.append(currentLastView!)
            self.visibleViews.removeLast()
            currentLastView = self.visibleViews.last
        }

        var currentFirstView = self.visibleViews.first
        while currentFirstView != nil
            && shouldRemoveFirstView(maxX: currentFirstView!.frame.maxX,
                                     minimumVisibleX: minimumVisibleX) {
            currentFirstView!.isHidden = true
            self.buffers.append(currentFirstView!)
            self.visibleViews.removeFirst()
            currentFirstView = self.visibleViews.first
        }
    }

    open func shouldPlaceNewViewOnRight(rightEdge: CGFloat, maximumVisibleX: CGFloat) -> Bool {
        return rightEdge < maximumVisibleX
    }

    open func shouldPlaceNewViewOnLeft(leftEdge: CGFloat, minimumVisibleX: CGFloat) -> Bool {
        return leftEdge > minimumVisibleX
    }

    open func shouldRemoveLastView(originX: CGFloat, maximumVisibleX: CGFloat) -> Bool {
        return originX >= maximumVisibleX
    }

    open func shouldRemoveFirstView(maxX: CGFloat, minimumVisibleX: CGFloat) -> Bool {
        return maxX <= minimumVisibleX
    }

    @discardableResult
    private func placeNewViewOnRight(rightEdge: CGFloat) -> CGFloat {
        var tag: Int = 0
        if let lastLabel = self.visibleViews.last {
            tag = lastLabel.tag + 1
        }
        guard let view = self.viewToLayout(tag: tag) else {
            return rightEdge
        }
        self.visibleViews.append(view)
        var frame = view.frame
        frame.origin.x = rightEdge
        frame.origin.y = 0.0
        frame.size.height = self.containerView.bounds.height
        view.frame = frame
        if view.superview == nil {
            self.containerView.addSubview(view)
        }
        self.dataSource?.infiniteScrollView(scrollView: self, willDisplay: view, at: tag)
        return frame.maxX
    }

    @discardableResult
    private func placeNewViewOnLeft(leftEdge: CGFloat) -> CGFloat {
        var tag: Int = 0
        if let firstLabel = self.visibleViews.first {
            tag = firstLabel.tag - 1
        }
        guard let view = self.viewToLayout(tag: tag) else {
            return leftEdge
        }
        self.visibleViews.insert(view, at: 0)
        var frame = view.frame
        frame.origin.x = leftEdge - frame.size.width
        frame.origin.y = 0.0
        frame.size.height = self.containerView.bounds.height
        view.frame = frame
        if view.superview == nil {
            self.containerView.addSubview(view)
        }
        self.dataSource?.infiniteScrollView(scrollView: self, willDisplay: view, at: tag)
        return frame.minX
    }

    private func viewToLayout(tag: Int) -> UIView? {
        guard self.dataSource != nil else {
            return nil
        }

        if let bufferdView = self.buffers.popLast() {
            bufferdView.tag = tag
            bufferdView.isHidden = false
            return bufferdView
        }
        let newView = self.dataSource?.infiniteScrollView(scrollView: self, viewForIndex: tag)
        if let viewFrame = newView?.frame {
            assertLog(!viewFrame.isEmpty)
        }
        newView?.tag = tag
        newView?.autoresizingMask = [.flexibleHeight]
        return newView
    }

    func killScroll() {
        var offset = self.contentOffset
        offset.x -= 1.0
        offset.y -= 1.0
        self.setContentOffset(offset, animated: false)
        offset.x += 1.0
        offset.y += 1.0
        self.setContentOffset(offset, animated: false)
    }
}
