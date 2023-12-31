//
//  MergeForwardMessageDetailViewControlller.swift
//  Lark
//
//  Created by zc09v on 2018/5/18.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RxSwift
import LarkMessageBase
import RxCocoa
import LarkMessageCore
import LarkInteraction
import LarkFeatureGating
import LarkSplitViewController
import RichLabel
import UniverseDesignColor
import LarkMessengerInterface
import EENavigator
import LarkOpenChat
import Swinject
import LarkContainer
import class AppContainer.BootLoader

protocol RightBarButtonItemsGenerator {
    func rightBarButtonItems() -> [UIBarButtonItem]
}

final class MergeForwardMessageDetailViewControlller: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UserResolverWrapper {
    var userResolver: UserResolver { viewModel.dependency.userResolver }
    private let contentTitle: String
    private let viewModel: MergeForwardMessageDetailContentViewModel
    private let disposeBag = DisposeBag()
    private var itemsGenerator: RightBarButtonItemsGenerator?
    private(set) var longPressGesture: UILongPressGestureRecognizer!
    private var chat: BehaviorRelay<Chat> {
        return self.viewModel.chatWrapper.chat
    }
    // 背景图
    lazy var backgroundImage: ChatBackgroundImageView = {
        let isOriginMode = self.chat.value.theme?.backgroundEntity.mode == .originMode
        let view = ChatBackgroundImageView(isOriginMode: isOriginMode)
        return view
    }()
    private lazy var tableView: MergeForwardMessageDetailTableView = {
        let tableView = MergeForwardMessageDetailTableView()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 9, right: 0)
        longPressGesture = tableView.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)), duration: 0.2, target: self)
        let rightClick = RightClickRecognizer(target: self, action: #selector(bubbleLongPressed(_:)))
        tableView.addGestureRecognizer(rightClick)
        return tableView
    }()

    private lazy var screenProtectService: ChatScreenProtectService? = {
        return self.viewModel.context.pageContainer.resolve(ChatScreenProtectService.self)
    }()

    private lazy var placeholderChatView: PlaceholderChatView = {
        let placeholderChatView = PlaceholderChatView(isDark: false,
                                                      title: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Text,
                                                      subTitle: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Desc)
        placeholderChatView.setNavigationBarDelegate(self)
        return placeholderChatView
    }()

    private let chatInfo: MergeForwardChatInfo?
    private lazy var titleView: MergeForwardMessageDetailTitleView = MergeForwardMessageDetailTitleView(navigator: navigator)

    public init(
        contentTitle: String,
        viewModel: MergeForwardMessageDetailContentViewModel,
        itemsGenerator: RightBarButtonItemsGenerator? = nil,
        chatInfo: MergeForwardChatInfo? = nil,
        messageActionModule: BaseMessageActionModule<MessageActionContext>.Type = MergeForwardMessageActionModule.self
    ) {
        self.contentTitle = contentTitle
        self.chatInfo = chatInfo
        self.viewModel = viewModel
        self.itemsGenerator = itemsGenerator
        super.init(nibName: nil, bundle: nil)
        self.tableView.uiDataSourceDelegate = viewModel
        self.viewModel.context.pageContainer.pageInit()
        self.initMenu(messageActionModule: messageActionModule)
    }

    private func initMenu(messageActionModule: BaseMessageActionModule<MessageActionContext>.Type) {
        // 构造菜单
        let messageActionContext = MessageActionContext(parent: Container(parent: BootLoader.container),
                                                        store: Store(),
                                                        interceptor: IMMessageActionInterceptor(),
                                                        userStorage: userResolver.storage, compatibleMode: userResolver.compatibleMode)
        messageActionModule.onLoad(context: messageActionContext)
        let actionModule = messageActionModule.init(context: messageActionContext)
        let messageMenuService = MessageMenuServiceImp(pushWrapper: viewModel.chatWrapper,
                                                       actionModule: actionModule)
        messageActionContext.container.register(ChatMessagesOpenService.self) { [weak self] _ -> ChatMessagesOpenService in
            return self ?? DefaultChatMessagesOpenService()
        }
        messageMenuService.delegate = self
        viewModel.context.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.viewModel.context.pageContainer.pageDeinit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.context.pageContainer.pageWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.viewModel.context.pageContainer.pageDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.viewModel.context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.viewModel.context.pageContainer.pageDidDisappear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let viewColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        self.view.backgroundColor = viewColor
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        titleView.targetVC = self
        titleView.update(title: contentTitle, chatInfo: chatInfo)
        self.navigationItem.titleView = titleView
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        if viewModel.isShowBgImageView {
            self.view.addSubview(backgroundImage)
            backgroundImage.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.view.sendSubviewToBack(backgroundImage)
            backgroundImage.setImage(theme: self.chat.value.theme) { [weak self] mode in
                self?.view.backgroundColor = mode == .originMode ? viewColor : .clear
            }
        }
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )

        self.driveViewModel()
        self.viewModel.setupData()
        self.viewModel.getURLPreviews()
        if let itemsGenerator = itemsGenerator {
            self.navigationItem.rightBarButtonItems = itemsGenerator.rightBarButtonItems()
        }
        self.viewModel.context.pageContainer.pageViewDidLoad()
        if !viewModel.isUserInteractionEnabled {
            longPressGesture.isEnabled = false
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
    }

    private func resizeVMIfNeeded() {
        let size = view.bounds.size
        if size != viewModel.hostUIConfig.size {
            let needOnResize = size.width != viewModel.hostUIConfig.size.width
            viewModel.hostUIConfig.size = size
            let fg = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.resize_if_need_by_width")
            if fg {
                // 仅宽度更新才刷新cell，因为部分机型系统下(iphone8 iOS15、不排除其他系统也存在相同问题)存在非预期回调，比如当唤起大图查看器时，系统回调了该函数，且给的高度不对
                /*1. cell渲染只依赖宽度 2. 目前正常情况下不存在只变高，不变宽的情况（转屏、ipad拖拽）
                 */
                if needOnResize {
                    viewModel.onResize()
                }
            } else {
                viewModel.onResize()
            }
        }
    }

    private func driveViewModel() {
        self.viewModel.tableRefreshDriver.drive(onNext: { [weak self] refreshType in
            switch refreshType {
            case .refreshTable:
                self?.tableView.reloadData()
            case .initMessages(let info):
                self?.tableView.hasHeader = info.hasHeader
                self?.tableView.hasFooter = info.hasFooter
                self?.tableView.reloadData()
            case .loadMoreOldMessages(let hasHeader):
                self?.tableView.headInsertCells(hasHeader: hasHeader)
            case .loadMoreNewMessages(let hasFooter):
                self?.tableView.appendCells(hasFooter: hasFooter)
            }
        }).disposed(by: self.disposeBag)

        self.viewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
            }).disposed(by: self.disposeBag)

        self.screenProtectService?.observe(screenCaptured: { [weak self] captured in
            if captured {
                self?.setupPlaceholderView()
            } else {
                self?.removePlaceholderView()
            }
        })
        self.screenProtectService?.observeEnterBackground(targetVC: self)
    }

    /// 添加占位的界面
    private func setupPlaceholderView() {
        self.isNavigationBarHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        /// 显示占位图
        self.view.addSubview(placeholderChatView)
        placeholderChatView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 移除占位的界面
    private func removePlaceholderView() {
        self.isNavigationBarHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        /// 移除占位图
        self.placeholderChatView.removeFromSuperview()
    }

    @objc
    public func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            /// locationInSelf
            let location = gesture.location(in: self.tableView)
            guard let indexPath = self.tableView.indexPathForRow(at: location),
                let cell = self.tableView.cellForRow(at: indexPath) as? MessageCommonCell,
                let cellVM = self.viewModel.uiDataSource[indexPath.row] as? MergeForwardMessageCellViewModel else {
                    return
            }
            // 点击气泡
            if let bubble = cell.getView(by: PostViewComponentConstant.bubbleKey),
                bubble.bounds.contains(self.tableView.convert(location, to: bubble)) {
                var (selectConstraintKey, copyType) = tableView.getPostViewComponentConstant(cell, location: location)
                cellVM.showMenu(cell,
                                location: self.tableView.convert(location, to: cell),
                                displayView: { _ in return cell },
                                triggerGesture: gesture,
                                copyType: copyType,
                                selectConstraintKey: selectConstraintKey)

            }
        default:
            break
        }
    }

    private func triggerVisibleCellsDisplay() {
        for cell in self.tableView.visibleCells {
            if let indexPath = self.tableView.indexPath(for: cell) {
                self.willDisplay(cell: cell, indexPath: indexPath)
            }
        }
    }

    private func willDisplay(cell: UITableViewCell, indexPath: IndexPath) {
        let cellVM = viewModel.uiDataSource[indexPath.row]
        // 在屏幕内的才触发vm的willDisplay
        if tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false {
            cellVM.willDisplay()
        }
    }

    // MARK: - UITableViewDelegate, UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.uiDataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellVM = self.viewModel.uiDataSource[indexPath.row]
        let cellId = (cellVM as? HasMessage)?.message.id ?? ""
        return cellVM.dequeueReusableCell(tableView, cellId: cellId)
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.willDisplay(cell: cell, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // 不在屏幕内的才触发didEndDisplaying
        guard let cell = cell as? MessageCommonCell,
            let cellVM = self.viewModel.cellViewModel(by: cell.cellId) else {
                return
        }
        if !(tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false) {
            cellVM.didEndDisplay()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let menuService = self.viewModel.context.pageContainer.resolve(MessageMenuOpenService.self) else { return }
        menuService.hideMenuIfNeeded(animated: true)
    }

    private var needDecelerate: Bool = false
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            needDecelerate = true
            return
        }
        needDecelerate = false
        updateMenuStateWhenEndScroll()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if needDecelerate {
            updateMenuStateWhenEndScroll()
        }
    }

    // 停止滚动时处理 menu 状态
    private func updateMenuStateWhenEndScroll() {
        guard let menuService = self.viewModel.context.pageContainer.resolve(MessageMenuOpenService.self) else { return }
        let tableShowRect = CGRect(
            x: tableView.contentOffset.x,
            y: tableView.contentOffset.y,
            width: tableView.frame.width,
            height: tableView.frame.height
        )
        if let triggerView = menuService.currentTriggerView {
            // 判断菜单是否在页面内部
            if triggerView.frame.intersects(tableShowRect) {
                menuService.unhideMenuIfNeeded(animated: true)
            } else {
                menuService.dissmissMenu(completion: nil)
            }
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let cellVM = self.viewModel.uiDataSource[indexPath.row]
        cellVM.didSelect()
    }

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.uiDataSource[indexPath.row].renderer.size().height
    }
}

extension MergeForwardMessageDetailViewControlller: PageAPI {
    func getChatThemeScene() -> ChatThemeScene {
        if self.viewModel.isShowBgImageView {
            return self.chat.value.theme?.componentScene ?? .defaultScene
        }
        return .defaultScene
    }

    func viewWillEndDisplay() {
        viewModel.uiOutput(enable: false, indentify: "maskByCell")
        self.tableView.endDisplayVisibleCells()
    }

    func viewDidDisplay() {
        viewModel.uiOutput(enable: true, indentify: "maskByCell")
        self.tableView.displayVisibleCells()
    }

    var pageSupportReply: Bool {
        return false
    }

    func insertAt(by chatter: Chatter?) {
    }

    func reply(message: Message, partialReplyInfo: PartialReplyInfo?) {
    }

    func reedit(_ message: Message) {
    }

    func multiEdit(_ message: Message) {
    }

    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return nil
    }
}

extension MergeForwardMessageDetailViewControlller: MergeForwardPageAPI {
    func reloadRows(current: String, others: [String]) {
        guard let currentIndex = self.viewModel.findMessageIndexBy(id: current) else {
            return
        }
        let otherIndexes = others.compactMap { (messageId) -> IndexPath? in
            return self.viewModel.findMessageIndexBy(id: messageId)
        }
        let current = currentIndex
        self.tableView.antiShakeReload(
            current: currentIndex,
            others: otherIndexes
        )
        self.tableView.scrollRectToVisibleBottom(indexPath: current, animated: true)
    }
}

extension MergeForwardMessageDetailViewControlller: PlaceholderChatNavigationBarDelegate {
    func backButtonClicked() {
        navigator.pop(from: self)
    }
}

extension MergeForwardMessageDetailViewControlller: MessageMenuServiceDelegate, LongMessageMenuOffsetProtocol {

    func messageMenuDidLoad(_ menuService: MessageMenuOpenService,
                            message: Message,
                            touchTest: MenuTouchTestInterface) {
        touchTest.enableTransmitTouch = true
    }

    func offsetTableView(_ menuService: MessageMenuOpenService, offset: MessageMenuVerticalOffset) {
        switch offset {
        case .normalSizeBegin(let offset):
            tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x,
                                               y: tableView.contentOffset.y + offset),
                                       animated: false)
        case .longSizeBegin(let view):
            self.autoOffsetForLargeSizeView(view, fromVC: self, tableView: self.tableView, tableTopBlockHeight: nil)
        case .move(let offset):
            tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x,
                                           y: tableView.contentOffset.y + offset),
                                   animated: false)
        case .end:
            let maxOffset = tableView.contentSize.height - tableView.frame.height + tableView.adjustedContentInset.bottom
            if maxOffset > 0 {
                if tableView.contentOffset.y > ceil(maxOffset) {
                    tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: maxOffset),
                                               animated: false)
                }
            } else {
                tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: 0),
                                           animated: false)
            }
        }
    }
}

extension MergeForwardMessageDetailViewControlller: ChatMessagesOpenService {
    var pageAPI: PageAPI? {
        return self
    }
    var dataSource: DataSourceAPI? {
        return self.viewModel.context.dataSourceAPI
    }
}
