//
//  GrayTableHeader.swift
//  Lark
//
//  Created by zc09v on 2017/6/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public final class GrayTableHeader: UITableViewHeaderFooterView {

    public private(set) var title: UILabel
    public private(set) var subTitle: UILabel

    override init(reuseIdentifier: String?) {
        title = UILabel()
        subTitle = UILabel()

        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgBase

        self.contentView.addSubview(title)
        self.contentView.addSubview(subTitle)

        title.font = UIFont.systemFont(ofSize: 14)
        title.textColor = UIColor.ud.N900
        title.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }

        subTitle.font = UIFont.systemFont(ofSize: 14)
        subTitle.textColor = UIColor.ud.N600
        subTitle.snp.makeConstraints { (maker) in
            maker.left.equalTo(self.title.snp.right).offset(4)
            maker.right.lessThanOrEqualToSuperview().offset(-16)
            maker.centerY.equalToSuperview()
        }
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        subTitle.text = nil
        title.text = nil
    }
}
