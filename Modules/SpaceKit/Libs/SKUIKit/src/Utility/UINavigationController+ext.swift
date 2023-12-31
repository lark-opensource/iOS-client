//
//  UINavigationController+ext.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/5/21.
//  

import Foundation
import SKFoundation

extension UINavigationController {
    public func pushViewController(_ viewController: UIViewController,
                                   animated: Bool,
                                   completion: @escaping (() -> Void)) {
        self.pushViewController(viewController, animated: animated)
        if animated {
            self.transitionCoordinator?.animate(alongsideTransition: nil, completion: { (_) in
                completion()
            })
        } else {
            completion()
        }
    }
}
