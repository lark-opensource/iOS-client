//
//  UDActionSheet+Transition.swift
//  UniverseDesignActionPanel
//
//  Created by 白镜吾 on 2022/7/22.
//

import UIKit
import Foundation
import UniverseDesignColor
import UniverseDesignPopover

class UDActionSheetTransition: NSObject, UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate {
    /// 是否显示 Dimming 黑色背景
    var showDimmingView: Bool = true
    var dismissCompletion: (() -> Void)?

    lazy var dimmingView: UIView = {
        let dimmingView = UIView()
        dimmingView.backgroundColor = UDColor.bgMask
        return dimmingView
    }()

    init(dismissCompletion: (() -> Void)? = nil) {
        self.dismissCompletion = dismissCompletion
        super.init()
    }

    func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController) -> UIPresentationController? {
        let vc = UDDimmingPresentationController(presentedViewController: presented, presenting: presenting)
        vc.showDimmingView = showDimmingView
        vc.delegate = self
        return vc
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        UDPanelStylePresentationTransitioning()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        UDPanelStyleDismissalTransitioning()
    }
}
