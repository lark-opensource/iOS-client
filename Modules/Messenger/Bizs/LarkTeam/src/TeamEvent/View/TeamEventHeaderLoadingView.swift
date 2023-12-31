//
//  TeamEventHeaderLoadingView.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/9/6.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignLoading

final class TeamEventHeaderLoadingView: UITableViewHeaderFooterView {
    static let identifier = "TeamEventheaderLoadingView"
    lazy var titleView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(72)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(24)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleView.layoutIfNeeded()
        titleView.showUDSkeleton()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
