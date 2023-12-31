//
//  PostCategoriesListCell.swift
//  Moment
//
//  Created by bytedance on 2021/4/22.
//

import Foundation
import UIKit
import LarkBizAvatar
import AvatarComponent
import LarkFeatureGating
import FigmaKit

final class PostCategoriesListCell: UITableViewCell {
    static let reuseId = "PostTabsListCell"
    let avatarWidth: CGFloat = 48
    public lazy var avatarView: BizAvatar = {
        let view = SmoothingBizAvatar()
        view.setSmoothCorner(radius: 8, smoothness: .max)
        view.clipsToBounds = true
        view.backgroundColor = UIColor.ud.N200
        let config = AvatarComponentUIConfig(style: .square)
        view.setAvatarUIConfig(config)
        return view
    }()

    let contentLabel: UILabel = UILabel()
    let rightImage: UIImageView = UIImageView(image: Resources.listCheck)
    var item: PostCategoryDataItem? {
        didSet {
            updateUI()
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    func setupUI() {
        self.backgroundColor = UIColor.ud.bgBody
        contentView.addSubview(avatarView)

        contentLabel.font = UIFont.systemFont(ofSize: 16.0)
        contentLabel.numberOfLines = 1
        contentView.addSubview(contentLabel)

        rightImage.isHidden = true
        contentView.addSubview(rightImage)

        avatarView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 45, height: 45))
        }
        contentLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(rightImage.snp.left).offset(-6)
        }

        rightImage.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 24, height: 24))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateUI() {
        guard let item = item else {
            return
        }
        self.avatarView.setAvatarByIdentifier(item.data.category.categoryID, avatarKey: item.data.category.iconKey, avatarViewParams: .init(sizeType: .size(avatarWidth)))
        self.contentLabel.text = item.data.category.name
        self.rightImage.isHidden = !item.userSelected
    }
}
