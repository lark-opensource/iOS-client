//
//  BootManagerDependency.swift
//  LarkTourDev
//
//  Created by Meng on 2020/9/29.
//

import UIKit
import Foundation
import BootManager
import AnimatedTabBar
import AppContainer

class BootManagerDependency: BootDependency {
    func tabStringToBizScope(_ tabString: String) -> BizScope? {
        return .messenger
    }

    func launchOptionToBizScope(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> BizScope? {
        return .messenger
    }

    var eventObserver: EventMonitorProtocol? {
        return nil
//        return LaunchOpenTracing.shared
    }
}
