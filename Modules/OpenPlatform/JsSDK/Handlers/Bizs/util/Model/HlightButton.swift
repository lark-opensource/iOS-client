//
//  HlightButton.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/11/14.
//

import UIKit

class HlightButton: UIButton {
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor(white: 1, alpha: 0.2) : UIColor.clear
        }
    }
}
