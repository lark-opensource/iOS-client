//
//  ThreadGroupPreviewContainerController.swift
//  LarkThread
//
//  Created by ByteDance on 2022/9/8.
//

import Foundation
import RxCocoa
import RxSwift
import SnapKit
import LarkCore
import LarkUIKit
import LarkBadge
import LarkModel
import EENavigator
import LarkMessageCore
import LarkMessageBase
import LKCommonsLogging
import LarkMessengerInterface
import LarkOpenFeed
import LarkFeatureGating
import LarkSplitViewController
import LarkTraitCollection
import LarkSDKInterface
import UniverseDesignToast
import LarkSuspendable
import UniverseDesignTabs
import LarkOpenChat
import LarkContainer
import LarkBizAvatar
import UIKit

protocol RightBarButtonItemsGenerator {
    func rightBarButtonItems() -> [UIBarButtonItem]
}

// MARK: - ThreadGroupPreviewContainerController
typealias GetThreadGroupPreviewControllerBlock = (ThreadPreviewContentConfig) throws -> ThreadGroupPreviewController

final class ThreadGroupPreviewContainerController: BaseUIViewController {
    private lazy var navBarHeight: CGFloat = {
        // modal态不关注statusBarHeight
        return 67
    }()
    private lazy var listContainerOffset: CGFloat = {
        // 为了展示圆角效果，向上推23px
        return 23
    }()

    init(viewModel: ThreadContainerViewModel,
         intermediateStateControl: InitialDataAndViewControl<(Chat, TopicGroup), Void>,
         getNaviBar: @escaping GetNavigationBar,
         getThreadsController: @escaping GetThreadGroupPreviewControllerBlock,
         itemsGenerator: RightBarButtonItemsGenerator? = nil) {
        self.intermediateStateControl = intermediateStateControl
        self.viewModel = viewModel
        self.getNavigationBar = getNaviBar
        self.getThreadsController = getThreadsController
        self.itemsGenerator = itemsGenerator
        super.init(nibName: nil, bundle: nil)
        if viewModel.useIntermediateEnable {
            self.startInitialDataAndViewControl()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var sourceID: String = UUID().uuidString

    private var itemsGenerator: RightBarButtonItemsGenerator?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.naviBar?.viewWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.naviBar?.viewDidAppear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.isNavigationBarHidden = true
        self.view.backgroundColor = UIColor.ud.bgBase
        // 如果已经有了chat和topicGroup数据，直接开始构造界面
        if !viewModel.useIntermediateEnable,
            let chatPushWrapper = self.viewModel.chatWrapper,
            let topicGroupPushWrapper = self.viewModel.topicGroupPushWrapper {
            self.setupView(with: chatPushWrapper, topicGroupPushWrapper: topicGroupPushWrapper)
        } else {
            self.intermediateStateControl.viewDidLoad()
        }
    }
    // MARK: private
    private static let logger = Logger.log(ThreadGroupPreviewContainerController.self, category: "Thread.GroupPreviewContainer")
    private static let cornerHeight = 8.0
    private let disposeBag = DisposeBag()
    private let viewModel: ThreadContainerViewModel
    private var naviBar: ChatNavigationBar?
    private let getNavigationBar: GetNavigationBar
    private let getThreadsController: GetThreadGroupPreviewControllerBlock
    private var loadingView: GroupIntermediateSkeletionView?
    private let intermediateStateControl: InitialDataAndViewControl<(Chat, TopicGroup), Void>
    private var threadAnounmentView: ThreadChatHeader?
    private lazy var cornerView: UIView = {
        let cornerView = UIView()
        cornerView.backgroundColor = UIColor.ud.bgFloat
        return cornerView
    }()
    /// 水印waterMarkView
    var waterMarkView: UIView?
    /// key: type；value: 全部、已订阅、我参与的控制器
    private var tabControllers = [TabItemType: UDTabsListContainerViewDelegate]()
    private var tabModels: [TabItemBaseModel] = []
    private var tabsView: ThreadTabsView?
    private lazy var listContainerView: UDTabsListContainerView = {
        return UDTabsListContainerView(dataSource: self)
    }()
    private func startInitialDataAndViewControl() {
        self.intermediateStateControl.start { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let status):
                ThreadGroupPreviewContainerController.logger.info("ProcessStatus is \(status)")
                switch status {
                // 获取到了Chat和TopicGroup
                case .blockDataFetched(data: let data):
                    self.viewModel.ready(chat: data.0, topicGroup: data.1)
                // 开始构造界面
                case .inNormalStatus:
                    guard let chatPushWrapper = self.viewModel.chatWrapper,
                          let topicGroupPushWrapper = self.viewModel.topicGroupPushWrapper else {
                        ThreadGroupPreviewContainerController.logger.error("block data is empty error")
                        return
                    }
                    self.setupView(with: chatPushWrapper, topicGroupPushWrapper: topicGroupPushWrapper)
                    self.hideLoadingView()
                // 显示中间态界面
                case .inInstantStatus:
                    self.showLoadingView()
                }
            case .failure(let error):
                ThreadGroupPreviewContainerController.logger.error("fetchTopicGroup error", error: error)
            }
        }
    }

    private func addObservers() {
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

    private func fetchChatData() {
        /// 进入话题群的时候 拉取更新一下群公告的内容,确保下次进入展示最新的群公告
        self.viewModel.chatAPI?.fetchChat(by: self.viewModel.chatID, forceRemote: true).subscribe(onNext: { (_) in
        }).disposed(by: disposeBag)
    }

    private func showLoadingView() {
        let loadingView = GroupIntermediateSkeletionView(backButtonClickedBlock: { [weak self] in
            guard let `self` = self else {
                assertionFailure("lack From VC")
                return
            }
            self.viewModel.navigator.pop(from: self)
        })
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingView.startLoading()
        self.loadingView = loadingView
    }

    private func hideLoadingView() {
        loadingView?.stopLoading()
        loadingView?.removeFromSuperview()
    }

    private func configData() {
        // 默认选中第一个标签
        self.tabsView?.selectItemAt(index: 0, selectedType: .code)
    }

    // MARK: 状态栏
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
}

// MARK: - setupView
extension ThreadGroupPreviewContainerController {
    private func setupView(with chatPushWrapper: ChatPushWrapper, topicGroupPushWrapper: TopicGroupPushWrapper) {
        let chat = chatPushWrapper.chat.value
        let topicGroup = topicGroupPushWrapper.topicGroupObservable.value
        guard let navigationBar = try? self.getNavigationBar(chat, false) else { return }
        if #available(iOS 13.0, *), Display.phone {
            navigationBar.overrideUserInterfaceStyle = .light
        }
        navigationBar.loadSubModuleData()
        self.naviBar = navigationBar
        self.naviBar?.viewWillRealRenderSubView()
        view.addSubview(navigationBar)
        self.setupNaviBar()
        setupThreadTabs(with: chatPushWrapper, navigationBar: navigationBar)
        self.setupAllTabController(with: chat, topicGroup: topicGroup)
        view.bringSubviewToFront(navigationBar)
        self.configData()
        addObservers()
        fetchChatData()
    }

    private func setupNaviBar() {
        naviBar?.backgroundColor = UIColor.clear
        naviBar?.delegate = self
        naviBar?.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }
    }

    private func setupThreadTabs(with chatPushWrapper: ChatPushWrapper, navigationBar: ChatNavigationBar) {
        guard let chatAPI = self.viewModel.chatAPI else { return }
        // 构建全部，我订阅的tab
        self.tabModels = []
        let allTabItem = AllTabItemModel(itemType: .all,
                                         cellType: AllTabItemCell.self,
                                         title: BundleI18n.LarkThread.Lark_Chat_TopicFilterAll,
                                         chatObserverable: chatPushWrapper.chat)
        self.tabModels.append(allTabItem)
        let tabsView = ThreadTabsView(tabModels: self.tabModels)
        tabsView.isHidden = true
        tabsView.listContainer = self.listContainerView
        tabsView.delegate = self
        self.tabsView = tabsView
        let viewModel = ThreadChatHeaderViewModel(
            userResolver: viewModel.userResolver,
            chatPushWrapper: chatPushWrapper,
            chatAPI: chatAPI,
            isDefaultTopicGroup: self.viewModel.isDefaultTopicGroup
        )
        // 涉及到动画的视图
        var relateAnimtaionViews = [UIView]()
        let threadAnounmentView = ThreadChatHeader(
            viewModel: viewModel,
            tabsView: tabsView,
            relateAnimtaionViews: relateAnimtaionViews,
            navBarHeight: self.navBarHeight
        )
        threadAnounmentView.addToView(self.view)
        threadAnounmentView.closeThreadChatHeader()
        self.threadAnounmentView = threadAnounmentView

        view.insertSubview(listContainerView, aboveSubview: threadAnounmentView)
        listContainerView.snp.makeConstraints { (make) in
            make.top.equalTo(threadAnounmentView.snp.bottom).offset(-listContainerOffset)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    private func setupAllTabController(with chat: Chat, topicGroup: TopicGroup) {
        guard tabControllers[.all] == nil else {
            return
        }
        let config = ThreadPreviewContentConfig(topicGroup: topicGroup, chat: chat)
        guard let allThreadController = try? getThreadsController(config) else { return }
        allThreadController.view.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        allThreadController.containerVC = self
        tabControllers[.all] = allThreadController
    }
}

extension ThreadGroupPreviewContainerController: UDTabsViewDelegate {
    /// 点击选中或者滚动选中都会调用该方法。适用于只关心选中事件，而不关心具体是点击还是滚动选中的情况。
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        ThreadGroupPreviewContainerController.logger.info("DidAppear \(index)")
    }

    /// 手动点击会触发，代码跳转不会触发
    func tabsView(_ tabsView: UDTabsView, didClickSelectedItemAt index: Int) {
        guard index < self.tabModels.count else { return }
        let model = self.tabModels[index]
    }
}

extension ThreadGroupPreviewContainerController: UDTabsListContainerViewDataSource {
    func numberOfLists(in listContainerView: UDTabsListContainerView) -> Int {
        return self.tabModels.count
    }

    func listContainerView(_ listContainerView: UDTabsListContainerView,
                           initListAt index: Int) -> UDTabsListContainerViewDelegate {
        guard index < self.tabModels.count else {
            Self.logger.error("index error -> \(self.tabModels.count) -> \(index) -> \(self.tabControllers.count)")
            return UnknownThreadTabContentView()
        }
        let itemType = self.tabModels[index].itemType
        if let targetVC = self.tabControllers[itemType] {
            return targetVC
        }
        guard let chat = self.viewModel.chatWrapper?.chat.value,
              let topicGroup = self.viewModel.topicGroupPushWrapper?.topicGroupObservable.value else {
            Self.logger.error("cannot create thread tabVC with nil chat or topicGroup")
            return UnknownThreadTabContentView()
        }
        switch itemType {
        case .all:
            setupAllTabController(with: chat, topicGroup: topicGroup)
            return tabControllers[.all] ?? UnknownThreadTabContentView()
        default:
            return UnknownThreadTabContentView()
        }
    }
}

extension ThreadGroupPreviewContainerController: FeedSelectionInfoProvider {
    func getFeedIdForSelected() -> String? {
        return self.viewModel.chatID
    }
}

// MARK: - ChatNavigationBarDelegate
extension ThreadGroupPreviewContainerController: ChatNavigationBarDelegate {
    func backItemClicked(sender: UIButton) {
        viewModel.navigator.pop(from: self)
    }
}

extension ThreadGroupPreviewContainerController: ChatOpenService {
    // "chat_id" 拼接\(chid_id)
    var chatPath: Path { return Path().prefix(Path().chat_id, with: viewModel.chatID) }

    func chatVC() -> UIViewController {
        return self
    }

    func chatTopNoticeChange(updateNotice: @escaping ((ChatTopNotice?) -> Void)) {
    }
}
