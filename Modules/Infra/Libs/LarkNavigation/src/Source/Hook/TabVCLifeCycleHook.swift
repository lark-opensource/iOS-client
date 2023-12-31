//
//  TabVCLifeCycleHook.swift
//  LarkNavigation
//
//  Created by KT on 2020/6/28.
//

import UIKit
import Foundation

extension UIViewController {
    static let cost = "Cost"

    public func hookTabVCLifeCycle() {
        let current = type(of: self)
        swizzlingIfNeeded(
            forClass: current,
            originalSelector: #selector(viewDidLoad),
            swizzledSelector: #selector(lark_tab_lifeCycle_viewDidLoad)
        )

        swizzlingIfNeeded(
            forClass: current,
            originalSelector: #selector(viewDidAppear(_:)),
            swizzledSelector: #selector(lark_tab_lifeCycle_viewDidAppear(_:))
        )
    }

    @objc
    func lark_tab_lifeCycle_viewDidLoad() {
        let last = CACurrentMediaTime()
        self.lark_tab_lifeCycle_viewDidLoad()
        self.post(.ViewDidLoad, cost: CACurrentMediaTime() - last)
    }

    @objc
    func lark_tab_lifeCycle_viewDidAppear(_ animated: Bool) {
        let last = CACurrentMediaTime()
        self.lark_tab_lifeCycle_viewDidAppear(animated)
        self.post(.ViewDidAppear, cost: CACurrentMediaTime() - last)
    }

    private func post(_ name: NSNotification.Name, cost: CFTimeInterval) {
        NotificationCenter.default.post(
            name: name,
            object: self,
            userInfo: [UIViewController.cost: cost * 1_000])
    }

    // MARK: - swizzling
    private func swizzlingIfNeeded(
        forClass: AnyClass,
        originalSelector: Selector,
        swizzledSelector: Selector
    ) {
        guard
            let originalMethod = class_getInstanceMethod(forClass, originalSelector),
            let swizzledMethod = class_getInstanceMethod(Self.self, swizzledSelector)
            else { return }

        // 如果子类没有实现originalSelector
        // 直接Hook，会交换super的originalSelector
        // 如果两个VC有相同的Super，会出现死循环
        if class_addMethod(
            forClass,
            originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
            ) {
            class_replaceMethod(
                forClass,
                swizzledSelector,
                method_getImplementation(originalMethod),
                method_getTypeEncoding(originalMethod)
            )
        }

        // 添加一次，成功才交换
        // 给子类的Class加入UIViewController的func
        if class_addMethod(
            forClass,
            swizzledSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
            ) {
            guard let target = class_getInstanceMethod(forClass, swizzledSelector) else { return }
            method_exchangeImplementations(originalMethod, target)
        }
    }
}
