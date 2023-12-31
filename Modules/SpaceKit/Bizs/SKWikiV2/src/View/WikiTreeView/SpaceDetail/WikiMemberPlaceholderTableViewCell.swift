//
//  WikiMemberPlaceholderTableViewCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/12/26.
//  

import UIKit

class WikiMemberPlaceholderTableViewCell: UITableViewCell {
    private lazy var avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N200
        return view
    }()

    private lazy var roleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N200
        view.layer.cornerRadius = 1
        view.clipsToBounds = true
        return view
    }()

    private lazy var nameView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N200
        view.layer.cornerRadius = 1
        view.clipsToBounds = true
        return view
    }()

    private lazy var descriptionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N200
        view.layer.cornerRadius = 1
        view.clipsToBounds = true
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }
        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true

        contentView.addSubview(roleView)
        roleView.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.width.equalTo(50)
        }

        contentView.addSubview(nameView)
        nameView.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.top.equalToSuperview().inset(14)
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.width.equalTo(110)
        }

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { make in
            make.top.equalTo(nameView.snp.bottom).offset(4)
            make.height.equalTo(16)
            make.bottom.equalToSuperview().inset(14)
            make.left.equalTo(nameView.snp.left)
            make.right.equalTo(roleView.snp.left).offset(-33)
        }
    }
}
