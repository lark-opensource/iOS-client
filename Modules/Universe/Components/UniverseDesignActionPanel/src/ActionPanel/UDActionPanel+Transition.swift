//
//  UDActionPanel+Transition.swift
//  UniverseDesignActionPanel
//
//  Created by 姚启灏 on 2020/11/4.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignPopover

class UDActionPanelTransition: NSObject, UIViewControllerTransitioningDelegate {
    
    lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = UDColor.bgMask
        return dimmingView
    }()

    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController)
        -> UIPresentationController? {
            let presentationVC = UDDimmingPresentationController(presentedViewController: presented,
                                                                 presenting: presenting)
            presentationVC.autoTransformPresentationStyle = true
            return presentationVC
    }

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {
            if let horizontalSizeClass = presenting.view.superview?.traitCollection.horizontalSizeClass,
               horizontalSizeClass == .regular {
                return nil
            } else {
                return UDPanelStylePresentationTransitioning()
            }
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return nil
    }
}
