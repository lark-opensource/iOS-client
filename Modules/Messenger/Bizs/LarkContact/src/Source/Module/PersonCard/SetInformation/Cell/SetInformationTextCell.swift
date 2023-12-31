//
//  SetInformationTextCell.swift
//  LarkContact
//
//  Created by 强淑婷 on 2020/7/15.
//

import UIKit
import Foundation
import LarkUIKit

struct SetInformationTextItem: SetInformationItemProtocol {
    var cellIdentifier: String
    var title: String
    var tapHandler: SetInforamtionTapHandler
}

final class SetInformationTextCell: SetInformationBaseCell {
    /// 中间标题
    private lazy var titleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        /// 中间标题
        self.titleLabel.textColor = UIColor.ud.functionDangerContentDefault
        self.titleLabel.numberOfLines = 0
        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
        self.titleLabel.textAlignment = .center
        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalToSuperview().offset(-16)
            make.top.equalTo(16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setCellInfo() {
        guard let currItem = item as? SetInformationTextItem else {
            assert(false, "\(self):item.Type error")
            return
        }
        self.titleLabel.text = currItem.title
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        if selected, let currItem = self.item as? SetInformationTextItem {
            currItem.tapHandler()
        }
        super.setSelected(selected, animated: animated)
    }
}
