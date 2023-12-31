//
//  AuthTenantView.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/2/25.
//

import UIKit
import Kingfisher

class AuthTenantView: UIView {

    let titleLabel: UILabel = UILabel()
    let imageView: UIImageView = UIImageView()
    let tenantLabel: UILabel = UILabel()
    let nameLabel: UILabel = UILabel()

    init() {
        super.init(frame: .zero)
        imageView.layer.cornerRadius = Common.Layer.commonAvatarImageRadius
        imageView.clipsToBounds = true

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.numberOfLines = 3

        tenantLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        tenantLabel.textColor = UIColor.ud.textTitle

        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.ud.textPlaceholder

        addSubview(titleLabel)
        addSubview(imageView)
        addSubview(tenantLabel)
        addSubview(nameLabel)

        titleLabel.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.lessThanOrEqualTo(20)
        }

        imageView.snp.makeConstraints { (make) in
            make.left.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.size.equalTo(Layout.imageSize)
        }

        tenantLabel.snp.makeConstraints { (make) in
            make.left.equalTo(imageView.snp.right).offset(Layout.labelleft)
            make.top.equalTo(imageView.snp.top)
            make.right.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(imageView.snp.bottom)
            make.left.equalTo(tenantLabel)
            make.right.equalToSuperview()
            make.top.greaterThanOrEqualTo(tenantLabel.snp.bottom)
        }

        let bottomLine = UIView()
        addSubview(bottomLine)
        bottomLine.backgroundColor = UIColor.ud.textTitle.withAlphaComponent(0.16)
        bottomLine.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(12)
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(0.6)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, imageUrl: String, tenant: String, name: String) {
        self.titleLabel.text = title
        self.imageView.kf.setImage(with: URL(string: imageUrl))
        self.tenantLabel.text = tenant
        self.nameLabel.text = name
    }
}

extension AuthTenantView {
    enum Layout {
        static let imageSize = CGSize(width: 40, height: 40)
        static let labelleft: CGFloat = 12
    }
}
