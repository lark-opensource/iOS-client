//
//  NavigationController.swift
//  ByteView
//
//  Created by kiri on 2020/7/21.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignColor

open class NavigationController: UINavigationController {
    private let popGestureRecognizerHandler = PopGestureRecognizerHandler()

    public var interactivePopDisabled: Bool = false

    public override func viewDidLoad() {
        super.viewDidLoad()
        guard let targets = interactivePopGestureRecognizer?.value(forKey: "_targets") as? [AnyObject],
            let target = targets[0].value(forKey: "target") else {
                return
        }
        let popGestureRecognizer = UIPanGestureRecognizer()
        popGestureRecognizer.maximumNumberOfTouches = 1
        popGestureRecognizerHandler.navigationController = self
        popGestureRecognizer.delegate = popGestureRecognizerHandler
        popGestureRecognizer.addTarget(target, action: NSSelectorFromString("handleNavigationTransition:"))
        interactivePopGestureRecognizer?.view?.addGestureRecognizer(popGestureRecognizer)
        interactivePopGestureRecognizer?.isEnabled = false
    }

    public override var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? false
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? .allButUpsideDown
    }

    public override var childForStatusBarStyle: UIViewController? {
        return topViewController
    }

    public override var childForStatusBarHidden: UIViewController? {
        return topViewController
    }

    private class PopGestureRecognizerHandler: NSObject, UIGestureRecognizerDelegate {
        weak var navigationController: NavigationController?
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let nav = self.navigationController,
                !nav.interactivePopDisabled, nav.viewControllers.count > 1 else {
                    return false
            }

            // Ignore pan gesture when the navigation controller is currently in transition.
            if let trasition = nav.value(forKey: "_isTransitioning") as? Bool, trasition {
                return false
            }

            // Prevent calling the handler when the gesture begins in an opposite direction.
            if pan.translation(in: pan.view).x <= 0 {
                return false
            }
            return true
        }
    }

}
