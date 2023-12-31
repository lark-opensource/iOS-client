//
//  EMAHighlightButton.swift
//  EEMicroAppSDK
//
//  Created by 武嘉晟 on 2019/11/19.
//

import UIKit

/// 点击高亮按钮
public final class EMAHighlightButton: UIButton {
    override public var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor(white: 1, alpha: 0.2) : UIColor.clear
        }
    }
}
