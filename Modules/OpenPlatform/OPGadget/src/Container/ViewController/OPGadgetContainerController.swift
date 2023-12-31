//
//  OPGadgetContainerController.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/25.
//

import Foundation
import TTMicroApp
import SnapKit
import OPFoundation
import EENavigator
import LarkFeatureGating
import LKCommonsLogging
import LarkContainer
import LarkNavigator
import LarkUIKit
import LarkSetting
import LarkTab
import RxRelay

protocol OPGadgetContainerControllerDelegate: AnyObject {
    
    func containerControllerDidAppear(viewController: UIViewController)
    
    func containerControllerDidDisappear(viewController: UIViewController)
}

class OPGadgetContainerController: BDPAppContainerController {
    private static let logger = Logger.log(OPGadgetContainerController.self, category: "GadgetContainer")

    weak var delegate: OPGadgetContainerControllerDelegate?
    
    var appeared: Bool = false

    var sourceStartPage: BDPAppPageURL? // 原始的startPage，未经过fixStartPageIfNeed（用于修复热启fixStartPageIfNeed两次的问题）
    var userResolver = Container.shared.getCurrentUserResolver()

    public lazy var XScreenTransitionDelegate: OPXScreenTransition = {
      return OPXScreenTransition()
    }()

    private lazy var loadingVC: OPGadgetLoadingViewController = {
      return OPGadgetLoadingViewController.init(uniqueID: self.uniqueID)
    }()

    /// 红点数据源
    private var _badge = BehaviorRelay<LarkTab.BadgeType>(value: .none)
    /// 红点是否可见数据源，可见
    private var _badgeOutsideVisable = BehaviorRelay<Bool>(value: true)
    /// 红点样式数据源，红色badge类型
    private var _badgeStyle = BehaviorRelay<BadgeRemindStyle>(value: .strong)
    /// 红点数据版本
    private var _badgeVersion = BehaviorRelay<String?>(value: nil)
    // badge data source
    public var badge: BehaviorRelay<LarkTab.BadgeType>? {
        return self._badge
    }
    public var badgeStyle: BehaviorRelay<BadgeRemindStyle>? {
        return _badgeStyle
    }
    public var badgeOutsideVisiable: BehaviorRelay<Bool>? {
        return _badgeOutsideVisable
    }
    public var badgeVersion: BehaviorRelay<String?>? {
        return _badgeVersion
    }

    private var badgeObsever: OPBadge.BadgePushObserver?

    private var badgeService: OPBadge.OPBadgeService?

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            try observeBadge()
        } catch {
            Self.logger.error("[OPBadge] observeBadge throws error, cannot get dependencies", error: error)
        }
        if containerContext?.apprearenceConfig.showDefaultLoadingView == true {
            // 隐藏 Loading View 不展示
            self.view.addSubview(loadingVC.view)
            loadingVC.didMove(toParent: self)
        }
        
        // 当前页面支持 detail 全屏
        self.supportSecondaryOnly = true
        // 当前页面支持 全屏手势
        self.supportSecondaryPanGesture = true
        self.fullScreenSceneBlock = {
            return "gadget"
        }
        
        OPObjectMonitorCenter.setupMemoryMonitor(with: self)
        OPObjectMonitorCenter.updateState(.expectedRetain, for: self)
    }
    
    deinit {
        OPObjectMonitorCenter.updateState(OPMonitoredObjectState.expectedDestroy, for: self.appController)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        appeared = true
        delegate?.containerControllerDidAppear(viewController: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        appeared = false
        delegate?.containerControllerDidDisappear(viewController: self)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard OPGadgetRotationHelper.enableGadgdetRotation(self.uniqueID) else {
            return
        }

        let isLandScape = size.width > size.height
        let navi = self.navigationController
        coordinator.animate(alongsideTransition: nil) { (_) in
            // 控制横竖屏下的侧滑手势
            if (OPSDKFeatureGating.controlLandscapePopGesture()) {
                navi?.interactivePopGestureRecognizer?.isEnabled = !isLandScape
            }
            self.fireWindowResize()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !FeatureGatingManager.shared.featureGatingValue(with: .init(stringLiteral: "openplatform.gadget.ipad.errorpage.followup.disable")),
           Display.pad {
            // self.loadingVC.view 是通过addsubview添加的，在ipad分屏模式下，需要手动管理frame
            self.loadingVC.view.bdp_width = self.view.bdp_width
        }
    }

    func fireWindowResize() {
        guard let uniqueID = self.uniqueID,
              let task = BDPTaskManager.shared().getTaskWith(uniqueID) else {
                  Self.logger.warn("can not get task or uniqueID is nil")
                  return
              }
        
        let screenSize = UIScreen.main.bounds.size
        var windowSize = screenSize
        var pageInterfaceOrientation = ""

        // Note: 这边取windowSize与BDPBaseContainerController中逻辑保持一致;
        // 原逻辑中会一直取不到BDPAppPageController导致一直返回subNavi.view的尺寸,这是有问题的.需要单独修改onWindowResize逻辑
        if let module = BDPModuleManager(of: .gadget).resolveModule(with: BDPContainerModuleProtocol.self) as? BDPContainerModuleProtocol,
           let subNavi = self.subNavi {
            windowSize = module.containerSize(subNavi, type: .gadget, uniqueID: uniqueID)
            subNavi.windowSize = windowSize
        } else {
            Self.logger.info("cannot get BDPContainerModuleProtocol instance or subNavi is nil \(BDPSafeString(uniqueID.fullString))")
        }

        if let appController = self.appController,
           let appPageController = appController.currentAppPage() {
            pageInterfaceOrientation = OPGadgetRotationHelper.configPageInterfaceResponse(appPageController.pageInterfaceOrientation)
        } else {
            Self.logger.info("cannot get current appPageController \(BDPSafeString(uniqueID.fullString))")
        }

        let data : [String : Any] = ["size" : ["windowWidth": windowSize.width,
                    "windowHeight" : windowSize.height,
                    "screenWidth" : screenSize.width,
                    "screenHeight" : screenSize.height],
                    "pageOrientation" : pageInterfaceOrientation]

        Self.logger.info("onWindowResize: \(data) uniqueID: \(BDPSafeString(uniqueID.fullString))")
        task.context?.bdp_fireEvent("onWindowResize", sourceID: NSNotFound, data: data)
    }
    
    func updateLoading(name: String, iconUrl: String) {
        if containerContext?.apprearenceConfig.showDefaultLoadingView == false {
            return
        }
        executeOnMainQueueAsync {
            self.loadingVC.updateLoadingView(appName: name, iconUrl: iconUrl)
        }
    }
    
    func hideLoading() {
        if containerContext?.apprearenceConfig.showDefaultLoadingView == false {
            return
        }
        executeOnMainQueueAsync {
            self.loadingVC.hideLoadingView(hideToolBar: true) { () -> (Void) in
                self.loadingVC.view.removeFromSuperview()
            }
        }
    }
    
    func updateLoadingWithFailstate(state: BDPLoadingViewState, info: String) {
        if containerContext?.apprearenceConfig.showDefaultLoadingView == false {
            return
        }
        executeOnMainQueueAsync {
            self.loadingVC.updateLoadingViewWithError(failState: state, info: info)
        }
    }

    func updateLoadingViewWithRecoverableRefresh(info: String, uniqueID: OPAppUniqueID) {
        executeOnMainQueueAsync { [weak self] in
            self?.loadingVC.updateLoadingViewWithRecoverableRefresh(info: info, uniqueID: uniqueID)
        }
    }
    
    func makeLoadingViewUnifyErrotState(errorStyle: UnifyExceptionStyle, uniqueID: OPAppUniqueID) {
        executeOnMainQueueAsync { [weak self] in
            self?.loadingVC.makeLoadingViewUnifyErrotState(errorStyle: errorStyle, uniqueID: uniqueID)
        }
    }

    /// 监听Badge变化
    private func observeBadge() throws {
        guard let uniqueID = uniqueID else {
            return
        }
        let appId = uniqueID.appID
        let badgeAPI = try userResolver.resolve(assert: OPBadgeAPI.self)
        let featureGatingService = try userResolver.resolve(assert: FeatureGatingService.self)
        let pushCenter = try userResolver.resolve(assert: PushNotificationCenter.self)
        
        let enableGadgetAppBadge = featureGatingService.staticFeatureGatingValue(
            with: OPBadgeFeatureKey.enableGadgetAppBadge.key
        )
        let enableMainTabOpenplatformAppBadge = featureGatingService.staticFeatureGatingValue(
            with: OPBadgeFeatureKey.enableMainTabOpenplatformAppBadge.key
        )
        guard enableGadgetAppBadge, enableMainTabOpenplatformAppBadge else {
            Self.logger.info("[OPBadge] observe badge, but fg: gadget.open_app.badge is not enable")
            self._badge.accept(.none)
            self._badgeVersion.accept(nil)
            return
        }
        var appAbility: OPBadge.AppAbility = .unknown
        /// 租户添加的应用：通过 tab.appType 判断
        /// 用户 pin 到导航栏的应用: appType 是 .appTypeOpenApp, 这种类型可能还包含用户手动添加的开放平台网页链接，因此用 tab.bizType 判断
        if uniqueID.appType == .gadget {
            appAbility = .MiniApp
        } else if uniqueID.appType == .webApp {
            appAbility = .H5
        } else {
            appAbility = .unknown
        }
        guard let featureType = appAbility.toAppFeatureType() else {
            Self.logger.error("[OPBadge] observe badge, but feature type not satisfied", additionalData: [
                "appId": appId,
                "appType": "\(uniqueID.appType)",
                "appAbility": "\(appAbility.rawValue)"
            ])
            self._badge.accept(.none)
            self._badgeVersion.accept(nil)
            return
        }
        
        let enableNewAppTabBadge = featureGatingService.staticFeatureGatingValue(
            with: OPBadgeFeatureKey.newOpenAppTabBadge.key
        )
        Self.logger.info("[OPBadge] start observe badge", additionalData: [
            "appId": appId,
            "appType": "\(uniqueID.appType)",
            "appAbility": "\(appAbility.rawValue)",
            "enableNewAppTabBadge": "\(enableNewAppTabBadge)"
        ])
        
        if enableNewAppTabBadge {
            /// 新的 badge 数据流程，从 rust 获取 badge 数据
            let badgeNodeCallback: ((
                _ badgeNode: OPBadgeRustAlias.OpenAppBadgeNode) -> Void
            ) = { [weak self] (badgeNode) in
                guard let self = self else {
                    Self.logger.error("[OPBadge] observe badge, but OPAppTabRepresentable released")
                    return
                }
                
                if badgeNode.needShow {
                    Self.logger.info("[OPBadge] Tab update badge", additionalData: [
                        "appId": badgeNode.appID,
                        "needShow": "\(badgeNode.needShow)",
                        "badgeNum": "\(badgeNode.badgeNum)",
                        "version": "\(badgeNode.version)",
                        "feature": "\(badgeNode.feature)",
                        "updateTime": "\(badgeNode.updateTime)"
                    ])
                    self._badge.accept(.number(Int(badgeNode.badgeNum)))
                    self._badgeVersion.accept(badgeNode.version)
                } else {
                    Self.logger.info("[OPBadge] Tab hide badge", additionalData: [
                        "appId": badgeNode.appID,
                        "needShow": "\(badgeNode.needShow)",
                        "badgeNum": "\(badgeNode.badgeNum)",
                        "version": "\(badgeNode.version)",
                        "feature": "\(badgeNode.feature)",
                        "updateTime": "\(badgeNode.updateTime)"
                    ])
                    self._badge.accept(.none)
                    self._badgeVersion.accept(badgeNode.version)
                }
            }
            
            self.badgeService = OPBadge.OPBadgeService(
                pushCenter: pushCenter,
                badgeAPI: badgeAPI,
                appId: appId,
                featureType: featureType,
                badgeNodeCallback: badgeNodeCallback
            )
        } else {
            /// 旧的 badge 数据流程，从工作台通知获取 badge 数据
            let badgeNumCallback: ((
                _ badgeNum: Int,
                _ needShow: Bool) -> Void
            ) = { [weak self] (badgeNum, needShow) in
                guard let self = self else {
                    Self.logger.error("[OPBadge] observe badge, but OPAppTabRepresentable released")
                    return
                }
                
                if needShow {
                    Self.logger.info("[OPBadge] Tab update badge", additionalData: [
                        "appId": appId,
                        "appAbility": "\(appAbility.description)",
                        "badgeNum": "\(badgeNum)"
                    ])
                    self._badge.accept(.number(badgeNum))
                } else {
                    Self.logger.info("[OPBadge] Tab hide badge", additionalData: [
                        "appId": appId,
                        "appAbility": "\(appAbility.description)",
                        "badgeNum": "\(badgeNum)"
                    ])
                    self._badge.accept(.none)
                }
            }
            self.badgeObsever = OPBadge.BadgePushObserver(
                appId: appId,
                type: appAbility,
                badgeNumCallback: badgeNumCallback
            )
        }
    }
}

extension OPGadgetContainerController: OPGadgetContainerControllerAdapterProtocol {
    
    func asBaseContainerController() -> BDPBaseContainerController {
        return self
    }
    
}

/// 让BDPBaseContainerController遵循GadgetNavigationProtocol协议，这可以让它使用新的小程序统一路由
extension BDPBaseContainerController: GadgetNavigationProtocol {
    public var isCloseOtherSceneWhenOnlyHasIt: Bool {
        true
    }

    public func navigationStyle(in modalViewController: UIViewController) -> GadgetNavigationStyle {
        if modalViewController is UINavigationController {
            if BDPDeviceHelper.isPadDevice() {
                /// 特化逻辑只针对iPad
                let traitCollection = modalViewController.traitCollection
                /// 只要有一边是C，那么我们都要使用present
                if traitCollection.horizontalSizeClass == .compact || traitCollection.verticalSizeClass == .compact {
                    return .present
                } else {
                    return .innerOpen
                }
            } else {
                return .innerOpen
            }
        } else {
            /// 如果模态不是NC，那么我们只能模态弹出
            return .present
        }
    }

    public func modalStyleWhenPresented(from modalViewController: UIViewController) -> UIModalPresentationStyle {
        /// 特化逻辑只针对iPad
        guard BDPDeviceHelper.isPadDevice() else {
            /// 不是iPad，则全屏模态
            return .fullScreen
        }

        /// 获取window的lkTraitCollection，注意这里存在主端的特化逻辑，不建议使用traitCollection
        /// 相关文档 https://bytedance.feishu.cn/wiki/wikcnfyheXh4b4AZ70Z5XvcgAob#
        guard let traitCollection = modalViewController.view.window?.lkTraitCollection else {
            /// 如果获取不到，那么肯定发生了比较严重的问题，我们需要assert
            assertionFailure("modalViewController isn't in window")
            return .pageSheet
        }

        /// 只要有一边是C，那么我们都要使用fullScreen
        if traitCollection.horizontalSizeClass == .compact || traitCollection.verticalSizeClass == .compact {
            return .fullScreen
        } else {
            return .pageSheet
        }

    }

    public func recoverBlankViewControllerActionOnPresented() -> ((_ blankViewController: UIViewController) -> ())? {
        guard let uniqueID = self.uniqueID else {
            OPAssertionFailureWithLog("uniqueID is nil")
            return nil
        }
        guard let url = GadgetAppLinkBuilder(uniqueID: uniqueID).buildURL() else {
            return nil
        }

        /// 设置恢复行为
        return {
            (blankViewController: UIViewController) -> Void in
            /// 需要找到UIWindow，这样传入路由体系会比较安全，在新路由体系下，传入什么都可以兜住，但是在老路由体系下易出问题
            guard let window = blankViewController.view.window ?? OPWindowHelper.fincMainSceneWindow() else {
                return
            }
            
            OPUserScope.userResolver().navigator.open(url, from: window)
        }
    }
    
    public var openInTemporaryTab: Bool {
        return shouldOpenInTemporaryTab
    }
}

extension OPGadgetContainerController : OPMemoryMonitorObjectProtocol{
    static var overcountNumber: UInt{
        return 10
    }
}

