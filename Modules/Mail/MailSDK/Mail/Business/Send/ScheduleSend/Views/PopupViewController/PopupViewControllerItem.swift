//
//  PopupViewControllerItem.swift
//  iOS
//
//  Created by 张威 on 2020/1/9.
//

import UIKit

enum Popup {

    // MARK: Popup Offset

    /// `PopupOffset` 描述弹窗的漏出比例，有效值：0.0..<1.0
    /// 譬如 container contentHeight = 1000pt，offset = 0.3，则意味着当前弹窗内容高度为 300pt
    struct Offset: RawRepresentable, Comparable {
        var rawValue: CGFloat

        init(rawValue: CGFloat) {
            self.rawValue = max(min(1.0, rawValue), 0.0)
        }

        static func < (lhs: Offset, rhs: Offset) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        static let minimum = Offset(rawValue: 0.0)
        static let maximum = Offset(rawValue: 1.0)
        static let zero = Offset.minimum
        static let full = Offset.maximum
    }

    // MARK: Popup Const

    /// 弹窗相关常量
    struct Const {
        /// indicator View height
        static let indicatorHeight: CGFloat = 20.0
        /// 弹窗动画数值
        static let animationDuration: TimeInterval = 0.25
    }

    static var standardContentHeight: CGFloat {
        UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.height - Popup.Const.indicatorHeight - 24
    }
}

typealias PopupOffset = Popup.Offset

// MARK: PopupViewControllerItem

/// `PopupViewController` 容器的 item view controller
protocol PopupViewControllerItem: UIViewController {

    /// 描述支持的悬停高度，譬如：容器 contentHeight = 800pt；
    /// `[PopupOffset(rawValue: 0.4), PopupOffset(rawValue: 1.0)]` 则表示：
    /// 当前 VC 可以 320pt，800pt 这两个位置悬停，其他高度无法正常悬停
    var hoverPopupOffsets: [PopupOffset] { get }

    /// 描述当前 VC 所期待的高度，转场时，`PopupViewController` 会将当前 VC 切换到合适的高度
    var preferredPopupOffset: PopupOffset { get }

    /// 弹窗背景被点击，默认行为是：弹窗消失；可以自定义行为，譬如阻止弹窗消失
    func popupBackgroundDidClick()

    /// 弹窗交互手势（pan 手势）开始交互前，`PopupViewController` 调用该回调，VC 可以用以处理手势冲突逻辑
    func shouldBeginPopupInteracting(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool
}

// Default Implementations

extension PopupViewControllerItem {

    var hoverPopupOffsets: [PopupOffset] { [.full] }
    var preferredPopupOffset: PopupOffset { hoverPopupOffsets.last ?? .full }
    var viewController: UIViewController { self }

    func popupBackgroundDidClick() {
        popupViewController?.dismiss(animated: true, completion: nil)
    }

    func shouldBeginPopupInteracting(with interactivePopupGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }
}

extension PopupViewControllerItem {

    weak var popupViewController: PopupViewController? {
        viewController.parent as? PopupViewController
    }
}
