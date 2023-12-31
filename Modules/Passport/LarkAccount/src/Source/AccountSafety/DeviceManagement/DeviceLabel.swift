//
//  DeviceLabel.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/3/28.
//

import UIKit
import UniverseDesignColor

class DeviceLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UDColor.udtokenTagBgRed
        layer.cornerRadius = 4
        layer.masksToBounds = true
        font = .systemFont(ofSize: 12, weight: .medium)
        setContentCompressionResistancePriority(.required, for: .horizontal)
        textColor = UDColor.udtokenTagTextSRed
        textAlignment = .center
    }
    
    override var intrinsicContentSize: CGSize {
        let contentSize = super.intrinsicContentSize
        return CGSize(width: contentSize.width + 8, height: 18)
    }
}
