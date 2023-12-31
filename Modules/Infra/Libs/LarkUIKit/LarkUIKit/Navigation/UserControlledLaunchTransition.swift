//
//  LarkInterface+LaunchTransition.swift
//  LarkInterface
//
//  Created by PGB on 2019/10/28.
//

import UIKit
import Foundation
import RxCocoa

extension Notification.Name {
    /// launch view did dissmiss notification
    public static let launchTransitionDidDismiss = Notification.Name(rawValue: "LaunchTransitionDidDismiss")
}

/// Conforms to this protocol if you want to control the time to dismiss the launch view when your view controller is in the first tab,
/// otherwise the launch view will be dismissed with the second Runloop.
public protocol UserControlledLaunchTransition: UIViewController {
    /// A signal indicates when to dismiss the launch view.
    /// Please make sure to assign it with the initial value 'false', and accept 'true' when you want to dismiss the launch view.
    var dismissSignal: BehaviorRelay<Bool> { get }
}
