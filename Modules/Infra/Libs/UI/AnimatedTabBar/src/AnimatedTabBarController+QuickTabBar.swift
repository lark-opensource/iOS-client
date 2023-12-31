//
//  AnimatedTabBarController+QuickTabBar.swift
//  AnimatedTabBar
//
//  Created by 夏汝震 on 2021/6/4.
//

import UIKit
import Homeric
import LarkTab
import LKCommonsTracker
import UniverseDesignToast

extension AnimatedTabBarController {

    /// 点击【更多】按钮时，需要添加/移除快捷导航popView
    func showOrDismssQuickTabBar() {
        if quickTabBar == nil {
            if let superView = mainTabBar.superview {
                showQuickTabBar(parentView: superView, dataSource: quickTabBarItems)
            }
        } else {
            dismissQuickTabBar()
        }
    }

    /// 点击【更多】按钮时，需要添加快捷导航popView
    private func showQuickTabBar(parentView: UIView, dataSource: [AbstractTabBarItem]) {
        let editEnabled = animatedTabBarDelegate?.editTabBarEnabled() ?? true
        let contentView = QuickTabBarContentView(frame: .zero, dataSource: dataSource, editEnabled: editEnabled, userResolver: userResolver)
        contentView.delegate = self
        self.quickTabBarContentView = contentView

        let quickTabBar = QuickTabBar(frame: parentView.bounds, contentView: contentView, delegate: self)
        parentView.insertSubview(quickTabBar, belowSubview: mainTabBar)

        quickTabBar.snp.makeConstraints { make in
            make.top.leading.trailing.equalTo(parentView)
            make.bottom.equalTo(mainTabBar.snp.top)
        }
        quickTabBar.show(contentView: contentView, delegate: self)
        self.quickTabBar = quickTabBar
    }

    /// 点击【更多】按钮或者点击其他按钮时，需要移除快捷导航popView
    func dismissQuickTabBar() {
        quickTabBar?.dismiss()
    }

    /// Tabar 层级变化，更新 quick tab，主要是用来dismiss掉
    func dismissQuickTabBarIfNeed() {
        if mainTabBar.superview == nil {
            dismissQuickTabBar()
        }
    }

    /// 收到数据时，需要刷新collectionView，并重新布局
    func refreshQuickTabBar(_ dataSource: [AbstractTabBarItem]) {
        quickTabBarContentView?.updateData(dataSource)
        quickTabBar?.layout()
    }

    // 横竖屏/CR切换时，需要刷新布局
    func layoutQuickTabBar() {
        self.quickTabBar?.layout()
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            /// 放到下个runloop更新，确保content view宽度已经完全正确
            self.quickTabBarContentView?.reload()
        }
    }
}

extension AnimatedTabBarController: QuickTabBarDelegate {

    public func quickTabBarDidShow(_ quickTabBar: QuickTabBarInterface, isSlide: Bool) {
        quickNavigationDidAppear(isSlide: isSlide)
        mainTabBar.clearShadow()
    }

    public func quickTabBarDidDismiss(_ quickTabBar: QuickTabBarInterface, isSlider: Bool) {
        // nothing
        if isInBottomMainBar(selectedTab) {
            selectedTabItem?.selectedState()
            bottomMoreItem?.deselectedState()
        }
        mainTabBar.setupTabBarShadow()
    }
}

extension AnimatedTabBarController: QuickTabBarContentViewDelegate {
    func quickTabBar(_ contentView: QuickTabBarContentViewInterface, didSelectItem tab: Tab) {
        tabItemSelectHandler(for: tab)
    }

    func quickTabBarDidTapEditButton(_ contentView: QuickTabBarContentViewInterface) {
        dismissQuickTabBar()
        showTabEditController()
        Tracker.post(TeaEvent(Homeric.NAVIGATION_MORE_EDIT))
    }

    func showTabEditController(on viewController: UIViewController? = nil) {
        if !isEditNaivDisable {
            // 新版编辑页面
            let (main, quick) = animatedTabBarDelegate?.computeNaviEditItems() ?? ([], [])
            let viewModel = NaviEditViewModel(mainItems: main,
                                              quickItems: quick,
                                              minTabCount: tabBarConfig.minBottomTab,
                                              maxTabCount: tabBarConfig.maxBottomTab)
            let editController = NaviEditViewController(tabBarVC: self, viewModel: viewModel, moreTabEnabled: self.moreTabEnabled, userResolver: self.userResolver) { [weak self] (vc, changed, main, quick) in
                guard let self = self, let hudOn = vc.view else { return }
                guard changed else {
                    vc.dismiss(animated: true, completion: nil)
                    return
                }
                let hud = UDToast.showLoading(with: BundleI18n.AnimatedTabBar.Lark_Legacy_BaseUiLoading, on: hudOn, disableUserInteraction: true)
                self.animatedTabBarDelegate?.tabbarController(self, didEditForMain: main, quick: quick, success: { [weak vc] in
                    vc?.dismiss(animated: true, completion: nil)
                    hud.remove()
                }, fail: {
                    hud.remove()
                    UDToast.showFailure(with: BundleI18n.AnimatedTabBar.Lark_Legacy_NetworkError, on: hudOn)
                })
            }
            editController.modalPresentationStyle = .fullScreen
            editController.modalTransitionStyle = .crossDissolve
            if let presentingVC = viewController {
                presentingVC.present(editController, animated: true)
            } else {
                present(editController, animated: true)
            }
        } else {
            // 旧版编辑页面
            let (main, quick) = animatedTabBarDelegate?.computeRankItems() ?? ([], [])
            let viewModel = RankViewModel(mainItems: main,
                                          quickItems: quick,
                                          minTabCount: tabBarConfig.minBottomTab,
                                          maxTabCount: tabBarConfig.maxBottomTab)
            let editController = RankViewController(viewModel: viewModel,
                                                    previewEnabled: tabbarStyle == .bottom,
                                                    userResolver: userResolver) { [weak self] (vc, changed, main, quick) in
                guard let self = self, let hudOn = self.view else { return }
                guard changed else {
                    vc.dismiss(animated: true, completion: nil)
                    return
                }
                let hud = UDToast.showLoading(with: BundleI18n.AnimatedTabBar.Lark_Legacy_BaseUiLoading, on: hudOn, disableUserInteraction: true)
                self.animatedTabBarDelegate?.tabbarController(self, didReorderForMain: main, quick: quick, success: { [weak vc] in
                    vc?.dismiss(animated: true, completion: nil)
                    hud.remove()
                }, fail: {
                    hud.remove()
                    UDToast.showFailure(with: BundleI18n.AnimatedTabBar.Lark_Legacy_NetworkError, on: hudOn)
                })
            }
            switch tabbarStyle {
            case .edge:
                editController.modalPresentationStyle = .formSheet
            case .bottom:
                editController.transitionManager = RankViewTransitionManager(
                    controller: editController,
                    isQuickLauncherEnabled: isQuickLauncherEnabled
                )
            }
            if let presentingVC = viewController {
                presentingVC.present(editController, animated: true)
            } else {
                present(editController, animated: true)
            }
        }
    }
}
