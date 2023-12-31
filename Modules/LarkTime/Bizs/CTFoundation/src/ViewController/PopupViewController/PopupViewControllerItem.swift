//
//  PopupViewControllerItem.swift
//  iOS
//
//  Created by 张威 on 2020/1/9.
//  Copyright © 2020 SadJason. All rights reserved.
//

import UIKit
import LarkUIKit
import UniverseDesignIcon

public enum Popup {

    // MARK: Popup Offset

    /// `PopupOffset` 描述弹窗的漏出比例，有效值：0.0..<1.0
    /// 譬如 container contentHeight = 1000pt，offset = 0.3，则意味着当前弹窗内容高度为 300pt
    public struct Offset: RawRepresentable, Comparable {
        public var rawValue: CGFloat

        public init(rawValue: CGFloat) {
            self.rawValue = max(min(1.0, rawValue), 0.0)
        }

        public static func < (lhs: Offset, rhs: Offset) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        public static let minimum = Offset(rawValue: 0.0)
        public static let maximum = Offset(rawValue: 1.0)
        public static let zero = Offset.minimum
        public static let full = Offset.maximum
    }

    // MARK: Popup Const

    /// 弹窗相关常量
    public struct Const {
        /// indicator View height
        public static let indicatorHeight: CGFloat = 21.0
        /// navibar高度
        static let naviBarHeight: CGFloat = 62
        /// 弹窗动画数值
        static let animationDuration: TimeInterval = 0.25
        /// R视图下弹窗下滑时关闭高度
        static let dismissHeight: CGFloat = 300
        /// R视图弹窗高度
        static let popupViewRegularHeight: CGFloat = 640
        /// R视图弹窗宽度
        static let popupViewRegularWeight: CGFloat = 580
        /// R视图下滑关闭的最小速度
        static let minDismissVelocity: CGFloat = 2000
        /// R视图上滑
        static let slideUpMultiple: Double = 4
        /// C视图下默认弹窗高度
        public static let defaultPresentHeight: CGFloat = 327
        /// R视图下键盘弹起时窗口距离顶端的最小距离
        static let minHeightToTop: CGFloat = 44
    }

    public static var standardDistanceToTop: CGFloat = 24

    // MARK: NaviBar
    /// c视图下navibar样式
    public enum NaviBarStyle {
        case `default`
        case none
    }
}

public typealias PopupOffset = Popup.Offset

// MARK: PopupViewControllerItem

/// `PopupViewController` 容器的 item view controller
public protocol PopupViewControllerItem: UIViewController {

    /// 描述支持的悬停高度，譬如：容器 contentHeight = 800pt；
    /// `[PopupOffset(rawValue: 0.4), PopupOffset(rawValue: 1.0)]` 则表示：
    /// 当前 VC 可以 320pt，800pt 这两个位置悬停，其他高度无法正常悬停
    var hoverPopupOffsets: [PopupOffset] { get }

    /// 描述当前 VC 所期待的高度，转场时，`PopupViewController` 会将当前 VC 切换到合适的高度
    var preferredPopupOffset: PopupOffset { get }

    var naviBarStyle: Popup.NaviBarStyle { get }

    /// naviBar标题
    var naviBarTitle: String { get }

    /// 弹窗背景被点击，默认行为是：弹窗消失；可以自定义行为，譬如阻止弹窗消失
    func popupBackgroundDidClick()

    /// 弹窗交互手势C视图（pan 手势）开始交互前，`PopupViewController` 调用该回调，VC 可以用以处理手势冲突逻辑
    func shouldBeginPopupInteractingInCompact(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool

    /// 弹窗交互手势R视图（pan 手势）开始交互前，`PopupViewController` 调用该回调，VC 可以用以处理手势冲突逻辑
    func shouldBeginPopupInteractingInRegular(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool

    /// naviBar 左侧Item
    var naviBarLeftItems: [TitleNaviBarItem]? { get }

    /// naviBar 右侧Item
    var naviBarRightItems: [TitleNaviBarItem]? { get }

    /// naviBar背景色
    var naviBarBackgroundColor: UIColor { get }
}

// Default Implementations

public extension PopupViewControllerItem {

    var hoverPopupOffsets: [PopupOffset] { [.full] }
    var preferredPopupOffset: PopupOffset { hoverPopupOffsets.last ?? .full }
    var viewController: UIViewController { self }
    var naviBarStyle: Popup.NaviBarStyle { .default }
    var naviBarTitle: String { "" }
    var naviBarLeftItems: [TitleNaviBarItem]? { nil }
    var naviBarRightItems: [TitleNaviBarItem]? { nil }
    var naviBarBackgroundColor: UIColor { UIColor.ud.bgBody }

    func popupBackgroundDidClick() {
        popupViewController?.dismiss(animated: true, completion: nil)
    }

    func shouldBeginPopupInteractingInCompact(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    func shouldBeginPopupInteractingInRegular(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension PopupViewControllerItem {
    public weak var popupViewController: PopupViewController? {
        viewController.parent as? PopupViewController
    }
}
