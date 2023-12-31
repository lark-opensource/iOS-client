//
//  QuickLaunchAuroraView.swift
//  AnimatedTabBar
//
//  Created by Hayden Wang on 2023/7/18.
//

import UIKit
import FigmaKit

public class QuickLaunchAuroraView: AuroraView {

    private let isPopover: Bool

    lazy var lightModeConfig = AuroraViewConfiguration(
        mainBlob: .init(color: UIColor.ud.B600,
                        frame: CGRect(x: -120, y: -160, width: 200, height: 240),
                        opacity: 0.18,
                        blurRadius: 100),
        subBlob: .init(color: UIColor.ud.B500,
                       frame: CGRect(x: -10, y: -140, width: 228, height: 220),
                       opacity: 0.25,
                       blurRadius: 100),
        reflectionBlob: .init(color: UIColor.ud.T350,
                              frame: CGRect(x: 150, y: -120, width: 160, height: 180),
                              opacity: 0.2,
                              blurRadius: 100)
    )

    lazy var darkModeConfig = AuroraViewConfiguration(
        mainBlob: .init(color: UIColor.ud.B300,
                        frame: CGRect(x: -120, y: -160, width: 200, height: 240),
                        opacity: 0.5,
                        blurRadius: 100),
        subBlob: .init(color: UIColor.ud.B300,
                       frame: CGRect(x: -10, y: -140, width: 228, height: 220),
                       opacity: 0.4,
                       blurRadius: 100),
        reflectionBlob: .init(color: UIColor.ud.T400,
                              frame: CGRect(x: 150, y: -120, width: 160, height: 180),
                              opacity: 0.4,
                              blurRadius: 100)
    )

    public override init(frame: CGRect) {
        self.isPopover = false
        super.init(frame: frame)
        updateAppearanceByCurrentTheme()
        backgroundColor = .clear
    }

    public init(isPopover: Bool = false) {
        self.isPopover = isPopover
        super.init(config: .default, blobType: .gradient)
        updateAppearanceByCurrentTheme()
        if #unavailable(iOS 13), isPopover {
            // 处理低版本系统 Popover 默认底色不一致问题
            backgroundColor = UIColor.ud.bgFloatBase.withAlphaComponent(0.7)
        } else {
            backgroundColor = .clear
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateAppearanceByCurrentTheme() {
        if #available(iOS 13.0, *), traitCollection.userInterfaceStyle == .dark {
            updateAppearance(with: darkModeConfig, animated: false)
            blobsOpacity = isPopover ? 0.2 : 0.4
        } else {
            updateAppearance(with: lightModeConfig, animated: false)
            blobsOpacity = isPopover ? 0.22 : 0.8
        }
        blobsBlurRadius = 100
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearanceByCurrentTheme()
        }
    }
}
