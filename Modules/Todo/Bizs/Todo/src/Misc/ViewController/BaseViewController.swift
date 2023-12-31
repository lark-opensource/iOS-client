//
//  BaseViewController.swift
//  Todo
//
//  Created by 张威 on 2020/11/19.
//

import LarkUIKit
import LarkSplitViewController
import LarkContainer

protocol ViewControllerExtension: UIViewController { }

extension ViewControllerExtension {
    var rootSizeClassIsRegular: Bool {
        return view.window?.lkTraitCollection.horizontalSizeClass == .regular
    }
}

class BaseViewController: BaseUIViewController, ViewControllerExtension { }

extension BaseViewController {

    func closeViewController(_ userResolver: LarkContainer.UserResolver) {
        guard let naviVC = navigationController else {
            dismiss(animated: true, completion: { self.closeCallback?() })
            return
        }
        if naviVC.viewControllers.count == 1 {
            if let split = larkSplitViewController,
               split.secondaryViewController == naviVC {
                userResolver.navigator.showDetail(
                    DefaultDetailController(),
                    wrap: LkNavigationController.self,
                    from: self
                )
                closeCallback?()
            } else {
                naviVC.dismiss(animated: true, completion: { self.closeCallback?() })
            }
        } else {
            naviVC.popViewController(animated: true)
            closeCallback?()
        }

    }
}
