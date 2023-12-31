//
//  OpenPluginMenuManager.swift
//  OPPlugin
//
//  Created by laisanpin on 2021/7/14.
//  UIMenuController管理对象

import Foundation
import ECOProbe
import LarkOpenAPIModel

/// UIMenuController显示状态;
enum OPMenuState {
    case willShow
    case didShow
    case willHide
    case didHide
}

/// UIMenuController显示状态变化Block
typealias OPMenuStateChangeBlock = (_ state: OPMenuState) -> Void

/// 要呈现UIMenuController需要实现的协议
public protocol OpenPluginMenuProtocol: UIResponder {

    /// 当前拥有的MenuItem对应的Action数组;
    var actionHelper: [Selector] { get set }

    /// 构建UIMenuItem方法
    func opMenuItem(uid: String, title: String, action: @escaping () -> Void) -> UIMenuItem
}

struct OpenPluginMenuMangerConfig {
    weak var targetView: UIView?
    weak var container: OpenPluginMenuProtocol?
}

final class OpenPluginMenuManager: NSObject {

    let trace: OPTrace

    /// 构造参数
    var config: OpenPluginMenuMangerConfig

    /// UIMenuController显示状态变化Block
    var menuStateChangeCallback: OPMenuStateChangeBlock?

    public func showMenu(in targetRect: CGRect,
                         items menuItems:[UIMenuItem],
                         offsetTop: CGFloat = 0.0,
                         offsetBottom: CGFloat = 0.0) -> Bool {
        guard let targetView = config.targetView else {
            trace.error("config targetView is nil")
            return false
        }

        guard let container = config.container else {
            trace.error("config container is nil")
            return false
        }

        return showMenu(view: targetView,
                        container: container,
                        rect: targetRect,
                        items: menuItems,
                        offsetTop: offsetTop,
                        offsetBottom: offsetBottom)
    }

    public func showMenu(view targetView: UIView,
                         container: OpenPluginMenuProtocol,
                         rect targetRect: CGRect,
                         items menuItems:[UIMenuItem],
                         offsetTop: CGFloat = 0.0,
                         offsetBottom: CGFloat = 0.0) -> Bool {
        trace.info("show popoverMenu rect:\(targetRect), itemsCount:\(menuItems.count), offsetTop:\(offsetTop), offsetBottom:\(offsetBottom)")
        addMenuObserver()
        //确保container是firstResponder;防止UIMenuController弹不出来
        container.becomeFirstResponder()
        let menu = UIMenuController.shared
        var rectInWindow = targetRect

        // PopoverMenu控件的高度
        let menuHeight: CGFloat = 100.0

        // 前端控件底部的y坐标
        let rectBottom = rectInWindow.minY + rectInWindow.height

        // 控件上方没有足够空间显示menu
        let topSpaceNotEnough = (rectInWindow.minY - offsetTop) < menuHeight

        // 控件下方没有足够空间显示menu
        let bottomSpaceNotEnough = (rectBottom + offsetBottom + menuHeight) > targetView.bounds.size.height

        // 控件上方没有足够距离则将menu显示在控件下方
        if (topSpaceNotEnough) {
            menu.arrowDirection = .up
        } else {
            menu.arrowDirection = .default
        }

        // 控件上下都没有足够距离(控件超过屏幕高度)显示menu, 则设置menu显示在中间
        if topSpaceNotEnough && bottomSpaceNotEnough {
            menu.arrowDirection = .default
            rectInWindow.origin.y = targetView.bounds.size.height / 2
        }

        setContainerMenuItems(menuItems: menuItems)
        menu.menuItems = menuItems

        if #available(iOS 13, *) {
            menu.showMenu(from: targetView, rect: rectInWindow)
        } else {
            menu.setTargetRect(rectInWindow, in: targetView)
            menu.setMenuVisible(true, animated: true)
        }
        return true
    }

    public func hideMenu() -> Bool {
        guard let targetView = config.targetView else {
            trace.error("config targetView is nil")
            return false
        }

        let menu = UIMenuController.shared
        menu.arrowDirection = .default
        trace.info("hide popoverMenu")
        if #available(iOS 13, *) {
            menu.hideMenu(from: targetView)
        } else {
            menu.setMenuVisible(false, animated: true)
        }
        return true
    }

    public func makeMenuItem(id: String, title: String, action: @escaping ()->Void) -> UIMenuItem? {
        guard let container = config.container else {
            trace.error("config container is nil")
            return nil
        }
        trace.info("make menu item with id:\(id)")
        return container.opMenuItem(uid: id, title: title, action: action)
    }

    public func setContainerMenuItems(menuItems: [UIMenuItem]) {
        guard let container = config.container else {
            trace.error("config container is nil")
            return
        }

        container.actionHelper = menuItems.map {
            $0.action
        }
    }

    init(_ config: OpenPluginMenuMangerConfig, _ trace: OPTrace?) {
        self.config = config
        self.trace = trace ?? OPTraceService.default().generateTrace()
    }
}

extension OpenPluginMenuManager {
    /// 添加UIMenuController的监听; 注意: UIMenuController是单例, 要注意其他地方使用该对象时产生的通知;
    private func addMenuObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(menuWillShow), name: UIMenuController.willShowMenuNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidShow), name: UIMenuController.didShowMenuNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuWillHide), name: UIMenuController.willHideMenuNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(menuDidHide), name: UIMenuController.didHideMenuNotification, object: nil)
    }

    /// 移除UIMenuController监听; 当menuDidHide的时后移除监听
    private func removeMenuObserver() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func menuWillShow() {
        menuStateChangeCallback?(.willShow)
    }

    @objc private func menuDidShow() {
        menuStateChangeCallback?(.didShow)
    }

    @objc private func menuWillHide() {
        menuStateChangeCallback?(.willHide)
    }

    @objc private func menuDidHide() {
        menuStateChangeCallback?(.didHide)
        //重置arrowDirection, 防止影响其他处使用;
        UIMenuController.shared.arrowDirection = .default
        //防止其他地方使用UIMenuController影响这边;
        removeMenuObserver()
    }
}
