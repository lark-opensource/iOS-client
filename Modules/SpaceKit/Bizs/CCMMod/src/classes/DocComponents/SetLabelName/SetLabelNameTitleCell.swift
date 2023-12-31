//
//  SetLabelNameTitleCell.swift
//  LarkSpaceKit
//
//  Created by zhangxingcheng on 2021/7/27.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import LarkUIKit
import UniverseDesignColor

class SetLabelNameTitleCell: UITableViewCell {

    private var titleLabel: UILabel = UILabel()

    var titleModel: SetLabelNameTitleModel?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.backgroundColor = UDColor.bgBase

        self.contentView.addSubview(self.titleLabel)
        self.titleLabel.font = UIFont.systemFont(ofSize: 14)
        self.titleLabel.textColor = UDColor.textPlaceholder
        self.titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(14)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(22)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setCellModel(_ titleModel: SetLabelNameTitleModel) {
        self.titleModel = titleModel
        self.titleLabel.text = titleModel.title
    }
}
