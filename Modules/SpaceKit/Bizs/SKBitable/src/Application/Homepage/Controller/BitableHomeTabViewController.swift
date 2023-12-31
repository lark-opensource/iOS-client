//
//  BitableHomeTabViewController.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/10/27.
//

import Foundation
import SKCommon
import SKUIKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignToast
import UniverseDesignDialog
import SKFoundation
import LarkUIKit
import SKResource
import LarkDocsIcon
import SKInfra
import SpaceInterface
import UniverseDesignTheme

enum BitableHomeScene: String {
    case homepage
    case recommend
    case new
}

protocol BitableHomePageTabBarDelegate: AnyObject {
    func showBottomTabBar(animated: Bool)
    func hideBottomTabBar(animated: Bool)
}

final public class BitableHomeTabViewController: UIViewController {
    static let bottomTabBarHeight = 64.0

    public override var prefersStatusBarHidden: Bool {
        return false
    }
    
    private lazy var contentView: UIView = {
        return UIView()
    }()

    private lazy var bottomTabBar: BitableHomeBottomTabBar = {
        let bar = BitableHomeBottomTabBar()
        bar.delegate = self
        return bar
    }()

    private lazy var loadingView: BitableHomeLoadingView = {
        let loadingView = BitableHomeLoadingView()
        loadingView.isHidden = true
        return loadingView
    }()

    private lazy var bottomContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.bgBody
        return view
    }()

    private lazy var homePageViewController: UIViewController = {
        let factory = try? context.userResolver.resolve(assert: BitableVCFactoryProtocol.self)
        guard let multiListVC = factory?.makeBitableMultiListController(context: context)  else {
               DocsLogger.error("can not get MultiList")
               return BaseViewController()
        }
        return BitableHomePageViewController(multiListViewController:multiListVC, context: context)
    }()

    private lazy var recommendTabController: UIViewController = {
        return BitableRecommendNativeWrapperController(context: self.context)
    }()

    private var currentVC : UIViewController?
    let context: BaseHomeContext

    private let initStartTime: TimeInterval

    // MARK: - 初始化&生命周期

    init(context: BaseHomeContext) {
        self.context = context
        self.initStartTime = Date().timeIntervalSince1970
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        fetchXYZDiversion()
        
        if let VC = homePageViewController as? BitableHomePageViewController {
            VC.tabBarDelegate = self
            VC.delegate = self
        }
        setupDarkModeObserver()
    }

    private func setupDarkModeObserver() {
        if UserScopeNoChangeFG.LYL.disablePopHomeWhenDarkModeChanged {
            return
        }
        navigationController?.view.registerTraitCollectionChanges(
            forKey: "BitableHomeTabViewController",
            handler: { [weak self] _ in
                self?.checkPopWhenTraitCollectionDidChange()
        })
    }

    private func checkPopWhenTraitCollectionDidChange() {
        guard #available(iOS 13.0, *) else {
            return
        }
        guard UDThemeManager.getSettingUserInterfaceStyle() == .unspecified else {
            return
        }
        guard UIApplication.shared.applicationState != .background else {
            return
        }
        DocsLogger.info("[BitableHomeTabViewController] userInterfaceStyle changed close page")
        // Base 首页部分颜色没有使用 UD Token, 暗黑模式切换会导致颜色不对，所有这里直接 pop
        navigationController?.popToViewController(self, animated: false)
        navigationController?.popViewController(animated: false)
    }

    private func setupUI() {
        view.backgroundColor = UDColor.bgBody
        navigationController?.isNavigationBarHidden = true

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        setupBottomTabBar()

        setupLoading()
    }

    private func setupLoading() {
        view.addSubview(loadingView)
        loadingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupBottomTabBar() {
        view.addSubview(bottomContentView)
        bottomContentView.addSubview(bottomTabBar)
        bottomContentView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        bottomTabBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.height.equalTo(Self.bottomTabBarHeight)
        }
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.specifiedPage(page: .home, contextViewId: viewId)
        PowerConsumptionExtendedStatistic.markStart(scene: scene)
    }

    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        let viewId = "\(ObjectIdentifier(self))"
        let scene = PowerConsumptionStatisticScene.specifiedPage(page: .home, contextViewId: viewId)
        PowerConsumptionExtendedStatistic.markEnd(scene: scene)

        BTOpenHomeReportMonitor.reportCancel(context: context, type: .user_back)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let nativeRecommendController = currentVC as? BitableRecommendNativeWrapperController {
            nativeRecommendController.recommendController.reloadHomeLayout()
        }
    }

    // MARK: - 切换推荐瀑布流&我的页面
    private func mountBaseVC(isUserClick: Bool) {
        currentVC = homePageViewController
        addChild(homePageViewController)
        homePageViewController.didMove(toParent: self)
        contentView.addSubview(homePageViewController.view)
        homePageViewController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        bottomTabBar.update(selectScene: .homepage, animated: isUserClick)
    }

    private func mountRecommendVC(isUserClick: Bool) {
        updateRecommendSelect(isSelect: true)
        currentVC = recommendTabController
        addChild(recommendTabController)
        recommendTabController.didMove(toParent: self)
        contentView.addSubview(recommendTabController.view)

        recommendTabController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        bottomTabBar.update(selectScene: .recommend, animated: isUserClick)
    }

    private func unmountBaseVC() {
        homePageViewController.willMove(toParent: nil)
        homePageViewController.view.removeFromSuperview()
        homePageViewController.removeFromParent()
    }

    private func unmountRecommendVC() {
        updateRecommendSelect(isSelect: false)
        recommendTabController.willMove(toParent: nil)
        recommendTabController.view.removeFromSuperview()
        recommendTabController.removeFromParent()
    }

    private func updateRecommendSelect(isSelect: Bool) {
        if let nativeRecommendController = self.recommendTabController as? BitableRecommendNativeWrapperController {
            nativeRecommendController.recommendController.isSelect = isSelect
        }
    }

    private func switchToBaseVC() {
        let shouldSwitch = currentVC != homePageViewController
        if shouldSwitch {
            mountBaseVC(isUserClick: true)
            self.transition(from: recommendTabController, to: homePageViewController, duration: 0.5) { [weak self] in
                self?.unmountRecommendVC()
            }
        }
        DocsTracker.reportBitableHomePageClick(context: context, click: .personal)
    }

    private func swichToRecommendVC() {
        let shouldSwitch = (currentVC == homePageViewController)
        if shouldSwitch {
            mountRecommendVC(isUserClick: true)
            self.transition(from: homePageViewController, to: recommendTabController, duration: 0.5) { [weak self] in
                self?.unmountBaseVC()
            }

            DocsTracker.reportBitableHomePageClick(context: context, click: .recommend)
        }
    }

    private func createBitable(source: BitableHomeCreateBaseSource) {
        DocsLogger.btInfo("[Action] crate new bitable file")
        let module = PageModule.baseHomePage(context: context)
        let intent = SpaceCreateIntent(context: SpaceCreateContext.bitableHome(module), source: .recent, createButtonLocation: .bottomRight)
        let ccmOpenSource = intent.context.module.generateCCMOpenCreateSource()
        let trackParameters = DocsCreateDirectorV2.TrackParameters(source: intent.source,
                                                                   module: intent.context.module,
                                                                   ccmOpenSource: ccmOpenSource)
        let createPanelHelper = SpaceCreatePanelHelper(trackParameters: trackParameters,
                                            mountLocation: intent.context.mountLocation,
                                            createDelegate: self,
                                            createRouter: self,
                                            createButtonLocation: intent.createButtonLocation)

        let _ = createPanelHelper.createBitableAddButtonHandler(sourceView: bottomTabBar)

        DocsTracker.reportBitableHomePageClick(context: context, click: source.trackerClickType())
        BTOpenHomeReportMonitor.reportCancel(context: context, type: .new_file)
    }
}

extension BitableHomeTabViewController: DocsCreateViewControllerDelegate {
    
    public func createComplete(token: String?, type: LarkDocsIcon.CCMDocsType, error: Error?) {
        if let docsError = error as? DocsNetworkError {
            let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self)!
            let context = PermissionCommonErrorContext(objToken: token ?? "", objType: type, operation: .createSubNode)
            if let behavior = permissionSDK.canHandle(error: docsError, context: context) {
                behavior(self, BundleI18n.SKResource.Doc_Facade_CreateFailed)
                return
            }
            if docsError.code == .createLimited {
                DispatchQueue.main.asyncAfter(deadline: .now() + DispatchQueueConst.MilliSeconds_1000, execute: { [weak self] in
                    // 租户达到创建的上线，弹出付费提示
                    let dialog = UDDialog()
                    dialog.setTitle(text: BundleI18n.SKResource.Doc_List_CreateDocumentExceedLimit)
                    dialog.setContent(text: docsError.errorMsg)
                    dialog.addSecondaryButton(text: BundleI18n.SKResource.Doc_Facade_Cancel)
                    dialog.addDestructiveButton(text: BundleI18n.SKResource.Doc_Facade_NotifyAdminUpgrade)
                    self?.present(dialog, animated: true, completion: nil)
                })
            } else {
                UDToast.showFailure(with: docsError.errorMsg, on: view.window ?? view)
            }
            return
        }
        if error != nil {
            UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed, on: view.window ?? view)
        }
    }
    
    public func createCancelled() {}
}

extension BitableHomeTabViewController: DocsCreateViewControllerRouter {
    
    // 因为在模版创建时，会把routerImpl上面的所有VC pop，所以返回self
    public var routerImpl: UIViewController? {
        return self
    }
    
    // 其他协议函数，直接使用默认实现
}

extension BitableHomeTabViewController: BitableHomeBottomTabBarDelegate {
    func tabBar(_ tabbar: BitableHomeBottomTabBar, didSelect scene: BitableHomeScene) {
        switch scene {
        case .homepage:
            switchToBaseVC()
        case .recommend:
            swichToRecommendVC()
        case .new:
            createBitable(source: .create_base)
        }
        BTOpenHomeReportMonitor.reportCancel(context: context, type: .switch_tab)
    }
}

// XYZ
extension BitableHomeTabViewController {
    private func fetchXYZDiversion() {
        BTOpenHomeReportMonitor.reportXYZStart(context: context)

        showLoadingView()
        let xyzStartTime = Date().timeIntervalSince1970
        XYZDiversionHelper.doXYZDiversion {[weak self] firstLoadType, loadFrom in
            guard let `self` = self else {
                return
            }
            let duration = Int64((Date().timeIntervalSince1970 - xyzStartTime) * 1000)
            let tabName = firstLoadType == .recommendVC ? BitableHomeScene.recommend : BitableHomeScene.homepage
            self.trackXYZLoad(loadFrom: loadFrom, tabName: tabName.rawValue, requestDuration: duration)

            self.hideLoadingView()

            BTOpenHomeReportMonitor.reportXYZEnd(
                context: context,
                from: loadFrom,
                scene: firstLoadType == .baseHomeVC ? .homepage : .recommend
            )

            self.setupXYZDiversion(firstLoadType: firstLoadType, loadFrom: loadFrom, requestDuration: duration)
        }
    }

    private func setupXYZDiversion(firstLoadType: BitableTabSwitchView.Event, loadFrom: TabLoadFrom, requestDuration: Int64) {
        let viewStartTime = Date().timeIntervalSince1970

        switch firstLoadType {
        case .recommendVC:
            mountRecommendVC(isUserClick: false)
        case .baseHomeVC:
            mountBaseVC(isUserClick: false)
        }

        let renderDuration = Int64((Date().timeIntervalSince1970 - viewStartTime) * 1000)
        let tabName = firstLoadType == .recommendVC ? BitableHomeScene.recommend : BitableHomeScene.homepage
        self.trackBaseContainerLoad(loadFrom: loadFrom, tabName: tabName.rawValue, requestDuration: requestDuration, renderDuration: renderDuration)
    }

    private func showLoadingView() {
        loadingView.isHidden = false
        loadingView.startAnimation()
    }

    private func hideLoadingView() {
        loadingView.isHidden = true
        loadingView.stopAnimation()
    }
}

extension BitableHomeTabViewController: BitableHomePageTabBarDelegate {
    
    func showBottomTabBar(animated: Bool = true) {
        if !bottomContentView.isHidden {
            DocsLogger.btError("Error: BottomTabBar has been showed")
            return
        }
        self.bottomContentView.isHidden = false
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                self.bottomContentView.transform = self.bottomContentView.transform.translatedBy(x: 0, y: -CGFloat(CGFloat(BitableHomeTabViewController.bottomTabBarHeight) + self.view.safeAreaInsets.bottom))
            }
        } else {
            self.bottomContentView.transform = self.bottomContentView.transform.translatedBy(x: 0, y: -CGFloat(CGFloat(BitableHomeTabViewController.bottomTabBarHeight) + self.view.safeAreaInsets.bottom))
        }
    }
    
    func hideBottomTabBar(animated: Bool = true) {
        if bottomContentView.isHidden {
            DocsLogger.btError("Error: BottomTabBar has been hidden")
            return
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut) {
                self.bottomContentView.transform = self.bottomContentView.transform.translatedBy(x: 0, y: CGFloat(CGFloat(BitableHomeTabViewController.bottomTabBarHeight) + self.view.safeAreaInsets.bottom))
            } completion: { [weak self] (_) in
                guard let self = self else { return }
                self.bottomContentView.isHidden = true
            }
        } else {
            self.bottomContentView.isHidden = true
            self.bottomContentView.transform = self.bottomContentView.transform.translatedBy(x: 0, y: CGFloat(CGFloat(BitableHomeTabViewController.bottomTabBarHeight) + self.view.safeAreaInsets.bottom))
        }
    }
}

extension BitableHomeTabViewController: BitableHomePageViewControllerDelegate {
    func createBitableFileIfNeeded(isEmpty: Bool) {
        if isEmpty {
            createBitable(source: .create_base_lead)
        } else {
            createBitable(source: .new_base_popup)
        }
    }
    
    func allowRightSlidingForBack(){
        naviPopGestureRecognizerEnabled = true
    }
    
    func forbiddenRightSlidingForBack(){
        naviPopGestureRecognizerEnabled = false
    }
}

extension BitableHomeTabViewController {
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
