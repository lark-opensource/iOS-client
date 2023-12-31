//
//  Protocols.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/27.
//

import UIKit
import Foundation

// NOTE: class 必须加，否则协议调用的时候可能找不到self
public protocol FragmentLocate: AnyObject where Self: UIViewController {
    func customLocate(by fragment: String, with context: [String: Any], animated: Bool)
}

public protocol NavigatorNotification: AnyObject where Self: UIViewController {
    func willDismiss(animated: Bool)
}

public extension NavigatorNotification {
    func willDismiss(animated: Bool) {}
}
