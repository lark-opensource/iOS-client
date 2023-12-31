//
//  RecentsListCell.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2023/5/11.
//

import UIKit
import LarkTab
import ByteWebImage
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor
import LarkExtensions

/// 展示单条 “最近使用” 记录的 Cell
final class RecentsListCell: UICollectionViewCell {

    var moreHandler: ((UIButton) -> Void)?

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 6
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var moreButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.moreOutlined,
                                            iconColor: UIColor.ud.iconN2,
                                            size: CGSize(width: 16, height: 16)), for: .normal)
        return button
    }()

    func config(with tab: TabCandidate) {
        titleLabel.text = tab.title
        let placeHolder = UDIcon.getIconByKey(.globalLinkOutlined, iconColor: UIColor.ud.iconN3)
        switch tab.icon.type {
        case .udToken:
            imageView.image = UDIcon.getIconByString(tab.icon.content) ?? placeHolder
        case .byteKey:
            let keys = tab.icon.parseKeyAndEntityID()
            if let key = keys.key {
                imageView.bt.cancelImageRequest()
                imageView.bt.setLarkImage(with: .avatar(key: key, entityID: keys.entityID ?? ""), placeholder: placeHolder)
            } else {
                imageView.image = placeHolder
            }
        case .webURL:
            if let url = URL(string: tab.icon.content) {
                imageView.bt.setImage(url, placeholder: placeHolder)
            } else {
                imageView.image = placeHolder
            }
        @unknown default:
            break
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(moreButton)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
        }
        moreButton.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(12)
            make.trailing.equalTo(moreButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        moreButton.hitTestEdgeInsets = .init(top: -10, left: -10, bottom: -10, right: -10)
        moreButton.addTarget(self, action: #selector(didTapMoreButton), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func didTapMoreButton() {
        moreHandler?(moreButton)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
    }
}

final class RecentsListMoreCell: UICollectionViewCell {

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.body2
        label.textColor = UIColor.ud.primaryPri500
        return label
    }()

    private lazy var detailButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.rightSmallCcmOutlined,
                                            iconColor: UIColor.ud.iconN2,
                                            size: CGSize(width: 16, height: 16)), for: .normal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(textLabel)
        contentView.addSubview(detailButton)
        textLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalTo(detailButton.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        detailButton.snp.makeConstraints { make in
            make.width.height.equalTo(16)
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
        }
        textLabel.text = BundleI18n.AnimatedTabBar.Lark_Core_More_ViewMoreTabs_Button
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
