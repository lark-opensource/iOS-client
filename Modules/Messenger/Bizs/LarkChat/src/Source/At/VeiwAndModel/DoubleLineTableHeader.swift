//
//  DoubleLineTableHeader.swift
//  Lark
//
//  Created by zhenning on 2020/02/04.
//  Copyright © 2020年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

public final class DoubleLineTableHeader: UITableViewHeaderFooterView {

    public private(set) var title: UILabel

    override init(reuseIdentifier: String?) {
        title = UILabel()

        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgBody

        self.contentView.addSubview(title)

        title.font = UIFont.systemFont(ofSize: 14)
        title.textColor = UIColor.ud.N900
        title.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
        }
    }
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        title.text = nil
    }
}
