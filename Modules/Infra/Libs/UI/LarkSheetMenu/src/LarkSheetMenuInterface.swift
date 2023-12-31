//
//  LarkSheetMenuDelegate.swift
//  LarkSheetMenu
//
//  Created by Zigeng on 2023/1/25.
//

import Foundation
import UIKit

public struct LarkSheetMenu {
    @discardableResult
    /// - Parameters:
    ///   - sourceView: 触发唤起菜单的UIView
    ///   - contentView: 触发唤起菜单的UIView的内容View
    ///   - partialRect: 部分选择状态下的触发区域,若不传则菜单根据trigger自动计算
    ///   - layout: 菜单组件的布局参数样式
    /// - Returns:  尝试展示成功后的菜单接口(LarkSheetMenuInterface)
    public static func getMenu(model vm: LarkSheetMenuViewModel,
                               delegate: SheetMenuLifeCycleDelegate? = nil,
                               trigger sourceView: UIView,
                               selected contentView: UIView?,
                               partialRect: (() -> CGRect?)? = nil,
                               layout: LarkSheetMenuLayout) -> LarkSheetMenuInterface {
        let interface: LarkSheetMenuInterface
        if UIDevice.current.userInterfaceIdiom == .pad {
            let menu = LarkSheetMenuPadController(vm: vm,
                                                  source: LarkSheetMenuSourceInfo(sourceView: sourceView, contentView: contentView, partialRect: partialRect),
                                                  layout: layout)
            menu.menuDelegate = delegate
            interface = menu
        } else {
            let menu = LarkSheetMenuPhoneController(vm: vm,
                                                    source: LarkSheetMenuSourceInfo(sourceView: sourceView, contentView: contentView, partialRect: partialRect),
                                                    layout: layout)
            menu.menuDelegate = delegate
            interface = menu
        }
        return interface
    }
}

public enum MenuVerticalOffset {
    case normalSizeBegin(CGFloat)
    case longSizeBegin(UIView)
    case move(CGFloat)
    case end
}

public protocol SheetMenuLifeCycleDelegate: AnyObject {
    /// 菜单高度发生偏移
    /// - Parameters:
    ///   - menuVC: LarkSheetMenuInterface
    ///   - offset: 菜单期望上层页面的垂直偏移量
    func suggestVerticalOffset(_ menuVC: LarkSheetMenuInterface, offset: MenuVerticalOffset)
    /// 菜单将要展开
    func menuWillExpand(_ menuVC: LarkSheetMenuInterface)
    /// 菜单将要展示
    func menuWillAppear(_ menuVC: LarkSheetMenuInterface)
    /// 菜单已经展示
    func menuDidAppear(_ menuVC: LarkSheetMenuInterface)
    /// 菜单将要dismiss
    func menuWillDismiss(_ menuVC: LarkSheetMenuInterface)
    /// 菜单已经dismiss
    func menuDidDismiss(_ menuVC: LarkSheetMenuInterface)
}

public extension SheetMenuLifeCycleDelegate {
    func suggestVerticalOffset(_ menuVC: LarkSheetMenuInterface, offset: MenuVerticalOffset) { }
    func menuWillExpand(_ menuVC: LarkSheetMenuInterface) { }
    func menuWillAppear(_ menuVC: LarkSheetMenuInterface) { }
    func menuDidAppear(_ menuVC: LarkSheetMenuInterface) { }
    func menuWillDismiss(_ menuVC: LarkSheetMenuInterface) { }
    func menuDidDismiss(_ menuVC: LarkSheetMenuInterface) { }
}

public protocol LarkSheetMenuInterface: UIViewController {
    /// 获取触发View
    var triggerView: UIView { get }
    /// 设置触控是否可以穿透
    var enableTransmitTouch: Bool { get set }
    /// 设置是否使用下层响应手势 如果返回 true 则 menuVC 不会响应 hittest
    var handleTouchArea: ((CGPoint, UIViewController) -> Bool)? { get set }
    /// 返回响应 hitTest 的 view
    var handleTouchView: ((CGPoint, UIViewController) -> UIView?)? { get set }
    /// 指定菜单的父VC并展示
    func show(in vc: UIViewController)
    /// 隐藏菜单
    func hide(animated: Bool, completion: ((Bool) -> Void)?)
    /// 更新菜单的数据源
    func updateMenuWith(_ data: [LarkSheetMenuActionSection]?, willShowInPartial: Bool?)
    /// 显示菜单(隐藏后重新展示)
    func showMenu(animated: Bool)
    /// 切换至菜单{更多}页面
    func switchToMoreView()
    /// 隐藏并销毁菜单
    func dismiss(completion: (() -> Void)?)
}

public protocol LarkSheetMenuLayout {
    /// 顶部热区"-"至菜单顶端高度 默认值为8
    var hotZoneSpace: CGFloat { get }
    /// Header高度(eg.emoji bar高度) 默认值为0
    var headerHeight: CGFloat { get }
    /// 每个按钮的最小高度 默认值为48, 折行后会自动增加
    var cellHeight: CGFloat { get }
    /// 不同按钮分组间的间距 默认值为12
    var sectionInterval: CGFloat { get }
    /// 折叠时菜单 Sheet 展示高度 默认值为屏幕高度48%
    var foldSheetHeight: CGFloat { get }
    /// 展开后Sheet可达到的高度 默认值为屏幕高度70%
    var expandedSheetHeight: CGFloat { get }
    /// Popover 状态的Frame
    func popoverSize(_ traitCollection: UITraitCollection, containerSize: CGSize) -> CGSize
    /// Popover 状态箭头大小 不可更改
    var popoverArrowSize: CGSize { get }
    /// More界面最大高度 默认值为屏幕高度70%
    var moreViewMaxHeight: CGFloat { get }
    /// 部分选择态悬浮菜单的上下间距
    var partialTopAndBottomMargin: CGFloat { get }
    /// 顶部安全间距
    var topPadding: CGFloat { get }
    /// popover距屏幕安全间距
    var popoverSafePadding: CGFloat { get }
    /// 消息底部与菜单顶部最小距离 默认值话题群为0 其他场景为10
    var messageOffset: CGFloat { get }

    func updateLayout(sectionCount: Int, itemCount: Int, header: LarkSheetMenuHeader) -> LarkSheetMenuLayout
}
