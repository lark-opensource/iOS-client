//
//  SpaceEntranceV2Cell.swift
//  SKSpace
//
//  Created by Weston Wu on 2023/5/18.
//

import UIKit
import SnapKit
import UniverseDesignColor
import CoreGraphics
import SKFoundation

public struct SpaceEntranceV2Layout: SpaceEntranceLayoutType {
    public var sectionHorizontalInset: CGFloat { 0 }

    public var footerHeight: CGFloat { 12 }
    public var footerColor: UIColor { UDColor.bgBody }

    public var itemSize: CGSize {
        CGSize(width: containerWidth / 4, height: 92)
    }
    private var containerWidth: CGFloat = 375

    public init(itemCount: Int) {}

    public mutating func update(itemCount: Int) {}

    public mutating func update(containerWidth: CGFloat) {
        self.containerWidth = containerWidth
    }
}

public class SpaceEntranceV2Cell: UICollectionViewCell, SpaceEntranceCellType {

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var iconBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.numberOfLines = 2
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    public override var isHighlighted: Bool {
        didSet {
            contentView.backgroundColor = isHighlighted ? UIColor.ud.N200 : UIColor.clear
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor.clear
        contentView.layer.cornerRadius = 4

        contentView.addSubview(iconBackgroundView)
        iconBackgroundView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(48)
        }

        iconBackgroundView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconBackgroundView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().inset(8)
        }

        contentView.docs.addHighlight(with: .zero, radius: 8)
    }

    public override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        iconBackgroundView.backgroundColor = .clear
        titleLabel.text = nil
    }

    public func update(entrance: SpaceEntrance) {
        iconView.image = entrance.image
        titleLabel.text = entrance.title
        iconBackgroundView.backgroundColor = entrance.themeColor
    }
    
    public func update(needHighlight: Bool) {}
}
