//
//  MinutesCollectionButton.swift
//  ByteViewTab
//
//  Created by 陈乐辉 on 2023/5/6.
//

import Foundation
import UIKit
import UniverseDesignIcon
import SnapKit

final class MinutesCollectionButton: UIButton {

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.text = I18n.View_G_BreakoutRecordings
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    lazy var icon: UIImageView = {
        let iv = UIImageView()
        iv.image = UDIcon.getIconByKey(.rightSmallCcmOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: 16, height: 16))
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
        }
        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.centerY.equalToSuperview()
            make.left.equalTo(textLabel.snp.right).offset(2)
            make.right.equalToSuperview()
        }
        layer.cornerRadius = 4
        clipsToBounds = true
        setBackgroundColor(UIColor.ud.fillPressed, for: .highlighted)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
