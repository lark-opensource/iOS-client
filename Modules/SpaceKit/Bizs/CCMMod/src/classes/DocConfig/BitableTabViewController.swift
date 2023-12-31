//
//  BitableTabViewController.swift
//  CCMMod
//
//  Created by yinyuan on 2023/3/31.
//

import LarkUIKit
import RxRelay
import RxSwift
import EENavigator
import LarkNavigation
import LarkTab
import SnapKit
import AnimatedTabBar
import RustPB
import SKSpace
import SKInfra
import SKCommon
import UniverseDesignColor
import LarkKeyCommandKit
import SKResource
import SKFoundation
import LarkSetting
import SKBitable

#if MessengerMod
import LarkMessengerInterface
#endif

final class BaseTab: TabRepresentable {
    var tab: Tab { return .base }

    var openMode: TabOpenMode? {
        if UserScopeNoChangeFG.LYL.enableHomePageV4 {
            return .pushMode
        }
        return nil
    }

    // 业务自定义更多图标显示方式
    var quickIconStyle: TabIconStyle? { return .Tiled }
}

class BaseTabViewController: UIViewController {
    
    private let myTabName = "personal"
    private let recommendTabName = "recommend"
    
    private let bag = DisposeBag()
    private let spaceHomeViewController: SpaceHomeViewController
    private lazy var baseRecommendController: SKBitableRecommendController = {
        return SKBitableRecommendController.init()
    }()
    
    private var currentVC : UIViewController?
    private let context: BaseHomeContext
    private var magicRegister: FeelGoodRegister?
    
    private let initStartTime: TimeInterval
    
    // 记录第一次上屏，防止曝光重复上报
    private var myFirstAppear: Bool = true
    private var recommendFirstAppear: Bool = true
        
    private lazy var shouldShowRecommend: Bool = {
        return context.shouldShowRecommend
    }()
    
    private lazy var recommendTabController: UIViewController? = {
        if UserScopeNoChangeFG.WPB.homepageRecommendNativeEnable {
            return SKBitableRecommendNativeController.init(context: self.context)
        }else {
            return SKBitableRecommendController.init().viewController
        }
    }()
    
    private lazy var loadingView: DocsUDLoadingImageView = {
        let loadingView = DocsUDLoadingImageView()
        return loadingView
    }()
    
    // MARK: - 初始化&生命周期
    init(context: BaseHomeContext, spaceHomeViewController: SpaceHomeViewController) {
        self.spaceHomeViewController = spaceHomeViewController
        self.context = context
        self.initStartTime = Date().timeIntervalSince1970
        super.init(nibName: nil, bundle: nil)
        spaceHomeViewController.naviBarCoordinator.update(naviBarProvider: self)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = UDColor.bgBody
        navigationController?.isNavigationBarHidden = true
        
        if shouldShowRecommend {
            if UserScopeNoChangeFG.PXR.btHomepageXYZDiversionEnable {
                showLoadingView()
                let xyzStartTime = Date().timeIntervalSince1970
                doXYZDiversion {[weak self] firstLoadType, loadFrom in
                    guard let `self` = self else {
                        return
                    }
                    let duration = Int64((Date().timeIntervalSince1970 - xyzStartTime) * 1000)
                    let tabName = firstLoadType == .recommendVC ? self.recommendTabName : self.myTabName
                    self.trackXYZLoad(loadFrom: loadFrom, tabName: tabName, requestDuration: duration)
                    
                    self.hideLoadingView()
                    self.setupScrollPagesView(firstLoadType: firstLoadType, loadFrom: loadFrom, requestDuration: duration)
                }
            } else {
                setupDefaultSwitchView()
            }
        } else {
            setupChildVC()
        }
    }
    
    
    /// 设置默认的switch view
    func setupDefaultSwitchView() {
        // 默认逻辑
        let firstShowSpace = UserScopeNoChangeFG.PXR.btHomepageFirstShowMySpaceEnable
        if firstShowSpace {
            setupSwitchView(firstShowBaseHomeVC: true)
            mountBaseVC()
        } else {
            setupSwitchView(firstShowBaseHomeVC: false)
            mountRecommendVC()
        }
    }
    
    /// 设置是否可以横滑Pages view
    func setupScrollPagesView(firstLoadType: BitableTabSwitchView.Event, loadFrom: TabLoadFrom, requestDuration: Int64) {
        
        let viewStartTime = Date().timeIntervalSince1970
        var selectIndex: Int = 0
        switch firstLoadType {
        case .recommendVC:
            selectIndex = 0
        case .baseHomeVC:
            selectIndex = 1
        }
        
        if UserScopeNoChangeFG.WPB.homepageScrollHorizontalEnable {
            self.setupPagesView(selectIndex: selectIndex)
        }else {
            if selectIndex == 1 {
                setupSwitchView(firstShowBaseHomeVC: true)
                mountBaseVC()
            } else {
                setupSwitchView(firstShowBaseHomeVC: false)
                mountRecommendVC()
            }
        }
        
        let renderDuration = Int64((Date().timeIntervalSince1970 - viewStartTime) * 1000) 
        let tabName = firstLoadType == .recommendVC ? self.recommendTabName : self.myTabName
        self.trackBaseContainerLoad(loadFrom: loadFrom, tabName: tabName, requestDuration: requestDuration, renderDuration: renderDuration)
        if let recommendVC = self.recommendTabController as? SKBitableRecommendNativeController {
            recommendVC.tabContainerLoadDurationForLog = Int64((Date().timeIntervalSince1970 - self.initStartTime) * 1000)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if magicRegister == nil,
           let navigationController = self.navigationController {
            magicRegister = FeelGoodRegister(type: .spaceHome) { [weak navigationController] in
                return navigationController
            }
        }
    }
    
    func showLoadingView() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func hideLoadingView() {
        loadingView.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.specifiedPage(page: .home, contextViewId: viewId)
        PowerConsumptionExtendedStatistic.markStart(scene: scene)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.specifiedPage(page: .home, contextViewId: viewId)
        PowerConsumptionExtendedStatistic.markEnd(scene: scene)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        spaceHomeViewController.reloadHomeLayout()
        
        guard let nativeRecommendController = currentVC as? SKBitableRecommendNativeController else {
            return
        }
        nativeRecommendController.reloadHomeLayout()
    }
    
    private func setupPagesView(selectIndex: Int) {
        
        let tabSegment = BitableHomeSegment()
        let segmentView = BitablePageScrollView(segment: tabSegment)
        view.addSubview(segmentView)
        let tabHeight = self.tabBarController?.tabBar.bdp_height
        segmentView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(naviHeight)
            make.leading.trailing.equalToSuperview()
            if !Display.pad {
               make.bottom.equalToSuperview().offset(-(tabHeight ?? 0))
            }else{
                make.bottom.equalToSuperview()
            }
        }
        segmentView.setNeedsLayout()
        
        let recomendContainerView = BitablePageContainerView(frame: .zero, viewDidAppear: { [weak self] (currentView)in
            
            guard let `self` = self, let currentRecommendController = self.recommendTabController else {
                return
            }
            
            var firstLoad = false
            if currentRecommendController.parent == nil {
                firstLoad = true
                self.updateRecommendSelect(isSelect: true)
                self.addChild(currentRecommendController)
                currentRecommendController.didMove(toParent: self)
                currentView.addSubview(currentRecommendController.view)
                currentRecommendController.view.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                self.trackControllerAppear(tabName: self.recommendTabName)
            }
            
            if self.currentVC != currentRecommendController {
                self.currentVC = currentRecommendController
                
                if let nativeRecommendController = self.currentVC as? SKBitableRecommendNativeController {
                    nativeRecommendController.enterContainerView(isFristLoad: firstLoad)
                }
                self.trackTabClick(name: self.recommendTabName)
            }
        }, viewDisAppear: { [weak self] _ in
            if let nativeRecommendController = self?.recommendTabController as? SKBitableRecommendNativeController {
                nativeRecommendController.leaveContainerView()
            }
        })
        
        let myContainerView = BitablePageContainerView(frame: .zero, viewDidAppear: { [weak self] (currentView) in
            guard let `self` = self else {
                return
            }
            
            if self.spaceHomeViewController.parent == nil {
                self.spaceHomeViewController.enableSimultaneousGesture = true
                self.addChild(self.spaceHomeViewController)
                currentView.addSubview(self.spaceHomeViewController.view)
                self.spaceHomeViewController.didMove(toParent: self)
                self.spaceHomeViewController.view.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
                self.trackControllerAppear(tabName: self.myTabName)
            }
            
            if self.currentVC != self.spaceHomeViewController {
                self.currentVC = self.spaceHomeViewController
                self.trackTabClick(name: "my")
            }
        }, viewDisAppear: { _ in
            
        })

        let tabTitles = HomePageTabConfig.tabTitles()
        let titlesView: [(title: String, view: BitablePageContainerView)] = [
            (title: tabTitles.recomTitle, view: recomendContainerView),
            (title: tabTitles.myTitle, view: myContainerView)
        ]
        segmentView.set(views: titlesView, selectIndex: selectIndex)
    }
    
    private func updateRecommendSelect(isSelect: Bool) {
        if let nativeRecommendController = self.recommendTabController as? SKBitableRecommendNativeController {
            nativeRecommendController.isSelect = isSelect
        }
    }
    
    private func setupChildVC() {
        addChild(spaceHomeViewController)
        view.addSubview(spaceHomeViewController.view)
        spaceHomeViewController.didMove(toParent: self)
        spaceHomeViewController.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(naviHeight)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func doXYZDiversion(with result: @escaping ((BitableTabSwitchView.Event, TabLoadFrom) -> Void)) {
        XYZDiversionHelper.doXYZDiversion(with: result)
    }
    
    // MARK: - 切换推荐瀑布流&我的页面
    private func setupSwitchView(firstShowBaseHomeVC: Bool) {
        let switchView = BitableTabSwitchView.init(firstShowBaseHomeVC: firstShowBaseHomeVC, buttonAction: { [weak self] (event) in
            switch event {
            case .recommendVC:
                self?.swichToRecommendVC()
            case .baseHomeVC:
                self?.switchToBaseVC()
            @unknown default:
                break
            }
        })
        
        self.view.addSubview(switchView)
        switchView.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(naviHeight)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(tabBarSwitchHeight)
        }  
    }
    
    private func mountBaseVC() {
        currentVC = spaceHomeViewController
        addChild(spaceHomeViewController)
        spaceHomeViewController.didMove(toParent: self)
        view.addSubview(spaceHomeViewController.view)
        spaceHomeViewController.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(topOffset)
            make.leading.trailing.bottom.equalToSuperview()
        }
        if myFirstAppear {
            myFirstAppear = false
            self.trackControllerAppear(tabName: self.myTabName)
        }
    }
    
    private func mountRecommendVC() {
        if let recommendViewController = recommendTabController {
            updateRecommendSelect(isSelect: true)
            currentVC = recommendViewController
            addChild(recommendViewController)
            recommendViewController.didMove(toParent: self)
            view.addSubview(recommendViewController.view)
            
            let tabHeight = self.tabBarController?.tabBar.bdp_height
            recommendViewController.view.snp.makeConstraints { (make) in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(topOffset)
                make.left.right.equalToSuperview()
                if !Display.pad {
                   make.bottom.equalToSuperview().offset(-(tabHeight ?? 0))
                }else{
                    make.bottom.equalToSuperview()
                }
            }
            
            if recommendFirstAppear {
                recommendFirstAppear = false
                self.trackControllerAppear(tabName: self.recommendTabName)
            }
        }
    }
    
    private func unmountBaseVC() {
        spaceHomeViewController.willMove(toParent: nil)
        spaceHomeViewController.view.removeFromSuperview()
        spaceHomeViewController.removeFromParent()
    }
    
    private func unmountRecommendVC() {
        guard let recommendVC = recommendTabController else {
            return
        }
        updateRecommendSelect(isSelect: false)
        recommendVC.willMove(toParent: nil)
        recommendVC.view.removeFromSuperview()
        recommendVC.removeFromParent()
    }
    
    private func switchToBaseVC() {
        guard let recommendVC = recommendTabController else {
            return
        }
        let shouldSwitch = currentVC != spaceHomeViewController
        if shouldSwitch {
            mountBaseVC()
            self.transition(from: recommendVC, to: spaceHomeViewController, duration: 0.5) { [weak self] in
                self?.unmountRecommendVC()
            }
        }
        let bizParams = SpaceBizParameter(module: .baseHomePage(context: context))
        var dic: [String: Any] = bizParams.params
        dic.merge(other: ["click": "my","target":"none","container_env":"larktab_bitable"])
        DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageLandingClick, parameters: dic)
    }
    
    private func swichToRecommendVC() {
        guard let recommendVC = recommendTabController else {
            return
        }
        let shouldSwitch = (currentVC == spaceHomeViewController)
        if shouldSwitch {
            mountRecommendVC()
            self.transition(from: spaceHomeViewController, to: recommendVC, duration: 0.5) { [weak self] in
                self?.unmountBaseVC()
            }
            
            let bizParams = SpaceBizParameter(module: .baseHomePage(context: context))
            var dic: [String: Any] = bizParams.params
            dic.merge(other: ["click": "recommend","target":"none","container_env":"larktab_bitable"])
            DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageLandingClick, parameters: dic)
        }
    }
    
    // MARK: - 交互事件
    override func keyBindings() -> [KeyBindingWraper] {
        super.keyBindings() + [
            KeyCommandBaseInfo(input: "k",
                               modifierFlags: .command,
                               discoverabilityTitle: SKResource.BundleI18n.SKResource.Doc_Facade_Search)
                .binding { [weak self] in
                    self?.navigateToSearch()
                }
                .wraper
        ]
    }

    private func navigateToSearch() {
        #if MessengerMod
        let searchBody = SearchMainBody(topPriorityScene: .rustScene(.searchDoc), sourceOfSearch: .docs)
        Navigator.shared.push(body: searchBody, from: self)
        #endif
    }
}

// MARK: - TabRootViewController
extension BaseTabViewController: TabRootViewController {
    var tab: Tab { .base }
    var controller: UIViewController { self }
}

// MARK: - LarkNaviBarProtocol
extension BaseTabViewController: LarkNaviBarProtocol {
    var titleText: BehaviorRelay<String> { .init(value: SKResource.BundleI18n.SKResource.Bitable_Workspace_Base_Title) }
    var isNaviBarEnabled: Bool { true }
    var isDrawerEnabled: Bool { true }

    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .search:
            let bizParams = SpaceBizParameter(module: .baseHomePage(context: context))
            var dic: [String: Any] = bizParams.params
            dic.merge(other: ["click": "search"])
            DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageLandingClick, parameters: dic)
            navigateToSearch()
        case .first:
            break
        case .second:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - LarkNaviBarAbility
extension BaseTabViewController: LarkNaviBarAbility {}

// MARK: - CustomNaviAnimation
extension BaseTabViewController: CustomNaviAnimation {
    // transform push transition to MainTabBarController
    public var animationProxy: CustomNaviAnimation? {
        return self.animatedTabBarController as? CustomNaviAnimation
    }
}

// MARK: - SpaceNaviBarProvider
extension BaseTabViewController: SpaceNaviBarProvider {
    // 暂时不需要提供 naviBar
    var skNaviBar: SpaceNaviBarCompatible? { nil }
}

extension BaseTabViewController: TabbarItemTapProtocol {
    public func onTabbarItemTap(_ isSameTab: Bool) {
        NotificationCenter.default.post(name: .BaseTabItemTapped,
                                        object: nil,
                                        userInfo: [SpaceTabItemTappedNotificationKey.isSameTab: isSameTab])
    }

    public func onTabbarItemDoubleTap() {
        spaceHomeViewController.forceScrollToTop()
        // native recommend support scroll to top when double tap tab.
        guard let nativeRecommendController = currentVC as? SKBitableRecommendNativeController else {
            return
        }
        nativeRecommendController.forceScrollToTop()
    }
}
extension BaseTabViewController: DocsCreateViewControllerRouter { }

extension BaseTabViewController {
    public var tabBarSwitchHeight : CGFloat {
        return 40
    }
    public var topOffset : CGFloat {
        return self.shouldShowRecommend ? naviHeight + tabBarSwitchHeight : naviHeight
    }
}

extension BaseTabViewController {
    static public func shouldShowRecommend() -> Bool{
        return SKBitableRecommendController.shouldShowRecommend()
    }
}

extension BaseTabViewController {
    
    func trackControllerAppear(tabName: String) {
        let dic: [String: Any] = self.pageCommonParams(tabName: tabName)
        DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageNewAppear, parameters: dic)
    }
    
    func trackTabClick(name: String) {
        let bizParams = SpaceBizParameter(module: .baseHomePage(context: self.context))
        var dic: [String: Any] = bizParams.params
        dic.merge(other: ["click": name,"target":"none","container_env":"larktab_bitable"])
        DocsTracker.newLog(enumEvent: DocsTracker.EventType.baseHomepageLandingClick, parameters: dic)
    }
    
    
    func pageCommonParams(tabName: String) -> [String: Any] {
        let bizParams = SpaceBizParameter(module: .baseHomePage(context: self.context))
        var dic: [String: Any] = bizParams.params
        dic.merge(other: ["tab_name": tabName])
        return dic
    }
    
    func trackXYZLoad(loadFrom: TabLoadFrom, tabName: String, requestDuration: Int64) {
        let loadFromStr: String = loadFrom.rawValue
        let isRecommendH5 = !UserScopeNoChangeFG.WPB.homepageRecommendNativeEnable
        var dic: [String: Any] = pageCommonParams(tabName: tabName)
        dic.merge(other: ["request_duration": requestDuration, "load_from": loadFromStr, "recommend_h5": isRecommendH5])
        DocsTracker.newLog(event: "ccm_base_homepage_xyz_load_view", parameters: dic)
    }
    
    func trackBaseContainerLoad(loadFrom: TabLoadFrom, tabName: String, requestDuration: Int64, renderDuration: Int64) {
        let duration = Int64((Date().timeIntervalSince1970 - self.initStartTime) * 1000)
        let loadFromStr: String = loadFrom.rawValue
        var dic: [String: Any] = pageCommonParams(tabName: tabName)
        dic.merge(other: ["duration": duration, "request_duration": requestDuration, "render_duration": renderDuration, "load_from": loadFromStr])
        DocsTracker.newLog(event: "ccm_base_homepage_load_view", parameters: dic)
    }
}
