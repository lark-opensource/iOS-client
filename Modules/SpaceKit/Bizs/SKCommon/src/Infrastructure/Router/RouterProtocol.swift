//
//  RouterProtocol.swift
//  SpaceKit
//
//  Created by Gill on 2019/12/23.
//

import UIKit

public protocol RouterProtocol: AnyObject {
    func routerPresent(vc: UIViewController, animated: Bool, completion: (() -> Void)?)
    func routerPush(vc: UIViewController, animated: Bool)
    var routerImpl: UIViewController? { get }
}

public extension RouterProtocol where Self: UIViewController {
    func routerPresent(vc: UIViewController, animated: Bool, completion: (() -> Void)?) {
        self.present(vc, animated: animated, completion: completion)
    }
    func routerPush(vc: UIViewController, animated: Bool) {
        self.navigationController?.pushViewController(vc, animated: animated)
    }
    var routerImpl: UIViewController? { return self }
}
