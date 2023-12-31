//
//  MeetTabScrollToTopButton.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import ByteViewUI

class MeetTabScrollToTopButton: UIView {

    var buttonColor: UIColor = .ud.N650 & .ud.iconN1

    lazy var button: VisualButton = {
        let button = VisualButton()
        button.setImage(UDIcon.getIconByKey(.upTopOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20)), for: .normal)
        button.setImage(UDIcon.getIconByKey(.upTopOutlined, iconColor: .ud.iconN1, size: CGSize(width: 20, height: 20)), for: .highlighted)
        button.setBackgroundColor(.ud.bgFloat, for: .normal)
        button.setBackgroundColor(.ud.udtokenBtnSeBgNeutralHover, for: .highlighted)
        button.layer.borderWidth = 0.5
        button.setBorderColor(.ud.N900.withAlphaComponent(0.15) & .ud.lineBorderCard, for: .normal)
        button.clipsToBounds = true
        return button
    }()

    lazy var shadow: CALayer = {
        let layer = CALayer()
        layer.ud.setShadowColor(.ud.shadowDefaultMd, bindTo: self)
        layer.shadowOpacity = 1
        layer.shadowRadius = 8.0
        layer.shadowOffset = CGSize(width: 0, height: 4)
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addInteraction(type: .lift)
        layer.addSublayer(shadow)
        addSubview(button)
        button.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(self.snp.width)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        button.layer.cornerRadius = bounds.width / 2
        let shadowFrame = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.width))
        shadow.frame = shadowFrame
        shadow.shadowPath = UIBezierPath(roundedRect: shadowFrame, cornerRadius: bounds.width / 2).cgPath
    }
}
