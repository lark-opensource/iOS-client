//
//  ThreadDetailTableView.swift
//  LarkFeed
//
//  Created by zc09v on 2019/3/1.
//

import Foundation
import RxSwift
import SnapKit
import LarkCore
import RichLabel
import AsyncComponent
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface
import LarkInteraction
import LarkUIKit
import UIKit
import LarkFeatureGating
import LarkOpenChat
import LarkContainer

protocol DetailTableDelegate: AnyObject {
    var menuService: MessageMenuOpenService? { get }
    func tapHandler()
    func showTopLoadMore(status: ScrollViewLoadMoreStatus)
    func showBottomLoadMore(status: ScrollViewLoadMoreStatus)
    func showMenuForCellVM(cellVM: ThreadDetailCellVMGeneralAbility)
    func willDisplay(cell: UITableViewCell, cellVM: ThreadDetailCellViewModel)
}

extension DetailTableDelegate {
    var menuService: MessageMenuOpenService? { nil }
}
protocol ThreadDetailTableViewDataSource: AnyObject, UserResolverWrapper {
    var uiDataSource: [[ThreadDetailCellViewModel]] { get }
    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?)
    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?)
    func showHeader(section: Int) -> Bool
    func showFooter(section: Int) -> Bool
    func footerBackgroundColor(section: Int) -> UIColor?
    func showReplyMessageLastSepratorLine(section: Int) -> Bool
    func replyCount() -> Int
    func replysIndex() -> Int
    func cellViewModel(by id: String) -> ThreadDetailCellViewModel?
    func findMessageIndexBy(id: String) -> IndexPath?
    func threadHeaderForSection(_ section: Int, replyCount: Int) -> UIView?
    func threadHeaderHeightFor(section: Int) -> CGFloat
    func threadFooterHeightFor(section: Int) -> CGFloat
    func threadReplyMessagesFooterHeightFor(section: Int) -> CGFloat
}
extension ThreadDetailTableViewDataSource {
    func footerBackgroundColor(section: Int) -> UIColor? {
        return nil
    }
    func threadHeaderForSection(_ section: Int, replyCount: Int) -> UIView? {
        return nil
    }
    func threadHeaderHeightFor(section: Int) -> CGFloat {
        return DetailViewConfig.headerHeight
    }
    func threadFooterHeightFor(section: Int) -> CGFloat {
        return DetailViewConfig.footerHeight
    }
    func threadReplyMessagesFooterHeightFor(section: Int) -> CGFloat {
        return DetailViewConfig.replyMessagesFooterHeight
    }
}

struct DetailViewConfig {
    static var headerHeight: CGFloat {
        return ThreadDetailHeader.Cons.headerHeight
    }
    static let footerHeight: CGFloat = 8
    static let replyMessagesFooterHeight: CGFloat = 12
}

final class ThreadDetailTableView: ThreadBusinessTableview, UITableViewDelegate, UITableViewDataSource, PostViewContentCopyProtocol {
    private let disposeBag = DisposeBag()
    private let viewModel: ThreadDetailTableViewDataSource
    private(set) var longPressGesture: UILongPressGestureRecognizer!
    private static let logger = Logger.log(ThreadDetailTableView.self, category: "LarkThread.ThreadDetailTableView")
    private let chatFromWhere: ChatFromWhere

    weak var detailTableDelegate: DetailTableDelegate?

    lazy var keepOffsetRefreshRefactorEnable: Bool =
        viewModel.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "ios.chattable.offset.refactor"))

    init(viewModel: ThreadDetailTableViewDataSource, tableDelegate: DetailTableDelegate?, chatFromWhere: ChatFromWhere = .ignored) {
        self.viewModel = viewModel
        self.detailTableDelegate = tableDelegate
        self.chatFromWhere = chatFromWhere
        super.init(frame: .zero, style: .grouped)

        self.dataSource = self
        self.delegate = self
        self.separatorStyle = .none
        self.backgroundColor = UIColor.clear
        self.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
        self.contentInsetAdjustmentBehavior = .never

        self.longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)), duration: Display.pad ? 0.3 : 0.2, target: self)
        self.longPressGesture.allowableMovement = 5

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)

        let rightClick = RightClickRecognizer(target: self, action: #selector(bubbleLongPressed(_:)))
        self.addGestureRecognizer(rightClick)

        self.backgroundColor = UIColor.ud.bgBody

        self.observeApplicationState()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        self.viewModel.loadMoreNewMessages(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        self.viewModel.loadMoreOldMessages(finish: finish)
    }

    override func reloadAndGuarantLastCellVisible(animated: Bool = false) {
        let tableStickToBottom = self.stickToBottom()
        self.reloadData()
        // contentSize立即生效，避免可能存在大量刷新时造成高度抖动。
        self.layoutIfNeeded()
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

    override func headInsertCells(hasHeader: Bool) {
        super.headInsertCells(hasHeader: hasHeader)
        // trigger cells invoke willDisplay(cell:) method. because headInsertCells(hasHeader:) will prevent cell invoke willDisplay(cell:).
        // 重新触发当前屏幕内的cell willDisplay(cell:)方法，因为headInsertCells(hasHeader:)会阻止cell调用willDisplay(cell:)。导致屏幕内的消息已读无法正常触发。
        ThreadDetailTableView.logger.info("LarkThread: headInsertCells and triggerVisibleCellsDisplay")
        self.displayVisibleCells()
    }

    func showRoot(rootHeight: CGFloat) {
        let oldHeight = self.contentSize.height
        let odlOffsetY = self.contentOffset.y
        self.reloadData()
        self.layoutIfNeeded()
        let newHeight = self.contentSize.height
        self.contentOffset = CGPoint(x: 0, y: odlOffsetY + newHeight - oldHeight)
    }

    @objc
    func tapHandler(_ gesture: UITapGestureRecognizer) {
        // for other business like locktable when lklabel tap, if lklable handle the tap, do not fold the keyboard automaticlly
        // 如果LKLabel响应了事件，不做收起键盘, 交由LKLabel的对应事件处理，因为有先锁住table再收起键盘等需求
        let location = gesture.location(in: self)
        let hitTestView = self.hitTest(location, with: UIEvent())
        if hitTestView as? LKLabel != nil {
            ThreadDetailTableView.logger.info("ThreadDetailTableView: LKLabel handle tap")
        } else {
            detailTableDelegate?.tapHandler()
        }
    }

    @objc
    public func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            let location = gesture.location(in: self)
            if let indexPath = self.indexPathForRow(at: location),
                let cell = self.cellForRow(at: indexPath) as? MessageCommonCell,
                let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.row] as? ThreadDetailCellVMGeneralAbility {
                // 长按展示菜单
                self.showMenu(cell, location: location, cellVM: cellVM, triggerGesture: gesture)
            }
        default:
            break
        }
    }

    func showMenu(from triggerView: UIView) {
        var target = triggerView
        while !(target is MessageCommonCell), let superview = target.superview {
            target = superview
        }
        guard let cell = target as? MessageCommonCell,
              let indexPath = self.indexPath(for: cell),
              let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.row] as? ThreadDetailCellVMGeneralAbility else {
            return
        }
        self.showMenu(
            cell,
            location: triggerView.convert(triggerView.bounds.center, to: self),
            cellVM: cellVM,
            triggerGesture: nil
        )
    }

    func showMenu(_ cell: MessageCommonCell, location: CGPoint, cellVM: ThreadDetailCellVMGeneralAbility, triggerGesture: UIGestureRecognizer?) {
        self.detailTableDelegate?.showMenuForCellVM(cellVM: cellVM)
        let (selectConstraintKey, copyType) = getPostViewComponentConstant(cell, location: location)
        let displayViewBlock: ((Bool) -> UIView?) = { [weak cell, weak self] hasCursor in
            guard let cell = cell, let self = self else { return nil }
            if !hasCursor {
                return cell.getView(by: PostViewComponentConstant.bubbleKey)
            }
            //文本view
            var contentView: UIView?
            //翻译
            let displayRule = cellVM.message.displayRule
            if displayRule == .noTranslation {//原文
                contentView = cell.getView(by: PostViewComponentConstant.contentKey)
            } else if displayRule == .onlyTranslation {//译文
                contentView = cell.getView(by: PostViewComponentConstant.translateContentKey)
            } else if displayRule == .withOriginal {
                //在原文里
                if let label = cell.getView(by: PostViewComponentConstant.contentKey),
                   label.bounds.contains(self.convert(location, to: label)) {
                    contentView = label
                    // 点在翻译内容里
                } else if let contentLabel = cell.getView(by: PostViewComponentConstant.translateContentKey),
                          contentLabel.bounds.contains(self.convert(location, to: contentLabel)) {
                    contentView = contentLabel
                }
            }
            //没有文本view返回气泡
            return (contentView ?? cell.getView(by: PostViewComponentConstant.bubbleKey)) ?? cell
        }
        cellVM.showMenu(cell,
                        location: self.convert(location, to: cell),
                        displayView: displayViewBlock,
                        triggerGesture: triggerGesture,
                        copyType: copyType,
                        selectConstraintKey: selectConstraintKey)
    }

    private func observeApplicationState() {
        NotificationCenter.default.rx
            .notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.displayVisibleCells()
            }).disposed(by: self.disposeBag)
    }

    func displayVisibleCells() {
        for cell in self.visibleCells {
            if let indexPath = self.indexPath(for: cell) {
                self.willDisplay(cell: cell, indexPath: indexPath)
            }
        }
    }

    func endDisplayVisibleCells() {
        for cell in self.visibleCells {
            if let indexPath = self.indexPath(for: cell) {
                let cellVM = viewModel.uiDataSource[indexPath.section][indexPath.row]
                cellVM.didEndDisplay()
            }
        }
    }

    func willDisplay(cell: UITableViewCell, indexPath: IndexPath) {
        guard self.willDisplayEnable,
            indexPath.section < viewModel.uiDataSource.count,
            indexPath.row < viewModel.uiDataSource[indexPath.section].count else {
                ThreadDetailTableView.logger.error(
                    """
                    LarkThread error: willDisplay guard return
                    \(self.willDisplayEnable)
                    \(indexPath.row)
                    \(indexPath.section)
                    \(viewModel.uiDataSource.count)
                    """
                )
            return
        }
        let cellVM = viewModel.uiDataSource[indexPath.section][indexPath.row]
        // 在屏幕内的才触发vm的willDisplay
        if self.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            cellVM.willDisplay()
        }
        self.detailTableDelegate?.willDisplay(cell: cell, cellVM: cellVM)
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if UIApplication.shared.applicationState != .background {
            self.willDisplay(cell: cell, indexPath: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.delegateProxy.didEndDisplayingCell?((cell, indexPath))
        guard let cell = cell as? MessageCommonCell,
            let cellVM = self.viewModel.cellViewModel(by: cell.cellId) else {
                return
        }
        // 不在屏幕内的才触发didEndDisplaying
        if !(self.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            cellVM.didEndDisplay()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let cellVM = viewModel.uiDataSource[indexPath.section][indexPath.row]
        cellVM.didSelect()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.heightFor(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.heightFor(indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.heightFor(header: section)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return self.heightFor(header: section)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return self.heightFor(footer: section)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return self.heightFor(footer: section)
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.viewModel.showFooter(section: section) {
            let view = UIView(frame: .zero)
            view.backgroundColor = self.viewModel.footerBackgroundColor(section: section) ?? UIColor.ud.bgBase
            return view
        } else if self.viewModel.showReplyMessageLastSepratorLine(section: section) {
            let view = UIView(frame: .zero)
            let lineView = UIView()
            lineView.backgroundColor = UIColor.ud.lineDividerDefault
            view.addSubview(lineView)
            lineView.snp.makeConstraints { (make) in
                make.leading.bottom.trailing.equalToSuperview()
                make.height.equalTo(1.0 / UIScreen.main.scale)
            }
            return view
        }
        return nil
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if self.viewModel.showHeader(section: section) {
            let header = self.viewModel.threadHeaderForSection(section, replyCount: self.viewModel.replyCount())
            return header ?? ThreadDetailHeader(repliesCount: self.viewModel.replyCount())
        }
        return nil
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.uiDataSource[section].count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellVM = viewModel.uiDataSource[indexPath.section][indexPath.row]
        let cellId = (cellVM as? HasMessage)?.message.id ?? ""
        let cell = cellVM.dequeueReusableCell(tableView, cellId: cellId)
        return cell
    }

    private func heightFor(indexPath: IndexPath) -> CGFloat {
        /// 这里做个防御 如果取值范围超标 VM不存 返回0
        guard indexPath.section < self.viewModel.uiDataSource.count,
              indexPath.row < self.viewModel.uiDataSource[indexPath.section].count else {
                  assertionFailure("保留现场！！！")
                  return 0
              }
        return self.viewModel.uiDataSource[indexPath.section][indexPath.row].renderer.size().height
    }

    private func heightFor(header section: Int) -> CGFloat {
        if self.viewModel.showHeader(section: section) {
            return self.viewModel.threadHeaderHeightFor(section: section)
        }
        return CGFloat.leastNormalMagnitude
    }

    private func heightFor(footer section: Int) -> CGFloat {
        if self.viewModel.showFooter(section: section) {
            return self.viewModel.threadFooterHeightFor(section: section)
        } else if self.viewModel.showReplyMessageLastSepratorLine(section: section) {
            return self.viewModel.threadReplyMessagesFooterHeightFor(section: section)
        }
        return CGFloat.leastNormalMagnitude
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        super.scrollViewWillBeginDragging(scrollView)
        if scrollView.isTracking {
            self.detailTableDelegate?.tapHandler()
        }
        detailTableDelegate?.menuService?.hideMenuIfNeeded(animated: true)
    }

    private var needDecelerate: Bool = false
    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        if decelerate {
            needDecelerate = true
            return
        }
        needDecelerate = false
        updateMenuStateWhenEndScroll()
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView)
        if needDecelerate {
            updateMenuStateWhenEndScroll()
        }
    }

    // 停止滚动时处理 menu 状态
    private func updateMenuStateWhenEndScroll() {
        let tableShowRect = CGRect(
            x: self.contentOffset.x,
            y: self.contentOffset.y,
            width: self.frame.width,
            height: self.frame.height
        )
        if let triggerView = detailTableDelegate?.menuService?.currentTriggerView {
            // 判断菜单是否在页面内部
            if triggerView.frame.intersects(tableShowRect) {
                detailTableDelegate?.menuService?.unhideMenuIfNeeded(animated: true)
            } else {
                detailTableDelegate?.menuService?.dissmissMenu(completion: nil)
            }
        }
    }

    override func showTopLoadMore(status: ScrollViewLoadMoreStatus) {
        self.detailTableDelegate?.showTopLoadMore(status: status)
    }

    override func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {
        self.detailTableDelegate?.showBottomLoadMore(status: status)
    }

    func scrollsToMaxOffsetY(animated: Bool = false) {
        let maxOffset = self.tableViewOffsetMaxY()
        if maxOffset > 0 {
            self.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: animated)
        }
    }

    func scrollToOffsetY(_ offsetY: CGFloat, animated: Bool = false) {
        if offsetY > 0 {
            self.setContentOffset(CGPoint(x: self.contentOffset.x, y: offsetY), animated: animated)
        } else {
            self.setContentOffset(CGPoint(x: self.contentOffset.x, y: 0), animated: animated)
        }
    }

}

extension ThreadDetailTableView: KeepOffsetRefresh {
    func newOffsetY(by cell: UITableViewCell) -> CGFloat? {
        if let cell = cell as? MessageCommonCell,
            !cell.cellId.isEmpty,
            let index = self.viewModel.findMessageIndexBy(id: cell.cellId) {
            var newY: CGFloat = 0
            for i in 0..<index.row {
                newY +=
                    self.viewModel.uiDataSource[self.viewModel.replysIndex()][i].renderer.size().height
            }
            return newY
        }
        return nil
    }
}
