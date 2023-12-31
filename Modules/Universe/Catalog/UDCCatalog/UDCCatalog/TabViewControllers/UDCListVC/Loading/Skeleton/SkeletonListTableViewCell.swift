//
//  SkeletonListTableViewCell.swift
//  UniverseDesignLoadingDev
//
//  Created by Miaoqi Wang on 2020/11/9.
//

import Foundation
import UIKit
import UniverseDesignLoading

class SkeletonListTableViewCell: UITableViewCell {

    let mainLabel: UILabel
    let subLabel: UILabel
    var avatarView: UIImageView

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.mainLabel = UILabel()
        self.subLabel = UILabel()
        self.avatarView = UIImageView()

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.isSkeletonable = true
        self.contentView.addSubview(mainLabel)
        self.contentView.addSubview(subLabel)
        self.contentView.addSubview(avatarView)

        self.contentView.isSkeletonable = true
        avatarView.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().inset(16)
            make.height.width.equalTo(50)
            make.centerY.equalToSuperview()
        }

        mainLabel.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.snp.centerY).inset(8)
            make.leading.equalTo(avatarView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(60)
        }

        subLabel.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.centerY).offset(8)
            make.leading.equalTo(mainLabel)
            make.trailing.equalToSuperview().inset(16)
        }

        avatarView.layer.borderWidth = 1.0
        avatarView.ud.setLayerBorderColor(UIColor.ud.lineBorderComponent)
        mainLabel.isSkeletonable = true
        subLabel.isSkeletonable = true
        avatarView.isSkeletonable = true
        avatarView.layer.masksToBounds = true
        mainLabel.text = " "
        subLabel.text = " "
        mainLabel.udSkeletonCorner()
        subLabel.udSkeletonCorner()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarView.layer.cornerRadius = avatarView.bounds.height / 2
    }
}

class SkeletonCollectionCel: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isSkeletonable = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 5
        layer.masksToBounds = true
    }
}
