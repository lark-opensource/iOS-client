//
//  ViewModelCoordinator.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/8/10.
//

import UIKit
import EENavigator

public protocol ViewModelCoordinator: NavigatorFrom {
    var view: UIView? { get }
}

public final class ViewModelCoordinatorImp: ViewModelCoordinator {

    public var view: UIView? { controller?.view }

    public var fromViewController: UIViewController? { controller }

    /// 是否可以被路由强持有
    public var canBeStrongReferences: Bool { false }

    private weak var controller: UIViewController?

    public init(controller: UIViewController?) {
        self.controller = controller
    }
}
