//
//  OPRenderSlot.swift
//  OPSDK
//
//  Created by yinyuan on 2020/10/27.
//

import Foundation

/// 视图渲染协议
@objc public protocol OPRenderSlotDelegate: NSObjectProtocol {
    
    /// Render 已经添加到 Slot 上
    func onRenderAttatched(renderSlot: OPRenderSlotProtocol)

    /// Render 从 Slot 上移除
    func onRenderRemoved(renderSlot: OPRenderSlotProtocol)
    
    /// 获取当前用于 present 的 ViewController
    func currentViewControllerForPresent() -> UIViewController?
    
    /// 获取当前用于 push 的 NavigationController
    func currentNavigationControllerForPush() -> UINavigationController?
}

/// 渲染层协助显示错误提示界面
@objc public protocol OPRenderSlotFailedViewUIDelegate: AnyObject {
    func showFailedView(with tipInfo: String, context: OPContainerContext)
}

@objc public protocol OPRenderSlotProtocol {
    
    // 所在 window 用于支持 iPad 多 scene
    var window: UIWindow? { get }
    
    var delegate: OPRenderSlotDelegate? { get set}
    
    var hidden: Bool { get set }
}

@objcMembers
public final class OPViewRenderSlot: NSObject, OPRenderSlotProtocol {
    
    /// Slot View
    public weak var view: UIView?
    
    public var delegate: OPRenderSlotDelegate?
    
    /// 只能模块内部可以修改这个属性，外部不允许修改
    public var hidden: Bool
    
    public var window: UIWindow? {
        get {
            return view?.window
        }
    }

    /// 初始化方法
    /// - Parameters:
    ///   - view: 弱引用当前的 view
    ///   - defaultHidden: 当前 view 是否是 hidden 状态
    public init(view: UIView, defaultHidden: Bool) {
        self.view = view
        self.hidden = defaultHidden
    }
}

@objcMembers
public final class OPUniversalPushControllerRenderSlot: NSObject, OPRenderSlotProtocol {

    public var delegate: OPRenderSlotDelegate?

    /// 只能模块内部可以修改这个属性，外部不允许修改
    public var hidden: Bool

    public var window: UIWindow?

    public init(window: UIWindow?, defaultHidden: Bool) {
        self.window = window
        self.hidden = defaultHidden
    }
}

@objcMembers
public final class OPPushControllerRenderSlot: NSObject, OPRenderSlotProtocol {
    
    /// Slot Controller
    public let navigationController: UINavigationController
    
    public var delegate: OPRenderSlotDelegate?
    
    /// 只能模块内部可以修改这个属性，外部不允许修改
    public var hidden: Bool
    
    public var window: UIWindow? {
        get {
            return navigationController.view.window
        }
    }

    public init(navigationController: UINavigationController, defaultHidden: Bool) {
        self.navigationController = navigationController
        self.hidden = defaultHidden
    }
}

@objcMembers
public final class OPPresentControllerRenderSlot: NSObject, OPRenderSlotProtocol {
    
    /// Slot Controller
    public let presentingViewController: UIViewController
    
    public var delegate: OPRenderSlotDelegate?
    
    /// 只能模块内部可以修改这个属性，外部不允许修改
    public var hidden: Bool
    
    public var window: UIWindow? {
        get {
            return presentingViewController.view.window
        }
    }

    public init(presentingViewController: UIViewController, defaultHidden: Bool) {
        self.presentingViewController = presentingViewController
        self.hidden = defaultHidden
    }
}

@objcMembers
public final class OPXScreenControllerRenderSlot: NSObject, OPRenderSlotProtocol {
    
    /// Slot Controller
    public let presentingViewController: UIViewController
    
    public var delegate: OPRenderSlotDelegate?
    
    /// 仅限于模块内部可以修改这个属性，请勿随意修改
    public var hidden: Bool
    
    public var window: UIWindow? {
        get {
            return presentingViewController.view.window
        }
    }

    public init(presentingViewController: UIViewController, defaultHidden: Bool) {
        self.presentingViewController = presentingViewController
        self.hidden = defaultHidden
    }
}


@objcMembers
public final class OPChildControllerRenderSlot: NSObject, OPRenderSlotProtocol {
    
    /// Slot Controller
    public let parentViewController: UIViewController
    
    public weak var delegate: OPRenderSlotDelegate?

    /// 子控制器插槽需要自己来实现错误提示界面
    public weak var failedViewUIDelegate: OPRenderSlotFailedViewUIDelegate?
    
    /// 只能模块内部可以修改这个属性，外部不允许修改
    public var hidden: Bool
    
    public var window: UIWindow? {
        get {
            return parentViewController.view.window
        }
    }

    public init(parentViewController: UIViewController, defaultHidden: Bool) {
        self.parentViewController = parentViewController
        self.hidden = defaultHidden
    }
}

/// 按照 renderSlot 协议绑定视图
/// - Parameter renderSlot: renderSlot
/// - Parameter controller: 要加载的VC
/// - Parameter container: container
/// - Returns: 是否完成绑定
public typealias OPCustomBindViewControllerBlock = (_ renderSlot: OPCustomControllerRenderSlot, _ controller: UIViewController, _ container: OPContainerProtocol) -> Bool

/// 取消 renderSlot 协议的视图绑定
/// - Parameter renderSlot: renderSlot
/// - Parameter controller: 要卸载的VC
/// - Parameter container: container
/// - Returns: 是否已取消绑定
public typealias OPCustomUnbindViewControllerBlock = (_ renderSlot: OPCustomControllerRenderSlot, _ controller: UIViewController, _ container: OPContainerProtocol) -> Bool


/// 完全由业务定制 VC 加载方法的协议
@objcMembers public final class OPCustomControllerRenderSlot: NSObject, OPRenderSlotProtocol {
    
    public weak var delegate: OPRenderSlotDelegate?
    
    public let bindViewControllerBlock: OPCustomBindViewControllerBlock
    
    public let unbindViewControllerBlock: OPCustomUnbindViewControllerBlock
    
    /// 只能模块内部可以修改这个属性，外部不允许修改
    public var hidden: Bool
    
    public private(set) weak var window: UIWindow?

    public init(window: UIWindow?, bindViewControllerBlock: @escaping OPCustomBindViewControllerBlock, unbindViewControllerBlock: @escaping OPCustomUnbindViewControllerBlock, defaultHidden: Bool) {
        self.window = window
        self.hidden = defaultHidden
        self.bindViewControllerBlock = bindViewControllerBlock
        self.unbindViewControllerBlock = unbindViewControllerBlock
    }
}

extension OPRenderSlotProtocol {
    
    func onRenderAttatched(renderSlot: OPRenderSlotProtocol) {}

    func onRenderRemoved(renderSlot: OPRenderSlotProtocol) {}
    
    func currentViewControllerForPresent() -> UIViewController? { nil }
    
    func currentNavigationControllerForPush() -> UINavigationController? { nil }
}
