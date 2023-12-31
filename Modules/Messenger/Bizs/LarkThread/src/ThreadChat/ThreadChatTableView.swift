//
//  ThreadChatTableView.swift
//  LarkThread
//
//  Created by zc09v on 2019/2/18.
//

import UIKit
import Foundation
import LarkCore
import RxSwift
import RxCocoa
import EENavigator
import LarkModel
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface
import LarkInteraction
import RustPB
import LarkSDKInterface
import LarkUIKit
import LarkFeatureGating
import LarkContainer

protocol ThreadChatTableViewDelegate: AnyObject {
    var hasDisplaySheetMenu: Bool { get }
    func threadWillDisplay(thread: RustPB.Basic_V1_Thread)
    /// 长按出菜单时，有哪些遮挡区域需要规避
    func menuCustomInserts() -> UIEdgeInsets
    func showTopLoadMore(status: ScrollViewLoadMoreStatus)
    func showBottomLoadMore(status: ScrollViewLoadMoreStatus)
    func chatModel() -> Chat
    func tableviewDidSelectRowAt(indexPath: IndexPath)
}
extension ThreadChatTableViewDelegate {
    func tableviewDidSelectRowAt(indexPath: IndexPath) {}
}

/// tableView viewModel 扩展其通用性
protocol ThreadListViewModel: UserResolverWrapper {

    /// 话题高亮的Postion
    var highlightPosition: Int32? { get set }

    /// 拷贝一份的CellViewModel保证在主线程中，不受子线程异步处理CellViewModel的影响。
    var uiDataSource: [ThreadCellViewModel] { get }

    /// 加载更旧的话题
    ///
    /// - Parameter finish: ((Bool) -> Void)?
    func loadMoreBottomMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?)

    /// 加载更新的话题
    ///
    /// - Parameter finish: ((Bool) -> Void)?
    func loadMoreTopMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?)

    /// 通过id寻找thread的index
    ///
    /// - Parameter id: String
    /// - Returns: Int?
    func findThreadIndexBy(id: String) -> Int?

    /// 通过id寻找ThreadCellViewModel
    ///
    /// - Parameter id: String
    /// - Returns: ThreadCellViewModel?
    func cellViewModel(by id: String) -> ThreadCellViewModel?

    /// 发已读
    func putRead(threadMessage: ThreadMessage)
}

final class ThreadChatTableView: ThreadBusinessTableview, UITableViewDelegate, UITableViewDataSource, PostViewContentCopyProtocol {
    private static let logger = Logger.log(ThreadChatTableView.self, category: "LarkThread")
    private let disposeBag = DisposeBag()
    private var viewModel: ThreadListViewModel
    /// 点击高亮渐现，退出时高亮渐隐。记录高亮的threadID
    private var hightlightThreadID: String?
    private var longPressGesture: UILongPressGestureRecognizer!
    weak var chatTableDelegate: ThreadChatTableViewDelegate?
    /// 最小的内容高度
    var minContentSizeHeight: CGFloat = 0
    /// view did show. 判断界面是否在界面内
    var showViewEnable = true

    // 如果为true，则tableview只接收上下滑动事件
    let isOnlyReceiveScroll: Bool

    lazy var keepOffsetRefreshRefactorEnable: Bool =
        viewModel.userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "ios.chattable.offset.refactor"))

    init(viewModel: ThreadListViewModel,
         isOnlyReceiveScroll: Bool = false) {
        self.viewModel = viewModel
        self.isOnlyReceiveScroll = isOnlyReceiveScroll
        super.init(frame: .zero, style: .plain)
        self.dataSource = self
        self.delegate = self
        self.separatorStyle = .none
        self.backgroundColor = UIColor.clear
        self.contentInsetAdjustmentBehavior = .never

        self.longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)), duration: Display.pad ? 0.3 : 0.2, target: self)
        self.longPressGesture.allowableMovement = 5
        let rightClick = RightClickRecognizer(target: self, action: #selector(bubbleLongPressed(_:)))
        self.addGestureRecognizer(rightClick)

        self.observeApplicationState()
        self.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeObserver(self, forKeyPath: "contentSize")
    }

    // 查找可以响应事件的view
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isOnlyReceiveScroll {
            guard isUserInteractionEnabled, !isHidden, alpha > 0.01, self.point(inside: point, with: event) else { return nil }
            /// 不往下继续查找
            return self
        }
        return super.hitTest(point, with: event)
    }

    // 触摸事件的处理方法
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isOnlyReceiveScroll {
            return
        }
        super.touchesBegan(touches, with: event)
    }

    // 手势事件的处理方法
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if isOnlyReceiveScroll {
            guard gestureRecognizer.view == self else {
                return super.gestureRecognizerShouldBegin(gestureRecognizer)
            }
            guard panGestureRecognizer == gestureRecognizer else {
                return false
            }
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
        return super.gestureRecognizerShouldBegin(gestureRecognizer)
    }

    override func showTopLoadMore(status: ScrollViewLoadMoreStatus) {
        self.chatTableDelegate?.showTopLoadMore(status: status)
    }

    override func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {
        self.chatTableDelegate?.showBottomLoadMore(status: status)
    }

    override func loadMoreBottomContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        self.viewModel.loadMoreBottomMessages(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        self.viewModel.loadMoreTopMessages(finish: finish)
    }

    override func headInsertCells(hasHeader: Bool) {
        super.headInsertCells(hasHeader: hasHeader)
        // trigger cells invoke willDisplay(cell:) method. because headInsertCells(hasHeader:) will prevent cell invoke willDisplay(cell:).
        // 重新触发当前屏幕内的cell willDisplay(cell:)方法，因为headInsertCells(hasHeader:)会阻止cell调用willDisplay(cell:)。导致屏幕内的消息已读无法正常触发。
        ThreadChatTableView.logger.info("LarkThread: headInsertCells and triggerVisibleCellsDisplay")
        self.displayVisibleCells()
    }

    @objc
    public func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            let location = gesture.location(in: self)
            if let indexPath = self.indexPathForRow(at: location),
                let cell = self.cellForRow(at: indexPath) as? MessageCommonCell,
                let cellVM = self.viewModel.uiDataSource[indexPath.row] as? ThreadMessageCellViewModel {
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
              let cellVM = self.viewModel.uiDataSource[indexPath.row] as? ThreadMessageCellViewModel else {
            return
        }
        if let chat = self.chatTableDelegate?.chatModel() {
            IMTracker.Chat.Main.Click.MsgPress(chat, cellVM.threadMessage.rootMessage, .ignored)
        }
        self.showMenu(
            cell,
            location: triggerView.convert(triggerView.bounds.center, to: self),
            cellVM: cellVM,
            triggerGesture: nil
        )
    }

    func showMenu(_ cell: MessageCommonCell, location: CGPoint, cellVM: ThreadMessageCellViewModel, triggerGesture: UIGestureRecognizer?) {
        let extraInfo: [String: Any] = self.postViewCopyInfoForCell(cell, location: location)
        let displayView: ((Bool) -> UIView?)? = { [weak cell, weak self] _ -> UIView? in
            guard let cell = cell, let self = self else { return nil }
            //文本view
            var contentView: UIView?
            //翻译
            let displayRule = cellVM.threadMessage.rootMessage.displayRule
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
            return contentView
        }
        let (selectConstraintKey, copyType) = getPostViewComponentConstant(cell, location: location)
        cellVM.showMenu(cell,
                        location: self.convert(location, to: cell),
                        displayView: displayView,
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
                let cellVM = viewModel.uiDataSource[indexPath.row]
                cellVM.didEndDisplay()
            }
        }
    }

    // swiftlint:disable:next block_based_kvo
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if self.contentSize.height < self.minContentSizeHeight {
                self.contentSize = CGSize(width: self.contentSize.width, height: self.minContentSizeHeight)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    func willDisplay(cell: UITableViewCell, indexPath: IndexPath) {
        guard self.willDisplayEnable, indexPath.row < viewModel.uiDataSource.count else {
            ThreadChatTableView.logger.error("LarkThread error: willDisplay guard return \(self.willDisplayEnable) \(indexPath.row) \(viewModel.uiDataSource.count)")
            return
        }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        // 在屏幕内的才触发vm的willDisplay
        if self.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            cellVM.willDisplay()
        }

        // showViewEnable: update read state when view in screen.
        // showViewEnable: 只有在屏幕内是才需要更新消息已读。
        if showViewEnable,
            let messageCellVM = cellVM as? HasThreadMessage {
            self.viewModel.putRead(threadMessage: messageCellVM.getThreadMessage())
            self.chatTableDelegate?.threadWillDisplay(thread: messageCellVM.getThread())
            if messageCellVM.getThread().position == self.viewModel.highlightPosition {
                (cell as? MessageCommonCell)?.highlightView()
                self.viewModel.highlightPosition = nil
            }
        }
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
        let hasDisplaySheetMenu = self.chatTableDelegate?.hasDisplaySheetMenu ?? false
        self.chatTableDelegate?.tableviewDidSelectRowAt(indexPath: indexPath)
        guard !hasDisplaySheetMenu else { return }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        cellVM.didSelect()
        // 点击发送失败的话题没有高亮效果
        if (cellVM as? HasThreadMessage)?.getRootMessage().localStatus == .success {
            showHighlight(with: indexPath, cellViewModel: cellVM)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.uiDataSource.count else {
            ThreadChatTableView.logger.error("LarkThread error: cellForRowAt index out of range")
            assertionFailure("please contact lizhiqiang@bytedance.com")
            return UITableViewCell()
        }
        let cellVM = viewModel.uiDataSource[indexPath.row]
        let cellId = (cellVM as? HasThreadMessage)?.getThread().id ?? ""
        let cell = cellVM.dequeueReusableCell(tableView, cellId: cellId)
        // 小组中点击话题时的高亮状态。
        if let hightlightThreadID = hightlightThreadID,
            cellId == hightlightThreadID,
            let hightlightCell = (cell as? ThreadMessageCell) {
            hightlightCell.showHighlightView(animation: false)
        } else if let hightlightCell = (cell as? ThreadMessageCell) {
            hightlightCell.hideHighlightView(animation: false)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightFor(indexPath)
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return heightFor(indexPath)
    }

    private func heightFor(_ indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < viewModel.uiDataSource.count else {
            ThreadChatTableView.logger.error("LarkThread error: heightFor index out of range")
            assertionFailure("please contact lizhiqiang@bytedance.com")
            return 0
        }
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }

    private func showHighlight(with indexPath: IndexPath, cellViewModel: ThreadCellViewModel) {
        if let cell = self.cellForRow(at: indexPath) as? ThreadMessageCell,
            let threadID = (cellViewModel as? HasThreadMessage)?.getThread().id {
            self.hightlightThreadID = threadID
            cell.showHighlightView()
        }
    }

    func hideHighlight() {
        // 寻找高亮cellViewModel
        let indexTmp = self.viewModel.uiDataSource.firstIndex { (cellVM) -> Bool in
            if let hightlightThreadID = hightlightThreadID,
                let threadID = (cellVM as? HasThreadMessage)?.getThread().id,
                threadID == hightlightThreadID {
                return true
            }
            return false
        }

        guard let index = indexTmp,
            let cell = self.cellForRow(at: IndexPath(row: index, section: 0)) as? ThreadMessageCell else {
            return
        }

        cell.hideHighlightView(completion: { [weak self] (_) in
            self?.hightlightThreadID = nil
        }, animation: true)
    }

    func firstVisibleMessageCellInfo() -> (messagePosition: Int32, frame: CGRect)? {
        for indexPath in self.indexPathsForVisibleRows ?? [] {
            if let cellVM = (viewModel.uiDataSource[indexPath.row] as? HasThreadMessage), let cell = self.cellForRow(at: indexPath) {
                return (messagePosition: cellVM.getRootMessage().position, frame: cell.frame)
            }
        }
        return nil
    }

    func getVisibleCell(by messagePosition: Int32) -> UITableViewCell? {
        for indexPath in self.indexPathsForVisibleRows ?? [] {
            if let cellVM = (viewModel.uiDataSource[indexPath.row] as? HasThreadMessage), cellVM.getRootMessage().position == messagePosition {
                return self.cellForRow(at: indexPath)
            }
        }
        return nil
    }
}

extension ThreadChatTableView: VisiblePositionRange, KeepOffsetRefresh {
    func position(by indexPath: IndexPath) -> Int32? {
        let model = self.viewModel.uiDataSource[indexPath.row]
        return (model as? HasThreadMessage)?.getThreadMessage().position
    }

    func newOffsetY(by cell: UITableViewCell) -> CGFloat? {
        if let cell = cell as? MessageCommonCell,
            !cell.cellId.isEmpty,
            let index = self.viewModel.findThreadIndexBy(id: cell.cellId) {
            // 存放第一个消息cell前面所有cell的高度
            var newY: CGFloat = 0
            for i in 0..<index {
                newY += self.viewModel.uiDataSource[i].renderer.size().height
            }
            // 加上headerView的高度
            newY += self.tableHeaderView?.frame.size.height ?? 0
            return newY
        }
        return nil
    }
}
