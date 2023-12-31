//
//  MosaicTypeButton.swift
//  LarkUIKit
//
//  Created by ChalrieSu on 2018/8/5.
//  Copyright © 2018 liuwanlin. All rights reserved.
//

import Foundation
import UIKit

final class MosaicTypeButton: UIButton {
    let type: MosaicType

    init(type: MosaicType) {
        self.type = type
        super.init(frame: CGRect.zero)
        switch type {
        case .Gaussan:
            setImage(Resources.edit_Gaussan_effect, for: .normal)
        case .mosaic:
            setImage(Resources.edit_mosaic_effect, for: .normal)
        }
        snp.makeConstraints { (make) in
            make.width.equalTo(60)
            make.height.equalTo(30)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isSelected: Bool {
        didSet {
            if isSelected {
                layer.borderColor = UIColor.ud.color(0, 121, 255).cgColor
                layer.borderWidth = 3
                layer.cornerRadius = 2
                layer.masksToBounds = true
            } else {
                layer.borderColor = UIColor.clear.cgColor
                layer.borderWidth = 0
                layer.cornerRadius = 0
            }
        }
    }
}
