//
//  TeamEventCellLoadingView.swift
//  LarkTeam
//
//  Created by chaishenghua on 2022/9/6.
//

import Foundation
import UIKit

final class TeamEventCellLoadingView: UITableViewCell {
    static let identifier = "TeamEventLoadingCellView"

    lazy var circleView: UIView = {
        let circleView = UIView()
        circleView.layer.cornerRadius = 8
        circleView.clipsToBounds = true
        return circleView
    }()

    lazy var textView = UIView()

    lazy var dateView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.contentView.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(circleView)
        contentView.addSubview(textView)
        contentView.addSubview(dateView)
        circleView.snp.makeConstraints { (make) in
            make.width.equalTo(16)
            make.height.equalTo(16)
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(13)
        }
        textView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(52)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(13)
            make.height.equalTo(16)
        }
        dateView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(52)
            make.top.equalTo(textView.snp.bottom).offset(8)
            make.height.equalTo(14)
            make.width.equalTo(64)
            make.bottom.equalToSuperview().inset(13)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textView.layoutIfNeeded()
        dateView.layoutIfNeeded()
        circleView.showUDSkeleton()
        textView.showUDSkeleton()
        dateView.showUDSkeleton()
    }
}
