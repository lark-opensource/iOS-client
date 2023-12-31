//
//  VCPersonasCheckpointCell.swift
//  ByteView
//
//  Created by wpr on 2023/12/18.
//

import Foundation
import SnapKit
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

class VCPersonasCheckpointCell: UICollectionViewCell {

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        return label
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.backgroundColor = UIColor.ud.N200

        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.width.equalTo(150)
//            make.height.equalTo(imageView.snp.width).multipliedBy(16.0 / 9.0)
            make.height.equalTo(192.8)
        }

        titleLabel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom)
            make.height.greaterThanOrEqualTo(30)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCheckpoint(name: String) {
        self.titleLabel.text = name
        self.imageView.image = UIImage(named: name)
    }
}
