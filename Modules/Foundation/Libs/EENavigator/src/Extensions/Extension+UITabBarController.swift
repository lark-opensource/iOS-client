//
//  Extension+UITabBarController.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/27.
//

import UIKit
import Foundation

public protocol TabProvider: AnyObject {
    var tabbarController: UITabBarController? { get }
    func switchTab(to tabIdentifier: String)
}

extension UITabBarController {
    func switchTab(by tabIdentifier: String?, tabProvider: TabProvider) {
        guard let tab = tabIdentifier else { return }
        tabProvider.switchTab(to: tab)
    }
}
