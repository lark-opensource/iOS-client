//
//  ThreadFilterController.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/8/13.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RxCocoa
import RxSwift
import SnapKit
import LarkMessageCore
import LarkMessageBase
import LarkFeatureGating
import LarkTraitCollection
import RustPB
import RichLabel
import UniverseDesignTabs
import UniverseDesignEmpty
import LarkOpenChat
import Swinject
import LarkContainer

final class ThreadFilterController: BaseUIViewController, UserResolverWrapper {
    var userResolver: UserResolver { messagesViewModel.userResolver }
    // MARK: - internal
    let messagesViewModel: ThreadFilterMessagesViewModel
    weak var delegate: ThreadContainerDelegate?
    private var messageSelectControl: ThreadMessageSelectControl?

    lazy var copyOptimizeFG: Bool = {
        return (try? userResolver.fg)?.staticFeatureGatingValue(with: .init(key: .groupMobileCopyOptimize)) ?? false
    }()

    init(messagesViewModel: ThreadFilterMessagesViewModel,
         messageActionContext: MessageActionContext,
         context: ThreadContext) {
        self.messagesViewModel = messagesViewModel
        self.context = context
        super.init(nibName: nil, bundle: nil)
        self.context.pageContainer.pageInit()
        self.registerThreadMessageActionMenu(actionContext: messageActionContext)
    }

    deinit {
        self.context.pageContainer.pageDeinit()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        messagesViewModel.hostUIConfig = HostUIConfig(
            size: delegate?.hostSize ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        // 需要在 willReceiveProps 之前将 CR 信息给到 VM，willReceiveProps 会从 VM 中取 CR 信息，对按钮进行布局
        messagesViewModel.traitCollection = navigationController?.currentWindow()?.lkTraitCollection
        messageSelectControl = ThreadMessageSelectControl(chat: self, pasteboardToken: "LARK-PSDA-messenger-threadFilter-select-copyCommand-permission")
        messageSelectControl?.menuService = self.context.pageContainer.resolve(MessageMenuOpenService.self)
        messagesViewModel.loadFirstScreen()
        setupUI()
        addObservers()
        if copyOptimizeFG {
            self.messageSelectControl?.addMessageSelectObserver()
        }
        self.context.pageContainer.pageViewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.showViewEnable = true
        messagesViewModel.viewWillAppear = true
        ThreadTracker.trackTopicAllToFollow()
        context.pageContainer.pageWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.hideHighlight()
        self.context.pageContainer.pageDidAppear()
        self.delegate?.updateShowTableView(tableView: self.tableView)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        tableView.showViewEnable = false
        messagesViewModel.viewWillAppear = false
        messagesViewModel.filterUnfollowAndRecalled()
        context.pageContainer.pageDidDisappear()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if copyOptimizeFG {
            self.messageSelectControl?.dismissMenuIfNeeded()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
    }

    private func resizeVMIfNeeded() {
        let size = view.bounds.size
        if size != messagesViewModel.hostUIConfig.size {
            let needOnResize = size.width != messagesViewModel.hostUIConfig.size.width
            messagesViewModel.hostUIConfig.size = size
            let fg = self.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.resize_if_need_by_width")
            if fg {
                // 仅宽度更新才刷新cell，因为部分机型系统下(iphone8 iOS15、不排除其他系统也存在相同问题)存在非预期回调，比如当唤起大图查看器时，系统回调了该函数，且给的高度不对
                /*1. cell渲染只依赖宽度 2. 目前正常情况下不存在只变高，不变宽的情况（转屏、ipad拖拽）
                 */
                if needOnResize {
                    messagesViewModel.onResize()
                }
            } else {
                messagesViewModel.onResize()
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - private
    private let context: ThreadContext

    private let disposeBag = DisposeBag()

    private lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: UDEmptyConfig(description: UDEmptyConfig.Description(descriptionText: BundleI18n.LarkThread.Lark_Chat_TopicFilterFollowedTip),
                                                          type: .imSubscribeTabNoTopic))
        emptyView.backgroundColor = UIColor.clear
        return emptyView
    }()

    /// 注册 Thread "我订阅的" 界面的 MessageActionMenu
    func registerThreadMessageActionMenu(actionContext: MessageActionContext) {
        actionContext.container.register(ChatMessagesOpenService.self) { [weak self] _ -> ChatMessagesOpenService in
            return self ?? DefaultChatMessagesOpenService()
        }
        ThreadMessageActionModule.onLoad(context: actionContext)
        let actionModule = ThreadMessageActionModule(context: actionContext)
        let messageMenuService = MessageMenuServiceImp(pushWrapper: messagesViewModel.chatWrapper,
                                                       actionModule: actionModule)
        context.pageContainer.register(MessageMenuOpenService.self) {
            return messageMenuService
        }
    }

    lazy var tableView: ThreadChatTableView = {
        let tableView = ThreadChatTableView(viewModel: messagesViewModel)
        tableView.chatTableDelegate = self
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.contentInset = UIEdgeInsets(
            top: 0,
            left: 0,
            bottom: Display.iPhoneXSeries ? 109.5 : 65.5,
            right: 0
        )
        return tableView
    }()

    private func setupUI() {
        self.isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBase

        self.addTableView()
    }

    private func updateEmptyViewStatus() {
        guard self.messagesViewModel.initDataStatus.value != .error else {
            return
        }

        if messagesViewModel.messageDatasource.cellViewModels.isEmpty {
            showEmptyView(true)
        } else {
            showEmptyView(false)
        }
    }

    private func showEmptyView(_ isShow: Bool) {
        if isShow {
            if self.emptyView.superview == nil {
                self.tableView.addSubview(self.emptyView)
                self.emptyView.snp.remakeConstraints({ (make) in
                    make.centerY.equalTo(self.tableView).offset(-self.tableView.contentInset.bottom)
                    make.centerX.equalTo(self.tableView)
                    make.leading.greaterThanOrEqualToSuperview().offset(30)
                    make.trailing.lessThanOrEqualToSuperview().offset(-30)
                })
            }
            self.emptyView.isHidden = false
        } else {
            if self.emptyView.superview != nil {
                self.emptyView.isHidden = true
                self.emptyView.removeFromSuperview()
            }
        }
    }

    private func addTableView() {
        view.addSubview(tableView)
        // 44 filterSegment height
        tableView.contentSize = CGSize(width: messagesViewModel.hostUIConfig.size.width, height: messagesViewModel.hostUIConfig.size.height - messagesViewModel.navBarHeight - 44)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func addObservers() {
        // 控制空态图
        messagesViewModel.initDataStatusDriver
            .drive(onNext: { [weak self] (status) in
                guard let `self` = self else { return }
                switch status {
                case .start, .error:
                    self.showEmptyView(false)
                case .finish:
                    self.showEmptyView(false)
                case .none:
                    self.showEmptyView(true)
                }
            }).disposed(by: self.disposeBag)

        messagesViewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .refreshTable:
                    self?.tableView.reloadData()
                    self?.updateEmptyViewStatus()
                case .initMessages(let hasLoading):
                    self?.updateLoadingView(hasLoading: hasLoading)
                    self?.tableView.reloadData()
                    self?.initTableViewPostion()
                case .refreshMessages(hasLoading: let hasLoading):
                    self?.updateLoadingView(hasLoading: hasLoading)
                    self?.tableView.reloadData()
                    self?.updateEmptyViewStatus()
                case .messagesUpdate(indexs: let indexs):
                    let indexPaths = indexs.map({ IndexPath(row: $0, section: 0) })
                    self?.tableView.refresh(indexPaths: indexPaths, guarantLastCellVisible: false)
                case .loadMoreOldMessages(hasLoading: let hasLoading):
                    self?.appendOldMessages(hasLoading: hasLoading)
                case .updateOldMessageLoadingView(hasLoading: let hasLoading):
                    self?.updateLoadOldMessageLoadingView(hasLoading: hasLoading)
                }
            }).disposed(by: self.disposeBag)

        /// 翻译设置变了，需要刷新界面
        messagesViewModel.userGeneralSettings.translateLanguageSettingDriver.skip(1).drive(onNext: { [weak self] (_) in
            /// 清空一次标记
            let chatId = self?.messagesViewModel.chatWrapper.chat.value.id ?? ""
            self?.messagesViewModel.translateService.resetMessageCheckStatus(key: chatId)
            self?.tableView.displayVisibleCells()
        }).disposed(by: self.disposeBag)

        /// 自动翻译开关变了，需要刷新界面
        messagesViewModel.chatAutoTranslateSettingDriver.drive(onNext: { [weak self] () in
            /// 清空一次标记
            let chatId = self?.messagesViewModel.chatWrapper.chat.value.id ?? ""
            self?.messagesViewModel.translateService.resetMessageCheckStatus(key: chatId)
            self?.tableView.displayVisibleCells()
        }).disposed(by: self.disposeBag)

        messagesViewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadData()
                self?.updateEmptyViewStatus()
            }).disposed(by: self.disposeBag)

        /// 添加 VM 的 traitCollection 和 window.traitCollection 的订阅关系
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] change in
                self?.messagesViewModel.traitCollection = change.new
            }).disposed(by: disposeBag)

        /// 获取置顶的信号
        self.delegate?.topNoticeManager().topNoticeDriver
            .drive(onNext: { [weak self] topNotice in
                guard let self = self else { return }
                self.messagesViewModel.topNoticeSubject.onNext(topNotice)
            }).disposed(by: self.disposeBag)
    }

    // MARK: supprt reverse FG
    private func initTableViewPostion() {
        self.tableView.scrollToBottom(animated: false)
    }

    private func appendOldMessages(hasLoading: Bool) {
        self.tableView.headInsertCells(hasHeader: hasLoading)
    }

    private func updateLoadOldMessageLoadingView(hasLoading: Bool) {
        self.tableView.hasHeader = hasLoading
    }

    private func updateLoadingView(hasLoading: Bool) {
        self.tableView.hasHeader = hasLoading
    }
}

// MARK: - ThreadChatTableViewDelegate
extension ThreadFilterController: ThreadChatTableViewDelegate {

    var hasDisplaySheetMenu: Bool {
        guard let menuService = self.context.pageContainer.resolve(MessageMenuOpenService.self) else {
            return false
        }
        return menuService.hasDisplayMenu && menuService.isSheetMenu
    }

    func threadWillDisplay(thread: RustPB.Basic_V1_Thread) {
    }

    func menuCustomInserts() -> UIEdgeInsets {
        if self.tableView.contentOffset.y < 0 {
            return UIEdgeInsets(top: -self.tableView.contentOffset.y, left: 0, bottom: 0, right: 0)
        }
        return .zero
    }

    func showTopLoadMore(status: ScrollViewLoadMoreStatus) {
    }

    func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {
    }

    func chatModel() -> Chat {
        return self.messagesViewModel.chatWrapper.chat.value
    }
}

// MARK: - ThreadFilterController 对 OpenIM 架构暴露的关于Messages的能力
extension ThreadFilterController: ChatMessagesOpenService {
    func getUIMessages() -> [LarkModel.Message] {
        return self.messagesViewModel.uiDataSource.compactMap {
            return ($0 as? HasMessage)?.message
        }
    }
    var pageAPI: PageAPI? {
        return self
    }
    var dataSource: DataSourceAPI? {
        return self.context.dataSourceAPI
    }
}

// MARK: - PageAPI
extension ThreadFilterController: PageAPI {
    func viewWillEndDisplay() {
        messagesViewModel.uiOutput(enable: false, indentify: "maskByCell")
        self.tableView.endDisplayVisibleCells()
    }

    func viewDidDisplay() {
        messagesViewModel.uiOutput(enable: true, indentify: "maskByCell")
        self.tableView.displayVisibleCells()
    }

    var pageSupportReply: Bool {
        return true
    }

    func insertAt(by chatter: Chatter?) {

    }

    func reply(message: Message, partialReplyInfo: PartialReplyInfo?) {
    }

    func reedit(_ message: Message) {
        assert(false, "Thread 目前不需要撤回重新编辑，如果做新的Feature，实现当前方法即可")
    }

    func multiEdit(_ message: Message) {
    }

    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return self.messageSelectControl
    }
}

extension ThreadFilterController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }

    func listVC() -> UIViewController? {
        return self
    }
}
