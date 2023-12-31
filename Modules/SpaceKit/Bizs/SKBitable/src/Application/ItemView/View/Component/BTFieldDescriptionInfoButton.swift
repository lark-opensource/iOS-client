//
// Created by duanxiaochen.7 on 2021/12/6.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import UIKit
import SKUIKit
import SnapKit
import UniverseDesignColor
import UniverseDesignIcon

final class BTFieldTipsButton: UIButton {

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.udtokenBtnTextBgNeutralHover.withAlphaComponent(0.1)
            } else {
                if isSelected {
                    backgroundColor = UDColor.primaryContentDefault.withAlphaComponent(0.1)
                } else {
                    backgroundColor = .clear
                }
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            if isHighlighted {
                backgroundColor = UDColor.udtokenBtnTextBgNeutralHover.withAlphaComponent(0.1)
            } else {
                if isSelected {
                    backgroundColor = UDColor.primaryContentDefault.withAlphaComponent(0.1)
                } else {
                    backgroundColor = .clear
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 6
        contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    }

    func setImage(iconType: UDIconType,
                  withColorsForStates: [(UIColor, UIControl.State)] = []) {
        let image = UDIcon.getIconByKey(iconType, size: CGSize(width: 16, height: 16))
        if withColorsForStates.isEmpty {
            setImage(image, for: [.normal, .highlighted, .selected])
            return
        }
        setImage(image, withColorsForStates: withColorsForStates)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
