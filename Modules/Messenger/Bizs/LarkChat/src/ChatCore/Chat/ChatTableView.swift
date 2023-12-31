//
//  ChatTableView.swift
//  LarkChat
//
//  Created by zc09v on 2018/10/14.
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
import SuiteAppConfig
import LarkInteraction
import LarkUIKit
import LarkFeatureGating
import UniverseDesignColor

protocol ChatTableViewDelegate: AnyObject {
    func messageWillDisplay(message: Message)
    func messageDidEndDisplay(message: Message)
    func tapTableHandler()
    func removeHightlight(needRefresh: Bool)
    func tableDidScroll(table: ChatTableView)
    func tableWillBeginDragging()
    func safeAreaInsetsDidChange()
    func showTopLoadMore(status: ScrollViewLoadMoreStatus)
    func showBottomLoadMore(status: ScrollViewLoadMoreStatus)
    var isOriginTheme: Bool { get }
}

protocol ChatTableViewDataSourceDelegate: AnyObject {
    func cellViewModel(by id: String) -> ChatCellViewModel?
    func loadMoreNewMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?)
    func loadMoreOldMessages(finish: ((ScrollViewLoadMoreResult) -> Void)?)
    func findMessageIndexBy(id: String) -> IndexPath?
    func highlight(position: Int32)
    func batchSelectMesssages(startPosition: Int32)
    var uiDataSource: [ChatCellViewModel] { get }
    var readService: ChatMessageReadService { get }
    var chat: Chat { get }
}

class ChatTableView: CommonTable, UITableViewDelegate,
                           UITableViewDataSource, PostViewContentCopyProtocol {
    let userResolver: UserResolver

    var multiSelecting: Bool = false
    /// 滚动中记录上次的偏移，判断当前滚动方向
    private var lastContentOffsetY: CGFloat = 0
    private(set) var longPressGesture: UILongPressGestureRecognizer!
    private let chatFromWhere: ChatFromWhere
    private let keepOffset: () -> Bool
    static let logger = Logger.log(ChatTableView.self, category: "ChatTableView")
    /// 需要高亮的位置
    var highlightPosition: Int32?
    var hightlightCell: MessageCommonCell?

    //swiftlint:disable weak_delegate
    var chatTableDataSourceDelegate: ChatTableViewDataSourceDelegate?
    //swiftlint:enable weak_delegate
    weak var chatTableDelegate: ChatTableViewDelegate?

    // 如果为true，则tableview只接收上下滑动事件
    let isOnlyReceiveScroll: Bool

    var draggingDriver: Driver<(Bool, DraggingDirection)> {
        return draggingVariable.asDriver()
    }
    var visibleCellData: [IndexPath] = []

    /// 代理UITableView事件，需添加对应回调
    struct ChatTableViewDelegateProxy {
        var willDisplayCell: [((ChatUITableViewEvent) -> Void)] = []
        var didEndDisplayingCell: [((ChatUITableViewEvent) -> Void)] = []
        var willBeginDragging: [(() -> Void)] = []
        var didEndDecelerating: [(() -> Void)] = []
        var didEndDragging: [((Bool) -> Void)] = []
    }
    var delegateProxy = ChatTableViewDelegateProxy()

    enum DraggingDirection {
        case up
        case down
        case none
    }
    private var draggingVariable: BehaviorRelay<(Bool, DraggingDirection)> = BehaviorRelay(value: (false, .none))
    let disposeBag: DisposeBag = DisposeBag()
    private var didScrollSubject: PublishSubject<Void> = PublishSubject()

    lazy var keepOffsetRefreshRefactorEnable: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "ios.chattable.offset.refactor"))
    }()

    init(userResolver: UserResolver,
         isOnlyReceiveScroll: Bool,
         keepOffset: @escaping () -> Bool,
         chatFromWhere: ChatFromWhere) {
        self.userResolver = userResolver
        self.isOnlyReceiveScroll = isOnlyReceiveScroll
        self.keepOffset = keepOffset
        self.chatFromWhere = chatFromWhere
        super.init(frame: .zero, style: .plain)
        self.accessibilityIdentifier = "chat_list_view"
        self.backgroundColor = UIColor.clear
        self.separatorStyle = .none
        self.keyboardDismissMode = .onDrag
        self.estimatedRowHeight = 0
        self.dataSource = self
        self.delegate = self
        self.contentInsetAdjustmentBehavior = .never
        self.didScrollSubject
            .throttle(.milliseconds(300), scheduler: MainScheduler.asyncInstance)
            .asObservable()
            .subscribe(onNext: { [weak self] () in
                guard let self = self else { return }
                if self.isDragging {
                    // draggingVariable.value设置不放在BeginDragging里是因为要使用draging的方向，放到BeginDragging里无法判断方向
                    if self.contentOffset.y >= self.lastContentOffsetY {
                        self.draggingVariable.accept((true, .up))
                    } else {
                        self.draggingVariable.accept((true, .down))
                    }
                }
                self.lastContentOffsetY = self.contentOffset.y
                self.chatTableDelegate?.tableDidScroll(table: self)
            })
            .disposed(by: disposeBag)

        self.longPressGesture = self.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)), duration: Display.pad ? 0.3 : 0.2, target: self)
        self.longPressGesture.allowableMovement = 5
        let rightClick = RightClickRecognizer(target: self, action: #selector(bubbleLongPressed(_:)))
        self.addGestureRecognizer(rightClick)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
        tap.cancelsTouchesInView = false
        self.addGestureRecognizer(tap)
        self.observeApplicationState()
        self.addVisibilityObserverable()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("NewChat: ChatTableView deinit")
    }

    private func addVisibilityObserverable() {
        let willDisplayCallBack: ((ChatUITableViewEvent) -> Void) = { [weak self] (event) in
            guard let self = self else { return }
            self.visibleCellData.append(event.indexPath)
        }
        let didEndDisplayingCallBack: ((ChatUITableViewEvent) -> Void) = { [weak self] (event) in
            guard let self = self else { return }
            if let index = self.visibleCellData.firstIndex(of: event.indexPath) {
                self.visibleCellData.remove(at: index)
           }
        }
        self.delegateProxy.willDisplayCell.append(willDisplayCallBack)
        self.delegateProxy.didEndDisplayingCell.append(didEndDisplayingCallBack)
    }

    @objc
    public func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            // locationInSelf
            if self.highlightPosition != nil {
                guard let blinkView = self.hightlightCell?.getView(by: MessageCommonCell.highlightViewKey) else { return }
                blinkView.backgroundColor = UIColor.clear
                self.chatTableDelegate?.removeHightlight(needRefresh: false)
            }
            let location = gesture.location(in: self)
            self.showMenu(location: location,
                          triggerByDrag: false,
                          triggerGesture: gesture)
        default:
            break
        }
    }

    func showMenu(location: CGPoint,
                  triggerByDrag: Bool,
                  triggerGesture: UIGestureRecognizer?
    ) {
        guard let indexPath = self.indexPathForRow(at: location),
            let cell = self.cellForRow(at: indexPath) as? MessageCommonCell,
            let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] as? ChatMessageCellViewModel, let chat = self.chatTableDataSourceDelegate?.chat else {
            return
        }
        // 外部联系人如果非好友支持特定的一些menu
        IMTracker.Chat.Main.Click.MsgPress(chat, cellVM.message, self.chatFromWhere)

        // 点击气泡
        if let bubble = cell.getView(by: PostViewComponentConstant.bubbleKey),
            bubble.bounds.contains(self.convert(location, to: bubble)) {
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
            let (selectConstraintKey, copyType) = getPostViewComponentConstant(cell, location: location)
            cellVM.showMenu(cell,
                            location: self.convert(location, to: cell),
                            displayView: displayViewBlock,
                            triggerGesture: triggerGesture,
                            copyType: copyType,
                            selectConstraintKey: selectConstraintKey)
        } else if let avatar = cell.getView(by: ChatCellConsts.avatarKey),
            avatar.bounds.contains(self.convert(location, to: avatar)) {
            // 长按头像
            cellVM.avatarLongPressed()
        } else if let avatar = cell.getView(by: ChatCellConsts.secretAvatarKey),
                    avatar.bounds.contains(self.convert(location, to: avatar)) {
            // 长按头像
            cellVM.avatarLongPressed()
        }
    }

    // 查找可以响应事件的view
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isOnlyReceiveScroll {
            guard isUserInteractionEnabled, !isHidden, alpha > 0.01, self.point(inside: point, with: event) else { return nil }
            // 不往下继续查找
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
        self.chatTableDataSourceDelegate?.loadMoreNewMessages(finish: finish)
    }

    override func loadMoreTopContent(finish: @escaping (ScrollViewLoadMoreResult) -> Void) {
        self.chatTableDataSourceDelegate?.loadMoreOldMessages(finish: finish)
    }

    override func reloadAndGuarantLastCellVisible(animated: Bool = false) {
        let tableStickToBottom = self.stickToBottom()
        if self.keepOffset() {
            let currentOffsetY = self.contentOffset.y
            self.reloadData()
            self.layoutIfNeeded()
            self.contentOffset = CGPoint(x: 0, y: currentOffsetY)
        } else {
            self.reloadData()
        }
        if tableStickToBottom, !self.keepOffset() {
            if animated {
                UIView.animate(withDuration: CommonTable.scrollToBottomAnimationDuration) {
                    self.scrollToBottom(animated: false)
                }
            } else {
                self.scrollToBottom(animated: false)
            }
        }
    }

    override func scrollToRow(at indexPath: IndexPath, at scrollPosition: UITableView.ScrollPosition = .top, animated: Bool = false) {
        if self.indexPathsForVisibleRows?.contains(indexPath) ?? false,
            let cell = self.cellForRow(at: indexPath) {
            self.willDisplay(cell: cell, indexPath: indexPath)
        }
        // Prevent indexPath from crossing the boundary and causing crash
        if self.chatTableDataSourceDelegate?.uiDataSource.count ?? -1 > indexPath.row {
            super.scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        } else {
            ChatTableView.logger.error("indexPath越界 \(indexPath)")
            assertionFailure("indexPath越界 \(indexPath)，请保存上下文联系赵晨排查修复\n indexPath out of bounds \(indexPath), please save the context to contact Zhao Chen troubleshooting repair")
        }
    }

    /// VoIP拉活，后台可能导致已读，再次回到前台没有触发willDisplay的机制
    private func observeApplicationState() {
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.displayVisibleCells()
            }).disposed(by: self.disposeBag)
    }

    func willDisplay(cell: UITableViewCell, indexPath: IndexPath) {
        guard self.willDisplayEnable else {
            return
        }
        guard let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] else {
            return
        }

        // 在屏幕内的才触发vm的willDisplay
        if self.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            cellVM.willDisplay()
        }

        if let messageCellVM = cellVM as? HasMessage {
            self.chatTableDataSourceDelegate?.readService.putRead(element: messageCellVM.message, urgentConfirmed: { [weak self] position in
                self?.chatTableDataSourceDelegate?.highlight(position: position)
            })
            if messageCellVM.message.position == self.highlightPosition {
                self.hightlightCell = cell as? MessageCommonCell
            }
            self.chatTableDelegate?.messageWillDisplay(message: messageCellVM.message)
        }
    }

    func remakeConstraints(height: ConstraintRelatableTarget, bottom: ConstraintRelatableTarget, bottomOffset: CGFloat = 0) {
        self.snp.remakeConstraints({ make in
            make.left.right.equalToSuperview()
            make.height.equalTo(height)
            make.bottom.equalTo(bottom).offset(bottomOffset)
        })
        self.layoutIfNeeded()
    }

    @objc
    private func tapHandler(_ gesture: UITapGestureRecognizer) {
        // for other business like locktable when lklabel tap, if lklable handle the tap, do not fold the keyboard automaticlly
        // 如果LKLabel响应了事件，不做收起键盘, 交由LKLabel的对应事件处理，因为有先锁住table再收起键盘等需求
        let location = gesture.location(in: self)
        let hitTestView = self.hitTest(location, with: UIEvent())
        if hitTestView as? LKLabel != nil {
            ChatTableView.logger.info("NewChatTabel: LKLabel handle tap")
        } else {
            chatTableDelegate?.tapTableHandler()
        }
    }

    func firstVisibleMessageCellInfo() -> (messagePosition: Int32, frame: CGRect)? {
        for indexPath in self.indexPathsForVisibleRows ?? [] {
            if let cellVM = (self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] as? HasMessage), let cell = self.cellForRow(at: indexPath) {
                return (messagePosition: cellVM.message.position, frame: cell.frame)
            }
        }
        return nil
    }

    func getVisibleCell(by messagePosition: Int32) -> UITableViewCell? {
        for indexPath in self.indexPathsForVisibleRows ?? [] {
            if let cellVM = (self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] as? HasMessage), cellVM.message.position == messagePosition {
                return self.cellForRow(at: indexPath)
            }
        }
        return nil
    }

    func lastCellVisible() -> Bool? {
        /*加载更多历史消息后(headInserting)，因为会往table头部插入数据，造成table偏移，代码上通过设置contenoffset使table保持不动，
        但实际上初始偏移还是产生了(虽然用户看不到)，会导致下面的逻辑判断不符合预期
         这种情况下返回true,false都不合适，返回nil*/
        guard !self.headInserting else {
            return nil
        }
        guard let uiDataSource = self.chatTableDataSourceDelegate?.uiDataSource else {
            return true
        }
        guard let last = uiDataSource.last else { return true }
        let distanceToBottom = self.contentSize.height - (self.contentOffset.y + self.frame.size.height)
        let lastCellHeight = last.renderer.size().height
        return distanceToBottom < lastCellHeight
    }

    // 屏幕底部外已经加载但没有上屏的cells的总高度是否超过给定高度
    // 即当前屏幕底部到table底部的距离是否超过给定的height
    func bottomUnVisibleCellsHeightIsMoreThanHeight(_ height: CGFloat) -> Bool? {
        /*加载更多历史消息后(headInserting)，因为会往table头部插入数据，造成table偏移，代码上通过设置contenoffset使table保持不动，
        但实际上初始偏移还是产生了(虽然用户看不到)，会导致下面的逻辑判断不符合预期
         这种情况下返回true,false都不合适，返回nil*/
        guard !self.headInserting else {
            return nil
        }
        let distanceToBottom = self.contentSize.height - (self.contentOffset.y + self.frame.size.height)
        return distanceToBottom > height
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
            if let indexPath = self.indexPath(for: cell),
                let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] as? ChatMessageCellViewModel {
                cellVM.didEndDisplay()
            }
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.chatTableDataSourceDelegate?.uiDataSource.count ?? 0
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < self.chatTableDataSourceDelegate?.uiDataSource.count ?? 0 else {
            assertionFailure("保留现场！！！")
            return UITableViewCell()
        }
        guard let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] else {
            return UITableViewCell()
        }
        let cellId = (cellVM as? HasMessage)?.message.id ?? cellVM.id ?? ""
        let cell = cellVM.dequeueReusableCell(tableView, cellId: cellId)
        cell.backgroundColor = self.chatTableDelegate?.isOriginTheme == true ? (UIColor.ud.bgBody & UIColor.ud.bgBase) : .clear
        return cell
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row < self.chatTableDataSourceDelegate?.uiDataSource.count ?? 0 else {
            assertionFailure("保留现场！！！")
            return
        }
        delegateProxy.willDisplayCell.forEach { $0((cell, indexPath)) }
        self.willDisplay(cell: cell, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        delegateProxy.didEndDisplayingCell.forEach { $0((cell, indexPath)) }
        // 不在屏幕内的才触发didEndDisplaying
        guard let cell = cell as? MessageCommonCell,
            let cellVM = self.chatTableDataSourceDelegate?.cellViewModel(by: cell.cellId) else {
            return
        }
        if !(self.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            cellVM.didEndDisplay()
            if let message = (cellVM as? HasMessage)?.message {
                self.chatTableDelegate?.messageDidEndDisplay(message: message)
            }
        }
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < self.chatTableDataSourceDelegate?.uiDataSource.count ?? 0 else {
            assertionFailure("保留现场！！！")
            return 0
        }
        return chatTableDataSourceDelegate?.uiDataSource[indexPath.row].renderer.size().height ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard indexPath.row < self.chatTableDataSourceDelegate?.uiDataSource.count ?? 0 else {
            assertionFailure("保留现场！！！")
            return 0
        }
        return chatTableDataSourceDelegate?.uiDataSource[indexPath.row].renderer.size().height ?? 0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row]
        cellVM?.didSelect()
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.delegateProxy.willBeginDragging.forEach { $0() }
        chatTableDelegate?.tableWillBeginDragging()
        if scrollView.isTracking {
            self.chatTableDelegate?.tapTableHandler()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegateProxy.didEndDragging.forEach { $0(decelerate) }
        if !decelerate {
            draggingVariable.accept((false, .none))
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegateProxy.didEndDecelerating.forEach { $0() }
        draggingVariable.accept((false, .none))
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        self.didScrollSubject.onNext(Void())
    }

    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        // change the tableview bottom when view layout was finished
        self.chatTableDelegate?.safeAreaInsetsDidChange()
    }

    override func refresh(indexPaths: [IndexPath], animation: UITableView.RowAnimation = .fade, guarantLastCellVisible: Bool) {
        if let uiDataSource = self.chatTableDataSourceDelegate?.uiDataSource, uiDataSource.count != self.numberOfRows(inSection: 0) {
            self.reloadData()
            Self.logger.warn("chatTrace uiDataSource count is not equal numberOfRows")
        }
        super.refresh(indexPaths: indexPaths, animation: animation, guarantLastCellVisible: guarantLastCellVisible)
    }

    override func canPreLoadMoreOffset() -> Bool {
        return self.contentOffset.y >= -self.contentInset.top
    }
}

extension ChatTableView {
    func clickBatchSelect(referenceLocation: CGPoint) {
        guard let indexPath = self.indexPathForRow(at: referenceLocation) else {
            return
        }
        /// 从该点所在 cell 依次往下遍历，找到第一个可以被选择的 cell
        for (rowIndex, cell) in (self.chatTableDataSourceDelegate?.uiDataSource ?? []).enumerated() where rowIndex >= indexPath.row {
            if let cellVM = cell as? ChatMessageCellViewModel,
               let messageCell = self.cellForRow(at: IndexPath(row: rowIndex, section: indexPath.section)) as? MessageCommonCell,
               let checkbox = messageCell.getView(by: ChatCellConsts.checkboxKey) {
                let checkboxBottom = self.convert(checkbox.frame, from: messageCell).bottom
                if checkboxBottom < referenceLocation.y {
                    ChatTableView.logger.info("start batchSelectMesssages without current msg: startPos \(cellVM.message.position) msgId \(cellVM.message)")
                    self.chatTableDataSourceDelegate?.batchSelectMesssages(startPosition: cellVM.message.position + 1)
                    return
                } else {
                    ChatTableView.logger.info("start batchSelectMesssages: startPos \(cellVM.message.position) msgId \(cellVM.message)")
                    self.chatTableDataSourceDelegate?.batchSelectMesssages(startPosition: cellVM.message.position)
                    return
                }
            }
        }
    }
}

extension ChatTableView: DragContainer {
    func dragInteractionEnable(location: CGPoint) -> Bool {
        return true
    }

    func dragInteractionIgnore(location: CGPoint) -> Bool {
        return false
    }

    func dragInteractionContext(location: CGPoint) -> DragContext? {
        guard let indexPath = self.indexPathForRow(at: location),
            let cellVM = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row] as? ChatMessageCellViewModel else {
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

extension ChatTableView: VisiblePositionRange, KeepOffsetRefresh {
    func position(by indexPath: IndexPath) -> Int32? {
        let model = self.chatTableDataSourceDelegate?.uiDataSource[indexPath.row]
        return (model as? HasMessage)?.message.position
    }

    func newOffsetY(by cell: UITableViewCell) -> CGFloat? {
        if let cell = cell as? MessageCommonCell,
            !cell.cellId.isEmpty,
            let index = self.chatTableDataSourceDelegate?.findMessageIndexBy(id: cell.cellId),
            let uiDataSource = self.chatTableDataSourceDelegate?.uiDataSource {
            var newY: CGFloat = 0
            for i in 0..<index.row {
                newY += uiDataSource[i].renderer.size().height
            }
            return newY
        }
        return nil
    }

    func newOffsetY(by cell: UITableViewCell, cellId: String) -> CGFloat? {
        if let cell = cell as? MessageCommonCell,
            cell.cellId == cellId,
            let index = self.chatTableDataSourceDelegate?.findMessageIndexBy(id: cell.cellId),
            let uiDataSource = self.chatTableDataSourceDelegate?.uiDataSource {
            var newY: CGFloat = 0
            for i in 0..<index.row {
                newY += uiDataSource[i].renderer.size().height
            }
            return newY
        }
        return nil
    }
}
