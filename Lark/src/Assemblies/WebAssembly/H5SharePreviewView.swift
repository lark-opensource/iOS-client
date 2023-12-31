//
//  H5SharePreviewView.swift
//  Lark
//
//  Created by bytedance on 2022/7/29.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import OPFoundation

final class H5SharePreviewView: UIView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17.0, weight: .medium)
        label.textColor = UIColor.ud.textTitle
        label.backgroundColor = .clear
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16.0)
        label.textColor = UIColor.ud.N900
        label.backgroundColor = .clear
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var logoView: UIImageView = {
        let logoView = UIImageView()
        logoView.backgroundColor = UIColor.ud.staticWhite
        logoView.layer.cornerRadius = 4.0
        logoView.clipsToBounds = true
        logoView.ud.setMaskView()
        return logoView
    }()

    public init(title: String, description: String, imageKey: String) {
        super.init(frame: .zero)
        setupViews(title: title, description: description, imageKey: imageKey)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews(title: String, description: String, imageKey: String) {
        self.layer.cornerRadius = 6.0
        self.clipsToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.ud.N300.cgColor
        self.addSubview(titleLabel)
        titleLabel.text = title
        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }

        self.addSubview(logoView)
        logoView.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview().offset(-12)
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.size.equalTo(CGSize(width: 66, height: 66))
        }
        if !imageKey.isEmpty {
            logoView.bt.setLarkImage(with: .default(key: imageKey))
            logoView.contentMode = .scaleAspectFill
        } else {
            logoView.image = UIImage.op_imageNamed("share_h5_preview_icon")
        }

        self.addSubview(descriptionLabel)
        descriptionLabel.text = description
        descriptionLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.top.equalTo(logoView.snp.top)
            make.bottom.equalToSuperview().offset(-12)
            make.right.equalTo(logoView.snp.left).offset(-10)
        }
    }
}
