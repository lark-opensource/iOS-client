//
//  UDSpin.swift
//  UniverseDesignLoading
//
//  Created by Miaoqi Wang on 2020/10/15.
//

import Foundation
import UIKit
import UniverseDesignColor
import SnapKit

/// Spin indicator config
public struct UDSpinIndicatorConfig {

    /// Indicator Size
    public let size: CGFloat

    /// Indicator Color
    public let color: UIColor

    /// Degree of the indicator circle
    public let circleDegree: CGFloat

    /// Animation duration
    public let animationDuration: TimeInterval

    /// Indicator's line width
    let lineWidth: CGFloat

    /// Initialization
    /// - Parameters:
    ///   - size: Spin size
    ///   - color: Spin color
    ///   - lineWidth: Spin line width
    ///   - circleDegree: Spin circle degree, range from 0.1 to 0.9, default is 0.6
    ///   - animationDuration: animation duration default 1.2s
    public init(size: CGFloat,
                color: UIColor,
                circleDegree: CGFloat = 0.6,
                animationDuration: TimeInterval = 1.2) {
        self.size = size * UDSpin.Layout.indicatorSizeRatio
        self.color = color
        self.lineWidth = size * UDSpin.Layout.indicatorLineWidthRatio
        self.circleDegree = circleDegree
        self.animationDuration = animationDuration
    }
}

/// UDSpin text config
public struct UDSpinLabelConfig {

    /// text content
    public let text: String

    /// text font
    public let font: UIFont

    /// text color
    public let textColor: UIColor

    /// Initialization
    public init(text: String, font: UIFont, textColor: UIColor) {
        self.text = text
        self.font = font
        self.textColor = textColor
    }
}

/// UDSpin Config
public struct UDSpinConfig {

    /// Indicator config
    public let indicatorConfig: UDSpinIndicatorConfig
    /// Text config
    public let textLabelConfig: UDSpinLabelConfig?
    /// Distribution of text and indicator
    public let textDistribution: TextDistribution

    /// Initialization
    /// - Parameters:
    ///   - indicatorConfig: Indicator config
    ///   - textLabelConfig: Text label config
    ///   - textDistribution: Text and indicator distribution
    public init(indicatorConfig: UDSpinIndicatorConfig,
                textLabelConfig: UDSpinLabelConfig?,
                textDistribution: TextDistribution = .vertial) {
        self.indicatorConfig = indicatorConfig
        self.textLabelConfig = textLabelConfig
        self.textDistribution = textDistribution
    }

    /// Distribution of text and indicator
    public enum TextDistribution {
        /// Indicator on left as text on right
        case horizonal
        /// Indicator on top as text on bottom
        case vertial
    }
}

/// Spin Loading Component
public final class UDSpin: UIView {
    let indicator: UDSpinInicator
    var textLabel: UILabel?

    /// Initialization
    public init(config: UDSpinConfig) {
        let indicatorCfg = config.indicatorConfig
        self.indicator = UDSpinInicator(
            size: indicatorCfg.size,
            color: indicatorCfg.color,
            lineWidth: indicatorCfg.lineWidth,
            circleDegree: indicatorCfg.circleDegree,
            animationDuration: indicatorCfg.animationDuration
        )
        super.init(frame: .zero)
        clipsToBounds = true

        updateTextLabel(config: config)
        addSubview(indicator)
        layout(config: config)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func update(config: UDSpinConfig) {
        let indicatorConfig = config.indicatorConfig
        indicator.update(size: indicatorConfig.size,
                         color: indicatorConfig.color,
                         lineWidth: indicatorConfig.lineWidth,
                         circleDegree: indicatorConfig.circleDegree,
                         animationDuration: indicatorConfig.animationDuration)
        updateTextLabel(config: config)
        layout(config: config)
    }

    func updateTextLabel(config: UDSpinConfig) {
        if let textConfig = config.textLabelConfig {
            if self.textLabel == nil {
                let label = UILabel()
                label.numberOfLines = 0
                self.textLabel = label
                addSubview(label)
            }
            self.textLabel?.font = textConfig.font
            self.textLabel?.text = textConfig.text
            self.textLabel?.textColor = textConfig.textColor
        } else {
            self.textLabel?.removeFromSuperview()
            self.textLabel = nil
        }
    }

    func layout(config: UDSpinConfig) {
        // edge和lineWidth一样，都是size * 0.1
        let indicatorEdge = config.indicatorConfig.lineWidth
        indicator.snp.remakeConstraints { (make) in
            if textLabel == nil {
                make.edges.equalToSuperview().inset(indicatorEdge)
            } else {
                switch config.textDistribution {
                case .horizonal:
                    make.leading.equalToSuperview().offset(indicatorEdge)
                    make.centerY.equalToSuperview()
                    make.top.greaterThanOrEqualToSuperview().offset(indicatorEdge)
                    make.bottom.lessThanOrEqualToSuperview().inset(indicatorEdge)
                case .vertial:
                    make.top.equalToSuperview().offset(indicatorEdge)
                    make.leading.greaterThanOrEqualToSuperview().offset(indicatorEdge)
                    make.trailing.lessThanOrEqualToSuperview().inset(indicatorEdge)
                    make.centerX.equalToSuperview()
                }
            }
            make.size.equalTo(config.indicatorConfig.size)
        }
        addLabelIfHas(distribution: config.textDistribution, indicatorSpace: indicatorEdge + Layout.edgeDistance)
    }

    func addLabelIfHas(distribution: UDSpinConfig.TextDistribution, indicatorSpace: CGFloat) {
        if let label = textLabel {
            switch distribution {
            case .vertial:
                label.snp.remakeConstraints { (make) in
                    make.centerX.equalTo(indicator)
                    make.top.equalTo(indicator.snp.bottom).offset(indicatorSpace)
                    make.leading.greaterThanOrEqualToSuperview()
                    make.trailing.lessThanOrEqualToSuperview()
                    make.bottom.equalToSuperview().inset(Layout.edgeDistance)
                }
            case .horizonal:
                label.snp.remakeConstraints { (make) in
                    make.leading.equalTo(indicator.snp.trailing).offset(indicatorSpace)
                    make.top.greaterThanOrEqualToSuperview()
                    make.bottom.lessThanOrEqualToSuperview()
                    make.centerY.equalTo(indicator)
                    make.trailing.equalToSuperview().inset(Layout.edgeDistance)
                }
            }
        }
    }
}

// MARK: - Preset Spin
extension UDSpin {

    /// Preset color
    public enum PresetColor {
        /// Indicator colorfulBlue & Text N600
        case primary
        /// Indicator N00 & Text N00
        case neutralWhite
        /// Indicator N400 & Text N400
        case neutralGray

        func defaultColor() -> (indicator: UIColor, text: UIColor) {
            switch self {
            case .primary: return (UIColor.ud.primaryColor6, UIColor.ud.neutralColor8)
            case .neutralWhite: return (UIColor.ud.neutralColor1, UIColor.ud.neutralColor1)
            case .neutralGray: return (UIColor.ud.neutralColor6, UIColor.ud.neutralColor6)
            }
        }

        func color() -> (indicator: UIColor, text: UIColor) {
            return UDLoadingColorTheme.spinColor(preset: self)
        }
    }

    /// Preset Size
    public enum PresetSize {
        /// 24 * 24
        case normal
        /// 40 * 40
        case large

        func size() -> CGFloat {
            switch self {
            case .normal: return Layout.normalIndicatorSize
            case .large: return Layout.largeIndicatorSize
            }
        }
    }

    public func reset() {
        self.indicator.getShapeLayer()
    }
}

extension UDSpin {

    /// convience method for add spin to view center
    /// - Parameters:
    ///   - animated: set true if need animation
    public func addToCenter(on view: UIView) {
        view.addSubview(self)
        self.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.top.leading.greaterThanOrEqualToSuperview()
            make.bottom.trailing.lessThanOrEqualToSuperview()
        }
    }
}

extension UDSpin {
    enum Layout {
        static let largeIndicatorSize: CGFloat = 40
        static let normalIndicatorSize: CGFloat = 24
        static let indicatorLineWidthRatio: CGFloat = 1 / 10
        static let indicatorSizeRatio: CGFloat = 8 / 10
        static let edgeDistance: CGFloat = 8.0
        static let textFontSize: CGFloat = 14.0
    }
}
