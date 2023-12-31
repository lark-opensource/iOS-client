//
//  SubtitleFloatBackView.swift
//  ByteView
//
//  Created by panzaofeng on 2021/1/11.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import RxSwift
import Action
import SnapKit
import ByteViewUI
import UniverseDesignIcon

class SubtitleHistoryFloatBackView: UIControl {

    private lazy var icon: UIImageView = UIImageView()

    lazy var titleLabel: UILabel = {
        let l = UILabel()
        l.textColor = UIColor.ud.colorfulBlue
        return l
    }()

    var haveAddToContainer = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgFloat
        layer.ud.setShadow(type: .s4Down)
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        layer.borderWidth = 0.5
        layer.cornerRadius = 24
        icon.image = UDIcon.getIconByKey(.downBottomOutlined, iconColor: UIColor.ud.iconN1)
        addSubview(icon)

        titleLabel.attributedText = NSAttributedString(string: I18n.View_MV_NewSubArrow, config: .boldBodyAssist)
        addSubview(titleLabel)

        icon.snp.remakeConstraints { make in
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
        // 默认不显示title
        titleLabel.alpha = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // icon only -> icon + text
    func changeButtonStyleToText() {

        icon.image = UDIcon.getIconByKey(.downBottomOutlined, iconColor: UIColor.ud.colorfulBlue)
        icon.snp.remakeConstraints { make in
            make.left.equalTo(12)
            make.size.equalTo(12)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(3)
            make.right.equalTo(-12)
            make.centerY.equalToSuperview()
        }
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2) {
            self.layer.cornerRadius = 18
            self.titleLabel.alpha = 1
            self.layoutIfNeeded()
        }
    }
    func changeButtonStyleToIcon() {
        icon.image = UDIcon.getIconByKey(.downBottomOutlined, iconColor: UIColor.ud.iconN1)
        icon.snp.remakeConstraints { make in
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.size.equalTo(20)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
        // nolint-next-line: magic number
        UIView.animate(withDuration: 0.2) {
            self.layer.cornerRadius = 24
            self.titleLabel.alpha = 0
            self.layoutIfNeeded()
        }
    }
}
