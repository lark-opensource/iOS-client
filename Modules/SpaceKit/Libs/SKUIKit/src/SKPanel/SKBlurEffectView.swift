//
//  SKBlurEffectView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/8/31.
//

import UIKit
import UniverseDesignColor

// CCM 标准的毛玻璃效果
public final class SKBlurEffectView: UIView {

    private lazy var blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        let view = UIVisualEffectView(effect: blurEffect)
        view.contentView.backgroundColor = .clear
        return view
    }()

    private lazy var maskColorView = UIView()

    private static var popoverColor: UIColor {
        let lightColor = UDColor.bgFloatBase.withAlphaComponent(0.7)
        let darkColor = UDColor.bgFloatBase.alwaysDark.withAlphaComponent(0.85)
        return lightColor & darkColor
    }

    private static var standardColor: UIColor {
        let lightColor = UDColor.bgFloatBase.withAlphaComponent(0.7)
        let darkColor = UDColor.bgFloatBase.alwaysDark.withAlphaComponent(0.6)
        return lightColor & darkColor
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear
        addSubview(blurView)
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(maskColorView)
        maskColorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public func updateMaskColor(isPopover: Bool) {
        blurView.isHidden = isPopover
        maskColorView.backgroundColor = isPopover ? Self.popoverColor : Self.standardColor
    }

    public func set(cornerRadius: CGFloat, corners: CACornerMask) {
        blurView.layer.cornerRadius = cornerRadius
        blurView.layer.maskedCorners = corners
        blurView.clipsToBounds = true
        maskColorView.layer.cornerRadius = cornerRadius
        maskColorView.layer.maskedCorners = corners
        maskColorView.clipsToBounds = true
    }
}
