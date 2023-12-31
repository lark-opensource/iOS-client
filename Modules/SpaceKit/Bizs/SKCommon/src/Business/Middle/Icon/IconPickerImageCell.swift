//
//  IconPickerImageCell.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/10.
//

import UIKit
import SnapKit
import SKUIKit
/*
class IconPickerImageCell: UICollectionViewCell {
    
    static let reuseIdentifier = "imageCell"

    var iconInfo: DocsIconInfo? {
        didSet {
            _didModifyModel(old: oldValue, new: iconInfo)
        }
    }

    var isChoosen: Bool = false {
        didSet {
            backgroundColor = isChoosen ? UIColor.ud.N900.withAlphaComponent(0.1) : UIColor.ud.N00
        }
    }

    let avatarView: DocsAvatarImageView = DocsAvatarImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _didModifyModel(old oldValue: DocsIconInfo?, new newValue: DocsIconInfo?) {
        guard oldValue != newValue else { return }
        avatarView.configure(newValue, trigger: "IconPickerImageCell")
    }

}

extension IconPickerImageCell {

    private func setupView() {
        contentView.addSubview(avatarView)

        avatarView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(32)
        }
        
        avatarView.imageView.backgroundColor = nil
        avatarView.backgroundColor = nil
        avatarView.isOpaque = false
        avatarView.lastingColor = .clear
        contentView.layer.cornerRadius = 15
        contentView.clipsToBounds = true
    }

    private func configure() {
        avatarView.imageView.contentMode = .scaleAspectFit
    }

}
*/
