//
//  DescriptionHistoryCell.swift
//  LarkMine
//
//  Created by liuwanlin on 2018/8/2.
//

import Foundation
import UIKit
import LarkModel
import LarkUIKit
import UniverseDesignIcon

final class DescriptionHistoryCell: BaseTableViewCell {

    var deleteBlock: ((Chatter.Description) -> Void)?

    var chatterDescriotion: Chatter.Description? {
        didSet {
            guard let item = self.chatterDescriotion else { return }

            self.contentLabel.text = item.text
        }
    }

    var contentLabel: UILabel = UILabel()
    var deleteBtn: UIButton = UIButton()
    var dividingLine: UIView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(contentLabel)
        self.contentView.addSubview(deleteBtn)

        deleteBtn.setImage(UDIcon.getIconByKey(.closeOutlined).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        deleteBtn.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        deleteBtn.addTarget(self, action: #selector(clickDeleteBtn), for: .touchUpInside)
        deleteBtn.snp.makeConstraints { (make) in
            make.width.height.equalTo(15)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
        contentLabel.textColor = UIColor.ud.textTitle
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(12)
            make.right.lessThanOrEqualTo(deleteBtn.snp.left).offset(-16)
        }
        dividingLine = self.lu.addBottomBorder(leading: 12, trailing: 0, color: UIColor.ud.lineDividerDefault)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func clickDeleteBtn() {
        guard let item = self.chatterDescriotion else { return }
        self.deleteBlock?(item)
    }
}
