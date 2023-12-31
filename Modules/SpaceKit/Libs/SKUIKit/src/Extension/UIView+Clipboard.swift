//
//  UIView+Clipboard.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/9/12.
//

import Foundation
import UIKit
import LarkSplitViewController
import SKFoundation

//单一文档复制粘贴控制协议
public protocol ClipboardProtectProtocol {
    ///获取返回文档token，这里的token需要和ClipboardService中写入的文档token一致
    func getDocumentToken() -> String?
}

extension UIView {
    
    public func getEncryptId() -> String? {
        //从superview和nextResponder和最上层控制器拿拿到文档token
        let currentToken = self.getEncryptIdFromSuperView()
        //通过文档token获取encryptId
        let encryptId = ClipboardManager.shared.getEncryptId(token: currentToken)
        return encryptId
    }
    
    private func getEncryptIdFromSuperView() -> String? {
        
        var next: UIView? = self
        while next != nil {
            
            if let curView = next as? ClipboardProtectProtocol {
                return curView.getDocumentToken()
            }
            let nextResponder = next?.next
            if let responder = nextResponder as? ClipboardProtectProtocol {
                return responder.getDocumentToken()
            }
            next = next?.superview
        }
        
        if let topVC = self.topMost(of: self.window?.rootViewController) {
            return topVC.getDocumentToken()
        }
        
        return nil
    }
    
    private func topMost(of viewController: UIViewController?) -> ClipboardProtectProtocol? {
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            if let checkController = selectedViewController as? ClipboardProtectProtocol {
                return checkController
            }
            return self.topMost(of: selectedViewController)
        }

        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.topViewController {
            if let checkController = visibleViewController as? ClipboardProtectProtocol {
                return checkController
            }
            return self.topMost(of: visibleViewController)
        }

        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            if let checkController = pageViewController.viewControllers?.first as? ClipboardProtectProtocol {
                return checkController
            }
            return self.topMost(of: pageViewController.viewControllers?.first)
        }

        // LKSplitViewController
        if let svc = viewController as? SplitViewController {
            if let checkController = svc.topMost as? ClipboardProtectProtocol {
                return checkController
            }
            return self.topMost(of: svc.topMost)
        }
        
        if let presentedViewController = viewController?.presentedViewController {
            if let checkController = presentedViewController as? ClipboardProtectProtocol {
                return checkController
            }
            return topMost(of: presentedViewController)
        }

        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                if let checkController = childViewController as? ClipboardProtectProtocol {
                    return checkController
                }
                return self.topMost(of: childViewController)
            }
        }

        return nil
    }
}
