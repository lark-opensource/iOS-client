//
//  MinutesPagingView.swift
//  Minutes
//
//  Created by chenlehui on 2021/12/28.
//

import UIKit

enum HeaderVisibleStatus: Int {
    case invisible = 0, // 不可见
         partVisible,  // 展示部分
         fullVisible  // 展示完整
}

enum ScrollState {
    case scrollViewCanScroll
    case tableViewCanScroll
}

enum ScrollDirection: Int {
    case unknown = 0,
         up,  // 向上滑动
         down  // 向下滑动
}

@objc protocol MinutesPagingViewDelegate {
    /// tableHeaderView的高度，因为内部需要比对判断，只能是整型数
    func headerViewHeight(in pagingView: MinutesPagingView) -> CGFloat
    /// 返回tableHeaderView
    func headerView(in pagingView: MinutesPagingView) -> UIView
    ///headerview是否不滚动
    func canHeaderViewScroll(in pagingView: MinutesPagingView) -> Bool
    /// 返回悬浮HeaderView的高度，因为内部需要比对判断，只能是整型数
    func heightForPinSectionHeader(in pagingView: MinutesPagingView) -> CGFloat
    /// 返回悬浮HeaderView
    func viewForPinSectionHeader(in pagingView: MinutesPagingView) -> UIView
    /// 返回列表的数量
    func numberOfLists(in pagingView: MinutesPagingView) -> Int
    /// 根据index初始化一个对应列表实例，需要是遵从`PagingViewListViewDelegate`协议的对象。
    /// 如果列表是用自定义UIView封装的，就让自定义UIView遵从`PagingViewListViewDelegate`协议，该方法返回自定义UIView即可。
    /// 如果列表是用自定义UIViewController封装的，就让自定义UIViewController遵从`PagingViewListViewDelegate`协议，该方法返回自定义UIViewController即可。
    ///
    /// - Parameters:
    ///   - pagingView: pagingView description
    ///   - index: 新生成的列表实例
    func pagingView(_ pagingView: MinutesPagingView, initListAtIndex index: Int) -> PagingViewListViewDelegate
    /// 将要被弃用！请使用pagingView(_ pagingView: PagingView, mainTableViewDidScroll scrollView: UIScrollView) 方法作为替代。
    @available(*, message: "Use pagingView(_ pagingView: PagingView, mainTableViewDidScroll scrollView: UIScrollView) method")
    @objc optional func mainScrollViewDidScroll(_ scrollView: UIScrollView)
    @objc optional func pagingView(_ pagingView: MinutesPagingView, mainScrollViewWillBeginDragging scrollView: UIScrollView)
}

class MinutesPagingView: UIView {

    weak var delegate: MinutesPagingViewDelegate?

    lazy var mainScrollView: MinutesScrollView = {
        let scrollView = MinutesScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.ud.bgBody
        return scrollView
    }()

    private(set) lazy var listContainerView: PagingListContainerView = {
        let list = PagingListContainerView(dataSource: self, type: .scrollView)
        return list
    }()

    var currentScrollView: MinutesTableView? {
        return listContainerView.currentListView as? MinutesTableView
    }

    var headerView: UIView?
    var pinView: UIView?

    init(delegate: MinutesPagingViewDelegate) {
        super.init(frame: .zero)
        self.delegate = delegate
        setupViews()
        observeOffsetChange()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        addSubview(mainScrollView)
        guard let delegate = delegate else {
            return
        }
        mainScrollView.addSubview(delegate.headerView(in: self))
        mainScrollView.addSubview(delegate.viewForPinSectionHeader(in: self))
        mainScrollView.addSubview(listContainerView)
        headerView = delegate.headerView(in: self)
        pinView = delegate.viewForPinSectionHeader(in: self)
        listContainerView.reloadData()
    }

    func updateLayout() {
        guard let delegate = delegate else {
            return
        }
        mainScrollView.frame = bounds
        let headerHeight = delegate.headerViewHeight(in: self)
        let pinHeight = delegate.heightForPinSectionHeader(in: self)
        headerView?.frame = CGRect(x: 0, y: 0, width: bounds.width, height: headerHeight)
        pinView?.frame = CGRect(x: 0, y: headerHeight, width: bounds.width, height: pinHeight)
        listContainerView.frame = CGRect(x: 0, y: headerHeight + pinHeight, width: bounds.width, height: bounds.height - pinHeight)
        mainScrollView.contentSize = CGSize(width: bounds.width, height: bounds.height + headerHeight)
    }

    func showHeader(animated: Bool = true) {
        mainScrollView.setContentOffset(.zero, animated: animated)
    }

    func hideHeader(animated: Bool = true) {
        guard let delegate = delegate else {
            return
        }
        mainScrollView.setContentOffset(CGPoint(x: 0, y: delegate.headerViewHeight(in: self)), animated: animated)
    }

    func reloadData() {
        listContainerView.reloadData()
    }

    func isHeaderVisible() -> Bool {
        guard let delegate = delegate else {
            return false
        }
        return mainScrollView.contentOffset.y < delegate.headerViewHeight(in: self) - 10
    }
}

extension MinutesPagingView: PagingListContainerViewDataSource {

    func numberOfLists(in listContainerView: PagingListContainerView) -> Int {
        guard let delegate = delegate else { return 0 }
        return delegate.numberOfLists(in: self)
    }

    func listContainerView(_ listContainerView: PagingListContainerView, initListAt index: Int) -> PagingViewListViewDelegate? {
        guard let delegate = delegate else { fatalError("JXPaingView.delegate must not be nil") }
        return delegate.pagingView(self, initListAtIndex: index)
    }
}

extension MinutesPagingView: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.mainScrollViewDidScroll?(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.pagingView?(self, mainScrollViewWillBeginDragging: scrollView)
    }
}

extension MinutesPagingView {

    func observeOffsetChange() {
        guard let currentScrollView = currentScrollView else { return }
        // 解决手势冲突
        mainScrollView.innerScrollView = currentScrollView
        currentScrollView.outerScrollView = mainScrollView
        let task = { [weak self, weak currentScrollView] (scrollView: UIScrollView, oldOffset: CGPoint, newOffset: CGPoint) -> Bool in
            guard let self = self, let cscrollView = currentScrollView else { return false }
            return self.judgeIsScroll(scrollView: scrollView,
                                      moduleScrollView: cscrollView,
                                      oldOffset: oldOffset,
                                      newOffset: newOffset)
        }
        mainScrollView.contentOffsetChanging = task
        currentScrollView.contentOffsetChanging = task
    }

    func judgeIsScroll(scrollView: UIScrollView,
                       moduleScrollView: UIScrollView,
                       oldOffset: CGPoint,
                       newOffset: CGPoint) -> Bool {
        guard newOffset != oldOffset else { return false }

        // 滑动方向，ture为上滑，false为下拉
        var isScrollUP = newOffset.y > oldOffset.y
        if scrollView != self.mainScrollView, scrollView.contentOffset.y < -scrollView.adjustedContentInset.top { // 解决快速滑到顶端的抖动
            isScrollUP = false
        }
        // 临界值
        let headerHeight: CGFloat = delegate?.headerViewHeight(in: self) ?? 0
        let criticalValue = headerHeight
        // 使用旧值判断
        let oldScrollOffsetY: CGFloat
        let oldListOffsetY: CGFloat

        var minListOffsetY: CGFloat = 0
        if scrollView === self.mainScrollView {
            oldScrollOffsetY = oldOffset.y
            oldListOffsetY = moduleScrollView.contentOffset.y
            minListOffsetY = -moduleScrollView.adjustedContentInset.top
        } else {
            oldScrollOffsetY = self.mainScrollView.contentOffset.y
            oldListOffsetY = oldOffset.y
            minListOffsetY = -scrollView.adjustedContentInset.top
        }
        /*
         主要是以下两个主要条件：
            1. headerVisibleStatus：header的可见状态
            2. isListTop：moduleScrollView的y值是否在自身的顶部

         疑问点：
            1. 在即将要进行检测是否可滑动时，先调用了[super setContentOffset: newOffset]，其实不应该先调用，而是等结果再来决定是否。但是尝试了下，动画效果不行，offset变化幅度太大
            1. 使用旧值作为判断是否可以滑动的条件，却没有使用新值判断，需要进一步思考这块
            2. 使用旧值而不是新值来禁止滑动，即使加上了纠偏，但也需要进一步思考
         */
        let headerVisibleStatus: HeaderVisibleStatus
        if oldScrollOffsetY <= 0 {
            headerVisibleStatus = .fullVisible
        } else if oldScrollOffsetY > 0 && Int(oldScrollOffsetY) < Int(criticalValue) {
            headerVisibleStatus = .partVisible
        } else {
            headerVisibleStatus = .invisible
        }
        let isListTop = oldListOffsetY <= minListOffsetY

        // 默认scrollView可滑动
        var scrollState: ScrollState = .scrollViewCanScroll
        switch headerVisibleStatus {
        case .fullVisible:
            if !isScrollUP {
                // 当header全部可见时 & tableview的y值没有处于顶部时 & 下拉时
                scrollState = .tableViewCanScroll
            }
        case .partVisible:
            break
        case .invisible:
            if isListTop {
                if isScrollUP {
                    // 当header不显示时 & 当tableview的y值处于顶部时 & 上滑时：tableview可以滑动
                    scrollState = .tableViewCanScroll
                }
            } else {
                // 当header不显示时 & 当tableview的y值没有处于顶部时：tableview可以滑动
                scrollState = .tableViewCanScroll
            }
        }

        // 兜底，当header不显示时，直接让tableView可以滑动
        if headerHeight <= 0 {
            scrollState = .tableViewCanScroll
        }

        let canHeaderViewScroll = self.delegate?.canHeaderViewScroll(in: self) ?? true
        if canHeaderViewScroll == false {
            scrollState = .tableViewCanScroll
        }

        switch scrollState {
        case .scrollViewCanScroll:
            let scrollCanScroll = scrollView === self.mainScrollView
            return scrollCanScroll
        case .tableViewCanScroll:
            let tableCanScroll = scrollView === moduleScrollView
            return tableCanScroll
        }
    }
}
