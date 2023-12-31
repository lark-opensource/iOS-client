//
//  UniverseDesignBadgeBaseCell.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit

class UniverseDesignBadgeBaseCell: UITableViewCell {
    let label = UILabel(frame: .zero)
    let content = UIView(frame: .zero)

    var height: CGFloat {
        label.sizeToFit()
        return 22.0 + label.intrinsicContentSize.height + 10.0 + contentHeight + 12.0
    }

    var contentHeight: CGFloat {
        return 0.0
    }

    init(resultId: String, title: String) {
        super.init(style: .default, reuseIdentifier: resultId)
        selectionStyle = .none
        contentView.addSubview(label)
        contentView.addSubview(content)

        label.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(14.0)
            make.top.equalToSuperview().offset(22.0)
        }

        content.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(24.0)
            make.top.equalTo(label.snp.bottom).offset(10.0)
            make.bottom.equalToSuperview().inset(12.0)
        }

        label.textColor = UIColor.ud.textTitle
        label.font = .boldSystemFont(ofSize: 14.0)
        label.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
