//
//  LarkInterface+NaviBar.swift
//  LarkInterface
//
//  Created by KT on 2019/10/15.
//

import UIKit
import Foundation
import RxCocoa
import RxSwift
import SnapKit

/// 导航栏右侧Button类型
public enum LarkNaviButtonType {
    case search
    case first
    case second
}

/// 导航栏右侧Button类型V2：开放平台有需求自定义四个button，若在原LarkNaviButtonType新增case，
/// 则需要其他业务方适配，成本较大，暂时新增枚举兼容，由业务方决定使用哪种(useNaviButtonV2)，默认使用LarkNaviButtonType。
/// 待重构 @yuanping
/// 现在公司圈也有4个button了（3个自定义button+1个搜索），也用的V2 @jiaxiao
public enum LarkNaviButtonTypeV2: CaseIterable {
    case first
    case second
    case third
    case fourth
}

public enum LarkNaviBarBizScene {
    case workplace
}

public typealias LarkNaviBarProtocol = LarkNaviBarDataSource & LarkNaviBarDelegate

public protocol LarkNaviBarDataSource: UIViewController {
    // Title
    var titleText: BehaviorRelay<String> { get }
    // 是否在加载中
    var isNaviBarLoading: BehaviorRelay<Bool> { get }
    // Title旁边的箭头，有Filter的时候需要
    var needShowTitleArrow: BehaviorRelay<Bool> { get }
    // 是否展示Pad三栏样式
    var showPad3BarNaviStyle: BehaviorRelay<Bool> { get }
    // SubFilter文字，以小标签的形式显示
    var subFilterTitleText: BehaviorRelay<String?> { get }
    // 是否可以显示统一导航栏
    var isNaviBarEnabled: Bool { get }
    // 是否可以显示统一侧边栏
    var isDrawerEnabled: Bool { get }

    // 是否禁用默认搜索按钮(临时方案)
    var isDefaultSearchButtonDisabled: Bool { get }
    // 提供Button 优先级大于下面的方法
    func larkNaviBar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton?
    // 提供Button图片数据源
    func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage?
    // 自定义Color
    func larkNaviBar(userDefinedColorOf type: LarkNaviButtonType, state: UIControl.State) -> UIColor?
    // 是否使用LarkNaviButtonTypeV2：原LarkNaviButtonType在未实现上面两个方法时，在.search时有特化默认值
    // 无法判断是否使用V2，需要业务方决定，默认不使用
    var useNaviButtonV2: Bool { get }
    // 提供Button，支持自定义四个
    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton?
    // 自定义Color
    func larkNaviBarV2(userDefinedColorOf type: LarkNaviButtonTypeV2, state: UIControl.State) -> UIColor?
    // 支持自定义整个右侧View，优先级最高
    var naviButtonView: UIView? { get }
    // 自定义头像View，如果没有定制（如Feed的badge）可以不实现
    func usingCustomAvatarView() -> UIView?
    // 自定义背景色，如果返回 nil，则使用默认颜色
    func larkNavibarBgColor() -> UIColor?
    // 自定义用户状态 View，默认 nil
    func userFocusStatusView() -> UIView?
    // 是否在PadTabbar展示用户状态
    var showTabbarFocusStatus: BehaviorRelay<Bool> { get }
    // 来自哪个业务
    var bizScene: LarkNaviBarBizScene? { get }
    // 自定义 Title旁边的箭头，有Filter的时候需要
    func customTitleArrowView(titleColor: UIColor) -> UIView?
}

public extension LarkNaviBarDataSource {
    var isNaviBarLoading: BehaviorRelay<Bool> { return BehaviorRelay(value: false) }
    var needShowTitleArrow: BehaviorRelay<Bool> { return BehaviorRelay(value: false) }
    var showPad3BarNaviStyle: BehaviorRelay<Bool> { return BehaviorRelay(value: false) }
    var subFilterTitleText: BehaviorRelay<String?> { return BehaviorRelay(value: nil) }
    func usingCustomAvatarView() -> UIView? { return nil }
    var isDefaultSearchButtonDisabled: Bool { return false }
    func larkNaviBar(imageOfButtonOf type: LarkNaviButtonType) -> UIImage? { return nil }
    func larkNaviBar(userDefinedButtonOf type: LarkNaviButtonType) -> UIButton? { return nil }
    func larkNaviBar(userDefinedColorOf type: LarkNaviButtonType, state: UIControl.State) -> UIColor? { return nil }
    func larkNaviBarV2(userDefinedColorOf type: LarkNaviButtonTypeV2, state: UIControl.State) -> UIColor? { return nil }
    var useNaviButtonV2: Bool { return false }
    func larkNaviBarV2(userDefinedButtonOf type: LarkNaviButtonTypeV2) -> UIButton? { return nil }
    var naviButtonView: UIView? { return nil }
    func larkNavibarBgColor() -> UIColor? { return nil }
    func userFocusStatusView() -> UIView? { return nil }
    var showTabbarFocusStatus: BehaviorRelay<Bool> { return BehaviorRelay(value: false) }
    func customTitleArrowView(titleColor: UIColor) -> UIView? { return nil }
    var bizScene: LarkNaviBarBizScene? { return nil }
}

// Navi 事件集合
// swiftlint:disable class_delegate_protocol
public protocol LarkNaviBarDelegate: UIViewController {
    // 点击头像
    func onDefaultAvatarTapped()
    // 点击Title
    func onTitleViewTapped()
    // 点击右侧Button
    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType)
}

public extension LarkNaviBarDelegate {
    func onDefaultAvatarTapped() { }
    func onTitleViewTapped() { }
    func onButtonTapped(on button: UIButton, with type: LarkNaviButtonType) { }
}
// swiftlint:enable class_delegate_protocol

// 实现LarkNaviBarDataSource & LarkNaviBarDelegate的实例有下面的能力
public protocol LarkNaviBarAbility {
    // Navi的高度
    var naviHeight: CGFloat { get }
    // 判断Navi是否显示
    var isNaviBarShown: Bool { get }
    // 判断当前Filter箭头是否折叠
    var isNaviBarTitleArrowFolded: Bool { get }
    // 刷新
    func reloadNaviBar()

    var naviBar: UIView? { get }

    // 控制Navi是否显示/Filter箭头是否折叠。
    // 默认实现show/folded = nil，表示自动识别当前状态并变更。如果需要强制指定时可以直接对show/folded赋值
    func changeNaviBarPresentation(show: Bool?, animated: Bool)
    func changeTitleArrowPresentation(folded: Bool?, animated: Bool)
}

extension LarkNaviBarAbility where Self: UIViewController {

    public var naviHeight: CGFloat {
        return LarkNaviBarConsts.naviHeight
    }

    public var isNaviBarShown: Bool {
        return larkNaviBar?.isShown ?? false
    }

    public var isNaviBarTitleArrowFolded: Bool {
        return larkNaviBar?.isTitleViewArrowFolded ?? true
    }

    public func reloadNaviBar() {
        larkNaviBar?.reloadNaviBar()
    }

    public func changeNaviBarPresentation(show: Bool? = nil, animated: Bool) {
        larkNaviBar?.setPresentation(show: show, animated: animated)
    }

    public func changeTitleArrowPresentation(folded: Bool? = nil, animated: Bool) {
        larkNaviBar?.setArrowPresentation(folded: folded, animated: animated)
    }

    private var larkNaviBar: NaviBarProtocol? {
        let rootVC = UIApplication.shared.windows.compactMap({ $0.rootViewController as? UINavigationController })
        // 兜底：冷启动，tabVC viewDidLoad时RootNavigationController还未加入window，此时取不到naviBar
        let tab = rootVC.compactMap({ $0.viewControllers.first as? MainTabbarProtocol }).first ?? (self.tabBarController as? MainTabbarProtocol)
        return tab?.naviBar
    }

     public var naviBar: UIView? {
        return self.larkNaviBar
     }
}

public struct LarkNaviBarConsts {
    public static let naviHeight: CGFloat = 60
}

public protocol MainTabbarProtocol {
    var naviBar: NaviBarProtocol? { get set }
}

public protocol NaviBarProtocol: UIView {
    var isShown: Bool { get set }
    var isTitleViewArrowFolded: Bool { get set }
    var isNeedShowBadge: Bool { get set }

    var avatarKey: PublishSubject<(entityId: String, key: String)> { get }
    var groupNameText: PublishSubject<String> { get }
    var shouldShowGroup: PublishSubject<Bool> { get }
    var avatarShouldNoticeNewVersion: PublishSubject<Bool> { get }
    var avatarInLeanMode: PublishSubject<Bool> { get }
    var avatarNewBadgeCount: PublishSubject<Int> { get }
    var avatarDotBadgeShow: PublishSubject<Bool> { get }

    var dataSource: LarkNaviBarDataSource? { get set }
    var delegate: LarkNaviBarDelegate? { get set }

    func reloadNaviBar()
    func setPresentation(show: Bool?, animated: Bool)
    func setArrowPresentation(folded: Bool?, animated: Bool)
    func getTitleTappedSourceView() -> UIView
    func getAvatarContainer() -> UIView
    // provide navibar button by type
    func getButtonByType(buttonType: LarkNaviButtonType) -> UIView?
    func onAvatarContainerTapped()
    func showSideBar(completion: (() -> Void)?)
}

extension Notification.Name {
    public static let lkTabbarDidLayoutSubviews = Notification.Name(rawValue: "lkTabbarDidLayoutSubviews")
}
