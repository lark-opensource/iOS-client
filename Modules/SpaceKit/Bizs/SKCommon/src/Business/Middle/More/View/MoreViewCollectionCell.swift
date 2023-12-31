//
//  MoreViewCollectionCell.swift
//  SpaceKit
//
//  Created by Ryan on 2019/2/14.
//

import UIKit
import UniverseDesignColor
import UniverseDesignBadge

class MoreViewCollectionCell: UICollectionViewCell {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = UDColor.textTitle
        return label
    }()

    private lazy var imageView = UIImageView()

    /// 引导的小红点
    private lazy var reddotView: UDBadge = {
        let view = imageView.addBadge(.dot, anchor: .topRight, anchorType: .circle,
                                      offset: .init(width: 4, height: -4))
        view.config.dotSize = .large
        return view
    }()

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                contentView.backgroundColor = UDColor.fillPressed
            } else {
                contentView.backgroundColor = UDColor.bgFloat
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        contentView.backgroundColor = UDColor.bgFloat
        contentView.layer.cornerRadius = 8
        contentView.docs.addStandardLift()
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(12)
            make.width.height.equalTo(24)
            make.centerX.equalToSuperview()
        }
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(40)
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
    }

    func update(title: String, image: UIImage, needReddot: Bool) {
        titleLabel.text = title
        if imageView.tintColor == .clear {
            imageView.image = image.withRenderingMode(.alwaysOriginal)
        } else {
            imageView.image = image.withRenderingMode(.alwaysTemplate)
        }
        reddotView.isHidden = !needReddot
    }

    func update(isEnabled: Bool, imageEnableColor: UIColor, imageDisableColor: UIColor) {
        let imageColor: UIColor
        let textColor: UIColor
        if isEnabled {
            imageColor = imageEnableColor
            textColor = UDColor.textTitle
        } else {
            imageColor = imageDisableColor
            textColor = UDColor.textDisabled
        }
        imageView.tintColor = imageColor
        titleLabel.textColor = textColor
    }
}
