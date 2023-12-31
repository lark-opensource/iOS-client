//
//  Notification.swift
//  LarkNavigation
//
//  Created by KT on 2020/3/20.
//

import UIKit
import Foundation

extension Notification.Name {
    static let ViewDidAppear: NSNotification.Name = NSNotification.Name("lark.Tab.ViewDidAppear")
    static let ViewDidLoad: NSNotification.Name = NSNotification.Name("lark.Tab.ViewDidLoad")
}

extension Notification {
    var cost: CFTimeInterval {
        return self.userInfo?[UIViewController.cost] as? CFTimeInterval ?? 0
    }
}
