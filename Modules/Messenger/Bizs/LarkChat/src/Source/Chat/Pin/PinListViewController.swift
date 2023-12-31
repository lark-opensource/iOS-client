//
//  PinListViewController.swift
//  LarkChat
//
//  Created by zc09v on 2019/9/16.
//

import UIKit
import Foundation
import LarkUIKit
import LarkCore
import SnapKit
import RxSwift
import RxCocoa
import EENavigator
import LarkModel
import LarkMessageBase
import LarkGuide
import LarkSDKInterface
import AnimatedTabBar
import LarkMessageCore
import LKCommonsLogging
import LarkMessengerInterface
import LarkNavigation
import LarkTab
import LarkSplitViewController
import LarkAI
import LarkFeatureGating
import RustPB
import RichLabel
import UniverseDesignToast
import Homeric
import LKCommonsTracker
import LarkOpenChat

final class EnterPinCostInfo {
    private let start = CACurrentMediaTime()
    var sdkCost: Int?
    var initViewStamp: TimeInterval?
    var firstRenderStamp: TimeInterval?
    var end: TimeInterval?
    var chat: Chat?

    lazy var reciableLatencyDetail: [String: Any] = {
        guard let sdkCost = self.sdkCost,
              let initViewStamp = self.initViewStamp,
              let firstRenderStamp = self.firstRenderStamp,
              let end = end else {
            return [:]
        }
        return ["sdk_cost": sdkCost,
                "init_view_cost": Int((initViewStamp - start) * 1000),
                "first_render_cost": Int((firstRenderStamp - start) * 1000)]
    }()

    lazy var reciableMetric: [String: Any] = {
        guard let chat = self.chat else {
            return [:]
        }
        return ["feed_id": chat.id,
                "chatter_count": chat.userCount]
    }()

    lazy var reciableCategory: [String: Any] = {
        guard let chat = self.chat else {
            return [:]
        }
        return ["chat_type": self.chatTypeForReciable]
    }()

    lazy var cost: Int = {
        guard let end = end else { return 0 }
        return Int((end - start) * 1000)
    }()

    private lazy var chatTypeForReciable: Int = {
        guard let chat = self.chat else {
            return 0
        }
        var chatType: Int = 0
        if chat.chatMode == .threadV2 {
            chatType = 3
        } else if chat.type == .p2P {
            chatType = 1
        } else if chat.type == .group {
            chatType = 2
        }
        return chatType
    }()
}

final class PinListViewController: BaseUIViewController, UITextFieldDelegate {
    static let pageName = "\(PinListViewController.self)"

    static let searchViewHeight: CGFloat = 58
    private let disposeBag = DisposeBag()
    private let searchView = PinListSearchWrapperView()
    private var searchTextField: SearchUITextField {
        return searchView.searchTextField
    }
    private let resultView = SearchResultView(tableStyle: .plain)
    //pin搜索结果列表
    private var searchTableView: UITableView { return resultView.tableview }
    //pin列表
    private lazy var pinTableView: PinListTableView = {
        let tableview = PinListTableView(frame: .zero, style: .plain)
        tableview.backgroundColor = UIColor.clear
        tableview.separatorColor = UIColor.clear
        tableview.rowHeight = UITableView.automaticDimension
        tableview.estimatedRowHeight = 64
        tableview.keyboardDismissMode = .onDrag
        tableview.separatorStyle = .none
        tableview.enableTopPreload = false
        tableview.lu.addLongPressGestureRecognizer(action: #selector(bubbleLongPressed(_:)),
                                                   duration: 0.2,
                                                   target: self)
        tableview.contentInsetAdjustmentBehavior = .never
        return tableview
    }()

    private var currentTable: UITableView {
        switch self.viewModel.status {
        case .all:
            return self.pinTableView
        case .search:
            return self.searchTableView
        }
    }

    private let viewModel: PinListViewModel
    private let context: PinContext
    private let guideService: GuideService
    private let pinMenuService: PinMenuService

    // swiftlint:disable weak_delegate
    private lazy var pinListTableDelegate: PinListTableViewDelegateImpl = {
        return PinListTableViewDelegateImpl(viewModel: self.viewModel,
                                           targetVC: self)
    }()

    private lazy var searchPinListTableDelegate: SearchPinListTableViewDelegate = {
        return SearchPinListTableViewDelegate(viewModel: self.viewModel,
                                           targetVC: self)
    }()
    // swiftlint:enable weak_delegate

    lazy var emptyPinsView: PinListEmptyView = {
        let emptyView = PinListEmptyView()
        if self.chat.chatMode == .threadV2 {
            emptyView.tipsText = BundleI18n.LarkChat.Lark_Chat_TopicSidebarPinTip
        } else {
            emptyView.tipsText = BundleI18n.LarkChat.Lark_Pin_TipForTheEmptyPinList
        }
        emptyView.isHidden = true
        return emptyView
    }()

    private let enterCostInfo: EnterPinCostInfo
    private let chat: Chat

    private lazy var screenProtectService: ChatScreenProtectService? = {
        return self.context.pageContainer.resolve(ChatScreenProtectService.self)
    }()
    private lazy var placeholderChatView: PlaceholderChatView = {
        let placeholderChatView = PlaceholderChatView(isDark: false,
                                                      title: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Text,
                                                      subTitle: BundleI18n.LarkChat.Lark_IM_RestrictedMode_ScreenRecordingEmptyState_Desc)
        placeholderChatView.setNavigationBarDelegate(self)
        return placeholderChatView
    }()

    init(chat: Chat,
         context: PinContext,
         viewModel: PinListViewModel,
         guideService: GuideService,
         pinMenuService: PinMenuService,
         enterCostInfo: EnterPinCostInfo) {
        self.chat = chat
        self.viewModel = viewModel
        self.context = context
        self.guideService = guideService
        self.pinMenuService = pinMenuService
        self.enterCostInfo = enterCostInfo
        super.init(nibName: nil, bundle: nil)
        self.context.pageContainer.pageInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.context.pageContainer.pageDeinit()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizeVMIfNeeded()
    }

    private func resizeVMIfNeeded() {
        let size = view.bounds.size
        if size != viewModel.hostUIConfig.size {
            viewModel.hostUIConfig.size = size
            viewModel.onResize()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        context.pageContainer.pageWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        context.pageContainer.pageDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        context.pageContainer.pageWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        context.pageContainer.pageDidDisappear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.supportSecondaryOnly = true
        self.viewModel.hostUIConfig = HostUIConfig(
            size: navigationController?.view.bounds.size ?? view.bounds.size,
            safeAreaInsets: navigationController?.view.safeAreaInsets ?? view.safeAreaInsets
        )
        self.view.backgroundColor = UIColor.ud.bgBase

        let tableInsetTop: CGFloat
        let emptyViewTopConstraint: ConstraintItem
        let naviHeight = 0
        tableInsetTop = PinListViewController.searchViewHeight
        self.title = BundleI18n.LarkChat.Lark_IM_NewPin_PinnedMessages_Title
        searchTextField.addTarget(self, action: #selector(inputViewTextFieldBeginEdit), for: .editingDidBegin)
        searchTextField.addTarget(self, action: #selector(inputViewTextFieldDidChange), for: .editingChanged)
        searchTextField.delegate = self
        self.view.addSubview(searchView)
        searchView.snp.makeConstraints({ make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(PinListViewController.searchViewHeight)
        })
        resultView.isHidden = true
        resultView.defaultNoResultTip = BundleI18n.LarkChat.Lark_Pin_SearchNoResult
        self.view.addSubview(resultView)
        resultView.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.right.bottom.equalToSuperview()
        }
        resultView.tableview.contentInset = UIEdgeInsets(top: tableInsetTop, left: 0, bottom: 0, right: 0)
        resultView.loadingViewTopOffset = tableInsetTop
        self.searchPinListTableDelegate.tableView = resultView.tableview
        self.pinListTableDelegate.searchView = searchView
        self.searchPinListTableDelegate.searchView = searchView
        emptyViewTopConstraint = searchView.snp.bottom
        self.pinListTableDelegate.tableView = pinTableView
        pinTableView.contentInset = UIEdgeInsets(top: tableInsetTop, left: 0, bottom: 0, right: 0)
        self.view.addSubview(pinTableView)
        pinTableView.snp.makeConstraints({ make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(naviHeight)
            make.left.right.bottom.equalToSuperview()
        })
        self.view.bringSubviewToFront(resultView)
        self.view.bringSubviewToFront(searchView)
        self.view.addSubview(emptyPinsView)
        emptyPinsView.snp.makeConstraints { (make) in
            make.top.equalTo(emptyViewTopConstraint).offset(naviHeight)
            make.left.right.bottom.equalToSuperview()
        }

        self.bindViewModel()
        self.loadInitData()

        self.context.pageContainer.pageViewDidLoad()
        self.enterCostInfo.firstRenderStamp = CACurrentMediaTime()
        ChatTracker.trackChatIMChatPinView(chat: chat)
    }

    private func loadInitData() {
        self.viewModel.loadSearchCache()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                if let result = result {
                    self?.searchTextField.text = result.0
                }
                self?.searchTextField.canEdit = true
                self?.viewModel.fetchInitPins()
            }).disposed(by: self.disposeBag)
    }

    private func showGuideIfNeeded() {
        let key = "all_add_pin"
        /// 新版群架构不展示 old pin 引导
        guard !ChatNewPinConfig.checkEnable(chat: self.viewModel.chat, self.context.userResolver.fg) else {
            return
        }
        guard self.guideService.needShowGuide(key: key) else {
            return
        }
        var preferences = EasyhintBubbleView.globalPreferences
        preferences.drawing.arrowPosition = .top
        preferences.positioning.bubbleVInset = 0
        preferences.positioning.textVInset = 12
        preferences.positioning.railingOffset = CGPoint(x: 0, y: -12)
        preferences.drawing.textColor = UIColor.ud.textTitle
        preferences.drawing.font = UIFont.systemFont(ofSize: 14)
        preferences.positioning.maxWidth = 302
        preferences.drawing.textAlignment = .left
        GuideInterface.startBubbleGuide(
            text: BundleI18n.LarkChat.Lark_Pin_ClickSideBarGuideTipsMobile,
            preference: preferences,
            bearViewController: self,
            cutoutView: { [weak self] in
                return self?.navigationController?.navigationBar
            }, dismiss: { [weak self] in
                self?.guideService.didShowGuide(key: key)
            })
    }

    @objc
    private func bubbleLongPressed(_ gesture: UILongPressGestureRecognizer) {
        pinListTableDelegate.bubbleLongPressed(gesture)
    }

    private let _firstScreenDataReady = BehaviorRelay<Bool>(value: false)
    private func bindViewModel() {
        var hud: UDToast?
        self.viewModel.initStateDriver.drive(onNext: { [weak self] (state) in
            switch state {
            case .startInit:
                //如果上来显示了搜索缓存，不用显示loading
                if self?.viewModel.searchUIDataSource.isEmpty ?? false, let view = self?.view {
                    hud = UDToast.showDefaultLoading(on: view, disableUserInteraction: false)
                }
            case .initFinish:
                hud?.remove()
                self?.showGuideIfNeeded()
            case .none:
                break
            }
        }).disposed(by: self.disposeBag)

        self.viewModel.tableRefreshDriver.drive(onNext: { [weak self] (refreshType) in
            self?.swichTable()
            switch refreshType {
            case .refreshTable(let hasMore, let scrollTo):
                self?._firstScreenDataReady.accept(true)
                self?.currentTable.reloadData()
                if self?.viewModel.status ?? .all == .search {
                    self?.resultView.status = .result
                }
                self?.configLoadMore(hasMore: hasMore)
                if let scrollTo = scrollTo {
                    self?.currentTable.scrollToRow(at: scrollTo, at: .top, animated: false)
                }
                self?.showNoDataTipIfNeeded()
            case .searching:
                self?.resultView.status = .loading
            case .loadMoreFail:
                self?.currentTable.endBottomLoadMore()
            case .searchFail:
                self?.resultView.status = .result
                UDToast.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_SearchFail, on: self?.view ?? UIView())
            }
        }).disposed(by: self.disposeBag)

        self.viewModel.getPinsLoadMoreEnableDriver.drive(onNext: { [weak self] (enable) in
            self?.pinTableView.enableBottomLoadMore(enable)
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

    private func configLoadMore(hasMore: Bool?) {
        switch self.viewModel.status {
        case .search:
            if let hasMore = hasMore {
                if hasMore {
                    self.searchTableView.addBottomLoadMoreView { [weak self] in
                        self?.viewModel.loadMorePins()
                    }
                } else {
                    self.searchTableView.removeBottomLoadMore()
                }
            }
            self.searchTableView.enableBottomLoadMore(true)
        case .all:
            if let hasMore = hasMore {
                self.pinTableView.hasFooter = hasMore
            }
            self.pinTableView.enableBottomLoadMore(self.viewModel.getPinsLoadMoreEnable.value)
        }
    }

    private func swichTable() {
        switch self.viewModel.status {
        case .search:
            self.resultView.isHidden = false
            self.pinTableView.isHidden = true
        case .all:
            self.resultView.isHidden = true
            self.pinTableView.isHidden = false
        }
    }

    private func showNoDataTipIfNeeded() {
        switch self.viewModel.status {
        case .all:
            if self.viewModel.pinUIDataSource.isEmpty {
                emptyPinsView.isHidden = false
            } else {
                emptyPinsView.isHidden = true
            }
        case .search:
            emptyPinsView.isHidden = true
            if self.viewModel.searchUIDataSource.isEmpty {
                resultView.status = .noResult("")
            }
        }
    }

    @objc
    private func inputViewTextFieldBeginEdit() {
        ChatTracker.trackChatPinSearch()
        ChatTracker.trackIMChatPinClickSearch(chat: chat)
    }

    @objc
    private func inputViewTextFieldDidChange() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(searchTextChangedHandler), object: nil)
        self.perform(#selector(searchTextChangedHandler), with: nil, afterDelay: 0.3)
    }

    @objc
    private func searchTextChangedHandler() {
        guard searchTextField.markedTextRange == nil else { return }
        if searchTextField.text?.isEmpty ?? true {
            ChatTracker.trackChatPinSearchClear()
        }
        self.viewModel.searchPin(text: searchTextField.text ?? "", filters: [])
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.searchView.alpha = 1
    }
}

extension PinListViewController: PageAPI {
    func viewWillEndDisplay() {
        // viewModel not support enableUIOutput and message processing frequency is relatively low. so just use pauseQueue
        self.viewModel.pauseQueue()
        self.pinTableView.endDisplayVisibleCells()
    }

    func viewDidDisplay() {
        self.pinTableView.displayVisibleCells()
        self.viewModel.resumeQueue()
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

private final class PinListSearchWrapperView: UIView {
    let searchTextField: SearchUITextField = SearchUITextField()
    override init(frame: CGRect) {
        super.init(frame: frame)
        searchTextField.canEdit = false
        searchTextField.backgroundColor = UIColor.ud.N100
        searchTextField.placeholder = BundleI18n.LarkChat.Lark_Legacy_Search
        self.addSubview(searchTextField)
        searchTextField.snp.makeConstraints({ make in
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
        })
        self.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - EnterpriseEntityWordProtocol
extension PinListViewController: EnterpriseEntityWordDelegate {
    static private let logger = Logger.log(PinListViewController.self, category: "LarkNewPin.PinListViewController")

    func lockForShowEnterpriseEntityWordCard() {
        PinListViewController.logger.info("PinListViewController: pauseQueue for show enterprise entuty word card")
        viewModel.pauseDataQueue(true)
        searchTextField.resignFirstResponder()
    }

    func unlockForHideEnterpriseEntityWordCard() {
        PinListViewController.logger.info("PinListViewController: resumeQueue for after enterprise entuty word card hide")
        viewModel.pauseDataQueue(false)
    }
}

extension PinListViewController: PlaceholderChatNavigationBarDelegate {
    func backButtonClicked() {
        context.navigator.pop(from: self)
    }
}

extension PinListViewController: ChatMessagesOpenService {
    var pageAPI: PageAPI? {
        return self
    }
    var dataSource: DataSourceAPI? {
        return self.context.dataSourceAPI
    }
}
