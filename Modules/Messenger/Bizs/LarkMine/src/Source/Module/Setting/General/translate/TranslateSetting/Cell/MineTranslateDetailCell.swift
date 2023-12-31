//
//  MineTranslateDetailCell.swift
//  LarkMine
//
//  Created by 李勇 on 2019/7/22.
//

import UIKit
import Foundation

struct MineTranslateDetailModel: MineTranslateItemProtocol {
    var cellIdentifier: String
    var title: String
    var detail: String
    var isDetailRight: Bool = false
    var tapHandler: MineTranslateTapHandler
}

/// title + detail + arrow
final class MineTranslateDetailCell: MineTranslateBaseCell {
    /// 中间标题
    private let titleLabel = UILabel()
    /// 详情
    private let detailLabel = UILabel()
    /// 箭头
    private let arrowImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        /// 箭头
        self.arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.arrowImageView.setContentHuggingPriority(.required, for: .horizontal)
        self.arrowImageView.image = Resources.mine_right_arrow
        self.contentView.addSubview(self.arrowImageView)
        self.arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        /// 中间标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)

        /// 详情
        self.detailLabel.textColor = UIColor.ud.textPlaceholder
        self.detailLabel.numberOfLines = 0
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(self.detailLabel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let currItem = self.item as? MineTranslateDetailModel {
            currItem.tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }

    override func setCellInfo() {
        guard let currItem = self.item as? MineTranslateDetailModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
        self.detailLabel.text = currItem.detail
        self.detailLabel.isHidden = currItem.detail.isEmpty
        if currItem.detail.isEmpty {
            self.titleLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.top.equalTo(16)
                make.left.equalTo(16)
                make.right.lessThanOrEqualTo(self.arrowImageView.snp.left).offset(-16)
            }
            self.detailLabel.snp.removeConstraints()
        } else {
            self.titleLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.top.equalTo(16)
                make.left.equalTo(16)
                make.right.lessThanOrEqualTo(self.arrowImageView.snp.left).offset(-16)
            }
            if currItem.isDetailRight {
                self.detailLabel.snp.remakeConstraints { (make) in
                    make.centerY.equalToSuperview()
                    make.right.equalTo(self.arrowImageView.snp.left).offset(-12)
                }
            } else {
                self.detailLabel.snp.remakeConstraints { (make) in
                    make.left.equalTo(16)
                    make.right.lessThanOrEqualTo(self.arrowImageView.snp.left).offset(-16)
                    make.top.equalTo(self.titleLabel.snp.bottom).offset(4)
                    make.bottom.equalTo(-16)
                }
            }

        }
    }
}
