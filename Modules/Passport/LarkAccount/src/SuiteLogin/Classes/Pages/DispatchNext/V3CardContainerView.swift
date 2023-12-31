//
//  V3CardContainerView.swift
//  AnimatedTabBar
//
//  Created by quyiming on 2020/1/1.
//

import Foundation
import LarkUIKit

extension UIColor {
    static let cellHighlightBackgroundColor: UIColor = UIColor.ud.bgFiller
    static let cellNormalBackgroundColor: UIColor = Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgLogin //lk.css("#FFFFFF")
}

protocol SelectionStyleProtocol {
    func updateSelection(_ selected: Bool)
}

class V3CardContainerView: UIView, SelectionStyleProtocol {
    convenience init() {
        self.init(frame: .zero)
        layer.borderWidth = 1
        layer.cornerRadius = Common.Layer.commonCardContainerViewRadius
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
//        layer.applySketchShadow(color: UIColor.ud.textTitle, alpha: 0.1, x: 0, y: 1, blur: 4, spread: 0)
        backgroundColor = .cellNormalBackgroundColor
    }

    func updateSelection(_ selected: Bool) {
        backgroundColor = selected ? .cellHighlightBackgroundColor : .cellNormalBackgroundColor
    }
}
