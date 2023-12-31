//
//  ContactTableHeader.swift
//  Lark
//
//  Created by 吴子鸿 on 2017/7/18.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit

public final class ContactTableHeader: UITableViewHeaderFooterView {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgBody
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var headerText: UILabel = {
        let headerText = UILabel()
        self.contentView.addSubview(headerText)
        headerText.snp.makeConstraints { (make) in
            make.left.equalTo(30)
            make.centerY.equalToSuperview()
        }
        headerText.textColor = UIColor.ud.textTitle
        headerText.font = UIFont.systemFont(ofSize: 14)
        return headerText
    }()

    public func setContent(_ str: String, left: CGFloat = 30.0, textColor: UIColor = UIColor.ud.textTitle, animated: Bool = false) {
        self.headerText.text = str
        self.headerText.textColor = textColor
        self.headerText.snp.updateConstraints { (make) in
            make.left.equalTo(left)
        }

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutIfNeeded()
            })
        }
    }
}
