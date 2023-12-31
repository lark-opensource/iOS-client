//
//  ForwardChatPreviewViewController.swift
//  LarkChat
//
//  Created by ByteDance on 2022/9/8.
//

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
import UniverseDesignLoading
import UniverseDesignEmpty
import LarkMessengerInterface
import EENavigator
import LKCommonsLogging
import ServerPB
import UIKit
import LarkContainer

final class ForwardChatPreviewViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource {
    private let contentTitle: String
    private let titleView: UIView?
    private let userResolver: UserResolver
    private let viewModel: ForwardChatPreviewViewModel
    private let disposeBag = DisposeBag()
    private var itemsGenerator: RightBarButtonItemsGenerator?
    private(set) var longPressGesture: UILongPressGestureRecognizer!
    private let loadingView = UDLoading.presetSpin(loadingText: BundleI18n.LarkChat.Lark_Legacy_BaseUiLoading, textDistribution: .horizonal)
    private lazy var errorView: LoadFailPlaceholderView = {
        let view = LoadFailPlaceholderView()
        view.text = BundleI18n.LarkChat.Lark_Legacy_LoadingFailed
        return view
    }()
    // 背景图
    lazy var backgroundImage: ChatBackgroundImageView = {
        let isOriginMode = self.chat.value.theme?.backgroundEntity.mode == .originMode
        let view = ChatBackgroundImageView(isOriginMode: isOriginMode)
        return view
    }()
    private lazy var chatThemeScene: ChatThemeScene = self.chat.value.theme?.componentScene ?? .defaultScene
    private lazy var emptyView: UIView = {
        let view = UIView()
        let textLabel = UILabel()
        view.addSubview(textLabel)
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        textLabel.text = BundleI18n.LarkChat.Lark_ForwardPreviewNoMessages_Empty
        textLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return view
    }()
    private var chat: BehaviorRelay<Chat> {
        return self.viewModel.chatWrapper.chat
    }

    private lazy var tableView: MergeForwardMessageDetailTableView = {
        let tableView = MergeForwardMessageDetailTableView()
        tableView.backgroundColor = UIColor.clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.delegate = self
        tableView.dataSource = self
        tableView.uiDataSourceDelegate = self
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

    public init(contentTitle: String,
                viewModel: ForwardChatPreviewViewModel,
                itemsGenerator: RightBarButtonItemsGenerator? = nil,
                titleView: UIView? = nil,
                userResolver: UserResolver) {
        self.contentTitle = contentTitle
        self.viewModel = viewModel
        self.itemsGenerator = itemsGenerator
        self.titleView = titleView
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
        self.viewModel.context.pageContainer.pageInit()
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
        self.view.backgroundColor = self.chat.value.isCustomTheme ? .clear : (UIColor.ud.bgBody & UIColor.ud.bgBase)
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        if userResolver.fg.staticFeatureGatingValue(with: "core.forward.preview_potential_crash_fix") {
            guard let titleView else {
                assertionFailure("titleView can't be nil")
                return
            }
            self.navigationItem.titleView = titleView
            if chat.value.type == .p2P {
                titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(gotoProfile)))
            }
        } else {
            if let titleView = titleView {
                self.navigationItem.titleView = titleView
                titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(gotoProfile)))
            } else {
                self.title = self.contentTitle
            }
        }
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.setupStatusView()
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        self.driveViewModel()
        if let itemsGenerator = itemsGenerator as? ForwardChatPreviewBarItemsGenerator {
            itemsGenerator.groupMemberItem.button.addTarget(self, action: #selector(groupMemberButtonClick), for: .touchUpInside)
            self.navigationItem.rightBarButtonItems = itemsGenerator.rightBarButtonItems()
        }
        self.viewModel.context.pageContainer.pageViewDidLoad()
        if !viewModel.isUserInteractionEnabled {
            longPressGesture.isEnabled = false
        }
        self.view.addSubview(backgroundImage)
        backgroundImage.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.view.sendSubviewToBack(backgroundImage)
        backgroundImage.setImage(theme: self.chat.value.theme) { [weak self] mode in
            self?.view.backgroundColor = mode == .originMode ? UIColor.ud.bgBody & UIColor.ud.bgBase : .clear
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded(self.view.bounds.size)
    }

    private func setupStatusView() {
        //展示加载图
        self.view.addSubview(loadingView)
        self.view.addSubview(errorView)
        self.view.addSubview(emptyView)
        loadingView.snp.makeConstraints { $0.center.equalToSuperview() }
        errorView.snp.makeConstraints { $0.edges.equalToSuperview() }
        emptyView.snp.makeConstraints { $0.edges.equalToSuperview() }
        loadingView.isHidden = false
        errorView.isHidden = true
        emptyView.isHidden = true
    }

    @objc
    private func gotoProfile() {
        let body = PersonCardBody(chatterId: viewModel.chatWrapper.chat.value.chatterId, fromWhere: .none)
        viewModel.context.navigator.push(body: body, from: self)
    }
    @objc
    private func groupMemberButtonClick() {
        //目标预览群成员列表不展示多选/添加/搜索框，使用简化Cell（不展示签名状态等信息）
        let body = GroupChatterDetailBody(chatId: viewModel.chatWrapper.chat.value.id,
                                          isShowMulti: false,
                                          isAccessToAddMember: false,
                                          isAbleToSearch: false,
                                          useLeanCell: true)
        viewModel.context.navigator.push(body: body, from: self)
    }

    private func resizeVMIfNeeded(_ size: CGSize) {
        if size != viewModel.hostUIConfig.size {
            viewModel.hostUIConfig.size = size
            viewModel.onResize()
        }
    }

    /// 刷新，滚动到指定消息
    private func refreshForMessages(scrollTo: ScrollInfo?) {
        self.tableView.reloadData()
        // 是否需要滚动到指定消息
        if let scrollTo = scrollTo {
            self.tableView.scrollToRow(at: IndexPath(row: scrollTo.index, section: 0), at: scrollTo.tableScrollPosition ?? .bottom, animated: false)
        }
    }

    private func driveViewModel() {
        self.viewModel.tableRefreshDriver.drive(onNext: { [weak self] refreshType in
            switch refreshType {
            case .initMessages(let info):
                self?.refreshForMessages(scrollTo: info.scrollInfo)
            default:
                self?.tableView.reloadData()
                break
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

        self.viewModel.status.map { $0 != nil }.bind(to: self.loadingView.rx.isHidden).disposed(by: disposeBag)
        self.viewModel.status.map { $0 != .empty }.bind(to: self.emptyView.rx.isHidden).disposed(by: disposeBag)
        self.viewModel.status.map { $0 != .error }.bind(to: self.errorView.rx.isHidden).disposed(by: disposeBag)
        let messageBurnView = getMessageBurnView(title: BundleI18n.LarkChat.Lark_IM_SelfDestructOn_Title, desc: BundleI18n.LarkChat.Lark_IM_SelfDestructOn_Desc)
        let containBurnMessageView = getMessageBurnView(title: BundleI18n.LarkChat.Lark_IM_ContainsSelfDestruct_Desc, desc: BundleI18n.LarkChat.Lark_IM_SelfDestructOn_Desc)
        self.viewModel.status.map { $0 != .messageBurnMode }.bind(to: messageBurnView.rx.isHidden).disposed(by: disposeBag)
        self.viewModel.status.map { $0 != .containBurnMessage }.bind(to: containBurnMessageView.rx.isHidden).disposed(by: disposeBag)
        self.screenProtectService?.observeEnterBackground(targetVC: self)
        self.viewModel.fetchInputMessage()
    }

    private func getMessageBurnView(title: String, desc: String) -> UDEmpty {
        let config = UDEmptyConfig(
            titleText: title,
            description: .init(descriptionText: desc,
                               font: UIFont.systemFont(ofSize: 14)),
            type: .noAccess)
        let messageBurnView = UDEmpty(config: config)
        self.view.addSubview(messageBurnView)
        messageBurnView.snp.makeConstraints { $0.center.equalToSuperview() }
        messageBurnView.isHidden = true
        return messageBurnView
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

extension ForwardChatPreviewViewController: PageAPI {
    func getChatThemeScene() -> ChatThemeScene {
        self.chatThemeScene
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

extension ForwardChatPreviewViewController: MergeForwardPageAPI {
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

extension ForwardChatPreviewViewController: MergeForwardMessageDetailTableViewDataSourceDelegate {
    var uiDataSource: [MergeForwardCellViewModel] {
        return self.viewModel.uiDataSource
    }
}

extension ForwardChatPreviewViewController: PlaceholderChatNavigationBarDelegate {
    func backButtonClicked() {
        self.dismiss(animated: true)
    }
}
