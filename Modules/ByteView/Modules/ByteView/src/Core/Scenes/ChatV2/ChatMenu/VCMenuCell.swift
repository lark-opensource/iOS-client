//
//  VCMenuCell.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import SnapKit

class VCMenuCell: UICollectionViewCell {
    fileprivate enum Layout {
        static let labelMarginLeft: CGFloat = 3
        static let labelMarginRight: CGFloat = 4
        static let imageSize: CGSize = CGSize(width: 22, height: 22)
        static let imageMarginLeft: CGFloat = 16
        static let imageMarginRight: CGFloat = 17
        static let imageMarginTop: CGFloat = 16
        static let imageToLabel: CGFloat = 8
    }

    private lazy var iconImage: UIImageView = UIImageView()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = UIColor.ud.textTitle
        label.adjustsFontSizeToFitWidth = true
        label.baselineAdjustment = .alignCenters
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgFloat
        self.contentView.addSubview(iconImage)
        iconImage.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(Layout.imageMarginTop)
            make.left.equalToSuperview().inset(Layout.imageMarginLeft)
            make.size.equalTo(Layout.imageSize)
        }
        self.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(iconImage.snp.bottom).offset(Layout.imageToLabel)
            make.left.equalToSuperview().inset(Layout.labelMarginLeft)
            make.right.equalToSuperview().inset(Layout.labelMarginRight)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with item: VCMenuItem) {
        titleLabel.text = item.name
        iconImage.image = item.image.withRenderingMode(.alwaysTemplate)
        iconImage.tintColor = UIColor.ud.iconN1
    }
}
