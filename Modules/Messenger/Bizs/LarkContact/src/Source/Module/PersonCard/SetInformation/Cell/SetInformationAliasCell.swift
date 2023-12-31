//
//  SetInformationAliasCell.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/15.
//

import Foundation
import UIKit

final class SetInformationAliasItem: SetInformationItemProtocol {
    var cellIdentifier: String
    var title: String
    var detailTitle: String
    var tapHandler: SetInforamtionTapHandler

    init(cellIdentifier: String,
         title: String,
         detailTitle: String,
         tapHandler: @escaping SetInforamtionTapHandler) {
        self.cellIdentifier = cellIdentifier
        self.title = title
        self.detailTitle = detailTitle
        self.tapHandler = tapHandler
    }
}

final class SetInformationAliasCell: SetInformationBaseCell {
    /// 标题
    private lazy var titleLabel: UILabel = UILabel()
    /// 副标题
    private lazy var detailLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        /// 箭头
        let arrowImageView = UIImageView()
        arrowImageView.image = Resources.mine_right_arrow
        arrowImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.contentView.addSubview(arrowImageView)
        arrowImageView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }

        /// 标题
        self.titleLabel.textColor = UIColor.ud.textTitle
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.top.equalTo(16)
            make.centerY.equalToSuperview()
        }

        /// 副标题
        self.detailLabel.textColor = UIColor.ud.textPlaceholder
        self.detailLabel.font = UIFont.systemFont(ofSize: 14)
        self.contentView.addSubview(detailLabel)
        self.detailLabel.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        self.detailLabel.textAlignment = .right
        self.detailLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.right.equalTo(arrowImageView.snp.left).offset(-13)
            make.left.equalTo(self.titleLabel.snp.right).offset(20)
            make.top.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = item as? SetInformationAliasItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
        self.detailLabel.text = currItem.detailTitle
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let currItem = self.item as? SetInformationAliasItem {
            currItem.tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }
}
