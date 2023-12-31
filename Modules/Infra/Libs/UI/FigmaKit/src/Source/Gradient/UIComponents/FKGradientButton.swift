//
//  FKGradientButton.swift
//  FigmaKit
//
//  Created by Hayden on 2023/5/25.
//

import UIKit

open class FKGradientButton: UIButton {

    public struct ColorStyle {

        public var background: GradientPattern
        public var border: GradientPattern

        public var highlightedBackground: GradientPattern?
        public var highlightedBorder: GradientPattern?

        public var disabledBackground: GradientPattern?
        public var disabledBorder: GradientPattern?

        public static var `default`: ColorStyle {
            ColorStyle(
                background: .init(direction: .leftToRight, colors: [.systemBlue, .systemGreen]),
                border: .clear)
        }

        public init(background: GradientPattern,
                    border: GradientPattern,
                    highlightedBackground: GradientPattern? = nil,
                    highlightedBorder: GradientPattern? = nil,
                    disabledBackground: GradientPattern? = nil,
                    disabledBorder: GradientPattern? = nil) {
            self.background = background
            self.border = border
            self.highlightedBackground = highlightedBackground
            self.highlightedBorder = highlightedBorder
            self.disabledBackground = disabledBackground
            self.disabledBorder = disabledBorder
        }

        public static func solidGradient(background: GradientPattern,
                                         highlightedBackground: GradientPattern? = nil,
                                         disabledBackground: GradientPattern? = nil) -> ColorStyle {
            return ColorStyle(
                background: background,
                border: .clear,
                highlightedBackground: highlightedBackground,
                highlightedBorder: .clear,
                disabledBackground: disabledBackground,
                disabledBorder: .clear
            )
        }
    }

    open var cornerRadius: CGFloat = 0 {
        didSet {
            updateGradientColors()
        }
    }

    open var borderWidth: CGFloat = 0 {
        didSet {
            updateGradientColors()
        }
    }

    open override var isHighlighted: Bool {
        didSet {
            updateGradientColors()
        }
    }

    open override var isEnabled: Bool {
        didSet {
            updateGradientColors()
        }
    }

    open var colorStyle: ColorStyle = .default {
        didSet {
            updateGradientColors()
        }
    }

    private lazy var gradientBgLayer: FKGradientLayer = {
        let gradientLayer = FKGradientLayer(type: .linear)
        gradientLayer.direction = .leftToRight
        return gradientLayer
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(gradientBgLayer)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        gradientBgLayer.frame = bounds
        updateGradientColors()
    }

    private func updateGradientColors() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        if isHighlighted {
            // highlight
            gradientBgLayer.updatePattern(colorStyle.highlightedBackground ?? colorStyle.background)
            setGradientBorder(pattern: colorStyle.highlightedBorder ?? colorStyle.border, width: borderWidth, cornerRadius: cornerRadius)
        } else if !isEnabled {
            // disable
            gradientBgLayer.updatePattern(colorStyle.disabledBackground ?? colorStyle.background)
            setGradientBorder(pattern: colorStyle.disabledBorder ?? colorStyle.border, width: borderWidth, cornerRadius: cornerRadius)
        } else {
            // normal
            gradientBgLayer.updatePattern(colorStyle.background)
            setGradientBorder(pattern: colorStyle.border, width: borderWidth, cornerRadius: cornerRadius)
        }
        /* 如果需要 title 也做渐变，则需要添加另外的 layer，并设置 mask
        gradientTitleLayer.mask = titleLabel?.layer
        gradientImageLayer.mask = imageView?.layer
         */
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateGradientColors()
            }
        }
    }

    open func setInsets(iconTitleSpacing: CGFloat, contentInsets: UIEdgeInsets = .zero) {
        self.contentEdgeInsets = UIEdgeInsets(
            top: contentInsets.top,
            left: contentInsets.left,
            bottom: contentInsets.bottom,
            right: contentInsets.right + iconTitleSpacing
        )
        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: iconTitleSpacing,
            bottom: 0,
            right: -iconTitleSpacing
        )
    }
}

public extension UIColor {
    /// Create a ligher color
    func lighter(byPercentage percentage: CGFloat = 20) -> UIColor {
        return self.adjustBrightness(byPercentage: abs(percentage))
    }
    /// Create a darker color
    func darker(byPercentage percentage: CGFloat = 20) -> UIColor {
        return self.adjustBrightness(byPercentage: -abs(percentage))
    }
    /// Try to increase brightness or decrease beightness
    func adjustBrightness(byPercentage percentage: CGFloat = 20) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            let newB: CGFloat = max(0, min(1.0, b + (percentage / 100.0) * b))
            return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
        }
        return self
    }
    /// Create a brightness color
    func colorWithBrightness(_ brightness: CGFloat) -> UIColor {
        guard brightness >= 0, brightness <= 100 else { return self }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            let newB = brightness / 100
            return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
        }
        return self
    }
}

public class FKMultiLineGradientButton: FKGradientButton {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.numberOfLines = 0
        titleLabel?.lineBreakMode = .byWordWrapping
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var intrinsicContentSize: CGSize {
        let size = titleLabel?.intrinsicContentSize ?? .zero
        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: size.height + contentEdgeInsets.top + contentEdgeInsets.bottom
        )
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.preferredMaxLayoutWidth = titleLabel?.frame.size.width ?? 0
    }
}
