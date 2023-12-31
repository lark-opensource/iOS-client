//
//  WikiTabViewControllerV2.swift
//  LarkSpaceKit
//
//  Created by 邱沛 on 2021/4/13.
//

import UIKit
import SpaceKit
import RxRelay
import RxSwift
import EENavigator
import LarkUIKit
import LarkContainer

#if MessengerMod
import LarkMessengerInterface
#endif

import LarkNavigation
import AnimatedTabBar
import LarkTab
import SKWikiV2
import SKCommon
import SKFoundation
import SKUIKit
import UniverseDesignIcon

class WikiTab: TabRepresentable {
    var tab: Tab { return .wiki }
}

class WikiTabViewControllerV2: WikiHomePageViewController {
    private var isCreateButtonEnabled = true
    private var isTabDidLoad = false

    private lazy var naviBarCreateButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.moreAddOutlined, for: .normal)
        button.addTarget(self, action: #selector(openCreatePanel(sourceView:)), for: .touchUpInside)
        return button
    }()
    private let bag = DisposeBag()
    
    override func updateCreateBarItem(isEnabled: Bool) {
        isCreateButtonEnabled = isEnabled
        naviBarCreateButton.isEnabled = isEnabled
        reloadNaviBar()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let createButton = self.createButton else {
            return
        }
        // FG 关才展示右下角的创建按钮
        if !UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable {
            view.addSubview(createButton)
            createButton.snp.makeConstraints { make in
                make.right.equalTo(view.safeAreaLayoutGuide.snp.right).inset(16)
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(16)
                make.width.height.equalTo(48)
            }
            createButton.layer.cornerRadius = 24
        }
        
        subscribeTrailingBarButtonItemsUpdate()
    }
    
    private func subscribeTrailingBarButtonItemsUpdate() {
        trailingBarButtonItemsUpdate?.drive(onNext: { [weak self] _ in
            self?.reloadNaviBar()
        }).disposed(by: bag)
    }

    @objc
    private func openCreatePanel(sourceView: UIView) {
        didClickCreateItem(sourceView: sourceView)
    }
}

// MARK: - Wiki Tab
extension WikiTabViewControllerV2: TabRootViewController {
    public var tab: Tab {
        return Tab.wiki
    }
    public var controller: UIViewController {
        return self
    }
}

// MARK: - Wiki Navigation Bar
extension WikiTabViewControllerV2: LarkNaviBarProtocol {

    public var titleText: BehaviorRelay<String> {
        return BehaviorRelay(value: WikiHomePageViewController.wikiHomePageTitle)
    }

    public var isNaviBarEnabled: Bool {
        return true
    }

    public var isDrawerEnabled: Bool {
        return true
    }

    public func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? {
        nil
    }

    public func larkNaviBar(userDefinedButtonOf type: LarkUIKit.LarkNaviButtonType) -> UIButton? {
        guard case .first = type else {
            return nil
        }
        guard UserScopeNoChangeFG.WWJ.createButtonOnNaviBarEnable else { return nil }
        return naviBarCreateButton
    }

    public func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) {
        switch type {
        case .search:
            #if MessengerMod
            let body = SearchMainBody(topPriorityScene: .rustScene(.searchWikiScene), sourceOfSearch: .wiki)
            userResolver.navigator.push(body: body, from: self)
            reportOpenSearchEvent()
            #endif
        case .first:
            openCreatePanel(sourceView: button)
        case .second:
            break
        @unknown default:
            break
        }
    }
}

extension WikiTabViewControllerV2: LarkNaviBarAbility {}

extension WikiTabViewControllerV2: CustomNaviAnimation {
    // transform push transition to MainTabBarController
    var animationProxy: CustomNaviAnimation? {
        return self.animatedTabBarController as? CustomNaviAnimation
    }
}
