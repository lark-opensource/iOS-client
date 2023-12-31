//
//  MineTranslateLanguageCell.swift
//  LarkMine
//
//  Created by zhenning on 2020/02/11.
//

import UIKit
import Foundation
import LarkModel
import RustPB

struct MineTranslateLanguageModel: MineTranslateItemProtocol {
    var cellIdentifier: String
    var title: String
    var subTitle: String
    var detail: String
    var srcConfig: RustPB.Im_V1_SrcLanguageConfig?
    var srcLanugage: String
}

/// title + detail + arrow
final class MineTranslateLanguageCell: MineTranslateBaseCell {
    /// 中间标题
    private let titleLabel = UILabel()
    /// 详情
    private let detailLabel = UILabel()
    /// 箭头
    private let arrowImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        /// 标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(self.titleLabel)

        /// 箭头
        self.arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.arrowImageView.setContentHuggingPriority(.required, for: .horizontal)
        self.arrowImageView.image = Resources.mine_right_arrow
        self.contentView.addSubview(self.arrowImageView)
        self.arrowImageView.snp.makeConstraints { (make) in
            make.right.equalTo(-16)
            make.centerY.equalToSuperview()
        }

        /// 详情
        self.detailLabel.textColor = UIColor.ud.textPlaceholder
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.detailLabel.textAlignment = .right
        self.detailLabel.numberOfLines = 2
        self.contentView.addSubview(self.detailLabel)
        self.titleLabel.snp.remakeConstraints { (make) in
            make.top.equalTo(14)
            make.left.equalTo(16)
            make.width.lessThanOrEqualTo(140)
            make.bottom.equalTo(-14)
        }
        self.detailLabel.snp.makeConstraints { (make) in
            make.top.equalTo(16)
            make.left.greaterThanOrEqualTo(self.titleLabel.snp.right).offset(8)
            make.right.equalTo(self.arrowImageView.snp.left).offset(-8)
            make.width.lessThanOrEqualTo(160)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = self.item as? MineTranslateLanguageModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
        self.detailLabel.text = currItem.detail
    }
}
