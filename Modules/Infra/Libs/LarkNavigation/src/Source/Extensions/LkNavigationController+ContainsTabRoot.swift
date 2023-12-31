//
//  LkNavigationController+ContainsTabRoot.swift
//  LarkNavigation
//
//  Created by Meng on 2019/10/14.
//

import Foundation
import LarkUIKit
import AnimatedTabBar

extension LkNavigationController: ContainsTabRoot {
    open var rootController: TabRootViewController? {
        return self.viewControllers.first as? TabRootViewController
    }
}
