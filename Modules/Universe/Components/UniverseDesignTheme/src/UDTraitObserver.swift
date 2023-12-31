//
//  UDTraitObserver.swift
//  DarkModeTest
//
//  Created by Hayden on 2021/3/26.
//

import Foundation
import UIKit

public class TraitObserver: UIView {
    public var onTraitChange: ((UITraitCollection) -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isTraitObserver = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                onTraitChange?(traitCollection)
            }
        } else {
            onTraitChange?(traitCollection)
        }
    }
}

class UDTraitObserver: TraitObserver {

    typealias TraitCollectionCallback = (UITraitCollection) -> Void

    private lazy var callbackMap: [String: DynamicValueSetter] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isHidden = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func registerCallback(_ callback: @escaping DynamicValueSetter,
                          forKey key: String) {
        callbackMap[key] = callback
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                for callback in callbackMap.values {
                    DispatchQueue.main.async {
                        callback(self.traitCollection)
                    }
                }
            }
        }
    }
}

extension UIView {

    private struct AssociatedKeys {
        static var traitObserverKey = "UDTraitObserverKey"
        static var traitObserverIdentifierKey = "UDTraitObserverIdentifierKey"
    }

    /// An object that monitoring trait collection changing event.
    public var traitObserver: TraitObserver? {
        get {
            guard #available(iOS 13.0, *) else { return nil }
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.traitObserverKey
            ) as? TraitObserver
        }
        set {
            guard #available(iOS 13.0, *) else { return }
            guard newValue != traitObserver else { return }
            let oldTraitObserver = traitObserver
            oldTraitObserver?.removeFromSuperview()
            if let newTraitObserver = newValue {
                newTraitObserver.isHidden = true
                insertSubview(newTraitObserver, at: 0)
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.traitObserverKey,
                    newTraitObserver,
                    .OBJC_ASSOCIATION_RETAIN
                )
            }
        }
    }

    var udTraitObserver: UDTraitObserver? {
        get {
            traitObserver as? UDTraitObserver
        }
        set {
            let oldValue = traitObserver
            newValue?.onTraitChange = oldValue?.onTraitChange
            traitObserver = newValue
        }
    }

    /// Returns a Boolean value indicating whether the UIView object is a TraitObserver.
    public fileprivate(set) var isTraitObserver: Bool {
        get {
            return objc_getAssociatedObject(
                self,
                &AssociatedKeys.traitObserverIdentifierKey
            ) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.traitObserverIdentifierKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

extension NSObject {

    /// The memory address with class name.
    var address: String {
        return "<\(String(reflecting: type(of: self))): "
            + "\(Unmanaged.passUnretained(self).toOpaque())>"
    }
}
