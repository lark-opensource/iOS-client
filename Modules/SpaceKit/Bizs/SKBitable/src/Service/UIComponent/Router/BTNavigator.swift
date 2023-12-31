//
//  BTNavigator.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/7/26.
//  


import Foundation
import EENavigator
import SKUIKit
import UniverseDesignColor
import UniverseDesignActionPanel
import UIKit

final class BTNavigator {
    
    static func isReularSize(_ hostVC: UIViewController) -> Bool {
        return hostVC.isMyWindowRegularSize() && SKDisplay.pad
    }
    
    /// 打开特定控制器，并且嵌套在导航栏控制器中
    static func presentDraggableVCEmbedInNav(_ controller: BTDraggableViewController,
                                             from hostVC: UIViewController,
                                             completion: (() -> Void)? = nil) {
        
        let nav = SKNavigationController(rootViewController: controller)
        if isReularSize(hostVC) {
            nav.modalPresentationStyle = .formSheet
            nav.preferredContentSize = CGSize(width: 540, height: 620)
            nav.presentationController?.delegate = controller
        } else {
            nav.modalPresentationStyle = .overFullScreen
            nav.update(style: .clear)
            nav.transitioningDelegate = controller.panelTransitioningDelegate
            nav.delegate = controller.panelNavigationDelegate
        }
        Navigator.shared.present(nav, from: hostVC, completion: completion)
    }
    
    /// 打开特定控制器，并且嵌套在导航栏控制器中
    static func presentSKPanelVCEmbedInNav(_ controller: SKPanelController,
                                             from hostVC: UIViewController,
                                             completion: (() -> Void)? = nil) {
        
        let nav = SKNavigationController(rootViewController: controller)
        if isReularSize(hostVC) {
            nav.modalPresentationStyle = .formSheet
            nav.preferredContentSize = CGSize(width: 540, height: 620)
        } else {
            controller.updateLayoutWhenSizeClassChanged = false
            nav.modalPresentationStyle = .overFullScreen
            nav.update(style: .clear)
            nav.transitioningDelegate = controller.panelTransitioningDelegate
        }
        Navigator.shared.present(nav, from: hostVC, completion: completion)
    }
    
    /// 打开普通控制器，并且嵌套在导航栏控制器中
    static func presentVCEmbedInNav(_ controller: UIViewController,
                                             from hostVC: UIViewController,
                                             completion: (() -> Void)? = nil) {
        
        let nav = SKNavigationController(rootViewController: controller)
        if isReularSize(hostVC) {
            nav.modalPresentationStyle = .formSheet
            nav.preferredContentSize = CGSize(width: 540, height: 620)
        } else {
            nav.update(style: .clear)
        }
        if let controller = controller as? UIAdaptivePresentationControllerDelegate {
            nav.presentationController?.delegate = controller
        }
        Navigator.shared.present(nav, from: hostVC, completion: completion)
    }
    
    /// 在 ipad 下使用 pop actionSheet 的形式，需要业务放自己确保同时只有一个 didSelectedHandler
    static func presentActionSheetPage(with pageInfo: PoppverPageInfo,
                                didSelectedHandler: ((Int) -> Void)?,
                                didCancelHandelr: (() -> Void)? = nil) {
        let actionSheet = UDActionSheet.actionSheet(title: nil, popSource: pageInfo.popSource, dismissedByTapOutside: didCancelHandelr)
        for (index, item) in pageInfo.dataList.enumerated() {
            actionSheet.addItem(text: item.title, style: .default) {
                didSelectedHandler?(index)
            }
        }
        pageInfo.hostVC.present(actionSheet, animated: true, completion: nil)
        
    }
    
    /// 进行比较通用的 popver 设置
    static func setupPopover(_ controller: UIViewController,
                             sourceView: UIView,
                             sourceRect: CGRect,
                             contentSize: CGSize? = nil) {
        controller.modalPresentationStyle = .popover
        if let contentSize = contentSize {
            controller.preferredContentSize = contentSize
        }
        controller.popoverPresentationController?.backgroundColor = UDColor.bgBody
        controller.popoverPresentationController?.sourceView = sourceView
        controller.popoverPresentationController?.sourceRect = sourceRect
        controller.popoverPresentationController?.popoverLayoutMargins = .zero
        controller.popoverPresentationController?.permittedArrowDirections = [.up, .down]
    }
}
