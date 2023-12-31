//
//  MailGroupMemberTableHeader.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/10/28.
//

import Foundation
import UIKit

final class MailGroupMemberTableHeader: UITableViewHeaderFooterView {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgBody
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var headerText: UILabel = {
        let headerText = UILabel()
        headerText.numberOfLines = 0

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        self.contentView.addSubview(line)
        self.contentView.addSubview(headerText)
        headerText.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
        line.snp.makeConstraints { (make) in
            make.height.equalTo(0.5)
            make.left.right.bottom.equalToSuperview()
        }
        headerText.textColor = UIColor.ud.textCaption
        headerText.font = UIFont.systemFont(ofSize: 14)
        return headerText
    }()

    public func setContent(_ str: String, left: CGFloat = 16.0, animated: Bool = false) {
        self.headerText.text = str
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
