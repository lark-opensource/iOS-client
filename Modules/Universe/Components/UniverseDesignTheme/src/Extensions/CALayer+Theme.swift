//
//  CALayer+Theme.swift
//  UniverseDesignTheme
//
//  Created by Hayden on 2021/3/29.
//

import Foundation
import UIKit

// MARK: - Public APIs

public extension UDComponentsExtension where BaseType: UIView {

    /// Set the dynamic border color for receiver's layer.
    /// - Parameter color: dynamic color that responses to user interface style.
    func setLayerBorderColor(_ color: UIColor) {
        base.layer.ud.setBorderColor(color, bindTo: base)
    }

    /// Set the dynamic shadow color for receiver's layer.
    /// - Parameter color: dynamic color that responses to user interface style.
    func setLayerShadowColor(_ color: UIColor) {
        base.layer.ud.setShadowColor(color, bindTo: base)
    }

    /// Set the dynamic background color for receiver's layer.
    /// - Parameter color: dynamic color that responses to user interface style.
    func setLayerBackgroundColor(_ color: UIColor) {
        base.layer.ud.setBackgroundColor(color, bindTo: base)
    }
}

public extension UDComponentsExtension where BaseType: CALayer {

    /// Set the dynamic color of the layer’s border.
    /// - Parameters:
    ///   - color: dynamic color that responses to user interface style.
    ///   - view: view where the layer belongs to.
    func setBorderColor(_ color: UIColor, bindTo view: UIView? = nil) {
        base.setBorderColor(color, bindTo: view)
    }

    /// Set the dynamic color of the layer’s shadow.
    /// - Parameters:
    ///   - color: dynamic color that responses to user interface style.
    ///   - view: view where the layer belongs to.
    func setShadowColor(_ color: UIColor, bindTo view: UIView? = nil) {
        base.setShadowColor(color, bindTo: view)
    }

    /// Set the dynamic background color of the receiver.
    /// - Parameters:
    ///   - color: dynamic color that responses to user interface style.
    ///   - view: view where the layer belongs to.
    func setBackgroundColor(_ color: UIColor, bindTo view: UIView? = nil) {
        base.setBackgroundColor(color, bindTo: view)
    }
}

public extension UDComponentsExtension where BaseType: CAShapeLayer {

    /// Set the dynamic color used to fill the shape’s path.
    /// - Parameters:
    ///   - color: dynamic color that responses to user interface style.
    ///   - view: view where the layer belongs to.
    func setFillColor(_ color: UIColor, bindTo view: UIView? = nil) {
        base.setFillColor(color, bindTo: view)
    }

    /// Set the dynamic color used to stroke the shape’s path.
    /// - Parameters:
    ///   - color: dynamic color that responses to user interface style.
    ///   - view: view where the layer belongs to.
    func setStrokeColor(_ color: UIColor, bindTo view: UIView? = nil) {
        base.setStrokeColor(color, bindTo: view)
    }
}

public extension UDComponentsExtension where BaseType: CATextLayer {

    /// Set the dynamic color used to render the receiver’s text.
    /// - Parameters:
    ///   - color: dynamic color that responses to user interface style.
    ///   - view: view where the layer belongs to.
    func setForegroundColor(_ color: UIColor, bindTo view: UIView? = nil) {
        base.setForegroundColor(color, bindTo: view)
    }
}

public extension UDComponentsExtension where BaseType: CAGradientLayer {

    /// Set an array of dynamic colors for each gradient stop.
    /// - Parameters:
    ///   - colors: array of dynamic colors that responses to user interface style.
    ///   - view: view where the layer belongs to.
    func setColors(_ colors: [UIColor], bindTo view: UIView? = nil) {
        base.setColors(colors, bindTo: view)
    }
}

// MARK: - Implementations

fileprivate extension CALayer {

    func setBorderColor(_ color: UIColor, bindTo view: UIView? = nil) {
        // swiftlint:disable all
        guard let bindedView = view ?? hostView else {
            assertionFailure("Could not find a bindable view, please assign a bindable view or add layer to super layer first.")
            return
        }
        // swiftlint:enable all
        let uniqueKey = address + ".borderColor"
        setDynamic(uuid: uniqueKey, bindTo: bindedView) { [weak self] trait in
            guard let self = self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.borderColor = color.resolvedCompatibleColor(with: trait).cgColor
            CATransaction.commit()
        }
    }

    func setShadowColor(_ color: UIColor, bindTo view: UIView? = nil) {
        // swiftlint:disable all
        guard let bindedView = view ?? hostView else {
            assertionFailure("Could not find a bindable view, please assign a bindable view or add layer to super layer first.")
            return
        }
        // swiftlint:enable all
        let uniqueKey = address + ".shadowColor"
        setDynamic(uuid: uniqueKey, bindTo: bindedView) { [weak self] trait in
            guard let self = self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.shadowColor = color.resolvedCompatibleColor(with: trait).cgColor
            CATransaction.commit()
        }
    }

    func setBackgroundColor(_ color: UIColor, bindTo view: UIView? = nil) {
        // swiftlint:disable all
        guard let bindedView = view ?? hostView else {
            assertionFailure("Could not find a bindable view, please assign a bindable view or add layer to super layer first.")
            return
        }
        // swiftlint:enable all
        let uniqueKey = address + ".backgroundColor"
        setDynamic(uuid: uniqueKey, bindTo: bindedView) { [weak self] trait in
            guard let self = self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.backgroundColor = color.resolvedCompatibleColor(with: trait).cgColor
            CATransaction.commit()
        }
    }
}

extension CAShapeLayer {

    func setFillColor(_ color: UIColor, bindTo view: UIView? = nil) {
        // swiftlint:disable all
        guard let bindedView = view ?? hostView else {
            assertionFailure("Could not find a bindable view, please assign a bindable view or add layer to super layer first.")
            return
        }
        // swiftlint:enable all
        let uniqueKey = address + ".fillColor"
        setDynamic(uuid: uniqueKey, bindTo: bindedView) { [weak self] trait in
            guard let self = self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.fillColor = color.resolvedCompatibleColor(with: trait).cgColor
            CATransaction.commit()
        }
    }

    func setStrokeColor(_ color: UIColor, bindTo view: UIView? = nil) {
        // swiftlint:disable all
        guard let bindedView = view ?? hostView else {
            assertionFailure("Could not find a bindable view, please assign a bindable view or add layer to super layer first.")
            return
        }
        // swiftlint:enable all
        let uniqueKey = address + ".strokeColor"
        setDynamic(uuid: uniqueKey, bindTo: bindedView) { [weak self] trait in
            guard let self = self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.strokeColor = color.resolvedCompatibleColor(with: trait).cgColor
            CATransaction.commit()
        }
    }
}

extension CATextLayer {

    func setForegroundColor(_ color: UIColor, bindTo view: UIView? = nil) {
        // swiftlint:disable all
        guard let bindedView = view ?? hostView else {
            assertionFailure("Could not find a bindable view, please assign a bindable view or add layer to super layer first.")
            return
        }
        // swiftlint:enable all
        let uniqueKey = address + ".foregroundColor"
        setDynamic(uuid: uniqueKey, bindTo: bindedView) { [weak self] trait in
            guard let self = self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.foregroundColor = color.resolvedCompatibleColor(with: trait).cgColor
            CATransaction.commit()
        }
    }
}

extension CAGradientLayer {

    func setColors(_ colors: [UIColor], bindTo view: UIView? = nil) {
        // swiftlint:disable all
        guard let bindedView = view ?? hostView else {
            assertionFailure("Could not find a bindable view, please assign a bindable view or add layer to super layer first.")
            return
        }
        // swiftlint:enable all
        let uniqueKey = address + ".colors"
        setDynamic(uuid: uniqueKey, bindTo: bindedView) { [weak self] trait in
            guard let self = self else { return }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.colors = colors.map { $0.resolvedCompatibleColor(with: trait).cgColor }
            CATransaction.commit()
        }
    }
}

// MARK: - Extensions

fileprivate extension UIColor {

    /// Returns the version of the current color that results from the specified traits.
    /// (Compatible with iOS versions lower than 13.0)
    /// - Parameter traitCollection: The traits to use when resolving the color information.
    /// - Returns: The version of the color to display for the specified traits.
    func resolvedCompatibleColor(with traitCollection: UITraitCollection) -> UIColor {
        if #available(iOS 13.0, *) {
            return resolvedColor(with: traitCollection)
        } else {
            return self
        }
    }
}

fileprivate extension CALayer {

    /// Root view which the layer relied on.
    var hostView: UIView? {
        var currentLayer: CALayer? = self
        while currentLayer?.delegate == nil, currentLayer?.superlayer != nil {
            currentLayer = currentLayer?.superlayer
        }
        return currentLayer?.delegate as? UIView
    }
}
