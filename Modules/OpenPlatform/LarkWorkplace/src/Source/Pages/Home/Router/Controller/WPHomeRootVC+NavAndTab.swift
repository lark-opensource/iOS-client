//
//  WPHomeRootVC+Nav.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/17.
//

import Foundation
import AnimatedTabBar
import LarkTab
import LarkUIKit
import RxRelay
import LarkOPInterface

// MARK: - Tab

extension WPHomeRootVC: TabRootViewController {
    var tab: Tab { .appCenter }
    var controller: UIViewController { self }

    // 主导航首屏数据 Ready 上报
    var firstScreenDataReady: BehaviorRelay<Bool>? {
        wpFirstScreenDataReady
    }
}

extension WPHomeRootVC: TabbarItemTapProtocol {
    /// 单击 Tab
    func onTabbarItemTap(_ isSameTab: Bool) {
        context.tracker
            .start(.openplatform_workspace_main_page_click)
            .setClickValue(.tab)
            .setTargetView(.openplatform_workspace_main_page_view)
            .post()
        currentContainerVC?.onTabbarItemTap(isSameTab)
    }
}

// MARK: - Nav

extension WPHomeRootVC: LarkNaviBarDataSource {

    // MARK: - require

    /// 标题
    var titleText: BehaviorRelay<String> {
        currentContainerVC?.titleText ?? BehaviorRelay(value: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_Title)
    }

    var subFilterTitleText: BehaviorRelay<String?> {
        BehaviorRelay(value: nil)
    }

    /// 开启导航栏
    var isNaviBarEnabled: Bool {
        currentContainerVC?.isNaviBarEnabled ?? true
    }

    /// 开启侧边栏
    var isDrawerEnabled: Bool {
        true
    }

    // MARK: - optional

    /// 导航栏右侧按钮
    var useNaviButtonV2: Bool {
        true
    }

    /// 设置导航栏右侧按钮
    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton? {
        currentContainerVC?.larkNaviBarV2(userDefinedButtonOf: type)
    }

    func larkNaviBarV2(userDefinedColorOf type: LarkNaviButtonTypeV2, state: UIControl.State) -> UIColor? {
        currentContainerVC?.larkNaviBarV2(userDefinedColorOf: type, state: state)
    }

    /// 标题是否添加 ... 加载动画
    var isNaviBarLoading: BehaviorRelay<Bool> {
        currentContainerVC?.isNaviBarLoading ?? BehaviorRelay(value: false)
    }

    /// 标题右侧下拉箭头
    var needShowTitleArrow: BehaviorRelay<Bool> {
        if portalMenuView.portalList.count > 1 {
            return BehaviorRelay(value: true)
        } else {
            return BehaviorRelay(value: false)
        }
    }
    
    var bizScene: LarkNaviBarBizScene? {
        currentContainerVC?.bizScene
    }
}

extension WPHomeRootVC: LarkNaviBarDelegate {
    /// 点击头像
    func onDefaultAvatarTapped() {
        currentContainerVC?.onDefaultAvatarTapped()
    }

    /// 点击Title
    func onTitleViewTapped() {
        switchPortalListMenuVisibility()
    }
}

extension WPHomeRootVC: LarkNaviBarAbility {
}

extension WPHomeRootVC: WPHomeRootVCProtocol {
    // 顶部导航栏高度，包含 statusbar
    var topNavH: CGFloat {
        UIApplication.shared.statusBarFrame.height + naviHeight
    }

    var botTabH: CGFloat {
        animatedTabBarController?.tabbarHeight ?? 0
    }
    
    var templatePortalCount: Int {
        return self.portalMenuView.portalList.filter { portal in
            portal.type == .lowCode || portal.type == .web
        }.count
    }

    func reportFirstScreenDataReadyIfNeeded() {
        if wpFirstScreenDataReady.value != true {
            wpFirstScreenDataReady.accept(true)
        }
    }

    func rootReloadNaviBar() {
        reloadNaviBar()
    }
}
