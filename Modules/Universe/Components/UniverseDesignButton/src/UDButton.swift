//
//  UDButton.swift
//  Pods-UniverseDesignButtonDev
//
//  Created by 姚启灏 on 2020/9/1.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignStyle

/// UDButton UI Conifg
public struct UDButtonUIConifg {

    public typealias CustomButtonType = (size: CGSize, inset: CGFloat, font: UIFont, iconSize: CGSize)

    /// UDButton Theme Color
    /// Contains border, background, text
    public struct ThemeColor {
        let borderColor: UIColor
        let backgroundColor: UIColor
        let textColor: UIColor

        /// ThemeColor init
        /// - Parameters:
        ///   - borderColor: Border Color
        ///   - backgroundColor: Background Color
        ///   - textColor: Text Color
        public init(borderColor: UIColor,
                    backgroundColor: UIColor,
                    textColor: UIColor) {
                        self.borderColor = borderColor
                        self.backgroundColor = backgroundColor
                        self.textColor = textColor
        }
    }

    /// Determines the minimum size of the button
    public enum ButtonType: Equatable {
        /// min size 60 * 28
        case small

        /// min size 76 * 36
        case middle

        /// min size 104 * 48
        case big

        case custom(type: CustomButtonType)

        /// 由于原有的设计问题，很难基于某个已有的 `ButtonType` 更改其中一个参数，所以创建了这个方法。
        /// - Parameters:
        ///   - baseType: 基于哪一类修改
        ///   - size: 需要修改的按钮尺寸，不传则不修改
        ///   - inset: 需要修改的按钮左右边距，不传则不修改
        ///   - font: 需要修改的按钮字体，不传则不修改
        ///   - iconSize: 需要修改的按钮图标尺寸，不传则不修改
        /// - Returns: 修改后的 `ButtonType`
        /// - NOTE: 当然，可以使用 `.custom(type:)` 类型达到同样的效果，但是由于 `CustomButtonType` 是一个元组，基于已有类型创建会非常麻烦
        public static func custom(from baseType: ButtonType,
                                  size: CGSize? = nil,
                                  inset: CGFloat? = nil,
                                  font: UIFont? = nil,
                                  iconSize: CGSize? = nil) -> ButtonType {
            return .custom(type: (
                size: size ?? baseType.size(),
                inset: inset ?? baseType.edgeInsets(),
                font: font ?? baseType.font(),
                iconSize: iconSize ?? baseType.iconSize()
            ))
        }

        /// get button min size
        public func size() -> CGSize {
            switch self {
            case .small:
                return CGSize(width: 60, height: 28)
            case .middle:
                return CGSize(width: 76, height: 36)
            case .big:
                return CGSize(width: 104, height: 48)
            case .custom(let type):
                return type.size
            }
        }

        /// get button content edge insets
        public func edgeInsets() -> CGFloat {
            switch self {
            case .small:
                return 12
            case .middle:
                return 20
            case .big:
                return 32
            case .custom(let type):
                return type.inset
            }
        }

        public func font() -> UIFont {
            switch self {
            case .small:
                return UIFont.systemFont(ofSize: 14)
            case .middle:
                return UIFont.systemFont(ofSize: 16)
            case .big:
                return UIFont.systemFont(ofSize: 17)
            case .custom(let type):
                return type.font
            }
        }

        public func iconSize() -> CGSize {
            switch self {
            case .small:
                return CGSize(width: 12, height: 12)
            case .middle:
                return CGSize(width: 14, height: 14)
            case .big:
                return CGSize(width: 16, height: 16)
            case .custom(let type):
                return type.iconSize
            }
        }

        public static func == (lhs: UDButtonUIConifg.ButtonType, rhs: UDButtonUIConifg.ButtonType) -> Bool {
            switch (lhs, rhs) {
            case (.small, .small):
                return true
            case (.middle, .middle):
                return true
            case (.big, .big):
                return true
            case (.custom(let type1), .custom(let type2)):
                return type1.size == type2.size && type1.inset == type2.inset && type1.font == type2.font && type1.iconSize == type2.iconSize
            default:
                return false
            }
        }
    }

    /// Determines the cornerRadius of the button
    public enum ButtonStyle {
        /// radius:  height / 2
        case circle

        /// radius: 2
        case square
    }

    /// Button normal theme color
    public var normalColor: ThemeColor

    /// Button pressed theme color
    public var pressedColor: ThemeColor

    /// Button disable theme color
    public var disableColor: ThemeColor

    /// Button loading theme color
    public var loadingColor: ThemeColor

    /// Button loading icon color
    public var loadingIconColor: UIColor?

    /// Button size type
    public var type: ButtonType

    /// Button cornerRadius type
    public var radiusStyle: ButtonStyle

    /// Button semanticContentAttribute
    public var semanticContentAttribute: UISemanticContentAttribute

    ///  UDButtonUIConifg init
    /// - Parameters:
    ///   - normalColor: Button normal theme color
    ///   - pressedColor:   Button pressed theme color
    ///   - disableColor: Button disable theme color
    ///   - icon: Button icon image
    ///   - type: Button size type
    ///   - radiusStyle: Button cornerRadius type
    ///   - semanticContentAttribute: Button semanticContentAttribute
    public init(normalColor: ThemeColor,
                pressedColor: ThemeColor? = nil,
                disableColor: ThemeColor? = nil,
                loadingColor: ThemeColor? = nil,
                loadingIconColor: UIColor? = nil,
                type: ButtonType = .small,
                radiusStyle: ButtonStyle = .square,
                semanticContentAttribute: UISemanticContentAttribute = .unspecified) {
        self.normalColor = normalColor
        if let pressedColor = pressedColor {
            self.pressedColor = pressedColor
        } else {
            self.pressedColor = normalColor
        }

        if let disableColor = disableColor {
            self.disableColor = disableColor
        } else {
            self.disableColor = normalColor
        }

        if let loadingColor = loadingColor {
            self.loadingColor = loadingColor
        } else {
            self.loadingColor = normalColor
        }

        self.loadingIconColor = loadingIconColor
        self.type = type
        self.radiusStyle = radiusStyle
        self.semanticContentAttribute = semanticContentAttribute
    }

    /// Default button
    public static var defaultConfig: UDButtonUIConifg {
        let normalColor = ThemeColor(borderColor: UIColor.clear,
                                     backgroundColor: UIColor.ud.colorfulBlue,
                                     textColor: UIColor.ud.N00)
        return UDButtonUIConifg(normalColor: normalColor)
    }

    /// Mainly refers to the blue flat button
    public static var primaryBlue: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.ud.primaryFillDefault,
                                                      textColor: UIColor.ud.primaryOnPrimaryFill)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.primaryFillPressed,
                                                       textColor: UIColor.ud.primaryOnPrimaryFill)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.fillDisabled,
                                                       textColor: UIColor.ud.udtokenBtnPriTextDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.primaryFillLoading,
                                                       textColor: UIColor.ud.primaryOnPrimaryFill)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryOnPrimaryFill)
        return conifg
    }

    /// Mainly refers to the red flat button
    public static var primaryRed: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.ud.functionDangerFillDefault,
                                                      textColor: UIColor.ud.functionDangerOnDangerFill)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.functionDangerFillPressed,
                                                       textColor: UIColor.ud.functionDangerOnDangerFill)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.fillDisabled,
                                                       textColor: UIColor.ud.udtokenBtnPriTextDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.functionDangerFillLoading,
                                                       textColor: UIColor.ud.primaryOnPrimaryFill)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryOnPrimaryFill)
        return conifg
    }

    /// Gray stroke buttons (including rectangular buttons and full-width buttons)
    public static var secondaryGray: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.textTitle)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.ud.udtokenBtnSeBgNeutralPressed,
                                                       textColor: UIColor.ud.textTitle)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.udtokenComponentTextDisabledLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryContentDefault)
        return conifg
    }

    /// Blue stroke buttons (including rectangular buttons and full-width buttons)
    public static var secondaryBlue: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.primaryContentDefault,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.primaryContentDefault)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.primaryContentDefault,
                                                       backgroundColor: UIColor.ud.udtokenBtnSeBgPriPressed,
                                                       textColor: UIColor.ud.primaryContentDefault)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.primaryContentLoading,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.primaryContentLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryContentDefault)
        return conifg
    }

    /// Red stroke buttons (including rectangular buttons and full-width buttons)
    public static var secondaryRed: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.functionDangerContentDefault,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.functionDangerContentDefault)
        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.functionDangerContentDefault,
                                                       backgroundColor: UIColor.ud.udtokenBtnSeBgDangerPressed,
                                                       textColor: UIColor.ud.functionDangerContentDefault)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.lineBorderComponent,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.ud.functionDangerContentLoading,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.functionDangerContentLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.functionDangerContentDefault)
        return conifg
    }

    /// Gray text type button
    public static var textGray: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.textTitle)

        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor:
                                                        UIColor.ud.udtokenBtnTextBgNeutralPressed,
                                                       textColor: UIColor.ud.textTitle)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.udtokenComponentTextDisabledLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryContentDefault)
        return conifg
    }

    /// Blue text type button
    public static var textBlue: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.primaryContentDefault)

        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.udtokenBtnTextBgPriPressed,
                                                       textColor: UIColor.ud.primaryContentDefault)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.primaryContentLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.primaryContentDefault)
        return conifg
    }

    /// Red text type button
    public static var textRed: UDButtonUIConifg {
        let normalColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                      backgroundColor: UIColor.clear,
                                                      textColor: UIColor.ud.functionDangerContentDefault)

        let pressedColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.ud.udtokenBtnSeBgDangerPressed,
                                                       textColor: UIColor.ud.functionDangerContentDefault)
        let disableColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.textDisabled)
        let loadingColor = UDButtonUIConifg.ThemeColor(borderColor: UIColor.clear,
                                                       backgroundColor: UIColor.clear,
                                                       textColor: UIColor.ud.functionDangerContentLoading)
        let conifg = UDButtonUIConifg(normalColor: normalColor,
                                      pressedColor: pressedColor,
                                      disableColor: disableColor,
                                      loadingColor: loadingColor,
                                      loadingIconColor: UIColor.ud.functionDangerContentDefault)
        return conifg
    }
}

extension UDButtonUIConifg {

    public func type(_ value: ButtonType) -> Self {
        var config = self
        config.type = value
        return config
    }

    public mutating func radiusStyle(_ value: ButtonStyle) -> Self {
        var config = self
        config.radiusStyle = value
        return config
    }
}

public final class UDButton: UIButton {
    public override var isEnabled: Bool {
        didSet {
            update(isEnabled: isEnabled)
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            update(isHighlighted: isHighlighted)
        }
    }

    /// Button UI Conifg
    public var config: UDButtonUIConifg {
        didSet {
            updateUIConifg(config)
        }
    }

    private var loadingIcon: UIImage = UDIcon.chatLoadingOutlined.ud.resized(to: CGSize(width: 16, height: 16))

    private var iconImage: UIImage?

    var isLoading = false

    /// UDButton init
    /// - Parameter config: Button UI Conifg
    public init(_ config: UDButtonUIConifg = UDButtonUIConifg.defaultConfig) {
        self.config = config
        super.init(frame: .zero)

        self.clipsToBounds = true

        self.snp.makeConstraints { (make) in
            let size = config.type.size()
            make.width.greaterThanOrEqualTo(size.width)
            make.height.greaterThanOrEqualTo(size.height)
        }

        updateUIConifg(config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadius = config.radiusStyle == .circle ? min(bounds.width, bounds.height) / 2 : UDStyle.middleRadius
        self.layer.cornerRadius = cornerRadius

        if isEnabled {
            self.layer.ud.setBorderColor(config.normalColor.borderColor)
        } else {
            self.layer.ud.setBorderColor(config.disableColor.borderColor)
        }

        let edgeInsets = config.type.edgeInsets()
        var contentEdgeInsets = self.contentEdgeInsets
        contentEdgeInsets.left = contentEdgeInsets.left == 0 ? edgeInsets : contentEdgeInsets.left
        contentEdgeInsets.right = contentEdgeInsets.right == 0 ? edgeInsets : contentEdgeInsets.right

        if isLoading, self.config.type == .small {
            let size = self.bounds.size
            self.imageView?.center = CGPoint(x: size.width / 2, y: size.height / 2)
            self.titleLabel?.isHidden = true
        } else {
            self.titleLabel?.isHidden = false
        }
    }

    public override func setImage(_ image: UIImage?, for state: UIControl.State) {
        let image = image?.ud.resized(to: config.type.iconSize())
        self.iconImage = image
        // stash image when loading, and reset after loading
        if isLoading { return }
        super.setImage(image, for: state)

        setEdgeInsets(image)
    }

    /// Button show loading
    public func showLoading() {
        guard isEnabled else { return }
        // view refresh without animation will cause CABasicAnimation stop, so we need to add animation again
        if let imageView = self.imageView {
            addRotateAnimation(view: imageView)
        }
        guard !isLoading else { return }

        self.isUserInteractionEnabled = false
        self.isLoading = true

        // should not call self.setImage(:)
        super.setImage(loadingIcon, for: .normal)
        setEdgeInsets(loadingIcon)

        self.backgroundColor = config.loadingColor.backgroundColor
        self.setTitleColor(config.loadingColor.textColor, for: .normal)
        self.layer.ud.setBorderColor(config.loadingColor.borderColor)

        self.setNeedsLayout()
    }

    /// Button hide loading
    public func hideLoading() {
        guard isEnabled, isLoading else { return }

        self.isUserInteractionEnabled = true
        self.isLoading = false

        // reset for last icon
        self.setImage(iconImage, for: .normal)
        if let imageView = self.imageView {
            removeRotateAnimation(view: imageView)
        }

        self.backgroundColor = config.normalColor.backgroundColor
        self.setTitleColor(config.normalColor.textColor, for: .normal)
        self.layer.ud.setBorderColor(config.normalColor.borderColor)

        self.setNeedsLayout()
    }

    private func setEdgeInsets(_ image: UIImage?) {
        if image != nil {
            if self.semanticContentAttribute == .forceRightToLeft {
                self.imageEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
                self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
            } else {
                self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 2)
                self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 2, bottom: 0, right: -2)
            }
        } else {
            self.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    /// Set Button UI Config
    /// - Parameter config: UDButtonUIConifg
    private func updateUIConifg(_ config: UDButtonUIConifg) {
        self.semanticContentAttribute = config.semanticContentAttribute
        self.setTitleColor(config.normalColor.textColor, for: .normal)
        self.setTitleColor(config.pressedColor.textColor, for: .highlighted)
        self.setTitleColor(config.disableColor.textColor, for: .disabled)

        let cornerRadius = config.radiusStyle == .circle ? min(bounds.width, bounds.height) / 2 : UDStyle.smallRadius
        self.layer.cornerRadius = cornerRadius
        self.layer.borderWidth = 1

        if let loadingIconColor = config.loadingIconColor {
            self.loadingIcon = self.loadingIcon.ud.withTintColor(loadingIconColor)
        }

        if isEnabled {
            self.backgroundColor = config.normalColor.backgroundColor
            self.layer.ud.setBorderColor(config.normalColor.borderColor)
        } else {
            self.backgroundColor = config.disableColor.backgroundColor
            self.layer.ud.setBorderColor(config.disableColor.borderColor)
        }

        let constraintsSize = config.type.size()
        self.snp.updateConstraints { (make) in
            make.width.greaterThanOrEqualTo(constraintsSize.width)
            make.height.greaterThanOrEqualTo(constraintsSize.height)
        }

        let edgeInsets = config.type.edgeInsets()
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: edgeInsets, bottom: 0, right: edgeInsets)

        self.titleLabel?.font = config.type.font()
    }

    private func update(isEnabled: Bool) {
        if isLoading {
            self.backgroundColor = config.loadingColor.backgroundColor
            self.layer.ud.setBorderColor(config.loadingColor.borderColor)
            self.setTitleColor(config.loadingColor.textColor, for: .normal)
        } else if isEnabled {
            self.backgroundColor = config.normalColor.backgroundColor
            self.layer.ud.setBorderColor(config.normalColor.borderColor)
        } else {
            self.backgroundColor = config.disableColor.backgroundColor
            self.layer.ud.setBorderColor(config.disableColor.borderColor)
        }
    }

    private func update(isHighlighted: Bool) {
        if isLoading {
            self.backgroundColor = config.loadingColor.backgroundColor
            self.layer.ud.setBorderColor(config.loadingColor.borderColor)
            self.setTitleColor(config.loadingColor.textColor, for: .normal)
        } else if isHighlighted {
            self.backgroundColor = config.pressedColor.backgroundColor
            self.layer.ud.setBorderColor(config.pressedColor.borderColor)
        } else {
            self.backgroundColor = config.normalColor.backgroundColor
            self.layer.ud.setBorderColor(config.normalColor.borderColor)
        }
    }

    private func addRotateAnimation(view: UIView, duration: CFTimeInterval = 1) {
        let key = "rotateAnimation"
        if let rotateAnimation = view.layer.animation(forKey: key), rotateAnimation.duration == duration {
            view.layer.add(rotateAnimation, forKey: key)
        } else {
            let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotateAnimation.fromValue = 0.0
            rotateAnimation.toValue = CGFloat(CGFloat.pi * 2)
            rotateAnimation.isRemovedOnCompletion = false
            rotateAnimation.duration = duration
            rotateAnimation.repeatCount = Float.infinity
            view.layer.add(rotateAnimation, forKey: key)
        }
    }

    private func removeRotateAnimation(view: UIView) {
        view.layer.removeAllAnimations()
    }
}
