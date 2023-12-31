//
//  MinutesHomeFilterNavigationController.swift
//  Minutes
//
//  Created by sihuahao on 2021/7/18.
//

import Foundation
import LarkUIKit
import EENavigator

public final class MinutesHomeFilterNavigationController: LkNavigationController, UIViewControllerTransitioningDelegate {

    public override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        modalPresentationStyle = .custom
        transitioningDelegate = self
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func presentationController(forPresented presented: UIViewController,
                                       presenting: UIViewController?,
                                       source: UIViewController) -> UIPresentationController? {
        return MinutesHomeFilterPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
