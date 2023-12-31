//
//  NavigatorUtils.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/10/28.
//

import UIKit
import Foundation

public typealias Completion = () -> Void

func combine<T>(handlers: [(T, @escaping Completion) -> Void]) -> (T, @escaping Completion) -> Void {
    return { args, completion in
        func execute(idx: Int) {
            let handler = handlers[idx]
            if idx >= handlers.count - 1 {
                handler(args, completion)
            } else {
                handler(args) { execute(idx: idx + 1) }
            }
        }

        handlers.isEmpty ? completion() : execute(idx: 0)
    }
}

func combine(handlers: [(@escaping Completion) -> Void]) -> (@escaping Completion) -> Void {
    let handlers = handlers.map { (handler) -> (Void, @escaping Completion) -> Void in
        return { _, completion in
            handler(completion)
        }
    }
    return { completion in
        combine(handlers: handlers)((), completion)
    }
}

func locate(
    target: UIViewController, animated: Bool = true,
    by fragment: String, with context: [String: Any] = [:]) {

    if let fragmentLocate = (target as? FragmentLocate) ??
        (target.navigationController as? FragmentLocate) ??
        (target.tabBarController as? FragmentLocate) {
        fragmentLocate.customLocate(by: fragment, with: context, animated: animated)
    }
}

func willDismiss(target: UIViewController, animated: Bool) {
    if let target = target as? NavigatorNotification {
        target.willDismiss(animated: animated)
    }
    target.children.forEach {
        willDismiss(target: $0, animated: animated)
    }
}

func when(animated: Bool, action: () -> UINavigationController?, completion: Completion? = nil) {
    if animated {
        guard let navigation = action(), let coordinator = navigation.transitionCoordinator else {
            completion?()
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in
            completion?()
        }
    } else {
        // swiftlint:disable redundant_discardable_let
        let _ = action()
        completion?()
    }
}
