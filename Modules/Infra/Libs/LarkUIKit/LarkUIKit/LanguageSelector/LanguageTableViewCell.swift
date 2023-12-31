//
//  LanguageTableViewCell.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2020/6/8.
//

import Foundation
import UIKit
import UniverseDesignCheckBox

final class LanguageTableViewCell: BaseSettingCell {
    private lazy var titleLabel: UILabel = UILabel()
    private lazy var checkBox: UDCheckBox = UDCheckBox(boxType: .list)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.numberOfLines = 2
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-50)
            make.top.equalTo(12)
            make.bottom.equalTo(-12)
            make.centerY.equalToSuperview()
        }

        self.checkBox.isHidden = true
        self.checkBox.isUserInteractionEnabled = false
        self.contentView.addSubview(self.checkBox)
        self.checkBox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, isSelected: Bool) {
        self.titleLabel.text = title
        self.checkBox.isSelected = isSelected
        self.checkBox.isHidden = !isSelected
    }
}
