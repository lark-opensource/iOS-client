//
//  MineTranslateSwitchCell.swift
//  Lark
//
//  Created by zhenning on 2020/02/11.
//

import UIKit
import Foundation

struct MineTranslateSwitchModel: MineTranslateItemProtocol {
    var cellIdentifier: String
    var title: String
    var detail: String = ""
    var status: Bool
    var enabled: Bool = true
    var switchHandler: MineTranslateSwitchHandler
}

/// title + detail + switch
final class MineTranslateSwitchCell: MineTranslateBaseCell {
    /// 中间标题
    private let titleLabel = UILabel()
    /// 详情
    private let detailLabel = UILabel()
    /// 开关
    private let switchButton = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        /// 开关
        self.switchButton.onTintColor = UIColor.ud.primaryContentDefault
        self.switchButton.isEnabled = false
        self.switchButton.addTarget(self, action: #selector(switchButtonTapped), for: .valueChanged)

        self.contentView.addSubview(self.switchButton)
        self.switchButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.switchButton.setContentHuggingPriority(.required, for: .horizontal)
        self.switchButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16.5)
        }

        /// 中间标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)

        /// 详情
        self.detailLabel.textColor = UIColor.ud.textPlaceholder
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.detailLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func switchButtonTapped(sender: Any) {
        if let currItem = self.item as? MineTranslateSwitchModel {
            currItem.switchHandler(switchButton.isOn)
        }
    }

    override func setCellInfo() {
        guard let currItem = self.item as? MineTranslateSwitchModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.switchButton.isOn = currItem.status
        self.switchButton.isEnabled = currItem.enabled
        self.titleLabel.text = currItem.title
        self.detailLabel.text = currItem.detail
        self.detailLabel.isHidden = currItem.detail.isEmpty
        if currItem.detail.isEmpty {
            self.titleLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.top.equalTo(16)
                make.left.equalTo(16)
                make.right.lessThanOrEqualTo(self.switchButton.snp.left).offset(-16)
            }
            self.detailLabel.snp.removeConstraints()
        } else {
            self.titleLabel.snp.remakeConstraints { (make) in
                make.top.equalTo(16)
                make.left.equalTo(16)
                make.right.lessThanOrEqualTo(self.switchButton.snp.left).offset(-16)
            }
            self.detailLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(16)
                make.width.equalTo(208)
                make.top.equalTo(self.titleLabel.snp.bottom).offset(4)
                make.bottom.equalTo(-16)
            }
        }
    }
}
