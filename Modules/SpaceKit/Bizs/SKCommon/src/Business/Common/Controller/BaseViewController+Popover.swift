//
//  BaseViewController+Popover.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/10/17.
//  

import Foundation
import UniverseDesignColor
import SKUIKit

/// PopoverPresentationController
extension BaseViewController {
    /// Show Popover on a NavBar Button
    public func showPopover(to viewController: UIViewController,
                     at index: Int,
                     completion: (() -> Void)? = nil) {
        showPopover(to: viewController, at: index, isNewForm: false)
    }
    public func showPopover(to viewController: UIViewController,
                     at index: Int,
                     isNewForm: Bool,
                     completion: (() -> Void)? = nil) {
        let rightBtns = navigationBar.trailingButtons
        // rightButtons 是按倒序插入的
        let idx = index >= 0 ? (rightBtns.count - index - 1) : (-index - 1)
        if idx >= rightBtns.count {
            present(viewController, animated: true, completion: completion)
            return
        }
        let btnFrame = rightBtns[idx].convert(rightBtns[idx].bounds, to: navigationBar)

        viewController.modalPresentationStyle = .popover
        // 不要在这里统一设置 popoverPresentationController.backgroundColor, 原因是 more 面板不能设置此属性，各个调用方自己保证 or 通过布局处理
        viewController.popoverPresentationController?.sourceView = navigationBar
        viewController.popoverPresentationController?.sourceRect = CGRect(x: btnFrame.minX + btnFrame.width / 2, y: btnFrame.minY + btnFrame.height, width: 0, height: 0)
        if isNewForm {
            viewController.popoverPresentationController?.sourceRect = CGRect(x: btnFrame.minX + btnFrame.width / 2 + 25, y: btnFrame.minY + btnFrame.height + 30, width: 0, height: 0)
        }
        viewController.popoverPresentationController?.permittedArrowDirections = .up

        present(viewController, animated: true, completion: completion)
    }

    public func showPopover(panel: SKPanelController, at index: Int, completion: (() -> Void)? = nil) {
        let rightBtns = navigationBar.trailingButtons
        // rightButtons 是按倒序插入的
        let idx = index >= 0 ? (rightBtns.count - index - 1) : (-index - 1)
        if idx >= rightBtns.count {
            present(panel, animated: true, completion: completion)
            return
        }
        let btnFrame = rightBtns[idx].convert(rightBtns[idx].bounds, to: navigationBar)
        panel.transitioningDelegate = panel.panelTransitioningDelegate
        panel.modalPresentationStyle = .popover
        // 配置 iPad 场景 popover 降级为 overFullScreen or overCurrentContext 功能
        panel.presentationController?.delegate = panel.adaptivePresentationDelegate
        panel.popoverPresentationController?.backgroundColor = UDColor.bgFloat
        panel.popoverPresentationController?.permittedArrowDirections = .up
        panel.popoverPresentationController?.sourceView = navigationBar
        panel.popoverPresentationController?.sourceRect = CGRect(x: btnFrame.minX + btnFrame.width / 2, y: btnFrame.minY + btnFrame.height, width: 0, height: 0)
        present(panel, animated: true, completion: completion)
    }
    
    // 居中展示翻译语言选择面板
    public func translateShowPopover(panel: SKPanelController, completion: (() -> Void)? = nil) {
        panel.transitioningDelegate = panel.panelTransitioningDelegate
        panel.modalPresentationStyle = .popover
        // 配置 iPad 场景 popover 降级为 overFullScreen or overCurrentContext 功能
        panel.presentationController?.delegate = panel.adaptivePresentationDelegate
        panel.popoverPresentationController?.backgroundColor = UDColor.bgFloat
        panel.popoverPresentationController?.permittedArrowDirections = .up
        panel.popoverPresentationController?.sourceView = navigationBar
        // 居中展示
        panel.popoverPresentationController?.sourceRect = CGRect(x: navigationBar.frame.centerX, y: navigationBar.frame.maxY, width: 0, height: 0)
        present(panel, animated: true, completion: completion)
    }
    

    /// Obtain Popover Info on a NavBar Button
    public func obtainPopoverInfo(at index: Int) -> (sourceFrame: CGRect, direction: UIPopoverArrowDirection, sourceView: UIView)? {
        let rightBtns = navigationBar.trailingButtons
        // rightButtons 是按倒序插入的
        let idx = index >= 0 ? (rightBtns.count - index - 1) : (-index - 1)
        if idx >= rightBtns.count {
            return nil
        }
        let btnFrame = rightBtns[idx].convert(rightBtns[idx].bounds, to: navigationBar)
        return (btnFrame, .up, navigationBar)
    }
}
