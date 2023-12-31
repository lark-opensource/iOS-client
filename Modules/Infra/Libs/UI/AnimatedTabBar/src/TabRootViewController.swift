//
//  TabRootViewController.swift
//  LarkNavigation
//
//  Created by PGB on 2020/1/9.
//

import UIKit
import Foundation
import RxCocoa
import LarkTab

public protocol TabRootViewController: AnyObject {
    var tab: Tab { get }
    var controller: UIViewController { get }

    /// Tab常驻 -> 即使内存警告，(true)也不会被回收
    var deamon: Bool { get }

    /// 从当前Tab切走时，是否释放VC
    var deallocAfterSwitchTab: Bool { get }

    /// 首屏数据Ready
    var firstScreenDataReady: BehaviorRelay<Bool>? { get }
}

public extension TabRootViewController {
    var deamon: Bool { return false }
    var deallocAfterSwitchTab: Bool { return false }
    var firstScreenDataReady: BehaviorRelay<Bool>? { return nil }
}

public protocol ContainsTabRoot: AnyObject {
    var rootController: TabRootViewController? { get }
}
