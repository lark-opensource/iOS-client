//
//  UIViewController+Swizzled.swift
//  LarkTraitCollection
//
//  Created by 李晨 on 2020/5/25.
//

import UIKit
import Foundation

private struct AssociatedKeys {
    static var tempTraitCollection = "Lark.Temp.Trait.Collection.Tag"
}

extension UIViewController {

    var tempTraitCollection: UITraitCollection? {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.tempTraitCollection
            ) as? UITraitCollection
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.tempTraitCollection,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    @objc
    static func ltc_swizzleMethod() {
        let swizzlingSet: [(Selector, Selector)] = [
            (#selector(viewWillTransition(to:with:)), #selector(ltc_viewWillTransition(to:with:))),
            (#selector(willTransition(to:with:)), #selector(ltc_willTransition(to:with:)))
        ]

        swizzlingSet.forEach { (value) in
            let originalSelector = value.0
            let swizzledSelector = value.1
            ltc_swizzling(
                forClass: UIViewController.self,
                originalSelector: originalSelector,
                swizzledSelector: swizzledSelector
            )
        }
    }

    @objc
    func ltc_viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

        self.ltc_viewWillTransition(to: size, with: coordinator)

        /// 当 vc 是 rootVC, 并且开启自定义 sizeClass 之后，根据 size 通知 traitCollection 变化
        if self.isViewLoaded &&
            self.parent == nil &&
            self.presentingViewController == nil &&
            (self.view.window?.isRootWindow ?? false) &&
            RootTraitCollection.shared.useCustomSizeClass {

            let oldLKCollection = customTraitCollection
            let newLKCollection = TraitCollectionKit.customTraitCollection(
                self.tempTraitCollection ?? view.traitCollection,
                size
            )
            let change = TraitCollectionChange(
                old: oldLKCollection,
                new: newLKCollection
            )
            RootTraitCollection.observable.traitCollectionWillChange(self, change: change)
            coordinator.animate(alongsideTransition: nil) { [weak self](_) in
                guard let `self` = self else { return }
                RootTraitCollection.observable.traitCollectionDidChange(self, change: change)
            }
        }
    }

    @objc
    func ltc_willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        self.ltc_willTransition(to: newCollection, with: coordinator)

        self.tempTraitCollection = newCollection
        coordinator.animate(alongsideTransition: nil) { [weak self] (_) in
            self?.tempTraitCollection = nil
        }

        if self.isViewLoaded &&
            self.parent == nil &&
            self.presentingViewController == nil &&
            (self.view.window?.isRootWindow ?? false) {
            /// 如果开启自定义 sizeClass，这里判断新旧 sizeClass 是否发生变化，如果发生变化
            /// 则直接 return， 依靠 viewWillTransition 通知 sizeClass 变化
            if RootTraitCollection.shared.useCustomSizeClass &&
                (self.traitCollection.horizontalSizeClass != newCollection.horizontalSizeClass ||
                self.traitCollection.verticalSizeClass != newCollection.verticalSizeClass) {
                    return
            }
            let oldLKCollection = customTraitCollection
            let newLKCollection = TraitCollectionKit.customTraitCollection(
                newCollection, self.view.bounds.size
            )
            let change = TraitCollectionChange(
                old: oldLKCollection,
                new: newLKCollection
            )
            RootTraitCollection.observable.traitCollectionWillChange(self, change: change)
            coordinator.animate(alongsideTransition: nil) { [weak self](_) in
                guard let `self` = self else { return }
                RootTraitCollection.observable.traitCollectionDidChange(self, change: change)
            }
        }
    }

    static func ltc_swizzling(
        forClass: AnyClass,
        originalSelector: Selector,
        swizzledSelector: Selector) {

        guard let originalMethod = class_getInstanceMethod(forClass, originalSelector),
            let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector) else {
            return
        }
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
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}
