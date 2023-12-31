//
//  ThreadController.swift
//  LarkThread
//
//  Created by lizhiqiang on 2019/8/19.
//

import UIKit
import Foundation

public protocol ThreadController: UIViewController {
    var threadTableView: UITableView { get }
}

public protocol ThreadRefreshController: ThreadController {
    /// 即将刷新时的回调。
    var willRefreshDataCallback: (() -> Void)? { get set }

    /// 外部触发刷新。
    func refreshData()
}
