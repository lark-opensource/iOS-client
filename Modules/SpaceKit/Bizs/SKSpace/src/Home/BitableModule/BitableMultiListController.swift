//
//  BitableMultiListController.swift
import UIKit
import SnapKit
import RxSwift
import RxRelay
import RxCocoa
import ESPullToRefresh
import LarkContainer

import SKUIKit
import SKResource
import SKFoundation
import SKCommon

import UniverseDesignColor
import LarkUIKit
import UniverseDesignToast
import EENavigator
import LarkSceneManager
import LarkSplitViewController

import UniverseDesignBadge
import UniverseDesignDialog
import SpaceInterface
import SKInfra
import SKWorkspace


public class BitableMultiListController: UIViewController, SlideableSimultaneousGesture {
    
    //MARK: 容器属性
    public let userResolver: UserResolver
    private let disposeBag = DisposeBag()
 
    // 布局模块
    public let homeUI: SpaceHomeUI
    // 创建功能模块
    public let homeViewModel: SpaceHomeViewModel
    let keyboard = Keyboard()
    public var tabBadgeVisableChanged: Observable<Bool> {
        homeViewModel.tabBadgeVisableChanged
    }
  
    //MARK: 代理协议属性
    weak public var delegate: BitableMultiListControllerDelegate?
    
    //MARK: 状态属性
    var currentShowStyle: BitableMultiListShowStyle = .embeded
    var isInAnimation: Bool = false
    // 用于在 appear 的时候响应某些全局刷新的逻辑，如秘钥删除
    var isAppear = false
    private var hasDisappear = true
    var needRefreshWhenAppear = false
    var refreshing = false
    var hasActionView: Bool = false
    // 允许单元格支持响应多个手势，默认不支持
    public var enableSimultaneousGesture:Bool = true
    
    //MARK: UI属性
    // 导航栏模块
    public let naviBarCoordinator: SpaceNaviBarCoordinator
    //上拉下拉刷新
    private lazy var circleRefreshAnimator: BitableMultiListRefreshHeader = {
        let animator = BitableMultiListRefreshHeader.init()
        return animator
    }()
    lazy var footerAnimator = SpaceMoreRefreshAnimator()
    var refreshTipView: SpaceListRefreshTipView?
    var previousTipShowDate: Date?
 
    // 悬浮创建按钮
    public lazy var createButton = SKCreateButton()
    private lazy var disabledCreateMaskView = UIControl()

    var collectionViewConfig: BitableMultiListUIConfig?
    var collectionView: UICollectionView {
        return internalCollectionView
    }
    
    lazy public var multiListCollectionView: UICollectionView = {
        return internalCollectionView
    }()
    
    lazy public var internalCollectionView: BitableMultiListCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionHeadersPinToVisibleBounds = true
        let view = BitableMultiListCollectionView(frame: .zero, collectionViewLayout: layout)
        view.contentInsetAdjustmentBehavior = .never
        view.alwaysBounceVertical = true
        view.backgroundColor = UDColor.rgb("#FCFCFD") & UDColor.rgb("#202020")
        view.delegate = self
        view.dataSource = self
        view.dragDelegate = self
        return view
    }()
    
    lazy var decorationEmptyView: BitableMultiListDecorationView  = {
        let view = BitableMultiListDecorationView.init(style: .hasMuchSpace) { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate?.createBitableFileIfNeeded(isEmpty: false)
        }
        view.isHidden = true
        return view
    }()
    
    lazy var decorationGradientView: BitableMultiListDecorationView  = {
        let view = BitableMultiListDecorationView.init(style: .listIsfull)
        view.isHidden = true
        return view
    }()
    
    lazy public var swipeEmbedeGesture: UISwipeGestureRecognizer = {
        let swipe = UISwipeGestureRecognizer.init(target: self, action: #selector(swipeToTriggerEmbedStyle(recognizer: )))
        swipe.direction = .right
        return swipe
    }()
    
    //MARK: 构造方法
    deinit {
        print("SpaceHomeViewController deinit")
    }
    
    public init(userResolver: UserResolver,
                naviBarCoordinator: SpaceNaviBarCoordinator,
                homeUI: SpaceHomeUI,
                homeViewModel: SpaceHomeViewModel) {
        self.userResolver = userResolver
        self.naviBarCoordinator = naviBarCoordinator
        self.homeUI = homeUI
        self.homeViewModel = homeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init with coder not impl")
    }
    
    //MARK: lifeCycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindUIEvents()
        setupVM()
        setupKeyboardMonitor()
        setupAppearEvent()
        homeViewModel.notifyViewDidLoad()
        
        self.createButton.isHidden = true
        self.collectionView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        setUpDecorationView()
        updateDecorationViewConstraints()

        addApplicationObserver()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard self.isInAnimation == false else {
            return
        }
        homeViewModel.notifyViewDidAppear()
        homeUI.notifyViewDidAppear()
        isAppear = true
        if needRefreshWhenAppear {
            needRefreshWhenAppear = false
            DocsLogger.info("space.home.vc --- refresh when appear for previous notification")
            homeUI.notifyPullToRefresh()
        }

        // 文件列表从半屏到全屏会触发一次 viewDidAppear，导致多上报一次 trackerFileListView，这里过滤一下
        if hasDisappear {
            trackerFileListView()
        }
        hasDisappear = false
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard self.isInAnimation == false else {
            return
        }
        isAppear = false
        homeUI.notifyViewWillDisappear()
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard self.isInAnimation == false else {
            return
        }
        hasDisappear = true
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeUI.notifyViewDidLayoutSubviews(hostVCWidth: view.frame.width)
    }
    
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        guard UIApplication.shared.applicationState != .background else { return }
        DocsLogger.info("darkmode.service --- \(String(describing: type(of: self))) user interface style did change")
        NotificationCenter.default.post(name: Notification.Name.DocsThemeChanged, object: nil)
    }

    //MARK: publicMethod
    public func reloadHomeLayout() {
        view.layoutIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // 暴露给外部继承处理创建按钮的展示状态
    func setupCreateButtonHiddenStatus() {
        homeViewModel.createVisableDriver.map { !$0 }.drive(createButton.rx.isHidden).disposed(by: disposeBag)
    }

    func reloadData() {
        collectionView.reloadData()
    }
    
    //MARK: privateMethod
    private func setupUI() {
        view.backgroundColor = UDColor.rgb("#FCFCFD") & UDColor.rgb("#202020")
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview() // 为了iPad上列表内容延伸至 home indicator 下
        }

        // 注意要在添加 RefreshView 前处理好 HeaderView，避免 RefreshView 取 contentInset 不准
        if let headerSection = homeUI.headerSection {
            let headerView = headerSection.headerView
            let headerHeight = headerSection.headerViewHeight
            collectionView.addSubview(headerView)
            headerView.snp.makeConstraints { make in
                make.bottom.equalTo(collectionView.contentLayoutGuide.snp.top)
                make.left.right.equalTo(collectionView.frameLayoutGuide)
//                make.width.equalTo(collectionView.frameLayoutGuide)
                make.height.equalTo(headerHeight)
            }
            var contentInset = collectionView.contentInset
            contentInset.top += headerHeight
            collectionView.contentInset = contentInset
        }
        homeUI.setup(collectionView: collectionView)

        view.addSubview(createButton)
        createButton.snp.makeConstraints { make in
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
            make.width.height.equalTo(48)
        }
        createButton.layer.cornerRadius = 24

        view.addSubview(disabledCreateMaskView)
        disabledCreateMaskView.backgroundColor = .clear
        disabledCreateMaskView.isEnabled = false
        disabledCreateMaskView.snp.makeConstraints { make in
            make.edges.equalTo(createButton)
        }

        DocsLogger.info("using circle refresh animator")
        let headerView = collectionView.es.addPullToRefresh(animator: circleRefreshAnimator) { [weak self] in
            self?.refreshing = true
            self?.homeUI.notifyPullToRefresh()
        }
        headerView.frame.origin.y -= collectionView.contentInset.top
        collectionView.es.addInfiniteScrollingOfDoc(animator: footerAnimator) { [weak self] in
            self?.homeUI.notifyPullToLoadMore()
        }
    }
    
    private func bindUIEvents() {
        createButton.rx.tap
            .compactMap { [weak self] in
                guard let self else { return nil }
                return (FromSource.recent, .bottomRight, self.createButton)
            }
            .bind(to: homeViewModel.createIntentionTrigger)
            .disposed(by: disposeBag)
    }

    private func setupVM() {
        setupCreateDirector()
        homeViewModel.naviBarTitleDriver?.drive(onNext: { [weak self] title in
            self?.naviBarCoordinator.update(title: title)
        }).disposed(by: disposeBag)

        homeViewModel.naviBarItemsUpdated.drive(onNext: { [weak self] items in
            self?.naviBarCoordinator.update(items: items)
        }).disposed(by: disposeBag)

        homeUI.reloadSignal
            .emit(onNext: { [weak self] action in
                self?.handle(reloadAction: action)
            })
            .disposed(by: disposeBag)

        homeUI.actionSignal
            .emit(onNext: { [weak self] action in
                self?.handle(action: action)
            })
            .disposed(by: disposeBag)
        homeUI.prepare()
    }

    private func setupCreateDirector() {
        setupCreateButtonHiddenStatus()
        homeViewModel.createVisableDriver.map { !$0 }.drive(disabledCreateMaskView.rx.isHidden).disposed(by: disposeBag)
        homeViewModel.createEnableDriver.drive(createButton.rx.isEnabled).disposed(by: disposeBag)
        // 为了保证 disable 后点击创建按钮时不会穿透到列表，这里固定把 maskView 放出来，但是仅当 ViewModel 需要响应 disabledCreate 才真的发事件给 vm
        homeViewModel.createEnableDriver
            .map { !$0 }
            .drive(disabledCreateMaskView.rx.isEnabled)
            .disposed(by: disposeBag)
        if let disabledCreateTrigger = homeViewModel.disabledCreateTrigger {
            disabledCreateMaskView.rx.controlEvent(.touchUpInside)
                .map { () }
                .bind(to: disabledCreateTrigger)
                .disposed(by: disposeBag)
        }
        homeViewModel.actionSignal
            .emit(onNext: { [weak self] action in
                self?.handle(homeAction: action)
            })
            .disposed(by: disposeBag)
    }
        
    private func setUpDecorationView(){
        view.addSubview(decorationEmptyView)
        view.addSubview(decorationGradientView)
    }
    
    func updateDecorationView() {
        if let section = internalCollectionView.currentSubSection {
            let sectionState = section.listState
            let numbers = section.numberOfItems
            let identifier = section.identifier
            var isNormal = false
            if case .normal(_) = sectionState {
                isNormal = true
            }
            
            var isEmpty = false
            if case .empty = sectionState {
                isEmpty = true
            }
            
            if identifier == BitableMultiListSubSectionConfig.recentIdentifier {
                decorationEmptyView.isHidden = numbers > 2 || !isNormal
                decorationGradientView.isHidden =  currentShowStyle == .fullScreen || !decorationEmptyView.isHidden || isEmpty
                
            } else if identifier == BitableMultiListSubSectionConfig.quickAccessIdentifier {
                decorationEmptyView.isHidden = true
                decorationGradientView.isHidden = currentShowStyle == .fullScreen
                
            } else if identifier == BitableMultiListSubSectionConfig.favoritesIdentifier {
                decorationEmptyView.isHidden = true
                decorationGradientView.isHidden = currentShowStyle == .fullScreen
            }
            updateDecorationViewConstraints()
        }
    }

    func monitorSectionLoadState() {
        guard let section = internalCollectionView.currentSubSection else {
            return
        }
        let identifier = section.identifier
        var sectionType: BitableMultiListSectionType? = nil
        if identifier == BitableMultiListSubSectionConfig.recentIdentifier {
            sectionType = .recent
        } else if identifier == BitableMultiListSubSectionConfig.quickAccessIdentifier {
            sectionType = .quickAccess
        } else if identifier == BitableMultiListSubSectionConfig.favoritesIdentifier {
            sectionType = .favorites
        }
        guard let sectionType = sectionType else {
            return
        }
        let sectionState = section.listState

        switch sectionState {
        case .loading:
            delegate?.multiListController(vc: self, startRefreshSection: sectionType)
        case .normal(itemTypes: _):
            delegate?.multiListController(vc: self, endRefreshSection: sectionType, loadResult: .success)
        case .networkUnavailable:
            delegate?.multiListController(vc: self, endRefreshSection: sectionType, loadResult: .fail(reason: "networkUnavailable"))
        case .failure(description: let reason, clickHandler: _):
            delegate?.multiListController(vc: self, endRefreshSection: sectionType, loadResult: .fail(reason: reason))
        case .empty(description: _, emptyType: _, createEnable: _, createButtonTitle: _, createHandler: _):
            delegate?.multiListController(vc: self, endRefreshSection: sectionType, loadResult: .success)
        case .none:
            break
        }
    }

    private func updateDecorationViewConstraints() {
        if isInAnimation == false, decorationEmptyView.superview != nil {
            updateEmptyViewConstraints()
        }
        
        if decorationGradientView.superview != nil {
            decorationGradientView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(BitableMultiListDecorationView.Const.bottomMaskViewHeight)
            }
        }
    }
    
    private func updateEmptyViewConstraints() {
        if currentShowStyle == .fullScreen {
            decorationEmptyView.snp.remakeConstraints { make in
                make.left.right.equalToSuperview()
                make.height.equalTo(BitableMultiListDecorationView.Const.bottomCreateViewHeight)
                make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-60)
            }
        } else if currentShowStyle == .embeded {
            decorationEmptyView.snp.remakeConstraints { make in
                make.left.right.bottom.equalToSuperview()
                make.height.equalTo(BitableMultiListDecorationView.Const.bottomCreateViewHeight)
            }
        }
    }
}

//MARK: BitableMultiListControllerProtocol
extension BitableMultiListController: BitableMultiListControllerProtocol {
    
    public func collectionViewWillShowInfullScreen() {
        isInAnimation = true
        internalCollectionView.isScrollEnabled = true
        internalCollectionView.isInAnimation = true
        update(style: .fullScreen)
    }
    
    public func collectionViewDidShowInfullScreen() {
        isInAnimation = false
        internalCollectionView.isInAnimation = false
        allowRightSlidingForBack()

        for cell in internalCollectionView.visibleCells {
            guard cell is BitableMultiListCell else {
                return
            }
            cell.isUserInteractionEnabled = true
        }
    }
    
    public func collectionViewWillShowInEmbed() {
       isInAnimation = true
       internalCollectionView.isScrollEnabled = false
       internalCollectionView.isInAnimation = true
       updateStatus(isAnimating: true)
       update(style: .embeded)
    }
    
    public func collectionViewDidShowInEmbed() {
        isInAnimation = false
        internalCollectionView.isInAnimation = false

        for cell in internalCollectionView.visibleCells {
            guard cell is BitableMultiListCell else {
                return
            }
            cell.isUserInteractionEnabled = false
        }
    }
    
    public func collectionViewShouldReloadCellsForAnimation() {
        if reloadActionCanShowAnimation() {
            internalCollectionView.reloadData()
        } else {
            UIView.performWithoutAnimation {
                internalCollectionView.reloadData()
            }
        }
    }
    
    public func collectionViewPullToRefresh() {
        homeUI.notifyPullToRefresh()
    }
    
    public func update(config: BitableMultiListUIConfig) {
        collectionViewConfig = config
        internalCollectionView.layoutConfig = config
    }
    
    public func updateStatus(isAnimating: Bool) {
        if refreshing && isAnimating {
            collectionView.es.stopPullToRefresh()
        }
    }
    
    public func update(style: BitableMultiListShowStyle) {
        var isCurrentShowStyleChanged = false
        if currentShowStyle != style {
            isCurrentShowStyleChanged = true
        }
        self.currentShowStyle = style
        if isCurrentShowStyleChanged {
            trackerFileListView()
        }
        internalCollectionView.currentShowStyle = style
        updateDecorationView()
        monitorSectionLoadState()
    }
    
    func reloadActionCanShowAnimation() -> Bool {
        if let section = internalCollectionView.currentSubSection {
            let sectionState = section.listState
            if case .normal(_) = sectionState {
                return false
            } else {
                return true
            }
        }
        return true
    }
    
    public func showfullScreenAnimation() {
        updateEmptyViewConstraints()
    }
    
    public func showEmbededAnimation() {
        updateEmptyViewConstraints()
    }
    
    private func currentSectionIsNormalList() -> Bool {
        return internalCollectionView.currentSectionIsNormalList()
    }
    
    private func allowRightSlidingForBack(){
        internalCollectionView.addGestureRecognizer(swipeEmbedeGesture)
    }
    
    private func forbiddenRightSlidingForBack(){
        internalCollectionView.removeGestureRecognizer(swipeEmbedeGesture)
    }
    
    @objc
    private func swipeToTriggerEmbedStyle(recognizer: UISwipeGestureRecognizer) {
        self.delegate?.didRightSlidingTriggerEmbedStyle()
        forbiddenRightSlidingForBack()
    }
    
    private var isFullScreen: Bool {
        return currentShowStyle == .fullScreen
    }

    private var currentSectionType: BitableHomeTrackerFileListSubViewType? {
        guard let realCollectionView = multiListCollectionView as? BitableMultiListCollectionView else {
            return nil
        }
        guard let section = realCollectionView.currentSubSection else {
            return nil
        }
        let identifier = section.identifier
        if identifier == BitableMultiListSubSectionConfig.recentIdentifier {
            return .recent
        } else if identifier == BitableMultiListSubSectionConfig.quickAccessIdentifier {
            return .quick_access
        } else if identifier == BitableMultiListSubSectionConfig.favoritesIdentifier {
            return .favorites
        }
        return nil
    }
}

//MARK: 埋点
extension BitableMultiListController {
    private func addApplicationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc
    private func applicationDidBecomeActive(_ notification: Notification) {
        if view.superview == nil {
            return
        }
        if hasDisappear {
            return
        }
        trackerFileListView()
    }
    
    fileprivate func trackerFileListView() {
        guard let vm = homeViewModel as? BitableMultiListViewModel, case let .baseHomePage(context) = vm.createContext.module else {
            return
        }
        guard let type = currentSectionType else {
            return
        }
        DocsTracker.reportBitableHomePageFileListView(context: context, type: type, isFullScreen: isFullScreen)
    }
}

//MARK: 刷新
extension BitableMultiListController: RefreshViewDelegate {
    public func stateDidChange(view: ESRefreshComponent, state: ESRefreshViewState) { }
}
