//
//  InfiniteScrollView.swift
//  MailSDK
//
//  Created by zhaoxiongbin on 2021/11/1.
//

import Foundation
import UIKit
import LarkUIKit

protocol InfiniteScrollViewDelegate: AnyObject {
    func infiniteScrollView(scrollView: InfiniteScrollView, viewForIndex index: Int) -> UIView
    func infiniteScrollView(scrollView: InfiniteScrollView, willDisplay view: UIView, at index: Int)
}

class InfiniteScrollView: UIScrollView {

    weak var dataSource: InfiniteScrollViewDelegate?

    let containerView: UIView = UIView()

    var visibleViews: [UIView] = []

    var onSizeChanging: Bool = false

    init() {
        super.init(frame: CGRect.zero)
        self.commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func defaultContentSize() -> CGSize {
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

    func reloadData() {
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutVisibleViews()
    }

    func layoutVisibleViews() {
        self.recenterIfNeed()
        let visibleBounds = self.convert(self.bounds, to: self.containerView)

        self.tileFirstView(startX: visibleBounds.minX)
        self.tileViewsFromMinX(minimumVisibleX: visibleBounds.minX, maximumVisibleX: visibleBounds.maxX)
        for view in visibleViews {
            self.dataSource?.infiniteScrollView(scrollView: self, willDisplay: view, at: view.tag)
        }
        updateCellcellScale()
    }

    func updateCellcellScale() {
        // 根据cell距离scrollView centerY距离进行scale。居中最大scale为 1，两边最小scale为 14/17
        for cell in visibleViews {
            guard let cell = cell as? MailOOODatePickerCell, let superView = self.superview else { continue }
            let cellHeight = cell.bounds.width
            let visibleBounds = convert(bounds, to: containerView)
            let cellCenterX = cell.center.x
            let delta = abs(cellCenterX - visibleBounds.centerX)
            var finalScale: CGFloat = 14.0 / 17.0
            if delta <= cellHeight {
                //中心点处于居中一个和上或下第一个时，按比例scale
                finalScale = 1 - (delta / cellHeight) * (1 - finalScale)
            }
            //中心点在上下第一个以外时，直接用最小scale，14/17
            let transform = CGAffineTransform(scaleX: finalScale, y: finalScale).rotated(by: -(CGFloat.pi / 2.0))
            guard cell.label.transform != transform else { continue }
            cell.label.transform = transform
        }
    }

    fileprivate func recenterIfNeed() {
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

    private func tileFirstView(startX: CGFloat) {
        guard self.dataSource != nil, self.visibleViews.isEmpty else {
            return
        }
        self.placeNewViewOnRight(rightEdge: startX)
    }

    private  func tileViewsFromMinX(minimumVisibleX: CGFloat, maximumVisibleX: CGFloat) {
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
            self.visibleViews.removeLast()
            currentLastView = self.visibleViews.last
        }

        var currentFirstView = self.visibleViews.first
        while currentFirstView != nil
            && shouldRemoveFirstView(maxX: currentFirstView!.frame.maxX,
                                     minimumVisibleX: minimumVisibleX) {
            currentFirstView!.isHidden = true
            self.visibleViews.removeFirst()
            currentFirstView = self.visibleViews.first
        }
    }

    func shouldPlaceNewViewOnRight(rightEdge: CGFloat, maximumVisibleX: CGFloat) -> Bool {
        return rightEdge < maximumVisibleX
    }

    func shouldPlaceNewViewOnLeft(leftEdge: CGFloat, minimumVisibleX: CGFloat) -> Bool {
        return leftEdge > minimumVisibleX
    }

    func shouldRemoveLastView(originX: CGFloat, maximumVisibleX: CGFloat) -> Bool {
        return originX >= maximumVisibleX
    }

    func shouldRemoveFirstView(maxX: CGFloat, minimumVisibleX: CGFloat) -> Bool {
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
        // operationLog(optType: CalendarOperationType.threeToRight.rawValue)
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
        return frame.minX
    }

    private func viewToLayout(tag: Int) -> UIView? {
        guard self.dataSource != nil else {
            return nil
        }

        let newView = self.dataSource?.infiniteScrollView(scrollView: self, viewForIndex: tag)
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
