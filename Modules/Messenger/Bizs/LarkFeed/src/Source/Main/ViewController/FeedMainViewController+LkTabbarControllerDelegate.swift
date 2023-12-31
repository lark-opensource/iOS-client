//
//  FeedMainViewController+LkTabbarControllerDelegate.swift
//  LarkFeed
//
//  Created by liuxianyu on 2022/9/14.
//

import UIKit
import Foundation
import LarkOpenFeed
import LarkNavigation
import EENavigator

/// iPadFeed三栏提供左侧分组侧栏VC
extension FeedMainViewController: LkTabbarControllerDelegate {
    func getSupplementVC() -> UIViewController? {
        guard !Feed.Feature(userResolver).groupPopOverForPad else { return nil }
        let body = FeedFilterBody(hostProvider: nil)
        let response = userResolver.navigator.response(for: body)
        let filterVC = response.resource as? UIViewController
        return filterVC
    }
}
