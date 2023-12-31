//
//  PSTNDisabledTipView.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/3/31.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignIcon

class PSTNDisabledTipView: UIView {

    private lazy var icon: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.image = UDIcon.getIconByKey(.infoFilled, iconColor: .ud.primaryContentDefault, size: CGSize(width: 16, height: 16))
        return imageView
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.backgroundColor = .clear
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.attributedText = NSAttributedString(string: I18n.View_G_UpgradePlanToExtendPhoneCallLimit, config: .bodyAssist)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor.ud.primaryFillSolid02
        addSubview(icon)
        addSubview(label)
        icon.snp.makeConstraints { (maker) in
            maker.size.equalTo(16)
            maker.left.equalTo(16)
            maker.top.equalTo(14)
        }

        label.snp.makeConstraints { (maker) in
            maker.left.equalTo(icon.snp.right).offset(8)
            maker.top.bottom.equalToSuperview().inset(12)
            maker.right.equalToSuperview().offset(-16)
        }
    }

    func changeTipsInfo(message: String) {
        label.text = message
    }
}
