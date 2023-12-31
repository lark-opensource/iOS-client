//
//  MineTranslateRadioCell.swift
//  LarkMine
//
//  Created by 李勇 on 2019/9/27.
//

import UIKit
import Foundation
import LarkUIKit
import LarkModel
import RustPB
import UniverseDesignCheckBox

struct MineTranslateRadioModel: MineTranslateItemProtocol {
    var cellIdentifier: String
    var title: String
    var languageKey: String = ""
    var status: Bool
    var translateDisplayRule: RustPB.Basic_V1_DisplayRule?
    var isRadioLeft: Bool?
    var tapHandler: MineTranslateTapHandler
}

/// 单选
final class MineTranslateRadioCell: MineTranslateBaseCell {
    /// 标题
    private let titleLabel = UILabel()
    /// radio
    private let radioImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.radioImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.radioImageView.setContentHuggingPriority(.required, for: .horizontal)
        self.contentView.addSubview(self.radioImageView)

        /// 标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let currItem = self.item as? MineTranslateRadioModel {
            currItem.tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }

    override func setCellInfo() {
        guard let currItem = self.item as? MineTranslateRadioModel else {
            return
        }
        self.titleLabel.text = currItem.title
        self.radioImageView.image = currItem.status ? Resources.left_method_select_icon : Resources.left_method_normal_icon

        if let isRadioLeft = currItem.isRadioLeft, isRadioLeft {
            self.radioImageView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(16)
            }
            self.titleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(radioImageView.snp.right).offset(12)
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualTo(-16)
            }

        } else {
            self.radioImageView.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.right.equalTo(-16)
            }
            self.titleLabel.snp.remakeConstraints { (make) in
                make.left.top.equalTo(16)
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualTo(self.radioImageView.snp.left).offset(-16)
            }
        }

    }
}

/// 单选
final class MineTranslateCheckListBoxCell: MineTranslateBaseCell {
    /// 标题
    private let titleLabel = UILabel()
    private lazy var checkBox: UDCheckBox = UDCheckBox(boxType: .list)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.checkBox.isHidden = true
        self.checkBox.isUserInteractionEnabled = false
        self.contentView.addSubview(self.checkBox)

        /// 标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let currItem = self.item as? MineTranslateRadioModel {
            currItem.tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }

    override func setCellInfo() {
        guard let currItem = self.item as? MineTranslateRadioModel else {
            return
        }
        self.checkBox.isSelected = currItem.status
        self.checkBox.isHidden = !currItem.status
        self.titleLabel.text = currItem.title
        self.checkBox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        self.titleLabel.snp.remakeConstraints { (make) in
            make.left.top.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(self.checkBox.snp.left).offset(-16)
        }
    }
}
