//
//  DocESPullRefreshAnimator.swift
//  SpaceKit
//
//  Created by litao_dev on 2020/5/28.
//
//  Included OSS: GodEye
//  Copyright (c) 2017 陈奕龙(子循)
//  spdx license identifier: MIT

import Foundation
import ESPullToRefresh

class DocESRefreshFooterAnimator: ESRefreshFooterAnimator {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.subviews.forEach { (view) in
            if let titleLabel = view as? UILabel {
                titleLabel.textColor = UIColor.ud.N500
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class DocESRefreshHeaderAnimator: ESRefreshHeaderAnimator {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.subviews.forEach { (view) in
            if let titleLabel = view as? UILabel {
                titleLabel.textColor = UIColor.ud.N500
            }
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension ES where Base: UIScrollView {
    // Add pull-to-refresh
//    @discardableResult
//    func addPullToRefreshOfDoc(handler: @escaping ESRefreshHandler) -> ESRefreshHeaderView {
//        removeRefreshHeader()
//        let header = DocESRefreshHeaderView(frame: CGRect.zero, handler: handler)
//        let headerH = header.animator.executeIncremental
//        header.frame = CGRect(x: 0.0, y: -headerH /* - contentInset.top */, width: self.base.bounds.size.width, height: headerH)
//        self.base.addSubview(header)
//        self.base.header = header
//        return header
//    }

    @discardableResult
    public func addPullToRefreshOfDoc(animator: ESRefreshProtocol & ESRefreshAnimatorProtocol, handler: @escaping ESRefreshHandler) -> ESRefreshHeaderView {
        removeRefreshHeader()
        let header = DocESRefreshHeaderView(frame: CGRect.zero, handler: handler, animator: animator)
        let headerH = animator.executeIncremental
        header.frame = CGRect(x: 0.0, y: -headerH /* - contentInset.top */, width: self.base.bounds.size.width, height: headerH)
        self.base.addSubview(header)
        self.base.header = header
        return header
    }

//    /// Add infinite-scrolling
//    @discardableResult
//    public func addInfiniteScrollingOfDoc(handler: @escaping ESRefreshHandler) -> ESRefreshFooterView {
//        removeRefreshFooter()
//        let footer = DocESRefreshFooterView(frame: CGRect.zero, handler: handler)
//        let footerH = footer.animator.executeIncremental
//        footer.frame = CGRect(x: 0.0, y: self.base.contentSize.height, width: self.base.bounds.size.width, height: footerH)
//        self.base.addSubview(footer)
//        self.base.footer = footer
//        return footer
//    }

    @discardableResult
    public func addInfiniteScrollingOfDoc(animator: ESRefreshProtocol & ESRefreshAnimatorProtocol, handler: @escaping ESRefreshHandler) -> ESRefreshFooterView {
        removeRefreshFooter()
        let footer = DocESRefreshFooterView(frame: CGRect.zero, handler: handler, animator: animator)
        let footerH = footer.animator.executeIncremental
        footer.frame = CGRect(x: 0.0, y: self.base.contentSize.height, width: self.base.bounds.size.width, height: footerH)
        self.base.footer = footer
        self.base.addSubview(footer)
        return footer
    }

}
