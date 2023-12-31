//
//  AlbumListCell.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/29.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import UIKit
import SnapKit

final class AlbumListCell: UITableViewCell {
    var assetIdentifier: String?
    var thumbnailSize: CGSize {
        return CGSize(width: 50 * UIScreen.main.scale,
                      height: 50 * UIScreen.main.scale)
    }

    private let thumbnailImageView = UIImageView()
    private let mainTitleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let checkImageView = UIImageView()
    private let bottomSeperator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(thumbnailImageView)
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 50, height: 50))
        }

        checkImageView.image = Resources.image_picker_tick_blue
        addSubview(checkImageView)
        checkImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        checkImageView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
        }

        let titleStackView = UIStackView()
        titleStackView.axis = .vertical
        titleStackView.alignment = .leading
        titleStackView.distribution = .fill
        titleStackView.spacing = 10
        addSubview(titleStackView)
        titleStackView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(thumbnailImageView.snp.right).offset(10)
            make.right.lessThanOrEqualTo(checkImageView.snp.left).offset(-10)
        }

        mainTitleLabel.font = UIFont.boldSystemFont(ofSize: 13)
        titleStackView.addArrangedSubview(mainTitleLabel)

        subTitleLabel.font = UIFont.systemFont(ofSize: 10)
        subTitleLabel.textColor = UIColor.gray
        titleStackView.addArrangedSubview(subTitleLabel)

        addSubview(bottomSeperator)
        bottomSeperator.backgroundColor = .lightGray
        bottomSeperator.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, subTitle: String) {
        mainTitleLabel.text = title
        subTitleLabel.text = subTitle
    }

    func set(thumbnailImage: UIImage?) {
        thumbnailImageView.image = thumbnailImage
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        checkImageView.isHidden = !selected
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailImageView.image = nil
    }
}
