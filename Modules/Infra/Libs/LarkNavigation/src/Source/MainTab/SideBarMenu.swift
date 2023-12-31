//
//  SideBarMenu.swift
//  LarkNavigation
//
//  Created by kangsiwan on 2021/3/24.
//

import Foundation
import UIKit
import EENavigator
import LarkKeyboardKit
import LKCommonsLogging
import UniverseDesignDrawer
import LarkUIKit
import LarkTab
import LKCommonsTracker
import Homeric
import LarkContainer

public protocol SideBarAbility: UIViewController {
    func hideSideBar(animate: Bool, completion: (() -> Void)?)
}

public extension SideBarAbility {
    // 隐藏“我的”主页
    func hideSideBar(animate: Bool, completion: (() -> Void)?) {
        findAndHideSideBar(animate: animate, completion: completion)
    }
}

private extension UIViewController {
    func findAndHideSideBar(animate: Bool, completion: (() -> Void)?) {
        if let rootVC = findRootNavigationController(fromViewController: self) {
            // 调用sideBarMenu的hide方法，内部会判断是侧滑还是popover
            rootVC.tabbar?.sideBarMenu.hideSideBar(animate: animate, completion: completion)
        }
    }

    // 希望找到RootNavigationController，找不到返回nil
    private func findRootNavigationController(fromViewController: UIViewController) -> RootNavigationController? {
        var parentVC: UIViewController? = fromViewController
        while let currentVC = parentVC {
            if let rootVC = currentVC as? RootNavigationController {
                return rootVC
            }
            parentVC = currentVC.parent
            if parentVC == nil {
                parentVC = currentVC.presentingViewController
            }
        }
        return nil
    }
}

extension SideBarMenu {
    enum SideBarType {
        case popover
        case slide
    }

    enum PopoverShowStatus {
        case show(popoverController: UIViewController)
        case hide
    }
}

public weak var currentSideBarMenu: SideBarMenu?

protocol SideTabbarViewController: UIViewController, UserResolverWrapper {
    var curTab: Tab? { get }
}

public final class SideBarMenu: UIViewController {
    var userResolver: UserResolver? { mainTabbar?.userResolver }
    public weak var currentSubVC: SideBarViewController?
    private static let logger = Logger.log(SideBarMenu.self, category: "Source.MainTab")
    private weak var mainTabbar: SideTabbarViewController?
    private lazy var transitionManager: UDDrawerTransitionManager = UDDrawerTransitionManager(host: self)
    // 持有已展示的popover
    private weak var popover: UIViewController?
    // popover是否在展示
    private var isShowPopover: Bool = false
    // 设置popover状态
    private var popoverStatus: PopoverShowStatus = .hide {
        didSet {
            SideBarMenu.logger.info("popoverStatus has changed: \(popoverStatus)")
            switch popoverStatus {
            case .hide:
                popover = nil
                isShowPopover = false
            case .show(popoverController: let vc):
                popover = vc
                isShowPopover = true
            }
        }
    }

    // 外部调用，切换状态
    var showType: SideBarType {
        get { changeShowType }
        set {
            guard newValue != changeShowType else { return }
            changeShowType = newValue
        }
    }

    private var changeShowType: SideBarType = .slide {
        didSet {
            SideBarMenu.logger.info("chang showType to \(changeShowType)")
            // 状态变化了调用dismiss
            hideSideBar(animate: false, completion: nil)
            // 更新边缘滑动手势激活态
            if changeShowType == .popover {
                updateDrawerEdgeGesture(isEnable: false)
            } else {
                updateDrawerEdgeGesture(isEnable: true)
            }
        }
    }

    // 个人主页是否在展示
    var isSideBarShow: Bool {
        return isShowPopover || transitionManager.isDrawerShown
    }

    init(mainTabbar: SideTabbarViewController) {
        self.mainTabbar = mainTabbar
        super.init(nibName: nil, bundle: nil)

        currentSideBarMenu = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 展示个人主页
    // 根据showStatus状态展示不同,展示不同的modalPresentationStyle
    public func showSideBar(avatarView: UIView?, completion: (() -> Void)?) {
        SideBarMenu.logger.info("showSideBar with type: \(changeShowType)")
        switch changeShowType {
        case .popover:
            guard let subVC = subVC, let avatarView = avatarView else {
                return
            }
            subVC.modalPresentationStyle = .popover
            // popover 的 preferredContentSize 在 SideBarViewController 内部控制，此处不再控制
            subVC.popoverPresentationController?.sourceView = avatarView
            subVC.popoverPresentationController?.sourceRect = CGRect(x: avatarView.bounds.width / 2, y: avatarView.bounds.height, width: 0, height: 0)
            subVC.popoverPresentationController?.permittedArrowDirections = .up
            subVC.popoverPresentationController?.delegate = self
            KeyboardKit.shared.firstResponder?.resignFirstResponder() // 防止键盘过高使 Popover 过矮
            fromVC?.present(subVC, animated: true, completion: {
                self.popoverStatus = .show(popoverController: subVC)
                completion?()
            })
        case .slide:
            self.transitionManager.showDrawer(completion: completion)
        }
    }

    public func showDrawer(_ type: UDDrawerTriggerType, completion: (() -> Void)?) {
        self.transitionManager.showDrawer(type, completion: completion)
    }

    // 更新侧滑栏的宽度
    func updateWidth() {
        guard changeShowType == .slide else {
            return
        }
        transitionManager.updateDrawerWidth()
    }

    // 添加侧滑手势
    func addDrawerEdgeGesture(to: UIView) {
        transitionManager.addDrawerEdgeGesture(to: to)
    }

    // 更新侧滑手势状态
    func updateDrawerEdgeGesture(isEnable: Bool) {
        transitionManager.updateGestureEnable(isEnable: isEnable)
    }

    // 收回个人主页
    func hideSideBar(animate: Bool, completion: (() -> Void)?) {
        if isShowPopover {
            // 如果是展示
            self.popover?.dismiss(animated: animate, completion: completion)
            self.popoverStatus = .hide
        } else if transitionManager.isDrawerShown {
            // 如果是抽屉在展示
            transitionManager.hideDrawer(animate: animate, completion: completion)
        }
    }
}

extension SideBarMenu: UDDrawerAddable {
    public var fromVC: UIViewController? {
        return mainTabbar
    }

    public var contentWidth: CGFloat {
        return (mainTabbar?.view.frame.width ?? UDDrawerValues.contentDefaultWidth) * UDDrawerValues.contentDefaultPercent
    }

    public var customContentWidth: ((UDDrawerTriggerType) -> CGFloat?)? {
        return { [weak self] type -> CGFloat? in
            guard let self else { return nil }

            let width = (self.mainTabbar?.view.frame.width ?? UDDrawerValues.contentDefaultWidth)

            if let tabbar = self.mainTabbar, let curTab = tabbar.curTab,
               let source = SideBarMenuSourceFactory.source(for: curTab),
               let contentPercent = try? source.contentPercentProvider(tabbar.userResolver, type) {
                return width * contentPercent
            }

            return width * UDDrawerValues.contentDefaultPercent
        }
    }

    public var subVC: UIViewController? {
        let body = SideBarBody(hostProvider: mainTabbar)
        let result = Navigator.shared.response(for: body).resource as? UIViewController
        self.currentSubVC = result as? SideBarViewController
        return result
    }

    public var subCustomVC: ((UDDrawerTriggerType) -> UIViewController?)? {
        return { [weak self] type in
            guard let self = self else { return nil }

            if let tabbar = self.mainTabbar, let curTab = tabbar.curTab,
               let source = SideBarMenuSourceFactory.source(for: curTab) {
                return try? source.subCustomVCProvider(tabbar.userResolver, type, tabbar)
            }

            self.viewTrack(type)

            let body = SideBarBody(hostProvider: self.mainTabbar)
            let result = Navigator.shared.response(for: body).resource as? UIViewController
            self.currentSubVC = result as? SideBarViewController
            return result
        }
    }

    public var direction: UDDrawerDirection {
        return .left
    }
}

extension SideBarMenu: UIPopoverPresentationControllerDelegate {
    // 系统方法，点击其他区域收回popover，会调用此方法
    public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        self.popoverStatus = .hide
    }
}

extension SideBarMenu {
    private func viewTrack(_ type: UDDrawerTriggerType) {
        var evokeType: String
        switch type {
        case .click(_):
            evokeType = "click"
        case .pan:
            evokeType = "slide"
        }
        var belongedTab = "unknown"
        if let mainTabbar = mainTabbar as? MainTabbarController {
            switch mainTabbar.selectedTab {
            case .feed:         belongedTab = "im"
            case .calendar:     belongedTab = "cal"
            case .appCenter:    belongedTab = "platform"
            case .doc:          belongedTab = "doc"
            case .mail:         belongedTab = "email"
            case .contact:      belongedTab = "contact"
            case .byteview:     belongedTab = "vc"
            case .todo:         belongedTab = "todo"
            case .moment:       belongedTab = "moments"
            case .wiki:         belongedTab = "wiki"
            default:
                break
            }
        }
        Tracker.post(TeaEvent(Homeric.SETTING_MAIN_VIEW,
                              params: ["evoke_type": evokeType,
                                       "belonged_tab": belongedTab]))
    }
}
