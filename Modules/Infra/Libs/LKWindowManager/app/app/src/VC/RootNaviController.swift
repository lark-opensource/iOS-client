//
//  rootNaviController.swift
//  MultiUIWindowSolution
//
//  Created by bytedance on 2022/4/21.
//

import Foundation
import UIKit

// swiftlint:disable all
class RootNaviController: UINavigationController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationBar.isHidden = true
        self.viewControllers = [TabbarController()]
    }
}

