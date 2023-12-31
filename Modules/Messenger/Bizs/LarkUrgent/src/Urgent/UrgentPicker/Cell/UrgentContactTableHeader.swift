//
//  UrgentContactTableHeader.swift
//  LarkUrgent
//
//  Created by 李勇 on 2019/6/7.
//

import UIKit
import Foundation

final class UrgentContactTableHeader: UITableViewHeaderFooterView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.primaryOnPrimaryFill

        self.contentView.addSubview(self.headerText)
        self.headerText.snp.makeConstraints { (make) in
            make.left.equalTo(30)
            make.centerY.equalToSuperview()
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var headerText: UILabel = {
        let headerText = UILabel()
        headerText.textColor = UIColor.ud.color(74, 74, 74, 1.0)
        headerText.font = UIFont.systemFont(ofSize: 17)
        return headerText
    }()

    func setContent(_ str: String) {
        self.headerText.text = str
    }
}
