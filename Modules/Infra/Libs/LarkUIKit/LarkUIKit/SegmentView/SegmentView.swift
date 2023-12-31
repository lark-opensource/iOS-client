//
//  SegmentView.swift
//  LarkUIKit
//
//  Created by 吴子鸿 on 2017/7/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

@objc(LarkUIKitSegmentView)
open class SegmentView: UIView {
    public var segment: Segment

    var scrollView: UIScrollView = UIScrollView()

    private var contentView: UIView = UIView()

    private var viewsWithTitle: [(title: String, view: UIView)] = []

    private var viewWidth: CGFloat { scrollView.bounds.width }

    private var isLaunching: Bool = true
    private var isUpdateWidth: Bool = false

    private var currentScrollIndex: CGFloat {
        scrollView.layoutIfNeeded()
        guard scrollView.bounds.size.width != 0 else { return 0 }
        return scrollView.contentOffset.x / scrollView.bounds.size.width
    }

    public init(segment: Segment) {
        self.segment = segment
        super.init(frame: CGRect.zero)
        self.addSubview(segment.getControlView())
        segment.getControlView().snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(segment.height)
        }

        segment.tapTo = { [weak self] (index) in
            guard let `self` = self else { return }
            self.scrollView.setContentOffset(CGPoint(x: self.viewWidth * CGFloat(index), y: 0), animated: true)
        }

        self.scrollView.bounces = false
        self.scrollView.isPagingEnabled = true
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.delegate = self
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { (make) in
            make.left.right.width.bottom.equalToSuperview()
            make.top.equalTo(segment.getControlView().snp.bottom)
        }

        // 避免scrollView遮挡segment的投影
        bringSubviewToFront(segment.getControlView())
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(views: [(title: String, view: UIView)]) {
        clear()
        self.viewsWithTitle = views
        segment.setItems(titles: views.map { $0.title })
        self.setViews(views: views.map { $0.view })
        self.scrollView.setContentOffset(CGPoint.zero, animated: false)
    }

    func add(views: [(title: String, view: UIView)]) {
        segment.addItems(titles: views.map { $0.title })
        self.viewsWithTitle += views
        setViews(views: viewsWithTitle.map { $0.view })
    }

    func clear() {
        segment.clearAllItems()
        viewsWithTitle.forEach { $0.view.removeFromSuperview() }
        viewsWithTitle = []
        self.scrollView.contentSize = CGSize.zero
    }

    public func setCurrentView(index: Int, animated: Bool = true) {
        guard index < viewsWithTitle.count && index >= 0 else {
            return
        }
        if !animated {
            segment.setSelectedItem(index: index, isScrolling: false)
        }
        self.scrollView.setContentOffset(CGPoint(x: viewWidth * CGFloat(index), y: 0), animated: animated)
    }

    func removeView(at: Int) {
        guard at < viewsWithTitle.count && at >= 0 else {
            return
        }
        segment.removeItem(at: at)
        viewsWithTitle.remove(at: at)
        setViews(views: viewsWithTitle.map { $0.view })
    }

    func insert(viewWithTitle: (title: String, view: UIView), at: Int) {
        guard at >= 0 else {
            return
        }
        segment.insertItem(title: viewWithTitle.title, at: at)
        if at < self.viewsWithTitle.count {
            self.viewsWithTitle.insert(viewWithTitle, at: at)
        } else {
            self.viewsWithTitle.append(viewWithTitle)
        }
        setViews(views: viewsWithTitle.map { $0.view })
        guard viewWidth > 0 else { return }
        let index = scrollView.contentOffset.x / viewWidth
        if at <= Int(index) {
            self.scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x + viewWidth, y: 0), animated: false)
        }
    }

    private func setViews(views: [UIView]) {
        self.scrollView.contentSize = CGSize(width: viewWidth * CGFloat(views.count), height: 0)
        for i in 0..<views.count {
            let view = views[i]
            let viewLeftConstraint = i == 0 ? scrollView.snp.left : views[i - 1].snp.right
            self.scrollView.addSubview(view)
            view.snp.remakeConstraints({ (make) in
                make.left.equalTo(viewLeftConstraint)
                make.height.centerY.equalTo(scrollView)
                make.width.equalTo(scrollView)
            })
        }
    }

    open override func layoutSubviews() {
        let oldWidth = viewWidth
        /* 在被添加到父View的时候和屏幕旋转的时候调用，因此在调整UI的时候需要判断是否是因为屏幕滑动导致的方法调用 */
        isUpdateWidth = true
        defer { isUpdateWidth = false }
        super.layoutSubviews() // trigger autolayout update, may call scrollViewDidScroll
        if viewWidth != oldWidth {
            updateUI()
        }
    }

    private func updateUI() {
        if !self.viewsWithTitle.isEmpty {
            // 设置内容页
            self.scrollView.contentSize = CGSize(width: viewWidth * CGFloat(self.viewsWithTitle.count), height: 0)
            // 设置选中区
            segment.updateUI(width: viewWidth)
            self.setCurrentView(index: segment.currentSelectedIndex, animated: false)
        }
    }
}

extension SegmentView: UIScrollViewDelegate {
    // MARK: scrollview delegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /* 当屏幕修改后会设置scrollView在新宽度下的偏移量，会触发这个方法。在这里加锁避免偏移 */
        guard !isUpdateWidth else {
            return
        }
        self.segment.setOffset(offset: currentScrollIndex, isDragging: scrollView.isDragging)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.segment.setOffset(offset: currentScrollIndex, isDragging: false)
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        self.segment.setOffset(offset: currentScrollIndex, isDragging: false)
    }
}
