//
//  EnterpriseCallItemCell.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/7/5.
//

import UIKit
import UniverseDesignIcon

class EnterpriseCallItemCell: UICollectionViewCell {
    private(set) var item: EnterpriseCallItem?
    private(set) var iconType: UDIconType?

    enum Layout {
        static let itemWidth: CGFloat = Display.typeIsLike < Display.DisplayType.iPhone6 ? 64 : Display.iPhoneMaxSeries ? 82 : 72
        static let itemHeight: CGFloat = itemWidth + titleTopOffset + 44
        static let titleTopOffset: CGFloat = Display.iPhoneMaxSeries ? 8 : 7
    }

    private let roundView: UIView = {
        let roundView = UIView()
        roundView.layer.cornerRadius = Layout.itemWidth / 2
        roundView.clipsToBounds = true
        roundView.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1)
        return roundView
    }()

    let imageView = UIImageView()

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    override var isHighlighted: Bool {
        didSet {
            guard let item = item else { return }
            let alpha: CGFloat
            if item.isHighlighted {
                alpha = isHighlighted ? 0.7 : 0.6
            } else {
                alpha = isHighlighted ? 0.2 : 0.1
            }
            roundView.backgroundColor = UIColor.ud.N900.withAlphaComponent(alpha)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(roundView)
        roundView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.size.equalTo(Layout.itemWidth)
        }

        roundView.addSubview(imageView)
        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(Display.iPhoneMaxSeries ? 36 : 32)
            make.center.equalToSuperview()
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(roundView.snp.bottom).offset(Layout.titleTopOffset)
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.centerX.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with item: EnterpriseCallItem) {
        self.item = item
        self.iconType = item.icon
        titleLabel.attributedText = NSAttributedString(string: item.title, config: .body)
        let iconColor = item.isHighlighted ? UIColor.ud.primaryOnPrimaryFill : (item.isEnabled ? UIColor.ud.iconN1 : UIColor.ud.iconDisabled)
        imageView.image = UDIcon.getIconByKey(item.icon, iconColor: iconColor, size: CGSize(width: 32, height: 32))
        let alpha: CGFloat = item.isHighlighted ? 0.6 : 0.1
        roundView.backgroundColor = UIColor.ud.N900.withAlphaComponent(alpha)
        isUserInteractionEnabled = item.isEnabled
    }
}
