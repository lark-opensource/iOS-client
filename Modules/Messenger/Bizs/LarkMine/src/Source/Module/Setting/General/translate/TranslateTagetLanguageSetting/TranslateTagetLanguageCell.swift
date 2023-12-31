//
//  TranslateTagetLanguageCell.swift
//  LarkMine
//
//  Created by 李勇 on 2019/5/13.
//

import Foundation
import UIKit
import LarkUIKit

/// 翻译目标语言设置cell
final class TranslateTagetLanguageCell: BaseTableViewCell {
    private let titleLabel = UILabel()
    private let selectIcon = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(16)
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }

        self.selectIcon.image = Resources.language_select
        self.selectIcon.isHidden = true
        self.contentView.addSubview(self.selectIcon)
        self.selectIcon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, isSelected: Bool) {
        self.titleLabel.text = title
        self.selectIcon.isHidden = !isSelected
    }
}
