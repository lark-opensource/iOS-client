//
//  SetInformationArrowCell.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/15.
//

import UIKit
import Foundation

struct SetInformationArrowItem: SetInformationItemProtocol {
    var cellIdentifier: String
    var title: String
    var tapHandler: SetInforamtionTapHandler
}

final class SetInformationArrowCell: SetInformationBaseCell {
    /// 中间标题
    private lazy var titleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        /// 箭头
        let arrowImageView = UIImageView()
        arrowImageView.image = Resources.mine_right_arrow
        arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(-16)
        }

        /// 中间标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.lessThanOrEqualTo(arrowImageView.snp.left).offset(-16)
            make.top.equalTo(16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = item as? SetInformationArrowItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let currItem = self.item as? SetInformationArrowItem {
            currItem.tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }
}
