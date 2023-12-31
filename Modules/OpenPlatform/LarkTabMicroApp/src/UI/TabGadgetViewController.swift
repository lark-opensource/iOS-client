//
//  TabGadgetViewController.swift
//  LarkTabMicroApp
//
//  Created by yinyuan on 2020/12/28.
//

import Foundation
import LarkOPInterface
import LarkUIKit
import Swinject
import RxRelay
import EEMicroAppSDK
import SnapKit
import LKCommonsLogging
import LarkNavigation
import AnimatedTabBar
import LarkTab
import OPGadget
import OPSDK
import UniverseDesignEmpty
import LarkContainer
import OPFoundation

let tabGadgetInstanceID = "tab_gadget"
var tabGadgetInstanceIndex = 1

/// 新容器实现的 Tab 小程序
class TabGadgetViewController: BaseUIViewController, LarkNaviBarAbility, TabRootViewController,
                               LarkNaviBarDataSource, LarkNaviBarDelegate, TabbarItemTapProtocol,
                               OPRenderSlotDelegate, OPContainerLifeCycleDelegate, OPRenderSlotFailedViewUIDelegate {

    private static let logger = Logger.log(TabGadgetViewController.self)

    private let resolver: UserResolver
    private let gadegtTab: Tab
    private let tabExta: GadgetTabExtra
    private weak var container: OPContainerProtocol?
    private let tabContainerVC: UIViewController

    /// FG_TODO：openplatform.recovery.tab_gadget_failed_view
    /// FG全量时，需要删掉下方属性failedView的代码，并将属性newFailedView更改为failedView
    // 失败占位图
    lazy var failedView: LoadFaildRetryView = {
        let view = LoadFaildRetryView()
        view.retryAction = { [weak self] in
            self?.container?.reload(monitorCode: GDMonitorCode.about_restart)
        }
        return view
    }()

    var newFailedView: UDEmpty?

    // loading占位图
    lazy var loadingView: LoadingPlaceholderView = {
        let loadingView = LoadingPlaceholderView()
        return loadingView
    }()

    private lazy var scene: OPAppScene = {
        if let navigationService = resolver.resolve(NavigationService.self) {
            return navigationService.checkInMainTabs(for: self.gadegtTab) ? .mainTab : .convenientTab
        }
        return .mainTab
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        isNavigationBarHidden = true

        setupChildViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
        //  当iPad小程序被配置到导航栏第一个Tab的时候，因为时机很早，UIApplication.shared.statusBarFrame.height是0，所以在update下布局
        tabContainerVC.view.snp.updateConstraints { make in
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height + naviHeight)
            }
    }

    init(resolver: UserResolver, tab: Tab) {
        self.resolver = resolver
        self.gadegtTab = tab
        self.tabExta = GadgetTabExtra(dict: tab.extra)
        self.tabContainerVC = UIViewController()

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupChildViewController() {
        guard let appID = tabExta.appID else {
            // TODO: 日志
            return
        }

        // 这个属性需要配置，不然底部会空出一条(可能与Lark的定制Tab有关)
        extendedLayoutIncludesOpaqueBars = true


        self.addChild(tabContainerVC)
        self.view.insertSubview(tabContainerVC.view, at: 0)

        tabContainerVC.view.snp.makeConstraints { (make) in
            // Lark 的导航栏不规范，需要通过这种方法来实现从导航栏底部开始布局
            make.top.equalToSuperview().offset(UIApplication.shared.statusBarFrame.height + naviHeight)
            make.left.right.equalToSuperview()
            // 主导航tabBar开启半透明，可显示区域更正
            if let tabbarheight = self.animatedTabBarController?.tabbarHeight,
               let currentTabbar = self.animatedTabBarController?.tabBar,
               currentTabbar.isTranslucent {
                make.bottom.equalToSuperview().offset(-tabbarheight)
            } else {
                make.bottom.equalToSuperview()
            }
        }
        tabContainerVC.didMove(toParent: self)

        var uniqueID: OPAppUniqueID
        // 创建容器
        if OPSDKFeatureGating.enableTabGadgetUpdate() {
            uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget, instanceID: tabGadgetInstanceID+String(tabGadgetInstanceIndex))
            // 全局自增，保持每次创建的uniqueID不一样
            tabGadgetInstanceIndex += 1
        } else {
            uniqueID = OPAppUniqueID(appID: appID, identifier: nil, versionType: .current, appType: .gadget, instanceID: tabGadgetInstanceID)
        }

        let application = OPApplicationService.current.getApplication(appID: uniqueID.appID) ?? OPApplicationService.current.createApplication(appID: uniqueID.appID)

        let container = application.createContainer(
            uniqueID: uniqueID,
            containerConfig: OPGadgetContainerConfig(previewToken: nil, enableAutoDestroy: false))

        // 这个属性需要配置，不然底部会空出一条(可能与Lark的定制Tab有关)
        container.containerContext.apprearenceConfig.forceExtendedLayoutIncludesOpaqueBars = true
        // Tab 小程序禁用运行时更新能力
        container.containerContext.apprearenceConfig.forbidUpdateWhenRunning = !OPSDKFeatureGating.enableTabGadgetUpdate()

        let renderSlot = OPChildControllerRenderSlot(
            parentViewController: tabContainerVC,
            defaultHidden: false)
        renderSlot.delegate = self
        renderSlot.failedViewUIDelegate = self

        container.addLifeCycleDelegate(delegate: self)

        container.mount(
            data: OPGadgetContainerMountData(scene: scene, startPage: nil,relaunchWhileLaunching: false),
            renderSlot: renderSlot
        )

        self.container = container
    }

    func showLoadingView() {
        if loadingView.superview == nil {
            view.addSubview(loadingView)
            let topHeight = naviHeight + UIApplication.shared.statusBarFrame.height
            loadingView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalToSuperview().offset(topHeight)
            }
        }
        loadingView.isHidden = false
    }

    /// FG_TODO：openplatform.recovery.tab_gadget_failed_view
    /// FG全量时，需要删掉下方hideLoadingView与showFailedView方法的代码
    func hideLoadingView() {
        loadingView.isHidden = true
    }

    func showFailedView() {
        if failedView.superview == nil {
            view.addSubview(failedView)
            let topHeight = naviHeight + UIApplication.shared.statusBarFrame.height
            failedView.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalToSuperview().offset(topHeight)
            }
        }
        failedView.isHidden = false
    }

    func hideFailedView() {
        failedView.isHidden = true
    }

    /// FG_TODO：openplatform.recovery.tab_gadget_failed_view
    /// FG全量时，需要将showNewFailedView与hideNewFailedView两个方法名更改为showFailedView与hideFailedView
    /// 并将该文件中其它地方用到的所有showNewFailedView与hideNewFailedView调用，改为howFailedView与hideFailedView调用
    func showNewFailedView(tipInfo: String, uniqueID: OPAppUniqueID) {
        // 先把旧的错误提示界面给删掉
        hideNewFailedView()
        // 创建新的错误提示界面
        newFailedView = createEmptyView(tipInfo: tipInfo, retryBlock: { [weak self] _ in
            guard let self = self else { return }

            let container = OPApplicationService.current.getContainer(uniuqeID: uniqueID)
            container?.reload(monitorCode: GDMonitorCode.about_restart)
            self.hideNewFailedView()
        })
        // 隐藏无用的界面
        hideLoadingView()
    }

    func hideNewFailedView() {
        newFailedView?.removeFromSuperview()
        newFailedView = nil
    }

    func createEmptyView(tipInfo: String, retryBlock: @escaping (UIButton) -> Void) -> UDEmpty {
        let config = UDEmptyConfig(
            title: nil,
            description: .init(descriptionText: tipInfo, font: .systemFont(ofSize: 15), textAlignment: .left),
            type: .loadingFailure,
            primaryButtonConfig: (BDPI18n.retry, retryBlock)
        )
        let emptyView = UDEmpty(config: config)
        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.leading.equalToSuperview().offset(15)
            maker.trailing.equalToSuperview().offset(-15)
        }

        return emptyView
    }

    // MARK: - OPRenderSlotFailedViewUIDelegate {
    func showFailedView(with tipInfo: String, context: OPContainerContext) {
        showNewFailedView(tipInfo: tipInfo, uniqueID: context.uniqueID)
    }
    // MARK: - TabRootViewController
    var tab: Tab {
        return self.gadegtTab
    }

    var controller: UIViewController {
        self
    }
    public var deamon: Bool{
        true
    }
    
    // MARK: - LarkNaviBarDataSource
    var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: tabExta.name)
    }

    var isNaviBarEnabled: Bool {
        return true
    }

    var isDefaultSearchButtonDisabled: Bool {
        return true
    }

    var isDrawerEnabled: Bool {
        guard let enableDrawer = resolver.resolve(NavigationService.self)?.customNaviEnable else {
            TabGadgetViewController.logger.error("工作台：没有拿到主导航fg，所以没显示侧边栏")
            return false
        }
        return enableDrawer
    }

    func larkNaviBar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? {
        return nil
    }
    // MARK: - LarkNaviBarDelegate
    // 点击头像
    func onDefaultAvatarTapped() {
    }

    // 点击Title
    func onTitleViewTapped() {
    }

    // 点击右侧Button
    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
    }
    // MARK: - TabbarItemTapProtocol
    // MARK: - OPRenderSlotDelegate
    public func onRenderAttatched(renderSlot: OPRenderSlotProtocol) {

    }

    public func onRenderRemoved(renderSlot: OPRenderSlotProtocol) {

    }

    public func currentViewControllerForPresent() -> UIViewController? {
        return self
    }

    public func currentNavigationControllerForPush() -> UINavigationController? {
        return self.navigationController
    }
    // MARK: - OPContainerLifeCycleDelegate

    /// FG_TODO：openplatform.recovery.tab_gadget_failed_view
    /// FG全量时，修改以下代码，只保留最新的逻辑，删除旧逻辑
    public func containerDidLoad(container: OPContainerProtocol) {
        showLoadingView()
        hideNewFailedView()
        TabGadgetViewController.logger.info("LifeCycle:containerDidLoad")
    }

    public func containerDidReady(container: OPContainerProtocol) {
        hideLoadingView()
        hideNewFailedView()
        TabGadgetViewController.logger.info("LifeCycle:containerDidReady")
    }

    public func containerDidFail(container: OPContainerProtocol, error: OPError) {
        hideLoadingView()
        TabGadgetViewController.logger.info("LifeCycle:containerDidFail \(error)")
    }

    public func containerDidUnload(container: OPContainerProtocol) {
        TabGadgetViewController.logger.info("LifeCycle:containerDidUnload")
    }

    public func containerDidDestroy(container: OPContainerProtocol) {
        TabGadgetViewController.logger.info("LifeCycle:containerDidDestroy")
    }

    public func containerDidShow(container: OPContainerProtocol) {
        TabGadgetViewController.logger.info("LifeCycle:containerDidShow")
    }

    public func containerDidHide(container: OPContainerProtocol) {
        TabGadgetViewController.logger.info("LifeCycle:containerDidHide")
    }

    public func containerDidPause(container: OPContainerProtocol) {
        TabGadgetViewController.logger.info("LifeCycle:containerDidPause")
    }

    public func containerDidResume(container: OPContainerProtocol) {
        TabGadgetViewController.logger.info("LifeCycle:containerDidResume")
    }
    public func containerConfigDidLoad(container: OPContainerProtocol, config: OPProjectConfig) {
        TabGadgetViewController.logger.info("LifeCycle:containerConfigDidLoad")
    }

}
