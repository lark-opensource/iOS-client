//
//  MessageDetailTableView.swift
//  Action
//
//  Created by 赵冬 on 2019/7/23.
//

import Foundation
import UIKit
import LarkContainer
import RxSwift
import RxCocoa
import SnapKit
import LarkCore
import Swinject
import LarkMessageCore
import LarkModel
import LarkMessageBase
import LKCommonsLogging
import RichLabel
import LarkMessengerInterface
import LarkInteraction
import LarkUIKit
import UniverseDesignColor
import LarkSearchCore
import LarkFeatureGating

protocol MessageDetailTableDelegate: AnyObject {
    func tapTableHandler()
}

final class LoadingHeaderView: UITableViewHeaderFooterView {
    var titleLabel: UILabel = .init()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        titleLabel = UILabel()
        titleLabel.font = UIFont.ud.body2
        titleLabel.textColor = UIColor.ud.textPlaceholder
        titleLabel.text = BundleI18n.LarkChat.Lark_Legacy_LoadingLoading
        contentView.addSubview(titleLabel)
        contentView.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(5)
            make.height.equalTo(UIFont.ud.body2.rowHeight)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MessageDetailTableView: CommonTable, UITableViewDelegate, UITableViewDataSource, PostViewContentCopyProtocol {

    private static let logger = Logger.log(MessageDetailTableView.self, category: "LarkChat.MessageDetail")

    private let viewModel: MessageDetailMessagesViewModel

    private let chatFromWhere: ChatFromWhere

    weak var detailTableDelegate: MessageDetailTableDelegate?

    private(set) var longPressGesture: UILongPressGestureRecognizer!

    private var isShowLoading: Bool = false

    private var isShowError: Bool = false

    struct MessageDetailTableViewDelegateProxy {
        var willDisplayCell: ((ChatUITableViewEvent) -> Void)?
        var didEndDisplayingCell: ((ChatUITableViewEvent) -> Void)?
        var willBeginDragging: (() -> Void)?
        var didEndDecelerating: (() -> Void)?
        var didEndDragging: ((Bool) -> Void)?
    }

    var delegateProxy = MessageDetailTableViewDelegateProxy()

    init(viewModel: MessageDetailMessagesViewModel, chatFromWhere: ChatFromWhere) {
        self.viewModel = viewModel
        self.chatFromWhere = chatFromWhere
        super.init(frame: .zero, style: .plain)
        self.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        self.dataSource = self
        self.delegate = self
        self.separatorStyle = .none
        self.contentInsetAdjustmentBehavior = .never
        self.estimatedSectionHeaderHeight = 0
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            self.sectionHeaderTopPadding = 0
        }
        #endif
        self.register(LoadingHeaderView.self, forHeaderFooterViewReuseIdentifier: String(describing: LoadingHeaderView.self))
        self.longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)), duration: Display.pad ? 0.3 : 0.2, target: self)
        self.longPressGesture.allowableMovement = 5
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)

        let rightClick = RightClickRecognizer(target: self, action: #selector(bubbleLongPressed(_:)))
        self.addGestureRecognizer(rightClick)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func remakeConstraints(height: ConstraintRelatableTarget,
                           bottom: ConstraintRelatableTarget,
                           bottomOffset: CGFloat = 0,
                           isImmediatelyLayout: Bool = true) {
        self.snp.remakeConstraints({ make in
            make.left.right.equalToSuperview()
            make.height.equalTo(height)
            make.bottom.equalTo(bottom).offset(bottomOffset)
        })
        if isImmediatelyLayout {
            self.superview?.layoutIfNeeded()
        } else {
            self.superview?.setNeedsLayout()
        }
    }

    @objc
    func tapHandler(_ gesture: UITapGestureRecognizer) {
        // for other business like locktable when lklabel tap, if lklable handle the tap, do not fold the keyboard automaticlly
        // 如果LKLabel响应了事件，不做收起键盘, 交由LKLabel的对应事件处理，因为有先锁住table再收起键盘等需求
        let location = gesture.location(in: self)
        let hitTestView = self.hitTest(location, with: UIEvent())
        if hitTestView as? LKLabel != nil {
            MessageDetailTableView.logger.info("MessageDetailTableView: LKLabel handle tap")
        } else {
            detailTableDelegate?.tapTableHandler()
        }
    }

    @objc
    public func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            /// locationInSelf
            let location = gesture.location(in: self)
            self.showMenuIfNeeded(location: location, triggerByDrag: false, triggerGesture: gesture)
        default:
            break
        }
    }

    public func showMenuIfNeeded(location: CGPoint, triggerByDrag: Bool, triggerGesture: UIGestureRecognizer? = nil) {
        guard let indexPath = self.indexPathForRow(at: location),
            let cell = self.cellForRow(at: indexPath) as? MessageCommonCell,
            let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.row] as? MessageDetailMessageCellViewModel else {
                return
        }

        if let content = cell.getView(by: MessageDetailCellConsts.containerKey),
           content.bounds.contains(self.convert(location, to: content)) {
            /// 如果是拖拽触发手势，添加标记
            let (selectConstraintKey, copyType) = getPostViewComponentConstant(cell, location: location)
            let displayViewBlock: ((Bool) -> UIView?) = { [weak cell, weak self] hasCursor in
                guard let cell = cell, let self = self else { return nil }
                if triggerByDrag {
                    return cell.getView(by: PostViewComponentConstant.bubbleKey) ?? cell
                } else {
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
            }
            cellVM.showMenu(cell,
                            location: self.convert(location, to: cell),
                            displayView: displayViewBlock,
                            triggerGesture: nil,
                            copyType: copyType,
                            selectConstraintKey: selectConstraintKey)
        } else if let avatar = cell.getView(by: MessageDetailCellConsts.avatarKey),
                  avatar.bounds.contains(self.convert(location, to: avatar)) {
            // 长按头像
            cellVM.avatarLongPressed()
        }
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

    func initCells(isDisplayLoad: Bool, isSucceed: Bool?) {
        self.isShowLoading = isDisplayLoad
        if let isSucceed = isSucceed {
            self.isShowError = !isSucceed
        }
        self.reloadData()
    }

    func reloadAndGuarantLastCellVisible(isForceScrollToBottom: Bool = false, animated: Bool = false) {
        let tableStickToBottom = self.stickToBottom()
        self.reloadData()
        let isMoreThanLimit = self.contentSize.height > self.frame.height
        guard isMoreThanLimit else { return }
        if tableStickToBottom || isForceScrollToBottom {
            if animated {
                DispatchQueue.main.async {
                    UIView.animate(withDuration: CommonTable.scrollToBottomAnimationDuration) {
                        self.scrollToBottom(animated: false)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.scrollToBottom(animated: false)
                }
            }
        }
    }
    // MARK: - UITableViewDelegate, UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1, self.isShowLoading {
            let header = self.dequeueReusableHeaderFooterView(withIdentifier: String(describing: LoadingHeaderView.self))
            if let loadingHeader = header as? LoadingHeaderView, self.isShowError {
                loadingHeader.titleLabel.text = BundleI18n.LarkChat.Lark_Legacy_LoadingFailed
                return loadingHeader
            }
            return header
        }
        return nil
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1, self.isShowLoading {
            return 30
        }
        return 0
    }

    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition = .top, animated: Bool = false) {
        if self.indexPathsForVisibleRows?.contains(indexPath) ?? false,
            let cell = self.cellForRow(at: indexPath) {
            self.willDisplay(cell: cell, indexPath: indexPath)
        }
        // Prevent indexPath from crossing the boundary and causing crash
        if self.viewModel.uiDataSource[indexPath.section].count > indexPath.row {
            super.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        } else {
            MessageDetailTableView.logger.error("indexPath越界 \(indexPath)")
            assertionFailure("indexPath越界 \(indexPath)，请保存上下文联系赵冬排查修复\n indexPath out of bounds \(indexPath), please save the context to contact Zhao Dong troubleshooting repair")
        }

    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.willDisplay(cell: cell, indexPath: indexPath)
    }

    func willDisplay(cell: UITableViewCell, indexPath: IndexPath) {
        guard indexPath.section < viewModel.uiDataSource.count,
            indexPath.row < self.viewModel.uiDataSource[indexPath.section].count else {
                assertionFailure("保留现场！！！")
                return
        }
        let cellVM = viewModel.uiDataSource[indexPath.section][indexPath.row]

        // 在屏幕内的才触发vm的willDisplay
        if self.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            cellVM.willDisplay()
        }

        if let messageCellVM = cellVM as? HasMessage {
            self.viewModel.putRead(element: messageCellVM.message)
        }
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        delegateProxy.didEndDisplayingCell?((cell, indexPath))
        // 不在屏幕内的才触发didEndDisplaying
        guard let cell = cell as? MessageCommonCell,
            let cellVM = self.viewModel.cellViewModel(by: cell.cellId) else {
                return
        }
        if !(self.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            cellVM.didEndDisplay()
        }
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.viewModel.uiDataSource.isEmpty { return 0 }
        return self.viewModel.uiDataSource[section].count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < viewModel.uiDataSource.count,
            indexPath.row < self.viewModel.uiDataSource[indexPath.section].count else {
                assertionFailure("保留现场！！！")
                return UITableViewCell()
        }
        let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.row]
        let cellId = (cellVM as? HasMessage)?.message.id ?? ""
        return cellVM.dequeueReusableCell(tableView, cellId: cellId)
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < viewModel.uiDataSource.count,
            indexPath.row < self.viewModel.uiDataSource[indexPath.section].count else {
                assertionFailure("保留现场！！！")
                return 0
        }
        return viewModel.uiDataSource[indexPath.section][indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.section < viewModel.uiDataSource.count,
            indexPath.row < self.viewModel.uiDataSource[indexPath.section].count else {
                assertionFailure("保留现场！！！")
                return 0
        }
        return viewModel.uiDataSource[indexPath.section][indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.row]
        cellVM.didSelect()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.delegateProxy.willBeginDragging?()
        if scrollView.isTracking {
            self.detailTableDelegate?.tapTableHandler()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.delegateProxy.didEndDecelerating?()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.delegateProxy.didEndDragging?(decelerate)
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        // change the tableview bottom when view layout was finished
        self.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: 9 + self.safeAreaInsets.bottom,
            right: 0
        )
    }
}

extension MessageDetailTableView: DragContainer {
    func dragInteractionEnable(location: CGPoint) -> Bool {
        return true
    }

    func dragInteractionIgnore(location: CGPoint) -> Bool {
        return false
    }

    func dragInteractionContext(location: CGPoint) -> DragContext? {
        guard let indexPath = self.indexPathForRow(at: location),
            let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.row] as? MessageDetailMessageCellViewModel else {
            return nil
        }
        var context = DragContext()
        let chat = cellVM.metaModel.getChat()
        let message = cellVM.message
        context.set(key: DragContextKey.chat, value: chat, identifier: chat.id)
        context.set(key: DragContextKey.message, value: message, identifier: message.id)
        if let downloadFileScene = cellVM.context.downloadFileScene {
            context.set(key: DragContextKey.downloadFileScene, value: downloadFileScene, identifier: message.id)
        }
        return context
    }

    func dragInteractionForward(location: CGPoint) -> UIView? {
        guard let indexPath = self.indexPathForRow(at: location),
            let cell = self.cellForRow(at: indexPath) as? MessageCommonCell else {
            return nil
        }
        return cell
    }
}
