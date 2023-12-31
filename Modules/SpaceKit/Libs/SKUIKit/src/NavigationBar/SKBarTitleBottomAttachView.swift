//
//  SKBarTitleBottomAttachView.swift
//  SKUIKit
//
//  Created by zengsenyuan on 2021/12/6.
//  


import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

public struct SKBarTitleBottomAttachInfo {
    public var icon: UIImage?
    public var title: String
    
    public init(icon: UIImage?, title: String) {
        self.icon = icon
        self.title = title
    }
}

public final class SKBarTitleBottomAttachView: UIView {

    struct Metrics {
        static let iconSize: CGFloat = 14
        static let spacingBetweenIconAndTitle: CGFloat = 2
    }

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = UDColor.textPlaceholder
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(Metrics.iconSize)
            make.left.centerY.equalToSuperview()
        }

        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(Metrics.spacingBetweenIconAndTitle)
            make.right.equalToSuperview()
        }
    }
    public func calculateWidth(by text: String) -> CGFloat {
        return Metrics.iconSize + Metrics.spacingBetweenIconAndTitle + text.getWidth(font: UIFont.systemFont(ofSize: 12))
    }

    public func config(info: SKBarTitleBottomAttachInfo) {
        iconView.image = info.icon
        nameLabel.text = info.title
    }
}
