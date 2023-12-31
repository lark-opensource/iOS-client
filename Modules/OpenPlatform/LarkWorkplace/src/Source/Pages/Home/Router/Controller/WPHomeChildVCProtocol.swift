//
//  WPHomeChildVCProtocol.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/12/20.
//

import LarkUIKit
import AnimatedTabBar
import RxRelay
import CoreGraphics

typealias WPHomeContainerVC = UIViewController & WPHomeChildVCProtocol

/// parentVC -> childVC
protocol WPHomeChildVCProtocol {
    /// 更新门户信息
    func updateInitData(_ wrapper: WPHomeVCInitData)

    // MARK: - Tab

    func onDefaultAvatarTapped()

    func onTabbarItemTap(_ isSameTab: Bool)

    // MARK: - Nav

    // Title
    var titleText: BehaviorRelay<String> { get }

    // 是否在加载中
    var isNaviBarLoading: BehaviorRelay<Bool> { get }

    // 是否可以显示统一导航栏
    var isNaviBarEnabled: Bool { get }

    // 提供Button，支持自定义四个
    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton?

    func larkNaviBarV2(userDefinedColorOf type: LarkNaviButtonTypeV2, state: UIControl.State) -> UIColor?

    func topInsetDidChanged(height: CGFloat)

    var bizScene: LarkNaviBarBizScene? { get }
}

extension WPHomeChildVCProtocol {
    func onDefaultAvatarTapped() {}

    func onTabbarItemTap(_ isSameTab: Bool) {}

    func larkNaviBarV2(userDefinedColorOf type: LarkNaviButtonTypeV2, state: UIControl.State) -> UIColor? { return nil }

    var bizScene: LarkNaviBarBizScene? { nil }
}
