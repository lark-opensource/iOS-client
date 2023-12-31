//
//  TranslateLanguagesCell.swift
//  LarkMine
//
//  Created by 李勇 on 2019/5/13.
//

import UIKit
import Foundation
import LarkUIKit
import UniverseDesignCheckBox

/// 展示语言的单选样式cell
final class TranslateLanguagesCell: BaseTableViewCell {
    /// 标题
    private let titleLabel = UILabel()
    /// 选中图标
    private let checkBox = UDCheckBox(boxType: .list)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        /// 标题
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .left
        self.titleLabel.textColor = UIColor.ud.N900
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(16)
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        }
        /// 选中图标
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
    }
}
