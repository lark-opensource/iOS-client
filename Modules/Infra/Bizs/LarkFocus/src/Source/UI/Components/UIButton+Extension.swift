//
//  UIButton+Extension.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/3.
//

import Foundation
import UIKit

extension UIButton {

    func reverseImageTitle() {
        transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        titleLabel?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        imageView?.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    }
}

func getTopViewController() -> UIViewController? {
    guard let mainWindow = UIApplication.shared.delegate?.window else { return nil }
    let mainRootController = mainWindow?.rootViewController
    return topViewController(mainRootController)
}

func topViewController(_ rootVC: UIViewController?) -> UIViewController? {
    if let tabbarVC = rootVC as? UITabBarController, let selectedVC = tabbarVC.selectedViewController {
        return topViewController(selectedVC)
    } else if let naviVC = rootVC as? UINavigationController, let visibleVC = naviVC.visibleViewController {
        return topViewController(visibleVC)
    } else if let presentedVC = rootVC?.presentedViewController {
        return topViewController(presentedVC)
    }
    return rootVC
}
