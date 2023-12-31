//
//  UDLoading+Spin.swift
//  UniverseDesignLoading
//
//  Created by Miaoqi Wang on 2020/11/11.
//

import UIKit
import Foundation

extension UDLoading {
    /// Spin Loading
    public static func spin(config: UDSpinConfig) -> UDSpin {
        return UDSpin(config: config)
    }

    /// Preset Spin Generator
    /// - Parameters:
    ///   - color: Spin preset color
    ///   - size: Spin size
    ///   - loadingText: text color
    ///   - textDistribution: text distribution
    public static func presetSpin(color: UDSpin.PresetColor = .primary,
                                  size: UDSpin.PresetSize = .normal,
                                  loadingText: String? = nil,
                                  textDistribution: UDSpinConfig.TextDistribution = .vertial) -> UDSpin {
        var labelConfig: UDSpinLabelConfig?
        if let text = loadingText {
            labelConfig = UDSpinLabelConfig(
                text: text,
                font: UIFont.systemFont(ofSize: UDSpin.Layout.textFontSize),
                textColor: color.color().text)
        }
        let config = UDSpinConfig(
            indicatorConfig: .init(
                size: size.size(),
                color: color.color().indicator
            ),
            textLabelConfig: labelConfig,
            textDistribution: textDistribution
        )
        return UDSpin(config: config)
    }
}
