//
//  AppLockBackgroundViewV2.swift
//  LarkEMM
//
//  Created by chenjinglin on 2023/11/3.
//

import UIKit
import UniverseDesignColor
import UniverseDesignTheme

// 渐变层
struct AppLockSettingV2 {
    final class AppLockGradientView: UIView {
        // swiftlint:disable nesting
        final class ALayer: CAGradientLayer {
            static func getColors() -> [Any]? {
                if CurrentTheme.isDarkModeTheme {
                    return [
                        UDColor.rgb(0x374A44).cgColor,
                        UDColor.rgb(0x3A4A5B).cgColor,
                        UDColor.rgb(0x283442).cgColor
                    ]
                } else {
                    return [
                        UDColor.rgb(0xDCEFFF).cgColor,
                        UDColor.rgb(0xE2E9FB).cgColor,
                        UDColor.rgb(0xE2E5EF).cgColor
                    ]
                }
            }

            override init(layer: Any) {
                super.init(layer: layer)
                commonInit()
            }

            override init() {
                super.init()
                commonInit()
            }

            required init?(coder: NSCoder) {
                return nil
            }

            func commonInit() {
                opacity = 0.8
                colors = Self.getColors()
                locations = CurrentTheme.isDarkModeTheme ? [0, 0.44, 1] : [0, 0.49, 1]
                startPoint = CGPoint(x: 0.5, y: 0.25)
                endPoint = CGPoint(x: 0.5, y: 0.75)
            }
        }

        override class var layerClass: AnyClass { ALayer.self }
    }

    // swiftlint:disable:next line_length
    // https://www.figma.com/file/iTfvILLfZCdjEpZPCfAAT1/%F0%9F%96%A5-%E7%BB%88%E7%AB%AF%E5%AE%89%E5%85%A8---%E7%B2%98%E8%B4%B4%E4%BF%9D%E6%8A%A4%E3%80%81%E6%96%87%E4%BB%B6%E5%AE%89%E5%85%A8%E6%A3%80%E6%B5%8B%E7%AD%89?type=design&node-id=4000-251&mode=design&t=NHLptoDFHltPRby5-0
    final class AppLockBackgroundView: UIView {
        lazy var imageView: UIImageView = {
            let imageView = UIImageView(frame: bounds)
            let image = BundleResources.LarkEMM.app_lock_bg_icon.resizableImage(withCapInsets: .zero, resizingMode: .tile)
            imageView.image = image
            imageView.clipsToBounds = true
            imageView.alpha = CurrentTheme.isDarkModeTheme ? 1 : 0.1
            return imageView
        }()

        lazy var bgView: UIView = {
            let bgView = UIView(frame: bounds)
            bgView.alpha = CurrentTheme.isDarkModeTheme ? 1 : 0
            bgView.backgroundColor = UDColor.staticBlack.withAlphaComponent(0.28)
            return bgView
        }()

        lazy var gradientView = AppLockGradientView(frame: bounds)

        override init(frame: CGRect) {
            super.init(frame: frame)
            layer.masksToBounds = true
            backgroundColor = UDColor.N00 & UDColor.rgb(0x5A5A5A)
            // 渐变层
            addSubview(gradientView)
            // 灰色蒙层
            addSubview(bgView)
            // 噪点层
            addSubview(imageView)
            gradientView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            bgView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            drawBackgroundView()
        }

        required init?(coder: NSCoder) {
            return nil
        }

        private func drawBackgroundView() {
            bgView.alpha = CurrentTheme.isDarkModeTheme ? 1 : 0
            imageView.alpha = CurrentTheme.isDarkModeTheme ? 1 : 0.1
            if let layer = gradientView.layer as? AppLockGradientView.ALayer {
                layer.commonInit()
            }
        }

        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            guard #available(iOS 13.0, *),
                  traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
                return
            }
            drawBackgroundView()
        }
    }
    // swiftlint:enable nesting
}

struct CurrentTheme {
    static var isDarkModeTheme: Bool {
        if #available(iOS 13.0, *) {
            return UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        return false
    }
}
