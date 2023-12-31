//
//  TeamEventHeaderView.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/9/6.
//

import Foundation
import UIKit
import SnapKit

final class TeamEventHeaderView: UITableViewHeaderFooterView {
    static let identifier = "TeamEventheaderView"
    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textColor = UIColor.ud.textTitle
        return titleLabel
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        self.contentView.backgroundColor = UIColor.ud.bgBody
        titleLabel.snp.remakeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().inset(15)
        }
    }

    func setTitle(title: String) {
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
