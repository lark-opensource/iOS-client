//
//  MessageMenuService.swift
//  LarkOpenChat
//
//  Created by Zigeng on 2023/1/21.
//

import Foundation
import LarkModel
import UIKit
import LarkMessageBase

public enum MessageMenuHiddenStateTriggerAction {
    case scrollStopeed
    case cursorDragged
}
public protocol MessageMenuOpenService: AnyObject {
    /// 获取当前的菜单触发triggerView
    var currentTriggerView: UIView? { get }
    /// 消息菜单生命周期代理
    var delegate: MessageMenuServiceDelegate? { get set }
    /// 光标区域,部分选择菜单调整位置时使用
    var currentSelectedRect: (() -> CGRect?)? { get set }
    /// 是否是列表Menu即新菜单
    var isSheetMenu: Bool { get }

    /// 是否有正在展示的Menu
    var hasDisplayMenu: Bool { get }

    /// 当前选中消息
    var currentMessage: Message? { get }
    /// 当前菜单触发Component信息
    var currentComponentKey: String? { get }
    /// 当前菜单的选中类型
    var currentCopyType: CopyMessageType? { get }
    /// 更新消息菜单消息选中状态
    func updateMenuSelectInfo(_ selectType: CopyMessageSelectedType)
    /// 展示消息菜单
    func showMenu(message: Message,
                  source: MessageMenuLayoutSource,
                  extraInfo: MessageMenuExtraInfo)
    /// 隐藏消息菜单(只有在菜单动画结束后调用才会有效果)
    func hideMenuIfNeeded(animated: Bool)
    /// 重新展示消息菜单(若triggerView超出屏幕返回,将不会再次展示,而是会直接Dismiss)
    func unhideMenuIfNeeded(animated: Bool)
    /// 销毁消息菜单
    func dissmissMenu(completion: (() -> Void)?)
}

/// 消息菜单服务-触控管理
public protocol MenuTouchTestInterface: AnyObject {
    // 下层是否直接响应手势 如果返回 true 则 menuVC 不会响应 hittest
    var handleTouchArea: ((CGPoint, UIViewController) -> Bool)? { get set }
    // 返回响应 hitTest 的 view
    var handleTouchView: ((CGPoint, UIViewController) -> UIView?)? { get set }
    // 是否可以把触摸传递到下一层视图
    var enableTransmitTouch: Bool { get set }
}

public class DefaultMessageMenuOpenService: MessageMenuOpenService {

    public var isSheetMenu: Bool { false }
    public var hasDisplayMenu: Bool { false }
    public var currentSelectedRect: (() -> CGRect?)?
    public var currentCopyType: CopyMessageType?
    public var currentTriggerView: UIView?
    public var delegate: MessageMenuServiceDelegate?
    public var currentMessage: Message?
    public var currentComponentKey: String?
    public func updateMenuSelectInfo(_ selectType: CopyMessageSelectedType) { }
    public func showMenu(message: Message,
                         source: MessageMenuLayoutSource,
                         extraInfo: MessageMenuExtraInfo) { }
    public func hideMenuIfNeeded(animated: Bool) { }
    public func unhideMenuIfNeeded(animated: Bool) { }
    public func dissmissMenu(completion: (() -> Void)?) { }
    public init() {
    }
}

public enum MessageMenuVerticalOffset {
    case normalSizeBegin(CGFloat)
    case longSizeBegin(UIView)
    case move(CGFloat)
    case end
}

/// 消息菜单服务-生命周期代理
public protocol MessageMenuServiceDelegate: AnyObject {

    /// 长按消息, 将要load菜单
    /// - Parameters:
    ///   - menuService: 消息菜单服务
    ///   - message: 长按唤起菜单的对应消息
    ///   - componentConstant: 长按消息的 Cell Component 特征值
    /// - Returns: 期待展示的光标Rect
    func messageMenuWillLoad(_ menuService: MessageMenuOpenService, message: Message, componentConstant: String?)

    /// 菜单VC已初始化
    /// - Parameters:
    ///   - menuService: MessageMenuOpenService
    ///   - message: 长按唤起菜单的对应消息
    ///   - touchTest: MenuViewController的触控管理相关参数
    func messageMenuDidLoad(_ menuService: MessageMenuOpenService, message: Message, touchTest: MenuTouchTestInterface)

    /// 菜单VC Will Appear
    /// - Parameter menuService: 消息菜单服务
    func messageMenuWillAppear(_ menuService: MessageMenuOpenService)

    /// 菜单VC Did Appear
    /// - Parameter menuService: 消息菜单服务
    func messageMenuDidAppear(_ menuService: MessageMenuOpenService)

    /// 新版Sheet样式菜单高度发生改变
    func offsetTableView(_ menuService: MessageMenuOpenService, offset: MessageMenuVerticalOffset)

    /// 菜单VC Will Dismiss
    /// - Parameter menuService: 消息菜单服务
    func messageMenuWillDismiss(_ menuService: MessageMenuOpenService)

    /// 菜单VC Did Dismiss
    /// - Parameter menuService: 消息菜单服务
    func messageMenuDidDismiss(_ menuService: MessageMenuOpenService)
}

extension MessageMenuServiceDelegate {
    public func messageMenuWillLoad(_ menuService: MessageMenuOpenService,
                                    message: Message,
                                    componentConstant: String?) { }
    public func messageMenuDidLoad(_ menuService: MessageMenuOpenService,
                                   message: Message,
                                   touchTest: MenuTouchTestInterface) { }
    public func messageMenuWillAppear(_ menuService: MessageMenuOpenService) { }
    public func messageMenuDidAppear(_ menuService: MessageMenuOpenService) { }
    public func offsetTableView(_ menuService: MessageMenuOpenService, offset: MessageMenuVerticalOffset) { }
    public func messageMenuWillDismiss(_ menuService: MessageMenuOpenService) { }
    public func messageMenuDidDismiss(_ menuService: MessageMenuOpenService) { }
}

/// 消息菜单展示位置
public struct MessageMenuLayoutSource {
    // 触发 menu 的 view， eg： 长按唤出菜单的 message bubble cell
    public let trigerView: UIView
    // 触发 menu point，是相对于 trigerView 的相对位置，eg: 长按手势对于 message bubble cell 的相对位置
    public let trigerLocation: CGPoint?
    // 返回不可以被遮挡的view, 参数 uiview 为 trigerView, eg: 例如 chat 列表中支持区域copy的label
    public let displayViewBlcok: ((Bool) -> UIView?)?
    // 间距
    public let inserts: UIEdgeInsets
    //
    public let triggerGesture: UIGestureRecognizer?

    public init(
        trigerView: UIView,
        trigerLocation: CGPoint?,
        triggerGesture: UIGestureRecognizer? = nil,
        displayViewBlcok: ((Bool) -> UIView?)? = nil,
        inserts: UIEdgeInsets
    ) {
        self.trigerView = trigerView
        self.trigerLocation = trigerLocation
        self.triggerGesture = triggerGesture
        self.displayViewBlcok = displayViewBlcok
        self.inserts = inserts
    }
}

public struct MessageMenuExtraInfo {
    public let isNewLayoutStyle: Bool
    public let copyType: CopyMessageType
    public let selectConstraintKey: String?
    public let isOpen: Bool
    // 菜单弹起时消息底部与菜单顶部的偏移量 话题群 0 其他场景10
    public let messageOffset: CGFloat
    /// 透传到LarkSheetMenuLayout，控制展开时最大的高度，默认值保持和线上一致
    public let expandedSheetHeight: CGFloat
    public let moreViewMaxHeight: CGFloat

    public init(
        isNewLayoutStyle: Bool = true,
        copyType: CopyMessageType,
        selectConstraintKey: String?,
        isOpen: Bool = true,
        messageOffset: CGFloat = 10,
        expandedSheetHeight: CGFloat = UIScreen.main.bounds.size.height * CGFloat(0.91),
        moreViewMaxHeight: CGFloat = UIScreen.main.bounds.size.height * CGFloat(0.91)
    ) {
        self.copyType = copyType
        self.selectConstraintKey = selectConstraintKey
        self.isOpen = isOpen
        self.isNewLayoutStyle = isNewLayoutStyle
        self.messageOffset = messageOffset
        self.expandedSheetHeight = expandedSheetHeight
        self.moreViewMaxHeight = moreViewMaxHeight
    }
}
