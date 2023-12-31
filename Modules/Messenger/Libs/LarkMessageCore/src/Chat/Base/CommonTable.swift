//
//  CommonTable.swift
//  LarkChat
//
//  Created by zc09v on 2019/1/22.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LKCommonsTracker
import LarkCore
import LarkKeyCommandKit
import LKCommonsLogging
import LarkFoundation
import RxSwift

/*
 1. 带上/下拉加载更多
 2. 刷新table,并保证最后一个cell完整显示(可选带动画)
 3. 刷新一组cell,保证最后一个cell完整显示
 4. 滚动到底部
 5. 判断table当前是否在底部
 6. 前/后插入cells
 */

@objc
public enum ScrollViewHeaderRefreshStyle: Int {
    case activityIndicator
    case rotateArrow
}

public enum ScrollViewLoadMoreStatus {
    case start
    case finish(ScrollViewLoadMoreResult)
}

public enum ScrollViewLoadMoreResult {
    case success(sdkCost: Int64 = 0, valid: Bool) //vaild 返回的数据是否有效
    case error
    case noWork //不处理
    public func isValid() -> Bool {
        switch self {
        case .success(sdkCost: _, valid: let valid):
            return valid
        case .noWork:
            return true
        case .error:
            return false
        }
    }
}

open class CommonTable: UITableView, CommonScrollViewLoadMoreDelegate {

    private static let logger = Logger.log(CommonTable.self, category: "lark.chat.CommonTable")
    public static let scrollToBottomAnimationDuration = 0.15
    public static let scrollToTopAnimationDuration = 0.15
    public let loadMoreHeight: CGFloat = 44
    private let disposeBag = DisposeBag()

    /*加载更多历史消息后，因为会往table头部插入数据，造成table偏移，代码上通过设置contenoffset使table保持不动，
     但实际上初始偏移还是产生了(虽然用户看不到)，偏移区域的cellWillDisplay也会被调用，不符合预期，加入变量控制，在偏移期间不调用cellWillDisplay*/
    public var willDisplayEnable: Bool = true
    public var headInserting: Bool = false

    public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.scrollsToTop = false
        self.setLoadMoreHandlerDelegate(self)
        /*点击状态栏默认触发table滚动到顶部时，当接近顶部时会触发预加载，导致新的一屏数据被插入到前部，系统发现没有到顶部，就会又去滚动，继而又触发预先加载,
         此处hook状态栏点击，发送通知，table监听通知，使用setContentOffset to zero 不会产生相应问题*/
        NotificationCenter.default.rx
            .notification(Notification.statusBarTapped.name)
            .subscribe(onNext: { [weak self] (notification) in
                if let `self` = self, UIStatusBarHookManager.viewShouldResponse(of: self, for: notification) {
                    self.statusBarTap()
                }
            }).disposed(by: disposeBag)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func keyBindings() -> [KeyBindingWraper] {
        return super.keyBindings() + [
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputUpArrow,
                modifierFlags: .control,
                discoverabilityTitle: BundleI18n.LarkMessageCore.Lark_Legacy_iPadShortcutsScrollUp
            ).binding(
                target: self,
                selector: #selector(scrollToUp)
            ).wraper,
            KeyCommandBaseInfo(
                input: UIKeyCommand.inputDownArrow,
                modifierFlags: .control,
                discoverabilityTitle: BundleI18n.LarkMessageCore.Lark_Legacy_iPadShortcutsScrollDown
            ).binding(
                target: self,
                selector: #selector(scrollToDown)
            ).wraper
        ]
    }

    //展示loading时会产生回调
    open func showTopLoadMore(status: ScrollViewLoadMoreStatus) {

    }

    //展示loading时会产生回调
    open func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {

    }

    open func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        assertionFailure("子类需要重写该方法")
    }

    open func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        assertionFailure("子类需要重写该方法")
    }

    open func reloadAndGuarantLastCellVisible(animated: Bool = false) {
        let tableStickToBottom = self.stickToBottom()
        self.reloadData()
        if tableStickToBottom {
            if animated {
                UIView.animate(withDuration: CommonTable.scrollToBottomAnimationDuration) {
                    self.scrollToBottom(animated: false)
                }
            } else {
                self.scrollToBottom(animated: false)
            }
        }
    }

    open func refresh(indexPaths: [IndexPath], animation: UITableView.RowAnimation = .fade, guarantLastCellVisible: Bool) {
        let visibleIndexPaths = indexPaths.filter { (indexPath) -> Bool in
            return self.indexPathsForVisibleRows?.contains(indexPath) ?? false
        }

        if !visibleIndexPaths.isEmpty {
            let needReloadTable: () -> Bool = { [unowned self] () -> Bool in
                for index in visibleIndexPaths {
                    guard let cell = self.cellForRow(at: index) else {
                        continue
                    }
                    if cell.frame.origin.y < self.contentOffset.y {
                        return true
                    } else if cell.frame.maxY > self.contentOffset.y + self.frame.height {
                        return true
                    }
                }
                return false
            }
            /// 只有 cell 未完全展示时 reloadRows animation 会跳动, 用 reloadData 取代
            if needReloadTable() {
                self.reloadData()
            } else {
                self.reloadRows(at: visibleIndexPaths, with: animation)
            }

            let tableStickToBottom = guarantLastCellVisible ? self.stickToBottom() : false
            if tableStickToBottom, guarantLastCellVisible {
                self.scrollToBottom(animated: false)
            }
        }
    }

    open func scrollToBottom(animated: Bool, scrollPosition: ScrollPosition = .bottom) {
        let numberOfSections = self.numberOfSections
        guard numberOfSections > 0 else {
            return
        }
        for i in 1 ... numberOfSections {
            let section = numberOfSections - i
            let rowNum = self.numberOfRows(inSection: section)
            if rowNum > 0 {
                let indexPath = IndexPath(row: rowNum - 1, section: section)
                self.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
                break
            }
        }
    }

    open func scrollToTop(animated: Bool) {
        let numberOfSections = self.numberOfSections
        guard numberOfSections > 0, numberOfRows(inSection: 0) > 0 else {
            return
        }
        self.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: animated)
    }

    /// 是否表格视图贴低
    open func stickToBottom() -> Bool {
        let tableContentOffsetY = self.contentOffset.y
        let offsetMax = tableViewOffsetMaxY()
        // 内容高度很低，未达到视图的高度
        if offsetMax <= 0 {
            return true
        }
        return offsetMax <= tableContentOffsetY + 1
    }

    /// 是否表格视图贴顶
    open func stickToTop() -> Bool {
        if self.contentOffset.y <= 0 {
            return true
        }
        return false
    }

    open func headInsertCells(hasHeader: Bool) {
        self.willDisplayEnable = false
        self.headInserting = true
        self.hasHeader = hasHeader
        let originHeight = self.contentSize.height
        let offsetY = self.contentOffset.y
        self.reloadData()
        self.layoutIfNeeded()
        let newHeight = self.contentSize.height
        let change = newHeight - originHeight

        let newContentOffset: CGPoint
        if offsetY <= -self.contentInset.top {
            newContentOffset = CGPoint(x: 0, y: offsetY + change - loadMoreHeight)
        } else {
            newContentOffset = CGPoint(x: 0, y: offsetY + change)
        }

        self.contentOffset = newContentOffset
        if Utils.isiOSAppOnMacSystem {
            // Mac 直接设置 offset 会导致错误偏移, 先使用 animated 的方式设置 后续优化
            self.setContentOffset(newContentOffset, animated: true)
        }

        self.willDisplayEnable = true
        self.headInserting = false
    }

    open func appendCells(hasFooter: Bool) {
        self.reloadData()
        self.layoutIfNeeded()
        self.hasFooter = hasFooter
    }

    /// 表格视图能达到的最大偏移：内容总高度 - 视图高度
    open func tableViewOffsetMaxY() -> CGFloat {
        let contentHeight = self.contentSize.height
        let viewHeight = self.frame.size.height
        let offsetMax = contentHeight - viewHeight
        return offsetMax
    }

    private func statusBarTap() {
        if self.window != nil {
            self.setContentOffset(.zero, animated: true)
            CommonTable.logger.info("chatTrace table statusBarTap")
        }
    }

    @objc
    func scrollToUp() {
        let scrollOffset: CGFloat = self.frame.height / 2
        let contentYOffset = self.contentOffset.y
        let minYOffset: CGFloat = 0

        if contentYOffset > minYOffset {
            self.setContentOffset(
                CGPoint(
                    x: self.contentOffset.x,
                    y: max(contentYOffset - scrollOffset, minYOffset)
                ),
                animated: true
            )
        }
        CommonTable.logger.info("chatTrace table scrollToUp")
    }

    @objc
    func scrollToDown() {
        let scrollOffset: CGFloat = self.frame.height / 2
        let contentYOffset = self.contentOffset.y
        let maxYOffset: CGFloat = self.contentSize.height - self.frame.height

        if contentYOffset < maxYOffset {
            self.setContentOffset(
                CGPoint(
                    x: self.contentOffset.x,
                    y: min(contentYOffset + scrollOffset, maxYOffset)
                ),
                animated: true
            )
        }

    }
}

extension CommonTable: UIScrollViewDelegate {
    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.excutePreload()
    }
}
