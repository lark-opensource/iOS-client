//
//  LarkBlur.swift
//  LarkBlur
//
//  Created by Saafo on 2021/5/11.
//

import Foundation
import UIKit

public typealias VisualBlurView = SystemBlurView

/* 去除私有 API

public class VisualBlurView: UIView, UIViewBlurable {

    private enum Constants {
        static let blurRadiusKey = "blurRadius"
        static let colorTintKey = "colorTint"
        static let colorTintAlphaKey = "colorTintAlpha"
    }

    // MARK: - Public

    /// Blur radius. Defaults to `20`
    public var blurRadius: CGFloat = 20.0 {
        didSet {
            _setValue(realBlurRadius, forKey: Constants.blurRadiusKey)
        }
    }

    /// Tint color. Defaults to `nil`
    public var fillColor: UIColor? {
        didSet {
            _setValue(fillColor, forKey: Constants.colorTintKey)
        }
    }

    /// Tint color alpha. Defaults to `0`
    public var fillOpacity: CGFloat = 0.01 {
        didSet {
            _setValue(fillOpacity, forKey: Constants.colorTintAlphaKey)
        }
    }

    /// Visual effect view layer.
    private var blurLayer: CALayer {
        return visualEffectView.layer
    }

    private var realBlurRadius: CGFloat {
        blurRadius / 2
    }

    // MARK: - Initialization

    public init(
        radius: CGFloat = 20.0,
        color: UIColor? = nil,
        colorAlpha: CGFloat = 0.8) {
        blurRadius = radius
        super.init(frame: .zero)
        backgroundColor = .clear
        defer {
            blurRadius = radius
            fillColor = color
            fillOpacity = colorAlpha
        }
        setupViews()
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    // MARK: - Private

    /// Visual effect view.
    private lazy var visualEffectView: UIVisualEffectView = {
        if #available(iOS 14.0, *) {
            return UIVisualEffectView(effect: blurEffectAboveiOS14)
        } else {
            return UIVisualEffectView(effect: blurEffectUnderIOS14)
        }
    }()

    /// Blur effect for iOS >= 14
    private lazy var blurEffectAboveiOS14: VisualBlurEffect = {
        let effect = VisualBlurEffect.effect(with: .extraLight)
        effect.blurRadius = blurRadius
        return effect
    }()

    /// Blur effect for iOS < 14
    private lazy var blurEffectUnderIOS14: UIBlurEffect = {
        return (NSClassFromString("_UICustomBlurEffect") as? UIBlurEffect.Type ?? {
            return UIBlurEffect.self
        }()).init()
    }()

    /// Sets the value for the key on the blurEffect.
    private func _setValue(_ value: Any?, forKey key: String) {
        if #available(iOS 14.0, *) {
            if key == Constants.blurRadiusKey {
                resetBlurViewAboveIOS14()
            }
            let subviewClass = NSClassFromString("_UIVisualEffectSubview") as? UIView.Type
            let visualEffectSubview: UIView? = visualEffectView.subviews.first(where: { type(of: $0) == subviewClass })
            visualEffectSubview?.backgroundColor = fillColor
            visualEffectSubview?.alpha = fillOpacity
        } else {
            blurEffectUnderIOS14.setValue(value, forKeyPath: key)
            visualEffectView.effect = blurEffectUnderIOS14
        }
    }

    /// Setup views.
    private func setupViews() {
        addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }

    /// Update visualEffectView for ios14+, if we need to change blurRadius
    private func resetBlurViewAboveIOS14() {
        if #available(iOS 14.0, *) {
            visualEffectView.removeFromSuperview()
            let newEffect = VisualBlurEffect.effect(with: .extraLight)
            newEffect.blurRadius = realBlurRadius
            blurEffectAboveiOS14 = newEffect
            visualEffectView = UIVisualEffectView(effect: blurEffectAboveiOS14)
            setupViews()
        }
    }
}

final class VisualBlurEffect: UIBlurEffect {

    public var blurRadius: CGFloat = 10.0

    private enum Constants {
        static let blurRadiusSettingKey = "blurRadius"
    }

    class func effect(with style: UIBlurEffect.Style) -> VisualBlurEffect {
        let result = super.init(style: style)
        object_setClass(result, self)
        return result as? VisualBlurEffect ?? {
            return VisualBlurEffect()
        }()
    }

    override func copy(with zone: NSZone? = nil) -> Any {
        let result = super.copy(with: zone)
        object_setClass(result, Self.self)
        return result
    }

    override var effectSettings: AnyObject {
        get {
            let settings = super.effectSettings
            settings.setValue(blurRadius, forKey: Constants.blurRadiusSettingKey)
            return settings
        }
        set {
            super.effectSettings = newValue
        }
    }
}

private var associatedObjectHandle: UInt8 = 0

extension UIVisualEffect {

    // swiftlint:disable all
    @objc var effectSettings: AnyObject {
        get {
            objc_getAssociatedObject(self, &associatedObjectHandle) as AnyObject
        }
        set {
            objc_setAssociatedObject(self, &associatedObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    // swiftlint:enable all
}

 */
