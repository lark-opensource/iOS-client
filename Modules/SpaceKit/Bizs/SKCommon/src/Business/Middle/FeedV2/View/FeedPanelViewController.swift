//
//  FeedPanelViewController.swift
//  SKCommon
//
//  Created by huayufan on 2021/5/14.
//
// swiftlint:disable file_length


import UIKit
import SKUIKit
import RxSwift
import RxCocoa
import SKResource
import SpaceInterface
import SKFoundation
import UniverseDesignToast
import UniverseDesignEmpty
import UniverseDesignMenu
import UniverseDesignColor
import UniverseDesignIcon

public protocol FeedPanelType {
    var isShowing: Bool { get }
}

public typealias FeedPanelViewControllerType = DraggableViewController & FeedPanelType & UIViewControllerTransitioningDelegate

enum FeedDataType {
    case cache([FeedCellDataSource])
    case frontend([FeedCellDataSource])
    case server([FeedCellDataSource])
    var isCache: Bool {
        switch self {
        case .cache:
            return true
        default:
            return false
        }
    }
}

public final class FeedPanelViewController: DraggableViewController, FeedPanelType,
                                      UIViewControllerTransitioningDelegate,
                                      UITableViewDelegate, UITableViewDataSource {

    struct Layout {
        static let titleViewHeight: CGFloat = 60
    }
    
    enum Event {
        case create
        case repeatShow(panelHeight: CGFloat)
        case cellClick(indexPath: IndexPath)
        case cellEvent(_ indexPath: IndexPath, FeedCommentCell.Event)
        case viewDidLoad(panelHeight: CGFloat)
        case viewDidAppear
        case cellWillDisplay(indexPath: IndexPath)
        case dismiss
        case renderBegin
        case renderEnd(FeedDataType)
    }
    
    var dismissCover = UIView()
    
    var tableView = UITableView()

    lazy var titleView: DraggableTitleView = {
        let view = DraggableTitleView(showMoreButton: UserScopeNoChangeFG.TYP.messageAllRead || UserScopeNoChangeFG.CS.feedMuteEnabled)
        view.muteButtonClickHandler = { [weak self] mute in
            self?.viewModel.toggleMuteState(mute)
        }
        view.delegate = self
        return view
    }()
    
    lazy var loadingView: DocFeedLoadingView = {
        return DocFeedLoadingView()
    }()
    
    lazy var emptyView: UDEmptyView = {
        let emptyView = UDEmptyView(config: .init(title: .init(titleText: ""),
                                                  description: .init(descriptionText: ""),
                                                  imageSize: 100,
                                                  type: .noFile,
                                                  labelHandler: nil,
                                                  primaryButtonConfig: nil,
                                                  secondaryButtonConfig: nil))
        emptyView.useCenterConstraints = true
        return emptyView
    }()
    
    var datas: [FeedCellDataSource] = []
    
    var viewModel: DocsFeedViewModel!
    
    /// 接收数据
    var triggerRelay = BehaviorRelay<[String: Any]>(value: [:])
    
    /// 传递事件
    var feedRelay = PublishRelay<Event>()
    
    var scrollEndRelay = PublishRelay<[IndexPath]>()
    
    private var disposeBag = DisposeBag()
    
    public private(set) var from: FeedFromInfo
    
    public private(set) var docsInfo: DocsInfo
    
    public var supportOrientations: UIInterfaceOrientationMask = .portrait
    
    public var isShowing = false

    private let muteDisable: Bool
    
    /// 复制权限数据源
    public weak var permissionDataSource: CCMCopyPermissionDataSource?
    
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = [.thisView]
        return preventer
    }()
    
    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return supportOrientations
    }
    
    public required init(api: DocsFeedAPI, from: FeedFromInfo, docsInfo: DocsInfo, param: [String: Any]? = nil) {
        self.from = from
        self.docsInfo = docsInfo
        self.muteDisable = docsInfo.type == .file || !(UserScopeNoChangeFG.CS.feedMuteEnabled)
        super.init(nibName: nil, bundle: nil)
        self.viewModel = DocsFeedViewModel(api: api, from: from, docsInfo: docsInfo, param: param, controller: self)
        self.viewModel.permissionDataSource = self
        self.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark
        bindViewModel()
        feedRelay.accept(.create)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupInit()
        setupLayout()
        updateContentSize()
        clearLeftItems()
        feedRelay.accept(.viewDidLoad(panelHeight: view.frame.size.height - self.contentViewMaxY))
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        feedRelay.accept(.viewDidAppear)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isShowing = true
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isShowing = false
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { [weak self] _ in
            let orientation = LKDeviceOrientation.getInterfaceOrientation()
            self?.didChangeStatusBarOrientation(to: orientation)
        }
    }
    
    private func setupInit() {
        
        dismissCover.construct({
            $0.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
            $0.layer.shadowOffset = CGSize(width: 5, height: -10)
            $0.layer.shadowOpacity = 2
            $0.layer.shadowRadius = 22
            $0.isUserInteractionEnabled = true
            $0.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDismiss)))
        })
        
        contentView = UIView().construct({
            $0.backgroundColor = UIColor.ud.bgBody
            $0.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
            $0.layer.shadowOffset = CGSize(width: 5, height: -10)
            $0.layer.shadowOpacity = 2
            $0.layer.shadowRadius = 22
        })
        
        titleView.construct {
            $0.backgroundColor = UIColor.clear
            $0.addGestureRecognizer(panGestureRecognizer)
            $0.setTitle(BundleI18n.SKResource.Doc_Normal_DocMessage)
            $0.showDefaultShadowColor()
            $0.titleLabel.isAccessibilityElement = true
            $0.titleLabel.accessibilityIdentifier = "docs.feed.panel.title.label"
            $0.titleLabel.accessibilityLabel = "docs.feed.panel.title.label"
            $0.titleLabel.textColor = UIColor.ud.N900
            $0.titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        }
        
        tableView.construct {
            $0.register(FeedCommentCell.self, forCellReuseIdentifier: FeedCommentCell.reuseIdentifier)
            $0.register(FeedCommentCell.self, forCellReuseIdentifier: FeedCommentCell.simpleStyleIdentifier)
            $0.register(FeedCommentEmptyCell.self, forCellReuseIdentifier: FeedCommentEmptyCell.reuseIdentifier)
            $0.rowHeight = UITableView.automaticDimension
            $0.estimatedRowHeight = 80
            $0.delegate = self
            $0.dataSource = self
            $0.backgroundColor = UIColor.ud.bgBody
            $0.separatorStyle = .none
        }
        let container: UIView
        if ViewCapturePreventer.isFeatureEnable {
            container = viewCapturePreventer.contentView
            view.addSubview(container)
            container.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
        } else {
            container = view
        }
        container.addSubview(dismissCover)
        container.addSubview(contentView)
        contentView.addSubview(tableView)
        contentView.addSubview(titleView)
        contentView.addSubview(loadingView)
        
        setupCornerRadii()
        setuptitleView()
    }
    
    private func setupLayout() {
        dismissCover.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
//            make.left.right.top.equalToSuperview()
//            make.bottom.equalTo(contentView.snp.top)
        }
        
        contentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(contentViewMaxY)
            make.bottom.equalToSuperview()
        }
        
        titleView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(Layout.titleViewHeight)
        }
        
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleView.snp.bottom)
            make.bottom.equalToSuperview()
        }
        
        loadingView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(tableView)
            $0.height.equalTo(40)
        }
    }
    
    private func updateContentSize() {
        if SKDisplay.phone {
            if UIApplication.shared.statusBarOrientation.isLandscape {
                contentView.snp.remakeConstraints { (make) in
                    make.centerX.bottom.equalToSuperview()
                    make.top.equalTo(contentViewMaxY)
                    make.width.equalToSuperview().multipliedBy(0.7)
                }
                contentViewMinY = 11
            } else {
                contentView.snp.remakeConstraints { (make) in
                    make.left.right.equalToSuperview()
                    make.top.equalTo(contentViewMaxY)
                    make.bottom.equalToSuperview()
                }
                contentViewMinY = 64
            }
            updateEmptyViewSize()
        }
    }
    
    func updateEmptyViewSize() {
        guard emptyView.superview != nil else {
            return
        }
        if UIApplication.shared.statusBarOrientation.isLandscape {
            emptyView.snp.remakeConstraints { (make) in
                make.centerX.bottom.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(0.7)
                make.top.equalTo(titleView.snp.bottom)
            }
        } else {
            emptyView.snp.remakeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(titleView.snp.bottom)
            }
        }
    }
    
    private func clearLeftItems() {
        navigationItem.leftBarButtonItems = []
    }

    private func bindViewModel() {
        
        let input = DocsFeedViewModel.Input(trigger: triggerRelay,
                                            eventDrive: feedRelay,
                                            scrollEndRelay: scrollEndRelay)
        
        let output = viewModel.transform(input: input)
        
        // MARK: - 输出事件
        
        // 刷新UI
        output.data
              .subscribe(onNext: { [weak self] (dataType) in
                guard let self = self else { return }
                switch dataType {
                case let .cache(messages),
                     let .frontend(messages),
                     let .server(messages):
                    DocsLogger.feedInfo("receive data count:\(messages.count)")
                    self.datas = messages
                    self.feedRelay.accept(.renderBegin)
                    self.tableView.reloadData()
                    DispatchQueue.main.async {
                        self.feedRelay.accept(.renderEnd(dataType))
                    }
                }
                
            }).disposed(by: disposeBag)
        
        // 关闭面板
        output.close
              .subscribe(onNext: { [weak self] _ in
                self?.tapDismiss()
            }).disposed(by: disposeBag)
        
        // 隐藏红点
        output.readRelay
              .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                if let cell = self.tableView.cellForRow(at: indexPath) as? FeedCommentCell {
                    cell.hideRedDot()
                }
        }).disposed(by: disposeBag)
        
        // 局部刷新
        output.reloadSection
              .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                self.tableView.reloadRows(at: [indexPath], with: .none)
        }).disposed(by: disposeBag)
        
        output.gapStateRelay
              .subscribe(onNext: { [weak self] gapState in
              guard let self = self else { return }
              self.gapState = gapState
        }).disposed(by: disposeBag)
        
        output.showEmptyView.bind(to: rx.showEmptyView).disposed(by: disposeBag)
        
        output.showHUD.bind(to: rx.showHUD).disposed(by: disposeBag)
        
        output.loading.bind(to: rx.showLoading).disposed(by: disposeBag)
        
        output.scrollToItem.bind(to: rx.scrollToItem).disposed(by: disposeBag)

        output.muteToggleClickable.subscribe(onNext: { [weak self] in
            self?.titleView.setMuteToggleClickable($0)
        }).disposed(by: disposeBag)

        output.muteToggleIsMute.subscribe(onNext: { [weak self] in
            let fgDisable = self?.muteDisable ?? true
            self?.titleView.setMuteToggleHidden($0.isNil || fgDisable)
            self?.titleView.setMuteState($0 ?? false)
        }).disposed(by: disposeBag)
    }
    
    private func setupCornerRadii() {
        contentView.layer.cornerRadius = 12
        contentView.layer.maskedCorners = .top
    }
    
    private func setuptitleView() {
        //drive文件 在关闭FG的情况下不展示more按钮
        if docsInfo.type == .file && !(UserScopeNoChangeFG.TYP.messageAllRead) {
            titleView.setMoreButtonHidden(true)
        }
    }
    
    @objc
    func tapDismiss() {
        dismissPanel(animated: true)
    }
    
    public override func dragDismiss() {
        dismissPanel(animated: true)
    }
    
    public func dismissPanel(animated: Bool) {
        self.dismiss(animated: animated, completion: nil)
        feedRelay.accept(.dismiss)
    }

    // MARK: - UIViewControllerTransitioningDelegate

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomPresentAnimated()
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CustomDismissAnimated()
    }
    // MARK: - public
    /// 接收数据
    public func udpate(param: [String: Any]) {
        triggerRelay.accept(param)
    }
    
    /// 当前已经存在，又重复调用展示
    public func repeatShow() {
        feedRelay.accept(.repeatShow(panelHeight: view.frame.size.height - self.contentViewMaxY))
    }

    // MARK: - UITableViewDelegate UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datas.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if datas[indexPath.row].cellIdentifier != FeedCommentEmptyCell.reuseIdentifier {
            return UITableView.automaticDimension
        } else {
            return 0.01
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dequeueCell = tableView.dequeueReusableCell(withIdentifier: datas[indexPath.row].cellIdentifier, for: indexPath)
        if let cell = dequeueCell as? FeedCommentCell {
            var data = datas[indexPath.row]
            if UserScopeNoChangeFG.WWJ.permissionSDKEnable {
                data.contentCanCopy = permissionDataSource?.getCopyPermissionService()?.validate(operation: .copyContent).allow ?? false
            } else {
                let ownerAllow = permissionDataSource?.ownerAllowCopyFG() ?? false
                let adminAllow = permissionDataSource?.adminAllowCopyFG() ?? false
                data.contentCanCopy = ownerAllow && adminAllow
            }
            cell.config(data: data, redDotDelegate: viewModel)
            cell.actions
                .map { Event.cellEvent(indexPath, $0) }
                .bind(to: feedRelay)
                .disposed(by: cell.reuseBag)
            return cell
        } else if let cell = dequeueCell as? FeedCommentEmptyCell {
            return cell
        }
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        feedRelay.accept(.cellClick(indexPath: indexPath))
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        feedRelay.accept(.cellWillDisplay(indexPath: indexPath))
    }
    
    public func reloadTableViewData() {
        self.tableView.reloadData()
    }
    
    public func didChangeStatusBarOrientation(to newOrentation: UIInterfaceOrientation) {
        guard SKDisplay.phone, newOrentation != .unknown else { return }
        updateContentSize()
    }
    
    // 惯性滚动停止
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        logCurrentMessageIds(stage: "DidEndDecelerating")
    }
    
    // 手离开屏幕，没有惯性滚动
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            logCurrentMessageIds(stage: "DidEndDragging")
        }
    }
    
    private func logCurrentMessageIds(stage: String) {
        if let visibleRows = tableView.indexPathsForVisibleRows {
            scrollEndRelay.accept(visibleRows)
        } else {
            DocsLogger.feedInfo("no visibale rows at: \(stage)")
        }
    }
}

extension FeedPanelViewController: DraggableTitleDelegate {
    func didClickMoreButton(sourceView: UIView, operation: FeedMuteToggleView.Operation) {
        var actions: [UDMenuAction] = []
        
        // muteToggle
        if UserScopeNoChangeFG.CS.feedMuteEnabled && docsInfo.type != .file {
            let operationValue = setOperation(operation)
            var action = UDMenuAction(title: operationValue.1,
                                      icon: operationValue.0,
                                      showBottomBorder: false,
                                      tapHandler: { [weak self] in
                guard let self = self else {
                    DocsLogger.error("DraggableTitleView open fail, self is nil")
                    return
                }
                let isMute = (operation == .mute)
                self.viewModel.toggleMuteState(isMute)
            })
            action.titleTextColor = UDColor.textTitle
            actions.append(action)
        }
        
        // cleanButton
        if UserScopeNoChangeFG.TYP.messageAllRead {
            let hasUnReadMessage = hasUnReadMessage()
            var cleanAction: UDMenuAction
            if hasUnReadMessage {
                cleanAction = UDMenuAction(title: BundleI18n.SKResource.LarkCCM_Docs_Notifications_MarkAllRead_Menu_Mob, icon: UDIcon.doneOutlined, tapHandler: { [weak self] in
                    guard let self = self else {
                        DocsLogger.error("DraggableTitleView open fail, self is nil")
                        return
                    }
                    /// 后端接口
                    self.viewModel.toggleCleanButton()
                })
                
                cleanAction.titleTextColor = UDColor.textTitle
            } else {
                cleanAction = UDMenuAction(title: BundleI18n.SKResource.LarkCCM_Docs_Notifications_AllRead_Menu_Mob, icon: UDIcon.doneOutlined, tapHandler: nil)
                cleanAction.customIconHandler = { imageView in
                    imageView.image = UDIcon.doneOutlined.ud.withTintColor(UDColor.textDisabled)
                }
                cleanAction.isDisabled = true
                cleanAction.titleTextColor = UDColor.textDisabled
            }
            actions.append(cleanAction)
        }
        // UDMenu 暂不支持 横屏，需要点击的时候手动设置为竖屏
        LKDeviceOrientation.forceInterfaceOrientationIfNeed(to: .portrait) {
            var style = UDMenuStyleConfig.defaultConfig()
            style.menuMaxWidth = self.view.frame.width
            let menu = UDMenu(actions: actions, style: style)
            menu.showMenu(sourceView: sourceView, sourceVC: self)
        }
    }
    
    func hasUnReadMessage() -> Bool {
        return (viewModel.unReadedMessages.count != 0)
    }
    
    func setOperation(_ operation: FeedMuteToggleView.Operation) -> (UIImage, String) {
        switch operation {
        case .mute:
            return (UDIcon.alertsOffOutlined.ud.withTintColor(UDColor.iconN1), BundleI18n.SKResource.LarkCCM_Docs_Mute_Button)
        case .remind:
            return (UDIcon.bellOutlined.ud.withTintColor(UDColor.iconN1) , BundleI18n.SKResource.LarkCCM_Docs_Unmute_Button)
        }
    }
}

extension FeedPanelViewController {
    public func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
}

// MARK: - Binder

extension Reactive where Base: FeedPanelViewController {
    
    var showEmptyView: Binder<Bool> {
        return Binder(base) { (target, show) in
            if show {
                if target.emptyView.superview == nil {
                    target.view.addSubview(target.emptyView)
                    target.updateEmptyViewSize()
                }
                var config = UDEmptyConfig(title: .init(titleText: ""),
                                           description: .init(descriptionText: ""),
                                           type: .noNotice,
                                           labelHandler: nil,
                                           primaryButtonConfig: nil,
                                           secondaryButtonConfig: nil)
                if DocsNetStateMonitor.shared.isReachable {
                    config.description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.Doc_Doc_NoContent)
                    config.type = UDEmptyType.noGroup
                } else {
                    config.description = UDEmptyConfig.Description(descriptionText: BundleI18n.SKResource.Doc_Doc_NetException)
                    config.type = UDEmptyType.noWifi
                }
                target.emptyView.update(config: config)
            }
            target.emptyView.isHidden = !show
        }
    }

    var showHUD: Binder<DocsFeedViewModel.HUDType> {
        return Binder(base) { (target, type) in
            guard let view = target.view.window ?? target.view else {
                return
            }
            switch type {
            case .success(let text):
                UDToast.showSuccess(with: text, on: view)
            case .failure(let text):
                UDToast.showFailure(with: text, on: view)
            case .tips(let text):
                UDToast.showTips(with: text, on: view)
            case .loading(let text):
                UDToast.showLoading(with: text, on: view)
            case .close:
                UDToast.removeToast(on: view)
            }
        }
    }
    
    var showLoading: Binder<Bool> {
        return Binder(base) { (target, isLoading) in
            target.loadingView.isHidden = !isLoading
            if isLoading {
                target.loadingView.startLoading()
            } else {
                target.loadingView.stopLoading()
            }
        }
    }
    
    var scrollToItem: Binder<IndexPath> {
        return Binder(base) { (target, indexPath) in
            let numberOfRows = target.tableView.numberOfRows(inSection: 0)
            if indexPath.row < numberOfRows {
                target.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
//                target.tableView.layoutIfNeeded()
            } else {
                DocsLogger.feedError("indexPath:\(indexPath) greater than \(numberOfRows)")
            }
        }
    }
}

// MARK: - CCMCopyPermissionDataSource
extension FeedPanelViewController: CCMCopyPermissionDataSource {
    public func getCopyPermissionService() -> UserPermissionService? {
        permissionDataSource?.getCopyPermissionService()
    }
    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    public func adminAllowCopyFG() -> Bool {
        permissionDataSource?.adminAllowCopyFG() ?? false
    }
    @available(*, deprecated, message: "Use permissionService instead - PermissionSDK")
    public func ownerAllowCopy() -> Bool {
        return permissionDataSource?.ownerAllowCopy() ?? false
    }
    
    public func canPreview() -> Bool {
        return permissionDataSource?.canPreview() ?? false
    }
}
