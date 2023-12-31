//
//  LarkInterface+MainTabbarLifecycle.swift
//  LarkNavigation
//
//  Created by 袁平 on 2020/3/27.
//

import Foundation
import RxSwift

typealias TabbarLifecycle = MainTabbarLifecycle & TabbarLifecycleEvent

public protocol MainTabbarLifecycle: AnyObject {
    /// MainTabbarController viewDidAppear
    var onTabDidAppear: Observable<Void> { get }
}

protocol TabbarLifecycleEvent: AnyObject {
    func fireTabDidAppear()
}
