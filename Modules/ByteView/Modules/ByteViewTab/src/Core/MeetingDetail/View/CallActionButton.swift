//
//  CallActionButton.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/11/24.
//

import Foundation
import SnapKit
import ByteViewUI

class CallActionButton: UIView {

    lazy var button: VisualButton = {
        let button = VisualButton(type: .custom)
        button.edgeInsetStyle = .top
        button.space = 2
        button.isExclusiveTouch = true
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 10
        button.setBackgroundColor(.ud.bgFloat, for: .normal)
        button.setBackgroundColor(.ud.udtokenBtnSeBgNeutralPressed, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.titleLabel?.lineBreakMode = .byTruncatingMiddle
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(UIColor.ud.N700.dynamicColor, for: .normal)
        button.adjustsImageWhenHighlighted = false
        button.addInteraction(type: .lift)
        return button
    }()

    var rightConstraint: Constraint?
    var widthConstraint: Constraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.ud.setShadow(type: .s2Down)
        addSubview(button)
        button.snp.makeConstraints { [weak self] in
            $0.left.top.bottom.equalToSuperview()
            self?.rightConstraint = $0.right.equalToSuperview().constraint
            self?.widthConstraint = $0.width.equalTo(0).constraint
            self?.widthConstraint?.deactivate()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
