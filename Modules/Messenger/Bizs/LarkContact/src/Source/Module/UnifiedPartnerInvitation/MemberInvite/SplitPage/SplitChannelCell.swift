//
//  SplitChannelCell.swift
//  LarkContact
//
//  Created by shizhengyu on 2020/1/1.
//

import Foundation
import UIKit
import SnapKit

final class SplitChannelCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        layoutPageSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindModel(_ model: SplitChannel) {
        iconView.image = model.icon
        mainTitleLabel.text = model.title
        secondTitleLabel.text = model.secondTitle

        if model.secondTitle.isEmpty {
            mainTitleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(iconView.snp.right).offset(16)
                make.top.equalToSuperview().offset(16)
                make.right.equalTo(arrowView.snp.left).offset(-16)
                make.bottom.equalToSuperview().offset(-16)
            }
        } else {
            mainTitleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(iconView.snp.right).offset(16)
                make.top.equalToSuperview().offset(16)
                make.right.equalTo(arrowView.snp.left).offset(-16)
            }
            secondTitleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(mainTitleLabel)
                make.top.equalTo(mainTitleLabel.snp.bottom).offset(2)
                make.right.equalTo(arrowView.snp.left).offset(-16)
                make.bottom.equalToSuperview().offset(-16)
            }
        }
    }

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        return view
    }()

    private lazy var mainTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    private lazy var secondTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        return label
    }()

    private lazy var arrowView: UIImageView = {
        let view = UIImageView()
        view.image = MemberInviteNoDirectionalController.Icon.rightBoldOutlined
        return view
    }()
}

private extension SplitChannelCell {
    func layoutPageSubviews() {
        contentView.addSubview(iconView)
        contentView.addSubview(mainTitleLabel)
        contentView.addSubview(secondTitleLabel)
        contentView.addSubview(arrowView)
        self.backgroundColor = UIColor.ud.bgBody
        iconView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        mainTitleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(16)
            make.top.equalToSuperview().offset(16)
            make.right.equalTo(arrowView.snp.left).offset(-16)
        }
        secondTitleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(mainTitleLabel)
            make.top.equalTo(mainTitleLabel.snp.bottom).offset(2)
            make.right.equalTo(arrowView.snp.left).offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }
        arrowView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(15.5)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
    }
}
