//
//  UIView+Theme.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 2021/5/26.
//

import Foundation
import UIKit

// swiftlint:disable all

/// A ReferenceWritableKeyPath where the Root is member of UIView.
public typealias DynamicKeyPath<V: UIView, T> = ReferenceWritableKeyPath<V, T>
/// A closure that privides values according to UITraitCollection.
public typealias DynamicValueProvider<T> = (UITraitCollection) -> T
/// A closure that set dynamic values to key path.
internal typealias DynamicValueSetter = (UITraitCollection) -> Void

/// A convenience function that return a DynamicValueProvider.
/// - Parameters:
///   - light: value in light mode.
///   - dark: value in dark mode.
/// - Returns: a DynamicValueProvider closure.
public func UDDynamicProvider<T>(_ light: T, _ dark: T) -> DynamicValueProvider<T> {
    return { traitCollection in
        if #available(iOS 13.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .dark: return dark
            default:    return light
            }
        } else {
            return light
        }
    }
}
// swiftlint:enable all

/// A dynamic value providable protocol.
public protocol UDDynamicValue {

    /// Dynamic value type.
    associatedtype Value

    /// A closure that privides values according to UITraitCollection.
    var dynamicProvider: DynamicValueProvider<Value> { get }
}

public extension UDComponentsExtension where BaseType: UIView {

    /// Bind dynamic values to one key path.
    /// - Parameters:
    ///   - light: value in light mode.
    ///   - dark: value in dark mode.
    ///   - keyPath: key path the value associated with.
    func setValue<T>(forKeyPath keyPath: DynamicKeyPath<BaseType, T>,
                     light: T, dark: T) {
        base.setDynamic(
            forKeyPath: keyPath,
            dynamicProvider: UDDynamicProvider(light, dark)
        )
    }

    /// Bind a dynamic value provider to key path.
    /// - Parameters:
    ///   - keyPath: key path the value associated with.
    ///   - dynamicProvider: a closure that provide dynamic values.
    func setValue<T>(forKeyPath keyPath: DynamicKeyPath<BaseType, T>,
                     dynamicProvider: @escaping DynamicValueProvider<T>) {
        base.setDynamic(
            forKeyPath: keyPath,
            dynamicProvider: dynamicProvider
        )
    }
}

extension UIView {

    func setDynamic<V: UIView, T>(forKeyPath keyPath: DynamicKeyPath<V, T>,
                                  dynamicProvider: @escaping DynamicValueProvider<T>) {
        // Get trait observer object
        if self.udTraitObserver == nil {
            self.udTraitObserver = UDTraitObserver()
        }
        // Type erasure using closure
        let setterCallback: DynamicValueSetter = { [weak self] trait in
            guard let self = self, let typedSelf = self as? V else {
                assertionFailure("Can not find a bindable view.")
                return
            }
            typedSelf[keyPath: keyPath] = dynamicProvider(trait)
        }
        // Call immediately to set the property
        setterCallback(traitCollection)
        // Save the closure for trait collection changing
        udTraitObserver?.registerCallback(setterCallback, forKey: String(keyPath.hashValue))
    }
}

public extension UDComponentsExtension where BaseType: NSObject {

    /// Set the dynamic value of the host object.
    /// - Parameters:
    ///   - uuid: the unique id of callback.
    ///   - view: the view where the layer belongs to.
    ///   - handler: the closure called after trait collection changed.
    func setValue(uuid: String,
                  bindTo view: UIView? = nil,
                  handler: @escaping (UITraitCollection) -> Void) {
        base.setDynamic(uuid: uuid, bindTo: view, handler: handler)
    }
}

internal extension NSObject {

    func setDynamic(uuid: String,
                    bindTo view: UIView? = nil,
                    handler: @escaping DynamicValueSetter) {
        // Find the binded view from which trait collection changes notified
        guard let bindedView = view ?? (self as? UIView) else {
            assertionFailure("Could not find a bindable view.")
            return
        }
        // Get trait observer object
        if bindedView.udTraitObserver == nil {
            bindedView.udTraitObserver = UDTraitObserver()
        }
        // Call immediately to set the property
        handler(bindedView.traitCollection)
        // Save the closure for trait collection changing
        bindedView.udTraitObserver?.registerCallback(handler, forKey: uuid)
    }
}

extension UIView {
    /// Used for observing `traitCollection` changing event of host view.
    /// - Parameters:
    ///   - key: observation key, the caller should guarantee the uniqueness of key
    ///   - handler: traitCollection change callback
    /// - NOTE: Please use `registerForTraitChanges` instead after iOS17
    public func registerTraitCollectionChanges(forKey key: String, handler: @escaping (UITraitCollection) -> Void) {
        // Get trait observer object
        if self.udTraitObserver == nil {
            self.udTraitObserver = UDTraitObserver()
        }
        // Save the closure for trait collection changing
        udTraitObserver?.registerCallback(handler, forKey: key)
    }
}
