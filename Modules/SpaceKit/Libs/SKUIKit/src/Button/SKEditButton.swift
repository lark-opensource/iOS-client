//
// Created by duanxiaochen.7 on 2021/9/29.
// Affiliated with SKUIKit.
//
// Description:


import UIKit
import SKResource
import UniverseDesignColor
import UniverseDesignShadow
import UniverseDesignIcon

open class SKEditButton: UIButton {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if isHighlighted {
            backgroundColor = UDColor.primaryFillSolid02
        } else {
            backgroundColor = UDColor.bgFloat
        }
    }

    public override var isHighlighted: Bool {
        didSet {
            guard isEnabled else { return }
            if isHighlighted {
                backgroundColor = UDColor.primaryFillSolid02
            } else {
                backgroundColor = UDColor.bgFloat
            }
        }
    }

    private func setupUI() {
        layer.borderWidth = 0.5
        layer.ud.setBorderColor(UDColor.lineBorderCard)
        layer.ud.setShadow(type: .s4Down)
        setImage(UDIcon.ccmEditOutlined.ud.withTintColor(UDColor.primaryContentDefault), for: .normal)
        backgroundColor = UDColor.bgFloat
        adjustsImageWhenHighlighted = false
        adjustsImageWhenDisabled = false
        docs.addStandardLift()
        self.accessibilityIdentifier = "docs.edit.button"
    }
}
