//
//  ThreadGroupPreviewController.swift
//  LarkThread
//
//  Created by ByteDance on 2022/9/8.
//

import Foundation
import RxSwift
import RxCocoa
import SnapKit
import LarkCore
import Swinject
import LarkModel
import LarkBadge
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkContainer
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkMenuController
import LarkAlertController
import LarkTraitCollection
import LarkSDKInterface
import LarkFeatureGating
import AppReciableSDK
import LarkTab
import LarkSceneManager
import RustPB
import RichLabel
import UniverseDesignTabs
import UniverseDesignShadow
import UniverseDesignLoading
import UniverseDesignColor
import LarkMessengerInterface
import UIKit
import LarkOpenChat
import UniverseDesignDialog

final class ThreadGroupPreviewController: BaseUIViewController {
    static let pageName = "\(ThreadGroupPreviewController.self)"
    static let logger = Logger.log(ThreadGroupPreviewController.self, category: "Module.IM.Message")
    // UDTab里会临时构建一个VC，iPad下找层级关系可能会找错，这里需要外面传入containerVC
    weak var containerVC: UIViewController?
    private let disposeBag = DisposeBag()
    private var onboardingView: ThreadNewOnboardingView?
    fileprivate var topLoadMoreReciableKey: DisposedKey?
    fileprivate var bottomLoadMoreReciableKey: DisposedKey?

    lazy var tableView: ThreadChatTableView = {
        let tableView = ThreadChatTableView(viewModel: self.messageViewModel, isOnlyReceiveScroll: true)
        tableView.chatTableDelegate = self
        tableView.backgroundColor = UIColor.clear
        return tableView
    }()

    private lazy var loadingView = UDLoading.presetSpin(loadingText: BundleI18n.LarkThread.Lark_Legacy_BaseUiLoading, textDistribution: .horizonal)
    private lazy var emptyView: UIView = {
        let view = UIView()
        let textLabel = UILabel()
        view.addSubview(textLabel)
        textLabel.textColor = UIColor.ud.textPlaceholder
        textLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        textLabel.text = BundleI18n.LarkThread.Lark_ForwardPreviewNoMessages_Empty
        textLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.isHidden = true
        return view
    }()
    let chatViewModel: ThreadChatViewModel
    let messageViewModel: ThreadPreviewMessagesViewModel
    private let router: ThreadChatRouter
    private var viewDidDisappear = false
    private let context: ThreadContext
    // 防泄密
    private lazy var screenProtectService: ChatScreenProtectService? = {
        return self.context.pageContainer.resolve(ChatScreenProtectService.self)
    }()
    private lazy var placeholderChatView: PlaceholderChatView = {
        let placeholderChatView = PlaceholderChatView(isDark: false,
                                                      title: BundleI18n.LarkThread.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Text,
                                                      subTitle: BundleI18n.LarkThread.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Desc)
        placeholderChatView.setNavigationBarDelegate(self)
        return placeholderChatView
    }()

    // MARK: Life Cycle
    init(
        chatViewModel: ThreadChatViewModel,
        messageViewModel: ThreadPreviewMessagesViewModel,
        context: ThreadContext,
        router: ThreadChatRouter,
        specifiedPosition: Int32? = nil
    ) {
        self.chatViewModel = chatViewModel
        self.messageViewModel = messageViewModel
        self.context = context
        self.router = router
        super.init(nibName: nil, bundle: nil)
        self.context.pageContainer.pageInit()
        self.messageViewModel.gcunit?.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.context.pageContainer.pageDeinit()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewDidDisappear = false
        tableView.showViewEnable = true
        context.pageContainer.pageWillAppear()
        ThreadGroupPreviewController.logger.info("ThreadChat life: viewWillAppear \(viewDidDisappear) \(tableView.showViewEnable)")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.hideHighlight()
        context.pageContainer.pageDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDidDisappear = true
        tableView.showViewEnable = false
        context.pageContainer.pageDidDisappear()
        ThreadGroupPreviewController.logger.info("ThreadChat life: viewDidDisappear \(viewDidDisappear) \(tableView.showViewEnable)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.messageViewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        // 需要在 willReceiveProps 之前将 CR 信息给到 VM，willReceiveProps 会从 VM 中取 CR 信息，对按钮进行布局
        self.messageViewModel.traitCollection = navigationController?.currentWindow()?.lkTraitCollection
        self.setupView()
        self.setNeedsStatusBarAppearanceUpdate()
        self.observerMessageViewModel()
        self.messageViewModel.initMessages()
        self.observeTraitCollection()
        self.context.pageContainer.pageViewDidLoad()
        observceScreenShot()
    }

    // MARK: private methods
    private func observceScreenShot() {
        //监听截屏事件，打log
        NotificationCenter.default.rx.notification(UIApplication.userDidTakeScreenshotNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self, self.viewIfLoaded?.window != nil else { return }
                let viewModels = self.messageViewModel.uiDataSource
                let visibleViewModels = (self.tableView.indexPathsForVisibleRows ?? [])
                    .map { viewModels[$0.row] }
                let messages: [[String: String]] = visibleViewModels
                    .compactMap { (vm: ThreadCellViewModel) -> Message? in (vm as? ThreadMessageCellViewModel)?.getThreadMessage().message }
                    .map { (message: Message) -> [String: String]  in
                        let message_length = self.chatViewModel.dependency.modelService?.messageSummerize(message).count ?? -1
                        return ["id": "\(message.id)",
                            "time": "\(message.updateTime)",
                            "type": "\(message.type)",
                            "position": "\(message.position)",
                            "read_count": "\(message.readCount)",
                            "message_length": "\(message_length)"]
                    }
                let jsonEncoder = JSONEncoder()
                jsonEncoder.outputFormatting = .sortedKeys
                let data = (try? jsonEncoder.encode(messages)) ?? Data()
                let jsonStr = String(data: data, encoding: .utf8) ?? ""
                Self.logger.info("user screenshot accompanying infos:" + "channel_id: \(self.chatViewModel.chat.id), messages: \(jsonStr)")
            })
            .disposed(by: disposeBag)
    }

    private func setupView() {
        self.view.backgroundColor = UIColor.ud.bgBody & UIColor.ud.bgBase
        self.isNavigationBarHidden = true
        self.addTableView()
    }

    private func addTableView() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
        self.showLoadingView()
    }

    /// 展示加载图
    private func showLoadingView() {
        self.loadingView.isHidden = false
        self.view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.center.equalTo(self.view)
        }
    }

    /// 隐藏加载图
    private func hideLoadingView() {
        self.loadingView.isHidden = true
        self.loadingView.removeFromSuperview()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
        guard view.superview != nil else {
            return
        }
        if self.placeholderChatView.superview != nil {
            self.view.bringSubviewToFront(placeholderChatView)
        }
    }

    private func resizeVMIfNeeded() {
        let size = view.bounds.size
        if size != messageViewModel.hostUIConfig.size {
            let needOnResize = size.width != messageViewModel.hostUIConfig.size.width
            messageViewModel.hostUIConfig.size = size
            let fg = self.messageViewModel.userResolver.fg.dynamicFeatureGatingValue(with: "im.message.resize_if_need_by_width")
            if fg {
                // 仅宽度更新才刷新cell，因为部分机型系统下(iphone8 iOS15、不排除其他系统也存在相同问题)存在非预期回调，比如当唤起大图查看器时，系统回调了该函数，且给的高度不对
                /*1. cell渲染只依赖宽度 2. 目前正常情况下不存在只变高，不变宽的情况（转屏、ipad拖拽）
                 */
                if needOnResize {
                    messageViewModel.onResize()
                }
            } else {
                messageViewModel.onResize()
            }
        }
    }
}

// MARK: - observers
private extension ThreadGroupPreviewController {
    private func showEmptyView() {
        self.view.addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.center.equalTo(self.view)
        }
        self.emptyView.isHidden = false
    }

    func observerMessageViewModel() {
        self.messageViewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                ThreadGroupPreviewController.logger.info("tableRefreshDriver refreshType \(refreshType)")
                switch refreshType {
                case .initMessages(let info, _):
                    // 用户在拉取首屏期间没有发送消息，一定会走到此分支
                    self?.hideLoadingView()
                    self?.refreshForInitMessages(initInfo: info)
                case .noMessage:
                    self?.hideLoadingView()
                    self?.showEmptyView()
                case .refreshTable: // iPad分屏时触发
                    self?.tableView.reloadAndGuarantLastCellVisible()
                default:
                    break
                }
            }).disposed(by: self.disposeBag)

        self.messageViewModel.errorDriver.drive(onNext: { [weak self] (errorType) in
            guard let `self` = self else {
                return
            }
            switch errorType {
            case .jumpFail(let error):
                ThreadGroupPreviewController.logger.error("LarkThread error: jumpFail", error: error)
            case .loadMoreOldMsgFail(let error):
                ThreadGroupPreviewController.logger.error("LarkThread error: loadMoreOldMsgFail", error: error)
                self.tableView.endTopLoadMore(hasMore: true)
            case .loadMoreNewMsgFail(let error):
                ThreadGroupPreviewController.logger.error("LarkThread error: loadMoreNewMsgFail", error: error)
                self.tableView.endBottomLoadMore(hasMore: true)
            }
        }).disposed(by: self.disposeBag)

        self.messageViewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.tableView.reloadAndGuarantLastCellVisible(animated: true)
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
        self.navigationController?.isNavigationBarHidden = true
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        /// 显示占位图
        self.view.addSubview(placeholderChatView)
        placeholderChatView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    /// 移除占位的界面
    private func removePlaceholderView() {
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        /// 移除占位图
        self.placeholderChatView.removeFromSuperview()
    }

    /// 添加 VM 的 traitCollection 和 window.traitCollection 的订阅关系
    private func observeTraitCollection() {
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] change in
                self?.messageViewModel.traitCollection = change.new
            }).disposed(by: disposeBag)
    }

    private func refreshForInitMessages(initInfo: InitMessagesInfo) {
        self.refreshForMessages(hasHeader: initInfo.hasHeader, hasFooter: initInfo.hasFooter, scrollTo: initInfo.scrollInfo)
        switch initInfo.initType {
        case .recentLeftMessage:
            let cell = self.tableView.getVisibleCell(by: self.messageViewModel.chatWrapper.chat.value.lastReadPosition)
            if let cell = cell {
                let frame = self.view.convert(cell.frame, from: self.tableView)
                let contentOffsetY = min(self.tableView.tableViewOffsetMaxY(), self.tableView.contentOffset.y + (frame.minY - CGFloat(self.messageViewModel.chatWrapper.chat.value.lastReadOffset)))
                if contentOffsetY > 0 {
                    self.tableView.contentOffset.y = contentOffsetY
                }
            }
            break
        default:
            ThreadGroupPreviewController.logger.info("self.messageViewModel.publicInitType = \(initInfo.initType)")
            break
        }
    }

    //刷新，滚动到指定消息
    func refreshForMessages(hasHeader: Bool, hasFooter: Bool, scrollTo: ScrollInfo?) {
        self.tableView.hasHeader = hasHeader
        self.tableView.hasFooter = hasFooter
        self.tableView.reloadData()
        if let scrollTo = scrollTo {
            ThreadGroupPreviewController.logger.info("will scrollToRow index \(scrollTo.index) contentSize \(self.tableView.contentSize)")
            self.tableView.willDisplayEnable = false
            self.tableView.layoutIfNeeded()
            self.tableView.willDisplayEnable = true
            self.tableView.scrollToRow(at: IndexPath(row: scrollTo.index, section: 0), at: scrollTo.tableScrollPosition, animated: false)
            self.tableView.displayVisibleCells()
            ThreadGroupPreviewController.logger.info("did scrollToRow index \(scrollTo.index) contentSize \(self.tableView.contentSize)")
        }
    }
}

// MARK: - ThreadChatTableViewDelegate
extension ThreadGroupPreviewController: ThreadChatTableViewDelegate {
    var hasDisplaySheetMenu: Bool {
        return false
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
        return self.chatViewModel.chat
    }
}

// MARK: - PageAPI
extension ThreadGroupPreviewController: PageAPI {
    func viewWillEndDisplay() {
        messageViewModel.uiOutput(enable: false, indentify: "maskByCell")
        self.tableView.endDisplayVisibleCells()
    }

    func viewDidDisplay() {
        messageViewModel.uiOutput(enable: true, indentify: "maskByCell")
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
        assert(false, "thread needn't reeidt,if needed, override this func")
    }

    func multiEdit(_ message: Message) {

    }

    func getSelectionLabelDelegate() -> LKSelectionLabelDelegate? {
        return nil
    }
}

extension ThreadGroupPreviewController: GCUnitDelegate {
    func gc(limitWeight: Int64, callback: GCUnitDelegateCallback) {
        guard let range = tableView.visiblePositionRange() else { return }
        self.view.isUserInteractionEnabled = true
        let postion: Int32 = range.bottom
        ThreadGroupPreviewController.logger.info("chatTrace in GC \(self.chatViewModel.chat.id) \(postion)")
    }
}

extension ThreadGroupPreviewController: UDTabsListContainerViewDelegate {
    func listView() -> UIView {
        return self.view
    }

    func listVC() -> UIViewController? {
        return self
    }
}

extension ThreadGroupPreviewController: PlaceholderChatNavigationBarDelegate {
    func backButtonClicked() {
        self.dismiss(animated: true)
    }
}

extension ThreadGroupPreviewController: ChatPageAPI {
    func reloadRows(current: String, others: [String]) {
    }

    var inSelectMode: Observable<Bool> {
        return BehaviorRelay<Bool>(value: false).asObservable()
    }

    var selectedMessages: BehaviorRelay<[ChatSelectedMessageContext]> {
        return BehaviorRelay<[ChatSelectedMessageContext]>(value: [])
    }

    func startMultiSelect(by messageId: String) {
    }

    func endMultiSelect() {
    }

    func toggleSelectedMessage(by messageId: String) {
    }
    func originMergeForwardId() -> String? {
        return nil
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}
