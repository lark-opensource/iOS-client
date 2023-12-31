//
//  UniverseDesignBadgeCase.swift
//  UDCCatalog
//
//  Created by Meng on 2020/10/28.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit

class UniverseDesignBadgeCase: UIView {
    let label = UILabel(frame: .zero)
    let content = UIView(frame: .zero)

    var height: CGFloat {
        label.sizeToFit()
        return label.intrinsicContentSize.height + 8.0 + contentHeight + 16.0
    }

    var contentHeight: CGFloat {
        return 0.0
    }

    init(title: String) {
        super.init(frame: .zero)

        addSubview(label)
        addSubview(content)

        label.snp.makeConstraints { (make) in
            make.leading.top.equalToSuperview()
        }

        content.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(contentHeight)
            make.top.equalTo(label.snp.bottom).offset(8.0)
        }

        label.text = title
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 13.0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
