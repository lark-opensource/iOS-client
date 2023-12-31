//
//  FeedMainViewController+SetupViews.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/7/8.
//

import UIKit
import Foundation
import SnapKit
import RxDataSources
import RxSwift
import RxCocoa
import LarkNavigation
import AnimatedTabBar
import LKCommonsLogging
import RunloopTools
import LarkSDKInterface
import RustPB
import AppContainer
import LarkPerf
import LarkMessengerInterface
import EENavigator
import LarkKeyCommandKit
import LarkUIKit
import UniverseDesignTabs
import LarkFoundation
import Heimdallr
import AppReciableSDK
import LarkAccountInterface

// MARK: 创建及基本布局
extension FeedMainViewController {
    func setupViews() {
        self.isNavigationBarHidden = true
        let backgroundColor = UIColor.ud.bgBody
        view.backgroundColor = backgroundColor
        mainScrollView.backgroundColor = backgroundColor
        mainScrollView.delegate = self
        mainScrollView.alwaysBounceVertical = true
        mainScrollView.showsVerticalScrollIndicator = false
        filterTabView.delegate = self

        moduleVCContainerView.parentViewController = self
        // 控制NavigationBar中的floataction切换
        presentProcessor.delegate = self
    }

    // 布局
    func layout() {
        self.view.addSubview(mainScrollView)
        mainScrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(naviHeight)
            make.leading.trailing.bottom.equalToSuperview()
        }

        mainScrollView.addSubview(headerView)
        headerView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(0)
        }

        mainScrollView.addSubview(filterTabView)
        filterTabView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(self.filterTabViewModel.viewHeight)
        }
        mainScrollView.addSubview(moduleVCContainerView)
        moduleVCContainerView.snp.makeConstraints { (make) in
            make.top.equalTo(filterTabView.snp.bottom)
            make.leading.trailing.bottom.width.equalToSuperview()
            make.height.equalToSuperview()
        }

        changeTab(mainViewModel.firstTab, .viewDidLoad)

        // 展示简单模式tips
        showMinimumModeTipViewIfNeed()
    }

    func binds() {
        // 绑定筛选器相关信号
        bindFilter()
    }

    func asyncBinds() {

        // 新注册用户引导(头像红点)
        observeNewRegisterGuide()

        // 三栏引导
        observeFeedThreeColumnsGuide()

        // iPad: CR切换时，需要dismiss present的(filterType/filterCard/floatAction)
        dismissProcesserWhenTransition()
        observSelectFeedTab()

        // Founcs 相关
        bindFocus()

        NotificationCenter.default.rx
            .notification(Notification.statusBarTapped.name)
            .subscribe(onNext: { [weak self] (notification) in
                guard let self = self else { return }
                guard UIStatusBarHookManager.viewShouldResponse(of: self.view, for: notification) else { return }
                self.scrollTop(animated: true)
                self.setSubScrollContentOffset(.zero, animated: true)
            }).disposed(by: disposeBag)
    }
}
