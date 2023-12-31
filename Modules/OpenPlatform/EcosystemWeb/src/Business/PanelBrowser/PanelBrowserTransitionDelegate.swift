//
//  PanelBrowserTransitionDelegate.swift
//  EcosystemWeb
//
//  Created by jiangzhongping on 2022/9/8.
//

import UIKit

class PanelBrowserTransitionDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PanelBrowserPresentAnimation()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PanelBrowserDismissAnimation()
    }
}

    
    
