//
//  SpaceTabViewController.swift
//  LarkSpaceKit
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import SKSpace
import RxSwift
import RxRelay
import RxCocoa
import EENavigator
import LarkUIKit

#if MessengerMod
import LarkMessengerInterface
#endif

import LarkNavigation
import AnimatedTabBar
import SKResource
import LarkTab
import LarkKeyCommandKit
import SKCommon
import SKInfra
import SKFoundation
import UniverseDesignColor
import UniverseDesignIcon
import LarkContainer
import SKUIKit

class DocsTab: TabRepresentable {
    var tab: Tab { return .doc }
    let badge: BehaviorRelay<BadgeType>? = BehaviorRelay<BadgeType>(value: .none)
    var badgeStyle: BehaviorRelay<BadgeRemindStyle>? = BehaviorRelay<BadgeRemindStyle>(value: .strong)
}

class SpaceTabViewController: UIViewController {
    private let bag = DisposeBag()
    private let spaceHomeViewController: SpaceHomeViewController
    private var magicRegister: FeelGoodRegister?
    private let userReslover: UserResolver
    init(userReslover: UserResolver, spaceHomeViewController: SpaceHomeViewController) {
        self.userReslover = userReslover
        self.spaceHomeViewController = spaceHomeViewController
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
        setupChildVC()
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

    private func openCreatePanel(sourceView: UIView) {
        spaceHomeViewController.homeViewModel.createIntentionTrigger.accept((.recent, .bottomRight, sourceView))
    }
    
    private func openMorePanel(sourceView: UIView) {
        SpaceHomeListPanelNavigator.showSpaceListPanel(userResolver: userReslover, from: self, sourceView: sourceView)
    }
}

// MARK: - TabRootViewController
extension SpaceTabViewController: TabRootViewController {
    var tab: Tab { .doc }
    var controller: UIViewController { self }
}

// MARK: - LarkNaviBarProtocol
extension SpaceTabViewController: LarkNaviBarProtocol {
    var titleText: BehaviorRelay<String> { .init(value: SKResource.BundleI18n.SKResource.Doc_List_Space) }
    var isNaviBarEnabled: Bool { true }
    var isDrawerEnabled: Bool { true }

    func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        switch type {
        case .search:
            return nil
        case .first:
            if UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable {
                return UDIcon.moreAddOutlined
            } else {
                return nil
            }
        case .second:
            let needHidden = SKDisplay.pad && UserScopeNoChangeFG.MJ.newIpadSpaceEnable
            if UserScopeNoChangeFG.WWJ.newSpaceTabEnable && !needHidden {
                return UDIcon.moreOutlined
            }
            return nil
        @unknown default:
            return nil
        }
    }

    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .search:
            navigateToSearch()
        case .first:
            openCreatePanel(sourceView: button)
        case .second:
            openMorePanel(sourceView: button)
        @unknown default:
            break
        }
    }
}

// MARK: - LarkNaviBarAbility
extension SpaceTabViewController: LarkNaviBarAbility {}

// MARK: - CustomNaviAnimation
extension SpaceTabViewController: CustomNaviAnimation {
    // transform push transition to MainTabBarController
    public var animationProxy: CustomNaviAnimation? {
        return self.animatedTabBarController as? CustomNaviAnimation
    }
}

// MARK: - SpaceNaviBarProvider
extension SpaceTabViewController: SpaceNaviBarProvider {
    // 暂时不需要提供 naviBar
    var skNaviBar: SpaceNaviBarCompatible? { nil }
}

extension SpaceTabViewController: TabbarItemTapProtocol {
    public func onTabbarItemTap(_ isSameTab: Bool) {
        NotificationCenter.default.post(name: .SpaceTabItemTapped,
                                        object: nil,
                                        userInfo: [SpaceTabItemTappedNotificationKey.isSameTab: isSameTab])
        if !isSameTab {
            DocTrackUtil.trackDocsTab()
        }
    }

    public func onTabbarItemDoubleTap() {
        spaceHomeViewController.forceScrollToTop()
    }
}
extension SpaceTabViewController: DocsCreateViewControllerRouter { }
