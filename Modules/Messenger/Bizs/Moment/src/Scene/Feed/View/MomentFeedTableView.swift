//
//  MomentFeedTableView.swift
//  Moment
//
//  Created by zc09v on 2021/1/5.
//

import UIKit
import Foundation
import LarkMessageCore

protocol MomentFeedTableViewDelegate: AnyObject {
    func refreshPosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func loadMorePosts(finish: @escaping (ScrollViewLoadMoreResult) -> Void)
    func cellViewModel(indexPath: IndexPath) -> PolybasicCellViewModelProtocol
    func supportTopTipStyle() -> Bool
}

extension MomentFeedTableViewDelegate {
    func supportTopTipStyle() -> Bool { false }
}

final class MomentLinkagePostTableView: MomentFeedTableView {
    var canMove = false
    var lastOffSet: CGPoint = .zero
    var autoStartLinkage = true
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        if autoStartLinkage {
           onContentOffsetDidChange()
        }
    }

    func onContentOffsetDidChange() {
        if contentOffset.equalTo(lastOffSet) {
            return
        }
        if !canMove {
            contentOffset = lastOffSet
        }
        lastOffSet = contentOffset
    }

    override func willStartShowPostTip() {
        if !canMove {
            canMove = true
        }
    }
}

final class MomentUserPostTableView: MomentFeedTableView {
    override func headerRefreshStyle() -> ScrollViewHeaderRefreshStyle {
        return .activityIndicator
    }
}

//table 相关代理方法都可以收敛在这里
enum PostTipStyle {
    case success
    case empty
    case fail
}

class MomentFeedTableView: CommonTable, PostCellCanHandleLongPress {
    weak var momentFeedTableViewDelegate: MomentFeedTableViewDelegate?
    private(set) var longPressGesture: UILongPressGestureRecognizer!

    /// 该方法会在tableView顶部弹出提示，使用时无需关心当前是否在loading
    /// 内部已经处理了如果tableView 正在刷新的情况
    /// - Parameters:
    ///   - style: 顶部提示的延时
    ///   - finishResetHeader: 弹出之后，是否需要tableView的loadingView重新设置了
    func showPostTip(_ style: PostTipStyle?, finishResetHeader: Bool) {
        guard let style = style, self.momentFeedTableViewDelegate?.supportTopTipStyle() == true else {
            if finishResetHeader { self.hasHeader = true }
            return
        }
        let tipHeight: CGFloat = self.loadMoreHeight
        /// 将要开始展示tip
        self.willStartShowPostTip()
        let view = MomentsPostTipView(style: style)
        self.addSubview(view)
        let beginContentInset = self.contentInset
        var adjustContentInsert = false
        let enabled = self.topLoadMoreView?.enabled
        if self.contentInset.top < tipHeight {
            self.contentInset = UIEdgeInsets(top: tipHeight,
                                             left: self.contentInset.left,
                                             bottom: self.contentInset.bottom,
                                             right: self.contentInset.right)
            adjustContentInsert = true
            self.topLoadMoreView?.enabled = false
            /// 这里设置tableView offset 之前需要判断一些情况 比如用户已经滑动了，就不要设置了
            if self.contentOffset.y <= 0 {
                self.contentOffset = CGPoint(x: self.contentOffset.x, y: -tipHeight)
            }
        }
        view.frame = CGRect(x: 0, y: -contentInset.top - tipHeight, width: self.frame.width, height: tipHeight)
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            view.frame = CGRect(x: 0, y: -self.contentInset.top, width: self.frame.width, height: tipHeight)
        }
        let block = { [weak self] in
            if finishResetHeader {
                self?.hasHeader = finishResetHeader
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9, execute: { [weak self] in
            guard let self = self else { return }
            /// 如果直接没有调整过顶部的间距 直接重设header
            if !adjustContentInsert {
                block()
            }
            UIView.animate(withDuration: 0.25) {
                /// 如果直接没有调整过顶部的间距 直接重设header，需要等恢复原状在设置header 这样才不会影响下拉刷新
                if adjustContentInsert {
                    self.contentInset = beginContentInset
                    block()
                }
                view.alpha = 0
            } completion: { _ in
                view.removeFromSuperview()
                /// 如果不需要重置的话 设为原来的状态
                if let enabled = enabled, !finishResetHeader {
                    self.topLoadMoreView?.enabled = enabled
                }
            }
        })
    }

    func willStartShowPostTip() { }

    override func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        if contentOffset.y <= 0 {
            //防止下拉刷新时误触发预加载
            finish(.noWork)
            return
        }
        momentFeedTableViewDelegate?.loadMorePosts(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        momentFeedTableViewDelegate?.refreshPosts(finish: finish)
    }
    override func headerRefreshStyle() -> ScrollViewHeaderRefreshStyle {
        return .rotateArrow
    }

    init() {
        super.init(frame: .zero, style: .plain)
        self.contentInsetAdjustmentBehavior = .never
        self.longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)), duration: 0.2, target: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    public func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            // locationInSelf
            let location = gesture.location(in: self)
            self.showMenu(location: location, gesture: gesture)
        default:
            break
        }
    }

    func showMenu(location: CGPoint, gesture: UIGestureRecognizer) {
        guard let indexPath = self.indexPathForRow(at: location),
            let cell = self.cellForRow(at: indexPath) as? MomentCommonCell,
            cell.bounds.contains(self.convert(location, to: cell)),
            let cellVM = self.momentFeedTableViewDelegate?.cellViewModel(indexPath: indexPath) else {
            return
        }
        let locationInCell = self.convert(location, to: cell)
        let result = self.canHandle(cell: cell, location: locationInCell)
        if result.canHandle {
            cellVM.showMenu(cell, location: self.convert(location, to: cell), triggerGesture: gesture)
        }
    }

}
