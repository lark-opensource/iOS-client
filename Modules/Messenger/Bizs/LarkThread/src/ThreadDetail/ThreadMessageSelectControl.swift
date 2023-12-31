//
//  ThreadMessageSelectControl.swift
//  LarkThread
//
//  Created by bytedance on 2020/12/4.
//

import Foundation
import RxSwift
import LarkModel
import RxCocoa
import LarkFoundation
import LKCommonsLogging
import SnapKit
import LarkUIKit
import LarkContainer
import LarkCore
import LarkKeyboardView
import UIKit.UIGestureRecognizerSubclass
import RichLabel
import LarkMessageCore
import LarkMessageBase
import LarkMenuController
import LarkInteraction
import UniverseDesignToast
import LarkMessengerInterface
import LKRichView
import LarkEMM
import LarkOpenChat

typealias ThreadUITableViewEvent = (cell: UIView, indexPath: IndexPath)

protocol ThreadUITableView: UITableView {

    var raw: UITableView { get }

    func didEndDisplayingCell(_ callback: @escaping (ThreadUITableViewEvent) -> Void)

    func willBeginDragging(_ callback: @escaping () -> Void)

    func didEndDecelerating(_ callback: @escaping () -> Void)

    func didEndDragging(_ callback: @escaping (Bool) -> Void)
    /// 滚动到底部
    func scrollToBottom(animated: Bool, scrollPosition: ScrollPosition)
}

protocol ThreadCopyDataSoucre: UIViewController {
    var _chat: Chat? { get }
    func index(of messageId: String) -> IndexPath?
    func cellContentIsSelectableForIndexPath(_ indexPath: IndexPath, labelKey: String) -> Bool
    func resumeQueue()
    func pauseQueue()
    func lockTableHeightAndOffset()
    func unlockTableHeightAndOffset()
}

/// 复制需要在遵守的协议
protocol ThreadSelectControlHostController: ThreadCopyDataSoucre, UserResolverWrapper {
    var keyboardView: ThreadKeyboardView? { get }
    var _tableView: ThreadUITableView { get }
    var tableTopBlockHeight: CGFloat? { get }
    /// 不使用字典后的函数
    func findSelectedLabelAndStatus(messageId: String, postViewComponentConstant: String?) -> (LKSelectionLabel, Bool)?
    func findSelectedViewAndStatus(messageId: String, postViewComponentConstant: String?) -> (LKRichContainerView, Bool)?
    // 找到Thread的底层View
    func findThreadFloorView(by child: UIView) -> UIView
    func menuWillHide(inputWillBecomeFirstResponder: Bool)
    func showMenuByPointerDrag(for label: LKSelectionLabel)
}

// ThreadCopyDataSoucre 默认实现
extension ThreadCopyDataSoucre {
    var _chat: Chat? {
        return nil
    }

    func cellContentIsSelectableForIndexPath(_ indexPath: IndexPath, labelKey: String) -> Bool {
        return false
    }

    func index(of messageId: String) -> IndexPath? {
        return nil
    }

    func resumeQueue() {

    }

    func pauseQueue() {

    }

    func lockTableHeightAndOffset() {

    }

    func unlockTableHeightAndOffset() {
    }
}

/// ThreadSelectControlHostController 默认实现
extension ThreadSelectControlHostController {

    var keyboardView: ThreadKeyboardView? {
        return nil
    }

    var _tableView: ThreadUITableView {
        return ThreadBusinessTableview()
    }

    /// 话题群老版消息卡片仍然在使用LKLabel,相关逻辑不能下掉.
    func findSelectedLabelAndStatus(messageId: String, postViewComponentConstant: String?) -> (LKSelectionLabel, Bool)? {
        /// 没有有效的tag，直接返回nil
        guard let labelKey = postViewComponentConstant else { return nil }
        if let indexPath = self.index(of: messageId),
           let cell = self._tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? MessageCommonCell {
            /// 原文/译文 label
            guard let selectionLabel = cell.getView(by: labelKey) as? LKSelectionLabel else {
                return nil
            }
            let selectable = self.cellContentIsSelectableForIndexPath(indexPath, labelKey: labelKey)
            return (selectionLabel, selectable)
        }
        return nil
    }

    /// 新版长按处理不使用字典传参
    func findSelectedViewAndStatus(messageId: String, postViewComponentConstant: String?) -> (LKRichContainerView, Bool)? {
        /// 没有有效的tag，直接返回nil
        guard let labelKey = postViewComponentConstant else { return nil }

        if let indexPath = self.index(of: messageId),
           let cell = self._tableView.cellForRow(at: IndexPath(row: indexPath.row, section: indexPath.section)) as? MessageCommonCell {
            /// 原文/译文 RichView
            guard let selectionView = cell.getView(by: labelKey) as? LKRichContainerView else {
                return nil
            }
            /// 获取selectable
            let selectable = self.cellContentIsSelectableForIndexPath(indexPath, labelKey: labelKey)
            return (selectionView, selectable)
        }
        return nil
    }

    /// 找到最底层的View,即MessageCommonCell -> 处理手势
    func findThreadFloorView(by child: UIView) -> UIView {
        var target = child
        while !(target is MessageCommonCell), let superview = target.superview {
            target = superview
        }
        assert(target is MessageCommonCell)
        return target
    }

    func menuWillHide(inputWillBecomeFirstResponder: Bool) {

    }

}

extension ThreadFilterController: ThreadCopyDataSoucre {
    /// 弹出的chat
    var _chat: Chat? {
        return self.messagesViewModel.chatWrapper.chat.value
    }

    /// 消息所在的idx
    func index(of messageId: String) -> IndexPath? {
        if let row = self.messagesViewModel.getThreadIndexForMessage(id: messageId) {
            return IndexPath(row: row, section: 0)
        }
        return nil
    }

    func cellContentIsSelectableForIndexPath(_ indexPath: IndexPath, labelKey: String) -> Bool {
        guard indexPath.row < self.messagesViewModel.uiDataSource.count else {
            return false
        }
        var selectable = true
        let cellVM = self.messagesViewModel.uiDataSource[indexPath.row] as? LarkMessageBase.ThreadMessageCellViewModel<ThreadMessageMetaModel, ThreadCellMetaModelDependency>
        if let content = cellVM?.content as? TextPostContentViewModel {
            selectable = (labelKey == PostViewComponentConstant.contentKey) ? !content.isShowMore : !content.translateIsShowMore
        } else if let content = cellVM?.metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            // 话题转发卡片不支持局部选中
            selectable = false
        }
        return selectable
    }

    /// 操作menu的后 恢复队列
    func resumeQueue() {
        return self.messagesViewModel.resumeQueue()
    }

    /// 开始操作menu的时候 暂停队列
    func pauseQueue() {
        return self.messagesViewModel.pauseQueue()
    }

}

extension ThreadFilterController: ThreadSelectControlHostController {

    var tableTopBlockHeight: CGFloat? { nil }

    /// 遵守协议的tableview
    var _tableView: ThreadUITableView {
        return self.tableView
    }

    func showMenuByPointerDrag(for label: LKSelectionLabel) {
        self.tableView.showMenu(from: label)
    }
}

extension ThreadChatController: ThreadCopyDataSoucre {
    /// 弹出的chat
    var _chat: Chat? {
        return self.messageViewModel._chat
    }

    /// 消息所在的idx
    func index(of messageId: String) -> IndexPath? {
        if let row = self.messageViewModel.findThreadIndexBy(id: messageId) {
            return IndexPath(row: row, section: 0)
        }
        return nil
    }

    func cellContentIsSelectableForIndexPath(_ indexPath: IndexPath, labelKey: String) -> Bool {
        guard indexPath.row < self.messageViewModel.uiDataSource.count else {
            return false
        }
        let cellVM = self.messageViewModel.uiDataSource[indexPath.row] as? LarkMessageBase.ThreadMessageCellViewModel<ThreadMessageMetaModel, ThreadCellMetaModelDependency>
        var selectable = true
        if let content = cellVM?.content as? TextPostContentViewModel {
            selectable = (labelKey == PostViewComponentConstant.contentKey) ? !content.isShowMore : !content.translateIsShowMore
        } else if let content = cellVM?.metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            // 话题转发卡片不支持局部选中
            selectable = false
        }
        return selectable
    }

    /// 操作menu的后 恢复队列
    func resumeQueue() {
        return self.messageViewModel.resumeQueue()
    }

    /// 开始操作menu的时候 暂停队列
    func pauseQueue() {
        return self.messageViewModel.pauseQueue()
    }

}

extension ThreadChatController: ThreadSelectControlHostController {

    var tableTopBlockHeight: CGFloat? {
        if self.bannerView.isHidden {
            return nil
        }
        return self.bannerView.frame.height
    }

    /// 遵守协议的tableview
    var _tableView: ThreadUITableView {
        return self.tableView
    }

    func showMenuByPointerDrag(for label: LKSelectionLabel) {
        self.tableView.showMenu(from: label)
    }
}

extension ThreadDetailController: ThreadCopyDataSoucre {
    /// 弹出的chat
    var _chat: Chat? {
        return self.viewModel._chat
    }

    /// 操作menu的后 恢复队列
    func resumeQueue() {
        return self.viewModel.resumeQueue()
    }

    /// 开始操作menu的时候 暂停队列
    func pauseQueue() {
        return self.viewModel.pauseQueue()
    }

    func lockTableHeightAndOffset() {
        lockTableOffset = true
        let tableHeight = tableView.frame.height
        self.tableView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(navBar.snp.bottom)
            make.height.equalTo(tableHeight)
        }
    }

    func unlockTableHeightAndOffset() {
        if !self.lockTableOffset {
            return
        }
        self.lockTableOffset = false
        self.remakeTableViewConstraints()
    }

    /// 消息所在的idx
    func index(of messageId: String) -> IndexPath? {
        return self.viewModel.findMessageIndexBy(id: messageId)
    }

    func cellContentIsSelectableForIndexPath(_ indexPath: IndexPath, labelKey: String) -> Bool {
        //安全校验
        guard indexPath.section < self.viewModel.uiDataSource.count,
              indexPath.row < self.viewModel.uiDataSource[indexPath.section].count else {
            return false
        }

        let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.row] as? LarkMessageBase.ThreadDetailMessageCellViewModel<ThreadDetailMetaModel, ThreadDetailCellMetaModelDependency>
        var selectable = true
        if let content = cellVM?.content as? TextPostContentViewModel {
            selectable = (labelKey == PostViewComponentConstant.contentKey) ? !content.isShowMore : !content.translateIsShowMore
        } else if let content = cellVM?.metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            // 话题转发卡片不支持局部选中
            selectable = false
        }
        return selectable
    }
}

extension ReplyInThreadViewController: ThreadSelectControlHostController {

    var tableTopBlockHeight: CGFloat? { nil }

    /// 键盘的控制
    var keyboardView: ThreadKeyboardView? {
        return self.threadKeyboard?.keyboardView
    }

    /// 遵守协议的tableview
    var _tableView: ThreadUITableView {
        return self.tableView
    }

    func showMenuByPointerDrag(for label: LKSelectionLabel) {
        self.tableView.showMenu(from: label)
    }
}

extension ReplyInThreadViewController: ThreadCopyDataSoucre {
    /// 弹出的chat
    var _chat: Chat? {
        return self.viewModel._chat
    }

    /// 操作menu的后 恢复队列
    func resumeQueue() {
        return self.viewModel.resumeQueue()
    }

    /// 开始操作menu的时候 暂停队列
    func pauseQueue() {
        return self.viewModel.pauseQueue()
    }

    func lockTableHeightAndOffset() {
        lockTableOffset = true
        let tableHeight = tableView.frame.height
        self.tableView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalTo(self.view)
            make.top.equalTo(navBar.snp.bottom)
            make.height.equalTo(tableHeight)
        }
    }

    func unlockTableHeightAndOffset() {
        if !self.lockTableOffset {
            return
        }
        self.lockTableOffset = false
        self.remakeTableViewConstraint()
    }

    /// 消息所在的idx
    func index(of messageId: String) -> IndexPath? {
        return self.viewModel.findMessageIndexBy(id: messageId)
    }

    func cellContentIsSelectableForIndexPath(_ indexPath: IndexPath, labelKey: String) -> Bool {
        //安全校验
        guard indexPath.section < self.viewModel.uiDataSource.count,
              indexPath.row < self.viewModel.uiDataSource[indexPath.section].count else {
            return false
        }

        let cellVM = self.viewModel.uiDataSource[indexPath.section][indexPath.row] as? LarkMessageBase.ThreadDetailMessageCellViewModel<ThreadDetailMetaModel, ThreadDetailCellMetaModelDependency>
        var selectable = true
        if let content = cellVM?.content as? TextPostContentViewModel {
            selectable = (labelKey == PostViewComponentConstant.contentKey) ? !content.isShowMore : !content.translateIsShowMore
        } else if let content = cellVM?.metaModel.message.content as? MergeForwardContent, content.isFromPrivateTopic {
            // 话题转发卡片不支持局部选中
            selectable = false
        }
        return selectable
    }
}

extension ThreadDetailController: ThreadSelectControlHostController {

    var tableTopBlockHeight: CGFloat? { nil }

    /// 键盘的控制
    var keyboardView: ThreadKeyboardView? {
        return self.threadKeyboard?.keyboardView
    }

    /// 遵守协议的tableview
    var _tableView: ThreadUITableView {
        return self.tableView
    }

    func showMenuByPointerDrag(for label: LKSelectionLabel) {
        self.tableView.showMenu(from: label)
    }
}

final class ThreadMessageSelectControl: NSObject, UserResolverWrapper {
    let userResolver: UserResolver

    let disposeBag = DisposeBag()

    static let logger = Logger.log(ThreadMessageSelectControl.self, category: "lark.thread.message.select.control")

    private let pasteboardToken: String
    private var selectIndex: IndexPath?
    weak var selectedLabel: LKSelectionLabel?
    weak var selectedView: LKRichContainerView?
    weak var chatVC: ThreadSelectControlHostController?
    var naVC: LkNavigationController? {
        return self.chatVC?.navigationController as? LkNavigationController
    }
    weak var popGestureRecognizer: UIGestureRecognizer?

    var needBecomFirstResponder: Bool = false

    private var tapGesture: UITapGestureRecognizer? {
        didSet {
            if let gesture = oldValue {
                gesture.view?.removeGestureRecognizer(gesture)
            }
        }
    }
    private var longPressGesture: UILongPressGestureRecognizer? {
        didSet {
            if let gesture = oldValue {
                gesture.view?.removeGestureRecognizer(gesture)
            }
        }
    }

    private var panGesture: PanRecognizerWithInitialTouch? {
        didSet {
            if let gesture = oldValue {
                gesture.view?.removeGestureRecognizer(gesture)
            }
        }
    }

    private var rightClickGesture: RightClickRecognizer? {
        didSet {
            if let gesture = oldValue {
                gesture.view?.removeGestureRecognizer(gesture)
            }
        }
    }

    weak var menuService: MessageMenuOpenService? {
        didSet {
            menuService?.delegate = self
        }
    }

    @ScopedInjectedLazy private var modelService: ModelService?
    @ScopedInjectedLazy private var chatSecurityControlService: ChatSecurityControlService?
    let fixMessageCopy: Bool

    init(chat: ThreadSelectControlHostController, pasteboardToken: String) {
        self.chatVC = chat
        self.pasteboardToken = pasteboardToken
        self.userResolver = chat.userResolver
        self.fixMessageCopy = chat.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.fix_copy")
        super.init()
    }

    func dismissMenuIfNeeded() {
        self.menuService?.dissmissMenu(completion: nil)
    }

    func addMessageSelectObserver() {
        // 开始拖动的时候 reaction bar 消失
        self.chatVC?._tableView.willBeginDragging({ [weak self] in
            guard let self = self else { return }
            // 开始拖动的时候取消自动弹回键盘，并且让menu消失
            if self.needBecomFirstResponder, self.menuService?.isSheetMenu == false {
                self.needBecomFirstResponder = false
                self.menuService?.dissmissMenu(completion: nil)
            } else {
                // 如果开始拖动，没有自动回弹键盘，则暂时隐藏menu
                self.menuService?.hideMenuIfNeeded(animated: true)
            }
        })

        self.chatVC?._tableView.didEndDecelerating({ [weak self] in
            guard let self = self else { return }
            self.updateMenuStateWhenEndScroll()
        })

        self.chatVC?._tableView.didEndDragging({ [weak self] (decelerate) in
            if decelerate { return }
            guard let self = self else { return }
            self.updateMenuStateWhenEndScroll()
        })

        // 当 cell 划出屏幕的时候取消选中态
        self.chatVC?._tableView.didEndDisplayingCell({ [weak self] (event) in
            guard let self = self else { return }
            if let triggerView = self.menuService?.currentTriggerView,
                   triggerView == event.cell {
                NSObject.cancelPreviousPerformRequests(
                    withTarget: self,
                    selector: #selector(self.dismissMenuController),
                    object: nil)
                self.perform(
                    #selector(self.dismissMenuController),
                    with: nil,
                    afterDelay: 0.2,
                    inModes: [.tracking, .common])
            }
        })
    }

    // 停止滚动时处理 menu 状态
    func updateMenuStateWhenEndScroll() {
        guard let table = self.chatVC?._tableView else { return }
        let tableShowRect = CGRect(
            x: table.contentOffset.x,
            y: table.contentOffset.y,
            width: table.frame.width,
            height: table.frame.height
        )
        if let triggerView = menuService?.currentTriggerView {
            // 判断菜单是否在页面内部
            if triggerView.frame.intersects(tableShowRect) {
                self.menuService?.unhideMenuIfNeeded(animated: true)
            } else {
                self.menuService?.dissmissMenu(completion: nil)
            }
        }
    }

    // 当进入选中态, 锁住 chat 数据队列和 table 布局
    func lockChatTable() {
        guard let chatVC = self.chatVC else { return }
        chatVC.pauseQueue()
    }

    // 当取消选中态, 打开 chat 数据队列和 table 布局
    func unlockChatTable() {
        guard let chatVC = self.chatVC else { return }
        chatVC.resumeQueue()
    }

    func lockTableHeightAndOffset() {
        self.chatVC?.lockTableHeightAndOffset()
    }
    func unlockTableHeightAndOffset() {
        self.chatVC?.unlockTableHeightAndOffset()
    }

    @objc
    private func dismissMenuController() {
        self.menuService?.dissmissMenu(completion: nil)
    }

    private func cleanSelectionModel() {
        self.tapGesture = nil
        self.longPressGesture = nil
        self.panGesture = nil
        self.rightClickGesture = nil
        self.selectedLabel?.initSelectedRange = nil
        self.selectedLabel?.inSelectionMode = false
        self.selectedLabel = nil

        self.selectedView?.richView.switchMode(.normal)
        self.selectedView = nil

        // 恢复 table 手势
        self.setTableGestureEnable(true)
    }

    private func setTableGestureEnable(_ enable: Bool) {
        self.chatVC?._tableView.interactions.forEach({ (interaction) in
            if let drag = interaction as? UIDragInteraction {
                drag.isEnabled = enable
            }
        })
    }

    //lklabel 的 range  转化为 menu 的 select type
    func getMenuSelectedRange(label: LKLabel, showAllMessage: Bool, range: NSRange) -> MenuMessageSelectedType {
        guard let visibleTextRange = label.visibleTextRange else { return .all }

        let messageLength = visibleTextRange.length + visibleTextRange.location

        if range.location == 0 && range.length >= messageLength {
            return .all
        }

        if !showAllMessage {
            if range.location + range.length >= messageLength {
                return .from(range.location)
            }
        }

        return .range(range)
    }

    // menu 的 select type 转化为 lklabel 的 range
    func getLabelSelectRange(label: LKLabel, selectedType: MenuMessageSelectedType) -> NSRange? {
        let messageLength = label.attributedText?.string.count ?? 0
        switch selectedType {
        case .all, .richView:
            break
        case .from(let index):
            return NSRange(location: index, length: messageLength - index)
        case .to(let index):
            return NSRange(location: 0, length: index)
        case .range(let range):
            return range
        }
        return nil
    }

    // 添加冲突手势 禁止原有手势
    private func addCounteractGesuture(view: UIView) {
        // 需要把手势添加到 bubble View
        guard let target = chatVC?.findThreadFloorView(by: view) else {
            return
        }
        let gesture = target.lu.addTapGestureRecognizer(
            action: #selector(handleCounteractGesuture(gesture:)),
            target: self,
            touchNumber: 1)
        gesture.delegate = self
        gesture.cancelsTouchesInView = false
        target.addGestureRecognizer(gesture)
        self.tapGesture = gesture

        let longPressGesture = target.lu.addLongPressGestureRecognizer(
            action: #selector(handleCounteractGesuture(gesture:)),
            duration: 0.1,
            target: self)
        target.addGestureRecognizer(longPressGesture)
        longPressGesture.delegate = self
        longPressGesture.cancelsTouchesInView = false
        self.longPressGesture = longPressGesture

        let panGesture = PanRecognizerWithInitialTouch(
            target: self,
            action: #selector(handleCounteractGesuture(gesture:)))
        target.addGestureRecognizer(panGesture)
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        self.panGesture = panGesture
        self.naVC?.interactivePopGestureRecognizer?.require(toFail: panGesture)

        let rightClick = RightClickRecognizer(
            target: self,
            action: #selector(handleCounteractGesuture(gesture:)))
        rightClick.delegate = self
        rightClick.cancelsTouchesInView = false
        target.addGestureRecognizer(rightClick)
        self.rightClickGesture = rightClick
    }

    @objc
    func handleCounteractGesuture(gesture: UIGestureRecognizer) {
        // do nothing
    }

    func resumePopGestureDelaysTouchesBegan() {
        self.popGestureRecognizer?.delaysTouchesBegan = true
        self.popGestureRecognizer = nil
    }

    deinit {
        self.resumePopGestureDelaysTouchesBegan()
    }
}

/// 消息菜单生命周期管理
extension ThreadMessageSelectControl: MessageMenuServiceDelegate, LongMessageMenuOffsetProtocol {
    /// 消息选中态的处理
    /// 尝试唤起RichView选择器,当前场景不可唤起选择器,则将消息加置灰蒙层(Only for new menu)
    private func resetSelectionModel(messageId: String, postViewComponentConstant: String?, menuService: MessageMenuOpenService) {
        cleanSelectionModel()
        guard let chatVC = self.chatVC else { return }
        if let (richView, selectable) = chatVC.findSelectedViewAndStatus(messageId: messageId, postViewComponentConstant: postViewComponentConstant), selectable {
            richView.richView.selectionDelegate = self
            richView.richView.switchMode(.visual)

            // 添加手势抵消原有手势
            self.addCounteractGesuture(view: richView)
            self.selectedView = richView

            // 选中 label 禁止 tableView 手势
            self.setTableGestureEnable(false)
            /// 设置选中区域
            menuService.currentSelectedRect = { [weak self] in
                return self?.getSelectedRect()
            }
            return
        // RichLabel的相关逻辑,后续所有类型的消息均不使用LKLabel时下掉
        } else if let (contentLabel, selectable) = chatVC.findSelectedLabelAndStatus(messageId: messageId, postViewComponentConstant: postViewComponentConstant), selectable {
            contentLabel.selectionDelegate = self
            contentLabel.inSelectionMode = true
            // 添加手势抵消原有手势
            self.addCounteractGesuture(view: contentLabel)
            self.selectedLabel = contentLabel
            menuService.currentSelectedRect = { [weak self] in
                if let frame = self?.selectedLabel?.frame {
                    return self?.selectedView?.superview?.convert(frame, to: nil)
                }
                return nil
            }
            // 选中 label 禁止 tableView 手势
            self.setTableGestureEnable(false)
        } else {
            menuService.currentSelectedRect = nil
            return
        }
    }

    /// 获取用户选中的范围
    private func getSelectedRect() -> CGRect? {
        // 获取所有选中范围
        guard let selectedRects = self.selectedView?.richView.selectionModule.selectedRects,
                let superview = self.selectedView?.superview,
                let window = self.selectedView?.window else { return nil }
        // 把选中范围转换为屏幕中的坐标
        let screenRects = selectedRects.map {
            superview.convert($0, to: window)
        }
        // 获取选中范围的外围矩形框，就是获取最上、左、下、右的点
        var leftX: CGFloat = CGFloat.greatestFiniteMagnitude
        var rightX: CGFloat = 0
        var topY: CGFloat = CGFloat.greatestFiniteMagnitude
        var bottomY: CGFloat = 0
        screenRects.forEach { rect in
            leftX = min(leftX, rect.origin.x)
            rightX = max(rightX, rect.origin.x + rect.size.width)
            topY = min(topY, rect.origin.y)
            bottomY = max(bottomY, rect.origin.y + rect.size.height)
        }
        return CGRect(origin: CGPoint(x: leftX, y: topY), size: CGSize(width: rightX - leftX, height: bottomY - topY))
    }

    func messageMenuWillLoad(_ menuService: MessageMenuOpenService,
                             message: Message,
                             componentConstant: String?) {

        guard let chatVC = self.chatVC else { return }

        // let conflict gesture on bubble view to action
        self.popGestureRecognizer = self.naVC?.interactivePopGestureRecognizer
        self.popGestureRecognizer?.delaysTouchesBegan = false

        // 取消 menuVC 以及 选中索引
        self.selectIndex = chatVC.index(of: message.id)

        /// 锁定会话Table, 暂停更新队列
        self.lockChatTable()
        let beginKeyboardHeight = chatVC.keyboardView?.frame.height ?? 0
        let beginTableViewOffset = chatVC._tableView.contentOffset
        // 出现菜单之前如果键盘弹起 那么菜单取消的时候应该恢复键盘
        self.needBecomFirstResponder = chatVC.keyboardView?.inputTextView.isFirstResponder ?? false

        var showKeyboard = false
        if self.needBecomFirstResponder {
            showKeyboard = true
        } else if chatVC.keyboardView?.keyboardPanel.contentHeight ?? 0 > 0 {
            showKeyboard = true
        }
        if showKeyboard {
            if menuService.isSheetMenu { self.lockTableHeightAndOffset() }
            chatVC.keyboardView?.fold()
        }

        if showKeyboard, menuService.isSheetMenu {
            let changeHeight = beginKeyboardHeight - (chatVC.keyboardView?.frame.height ?? 0)
            if changeHeight <= 0 {
                ThreadMessageSelectControl.logger.info("ThreadMessageSelectControl beginKeyboardHeight:\(beginKeyboardHeight) " +
                                                        "keyboardView?.frame.height: \(chatVC.keyboardView?.frame.height) " +
                                                        "changeHeight: \(changeHeight)")
            } else {
                let tableHeight = chatVC._tableView.frame.height + changeHeight
                /// lockTableHeightAndOffset 会保证一定可以 updateConstraints height
                chatVC._tableView.snp.updateConstraints { make in
                    make.height.equalTo(tableHeight)
                }
                chatVC._tableView.layoutIfNeeded()
                /// 这个要保证偏移不变，需要设置为原来的offset
                chatVC._tableView.setContentOffset(beginTableViewOffset, animated: false)
            }
        }

        self.resetSelectionModel(messageId: message.id, postViewComponentConstant: componentConstant, menuService: menuService)
    }

    func messageMenuDidLoad(_ menuService: MessageMenuOpenService,
                            message: Message,
                            touchTest: MenuTouchTestInterface) {

        touchTest.enableTransmitTouch = true

        // 菜单加载后需要处理让 lklabel 同层级视图响应 touch
        touchTest.handleTouchArea = { [weak self] (point, menu) in
            guard let `self` = self else { return false }
            if message.type != .text && message.type != .post {
                return false
            }

            if let contentLabel = self.selectedLabel {
                let convertPoint = menu.view.convert(point, to: contentLabel)
                return contentLabel.bounds.contains(convertPoint)
            }

            if let contentView = self.selectedView {
                let convertPoint = menu.view.convert(point, to: contentView)
                return contentView.bounds.contains(convertPoint)
            }
            return false
        }

        // 为了处理 lklabel 识别范围超出视图
        touchTest.handleTouchView = { [weak self] (point, menu) in
            guard let `self` = self else { return nil }
            if message.type != .text && message.type != .post {
                return nil
            }

            if let contentLabel = self.selectedLabel {
                let convertPoint = menu.view.convert(point, to: contentLabel)
                return contentLabel.hitTest(convertPoint, with: nil)
            }

            if let contentView = self.selectedView {
                let convertPoint = menu.view.convert(point, to: contentView)
                return contentView.hitTest(convertPoint, with: nil)
            }
            return nil
        }
    }

    func offsetTableView(_ menuService: MessageMenuOpenService, offset: MessageMenuVerticalOffset) {
        guard let table = self.chatVC?._tableView else { return }
        switch offset {
        case .normalSizeBegin(let offset):
            table.setContentOffset(CGPoint(x: table.contentOffset.x,
                                           y: table.contentOffset.y + offset),
                                   animated: false)
        case .longSizeBegin(let view):
            self.autoOffsetForLargeSizeView(view,
                                            fromVC: self.chatVC,
                                            tableView: table,
                                            tableTopBlockHeight: self.chatVC?.tableTopBlockHeight)
        case .move(let offset):
            table.setContentOffset(CGPoint(x: table.contentOffset.x,
                                           y: table.contentOffset.y + offset),
                                   animated: false)
        case .end:
            let maxOffset = ceil(table.contentSize.height - table.frame.height + table.adjustedContentInset.bottom)
            let isNormalOffset = maxOffset > 0 && table.contentOffset.y <= maxOffset
            if !isNormalOffset {
                table.scrollToBottom(animated: false, scrollPosition: .bottom)
            }
        }
    }

    func messageMenuWillDismiss(_ menuService: MessageMenuOpenService) {
        guard let chatVC = self.chatVC else { return }
        // back to default value
        self.resumePopGestureDelaysTouchesBegan()
        self.needBecomFirstResponder = false
        chatVC.menuWillHide(inputWillBecomeFirstResponder: self.needBecomFirstResponder)
        self.unlockTableHeightAndOffset()
        if !fixMessageCopy {
            self.unlockChatTable()
        }
        self.cleanSelectionModel()
    }

    func messageMenuDidDismiss(_ menuService: MessageMenuOpenService) {
        // 需要在菜单消息切action回调完成之后再unlock，否则在文本复制等场景，action回调完之前unlock可能插入一个UI刷新，
        // 导致富文本局部选中状态被清除
        if fixMessageCopy {
            self.unlockChatTable()
        }
    }
}

///LKSelectionLabel相关代理
extension ThreadMessageSelectControl: LKSelectionLabelDelegate {
    func selectionDragModeUpdate(_ inDragMode: Bool) {
        if inDragMode {
            menuService?.hideMenuIfNeeded(animated: true)
        } else {
            menuService?.unhideMenuIfNeeded(animated: true)
        }
    }

    public func selectionRangeDidUpdate(_ range: NSRange) {
    }

    public func selectionRangeDidSelected(
        _ range: NSRange,
        didSelectedAttrString: NSAttributedString,
        didSelectedRenderAttributedString: NSAttributedString) {
        var selectedType: MenuMessageSelectedType = .all
        if let menuService = menuService,
           let chatVC = self.chatVC,
           let messageId = menuService.currentMessage?.id,
           let componentKey = menuService.currentComponentKey,
           let (label, showAllMessage) = chatVC.findSelectedLabelAndStatus(messageId: messageId, postViewComponentConstant: componentKey) {
            selectedType = self.getMenuSelectedRange(label: label, showAllMessage: showAllMessage, range: range)
            menuService.updateMenuSelectInfo(selectedType)
            menuService.unhideMenuIfNeeded(animated: true)
            return
        }
    }

    func selectionLabelBeginDragInteraction(label: LKSelectionLabel) {
        self.menuService?.dissmissMenu(completion: nil)
    }

    func selectionLabelWillEnterSelectionModeByPointerDrag(label: LKSelectionLabel) {
        self.menuService?.dissmissMenu(completion: nil)
        self.chatVC?.showMenuByPointerDrag(for: label)
    }

    func selectionRangeText(_ range: NSRange, didSelectedAttrString: NSAttributedString, didSelectedRenderAttributedString: NSAttributedString) -> String? {
        guard let menuService = self.menuService,
              let message = menuService.currentMessage else { return nil }

        var selectedType: MenuMessageSelectedType = .all
        if let chatVC = self.chatVC,
            let (label, showAllMessage) = chatVC.findSelectedLabelAndStatus(
                messageId: message.id,
                postViewComponentConstant: menuService.currentComponentKey) {
            selectedType = self.getMenuSelectedRange(label: label, showAllMessage: showAllMessage, range: range)
        }
        let copyType: CopyMessageType? = menuService.currentCopyType
        let copyString = modelService?.copyMessageSummerize(
            message,
            selectType: selectedType,
            copyType: copyType ?? .message)
        return copyString
    }

    public func selectionRangeHandleCopy(selectedText: String) -> Bool {
        assertionFailure("should not trigger copy")
        guard let window = self.chatVC?.view.window else { return true }
        self.menuService?.dissmissMenu(completion: nil)
        SCPasteboard.generalPasteboard().string = selectedText
        UDToast.showSuccess(with: BundleI18n.LarkThread.Lark_Legacy_JssdkCopySuccess, on: window)
        return false
    }
}

extension ThreadMessageSelectControl: LKRichViewSelectionDelegate {
    func willDragCursor(_ view: LKRichView) {
        menuService?.hideMenuIfNeeded(animated: true)
    }

    func didDragCursor(_ view: LKRichView) {
        if let menuService = menuService,
           let messageId = menuService.currentMessage?.id,
           let componentKey = menuService.currentComponentKey,
           let (richContainerView, isShowAll) = chatVC?.findSelectedViewAndStatus(messageId: messageId,
                                                                                  postViewComponentConstant: componentKey) {
            var selectedType = MenuMessageSelectedType.all
            if isShowAll && !richContainerView.richView.isSelectAll() {
                // 每次拖动鼠标时记录状态，不能在回调闭包中计算状态，因为闭包回调时会先清除选中态，计算不准
                let messageSelectedType = MessageSelectedType.transform(
                    canSelectMoreAhead: richContainerView.richView.canSelectMoreAhead(),
                    canSelectMoreAftwards: richContainerView.richView.canSelectMoreAftwards()
                )
                selectedType = .richView({ [weak richContainerView] in
                    guard let copyString = richContainerView?.richView.getCopyString() else { return nil }
                    return (copyString, messageSelectedType)
                })
            }
            menuService.updateMenuSelectInfo(selectedType)
            menuService.unhideMenuIfNeeded(animated: true)
        }
    }

    func handleCopyByCommand(_ view: LKRichView, text: NSAttributedString?) {
        defer {
            self.menuService?.dissmissMenu(completion: nil)
        }
        var copyAttr = text
        if view.isSelectAll(), let menuService = self.menuService, let message = menuService.currentMessage {
            // 如果全选，则从数据源解析全部数据（因为折叠时富文本数据不全）
            let copyType = menuService.currentCopyType ?? .message
            copyAttr = modelService?.copyMessageSummerizeAttr(message, selectType: .all, copyType: copyType)
        }
        guard let copyAttr = copyAttr, let chat = self.chatVC?._chat,
        let message = self.menuService?.currentMessage, let chatSecurityControlService = self.chatSecurityControlService else { return }
        IMCopyPasteMenuTracker.trackCopy(chat: chat,
                                         message: message,
                                         byCommand: true,
                                         allSelect: view.isSelectAll(),
                                         text: copyAttr)
        if CopyToPasteboardManager.copyToPasteboardFormAttribute(copyAttr,
                                                                 fileAuthority: .message(message, chat, chatSecurityControlService),
                                                                 pasteboardToken: pasteboardToken,
                                                                 fgService: self.userResolver.fg) {
            guard let window = self.chatVC?.view.window else { return }
            UDToast.showSuccess(with: BundleI18n.LarkThread.Lark_Legacy_JssdkCopySuccess, on: window)
        } else {
            guard let window = self.chatVC?.view.window else { return }
            UDToast.showFailure(with: BundleI18n.LarkThread.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
        }
    }
}

/// 手势相关的 不影响逻辑
extension ThreadMessageSelectControl: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        // 只在 lklabel 区域可以开始手势
        if let contentLabel = self.selectedLabel {
            let convertPoint = gestureRecognizer.location(in: contentLabel)
            if contentLabel.hitTest(convertPoint, with: nil) == nil {
                return false
            }
        }

        if let contentView = self.selectedView {
            let convertPoint = gestureRecognizer.location(in: contentView)
            if contentView.hitTest(convertPoint, with: nil) == nil {
                return false
            }
        }

        // pan 手势判断是否拖动到光标
        if let panGesture = gestureRecognizer as? PanRecognizerWithInitialTouch,
            let targetView = panGesture.view,
            let selectedLabel = self.selectedLabel,
            let point = panGesture.initialTouchLocation {
            let convertPoint = targetView.convert(point, to: selectedLabel)
            if !selectedLabel.startCursor.hitTest(convertPoint) &&
                !selectedLabel.endCursor.hitTest(convertPoint) {
                return false
            }
        }

        if let panGesture = gestureRecognizer as? PanRecognizerWithInitialTouch,
           let targetView = panGesture.view,
           let selectedView = self.selectedView,
           let point = panGesture.initialTouchLocation,
           let startCursor = selectedView.richView.startCursor,
           let endCursor = selectedView.richView.endCursor {
            let convertPoint = targetView.convert(point, to: selectedView)
            if !startCursor.hitTest(convertPoint, with: nil) &&
                !endCursor.hitTest(convertPoint, with: nil) {
                return false
            }
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        /// 不拦截 label 上的手势
        if otherGestureRecognizer.view == self.selectedLabel {
            return true
        }
        if otherGestureRecognizer.view == self.selectedView {
            return true
        }
        return false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        /// 不拦截 label 上的手势
        if otherGestureRecognizer.view == self.selectedLabel {
            return false
        }
        if otherGestureRecognizer.view == self.selectedView {
            return false
        }
        return true
    }
}

final class PanRecognizerWithInitialTouch: UIPanGestureRecognizer {
    var initialTouchLocation: CGPoint?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        initialTouchLocation = touches.first?.location(in: view)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
    }
}

final class EmptyCursor: LKSelectionCursor {
    override func updateLayer() {
        return
    }
}
