//
//  ThreadDetailPreviewController.swift
//  LarkThread
//
//  Created by ByteDance on 2023/1/3.
//

import UIKit
import Foundation
import Lottie
import SnapKit
import RxSwift
import RxCocoa
import LarkCore
import LarkModel
import LarkUIKit
import EENavigator
import LarkMessageCore
import LKCommonsLogging
import LarkMessageBase
import LarkSDKInterface
import LarkMessengerInterface
import LarkKeyCommandKit
import LarkAlertController
import LarkSplitViewController
import LarkAI
import LarkSceneManager
import LarkRichTextCore
import RustPB
import LarkSuspendable
import LarkContainer
import RichLabel
import UniverseDesignToast

final class ThreadDetailPreviewController: ThreadDetailBaseViewController {
    private lazy var navBarHeight: CGFloat = {
        return 48
    }()

    private static let logger = Logger.log(ThreadDetailPreviewController.self, category: "LarkThread.ThreadDetail")

    static let pageName = "\(ThreadDetailPreviewController.self)"

    enum LoadType {
        case unread
        case position(Int32)
        case root
        case justReply

        public var rawValue: Int {
            switch self {
            case .unread: return 0
            case .position: return 1
            case .root: return 2
            case .justReply: return 3
            }
        }
    }
    var sourceID: String = UUID().uuidString
    private var noReplyOnboarding: ThreadDetailOnboarding?
    private let disposeBag = DisposeBag()
    lazy var tableView: ThreadDetailTableView = {
        let tableView = ThreadDetailTableView(viewModel: self.viewModel, tableDelegate: self)
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude))
        return tableView
    }()

    /// 水印waterMarkView
    var waterMarkView: UIView?

    private var viewDidAppeaded: Bool = false

    lazy var fullScreenIcon: SecondaryOnlyButton = SecondaryOnlyButton(vc: self)

    lazy var sceneButtonItem: SceneButtonItem = SceneButtonItem(
        clickCallBack: { [weak self] (sender) in
            self?.clickSceneButton(sender: sender)
        },
        sceneKey: "ThreadPreview", sceneId: self.viewModel.threadObserver.value.id ?? ""
    )
    let viewModel: ThreadDetailPreviewViewModel
    let currentChatterId: String
    let chatAPI: ChatAPI
    private let loadType: LoadType
    private let context: ThreadDetailContext
    private let dependency: ThreadDetailControllerDependency
    private let getContainerController: () -> UIViewController?
    @ScopedInjectedLazy private var chatDurationStatusTrackService: ChatDurationStatusTrackService?

    init(
        loadType: LoadType,
        viewModel: ThreadDetailPreviewViewModel,
        context: ThreadDetailContext,
        currentChatterId: String,
        chatAPI: ChatAPI,
        dependency: ThreadDetailControllerDependency,
        getContainerController: @escaping () -> UIViewController?
    ) {
        self.getContainerController = getContainerController
        self.viewModel = viewModel
        self.context = context
        self.currentChatterId = currentChatterId
        self.loadType = loadType
        self.chatAPI = chatAPI
        self.dependency = dependency
        super.init(userResolver: viewModel.userResolver)
        self.context.pageContainer.pageInit()
        self.updateSceneTargetContentIdentifier()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.context.pageContainer.pageDeinit()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resizeVMIfNeeded(size)
    }

    override func splitVCSplitModeChange(split: SplitViewController) {
        super.splitVCSplitModeChange(split: split)

        resizeVMIfNeeded(self.view.bounds.size)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !viewDidAppeaded {
            resizeVMIfNeeded(navigationController?.view.bounds.size ?? view.bounds.size)
        }
        context.pageContainer.pageWillAppear()
        updateLeftNavigationItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: true)
        if !viewDidAppeaded {
            viewDidAppeaded = true
            self.observeToUpdateSceneTitle()
        }
        context.pageContainer.pageDidAppear()
        updateLeftNavigationItems()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        chatDurationStatusTrackService?.markIfViewControllerIsAppear(value: false)
        context.pageContainer.pageDidDisappear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.supportSecondaryPanGesture = true
        self.keyCommandToFullScreen = true
        self.fullScreenSceneBlock = { "channel_detail" }
        self.setupView()
        // 视图初始化后立即赋值，如果在监听之后用到，会因为立即来了数据push，导致crash
        self.viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        self.observerViewModel()
        self.obserScroll()
        self.viewModel.initMessages(loadType: self.loadType)
        self.context.pageContainer.pageViewDidLoad()
        chatDurationStatusTrackService?.setGetChatBlock { [weak self] in
            return self?.viewModel._chat
        }
    }

    override func subProviders() -> [KeyCommandProvider] {
        return [self.tableView]
    }

    private func resizeVMIfNeeded(_ size: CGSize) {
        if size != viewModel.hostUIConfig.size {
            viewModel.hostUIConfig.size = size
            viewModel.onResize()
        }
    }

    private func setupView() {
        self.view.backgroundColor = UIColor.ud.bgBase
        self.setupNavBar()
        self.loadingPlaceholderView.snp.remakeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        self.addTable()
    }

    /// 配置导航栏
    private func setupNavBar() {
        isNavigationBarHidden = true
        addCloseItemForNavBar()
        let titleView = ThreadDetailPreviewTitleView()
        navBar.titleView = titleView
        // 设置chatName,subjectText
        titleView.setObserveData(chatObservable: self.viewModel.chatObserver)
        view.addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(self.navBarHeight)
        }
    }

    private func addTable() {
        self.view.addSubview(tableView)

        tableView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        if !viewModel.isUserInteractionEnabled { tableView.longPressGesture.isEnabled = false }
    }

    private func obserScroll() {
        let refresh = self.viewModel.tableRefreshDriver.map { _ in return }
        let offset = self.tableView.rx.contentOffset.asDriver().map { _ in return }

        Driver<()>.merge([refresh, offset])
            .throttle(.milliseconds(300))
            .skip(1)
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }
                if let view = (self.tableView.visibleCells.first as? MessageCommonCell)?
                    .getView(by: PostViewComponentConstant.titleKey),
                    view.convert(view.bounds, to: self.view).maxY > 0 {
                    self.threadTitleView.isShowSubTitle = false
                } else {
                    self.threadTitleView.isShowSubTitle = true
                }
            })
            .disposed(by: disposeBag)

        offset
            .filter { [weak self] (_) -> Bool in
                guard let `self` = self else { return false }
                return (self.viewModel.uiDataSource.first?.isEmpty ?? true) && self.tableView.contentOffset.y < -8
            }
            .drive(onNext: { [weak self] (_) in
                self?.viewModel.showRootMessage()
            })
            .disposed(by: disposeBag)
    }

    /// 刷新 scene title
    private func observeToUpdateSceneTitle() {
        guard SceneManager.shared.supportsMultipleScenes else {
            return
        }
        self.viewModel.chatObserver
            .observeOn(MainScheduler.asyncInstance)
            .distinctUntilChanged({ $0.displayName == $1.displayName })
            .subscribe(onNext: { [weak self] (chat) in
                guard let vc = self else { return }
                SceneManager.shared.updateSceneIfNeeded(
                    title: chat.displayName,
                    from: vc
                )
            }).disposed(by: self.disposeBag)
    }

    override func clickSceneButton(sender: UIButton) {
        if #available(iOS 13.0, *) {
            var userInfo: [String: String] = [:]
            userInfo["chatID"] = "\(self.viewModel._chat.id)"
            let scene = LarkSceneManager.Scene(
                key: "ThreadPreview",
                id: self.viewModel.threadObserver.value.id,
                title: self.viewModel.chatObserver.value.displayName,
                userInfo: userInfo,
                sceneSourceID: self.currentSceneID(),
                windowType: "channel",
                createWay: "window_click"
            )
            SceneManager.shared.active(scene: scene, from: self) { [weak self] (_, error) in
                if let self = self, error != nil {
                    UDToast.showTips(
                        with: BundleI18n.LarkThread.Lark_Core_SplitScreenNotSupported,
                        on: self.view
                    )
                }
            }
        } else {
            assertionFailure()
        }
    }

    // MARK: 全屏按钮
    override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        self.updateLeftNavigationItems()
    }

    private func addBackItemForNavBar() {
        navBar.addBackButton { [weak self] in
            self?.backItemTapped()
        }
    }

    private func addCloseItemForNavBar() {
        navBar.addSmallCloseButton { [weak self] in
            self?.closeBtnTapped()
        }
    }
}

extension ThreadDetailPreviewController {
    func observerViewModel() {
        self.viewModel.tableRefreshDriver
            .drive(onNext: { [weak self] (refreshType) in
                switch refreshType {
                case .showRootMessage:
                    self?.tableView.reloadData()
                case .initMessages(let info):
                    self?.updateNoReplyOnboardingView()
                    self?.refreshForInitMessages(hasHeader: info.hasHeader,
                                                 hasFooter: info.hasFooter,
                                                 scrollType: info.scrollType)
                case .refreshTable:
                    self?.updateNoReplyOnboardingView()
                    self?.tableView.reloadAndGuarantLastCellVisible()
                case .refreshMissedMessage:
                    self?.tableView.keepOffsetRefresh(nil)
                case .showRoot(let rootHeight):
                    self?.tableView.showRoot(rootHeight: rootHeight)
                }
            }).disposed(by: self.disposeBag)

        self.viewModel.enableUIOutputDriver.filter({ return $0 })
            .drive(onNext: { [weak self] _ in
                self?.updateNoReplyOnboardingView()
                self?.tableView.reloadAndGuarantLastCellVisible(animated: true)
            }).disposed(by: self.disposeBag)

        self.viewModel
            .getWaterMarkImage()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (image) in
                guard let `self` = self,
                let waterMarkImage = image else { return }
                self.waterMarkView?.removeFromSuperview()
                self.waterMarkView = waterMarkImage
                self.view.addSubview(waterMarkImage)
                waterMarkImage.contentMode = .top
                waterMarkImage.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                func bringToFront(_ view: UIView) {
                    if view.superview == self.view {
                        self.view.bringSubviewToFront(view)
                    }
                }
                bringToFront(waterMarkImage)
            }).disposed(by: self.disposeBag)
    }

    private func updateNoReplyOnboardingView() {
        if self.viewModel.showReplyOnboarding() {
            if noReplyOnboarding == nil {
                let noReplyOnboarding = ThreadDetailOnboarding(threadObserver: viewModel.threadObserver)
                let size = noReplyOnboarding.systemLayoutSizeFitting(
                    CGSize(
                        width: self.view.bounds.width,
                        height: CGFloat.greatestFiniteMagnitude
                    )
                )
                noReplyOnboarding.frame = CGRect(origin: .zero, size: size)
                self.tableView.tableFooterView = noReplyOnboarding

                self.noReplyOnboarding = noReplyOnboarding
            }
        } else {
            tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: CGFloat.leastNonzeroMagnitude, height: CGFloat.leastNonzeroMagnitude))
            noReplyOnboarding = nil
        }
    }

    func refreshForInitMessages(hasHeader: Bool, hasFooter: Bool, scrollType: ThreadDetailPreviewViewModel.ScrollType) {
        self.tableView.hasHeader = hasHeader
        self.tableView.hasFooter = hasFooter
        self.tableView.reloadData()
        switch scrollType {
        case .toLastCell(let position):
            self.tableView.scrollToBottom(animated: false, scrollPosition: position)
        case .toReply(index: let index, section: let section, tableScrollPosition: let position, _):
            self.tableView.scrollToRow(at: IndexPath(row: index, section: section), at: position, animated: false)
        case .toTableBottom:
            self.tableView.scrollsToMaxOffsetY()
        case .toReplySection, .toRoot:
            break
        }
    }
}

// MARK: - ChatPageAPI 多选
extension ThreadDetailPreviewController: ChatPageAPI {
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

extension ThreadDetailPreviewController: DetailTableDelegate {

    func tapHandler() {
    }

    func showTopLoadMore(status: ScrollViewLoadMoreStatus) {
    }

    func showBottomLoadMore(status: ScrollViewLoadMoreStatus) {
    }

    func showMenuForCellVM(cellVM: ThreadDetailCellVMGeneralAbility) {
    }

    func willDisplay(cell: UITableViewCell, cellVM: ThreadDetailCellViewModel) {
        if let messageCellVM = cellVM as? HasMessage {
            if messageCellVM.message.threadPosition == self.viewModel.highlightPosition {
                (cell as? MessageCommonCell)?.highlightView()
                self.viewModel.highlightPosition = nil
            }
        }
    }
}

extension ThreadDetailPreviewController: PageAPI {
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

extension ThreadDetailPreviewController: EnterpriseEntityWordDelegate {

    func lockForShowEnterpriseEntityWordCard() {
        ThreadDetailPreviewController.logger.info("ThreadDetailPreviewController: pauseQueue for enterprise entity word card show")
        viewModel.pauseQueue()
    }

    func unlockForHideEnterpriseEntityWordCard() {
        ThreadDetailPreviewController.logger.info("ThreadDetailPreviewController: resumeQueue for after enterprise entity word card hide")
        viewModel.resumeQueue()
    }

}

extension ThreadDetailPreviewController {
    private func updateSceneTargetContentIdentifier() {
        let sceneInfo = LarkSceneManager.Scene(
            key: "ThreadPreview",
            id: self.viewModel.threadObserver.value.id
        )
        self.sceneTargetContentIdentifier = sceneInfo.targetContentIdentifier
    }

    private func updateLeftNavigationItems() {
        guard Display.pad else {
            return
        }
        let controller = self.getContainerController() ?? self
        self.navBar.leftItems = []
        let sceneInfo = LarkSceneManager.Scene(
            key: "ThreadPreview",
            id: self.viewModel.threadObserver.value.id
        )
        /// 在 iPad 分屏场景中
        if let split = self.larkSplitViewController {
            if let navigation = controller.navigationController,
               navigation.realViewControllers.first != controller {
                self.addBackItemForNavBar()
            }
            self.navBar.leftViews.append(fullScreenIcon)
            fullScreenIcon.updateIcon()
        } else {
        /// 在 iPad 非左右分屏场景
            if let navigation = self.navigationController {
                if navigation.realViewControllers.first == controller {
                    self.addCloseItemForNavBar()
                } else {
                    self.addBackItemForNavBar()
                }
            }
        }
        if SceneManager.shared.supportsMultipleScenes {
            if #available(iOS 13.0, *) {
                if self.currentScene()?.sceneInfo != sceneInfo {
                    self.navBar.leftViews.append(self.sceneButtonItem)
                }
            }
        }
    }
}
