//
//  InnerScrollViewController.swift
//  LarkSegmentController
//
//  Created by kongkaikai on 2018/12/10.
//  Copyright © 2018 kongkaikai. All rights reserved.
//

import Foundation
import UIKit

// swiftlint:disable missing_docs
public protocol PageInnerScrollableController {
    typealias PageInnerScrollViewDidScrollHandler = (_ scrollView: UIScrollView) -> Void

    var reuseIdentifier: String? { get set }
    var pageIndex: Int { get set }
    var innerScrollView: UIScrollView { get }

    /// 必须在 innerScrollView 的 ScrollViewDidScroll 调用该回调以保证滚动效果正常
    var innerScrollViewDidScroll: PageInnerScrollViewDidScrollHandler? { get set }

    /// 由于重用，ViewController有生命周期问题，但是 SegmentViewControllerDataSource 会在将要显示ViewController的View之前d回调该方法
    func reloadData()

    /// 将要切换页面回调
    func pageWillTransition()
    func pageDidTransition()
}

open class PageInnerTableViewController: UITableViewController, PageInnerScrollableController {
    public var reuseIdentifier: String?
    public var pageIndex: Int = 0
    public var innerScrollView: UIScrollView {
        return tableView
    }

    public var innerScrollViewDidScroll: PageInnerScrollViewDidScrollHandler?

    override open func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.setNavigationBarHidden(true, animated: false)
        tableView.contentInsetAdjustmentBehavior = .never
    }

    override open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        innerScrollViewDidScroll?(scrollView)
    }

    open func reloadData() {
        self.tableView.reloadData()
    }

    open func pageWillTransition() {
        self.tableView.reloadData()
    }

    open func pageDidTransition() {}
}
// swiftlint:enable missing_docs
