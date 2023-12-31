//
//  MineTranslateSwitchCell.swift
//  LarkMine
//
//  Created by 李勇 on 2019/7/17.
//

import UIKit
import Foundation
import LarkUIKit

struct MineTranslateTitleModel: MineTranslateItemProtocol {
    var cellIdentifier: String
    var title: String
    var tapHandler: MineTranslateTapHandler
}

/// title + arrow
final class MineTranslateTitleCell: MineTranslateBaseCell {
    /// 标题
    private let titleLabel = UILabel()
    /// 箭头
    private let arrowImageView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.arrowImageView.setContentHuggingPriority(.required, for: .horizontal)
        self.arrowImageView.image = Resources.mine_right_arrow
        self.contentView.addSubview(self.arrowImageView)
        self.arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.numberOfLines = 0
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.top.equalTo(16)
            make.centerY.equalToSuperview()
            make.right.lessThanOrEqualTo(self.arrowImageView.snp.left).offset(-16)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let currItem = self.item as? MineTranslateTitleModel {
            currItem.tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }

    override func setCellInfo() {
        guard let currItem = self.item as? MineTranslateTitleModel else {
            return
        }
        self.titleLabel.text = currItem.title
    }
}
