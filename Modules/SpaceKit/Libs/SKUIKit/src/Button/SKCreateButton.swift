//
//  SKCreateButton.swift
//  SKUIKit
//
//  Created by Weston Wu on 2020/12/14.
//

import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignIcon

open class SKCreateButton: UIButton {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }


    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    public override var isHighlighted: Bool {
        didSet {
            guard isEnabled else { return }
            if isHighlighted {
                backgroundColor = UDColor.primaryFillPressed
            } else {
                backgroundColor = UDColor.primaryFillDefault
            }
        }
    }

    public override var isEnabled: Bool {
        didSet {
            if isEnabled {
                backgroundColor = UDColor.primaryFillDefault
                layer.ud.setShadow(type: .s4DownPri)
            } else {
                backgroundColor = UDColor.iconDisabled
                layer.ud.setShadow(type: .s4Down)
            }
        }
    }

    private func setupUI() {
        layer.ud.setShadow(type: .s4DownPri)
        setImage(UDIcon.addOutlined.ud.withTintColor(UDColor.primaryOnPrimaryFill), for: .normal)
        backgroundColor = UDColor.primaryFillDefault
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false
        docs.addStandardLift()
        self.accessibilityIdentifier = "docs.space.more.button"
    }
}
